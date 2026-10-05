// Tests for roles/agents/files/opencode/lib/review-loop-core.ts
//
// Usage: bun test roles/agents/tests

import { describe, expect, test } from "bun:test"
import * as core from "../files/opencode/lib/review-loop-core.ts"

describe("detectFeedbackRead", () => {
  test("recognises gh commands that load review feedback", () => {
    expect(core.detectFeedbackRead("gh pr view 123 --comments")).toEqual({ ref: "123", repo: undefined })
    expect(core.detectFeedbackRead("gh pr view --json reviews,comments")).toEqual({ ref: undefined, repo: undefined })
    expect(core.detectFeedbackRead("gh pr view 7 -R acme/app --json reviewThreads")).toEqual({ ref: "7", repo: "acme/app" })
    expect(core.detectFeedbackRead("gh api repos/acme/app/pulls/42/comments --paginate")).toEqual({ ref: "42", repo: "acme/app" })
    expect(core.detectFeedbackRead("gh pr view https://github.com/acme/app/pull/9 --comments")).toEqual({
      ref: "https://github.com/acme/app/pull/9",
    })
    expect(core.detectFeedbackRead(`gh api graphql -f query='{ repository(owner:"a",name:"b"){ pullRequest(number:1){ reviewThreads(first:10){nodes{id}} } } }'`)).not.toBeNull()
    expect(core.detectFeedbackRead("pr-context threads acme/app#5")).toEqual({ ref: "acme/app#5" })
  })

  test("ignores unrelated commands", () => {
    expect(core.detectFeedbackRead("gh pr view 123")).toBeNull()
    expect(core.detectFeedbackRead("gh pr diff 123")).toBeNull()
    expect(core.detectFeedbackRead("git log --oneline")).toBeNull()
  })
})

describe("footer", () => {
  const receipts = [
    { id: "fb-1", notice: "Preserve authorization checks before returning cached results" },
    { id: "fb-2", notice: "Test cancellation during concurrent refresh operations" },
    { id: "fb-1", notice: "Preserve authorization checks before returning cached results" },
  ]

  test("formats unique notices under the title", () => {
    expect(core.formatFooter(receipts)).toBe(
      "💡 feedback captured\n- Preserve authorization checks before returning cached results\n- Test cancellation during concurrent refresh operations",
    )
    expect(core.formatFooter([])).toBe("")
  })

  test("appends a footer when missing", () => {
    const out = core.appendFooter("Done.", receipts)!
    expect(out.endsWith("- Test cancellation during concurrent refresh operations")).toBe(true)
    expect(out.startsWith("Done.\n\n💡 feedback captured")).toBe(true)
  })

  test("leaves a complete footer alone and fills a partial one", () => {
    const complete = `Done.\n\n${core.formatFooter(receipts)}`
    expect(core.appendFooter(complete, receipts)).toBeNull()
    const partial = "Done.\n\n💡 feedback captured\n- Preserve authorization checks before returning cached results."
    expect(core.appendFooter(partial, receipts)).toBe(`${partial}\n- Test cancellation during concurrent refresh operations`)
  })
})

describe("findings", () => {
  test("counts by severity with stable keys", () => {
    expect(core.countFindings([{ severity: "major", title: "a" }, { severity: "nit", title: "b" }, { severity: "major", title: "c" }])).toEqual({
      blocker: 0,
      major: 2,
      minor: 0,
      nit: 1,
      question: 0,
    })
    expect(core.formatCounts({ blocker: 0, major: 2, nit: 1 })).toBe("2 major, 1 nit")
    expect(core.formatCounts({})).toBe("no findings")
  })

  test("formats a run record compactly", () => {
    const line = core.formatRun({
      run_id: "pr-9-x",
      pr: 9,
      title: "Fix cache",
      status: "completed",
      tmux_session: "hex/review/pr-9",
      action: "launched",
      result: { verdict: "comment", summary: "Looks solid.", counts: { major: 1 } },
    })
    expect(line).toContain("#9 Fix cache — launched: completed · session hex/review/pr-9")
    expect(line).toContain("comment · 1 major · Looks solid.")
  })
})
