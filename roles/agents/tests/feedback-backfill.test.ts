// Tests for the pure helpers in roles/agents/files/opencode/lib/feedback-backfill.ts
//
// Usage: bun test roles/agents/tests

import { describe, expect, test } from "bun:test"
import * as bf from "../files/opencode/lib/feedback-backfill.ts"

const user = (login: string) => ({ login, __typename: "User" })
const botUser = (login: string) => ({ login, __typename: "Bot" })

describe("countFeedback", () => {
  test("separates human, bot, and own comments", () => {
    const node = {
      reviewThreads: {
        nodes: [
          { comments: { nodes: [{ author: user("alice") }] } },
          { comments: { nodes: [{ author: botUser("cursor") }] } },
          { comments: { nodes: [{ author: user("HoganMcDonald") }] } },
        ],
      },
      reviews: { nodes: [{ body: "LGTM with nits", author: user("bob") }, { body: "", author: user("carol") }, { body: "Summary", author: botUser("coderabbitai") }] },
      comments: { nodes: [{ body: "thanks", author: user("hoganmcdonald") }, { body: "can we split this?", author: user("dave") }] },
    }
    expect(bf.countFeedback(node, "hoganmcdonald")).toEqual({ human_threads: 1, bot_threads: 1, human_comments: 2 })
  })
})

const pr = (number: number, merged_at: string, status: bf.BackfillPr["status"] = "pending"): bf.BackfillPr => ({
  number,
  url: `https://github.com/acme/app/pull/${number}`,
  title: `PR ${number}`,
  merged_at,
  human_threads: 1,
  bot_threads: 0,
  human_comments: 0,
  status,
  attempts: 0,
})

describe("mergePlan", () => {
  test("keeps progress, requeues interrupted runs, and sorts oldest first", () => {
    const previous = [pr(2, "2026-02-01", "done"), pr(3, "2026-03-01", "running"), pr(9, "2025-12-01", "done")]
    const fresh = [pr(3, "2026-03-01"), pr(2, "2026-02-01"), pr(1, "2026-01-15")].map(({ status, attempts, ...p }) => p)
    const merged = bf.mergePlan(previous, fresh)
    expect(merged.map((p) => [p.number, p.status])).toEqual([
      [9, "done"],
      [1, "pending"],
      [2, "done"],
      [3, "pending"],
    ])
  })
})

describe("selectPrs", () => {
  const state: bf.BackfillState = {
    repo: "acme/app",
    author: "hoganmcdonald",
    since: "2026-01-01",
    planned_at: "",
    prs: [pr(1, "2026-01-02", "done"), pr(2, "2026-01-03", "failed"), pr(3, "2026-01-04"), pr(4, "2026-01-05")],
  }

  test("takes pending PRs in order, honouring limit and retries", () => {
    expect(bf.selectPrs(state, {}).map((p) => p.number)).toEqual([3, 4])
    expect(bf.selectPrs(state, { limit: 1 }).map((p) => p.number)).toEqual([3])
    expect(bf.selectPrs(state, { retryFailed: true }).map((p) => p.number)).toEqual([2, 3, 4])
  })

  test("explicit PRs run regardless of status but must be planned", () => {
    expect(bf.selectPrs(state, { prs: [4, 1] }).map((p) => p.number)).toEqual([1, 4])
    expect(() => bf.selectPrs(state, { prs: [99] })).toThrow(/not in the plan/)
  })
})

describe("summarizeResults", () => {
  test("counts unique captures and detects processed PRs", () => {
    const s = bf.summarizeResults([
      { kind: "created", id: "fb-1" },
      { kind: "needs_decision" },
      { kind: "merged", id: "fb-2" },
      { kind: "merged", id: "fb-2" },
      { kind: "unchanged", id: "fb-3" },
    ])
    expect(s.captured).toBe(2)
    expect(s.processed).toBe(true)
    expect(s.results).toEqual({ created: 1, needs_decision: 1, merged: 2, unchanged: 1 })
    expect(bf.summarizeResults([{ kind: "error" }]).processed).toBe(false)
    expect(bf.summarizeResults([{ kind: "reviewed" }]).processed).toBe(true)
  })
})

describe("monthsAgo", () => {
  test("counts back calendar months", () => {
    expect(bf.monthsAgo(9, new Date("2026-10-06T12:00:00Z"))).toBe("2026-01-06")
  })
})
