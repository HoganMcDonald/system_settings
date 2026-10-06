// Tests for roles/agents/files/opencode/lib/feedback-store.ts
//
// Usage: bun test roles/agents/tests

import { afterEach, beforeEach, describe, expect, test } from "bun:test"
import { mkdtemp, readFile, readdir, rm, symlink, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import * as fb from "../files/opencode/lib/feedback-store.ts"

let home: string

beforeEach(async () => {
  home = await mkdtemp(join(tmpdir(), "feedback-test-"))
  process.env.FEEDBACK_HOME = join(home, "store")
})

afterEach(async () => {
  delete process.env.FEEDBACK_HOME
  await rm(home, { recursive: true, force: true })
})

const PR = "https://github.com/acme/app/pull/123"
const REPO = "acme/app"

// Every entry file in the store, relative to entries/.
async function entryFiles(): Promise<string[]> {
  const root = join(process.env.FEEDBACK_HOME!, "entries")
  const out: string[] = []
  const walk = async (dir: string, rel: string) => {
    for (const d of await readdir(dir, { withFileTypes: true })) {
      if (d.isDirectory()) await walk(join(dir, d.name), rel ? `${rel}/${d.name}` : d.name)
      else if (d.name.endsWith(".md")) out.push(rel ? `${rel}/${d.name}` : d.name)
    }
  }
  await walk(root, "")
  return out.sort()
}

function cacheAuth(key = "github:acme/app#123:thread:PRRT_1") {
  return {
    source: {
      key,
      pr: PR,
      url: `${PR}#discussion_r1`,
      reviewer: "alice",
      thread_state: "open" as const,
      disposition: "pending" as const,
      excerpt: "This returns the cached value before checking the viewer can see it.",
    },
    entry: {
      title: "Check authorization before serving cached results",
      notice: "Preserve authorization checks before returning cached results",
      summary: "Cache hits must not bypass current access checks.",
      kind: "security",
      confidence: "confirmed",
      scope: { level: "repository" as const, repos: ["acme/app"], languages: ["typescript"], subsystems: ["query-cache"] },
      concepts: ["authorization", "caching"],
      aliases: ["authz", "permissions", "access control", "cache hit", "stale permissions", "tenant isolation"],
      symbols: ["getCachedResult", "authorize_query"],
      paths: ["src/cache/**"],
      lesson: "Evaluate current access before returning a cached result.",
      applies_when: "A cached response contains user- or tenant-scoped data.",
      why: "Permissions can change while cached results remain available.",
      check: "Trace both cache-hit and cache-miss paths through authorization.",
      exceptions: "Public, non-user-scoped data.",
    },
  }
}

describe("tokenize", () => {
  test("splits identifiers and keeps compounds", () => {
    const t = fb.tokenize("getCachedResult in src/cache_layer.ts")
    expect(t).toContain("getcachedresult")
    expect(t).toContain("cach")
    expect(t).toContain("result")
    expect(t).toContain("cachelayer")
  })

  test("stems plurals and gerunds", () => {
    expect(fb.stem("caching")).toBe("cach")
    expect(fb.stem("cached")).toBe("cach")
    expect(fb.stem("queries")).toBe("query")
    expect(fb.stem("results")).toBe("result")
    expect(fb.stem("class")).toBe("class")
  })
})

describe("serialization", () => {
  test("round-trips an entry with awkward strings", async () => {
    const res = await fb.capture(cacheAuth())
    expect(res.action).toBe("created")
    if (res.action !== "created") return
    const text = await readFile(res.receipt.file, "utf8")
    const parsed = fb.parseEntry(text)
    expect(parsed.title).toBe("Check authorization before serving cached results")
    expect(parsed.sources[0].excerpt).toContain("cached value")
    expect(parsed.scope.subsystems).toEqual(["query-cache"])
    expect(parsed.aliases).toContain("access control")
    expect(fb.serializeEntry(parsed)).toBe(text)
  })

  test("quotes YAML-reserved and colon-bearing scalars", () => {
    const e = fb.parseEntry(
      fb.serializeEntry({
        ...fb.parseEntry("---\nid: fb-20261005-abcdef\n---\n## Lesson\n\nx\n"),
        title: "yes: really # not a comment",
        notice: "no",
        summary: "true",
        concepts: ["on", "null", "1.5"],
      }),
    )
    expect(e.title).toBe("yes: really # not a comment")
    expect(e.notice).toBe("no")
    expect(e.summary).toBe("true")
    expect(e.concepts).toEqual(["on", "null", "1.5"])
  })
})

describe("capture", () => {
  test("validates notice length", async () => {
    const input = cacheAuth()
    input.entry.notice = "one two three four five six seven eight nine ten eleven"
    await expect(fb.capture(input)).rejects.toThrow(/at most 10 words/)
  })

  test("re-capturing the same source does not duplicate", async () => {
    await fb.capture(cacheAuth())
    const again = await fb.capture(cacheAuth())
    expect(again.action).toBe("unchanged")
    expect((await entryFiles()).length).toBe(1)
  })

  test("handling state change updates the entry and yields a receipt", async () => {
    await fb.capture(cacheAuth())
    const res = await fb.capture({
      source: {
        key: "github:acme/app#123:thread:PRRT_1",
        pr: PR,
        thread_state: "resolved",
        disposition: "addressed",
        handled_pr: PR,
        handled_url: "https://github.com/acme/app/commit/abc123",
      },
    })
    expect(res.action).toBe("updated")
    const shown = await fb.show([res.action === "updated" ? res.receipt.id : ""])
    expect(shown).toContain("disposition: addressed")
    expect(shown).toContain("https://github.com/acme/app/commit/abc123")
  })

  test("similar new lesson asks for a decision, then merges", async () => {
    const first = await fb.capture(cacheAuth())
    const second = cacheAuth("github:acme/app#200:thread:PRRT_9")
    second.source.pr = "https://github.com/acme/app/pull/200"
    const res = await fb.capture(second)
    expect(res.action).toBe("needs_decision")
    if (res.action !== "needs_decision" || first.action !== "created") return
    expect(res.candidates[0].id).toBe(first.receipt.id)

    const merged = await fb.capture({ ...second, merge_into: first.receipt.id })
    expect(merged.action).toBe("merged")
    const hit = (await fb.search({ query: "authorization cache", repo: REPO })).results[0]
    expect(hit.sources).toBe(2)
  })

  test("retired entries are not recreated from the same source", async () => {
    const created = await fb.capture(cacheAuth())
    if (created.action !== "created") throw new Error("expected create")
    await fb.retire(created.receipt.id, "no longer applies")
    const res = await fb.capture(cacheAuth())
    expect(res.action).toBe("skipped")
    expect((await fb.search({ query: "authorization", repo: REPO })).results.length).toBe(0)
    expect((await fb.search({ query: "authorization", repo: REPO, include_inactive: true })).results.length).toBe(1)
  })

  test("refuses a symlinked store", async () => {
    const real = join(home, "elsewhere")
    await Bun.write(join(real, "x"), "")
    await symlink(real, process.env.FEEDBACK_HOME!)
    await expect(fb.capture(cacheAuth())).rejects.toThrow(/symlinked/)
  })
})

describe("search", () => {
  beforeEach(async () => {
    await fb.capture(cacheAuth())
    await fb.capture({
      source: { key: "github:acme/app#130:thread:PRRT_2", pr: "https://github.com/acme/app/pull/130", disposition: "addressed", thread_state: "resolved" },
      entry: {
        title: "Cover cancellation in concurrent refresh tests",
        notice: "Test cancellation during concurrent refresh operations",
        summary: "Refresh logic needs tests for cancellation mid-flight.",
        kind: "testing",
        scope: { level: "global" },
        concepts: ["concurrency", "cancellation", "testing"],
        aliases: ["race condition", "abort signal", "in-flight request", "flaky test"],
        lesson: "Exercise cancellation while a refresh is in flight.",
      },
    })
  })

  test("finds lessons via synonyms and symptoms", async () => {
    expect((await fb.search({ query: "authz", repo: REPO })).results[0]?.title).toMatch(/authorization/)
    expect((await fb.search({ query: "race in background reload", repo: REPO })).results[0]?.title).toMatch(/cancellation/)
    expect((await fb.search({ query: "permission bypass on cache hit", repo: REPO })).results[0]?.title).toMatch(/authorization/)
  })

  test("matches symbols and path globs", async () => {
    const bySymbol = await fb.search({ query: "", repo: REPO, symbols: ["getCachedResult"] })
    expect(bySymbol.results[0]?.title).toMatch(/authorization/)
    const byPath = await fb.search({ query: "review", repo: REPO, paths: ["src/cache/store.ts"] })
    expect(byPath.results[0]?.matched).toContain("paths:glob")
  })

  test("partial terms still match", async () => {
    const res = await fb.search({ query: "caches authorizing", repo: REPO })
    expect(res.results[0]?.title).toMatch(/authorization/)
  })

  test("reindex picks up hand edits", async () => {
    const name = (await entryFiles()).find((n) => n.includes("cancellation"))!
    const file = join(process.env.FEEDBACK_HOME!, "entries", name)
    const text = await readFile(file, "utf8")
    await writeFile(file, text.replace("aliases: [", 'aliases: ["debounce", '))
    await fb.reindex()
    expect((await fb.search({ query: "debounce" })).results[0]?.title).toMatch(/cancellation/)
  })

  test("formatSearch is compact and points at show", async () => {
    const text = fb.formatSearch(await fb.search({ query: "cache", repo: REPO }))
    expect(text).toContain("feedback_show")
    expect(text.split("\n").length).toBeLessThan(12)
  })
})

describe("partitions", () => {
  // A repository convention, a global lesson, and a convention from another repo.
  async function seed() {
    const a = await fb.capture(cacheAuth())
    const g = await fb.capture({
      source: { key: "github:acme/app#130:thread:PRRT_2", pr: "https://github.com/acme/app/pull/130", url: "https://github.com/acme/app/pull/130#discussion_r2", reviewer: "bob", disposition: "pending", thread_state: "open" },
      entry: {
        title: "Cover cancellation in concurrent refresh tests",
        notice: "Test cancellation during concurrent refresh operations",
        summary: "Refresh logic needs tests for cancellation mid-flight.",
        kind: "testing",
        scope: { level: "global" },
        concepts: ["concurrency", "cancellation", "testing"],
        aliases: ["race condition", "abort signal", "in-flight request", "flaky test", "timeout"],
        lesson: "Exercise cancellation while a refresh is in flight.",
      },
    })
    const o = await fb.capture({
      source: { key: "github:other/web#7:thread:PRRT_3", pr: "https://github.com/other/web/pull/7", url: "https://github.com/other/web/pull/7#discussion_r3", reviewer: "carol", disposition: "pending", thread_state: "open" },
      entry: {
        title: "Name React hooks files with a use prefix",
        notice: "Prefix hook files with use",
        summary: "Hook modules in other/web are named useThing.ts.",
        kind: "naming",
        scope: { level: "repository" },
        concepts: ["naming", "react hooks"],
        aliases: ["file naming", "hook naming", "use prefix", "conventions", "module names"],
        lesson: "Name files that export a hook after the hook.",
      },
    })
    return { a, g, o }
  }

  test("files entries under their repository or _global", async () => {
    await seed()
    const files = await entryFiles()
    expect(files.filter((f) => f.startsWith("acme/app/")).length).toBe(1)
    expect(files.filter((f) => f.startsWith("_global/")).length).toBe(1)
    expect(files.filter((f) => f.startsWith("other/web/")).length).toBe(1)
  })

  test("search covers one repository plus global lessons", async () => {
    await seed()
    const inApp = await fb.search({ query: "naming hooks cancellation authorization", repo: "acme/app" })
    expect(inApp.results.map((r) => r.partition).sort()).toEqual(["_global", "acme/app"])
    expect(inApp.searched).toEqual(["acme/app", "_global"])

    const inWeb = await fb.search({ query: "naming hooks cancellation authorization", repo: "Other/Web" })
    expect(inWeb.results.map((r) => r.partition).sort()).toEqual(["_global", "other/web"])

    const noRepo = await fb.search({ query: "naming hooks cancellation authorization" })
    expect(noRepo.results.map((r) => r.partition)).toEqual(["_global"])
    expect(noRepo.hints.join(" ")).toContain("no repository given")

    const all = await fb.search({ query: "naming hooks cancellation authorization", all_repos: true })
    expect(all.results.length).toBe(3)
  })

  test("points at other repositories when the scoped search is thin", async () => {
    await seed()
    const res = await fb.search({ query: "hook file naming", repo: "acme/app" })
    expect(res.results.find((r) => r.partition === "other/web")).toBeUndefined()
    expect(res.hints.join(" ")).toContain("all_repos=true")
  })

  test("repository-scoped lessons cannot name another repository", async () => {
    const input = cacheAuth()
    input.entry.scope.repos = ["other/web"]
    await expect(fb.capture(input)).rejects.toThrow(/cannot be scoped to other\/web/)
  })

  test("repository scope defaults to the PR's repository", async () => {
    const input = cacheAuth()
    delete (input.entry.scope as any).repos
    const res = await fb.capture(input)
    expect(res.action === "created" && res.receipt.file.includes("/entries/acme/app/")).toBe(true)
  })

  test("look-alikes in another repository warn instead of blocking", async () => {
    await fb.capture(cacheAuth())
    const other = cacheAuth("github:other/web#9:thread:PRRT_9")
    other.source.pr = "https://github.com/other/web/pull/9"
    delete (other.entry.scope as any).repos
    const res = await fb.capture(other)
    expect(res.action).toBe("created")
    if (res.action !== "created") return
    expect(res.receipt.file).toContain("/entries/other/web/")
    expect(res.warnings.join(" ")).toContain("exists in acme/app")
  })

  test("cross-repository merges require promotion to global", async () => {
    const first = await fb.capture(cacheAuth())
    if (first.action !== "created") throw new Error("expected create")
    const other = cacheAuth("github:other/web#9:thread:PRRT_9")
    other.source.pr = "https://github.com/other/web/pull/9"
    await expect(fb.capture({ ...other, merge_into: first.receipt.id })).rejects.toThrow(/promote it with feedback_revise/)

    const promoted = await fb.revise(first.receipt.id, { scope: { level: "global" } }, "recurred in other/web")
    expect(promoted.receipt.file).toContain("/entries/_global/")
    expect((await entryFiles()).some((f) => f.startsWith("acme/"))).toBe(false)

    const merged = await fb.capture({ ...other, merge_into: first.receipt.id })
    expect(merged.action).toBe("merged")
    const hit = (await fb.search({ query: "authorization cache", repo: "third/repo" })).results[0]
    expect(hit?.partition).toBe("_global")
    expect(hit?.sources).toBe(2)
  })

  test("narrowing a multi-repository lesson needs one repository", async () => {
    const first = await fb.capture({ ...cacheAuth(), entry: { ...cacheAuth().entry, scope: { level: "global" as const } } } as any)
    if (first.action !== "created") throw new Error("expected create")
    const other = cacheAuth("github:other/web#9:thread:PRRT_9")
    other.source.pr = "https://github.com/other/web/pull/9"
    await fb.capture({ ...other, merge_into: first.receipt.id })
    await expect(fb.revise(first.receipt.id, { scope: { level: "repository" } }, "too broad")).rejects.toThrow(/exactly one repository/)
  })

  test("reindex moves legacy flat entries into their partition", async () => {
    const created = await fb.capture(cacheAuth())
    if (created.action !== "created") throw new Error("expected create")
    const entries = join(process.env.FEEDBACK_HOME!, "entries")
    const name = created.receipt.file.split("/").pop()!
    // Simulate a pre-partitioning store: flat file, no repo in scope, old index.
    const text = (await readFile(created.receipt.file, "utf8")).replace("repos: [acme/app]", "repos: []")
    await rm(join(entries, "acme"), { recursive: true })
    await writeFile(join(entries, name), text)
    await writeFile(join(process.env.FEEDBACK_HOME!, "index.jsonl"), "")
    const res = await fb.reindex()
    expect(res.moved).toBe(1)
    expect(res.errors).toEqual([])
    expect(await entryFiles()).toEqual([`acme/app/${name}`])
    expect((await fb.search({ query: "authorization", repo: REPO })).results.length).toBe(1)
  })

  test("normalizes repository names", () => {
    expect(fb.normalizeRepo("Acme/App")).toBe("acme/app")
    expect(fb.normalizeRepo("https://github.com/Acme/App.git")).toBe("acme/app")
    expect(fb.normalizeRepo("nope")).toBeUndefined()
    expect(fb.repoFromPrUrl("https://github.com/Acme/App/pull/3/files")).toBe("acme/app")
  })
})
