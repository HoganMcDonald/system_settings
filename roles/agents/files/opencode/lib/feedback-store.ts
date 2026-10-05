#!/usr/bin/env bun
//
// feedback-store - Local, searchable memory of code review feedback.
//
// One Markdown file per lesson (YAML frontmatter + sections) under
// ~/.feedback/entries, plus a generated index for lexical search. The module
// is shared by the OpenCode plugin (typed tools) and the `feedback` CLI, so
// every agent harness reads and writes the same store the same way.
//
// Override the location with FEEDBACK_HOME (used by the test suite).

import { existsSync, lstatSync } from "node:fs"
import { mkdir, readFile, readdir, rename, rm, stat, writeFile } from "node:fs/promises"
import { randomBytes } from "node:crypto"
import { homedir } from "node:os"
import { join, resolve } from "node:path"

// --- Schema ------------------------------------------------------------------

export const SCHEMA_VERSION = 1

export const KINDS = [
  "correctness",
  "security",
  "performance",
  "reliability",
  "data",
  "api",
  "design",
  "testing",
  "readability",
  "naming",
  "style",
  "docs",
  "ops",
  "process",
] as const

export const STATUSES = ["active", "proposed", "disputed", "superseded", "retired"] as const
export const CONFIDENCES = ["confirmed", "likely", "tentative"] as const
export const SCOPE_LEVELS = ["global", "language", "repository", "subsystem"] as const
export const THREAD_STATES = ["open", "resolved", "outdated", "none"] as const
export const DISPOSITIONS = ["pending", "addressed", "declined", "disputed", "acknowledged"] as const

export type Kind = (typeof KINDS)[number]
export type Status = (typeof STATUSES)[number]

export type Source = {
  key: string
  pr: string
  url?: string
  reviewer?: string
  thread_state: (typeof THREAD_STATES)[number]
  disposition: (typeof DISPOSITIONS)[number]
  handled_pr?: string
  handled_url?: string
  excerpt?: string
  captured_at: string
  updated_at?: string
}

export type Scope = {
  level: (typeof SCOPE_LEVELS)[number]
  repos: string[]
  languages: string[]
  subsystems: string[]
}

export type Body = {
  lesson: string
  applies_when: string
  why: string
  check: string
  exceptions: string
  history: string[]
}

export type Entry = {
  schema: number
  id: string
  title: string
  notice: string
  summary: string
  kind: Kind
  status: Status
  confidence: (typeof CONFIDENCES)[number]
  scope: Scope
  concepts: string[]
  aliases: string[]
  symbols: string[]
  paths: string[]
  superseded_by?: string
  sources: Source[]
  created: string
  updated: string
  body: Body
}

export type Receipt = {
  action: "created" | "merged" | "updated" | "revised" | "retired"
  id: string
  title: string
  notice: string
  pr?: string
  file: string
}

const SECTION_TITLES: Record<keyof Omit<Body, "history">, string> = {
  lesson: "Lesson",
  applies_when: "Applies when",
  why: "Why",
  check: "Check",
  exceptions: "Exceptions",
}

const ID_RE = /^fb-\d{8}-[a-z0-9]{6}$/
const FILE_RE = /^(fb-\d{8}-[a-z0-9]{6})--[a-z0-9-]{1,60}\.md$/
const SOURCE_KEY_RE = /^[a-z][a-z0-9-]*:\S{3,300}$/
const MAX_NOTICE_WORDS = 10

// --- Paths and safety --------------------------------------------------------

export function feedbackHome(): string {
  return resolve(process.env.FEEDBACK_HOME || join(homedir(), ".feedback"))
}

function paths(home = feedbackHome()) {
  return {
    home,
    entries: join(home, "entries"),
    state: join(home, "state"),
    sessions: join(home, "state", "sessions"),
    index: join(home, "index.jsonl"),
    sources: join(home, "state", "sources.json"),
    lock: join(home, ".lock"),
    readme: join(home, "README.md"),
  }
}

// Refuse to follow symlinks anywhere in the store: writes must land in the
// real ~/.feedback tree and nowhere else.
function assertNotSymlink(p: string) {
  if (existsSync(p) && lstatSync(p).isSymbolicLink()) {
    throw new Error(`refusing to use symlinked feedback path: ${p}`)
  }
}

export async function ensureStore(home = feedbackHome()) {
  const p = paths(home)
  for (const dir of [p.home, p.entries, p.state, p.sessions]) {
    assertNotSymlink(dir)
    await mkdir(dir, { recursive: true })
    assertNotSymlink(dir)
  }
  if (!existsSync(p.readme)) await atomicWrite(p.readme, README)
  return p
}

async function atomicWrite(file: string, content: string) {
  assertNotSymlink(file)
  const tmp = `${file}.tmp.${process.pid}.${randomBytes(3).toString("hex")}`
  await writeFile(tmp, content, "utf8")
  await rename(tmp, file)
}

export function sessionStatePath(sessionID: string, home = feedbackHome()): string {
  if (!/^[A-Za-z0-9_-]{1,120}$/.test(sessionID)) throw new Error(`invalid session id: ${sessionID}`)
  return join(paths(home).sessions, `${sessionID}.json`)
}

export async function readJson<T>(file: string, fallback: T): Promise<T> {
  try {
    return JSON.parse(await readFile(file, "utf8")) as T
  } catch {
    return fallback
  }
}

export async function writeJson(file: string, value: unknown) {
  await ensureStore()
  await atomicWrite(file, JSON.stringify(value, null, 2) + "\n")
}

// mkdir is atomic on every filesystem we care about, so it doubles as a lock.
async function withLock<T>(fn: () => Promise<T>, home = feedbackHome()): Promise<T> {
  const p = await ensureStore(home)
  const deadline = Date.now() + 15000
  for (;;) {
    try {
      await mkdir(p.lock)
      break
    } catch (err: any) {
      if (err?.code !== "EEXIST") throw err
      try {
        const age = Date.now() - (await stat(p.lock)).mtimeMs
        if (age > 30000) {
          await rm(p.lock, { recursive: true, force: true })
          continue
        }
      } catch {
        continue
      }
      if (Date.now() > deadline) throw new Error(`timed out waiting for ${p.lock}`)
      await Bun.sleep(40)
    }
  }
  try {
    return await fn()
  } finally {
    await rm(p.lock, { recursive: true, force: true })
  }
}

// --- Small helpers -----------------------------------------------------------

export function today(): string {
  const d = new Date()
  const pad = (n: number) => String(n).padStart(2, "0")
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

function newId(): string {
  return `fb-${today().replaceAll("-", "")}-${randomBytes(4).toString("hex").slice(0, 6)}`
}

function slugify(s: string): string {
  return (
    s
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60)
      .replace(/-+$/g, "") || "entry"
  )
}

function uniq(values: (string | undefined | null)[]): string[] {
  const seen = new Set<string>()
  const out: string[] = []
  for (const raw of values) {
    const v = (raw ?? "").toString().trim()
    if (!v) continue
    const k = v.toLowerCase()
    if (seen.has(k)) continue
    seen.add(k)
    out.push(v)
  }
  return out
}

function wordCount(s: string): number {
  return s.trim().split(/\s+/).filter(Boolean).length
}

function asList(v: unknown): string[] {
  if (Array.isArray(v)) return uniq(v.map(String))
  if (typeof v === "string" && v.trim()) return uniq(v.split(","))
  return []
}

function oneOf<T extends readonly string[]>(list: T, v: unknown, fallback: T[number]): T[number] {
  return (list as readonly string[]).includes(String(v)) ? (v as T[number]) : fallback
}

// --- YAML (emit a stable subset; parse with Bun.YAML) -------------------------

const PLAIN_RE = /^[A-Za-z0-9_./@+-][A-Za-z0-9_./@+ -]*$/
const RESERVED = /^(true|false|yes|no|on|off|null|~|y|n|[-+]?[0-9.]+(e[-+]?[0-9]+)?)$/i

function yamlScalar(v: unknown): string {
  if (v === null || v === undefined) return '""'
  if (typeof v === "number" || typeof v === "boolean") return String(v)
  const s = String(v)
  if (PLAIN_RE.test(s) && !RESERVED.test(s) && !s.endsWith(" ") && !s.includes(" #")) return s
  return JSON.stringify(s)
}

function emitYaml(value: Record<string, unknown>, indent = 0): string {
  const pad = " ".repeat(indent)
  let out = ""
  for (const [key, v] of Object.entries(value)) {
    if (v === undefined) continue
    if (Array.isArray(v)) {
      if (v.length === 0) {
        out += `${pad}${key}: []\n`
      } else if (v.every((x) => x === null || typeof x !== "object")) {
        out += `${pad}${key}: [${v.map(yamlScalar).join(", ")}]\n`
      } else {
        out += `${pad}${key}:\n`
        for (const item of v) {
          const lines = emitYaml(item as Record<string, unknown>, 0).trimEnd().split("\n")
          out += `${pad}  - ${lines[0]}\n`
          for (const line of lines.slice(1)) out += `${pad}    ${line}\n`
        }
      }
    } else if (v && typeof v === "object") {
      out += `${pad}${key}:\n${emitYaml(v as Record<string, unknown>, indent + 2)}`
    } else {
      out += `${pad}${key}: ${yamlScalar(v)}\n`
    }
  }
  return out
}

// --- Entry (de)serialisation -------------------------------------------------

function normalizeSource(raw: any): Source {
  return {
    key: String(raw?.key ?? ""),
    pr: String(raw?.pr ?? ""),
    url: raw?.url ? String(raw.url) : undefined,
    reviewer: raw?.reviewer ? String(raw.reviewer) : undefined,
    thread_state: oneOf(THREAD_STATES, raw?.thread_state, "none"),
    disposition: oneOf(DISPOSITIONS, raw?.disposition, "pending"),
    handled_pr: raw?.handled_pr ? String(raw.handled_pr) : undefined,
    handled_url: raw?.handled_url ? String(raw.handled_url) : undefined,
    excerpt: raw?.excerpt ? String(raw.excerpt).slice(0, 500) : undefined,
    captured_at: String(raw?.captured_at ?? today()),
    updated_at: raw?.updated_at ? String(raw.updated_at) : undefined,
  }
}

function normalizeEntry(meta: any, body: Body): Entry {
  return {
    schema: Number(meta?.schema ?? SCHEMA_VERSION),
    id: String(meta?.id ?? ""),
    title: String(meta?.title ?? "").trim(),
    notice: String(meta?.notice ?? meta?.title ?? "").trim(),
    summary: String(meta?.summary ?? "").trim(),
    kind: oneOf(KINDS, meta?.kind, "design"),
    status: oneOf(STATUSES, meta?.status, "active"),
    confidence: oneOf(CONFIDENCES, meta?.confidence, "likely"),
    scope: {
      level: oneOf(SCOPE_LEVELS, meta?.scope?.level, "repository"),
      repos: asList(meta?.scope?.repos),
      languages: asList(meta?.scope?.languages),
      subsystems: asList(meta?.scope?.subsystems),
    },
    concepts: asList(meta?.concepts),
    aliases: asList(meta?.aliases),
    symbols: asList(meta?.symbols),
    paths: asList(meta?.paths),
    superseded_by: meta?.superseded_by ? String(meta.superseded_by) : undefined,
    sources: Array.isArray(meta?.sources) ? meta.sources.map(normalizeSource) : [],
    created: String(meta?.created ?? today()),
    updated: String(meta?.updated ?? today()),
    body,
  }
}

export function parseEntry(text: string): Entry {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/)
  if (!m) throw new Error("missing YAML frontmatter")
  const meta = Bun.YAML.parse(m[1]) as any
  const body: Body = { lesson: "", applies_when: "", why: "", check: "", exceptions: "", history: [] }
  const byTitle = new Map(Object.entries(SECTION_TITLES).map(([k, t]) => [t.toLowerCase(), k]))
  const parts = m[2].split(/^## +(.+?)\s*$/m)
  for (let i = 1; i < parts.length; i += 2) {
    const title = parts[i].trim().toLowerCase()
    const content = (parts[i + 1] ?? "").trim()
    if (title === "history") {
      body.history = content
        .split("\n")
        .map((l) => l.replace(/^\s*-\s*/, "").trim())
        .filter(Boolean)
    } else {
      const key = byTitle.get(title) as keyof Omit<Body, "history"> | undefined
      if (key) body[key] = content
    }
  }
  return normalizeEntry(meta, body)
}

export function serializeEntry(e: Entry): string {
  const meta = {
    schema: e.schema,
    id: e.id,
    title: e.title,
    notice: e.notice,
    summary: e.summary,
    kind: e.kind,
    status: e.status,
    confidence: e.confidence,
    scope: e.scope,
    concepts: e.concepts,
    aliases: e.aliases,
    symbols: e.symbols,
    paths: e.paths,
    superseded_by: e.superseded_by,
    sources: e.sources.map((s) => Object.fromEntries(Object.entries(s).filter(([, v]) => v !== undefined))),
    created: e.created,
    updated: e.updated,
  }
  let md = `---\n${emitYaml(meta)}---\n`
  for (const [key, title] of Object.entries(SECTION_TITLES)) {
    const content = e.body[key as keyof typeof SECTION_TITLES]?.trim()
    if (content) md += `\n## ${title}\n\n${content}\n`
  }
  if (e.body.history.length) {
    md += `\n## History\n\n${e.body.history.map((h) => `- ${h}`).join("\n")}\n`
  }
  return md
}

export function validateEntry(e: Entry): string[] {
  const errors: string[] = []
  if (!ID_RE.test(e.id)) errors.push(`invalid id '${e.id}'`)
  if (!e.title) errors.push("title is required")
  if (e.title.length > 100) errors.push("title must be at most 100 characters")
  if (!e.notice) errors.push("notice is required")
  if (wordCount(e.notice) > MAX_NOTICE_WORDS) errors.push(`notice must be at most ${MAX_NOTICE_WORDS} words`)
  if (!e.summary) errors.push("summary is required")
  if (!e.body.lesson) errors.push("lesson is required")
  if (e.concepts.length === 0) errors.push("at least one concept is required")
  if (e.status === "superseded" && !e.superseded_by) errors.push("superseded entries need superseded_by")
  for (const s of e.sources) {
    if (!SOURCE_KEY_RE.test(s.key)) errors.push(`invalid source key '${s.key}'`)
    if (!/^https:\/\//.test(s.pr)) errors.push(`source ${s.key} needs a PR URL`)
  }
  return errors
}

function entryWarnings(e: Entry): string[] {
  const w: string[] = []
  if (e.aliases.length < 3) w.push("add more aliases (synonyms, symptoms, alternate phrasings) to reduce missed searches")
  if (!e.body.check) w.push("a concrete 'check' makes the lesson actionable during review")
  return w
}

// --- Store I/O ---------------------------------------------------------------

type Loaded = { entry: Entry; file: string }

async function loadAll(home = feedbackHome()): Promise<{ entries: Loaded[]; errors: string[] }> {
  const p = await ensureStore(home)
  const errors: string[] = []
  const entries: Loaded[] = []
  for (const name of (await readdir(p.entries)).sort()) {
    if (!name.endsWith(".md")) continue
    const file = join(p.entries, name)
    if (lstatSync(file).isSymbolicLink()) {
      errors.push(`${name}: symlinks are ignored`)
      continue
    }
    try {
      const entry = parseEntry(await readFile(file, "utf8"))
      const m = name.match(FILE_RE)
      if (!m || m[1] !== entry.id) errors.push(`${name}: filename does not match id '${entry.id}'`)
      entries.push({ entry, file })
    } catch (err: any) {
      errors.push(`${name}: ${err?.message ?? err}`)
    }
  }
  return { entries, errors }
}

async function findEntry(id: string, home = feedbackHome()): Promise<Loaded> {
  if (!ID_RE.test(id)) throw new Error(`invalid feedback id '${id}'`)
  const p = await ensureStore(home)
  const name = (await readdir(p.entries)).find((n) => n.startsWith(`${id}--`) && n.endsWith(".md"))
  if (!name) throw new Error(`feedback entry ${id} not found`)
  const file = join(p.entries, name)
  return { entry: parseEntry(await readFile(file, "utf8")), file }
}

async function saveEntry(e: Entry, previousFile?: string, home = feedbackHome()): Promise<string> {
  const errors = validateEntry(e)
  if (errors.length) throw new Error(`invalid feedback entry: ${errors.join("; ")}`)
  const p = await ensureStore(home)
  const file = join(p.entries, `${e.id}--${slugify(e.title)}.md`)
  await atomicWrite(file, serializeEntry(e))
  if (previousFile && previousFile !== file) await rm(previousFile, { force: true })
  return file
}

// --- Index -------------------------------------------------------------------

export type IndexRecord = {
  id: string
  file: string
  title: string
  notice: string
  summary: string
  kind: string
  status: string
  confidence: string
  level: string
  repos: string[]
  languages: string[]
  subsystems: string[]
  concepts: string[]
  aliases: string[]
  symbols: string[]
  paths: string[]
  prs: string[]
  reviewers: string[]
  updated: string
  text: string
}

function toRecord(e: Entry, file: string): IndexRecord {
  return {
    id: e.id,
    file,
    title: e.title,
    notice: e.notice,
    summary: e.summary,
    kind: e.kind,
    status: e.status,
    confidence: e.confidence,
    level: e.scope.level,
    repos: e.scope.repos,
    languages: e.scope.languages,
    subsystems: e.scope.subsystems,
    concepts: e.concepts,
    aliases: e.aliases,
    symbols: e.symbols,
    paths: e.paths,
    prs: uniq(e.sources.flatMap((s) => [s.pr, s.handled_pr])),
    reviewers: uniq(e.sources.map((s) => s.reviewer)),
    updated: e.updated,
    text: [
      e.body.lesson,
      e.body.applies_when,
      e.body.why,
      e.body.check,
      e.body.exceptions,
      ...e.sources.map((s) => s.excerpt ?? ""),
    ].join("\n"),
  }
}

export async function reindex(home = feedbackHome()) {
  return withLock(() => reindexUnlocked(home), home)
}

async function reindexUnlocked(home = feedbackHome()) {
  const p = await ensureStore(home)
  const { entries, errors } = await loadAll(home)
  const records = entries.map(({ entry, file }) => toRecord(entry, file))
  await atomicWrite(p.index, records.map((r) => JSON.stringify(r)).join("\n") + (records.length ? "\n" : ""))

  // Source keys are tombstones: they keep pointing at retired or deleted entries
  // so the same review comment is never silently re-captured.
  const sources = await readJson<Record<string, string>>(p.sources, {})
  for (const { entry } of entries) for (const s of entry.sources) sources[s.key] = entry.id
  await atomicWrite(p.sources, JSON.stringify(sources, null, 2) + "\n")
  return { entries: records.length, errors }
}

async function readIndex(home = feedbackHome()): Promise<IndexRecord[]> {
  const p = await ensureStore(home)
  if (!existsSync(p.index)) await reindex(home)
  const text = await readFile(p.index, "utf8").catch(() => "")
  const out: IndexRecord[] = []
  for (const line of text.split("\n")) {
    if (!line.trim()) continue
    try {
      out.push(JSON.parse(line))
    } catch {
      // A corrupt line is skipped; `reindex` rebuilds from the entries.
    }
  }
  return out
}

// --- Tokenisation and search ---------------------------------------------------

const STOP = new Set(
  "a an and are as at be but by for from has have if in into is it its of on or so that the their then there these this to was we were when where which while will with without you your should must can could would not no do does did".split(
    " ",
  ),
)

export function stem(t: string): string {
  if (t.length > 5 && t.endsWith("ing")) return t.slice(0, -3)
  if (t.length > 4 && t.endsWith("ies")) return t.slice(0, -3) + "y"
  if (t.length > 4 && t.endsWith("ed")) return t.slice(0, -2)
  if (t.length > 4 && /(ss|x|z|ch|sh)es$/.test(t)) return t.slice(0, -2)
  if (t.length > 3 && t.endsWith("s") && !t.endsWith("ss")) return t.slice(0, -1)
  return t
}

export function tokenize(text: string): string[] {
  const raw = String(text ?? "")
  const out: string[] = []
  // Whole identifiers ("getCachedResult", "src/cache") stay searchable as-is.
  for (const w of raw.toLowerCase().split(/[^a-z0-9_]+/)) {
    if (w.length > 2 && /[_]/.test(w)) out.push(w.replaceAll("_", ""))
  }
  for (const w of raw.split(/[^A-Za-z0-9]+/)) {
    if (/[a-z][A-Z]/.test(w) && w.length > 3) out.push(w.toLowerCase())
  }
  const split = raw
    .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
    .replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2")
    .toLowerCase()
    .split(/[^a-z0-9]+/)
  for (const t of split) {
    if (t.length < 2 || STOP.has(t)) continue
    out.push(stem(t))
  }
  return out
}

const FIELD_WEIGHTS: Record<string, number> = {
  title: 3,
  concepts: 3,
  symbols: 3,
  aliases: 2.5,
  subsystems: 2.5,
  summary: 2.5,
  notice: 2,
  paths: 2,
  kind: 1.5,
  languages: 1,
  repos: 1,
  text: 1,
}

function fieldTokens(r: IndexRecord): Record<string, string[]> {
  return {
    title: tokenize(r.title),
    concepts: tokenize(r.concepts.join(" ")),
    symbols: tokenize(r.symbols.join(" ")),
    aliases: tokenize(r.aliases.join(" ")),
    subsystems: tokenize(r.subsystems.join(" ")),
    summary: tokenize(r.summary),
    notice: tokenize(r.notice),
    paths: tokenize(r.paths.join(" ")),
    kind: tokenize(r.kind),
    languages: tokenize(r.languages.join(" ")),
    repos: tokenize(r.repos.join(" ")),
    text: tokenize(r.text),
  }
}

function globToRegExp(glob: string): RegExp {
  let re = ""
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i]
    if (c === "*") {
      if (glob[i + 1] === "*") {
        re += ".*"
        i++
        if (glob[i + 1] === "/") i++
      } else re += "[^/]*"
    } else if (c === "?") re += "[^/]"
    else re += c.replace(/[.+^${}()|[\]\\]/g, "\\$&")
  }
  return new RegExp(`^${re}$`)
}

function pathMatches(entryPaths: string[], queryPaths: string[]): boolean {
  for (const ep of entryPaths) {
    const re = globToRegExp(ep)
    const prefix = ep.replace(/\*.*$/, "").replace(/\/$/, "")
    for (const qp of queryPaths) {
      if (re.test(qp) || (prefix.length > 2 && (qp.startsWith(prefix) || prefix.startsWith(qp)))) return true
    }
  }
  return false
}

export type SearchOptions = {
  query: string
  repo?: string
  paths?: string[]
  symbols?: string[]
  kind?: string
  limit?: number
  offset?: number
  include_inactive?: boolean
}

export type SearchHit = {
  id: string
  title: string
  notice: string
  summary: string
  kind: string
  status: string
  confidence: string
  scope: string
  sources: number
  score: number
  matched: string[]
}

const STATUS_WEIGHT: Record<string, number> = {
  active: 1,
  proposed: 0.8,
  disputed: 0.6,
  superseded: 0.3,
  retired: 0.2,
}

export async function search(opts: SearchOptions, home = feedbackHome()) {
  const records = await readIndex(home)
  const limit = Math.max(1, Math.min(opts.limit ?? 8, 50))
  const offset = Math.max(0, opts.offset ?? 0)
  const queryText = [opts.query, ...(opts.symbols ?? []), ...(opts.paths ?? [])].join(" ")
  const terms = [...new Set(tokenize(queryText))]
  const docs = records
    .filter((r) => opts.include_inactive || (r.status !== "retired" && r.status !== "superseded"))
    .map((r) => ({ r, f: fieldTokens(r) }))

  const df = new Map<string, number>()
  for (const { f } of docs) {
    const all = new Set(Object.values(f).flat())
    for (const t of terms) if (all.has(t)) df.set(t, (df.get(t) ?? 0) + 1)
  }
  const n = Math.max(docs.length, 1)

  const scored: (SearchHit & { _updated: string })[] = []
  for (const { r, f } of docs) {
    let score = 0
    let matchedTerms = 0
    const matched = new Set<string>()
    const boosts: string[] = []
    for (const t of terms) {
      const idf = Math.log(1 + (n - (df.get(t) ?? 0) + 0.5) / ((df.get(t) ?? 0) + 0.5))
      let best = 0
      for (const [field, toks] of Object.entries(f)) {
        const w = FIELD_WEIGHTS[field] ?? 1
        let tf = 0
        let partial = false
        for (const tok of toks) {
          if (tok === t) tf++
          else if (t.length >= 4 && tok.length >= 4 && (tok.startsWith(t.slice(0, 5)) || t.startsWith(tok))) partial = true
        }
        const s = tf > 0 ? w * (1 + Math.log(tf)) : partial ? w * 0.45 : 0
        if (s > 0) matched.add(`${field}:${t}${tf > 0 ? "" : "~"}`)
        best = Math.max(best, s)
      }
      if (best > 0) {
        matchedTerms++
        score += best * Math.max(idf, 0.15)
      }
    }
    if (terms.length === 0) score = 1
    if (score <= 0) continue
    score *= 1 + matchedTerms / Math.max(terms.length, 1)
    if (opts.repo && r.repos.some((x) => x.toLowerCase() === opts.repo!.toLowerCase())) {
      score *= 1.25
      boosts.push(`repo:${opts.repo}`)
    } else if (opts.repo && r.level === "global") score *= 1.05
    if (opts.paths?.length && pathMatches(r.paths, opts.paths)) {
      score *= 1.35
      boosts.push("paths:glob")
    }
    if (opts.symbols?.length && r.symbols.some((s) => opts.symbols!.some((q) => q.toLowerCase() === s.toLowerCase()))) {
      score *= 1.3
      boosts.push("symbols:exact")
    }
    if (opts.kind && r.kind === opts.kind) score *= 1.2
    score *= STATUS_WEIGHT[r.status] ?? 1
    if (r.confidence === "tentative") score *= 0.85
    scored.push({
      id: r.id,
      title: r.title,
      notice: r.notice,
      summary: r.summary,
      kind: r.kind,
      status: r.status,
      confidence: r.confidence,
      scope: [r.level, ...r.repos, ...r.subsystems].join(" "),
      sources: r.prs.length,
      score: Math.round(score * 100) / 100,
      matched: [...boosts, ...matched].slice(0, 8),
      _updated: r.updated,
    })
  }
  scored.sort((a, b) => b.score - a.score || b._updated.localeCompare(a._updated))
  const results = scored.slice(offset, offset + limit).map(({ _updated, ...hit }) => hit)
  const hints: string[] = []
  if (scored.length > offset + limit) hints.push(`more results available: repeat with offset=${offset + limit}`)
  if (scored.length < 3)
    hints.push("few matches: retry with synonyms, symptoms, subsystem names, or symbols; '~' marks partial matches")
  return { total: scored.length, offset, terms, results, hints, entries_in_store: records.length }
}

export function formatSearch(res: Awaited<ReturnType<typeof search>>): string {
  if (res.results.length === 0) {
    return `No feedback matched (${res.entries_in_store} entries in store; terms: ${res.terms.join(", ") || "none"}).\n${res.hints.join("\n")}`
  }
  const lines = res.results.map(
    (h, i) =>
      `${res.offset + i + 1}. ${h.id} [${h.kind}/${h.status}${h.confidence === "confirmed" ? "" : `/${h.confidence}`}] ${h.title}\n` +
      `   ${h.summary}\n   scope: ${h.scope} · sources: ${h.sources} · score ${h.score} · matched: ${h.matched.join(", ")}`,
  )
  return [
    `${res.total} match(es); showing ${res.offset + 1}-${res.offset + res.results.length}.`,
    ...lines,
    ...res.hints,
    "Use feedback_show with selected ids to read full entries.",
  ].join("\n")
}

export async function show(ids: string[], home = feedbackHome()): Promise<string> {
  const out: string[] = []
  for (const id of ids.slice(0, 10)) {
    try {
      const { entry, file } = await findEntry(id, home)
      out.push(`<!-- ${file} -->\n${serializeEntry(entry)}`)
    } catch (err: any) {
      out.push(`${id}: ${err?.message ?? err}`)
    }
  }
  return out.join("\n\n")
}

export async function recent(limit = 10, home = feedbackHome()) {
  const records = await readIndex(home)
  return records
    .sort((a, b) => b.updated.localeCompare(a.updated))
    .slice(0, limit)
    .map((r) => ({ id: r.id, title: r.title, kind: r.kind, status: r.status, updated: r.updated, prs: r.prs.length }))
}

// --- Capture -------------------------------------------------------------------

export type EntryInput = {
  title?: string
  notice?: string
  summary?: string
  kind?: string
  confidence?: string
  status?: string
  scope?: Partial<Scope>
  concepts?: string[]
  aliases?: string[]
  symbols?: string[]
  paths?: string[]
  lesson?: string
  applies_when?: string
  why?: string
  check?: string
  exceptions?: string
}

export type CaptureInput = {
  source: Partial<Source> & { key: string; pr: string }
  entry?: EntryInput
  merge_into?: string
  force_new?: boolean
}

export type CaptureResult =
  | { action: "created" | "merged" | "updated"; receipt: Receipt; warnings: string[] }
  | { action: "unchanged"; id: string; reason: string }
  | { action: "skipped"; id: string; reason: string }
  | { action: "needs_decision"; reason: string; candidates: { id: string; title: string; summary: string; similarity: number }[] }

function jaccard(a: string[], b: string[]): number {
  const A = new Set(a)
  const B = new Set(b)
  if (!A.size || !B.size) return 0
  let inter = 0
  for (const x of A) if (B.has(x)) inter++
  return inter / (A.size + B.size - inter)
}

function lessonTokens(x: { title?: string; summary?: string; concepts?: string[]; notice?: string }) {
  return [...new Set(tokenize([x.title, x.summary, x.notice, ...(x.concepts ?? [])].join(" ")))]
}

function mergeSource(existing: Source | undefined, incoming: Partial<Source>): { source: Source; changed: boolean } {
  const base = existing ?? normalizeSource({ ...incoming, captured_at: today() })
  const next = normalizeSource({
    ...base,
    ...Object.fromEntries(Object.entries(incoming).filter(([, v]) => v !== undefined && v !== "")),
    captured_at: base.captured_at,
  })
  const keys: (keyof Source)[] = ["thread_state", "disposition", "handled_pr", "handled_url", "url", "reviewer", "excerpt"]
  const changed = !existing || keys.some((k) => (existing[k] ?? "") !== (next[k] ?? ""))
  if (changed && existing) next.updated_at = today()
  return { source: next, changed }
}

function applyTags(e: Entry, input: EntryInput | undefined) {
  if (!input) return
  e.concepts = uniq([...e.concepts, ...(input.concepts ?? [])])
  e.aliases = uniq([...e.aliases, ...(input.aliases ?? [])])
  e.symbols = uniq([...e.symbols, ...(input.symbols ?? [])])
  e.paths = uniq([...e.paths, ...(input.paths ?? [])])
  if (input.scope) {
    e.scope.repos = uniq([...e.scope.repos, ...(input.scope.repos ?? [])])
    e.scope.languages = uniq([...e.scope.languages, ...(input.scope.languages ?? [])])
    e.scope.subsystems = uniq([...e.scope.subsystems, ...(input.scope.subsystems ?? [])])
  }
}

function receiptFor(action: Receipt["action"], e: Entry, file: string, pr?: string): Receipt {
  return { action, id: e.id, title: e.title, notice: e.notice, pr, file }
}

export async function capture(input: CaptureInput, home = feedbackHome()): Promise<CaptureResult> {
  return withLock(async () => {
    const p = await ensureStore(home)
    const src = input.source
    if (!src || !SOURCE_KEY_RE.test(String(src.key ?? ""))) {
      throw new Error("source.key is required, e.g. github:owner/repo#123:thread:PRRT_abc")
    }
    if (!/^https:\/\//.test(String(src.pr ?? ""))) throw new Error("source.pr must be the PR URL")

    const sources = await readJson<Record<string, string>>(p.sources, {})
    const knownId = sources[src.key]

    // Same review comment seen again: update its handling state in place.
    if (knownId) {
      let loaded: Loaded
      try {
        loaded = await findEntry(knownId, home)
      } catch {
        return { action: "skipped", id: knownId, reason: "source was captured into an entry that has since been deleted" }
      }
      const e = loaded.entry
      const idx = e.sources.findIndex((s) => s.key === src.key)
      const { source, changed } = mergeSource(idx >= 0 ? e.sources[idx] : undefined, src)
      if (idx >= 0) e.sources[idx] = source
      else e.sources.push(source)
      const before = JSON.stringify([e.concepts, e.aliases, e.symbols, e.paths, e.scope])
      applyTags(e, input.entry)
      const tagsChanged = before !== JSON.stringify([e.concepts, e.aliases, e.symbols, e.paths, e.scope])
      const inactive = e.status === "retired" || e.status === "superseded"
      if (!changed && !tagsChanged) {
        return inactive
          ? { action: "skipped", id: e.id, reason: `source belongs to ${e.status} entry ${e.id}` }
          : { action: "unchanged", id: e.id, reason: "source already captured with the same state" }
      }
      e.updated = today()
      if (changed && source.disposition !== "pending") {
        e.body.history.push(`${today()}: ${source.key} -> ${source.disposition}${source.handled_url ? ` (${source.handled_url})` : ""}`)
      }
      const file = await saveEntry(e, loaded.file, home)
      await reindexUnlocked(home)
      if (inactive) {
        return { action: "skipped", id: e.id, reason: `source belongs to ${e.status} entry; state recorded without a receipt` }
      }
      // Only a change of handling state is worth announcing.
      if (!changed) return { action: "unchanged", id: e.id, reason: "only tags changed" }
      return { action: "updated", receipt: receiptFor("updated", e, file, source.pr), warnings: [] }
    }

    if (input.merge_into) {
      const loaded = await findEntry(input.merge_into, home)
      const e = loaded.entry
      const { source } = mergeSource(undefined, src)
      e.sources.push(source)
      applyTags(e, input.entry)
      if (e.status === "proposed" && e.sources.length > 1) e.confidence = "confirmed"
      e.updated = today()
      e.body.history.push(`${today()}: merged recurrence from ${source.url ?? source.pr}`)
      const file = await saveEntry(e, loaded.file, home)
      await reindexUnlocked(home)
      return { action: "merged", receipt: receiptFor("merged", e, file, source.pr), warnings: [] }
    }

    const ei = input.entry
    if (!ei?.title || !ei.summary || !ei.lesson) {
      throw new Error("new entries need entry.title, entry.summary, entry.notice, entry.lesson and entry.concepts")
    }

    if (!input.force_new) {
      const mine = lessonTokens(ei)
      const { entries } = await loadAll(home)
      const candidates = entries
        .filter(({ entry }) => entry.status !== "retired")
        .map(({ entry }) => ({
          id: entry.id,
          title: entry.title,
          summary: entry.summary,
          similarity: Math.round(jaccard(mine, lessonTokens(entry)) * 100) / 100,
        }))
        .filter((c) => c.similarity >= 0.34)
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, 5)
      if (candidates.length) {
        return {
          action: "needs_decision",
          reason: "similar lessons exist; retry with merge_into=<id> for a recurrence, or force_new=true for a distinct lesson",
          candidates,
        }
      }
    }

    const { source } = mergeSource(undefined, src)
    const e = normalizeEntry(
      {
        schema: SCHEMA_VERSION,
        id: newId(),
        title: ei.title,
        notice: ei.notice ?? ei.title,
        summary: ei.summary,
        kind: ei.kind,
        status: ei.status ?? (source.disposition === "disputed" ? "disputed" : "active"),
        confidence: ei.confidence,
        scope: ei.scope ?? {},
        concepts: ei.concepts ?? [],
        aliases: ei.aliases ?? [],
        symbols: ei.symbols ?? [],
        paths: ei.paths ?? [],
        sources: [source],
        created: today(),
        updated: today(),
      },
      {
        lesson: ei.lesson ?? "",
        applies_when: ei.applies_when ?? "",
        why: ei.why ?? "",
        check: ei.check ?? "",
        exceptions: ei.exceptions ?? "",
        history: [`${today()}: captured from ${source.url ?? source.pr}`],
      },
    )
    const file = await saveEntry(e, undefined, home)
    await reindexUnlocked(home)
    return { action: "created", receipt: receiptFor("created", e, file, source.pr), warnings: entryWarnings(e) }
  }, home)
}

// --- Maintenance ---------------------------------------------------------------

export type ReviseInput = EntryInput & {
  replace_tags?: boolean
  superseded_by?: string
}

export async function revise(id: string, changes: ReviseInput, note: string, home = feedbackHome()) {
  return withLock(async () => {
    const loaded = await findEntry(id, home)
    const e = loaded.entry
    const scalar: (keyof EntryInput)[] = ["title", "notice", "summary"]
    for (const k of scalar) if (typeof changes[k] === "string" && changes[k]) (e as any)[k] = String(changes[k]).trim()
    if (changes.kind) e.kind = oneOf(KINDS, changes.kind, e.kind)
    if (changes.status) e.status = oneOf(STATUSES, changes.status, e.status)
    if (changes.confidence) e.confidence = oneOf(CONFIDENCES, changes.confidence, e.confidence)
    if (changes.superseded_by) e.superseded_by = changes.superseded_by
    if (changes.scope?.level) e.scope.level = oneOf(SCOPE_LEVELS, changes.scope.level, e.scope.level)
    if (changes.replace_tags) {
      if (changes.concepts) e.concepts = uniq(changes.concepts)
      if (changes.aliases) e.aliases = uniq(changes.aliases)
      if (changes.symbols) e.symbols = uniq(changes.symbols)
      if (changes.paths) e.paths = uniq(changes.paths)
      if (changes.scope?.repos) e.scope.repos = uniq(changes.scope.repos)
      if (changes.scope?.languages) e.scope.languages = uniq(changes.scope.languages)
      if (changes.scope?.subsystems) e.scope.subsystems = uniq(changes.scope.subsystems)
    } else applyTags(e, changes)
    for (const k of Object.keys(SECTION_TITLES) as (keyof typeof SECTION_TITLES)[]) {
      if (typeof changes[k] === "string") e.body[k] = String(changes[k]).trim()
    }
    e.updated = today()
    e.body.history.push(`${today()}: revised: ${note || "manual edit"}`)
    const file = await saveEntry(e, loaded.file, home)
    await reindexUnlocked(home)
    return { action: "revised" as const, receipt: receiptFor("revised", e, file) }
  }, home)
}

export async function retire(id: string, reason: string, supersededBy?: string, home = feedbackHome()) {
  if (supersededBy) await findEntry(supersededBy, home)
  return withLock(async () => {
    const loaded = await findEntry(id, home)
    const e = loaded.entry
    e.status = supersededBy ? "superseded" : "retired"
    e.superseded_by = supersededBy
    e.updated = today()
    e.body.history.push(`${today()}: ${e.status}: ${reason || "no reason given"}${supersededBy ? ` (see ${supersededBy})` : ""}`)
    const file = await saveEntry(e, loaded.file, home)
    await reindexUnlocked(home)
    return { action: "retired" as const, receipt: receiptFor("retired", e, file) }
  }, home)
}

// --- Store README (for humans and agents that browse the directory) -----------

const README = `# Feedback memory

Lessons distilled from code review feedback on Hogan's pull requests. Written
by the feedback-accumulator skill; read by feedback-recall during reviews and
implementation work.

- \`entries/<id>--<slug>.md\` - one lesson per file (YAML frontmatter + sections)
- \`index.jsonl\` - generated search index (rebuild: \`feedback reindex\`)
- \`state/sources.json\` - review-comment keys already captured (tombstones included)
- \`state/sessions/\` - per-session capture receipts used for the footer

Search instead of reading everything:

    feedback search "cache authorization tenant" --repo owner/repo
    feedback show fb-20261005-abc123

Hand edits are fine; run \`feedback reindex\` afterwards.
`

// --- CLI ---------------------------------------------------------------------

function parseFlags(argv: string[]) {
  const flags: Record<string, string | boolean> = {}
  const positional: string[] = []
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a.startsWith("--")) {
      const [k, v] = a.slice(2).split("=", 2)
      if (v !== undefined) flags[k] = v
      else if (argv[i + 1] !== undefined && !argv[i + 1].startsWith("--")) flags[k] = argv[++i]
      else flags[k] = true
    } else positional.push(a)
  }
  return { flags, positional }
}

async function readPayload(flags: Record<string, string | boolean>): Promise<any> {
  if (typeof flags.json === "string") return JSON.parse(flags.json)
  const stdin = await Bun.stdin.text()
  if (!stdin.trim()) throw new Error("expected a JSON payload via --json '<payload>' or stdin")
  return JSON.parse(stdin)
}

const HELP = `feedback - search and maintain review feedback memory (~/.feedback)

Usage:
  feedback search <query...> [--repo owner/repo] [--paths a,b] [--symbols x,y]
                             [--kind KIND] [--limit N] [--offset N] [--all] [--json]
  feedback show <id...>
  feedback recent [--limit N]
  feedback capture --json '<CaptureInput>'     (or JSON on stdin)
  feedback revise <id> --note "why" --json '<changes>'
  feedback retire <id> --reason "why" [--superseded-by <id>]
  feedback reindex
  feedback path

Environment:
  FEEDBACK_HOME   store location (default ~/.feedback)
`

export async function main(argv: string[]) {
  const [cmd, ...rest] = argv
  const { flags, positional } = parseFlags(rest)
  const list = (v: unknown) => (typeof v === "string" ? v.split(",").map((s) => s.trim()).filter(Boolean) : undefined)
  switch (cmd) {
    case "search": {
      const res = await search({
        query: positional.join(" "),
        repo: typeof flags.repo === "string" ? flags.repo : undefined,
        paths: list(flags.paths),
        symbols: list(flags.symbols),
        kind: typeof flags.kind === "string" ? flags.kind : undefined,
        limit: flags.limit ? Number(flags.limit) : undefined,
        offset: flags.offset ? Number(flags.offset) : undefined,
        include_inactive: Boolean(flags.all),
      })
      console.log(flags.json ? JSON.stringify(res, null, 2) : formatSearch(res))
      return
    }
    case "show":
      if (!positional.length) throw new Error("usage: feedback show <id...>")
      console.log(await show(positional))
      return
    case "recent":
      console.log(JSON.stringify(await recent(flags.limit ? Number(flags.limit) : 10), null, 2))
      return
    case "capture":
      console.log(JSON.stringify(await capture(await readPayload(flags)), null, 2))
      return
    case "revise":
      if (!positional[0]) throw new Error("usage: feedback revise <id> --note why --json '<changes>'")
      console.log(JSON.stringify(await revise(positional[0], await readPayload(flags), String(flags.note ?? "")), null, 2))
      return
    case "retire":
      if (!positional[0]) throw new Error("usage: feedback retire <id> --reason why")
      console.log(
        JSON.stringify(
          await retire(
            positional[0],
            String(flags.reason ?? ""),
            typeof flags["superseded-by"] === "string" ? flags["superseded-by"] : undefined,
          ),
          null,
          2,
        ),
      )
      return
    case "reindex":
      console.log(JSON.stringify(await reindex(), null, 2))
      return
    case "path":
      console.log(feedbackHome())
      return
    case undefined:
    case "-h":
    case "--help":
    case "help":
      console.log(HELP)
      return
    default:
      throw new Error(`unknown command '${cmd}'\n\n${HELP}`)
  }
}

if (import.meta.main) {
  main(process.argv.slice(2)).catch((err) => {
    console.error(`feedback: ${err?.message ?? err}`)
    process.exit(1)
  })
}
