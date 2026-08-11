#!/usr/bin/env python3

import argparse
import fcntl
import html
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path


QUERY = r"""
query Dashboard {
  viewer { login }
  authored: search(
    type: ISSUE
    query: "is:pr is:open author:@me archived:false"
    first: 100
  ) {
    issueCount
    nodes { ...PullRequestFields }
  }
  requested: search(
    type: ISSUE
    query: "is:pr is:open review-requested:@me archived:false"
    first: 100
  ) {
    issueCount
    nodes { ...PullRequestFields }
  }
}

fragment PullRequestFields on PullRequest {
  id
  number
  title
  url
  updatedAt
  isDraft
  mergeable
  mergeStateStatus
  reviewDecision
  author { login }
  repository { nameWithOwner }
  comments { totalCount }
  statusCheckRollup { state }
  latestReviews(first: 100) {
    nodes {
      author { __typename login }
      state
      submittedAt
    }
  }
  reviewRequests(first: 100) {
    nodes {
      requestedReviewer {
        ... on User { id login }
        ... on Team { id slug organization { login } }
      }
    }
  }
  timelineItems(last: 100, itemTypes: [REVIEW_REQUESTED_EVENT]) {
    nodes {
      ... on ReviewRequestedEvent {
        createdAt
        requestedReviewer {
          ... on User { id login }
          ... on Team { id slug organization { login } }
        }
      }
    }
  }
}
"""


def parse_time(value):
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def reviewer_key(reviewer):
    if not reviewer:
        return None
    if reviewer.get("id"):
        return reviewer["id"]
    if reviewer.get("login"):
        return f"user:{reviewer['login'].lower()}"
    organization = (reviewer.get("organization") or {}).get("login")
    if organization and reviewer.get("slug"):
        return f"team:{organization.lower()}/{reviewer['slug'].lower()}"
    return None


def ci_state(pr):
    state = ((pr.get("statusCheckRollup") or {}).get("state") or "NONE").upper()
    if state in {"FAILURE", "ERROR"}:
        return "failing"
    if state in {"PENDING", "EXPECTED"}:
        return "pending"
    if state == "SUCCESS":
        return "passing"
    return "none"


def attention(pr):
    ci = ci_state(pr)
    if pr.get("isDraft"):
        return "draft", "Draft", 8
    if pr.get("reviewDecision") == "CHANGES_REQUESTED":
        return "needs-you", "Changes requested", 0
    if pr.get("mergeable") == "CONFLICTING" or pr.get("mergeStateStatus") == "DIRTY":
        return "needs-you", "Resolve conflicts", 1
    if ci == "failing":
        return "needs-you", "Fix CI", 2
    if pr.get("reviewDecision") == "APPROVED":
        if ci == "pending":
            return "waiting", "CI running", 4
        return "ready", "Ready to merge", 3
    if ci == "pending":
        return "waiting", "CI running", 4
    if pr.get("reviewDecision") == "REVIEW_REQUIRED" or (pr.get("reviewRequests") or {}).get("nodes"):
        return "waiting", "Waiting for review", 5
    return "open", "Open", 7


def request_time(pr, viewer, viewer_team_ids):
    current_reviewers = [
        node.get("requestedReviewer") for node in (pr.get("reviewRequests") or {}).get("nodes", [])
    ]
    current = {
        reviewer_key(reviewer)
        for reviewer in current_reviewers
        if reviewer
        and (
            reviewer.get("login", "").lower() == viewer.lower()
            or reviewer.get("id") in viewer_team_ids
        )
    }
    current.discard(None)
    matching = []
    for event in (pr.get("timelineItems") or {}).get("nodes", []):
        if reviewer_key(event.get("requestedReviewer")) in current and event.get("createdAt"):
            matching.append(event["createdAt"])
    return max(matching, key=lambda value: parse_time(value) or datetime.min.replace(tzinfo=timezone.utc)) if matching else None


def normalize_pr(pr, viewer, viewer_team_ids, review_request=False):
    css_class, status, rank = attention(pr)
    reviews = (pr.get("latestReviews") or {}).get("nodes", [])
    other_reviews = [
        review
        for review in reviews
        if (review.get("author") or {}).get("login", "").lower() != viewer.lower()
        and (review.get("author") or {}).get("__typename") != "Bot"
        and review.get("state") in {"APPROVED", "CHANGES_REQUESTED", "COMMENTED"}
    ]
    requested_at = request_time(pr, viewer, viewer_team_ids) if review_request else None
    return {
        "author": (pr.get("author") or {}).get("login") or "ghost",
        "comments": (pr.get("comments") or {}).get("totalCount", 0),
        "ci": ci_state(pr),
        "css_class": css_class,
        "draft": bool(pr.get("isDraft")),
        "number": pr.get("number"),
        "other_reviews": other_reviews,
        "rank": rank,
        "repository": (pr.get("repository") or {}).get("nameWithOwner") or "unknown",
        "requested_at": requested_at,
        "status": status,
        "title": pr.get("title") or "Untitled pull request",
        "updated_at": pr.get("updatedAt"),
        "url": pr.get("url") or "#",
    }


def build_model(payload):
    data = payload.get("data") or {}
    viewer = (data.get("viewer") or {}).get("login")
    if not viewer:
        raise ValueError("GitHub response did not include the authenticated viewer")
    viewer_team_ids = set(payload.get("viewerTeamIds") or [])

    authored_data = data.get("authored") or {}
    requested_data = data.get("requested") or {}
    authored = [normalize_pr(pr, viewer, viewer_team_ids) for pr in authored_data.get("nodes", []) if pr]
    requested = [normalize_pr(pr, viewer, viewer_team_ids, True) for pr in requested_data.get("nodes", []) if pr]

    authored.sort(key=lambda pr: (pr["rank"], -(parse_time(pr["updated_at"]) or datetime.min.replace(tzinfo=timezone.utc)).timestamp()))
    requested.sort(
        key=lambda pr: (
            bool(pr["other_reviews"]),
            parse_time(pr["requested_at"] or pr["updated_at"]) or datetime.max.replace(tzinfo=timezone.utc),
        )
    )
    return {
        "viewer": viewer,
        "authored": authored,
        "requested": requested,
        "authored_total": authored_data.get("issueCount", len(authored)),
        "requested_total": requested_data.get("issueCount", len(requested)),
    }


def tag(text, kind="neutral"):
    return f'<span class="tag tag--{kind}">{html.escape(text)}</span>'


def ci_tag(ci):
    labels = {
        "failing": ("CI failing", "danger"),
        "pending": ("CI pending", "warning"),
        "passing": ("CI passing", "success"),
        "none": ("No CI", "quiet"),
    }
    label, kind = labels[ci]
    return tag(label, kind)


def authored_row(pr):
    badges = [ci_tag(pr["ci"]), tag(f'{pr["comments"]} comments', "quiet")]
    if pr["draft"] and pr["status"] != "Draft":
        badges.insert(0, tag("Draft", "quiet"))
    status_kind = {
        "needs-you": "danger",
        "ready": "success",
        "waiting": "warning",
        "draft": "quiet",
        "open": "neutral",
    }[pr["css_class"]]
    return f"""
      <article class="pr-item" data-pr-key="{html.escape(pr['url'], quote=True)}">
        <a class="pr-card pr-card--{pr['css_class']}" href="{html.escape(pr['url'], quote=True)}">
          <span class="card-top">
            {tag(pr['status'], status_kind)}
            <span class="date">Updated <time datetime="{html.escape(pr['updated_at'] or '')}"></time></span>
          </span>
          <span class="identity">
            <strong>{html.escape(pr['title'])}</strong>
            <small>{html.escape(pr['repository'])} #{pr['number']}</small>
          </span>
          <span class="card-bottom"><span class="meta">{''.join(badges)}</span><span class="arrow" aria-hidden="true">→</span></span>
        </a>
        {comment_controls(pr)}
      </article>"""


def requested_row(pr):
    handled = bool(pr["other_reviews"])
    badges = [ci_tag(pr["ci"]), tag(f'{pr["comments"]} comments', "quiet")]
    if pr["draft"]:
        badges.insert(0, tag("Draft", "quiet"))
    if handled:
        reviewers = len({(review.get("author") or {}).get("login") for review in pr["other_reviews"]})
        badges.insert(0, tag(f"Reviewed by {reviewers} other" + ("" if reviewers == 1 else "s"), "quiet"))
    requested_at = pr["requested_at"] or pr["updated_at"] or ""
    requested_label = "Requested" if pr["requested_at"] else "Request age unavailable; updated"
    row_class = " pr-card--handled" if handled else ""
    return f"""
      <article class="pr-item" data-pr-key="{html.escape(pr['url'], quote=True)}">
        <a class="pr-card pr-card--review{row_class}" href="{html.escape(pr['url'], quote=True)}">
          <span class="card-top">
            {tag("Covered" if handled else "Waiting on you", "quiet" if handled else "danger")}
            <span class="date">{requested_label} <time datetime="{html.escape(requested_at)}"></time></span>
          </span>
          <span class="identity">
            <strong>{html.escape(pr['title'])}</strong>
            <small>{html.escape(pr['repository'])} #{pr['number']} by {html.escape(pr['author'])}</small>
          </span>
          <span class="card-bottom"><span class="meta">{''.join(badges)}</span><span class="arrow" aria-hidden="true">→</span></span>
        </a>
        {comment_controls(pr)}
      </article>"""


def comment_controls(pr):
    title = html.escape(pr["title"], quote=True)
    return f"""
        <button class="comment-toggle" type="button" aria-expanded="false" aria-label="Add a local comment for {title}">
          Comment <span class="local-comment-count">0</span>
        </button>
        <div class="jawbone" hidden>
          <div class="local-comments"></div>
          <form class="comment-form" hidden>
            <label class="visually-hidden">Add a local comment for {title}</label>
            <textarea maxlength="2000" rows="3" placeholder="Add a local comment..."></textarea>
            <div class="comment-form-footer">
              <span class="comment-status" aria-live="polite">Stored only in this browser</span>
              <button type="submit">Save comment</button>
            </div>
          </form>
        </div>"""


def empty_row(message):
    return f'<div class="empty">{html.escape(message)}</div>'


def render(model, generated_at, interval):
    authored = "".join(authored_row(pr) for pr in model["authored"]) or empty_row("No open pull requests.")
    requested = "".join(requested_row(pr) for pr in model["requested"]) or empty_row("No reviews waiting on you.")
    authored_limit = model["authored_total"] > len(model["authored"])
    requested_limit = model["requested_total"] > len(model["requested"])
    limit_warning = ""
    if authored_limit or requested_limit:
        limit_warning = '<div class="notice">GitHub returned more than 100 items. Showing the first 100 in affected sections.</div>'

    my_action = sum(pr["css_class"] in {"needs-you", "ready"} for pr in model["authored"])
    waiting = sum(pr["css_class"] == "waiting" for pr in model["authored"])
    reviews_waiting = sum(not pr["other_reviews"] for pr in model["requested"])
    covered = sum(bool(pr["other_reviews"]) for pr in model["requested"])

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Dashboard</title>
  <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='10' fill='%2316181a'/%3E%3Cpath d='M13 13h17v17H13z' fill='%235ef1ff'/%3E%3Cpath d='M34 13h17v17H34z' fill='%23bd5eff'/%3E%3Cpath d='M13 34h17v17H13z' fill='%23ff6e5e'/%3E%3Cpath d='M34 34h17v17H34z' fill='%235eff6c'/%3E%3C/svg%3E">
  <script>document.documentElement.dataset.theme = localStorage.getItem("dashboard-theme") || "dark";</script>
  <style>
    :root {{
      --bg: #16181a; --panel: #1e2124; --highlight: #3c4048; --fg: #ffffff; --muted: #7b8496;
      --blue: #5ea1ff; --green: #5eff6c; --cyan: #5ef1ff; --red: #ff6e5e; --yellow: #f1ff5e;
      --magenta: #ff5ef1; --pink: #ff5ea0; --orange: #ffbd5e; --purple: #bd5eff;
    }}
    :root[data-theme="light"] {{
      --bg: #ffffff; --panel: #eaeaea; --highlight: #acacac; --fg: #16181a; --muted: #7b8496;
      --blue: #0057d1; --green: #008b0c; --cyan: #008c99; --red: #d11500; --yellow: #997b00;
      --magenta: #d100bf; --pink: #f40064; --orange: #d17c00; --purple: #a018ff;
    }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; background: var(--bg); color: var(--fg); font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif; transition: background 160ms ease, color 160ms ease; }}
    main {{ width: min(1600px, calc(100% - 40px)); margin: 0 auto; padding: 24px 0 52px; }}
    .toolbar {{ display: flex; justify-content: flex-end; margin-bottom: 16px; }}
    .theme-toggle {{ appearance: none; padding: 8px 11px; border: 1px solid var(--highlight); background: var(--panel); color: var(--fg); font: 800 .72rem/1 monospace; text-transform: uppercase; letter-spacing: .07em; cursor: pointer; }}
    .theme-toggle:hover, .theme-toggle:focus-visible {{ color: var(--cyan); border-color: var(--cyan); outline: none; }}
    #stale {{ display: none; margin-bottom: 16px; padding: 12px 14px; color: var(--bg); background: var(--yellow); font-weight: 850; }}
    .notice {{ margin-bottom: 16px; padding: 12px 14px; color: var(--yellow); border: 1px solid var(--yellow); font-weight: 750; }}
    .metrics {{ display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin-bottom: 16px; }}
    .metric {{ min-height: 112px; padding: 15px 17px; background: var(--panel); border-top: 4px solid var(--blue); }}
    .metric:nth-child(1) {{ border-color: var(--red); }} .metric:nth-child(2) {{ border-color: var(--yellow); }}
    .metric:nth-child(3) {{ border-color: var(--magenta); }} .metric:nth-child(4) {{ border-color: var(--green); }}
    .metric strong {{ display: block; font-size: 2.8rem; line-height: 1; letter-spacing: -.06em; font-weight: 900; }}
    .metric span {{ display: block; margin-top: 15px; color: var(--muted); font: 800 .68rem/1 monospace; text-transform: uppercase; letter-spacing: .09em; }}
    .queues {{ display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); align-items: start; gap: 16px; }}
    section {{ min-width: 0; padding: 16px; background: var(--panel); }}
    .section-heading {{ display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-bottom: 13px; padding-bottom: 13px; border-bottom: 1px solid var(--highlight); }}
    h2 {{ margin: 0; font-size: clamp(1.45rem, 2.4vw, 2.1rem); line-height: 1; letter-spacing: -.04em; font-weight: 900; }}
    .count {{ color: var(--cyan); font: 850 1rem/1 monospace; }}
    .pr-list {{ display: grid; gap: 8px; }}
    .pr-item {{ position: relative; min-width: 0; }}
    .pr-card {{ position: relative; display: grid; gap: 14px; min-height: 142px; padding: 14px 15px 13px 18px; color: inherit; background: var(--bg); border-left: 4px solid var(--highlight); text-decoration: none; transition: background 120ms ease, border-color 120ms ease, transform 120ms ease; }}
    .pr-card--needs-you, .pr-card--review:not(.pr-card--handled) {{ border-left-color: var(--red); }}
    .pr-card--waiting {{ border-left-color: var(--yellow); }} .pr-card--ready {{ border-left-color: var(--green); }}
    .pr-card--draft {{ border-left-color: var(--muted); opacity: .4; }} .pr-card--draft:hover, .pr-card--draft:focus-visible {{ opacity: .75; }}
    .pr-card:hover, .pr-card:focus-visible {{ background: var(--highlight); border-left-color: var(--cyan); transform: translateX(3px); outline: none; }}
    .pr-card--handled {{ opacity: .4; }} .pr-card--handled:hover, .pr-card--handled:focus-visible {{ opacity: .75; }}
    .card-top, .card-bottom {{ display: flex; align-items: center; justify-content: space-between; gap: 12px; }}
    .identity {{ min-width: 0; }}
    .identity strong {{ display: -webkit-box; overflow: hidden; font-size: 1rem; line-height: 1.28; font-weight: 850; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }}
    .identity small {{ display: block; margin-top: 7px; overflow: hidden; color: var(--muted); font: 700 .72rem/1.2 monospace; text-overflow: ellipsis; white-space: nowrap; }}
    .meta {{ display: flex; flex: 1; flex-wrap: wrap; gap: 5px; padding-right: 98px; }}
    .tag {{ display: inline-block; padding: 4px 6px; border: 1px solid currentColor; font-size: .62rem; font-weight: 850; line-height: 1; text-transform: uppercase; letter-spacing: .045em; white-space: nowrap; }}
    .tag--danger {{ color: var(--red); }} .tag--warning {{ color: var(--yellow); }} .tag--success {{ color: var(--green); }}
    .tag--quiet {{ color: var(--muted); }} .tag--neutral {{ color: var(--blue); }}
    .date {{ color: var(--muted); font-size: .7rem; font-weight: 750; line-height: 1.3; text-align: right; }}
    .arrow {{ color: var(--cyan); font: 900 1rem/1 monospace; }}
    .comment-toggle {{ position: absolute; z-index: 2; top: 105px; right: 43px; padding: 4px 6px; color: var(--purple); background: var(--bg); border: 1px solid var(--purple); font: 850 .62rem/1 monospace; text-transform: uppercase; letter-spacing: .045em; cursor: pointer; }}
    .comment-toggle:hover, .comment-toggle:focus-visible, .comment-toggle[aria-expanded="true"] {{ color: var(--cyan); border-color: var(--cyan); outline: none; }}
    .local-comment-count {{ color: inherit; }}
    .jawbone {{ position: relative; margin-top: 8px; padding: 14px; background: var(--highlight); border-top: 2px solid var(--cyan); }}
    .jawbone[hidden] {{ display: none; }}
    .jawbone::before {{ content: ""; position: absolute; right: 64px; bottom: 100%; border-right: 8px solid transparent; border-bottom: 8px solid var(--cyan); border-left: 8px solid transparent; }}
    .local-comments {{ display: grid; gap: 8px; margin-bottom: 12px; }}
    .local-comments:has(+ .comment-form[hidden]) {{ margin-bottom: 0; }}
    .local-comment {{ padding: 10px 11px; color: var(--fg); background: var(--panel); border-left: 2px solid var(--purple); }}
    .local-comment p {{ margin: 0; font-size: .82rem; font-weight: 650; line-height: 1.45; white-space: pre-wrap; overflow-wrap: anywhere; }}
    .local-comment time {{ display: block; margin-top: 7px; color: var(--muted); font: 700 .62rem/1 monospace; }}
    .no-comments {{ margin: 0 0 12px; color: var(--muted); font-size: .76rem; font-weight: 750; }}
    .comment-form {{ display: grid; gap: 8px; }}
    .comment-form[hidden] {{ display: none; }}
    .comment-form textarea {{ width: 100%; resize: vertical; padding: 9px 10px; color: var(--fg); background: var(--bg); border: 1px solid var(--muted); border-radius: 0; font: inherit; font-size: .82rem; font-weight: 650; line-height: 1.4; }}
    .comment-form textarea:focus {{ border-color: var(--cyan); outline: none; }}
    .comment-form textarea::placeholder {{ color: var(--muted); }}
    .comment-form-footer {{ display: flex; align-items: center; justify-content: space-between; gap: 10px; }}
    .comment-status {{ color: var(--muted); font: 700 .62rem/1.2 monospace; }}
    .comment-form button {{ padding: 7px 9px; color: var(--bg); background: var(--cyan); border: 1px solid var(--cyan); font: 850 .64rem/1 monospace; text-transform: uppercase; letter-spacing: .05em; cursor: pointer; }}
    .comment-form button:hover, .comment-form button:focus-visible {{ color: var(--cyan); background: var(--bg); outline: none; }}
    .visually-hidden {{ position: absolute; width: 1px; height: 1px; padding: 0; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0; }}
    .empty {{ padding: 28px 14px; color: var(--muted); background: var(--bg); font-size: .9rem; font-weight: 750; }}
    footer {{ margin-top: 16px; color: var(--muted); font: 700 .68rem/1.5 monospace; text-align: right; }}
    @media (max-width: 1050px) {{ .queues {{ grid-template-columns: 1fr; }} }}
    @media (max-width: 640px) {{
      main {{ width: min(100% - 20px, 720px); padding-top: 14px; }} .metrics {{ grid-template-columns: 1fr 1fr; gap: 8px; }}
      .metric {{ min-height: 92px; padding: 12px 13px; }} .metric strong {{ font-size: 2.2rem; }} section {{ padding: 11px; }}
      .card-top {{ align-items: flex-start; }} .date {{ max-width: 145px; }} .meta {{ padding-right: 0; }}
      .comment-toggle {{ top: auto; right: 42px; bottom: 12px; }} .pr-item:has(.jawbone:not([hidden])) .comment-toggle {{ bottom: auto; top: 105px; }}
      footer {{ text-align: left; }}
    }}
  </style>
</head>
<body>
  <main>
    <div class="toolbar"><button class="theme-toggle" id="theme-toggle" type="button">Light mode</button></div>
    <div id="stale">This dashboard is stale. Run <code>dash update</code> and inspect <code>dash logs</code> if it stays stale.</div>
    {limit_warning}
    <div class="metrics" aria-label="Dashboard summary">
      <div class="metric"><strong>{my_action}</strong><span>My action</span></div>
      <div class="metric"><strong>{waiting}</strong><span>Waiting</span></div>
      <div class="metric"><strong>{reviews_waiting}</strong><span>Reviews waiting</span></div>
      <div class="metric"><strong>{covered}</strong><span>Covered</span></div>
    </div>
    <div class="queues">
      <section>
        <div class="section-heading"><h2>My pull requests</h2><span class="count">{len(model['authored'])}</span></div>
        <div class="pr-list">{authored}</div>
      </section>
      <section>
        <div class="section-heading"><h2>Review requests</h2><span class="count">{len(model['requested'])}</span></div>
        <div class="pr-list">{requested}</div>
      </section>
    </div>
    <footer>Generated <time id="generated" datetime="{generated_at.isoformat()}"></time>. Refreshes every {interval // 60} minutes.</footer>
  </main>
  <script>
    const generatedAt = new Date({json.dumps(generated_at.isoformat())});
    const themeToggle = document.querySelector("#theme-toggle");
    function updateThemeLabel() {{ themeToggle.textContent = document.documentElement.dataset.theme === "dark" ? "Light mode" : "Dark mode"; }}
    themeToggle.addEventListener("click", () => {{
      const theme = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
      document.documentElement.dataset.theme = theme; localStorage.setItem("dashboard-theme", theme); updateThemeLabel();
    }});
    const commentStorageKey = "dashboard-pr-comments";
    function loadComments() {{
      try {{
        const comments = JSON.parse(localStorage.getItem(commentStorageKey) || "[]");
        return Array.isArray(comments)
          ? comments.filter((comment) => comment && typeof comment.pr === "string" && typeof comment.body === "string" && typeof comment.createdAt === "string")
          : [];
      }} catch {{ return []; }}
    }}
    function commentsFor(prKey) {{
      return loadComments().filter((comment) => comment.pr === prKey).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    }}
    function renderComments(item) {{
      const comments = commentsFor(item.dataset.prKey);
      const count = item.querySelector(".local-comment-count");
      const container = item.querySelector(".local-comments");
      const form = item.querySelector(".comment-form");
      const jawbone = item.querySelector(".jawbone");
      count.textContent = comments.length;
      container.replaceChildren();
      if (!comments.length) {{
        const empty = document.createElement("p"); empty.className = "no-comments"; empty.textContent = "No local comments yet."; container.append(empty);
        jawbone.hidden = form.hidden;
        return;
      }}
      comments.forEach((comment) => {{
        const entry = document.createElement("div"); entry.className = "local-comment";
        const body = document.createElement("p"); body.textContent = comment.body;
        const time = document.createElement("time"); time.dateTime = comment.createdAt;
        entry.append(body, time); container.append(entry);
      }});
      jawbone.hidden = false;
    }}
    function renderAllComments() {{ document.querySelectorAll(".pr-item").forEach(renderComments); updateTimes(); }}
    document.querySelectorAll(".pr-item").forEach((item) => {{
      const toggle = item.querySelector(".comment-toggle");
      const jawbone = item.querySelector(".jawbone");
      const form = item.querySelector(".comment-form");
      const textarea = form.querySelector("textarea");
      const status = form.querySelector(".comment-status");
      toggle.addEventListener("click", () => {{
        const opening = form.hidden; form.hidden = !opening; jawbone.hidden = !opening && !commentsFor(item.dataset.prKey).length;
        toggle.setAttribute("aria-expanded", String(opening));
        if (opening) textarea.focus();
      }});
      form.addEventListener("submit", (event) => {{
        event.preventDefault();
        const body = textarea.value.trim();
        if (!body) {{ status.textContent = "Write a comment first"; textarea.focus(); return; }}
        const retained = loadComments().sort((a, b) => b.createdAt.localeCompare(a.createdAt)).slice(0, 49);
        retained.unshift({{ pr: item.dataset.prKey, body, createdAt: new Date().toISOString() }});
        try {{
          localStorage.setItem(commentStorageKey, JSON.stringify(retained));
          textarea.value = ""; status.textContent = "Stored only in this browser"; form.hidden = true;
          toggle.setAttribute("aria-expanded", "false"); renderAllComments();
        }} catch {{ status.textContent = "Could not save comment"; }}
      }});
    }});
    window.addEventListener("storage", (event) => {{ if (event.key === commentStorageKey) renderAllComments(); }});
    const relative = new Intl.RelativeTimeFormat(undefined, {{ numeric: "auto" }});
    function relativeTime(date) {{
      const seconds = Math.round((date - Date.now()) / 1000);
      const units = [["year", 31536000], ["month", 2592000], ["week", 604800], ["day", 86400], ["hour", 3600], ["minute", 60]];
      for (const [unit, size] of units) if (Math.abs(seconds) >= size || unit === "minute") return relative.format(Math.round(seconds / size), unit);
    }}
    function updateTimes() {{
      document.querySelectorAll("time[datetime]").forEach((element) => {{
        const date = new Date(element.dateTime);
        if (!Number.isNaN(date.valueOf())) {{ element.textContent = relativeTime(date); element.title = date.toLocaleString(); }}
      }});
      document.querySelector("#stale").style.display = Date.now() - generatedAt > {interval * 2 * 1000} ? "block" : "none";
    }}
    updateThemeLabel(); renderAllComments(); setInterval(updateTimes, 60000);
  </script>
</body>
</html>
"""


def fetch_payload(input_path=None):
    if input_path:
        return json.loads(Path(input_path).read_text())

    def gh_json(arguments):
        result = subprocess.run(["gh", *arguments], capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or f"gh exited with status {result.returncode}")
        return json.loads(result.stdout)

    teams = gh_json(["api", "user/teams", "--paginate", "--slurp"])
    payload = gh_json(["api", "graphql", "-f", f"query={QUERY}"])
    payload["viewerTeamIds"] = [team["node_id"] for page in teams for team in page if team.get("node_id")]
    return payload


def write_atomic(output, content):
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=output.parent, delete=False, encoding="utf-8") as temporary:
        temporary.write(content)
        temporary.flush()
        os.fsync(temporary.fileno())
        temporary_path = Path(temporary.name)
    temporary_path.chmod(0o644)
    temporary_path.replace(output)


def main(argv=None):
    home = Path.home()
    parser = argparse.ArgumentParser(description="Generate the local dashboard")
    parser.add_argument("--input", help="Read a saved GraphQL response instead of calling gh")
    parser.add_argument("--interval", type=int, default=300)
    parser.add_argument("--output", type=Path, default=home / ".local/share/dashboard/index.html")
    parser.add_argument("--state-dir", type=Path, default=home / ".local/state/dashboard")
    args = parser.parse_args(argv)

    args.state_dir.mkdir(parents=True, exist_ok=True)
    with (args.state_dir / "generate.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("Dashboard generation is already in progress")
            return 0

        generated_at = datetime.now(timezone.utc)
        model = build_model(fetch_payload(args.input))
        write_atomic(args.output, render(model, generated_at, args.interval))
        print(f"Updated {args.output} with {len(model['authored'])} authored PRs and {len(model['requested'])} review requests")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (json.JSONDecodeError, OSError, RuntimeError, ValueError) as error:
        print(f"Dashboard update failed: {error}", file=sys.stderr)
        raise SystemExit(1)
