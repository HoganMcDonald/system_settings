// Tests for lib/schedule-store.ts and plugin/schedule.ts
//
// Usage: bun test roles/agents/tests

import { afterEach, beforeEach, describe, expect, test } from "bun:test"
import { mkdtempSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import * as store from "../files/opencode/lib/schedule-store.ts"

let dir: string
let file: string

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "schedule-test-"))
  file = join(dir, "nested", "pending.json")
  process.env.OPENCODE_SCHEDULE_FILE = file
})

afterEach(() => {
  delete process.env.OPENCODE_SCHEDULE_FILE
  rmSync(dir, { recursive: true, force: true })
})

const entry = (over: Partial<store.Entry> = {}): store.Entry => ({
  id: "sched_a",
  session: "ses_1",
  directory: "/work/app",
  prompt: "check CI",
  created_at: 1_000,
  fire_at: 2_000,
  ...over,
})

describe("store", () => {
  test("add, read, and claim round-trip", () => {
    expect(store.readAll(file)).toEqual([])
    store.add(file, entry())
    store.add(file, entry({ id: "sched_b" }))
    expect(store.readAll(file).map((e) => e.id)).toEqual(["sched_a", "sched_b"])
    expect(store.claim(file, "sched_a")?.id).toBe("sched_a")
    expect(store.claim(file, "sched_a")).toBeUndefined()
    expect(store.has(file, "sched_b")).toBe(true)
  })

  test("claimWhere removes matches only", () => {
    store.add(file, entry())
    store.add(file, entry({ id: "sched_b", session: "ses_2" }))
    expect(store.claimWhere(file, (e) => e.session === "ses_2").map((e) => e.id)).toEqual(["sched_b"])
    expect(store.readAll(file).map((e) => e.id)).toEqual(["sched_a"])
  })

  test("tolerates a corrupt file", () => {
    store.add(file, entry())
    writeFileSync(file, "{not json")
    expect(store.readAll(file)).toEqual([])
  })

  test("clampMinutes bounds the delay", () => {
    expect(store.clampMinutes(0)).toBe(store.MIN_MINUTES)
    expect(store.clampMinutes(30)).toBe(30)
    expect(store.clampMinutes(1e9)).toBe(store.MAX_MINUTES)
    expect(store.clampMinutes(Number.NaN)).toBe(store.MIN_MINUTES)
  })

  test("formatDuration", () => {
    expect(store.formatDuration(45_000)).toBe("45s")
    expect(store.formatDuration(30 * 60_000)).toBe("30m")
    expect(store.formatDuration(2 * 3_600_000)).toBe("2h")
    expect(store.formatDuration(2.5 * 3_600_000)).toBe("2h30m")
  })

  test("wakeMessage flags late delivery", () => {
    const e = entry({ created_at: 0, fire_at: 30 * 60_000, label: "CI" })
    const onTime = store.wakeMessage(e, 30 * 60_000)
    expect(onTime).toContain("[scheduled wakeup sched_a, CI] Set 30m ago.")
    expect(onTime).not.toContain("late")
    expect(onTime.endsWith("check CI")).toBe(true)
    expect(store.wakeMessage(e, 90 * 60_000)).toContain("fired 60m late")
  })
})

describe("plugin", () => {
  const load = async () => {
    const calls: any[] = []
    const client = {
      session: {
        status: async () => ({ data: {} }),
        promptAsync: async (req: any) => void calls.push(req),
      },
    }
    const mod = await import("../files/opencode/plugin/schedule.ts")
    const hooks: any = await mod.default({ client, directory: "/work/app" } as any)
    return { calls, hooks }
  }
  const ctx = { sessionID: "ses_1", directory: "/work/app", agent: "build" } as any

  test("schedule_wakeup persists, list shows it, cancel removes it", async () => {
    const { hooks } = await load()
    const out = await hooks.tool.schedule_wakeup.execute({ minutes: 30, prompt: "check CI", label: "CI" }, ctx)
    expect(out).toContain("Scheduled sched_")
    expect(store.readAll(file)).toHaveLength(1)

    const listed = await hooks.tool.schedule_list.execute({}, ctx)
    expect(listed).toContain("(CI)")
    expect(await hooks.tool.schedule_list.execute({}, { ...ctx, sessionID: "other" })).toBe("No pending wakeups.")
    expect(await hooks.tool.schedule_list.execute({ all: true }, { ...ctx, sessionID: "other" })).toContain("(CI)")

    const id = store.readAll(file)[0].id
    expect(await hooks.tool.schedule_cancel.execute({ id }, ctx)).toBe(`Cancelled ${id}.`)
    expect(store.readAll(file)).toEqual([])
    expect(await hooks.tool.schedule_cancel.execute({ id }, ctx)).toBe(`No pending wakeup ${id}.`)
  })

  test("overdue persisted entries for this directory fire after startup", async () => {
    store.add(file, entry({ fire_at: Date.now() - 5 * 60_000, created_at: Date.now() - 35 * 60_000 }))
    store.add(file, entry({ id: "sched_other", directory: "/elsewhere", fire_at: Date.now() - 1000 }))
    const { calls } = await load()
    await Bun.sleep(3_500)
    expect(calls).toHaveLength(1)
    expect(calls[0].path.id).toBe("ses_1")
    expect(calls[0].body.parts[0].text).toContain("check CI")
    expect(store.readAll(file).map((e) => e.id)).toEqual(["sched_other"])
  })

  test("session.deleted drops that session's entries", async () => {
    const { hooks } = await load()
    await hooks.tool.schedule_wakeup.execute({ minutes: 30, prompt: "x" }, ctx)
    await hooks.event({ event: { type: "session.deleted", properties: { info: { id: "ses_1" } } } })
    expect(store.readAll(file)).toEqual([])
  })
})
