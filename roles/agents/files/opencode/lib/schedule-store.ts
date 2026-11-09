// Pending scheduled wakeups for the schedule plugin.
//
// Entries live in one small JSON file so they survive an OpenCode restart.
// Every write is a synchronous read-modify-write followed by a rename, which
// keeps "claim an entry" safe when two OpenCode processes share the file.

import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs"
import { dirname } from "node:path"

export const MIN_MINUTES = 0.1
export const MAX_MINUTES = 24 * 60

export type Entry = {
  id: string
  session: string
  directory: string
  agent?: string
  label?: string
  prompt: string
  created_at: number
  fire_at: number
}

export function storePath(env: Record<string, string | undefined> = process.env): string {
  if (env.OPENCODE_SCHEDULE_FILE) return env.OPENCODE_SCHEDULE_FILE
  const state = env.XDG_STATE_HOME || `${env.HOME}/.local/state`
  return `${state}/opencode-schedule/pending.json`
}

export function readAll(file: string): Entry[] {
  if (!existsSync(file)) return []
  try {
    const parsed = JSON.parse(readFileSync(file, "utf8"))
    return Array.isArray(parsed) ? parsed.filter(isEntry) : []
  } catch {
    return []
  }
}

function isEntry(value: any): value is Entry {
  return (
    value &&
    typeof value.id === "string" &&
    typeof value.session === "string" &&
    typeof value.directory === "string" &&
    typeof value.prompt === "string" &&
    typeof value.fire_at === "number"
  )
}

function writeAll(file: string, entries: Entry[]) {
  mkdirSync(dirname(file), { recursive: true })
  const tmp = `${file}.${process.pid}.tmp`
  writeFileSync(tmp, JSON.stringify(entries, null, 2))
  renameSync(tmp, file)
}

export function add(file: string, entry: Entry) {
  writeAll(file, [...readAll(file), entry])
}

export function has(file: string, id: string): boolean {
  return readAll(file).some((e) => e.id === id)
}

/** Remove and return the entry, or undefined when it is already gone. */
export function claim(file: string, id: string): Entry | undefined {
  const entries = readAll(file)
  const hit = entries.find((e) => e.id === id)
  if (!hit) return undefined
  writeAll(
    file,
    entries.filter((e) => e.id !== id),
  )
  return hit
}

/** Remove every entry matching the predicate and return them. */
export function claimWhere(file: string, match: (e: Entry) => boolean): Entry[] {
  const entries = readAll(file)
  const gone = entries.filter(match)
  if (gone.length > 0) writeAll(file, entries.filter((e) => !match(e)))
  return gone
}

export function newId(): string {
  return `sched_${Math.random().toString(36).slice(2, 8)}`
}

export function clampMinutes(minutes: number): number {
  if (!Number.isFinite(minutes)) return MIN_MINUTES
  return Math.min(MAX_MINUTES, Math.max(MIN_MINUTES, minutes))
}

export function formatDuration(ms: number): string {
  const total = Math.max(0, Math.round(ms / 1000))
  if (total < 90) return `${total}s`
  const minutes = Math.round(total / 60)
  if (minutes < 90) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const rest = minutes % 60
  return rest === 0 ? `${hours}h` : `${hours}h${rest}m`
}

/** The text injected into the session when an entry fires. */
export function wakeMessage(entry: Entry, now: number): string {
  const waited = formatDuration(now - entry.created_at)
  const late = now - entry.fire_at
  const tag = entry.label ? `${entry.id}, ${entry.label}` : entry.id
  const lines = [`[scheduled wakeup ${tag}] Set ${waited} ago.`]
  if (late > 60_000) {
    lines.push(`It fired ${formatDuration(late)} late because OpenCode was not running at the scheduled time.`)
  }
  lines.push("", entry.prompt)
  return lines.join("\n")
}
