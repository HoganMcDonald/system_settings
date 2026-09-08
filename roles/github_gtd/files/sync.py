#!/usr/bin/env python3

import argparse
import fcntl
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, time, timedelta, timezone
from pathlib import Path


API_URL = "https://api.todoist.com/api/v1"
SOURCE_LABEL = "github"
CONTEXT_LABELS = {"needs-review", "fixup", "needs-merge"}
MARKER_RE = re.compile(r"^GTD Sync: (github-gtd:v1:[^\s]+)$", re.MULTILINE)

SEARCH_QUERY = r"""
query PullRequests($searchQuery: String!, $cursor: String) {
  viewer { login }
  search(type: ISSUE, query: $searchQuery, first: 100, after: $cursor) {
    issueCount
    pageInfo { hasNextPage endCursor }
    nodes {
      ... on PullRequest {
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
        statusCheckRollup { state }
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
    }
  }
}
"""


def parse_time(value):
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def format_time(value):
    return value.astimezone(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def add_weekday_hours(start, hours, local_timezone=None):
    local_timezone = local_timezone or datetime.now().astimezone().tzinfo
    cursor = start.astimezone(local_timezone)
    remaining = hours * 3600

    while remaining:
        tomorrow = cursor.date() + timedelta(days=1)
        boundary = datetime.combine(tomorrow, time.min, tzinfo=local_timezone)
        if cursor.weekday() >= 5:
            cursor = boundary
            continue

        available = int((boundary.astimezone(timezone.utc) - cursor.astimezone(timezone.utc)).total_seconds())
        consumed = min(remaining, available)
        cursor = (cursor.astimezone(timezone.utc) + timedelta(seconds=consumed)).astimezone(local_timezone)
        remaining -= consumed

    return cursor


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


def request_time(pr, viewer, viewer_team_ids):
    current = {
        reviewer_key(node.get("requestedReviewer"))
        for node in (pr.get("reviewRequests") or {}).get("nodes", [])
        if node.get("requestedReviewer")
        and (
            node["requestedReviewer"].get("login", "").lower() == viewer.lower()
            or node["requestedReviewer"].get("id") in viewer_team_ids
        )
    }
    current.discard(None)
    matching = [
        event["createdAt"]
        for event in (pr.get("timelineItems") or {}).get("nodes", [])
        if reviewer_key(event.get("requestedReviewer")) in current and event.get("createdAt")
    ]
    return max(matching, key=lambda value: parse_time(value) or datetime.min.replace(tzinfo=timezone.utc)) if matching else None


def ci_state(pr):
    return ((pr.get("statusCheckRollup") or {}).get("state") or "NONE").upper()


def authored_context(pr):
    if pr.get("isDraft"):
        return None, None
    if pr.get("reviewDecision") == "CHANGES_REQUESTED":
        return "fixup", "changes requested"
    if pr.get("mergeable") == "CONFLICTING" or pr.get("mergeStateStatus") == "DIRTY":
        return "fixup", "merge conflicts"
    if ci_state(pr) in {"FAILURE", "ERROR"}:
        return "fixup", "failing CI"
    if (
        pr.get("reviewDecision") == "APPROVED"
        and pr.get("mergeable") == "MERGEABLE"
        and ci_state(pr) in {"SUCCESS", "NONE"}
        and pr.get("mergeStateStatus") in {"CLEAN", "HAS_HOOKS", "UNSTABLE"}
    ):
        return "needs-merge", "approved and ready"
    return None, None


def task_marker(task):
    match = MARKER_RE.search(task.get("description") or "")
    return match.group(1) if match else None


def default_state():
    return {"version": 1, "tasks": {}, "acknowledged": [], "contexts": {}}


def hydrate_state_from_tasks(state, active_tasks, completed_tasks):
    contexts = state.setdefault("contexts", {})
    for task in [*active_tasks, *completed_tasks]:
        marker = task_marker(task)
        if not marker:
            continue
        match = re.match(r"^github-gtd:v1:([^:]+):(fixup|needs-merge):(\d+)$", marker)
        if not match:
            continue
        node_id, context, generation = match.groups()
        base = f"{node_id}:{context}"
        episode = contexts.setdefault(base, {"active": True, "generation": 0})
        episode["generation"] = max(int(episode.get("generation", 0)), int(generation))


def build_actions(payload, state, sla_hours=24, local_timezone=None):
    viewer = payload.get("viewer")
    if not viewer:
        raise ValueError("GitHub response did not include the authenticated viewer")

    actions = {}
    team_ids = set(payload.get("viewerTeamIds") or [])
    for pr in payload.get("requested", []):
        if pr.get("isDraft"):
            continue
        requested_at = request_time(pr, viewer, team_ids)
        requested = parse_time(requested_at)
        if not requested:
            raise ValueError(f"Review request for {pr.get('url')} has no timestamp")
        action_id = f"github-gtd:v1:{pr['id']}:needs-review:{requested_at}"
        actions[action_id] = make_action(
            action_id,
            pr,
            "needs-review",
            "Review",
            f"Review requested {requested_at}",
            due_datetime=format_time(add_weekday_hours(requested, sla_hours, local_timezone)),
        )

    active_contexts = set()
    contexts = state.setdefault("contexts", {})
    for pr in payload.get("authored", []):
        context, reason = authored_context(pr)
        if not context:
            continue
        base = f"{pr['id']}:{context}"
        active_contexts.add(base)
        episode = contexts.setdefault(base, {"active": False, "generation": 0})
        if not episode.get("active"):
            episode["generation"] = int(episode.get("generation", 0)) + 1
        episode["active"] = True
        action_id = f"github-gtd:v1:{pr['id']}:{context}:{episode['generation']}"
        verb = "Fix" if context == "fixup" else "Merge"
        actions[action_id] = make_action(action_id, pr, context, verb, reason)

    for base, episode in contexts.items():
        if base not in active_contexts:
            episode["active"] = False
    return actions


def make_action(action_id, pr, context, verb, reason, due_datetime=None):
    repository = (pr.get("repository") or {}).get("nameWithOwner") or "unknown"
    author = (pr.get("author") or {}).get("login") or "ghost"
    description = "\n".join(
        [
            pr["url"],
            f"GitHub state: {reason}",
            f"Author: @{author}",
            f"GTD Sync: {action_id}",
        ]
    )
    return {
        "id": action_id,
        "content": f"{verb} {repository}#{pr['number']}: {pr.get('title') or 'Untitled pull request'}",
        "description": description,
        "context": context,
        "due_datetime": due_datetime,
    }


def plan_reconciliation(actions, active_tasks, completed_tasks, state):
    acknowledged = set(state.get("acknowledged") or [])
    tracked = state.setdefault("tasks", {})
    completed_markers = {marker for task in completed_tasks if (marker := task_marker(task))}
    acknowledged.update(completed_markers)

    active_by_marker = {}
    operations = []
    for task in active_tasks:
        marker = task_marker(task)
        if not marker:
            continue
        if marker in active_by_marker:
            operations.append({"operation": "close", "task_id": task["id"], "action_id": marker})
            continue
        active_by_marker[marker] = task
        acknowledged.discard(marker)
        tracked[marker] = task["id"]

    for action_id, task_id in list(tracked.items()):
        if action_id not in active_by_marker and action_id not in completed_markers:
            acknowledged.add(action_id)

    for action_id, task in active_by_marker.items():
        action = actions.get(action_id)
        if not action:
            operations.append({"operation": "close", "task_id": task["id"], "action_id": action_id})
            continue
        current_labels = set(task.get("labels") or [])
        desired_labels = (current_labels - CONTEXT_LABELS) | {SOURCE_LABEL, action["context"]}
        if desired_labels != current_labels:
            operations.append(
                {
                    "operation": "update-labels",
                    "task_id": task["id"],
                    "action_id": action_id,
                    "labels": sorted(desired_labels),
                }
            )

    for action_id, action in actions.items():
        if action_id in active_by_marker or action_id in acknowledged:
            continue
        operations.append({"operation": "create", "action_id": action_id, "action": action})

    state["acknowledged"] = sorted(acknowledged)
    return operations


class TodoistClient:
    def __init__(self, token, api_url=API_URL):
        self.token = token
        self.api_url = api_url.rstrip("/")

    def request(self, method, path, body=None, query=None):
        url = f"{self.api_url}{path}"
        if query:
            url = f"{url}?{urllib.parse.urlencode(query)}"
        data = json.dumps(body).encode() if body is not None else None
        request = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={"Authorization": f"Bearer {self.token}", "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                content = response.read()
                return json.loads(content) if content else None
        except urllib.error.HTTPError as error:
            detail = error.read().decode(errors="replace")
            try:
                parsed = json.loads(detail)
                reason = parsed.get("error_tag") or parsed.get("error") or "request rejected"
            except json.JSONDecodeError:
                reason = "request rejected"
            raise RuntimeError(f"Todoist {method} {path} failed with HTTP {error.code}: {reason}") from error
        except urllib.error.URLError as error:
            raise RuntimeError(f"Todoist {method} {path} failed: {error.reason}") from error

    def paginated(self, path, query=None, result_keys=("results", "items")):
        cursor = None
        values = []
        while True:
            page_query = dict(query or {})
            page_query["limit"] = 200
            if cursor:
                page_query["cursor"] = cursor
            payload = self.request("GET", path, query=page_query)
            if isinstance(payload, list):
                values.extend(payload)
                break
            if not isinstance(payload, dict):
                raise RuntimeError(f"Todoist GET {path} returned an invalid response")
            page_values = next((payload.get(key) for key in result_keys if key in payload), [])
            values.extend(page_values or [])
            cursor = payload.get("next_cursor")
            if not cursor:
                break
        return values

    def active_tasks(self):
        return self.paginated("/tasks")

    def completed_tasks(self, full_history=False):
        now = datetime.now(timezone.utc)
        oldest = datetime(2015, 1, 1, tzinfo=timezone.utc) if full_history else now - timedelta(days=90)
        completed = []
        end = now + timedelta(seconds=1)
        while end > oldest:
            start = max(oldest, end - timedelta(days=89))
            completed.extend(
                self.paginated(
                    "/tasks/completed/by_completion_date",
                    query={
                        "since": format_time(start),
                        "until": format_time(end),
                        "filter_query": f"@{SOURCE_LABEL}",
                        "filter_lang": "en",
                    },
                )
            )
            end = start
        return completed

    def labels(self):
        return self.paginated("/labels")

    def create_label(self, name):
        return self.request("POST", "/labels", {"name": name})

    def create_task(self, action):
        body = {
            "content": action["content"],
            "description": action["description"],
            "labels": [SOURCE_LABEL, action["context"]],
        }
        if action.get("due_datetime"):
            body["due_datetime"] = action["due_datetime"]
        return self.request("POST", "/tasks", body)

    def update_labels(self, task_id, labels):
        return self.request("POST", f"/tasks/{task_id}", {"labels": labels})

    def close_task(self, task_id):
        return self.request("POST", f"/tasks/{task_id}/close")


def gh_json(arguments):
    result = subprocess.run(["gh", *arguments], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or f"gh exited with status {result.returncode}")
    return json.loads(result.stdout)


def fetch_github():
    teams = gh_json(["api", "user/teams", "--paginate", "--slurp"])

    def search(query):
        cursor = None
        nodes = []
        viewer = None
        while True:
            arguments = ["api", "graphql", "-f", f"query={SEARCH_QUERY}", "-F", f"searchQuery={query}"]
            if cursor:
                arguments.extend(["-F", f"cursor={cursor}"])
            response = gh_json(arguments)
            data = response.get("data") or {}
            viewer = viewer or (data.get("viewer") or {}).get("login")
            page = data.get("search") or {}
            if int(page.get("issueCount") or 0) >= 1000:
                raise RuntimeError(f"GitHub search reached its 1,000-result safety limit: {query}")
            nodes.extend(node for node in page.get("nodes", []) if node)
            page_info = page.get("pageInfo") or {}
            if not page_info.get("hasNextPage"):
                return viewer, nodes
            cursor = page_info.get("endCursor")
            if not cursor:
                raise RuntimeError("GitHub pagination ended without a cursor")

    viewer, authored = search("is:pr is:open author:@me archived:false")
    requested_viewer, requested = search("is:pr is:open review-requested:@me archived:false")
    if requested_viewer and viewer != requested_viewer:
        raise RuntimeError("GitHub viewer changed during synchronization")
    return {
        "viewer": viewer,
        "authored": authored,
        "requested": requested,
        "viewerTeamIds": [team["node_id"] for page in teams for team in page if team.get("node_id")],
    }


def read_token():
    if os.environ.get("TODOIST_API_TOKEN"):
        return os.environ["TODOIST_API_TOKEN"]
    result = subprocess.run(
        [
            "/usr/bin/security",
            "find-generic-password",
            "-w",
            "-a",
            os.environ.get("USER", ""),
            "-s",
            "com.hoganmcdonald.github-gtd.todoist",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise RuntimeError("Todoist token not found in macOS Keychain; run `github-gtd auth`")
    return result.stdout.strip()


def load_state(path):
    if not path.exists():
        return default_state()
    state = json.loads(path.read_text())
    if state.get("version") != 1:
        raise ValueError(f"Unsupported state version in {path}")
    return state


def write_atomic(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False, encoding="utf-8") as temporary:
        json.dump(payload, temporary, indent=2, sort_keys=True)
        temporary.write("\n")
        temporary.flush()
        os.fsync(temporary.fileno())
        temporary_path = Path(temporary.name)
    temporary_path.chmod(0o600)
    temporary_path.replace(path)


def ensure_labels(client, dry_run=False):
    existing = {label.get("name") for label in client.labels()}
    for label in sorted(({SOURCE_LABEL} | CONTEXT_LABELS) - existing):
        print(f"create label @{label}")
        if not dry_run:
            client.create_label(label)


def apply_operations(client, operations, state, dry_run=False):
    for operation in operations:
        action_id = operation["action_id"]
        kind = operation["operation"]
        if kind == "create":
            action = operation["action"]
            print(f"create @{action['context']}: {action['content']}")
            if not dry_run:
                task = client.create_task(action)
                state["tasks"][action_id] = task["id"]
        elif kind == "update-labels":
            print(f"update labels for {operation['task_id']}: {', '.join(operation['labels'])}")
            if not dry_run:
                client.update_labels(operation["task_id"], operation["labels"])
        elif kind == "close":
            print(f"complete resolved action {operation['task_id']}")
            if not dry_run:
                client.close_task(operation["task_id"])


def doctor(client):
    github = subprocess.run(["gh", "auth", "status"], capture_output=True, text=True)
    if github.returncode:
        raise RuntimeError(github.stderr.strip() or "GitHub authentication failed")
    labels = {label.get("name") for label in client.labels()}
    print("GitHub authentication: ok")
    print("Todoist authentication: ok")
    missing = sorted(({SOURCE_LABEL} | CONTEXT_LABELS) - labels)
    print(f"Todoist labels: {'missing ' + ', '.join(missing) if missing else 'ok'}")
    return 1 if missing else 0


def main(argv=None):
    home = Path.home()
    parser = argparse.ArgumentParser(description="Synchronize actionable GitHub PRs into Todoist")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--check-auth", action="store_true")
    parser.add_argument("--status", action="store_true")
    parser.add_argument("--github-input", type=Path, help="Use saved GitHub JSON instead of gh")
    parser.add_argument("--sla-hours", type=int, default=24)
    parser.add_argument("--state-dir", type=Path, default=home / ".local/state/github-gtd")
    args = parser.parse_args(argv)

    args.state_dir.mkdir(parents=True, exist_ok=True)
    state_path = args.state_dir / "state.json"
    state_exists = state_path.exists()
    if args.status:
        state = load_state(state_path)
        print(state.get("last_success", "never"))
        return 0

    with (args.state_dir / "sync.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("GitHub GTD synchronization is already in progress")
            return 0

        client = TodoistClient(read_token())
        if args.check_auth:
            client.labels()
            print("Todoist authentication: ok")
            return 0
        if args.doctor:
            return doctor(client)

        state = load_state(state_path)
        payload = json.loads(args.github_input.read_text()) if args.github_input else fetch_github()

        # Complete both remote reads before allowing any Todoist writes.
        active_tasks = client.active_tasks()
        completed_tasks = client.completed_tasks(full_history=not state_exists)
        hydrate_state_from_tasks(state, active_tasks, completed_tasks)
        actions = build_actions(payload, state, args.sla_hours)
        operations = plan_reconciliation(actions, active_tasks, completed_tasks, state)
        ensure_labels(client, args.dry_run)
        apply_operations(client, operations, state, args.dry_run)

        if not args.dry_run:
            state["last_success"] = format_time(datetime.now(timezone.utc))
            write_atomic(state_path, state)
        print(f"Sync complete: {len(actions)} actionable, {len(operations)} change(s)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (json.JSONDecodeError, OSError, RuntimeError, ValueError) as error:
        print(f"GitHub GTD sync failed: {error}", file=sys.stderr)
        raise SystemExit(1)
