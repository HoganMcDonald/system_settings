// schedule - let the agent end its turn now and be woken up later.
//
// - schedule_wakeup: re-prompt this session after N minutes (non-blocking)
// - schedule_list / schedule_cancel: inspect and cancel pending wakeups
//
// Typical use: kick off CI, call schedule_wakeup(30, "check the run and fix
// failures"), and stop. When the timer fires the prompt is injected into the
// same session, so the full conversation context is still there.
//
// Pending wakeups are persisted (see lib/schedule-store.ts) and re-armed the
// next time OpenCode starts in the same directory. Timers only run while
// OpenCode is running; a wakeup that came due while it was closed fires a few
// seconds after startup and says so.

import type { Plugin } from "@opencode-ai/plugin"
import * as store from "../lib/schedule-store.ts"

// This file is symlinked into ~/.config/opencode/plugin, so bare-specifier
// resolution can start from the dotfiles checkout, which has no node_modules.
// Fall back to the copy OpenCode installs in its config directory.
const { tool } = (await import("@opencode-ai/plugin").catch(
  () => import(`${process.env.HOME}/.config/opencode/node_modules/@opencode-ai/plugin/dist/index.js`),
)) as typeof import("@opencode-ai/plugin")

const s = tool.schema

const BUSY_RETRY_MS = 15_000
const MAX_BUSY_RETRIES = 40 // about 10 minutes, then deliver anyway
const OVERDUE_DELAY_MS = 3_000

export default (async ({ client, directory }: any) => {
  const file = store.storePath()
  const timers = new Map<string, ReturnType<typeof setTimeout>>()

  const log = (level: "info" | "warn" | "error", message: string) => {
    client.app?.log?.({ body: { service: "schedule", level, message } } as any)?.catch?.(() => {})
  }

  async function isBusy(session: string): Promise<boolean> {
    try {
      const res: any = await client.session.status({} as any)
      const status = res?.data?.[session]
      return !!status && status.type !== "idle"
    } catch {
      return false
    }
  }

  function arm(entry: store.Entry, delayMs: number, attempt = 0) {
    clearTimeout(timers.get(entry.id))
    timers.set(
      entry.id,
      setTimeout(() => void fire(entry, attempt), Math.max(0, delayMs)),
    )
  }

  async function fire(entry: store.Entry, attempt: number) {
    timers.delete(entry.id)
    // Cancelled, or already claimed by another OpenCode process.
    if (!store.has(file, entry.id)) return

    if (attempt < MAX_BUSY_RETRIES && (await isBusy(entry.session))) {
      arm(entry, BUSY_RETRY_MS, attempt + 1)
      return
    }

    const claimed = store.claim(file, entry.id)
    if (!claimed) return

    try {
      await client.session.promptAsync({
        path: { id: claimed.session },
        query: { directory: claimed.directory },
        body: {
          ...(claimed.agent ? { agent: claimed.agent } : {}),
          parts: [{ type: "text", text: store.wakeMessage(claimed, Date.now()) }],
        },
      } as any)
      log("info", `fired ${claimed.id} into session ${claimed.session}`)
    } catch (err: any) {
      log("error", `failed to deliver ${claimed.id} to session ${claimed.session}: ${err?.message ?? err}`)
    }
  }

  // Re-arm anything persisted for this directory by an earlier process.
  for (const entry of store.readAll(file)) {
    if (entry.directory !== directory) continue
    arm(entry, entry.fire_at <= Date.now() ? OVERDUE_DELAY_MS : entry.fire_at - Date.now())
  }

  const describe = (e: store.Entry, now: number) => {
    const when = e.fire_at <= now ? "due now" : `in ${store.formatDuration(e.fire_at - now)}`
    const label = e.label ? ` (${e.label})` : ""
    const prompt = e.prompt.length > 100 ? `${e.prompt.slice(0, 100)}...` : e.prompt
    return `${e.id}${label} ${when}: ${prompt}`
  }

  return {
    tool: {
      schedule_wakeup: tool({
        description: [
          "Schedule a prompt to be sent back to THIS session after a delay, without blocking.",
          "Use it to wait on something slow (CI, a deploy, a long job): start the work, call this,",
          "then end your turn. Do not poll or sleep in the meantime. When the delay elapses the",
          "prompt arrives as a new user message in this session with the conversation intact.",
          "Write the prompt as instructions to your future self: what to check (include run ids,",
          "PR numbers, commands) and what to do for each outcome. Pending wakeups only fire while",
          "OpenCode is running; they resume on the next start in this directory.",
        ].join(" "),
        args: {
          minutes: s.number().describe(`Delay in minutes (${store.MIN_MINUTES} to ${store.MAX_MINUTES}).`),
          prompt: s.string().describe("Message to send to this session when the delay elapses."),
          label: s.string().optional().describe("Short label shown in schedule_list, such as 'CI for PR 123'."),
        },
        async execute(args, ctx) {
          const minutes = store.clampMinutes(args.minutes)
          const now = Date.now()
          const entry: store.Entry = {
            id: store.newId(),
            session: ctx.sessionID,
            directory: ctx.directory || directory,
            agent: ctx.agent,
            label: args.label,
            prompt: args.prompt,
            created_at: now,
            fire_at: now + minutes * 60_000,
          }
          store.add(file, entry)
          arm(entry, entry.fire_at - now)
          const note = minutes !== args.minutes ? ` (clamped from ${args.minutes}m)` : ""
          return `Scheduled ${entry.id} in ${store.formatDuration(minutes * 60_000)}${note}. End your turn now; the prompt will arrive in this session.`
        },
      }),

      schedule_list: tool({
        description: "List pending scheduled wakeups for this session, or for every session in this directory.",
        args: {
          all: s.boolean().optional().describe("Include other sessions in this directory."),
        },
        async execute(args, ctx) {
          const dir = ctx.directory || directory
          const now = Date.now()
          const entries = store
            .readAll(file)
            .filter((e) => (args.all ? e.directory === dir : e.session === ctx.sessionID))
            .sort((a, b) => a.fire_at - b.fire_at)
          if (entries.length === 0) return "No pending wakeups."
          return entries.map((e) => describe(e, now)).join("\n")
        },
      }),

      schedule_cancel: tool({
        description: "Cancel a pending scheduled wakeup by id.",
        args: {
          id: s.string().describe("Wakeup id from schedule_wakeup or schedule_list."),
        },
        async execute(args) {
          clearTimeout(timers.get(args.id))
          timers.delete(args.id)
          const removed = store.claim(file, args.id)
          return removed ? `Cancelled ${removed.id}.` : `No pending wakeup ${args.id}.`
        },
      }),
    },

    event: async ({ event }: any) => {
      if (event.type !== "session.deleted") return
      const id = event.properties?.info?.id
      if (!id) return
      for (const gone of store.claimWhere(file, (e) => e.session === id)) {
        clearTimeout(timers.get(gone.id))
        timers.delete(gone.id)
      }
    },
  }
}) satisfies Plugin
