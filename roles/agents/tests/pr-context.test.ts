// Tests for the pure helpers in roles/agents/files/opencode/lib/pr-context.ts
//
// Usage: bun test roles/agents/tests

import { describe, expect, test } from "bun:test"
import * as prc from "../files/opencode/lib/pr-context.ts"

const ref = prc.parsePrUrl("https://github.com/acme/app/pull/42/files")!

describe("parsePrUrl", () => {
  test("normalises tabs and anchors away", () => {
    expect(ref).toEqual({ owner: "acme", name: "app", repo: "acme/app", number: 42, url: "https://github.com/acme/app/pull/42" })
    expect(prc.parsePrUrl("https://github.com/acme/app/issues/42")).toBeNull()
  })
})

describe("extractLinearIds", () => {
  test("finds ids in titles, branches, and links", () => {
    expect(prc.extractLinearIds(["HEX-123: fix cache", "hogan/hex-456-thing", "see https://linear.app/hex/issue/ENG-9/x"])).toEqual([
      "HEX-123",
      "HEX-456",
      "ENG-9",
    ])
  })

  test("ignores encodings and lowercase prose", () => {
    expect(prc.extractLinearIds(["Use UTF-8 and SHA-256 everywhere", "a well-1 known thing"])).toEqual([])
  })
})

describe("sliceDiff", () => {
  const patch = [
    "diff --git a/src/a.ts b/src/a.ts\n--- a/src/a.ts\n+++ b/src/a.ts\n@@ -1 +1 @@\n-a\n+b\n",
    "diff --git a/src/b.ts b/src/b.ts\n--- a/src/b.ts\n+++ b/src/b.ts\n@@ -1 +1 @@\n-c\n+d\n",
  ].join("")

  test("filters to one file", () => {
    const out = prc.sliceDiff(patch, { path: "src/b.ts" })
    expect(out).toContain("+d")
    expect(out).not.toContain("+b")
  })

  test("paginates long diffs with a continuation hint", () => {
    const long = patch.repeat(500)
    const out = prc.sliceDiff(long, { limit: 2000 })
    expect(out).toContain("continue with offset=2000")
  })
})

describe("formatDiscussion", () => {
  const d: prc.Discussion = {
    ref,
    author: "hoganmcdonald",
    head_sha: "abcdef1234567890",
    bot_comments_hidden: 1,
    threads: [
      {
        id: "PRRT_resolved",
        path: "src/a.ts",
        line: 3,
        original_line: 3,
        resolved: true,
        outdated: false,
        resolved_by: "hoganmcdonald",
        hunk: "@@ -1 +1 @@\n+x",
        comments: [{ id: "c1", url: "https://github.com/acme/app/pull/42#discussion_r1", author: "alice", body: "nit", created: "2026-10-01T00:00:00Z", outdated: false }],
      },
      {
        id: "PRRT_open",
        path: "src/b.ts",
        line: null,
        original_line: 9,
        resolved: false,
        outdated: true,
        hunk: "",
        comments: [{ id: "c2", url: "https://github.com/acme/app/pull/42#discussion_r2", author: "bob", body: "this races", created: "2026-10-02T00:00:00Z", outdated: true }],
      },
    ],
    comments: [],
    reviews: [{ id: "PRR_1", url: "https://github.com/acme/app/pull/42#pullrequestreview-1", author: "bob", body: "Mostly good", created: "2026-10-02T00:00:00Z", outdated: false, state: "COMMENTED" }],
  }

  test("lists open threads first with source keys", () => {
    const out = prc.formatDiscussion(d)
    expect(out.indexOf("PRRT_open")).toBeLessThan(out.indexOf("PRRT_resolved"))
    expect(out).toContain("source_key: github:acme/app#42:thread:PRRT_open")
    expect(out).toContain("src/b.ts:9 (original line)")
    expect(out).toContain("1 bot comments hidden")
    expect(out).toContain("github:acme/app#42:review:PRR_1")
  })

  test("filters by state", () => {
    const out = prc.formatDiscussion(d, { state: "open" })
    expect(out).not.toContain("PRRT_resolved")
  })
})

describe("numberLines", () => {
  test("windows and points at the next page", () => {
    const text = Array.from({ length: 10 }, (_, i) => `line ${i + 1}`).join("\n")
    const out = prc.numberLines(text, 3, 4)
    expect(out).toContain("    3  line 3")
    expect(out).toContain("continue with start=5")
  })
})
