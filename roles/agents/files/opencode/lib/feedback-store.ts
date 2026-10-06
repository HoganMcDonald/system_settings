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
import { mkdir, readFile, readdir, rename, rm, rmdir, stat, writeFile } from "node:fs/promises"
import { randomBytes } from "node:crypto"
import { homedir } from "node:os"
import { basename, dirname, join, resolve } from "node:path"

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
const REPO_RE = /^[a-z0-9][a-z0-9-]{0,38}\/[a-z0-9._-]{1,100}$/

// --- Partitions --------------------------------------------------------------
//
// Entries are partitioned by repository: entries/<owner>/<repo>/ holds lessons
// scoped to that repository (or one of its subsystems), and entries/_global/
// holds lessons that apply across codebases (global or language scope).
// Searches cover one repository plus _global unless all_repos is requested,
// so a convention from one codebase never leaks into reviews of another.
// GitHub owners cannot start with "_", so the name cannot collide.

export const GLOBAL_PARTITION = "_global"

export function normalizeRepo(repo: string | undefined | null): string | undefined {
  const r = String(repo ?? "")
    .trim()
    .toLowerCase()
    .replace(/^https?:\/\/(www\.)?github\.com\//, "")
    .replace(/\.git$/, "")
    .split("/")
    .slice(0, 2)
    .join("/")
  return REPO_RE.test(r) ? r : undefined
}

export function repoFromPrUrl(url: string | undefined): string | undefined {
  const m = String(url ?? "").match(/^https?:\/\/(?:www\.)?github\.com\/([^/\s]+)\/([^/\s]+)\/pull\/\d+/)
  return m ? normalizeRepo(`${m[1]}/${m[2]}`) : undefined
}

export function isRepoScoped(level: string): boolean {
  return level === "repository" || level === "subsystem"
}

export function partitionOf(e: Pick<Entry, "scope">): string {
  if (!isRepoScoped(e.scope.level)) return GLOBAL_PARTITION
  const repo = normalizeRepo(e.scope.repos[0])
  if (!repo) throw new Error("repository-scoped entries need exactly one owner/repo in scope.repos")
  return repo
}

// Best-effort repository of a working directory, from its GitHub remote.
// Strips the SDK variables a Nix-launched tmux server leaks into panes, which
// break Apple's /usr/bin/git shim.
export function inferRepo(cwd: string): string | undefined {
  const env: Record<string, string> = {}
  for (const [k, v] of Object.entries(process.env)) if (v !== undefined && k !== "DEVELOPER_DIR" && k !== "SDKROOT") env[k] = v
  const git = (args: string[]) => {
    try {
      const r = Bun.spawnSync(["git", ...args], { cwd, env, stdout: "pipe", stderr: "ignore" })
      return r.exitCode === 0 ? new TextDecoder().decode(r.stdout).trim() : ""
    } catch {
      return ""
    }
  }
  const remotes = git(["remote"]).split("\n").filter(Boolean)
  const ordered = [...remotes.filter((r) => r === "origin"), ...remotes.filter((r) => r !== "origin")]
  for (const remote of ordered) {
    const url = git(["remote", "get-url", remote])
    const m = url.match(/github\.com[:/]+([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/)
    const repo = m ? normalizeRepo(`${m[1]}/${m[2]}`) : undefined
    if (repo) return repo
  }
  return undefined
}

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
  for (const dir of [p.home, p.entries, join(p.entries, GLOBAL_PARTITION), p.state, p.sessions]) {
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
    if (!repoFromPrUrl(s.pr)) errors.push(`source ${s.key} needs a GitHub PR URL`)
  }
  if (isRepoScoped(e.scope.level)) {
    const repos = e.scope.repos.map(normalizeRepo)
    if (repos.length !== 1 || !repos[0]) {
      errors.push(`${e.scope.level}-scoped entries need exactly one owner/repo in scope.repos (got ${JSON.stringify(e.scope.repos)})`)
    } else {
      const foreign = e.sources.filter((s) => repoFromPrUrl(s.pr) !== repos[0])
      if (foreign.length) {
        errors.push(
          `${e.scope.level}-scoped entry for ${repos[0]} has sources from other repositories (${foreign.map((s) => repoFromPrUrl(s.pr)).join(", ")}); use level global or language for cross-repository lessons`,
        )
      }
    }
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

// Every entry file: partitioned (entries/_global/*.md, entries/<owner>/<repo>/*.md)
// and legacy flat files (entries/*.md), which reindex moves into place.
async function entryFiles(home = feedbackHome()): Promise<string[]> {
  const p = await ensureStore(home)
  const out: string[] = []
  const dirents = async (dir: string) => (await readdir(dir, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name))
  for (const d of await dirents(p.entries)) {
    const path = join(p.entries, d.name)
    if (d.isSymbolicLink()) continue
    if (d.isFile() && d.name.endsWith(".md")) out.push(path)
    if (!d.isDirectory()) continue
    for (const d2 of await dirents(path)) {
      const path2 = join(path, d2.name)
      if (d2.isSymbolicLink()) continue
      if (d2.isFile() && d2.name.endsWith(".md") && d.name === GLOBAL_PARTITION) out.push(path2)
      if (!d2.isDirectory() || d.name === GLOBAL_PARTITION) continue
      for (const d3 of await dirents(path2)) {
        if (d3.isFile() && d3.name.endsWith(".md")) out.push(join(path2, d3.name))
      }
    }
  }
  return out
}

function partitionDir(partition: string, home = feedbackHome()): string {
  const p = paths(home)
  if (partition === GLOBAL_PARTITION) return join(p.entries, GLOBAL_PARTITION)
  const repo = normalizeRepo(partition)
  if (!repo) throw new Error(`invalid partition '${partition}'`)
  const [owner, name] = repo.split("/")
  return join(p.entries, owner, name)
}

function expectedFile(e: Entry, home = feedbackHome()): string {
  return join(partitionDir(partitionOf(e), home), `${e.id}--${slugify(e.title)}.md`)
}

async function loadAll(home = feedbackHome()): Promise<{ entries: Loaded[]; errors: string[] }> {
  const errors: string[] = []
  const entries: Loaded[] = []
  const root = paths(home).entries
  for (const file of await entryFiles(home)) {
    const rel = file.slice(root.length + 1)
    if (lstatSync(file).isSymbolicLink()) {
      errors.push(`${rel}: symlinks are ignored`)
      continue
    }
    try {
      const entry = parseEntry(await readFile(file, "utf8"))
      const m = basename(file).match(FILE_RE)
      if (!m || m[1] !== entry.id) errors.push(`${rel}: filename does not match id '${entry.id}'`)
      entries.push({ entry, file })
    } catch (err: any) {
      errors.push(`${rel}: ${err?.message ?? err}`)
    }
  }
  return { entries, errors }
}

async function findEntry(id: string, home = feedbackHome()): Promise<Loaded> {
  if (!ID_RE.test(id)) throw new Error(`invalid feedback id '${id}'`)
  const file = (await entryFiles(home)).find((f) => basename(f).startsWith(`${id}--`))
  if (!file) throw new Error(`feedback entry ${id} not found`)
  return { entry: parseEntry(await readFile(file, "utf8")), file }
}

async function saveEntry(e: Entry, previousFile?: string, home = feedbackHome()): Promise<string> {
  const errors = validateEntry(e)
  if (errors.length) throw new Error(`invalid feedback entry: ${errors.join("; ")}`)
  await ensureStore(home)
  const file = expectedFile(e, home)
  const dir = dirname(file)
  for (let d = dir; d.startsWith(paths(home).entries) && d !== paths(home).entries; d = dirname(d)) assertNotSymlink(d)
  await mkdir(dir, { recursive: true })
  await atomicWrite(file, serializeEntry(e))
  if (previousFile && previousFile !== file) {
    await rm(previousFile, { force: true })
    await pruneEmptyDirs(dirname(previousFile), home)
  }
  return file
}

async function pruneEmptyDirs(dir: string, home = feedbackHome()) {
  const root = paths(home).entries
  for (let d = dir; d.startsWith(root) && d !== root; d = dirname(d)) {
    try {
      if ((await readdir(d)).length) return
      await rmdir(d)
    } catch {
      return
    }
  }
}

// --- Index -------------------------------------------------------------------

export type IndexRecord = {
  id: string
  file: string
  partition: string
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

function safePartition(e: Entry): string {
  try {
    return partitionOf(e)
  } catch {
    return "_invalid"
  }
}

function toRecord(e: Entry, file: string): IndexRecord {
  return {
    id: e.id,
    file,
    partition: safePartition(e),
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

// Fill in a repository-scoped entry's repo from its sources when missing
// (older or hand-written entries); returns whether anything changed.
function repairScope(e: Entry): boolean {
  if (!isRepoScoped(e.scope.level)) return false
  const normalized = uniq(e.scope.repos.map((r) => normalizeRepo(r) ?? r))
  if (normalized.length === 0) {
    const fromSources = uniq(e.sources.map((s) => repoFromPrUrl(s.pr)))
    if (fromSources.length !== 1) return false
    e.scope.repos = fromSources
    return true
  }
  if (JSON.stringify(normalized) !== JSON.stringify(e.scope.repos)) {
    e.scope.repos = normalized
    return true
  }
  return false
}

async function reindexUnlocked(home = feedbackHome()) {
  const p = await ensureStore(home)
  const loaded = await loadAll(home)
  const errors = [...loaded.errors]
  let moved = 0

  // Keep every entry in its partition: hand edits that change scope, and
  // legacy flat files, are moved (and repaired) here.
  const entries: Loaded[] = []
  for (const item of loaded.entries) {
    const repaired = repairScope(item.entry)
    const problems = validateEntry(item.entry)
    if (problems.length) {
      errors.push(`${item.file.slice(p.entries.length + 1)}: ${problems.join("; ")}`)
      entries.push(item)
      continue
    }
    if (repaired || item.file !== expectedFile(item.entry, home)) {
      const file = await saveEntry(item.entry, item.file, home)
      moved++
      entries.push({ entry: item.entry, file })
    } else entries.push(item)
  }

  const records = entries.map(({ entry, file }) => toRecord(entry, file))
  await atomicWrite(p.index, records.map((r) => JSON.stringify(r)).join("\n") + (records.length ? "\n" : ""))

  // Source keys are tombstones: they keep pointing at retired or deleted entries
  // so the same review comment is never silently re-captured.
  const sources = await readJson<Record<string, string>>(p.sources, {})
  for (const { entry } of entries) for (const s of entry.sources) sources[s.key] = entry.id
  await atomicWrite(p.sources, JSON.stringify(sources, null, 2) + "\n")
  if ((await readFile(p.readme, "utf8").catch(() => "")) !== README) await atomicWrite(p.readme, README)
  const partitions: Record<string, number> = {}
  for (const r of records) partitions[r.partition] = (partitions[r.partition] ?? 0) + 1
  return { entries: records.length, moved, partitions, errors }
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
  // Indexes written before partitioning lack the field; rebuild once.
  if (out.some((r) => !r.partition)) {
    await reindex(home)
    return readIndex(home)
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
  /** Repository partition to search alongside _global (owner/repo). */
  repo?: string
  /** Search every partition instead of one repository plus _global. */
  all_repos?: boolean
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
  partition: string
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

export function searchPartitions(opts: Pick<SearchOptions, "repo" | "all_repos">): string[] | "all" {
  if (opts.all_repos) return "all"
  const repo = normalizeRepo(opts.repo)
  return repo ? [repo, GLOBAL_PARTITION] : [GLOBAL_PARTITION]
}

export async function search(opts: SearchOptions, home = feedbackHome()) {
  if (opts.repo && !opts.all_repos && !normalizeRepo(opts.repo)) throw new Error(`repo must be owner/repo, got '${opts.repo}'`)
  const records = await readIndex(home)
  const limit = Math.max(1, Math.min(opts.limit ?? 8, 50))
  const offset = Math.max(0, opts.offset ?? 0)
  const queryText = [opts.query, ...(opts.symbols ?? []), ...(opts.paths ?? [])].join(" ")
  const terms = [...new Set(tokenize(queryText))]
  const partitions = searchPartitions(opts)
  const inScope = records.filter((r) => partitions === "all" || partitions.includes(r.partition))
  const docs = inScope
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
    // Lessons specific to the repository being worked on outrank general ones.
    if (r.partition !== GLOBAL_PARTITION && r.partition === normalizeRepo(opts.repo)) {
      score *= 1.15
      boosts.push(`repo:${r.partition}`)
    }
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
      partition: r.partition,
      scope: [r.level, ...r.languages, ...r.subsystems].join(" "),
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
  if (partitions !== "all" && !normalizeRepo(opts.repo)) {
    hints.push("no repository given: searched only cross-repository (_global) lessons; pass repo=owner/repo for that repository's lessons")
  }
  const outside = records.length - inScope.length
  if (partitions !== "all" && outside > 0 && scored.length < 3) {
    hints.push(`${outside} lesson(s) belong to other repositories; all_repos=true searches them (apply only if the reasoning transfers)`)
  }
  return {
    total: scored.length,
    offset,
    terms,
    searched: partitions === "all" ? ["all repositories"] : partitions,
    results,
    hints,
    entries_in_store: records.length,
  }
}

export function formatSearch(res: Awaited<ReturnType<typeof search>>): string {
  const where = `searched ${res.searched.join(" + ")}`
  if (res.results.length === 0) {
    return `No feedback matched (${where}; ${res.entries_in_store} entries in store; terms: ${res.terms.join(", ") || "none"}).\n${res.hints.join("\n")}`
  }
  const lines = res.results.map(
    (h, i) =>
      `${res.offset + i + 1}. ${h.id} [${h.kind}/${h.status}${h.confidence === "confirmed" ? "" : `/${h.confidence}`}] ${h.title}\n` +
      `   ${h.summary}\n   ${h.partition === GLOBAL_PARTITION ? "global" : h.partition} · scope: ${h.scope} · sources: ${h.sources} · score ${h.score} · matched: ${h.matched.join(", ")}`,
  )
  return [
    `${res.total} match(es) (${where}); showing ${res.offset + 1}-${res.offset + res.results.length}.`,
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

export async function recent(limit = 10, repo?: string, home = feedbackHome()) {
  const partitions = repo ? searchPartitions({ repo }) : "all"
  const records = (await readIndex(home)).filter((r) => partitions === "all" || partitions.includes(r.partition))
  return records
    .sort((a, b) => b.updated.localeCompare(a.updated))
    .slice(0, limit)
    .map((r) => ({ id: r.id, partition: r.partition, title: r.title, kind: r.kind, status: r.status, updated: r.updated, prs: r.prs.length }))
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
  | {
      action: "needs_decision"
      reason: string
      candidates: { id: string; partition: string; title: string; summary: string; similarity: number }[]
    }

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
    // A repository-scoped entry belongs to exactly one repository; for
    // cross-repository entries, repos records where the lesson was seen.
    if (!isRepoScoped(e.scope.level)) e.scope.repos = uniq([...e.scope.repos, ...(input.scope.repos ?? []).map((r) => normalizeRepo(r) ?? r)])
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
    const srcRepo = repoFromPrUrl(src.pr)
    if (!srcRepo) throw new Error("source.pr must be the GitHub PR URL (https://github.com/owner/repo/pull/N)")

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
      const target = partitionOf(e)
      if (target !== GLOBAL_PARTITION && target !== srcRepo) {
        throw new Error(
          `${e.id} is scoped to ${target}, but this feedback is from ${srcRepo}. Entries are partitioned by repository: ` +
            `if the lesson genuinely applies across codebases, first promote it with feedback_revise (scope.level global or language), then merge; ` +
            `otherwise capture it as a new ${srcRepo} entry with force_new=true.`,
        )
      }
      const { source } = mergeSource(undefined, src)
      e.sources.push(source)
      if (target === GLOBAL_PARTITION) e.scope.repos = uniq([...e.scope.repos, srcRepo])
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

    // Partition of the new entry: repository-scoped lessons belong to the
    // repository the feedback came from; everything else is cross-repository.
    const scopeIn = ei.scope ?? {}
    const level = oneOf(SCOPE_LEVELS, scopeIn.level, "repository")
    let repos: string[]
    if (isRepoScoped(level)) {
      const named = uniq((scopeIn.repos ?? []).map((r) => normalizeRepo(r) ?? r))
      if (named.length > 1 || (named.length === 1 && named[0] !== srcRepo)) {
        throw new Error(
          `a ${level}-scoped lesson from ${srcRepo} cannot be scoped to ${named.join(", ")}; use level global or language for lessons that span repositories`,
        )
      }
      repos = [srcRepo]
    } else repos = uniq([...(scopeIn.repos ?? []).map((r) => normalizeRepo(r) ?? r), srcRepo])
    const partition = isRepoScoped(level) ? srcRepo : GLOBAL_PARTITION

    const similar: { id: string; partition: string; title: string; summary: string; similarity: number }[] = []
    {
      const mine = lessonTokens(ei)
      const { entries } = await loadAll(home)
      for (const { entry } of entries) {
        if (entry.status === "retired") continue
        const similarity = Math.round(jaccard(mine, lessonTokens(entry)) * 100) / 100
        if (similarity >= 0.34) {
          similar.push({ id: entry.id, partition: safePartition(entry), title: entry.title, summary: entry.summary, similarity })
        }
      }
      similar.sort((a, b) => b.similarity - a.similarity)
    }
    // Only lessons this entry could merge into (same repository or global)
    // block creation; look-alikes in other repositories are reported instead.
    const mergeable = similar.filter((c) => c.partition === srcRepo || c.partition === GLOBAL_PARTITION).slice(0, 5)
    const elsewhere = similar.filter((c) => !mergeable.includes(c) && c.partition !== partition).slice(0, 3)
    if (!input.force_new && mergeable.length) {
      return {
        action: "needs_decision",
        reason: "similar lessons exist in this repository or globally; retry with merge_into=<id> for a recurrence, or force_new=true for a distinct lesson",
        candidates: mergeable,
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
        scope: { ...scopeIn, level, repos },
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
    const warnings = entryWarnings(e)
    for (const c of elsewhere) {
      warnings.push(
        `similar lesson ${c.id} exists in ${c.partition} ("${c.title}"); if it applies across repositories, promote one to global scope with feedback_revise and retire the other`,
      )
    }
    return { action: "created", receipt: receiptFor("created", e, file, source.pr), warnings }
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
    if (changes.scope?.level) {
      const next = oneOf(SCOPE_LEVELS, changes.scope.level, e.scope.level)
      // Narrowing a cross-repository lesson needs its one repository: an
      // explicit scope.repos, or the repository all of its sources share.
      if (isRepoScoped(next) && !isRepoScoped(e.scope.level)) {
        const target = uniq((changes.scope.repos?.length ? changes.scope.repos : e.sources.map((s) => repoFromPrUrl(s.pr))).map((r) => normalizeRepo(r) ?? r))
        if (target.length !== 1) {
          throw new Error(`narrowing ${e.id} to ${next} scope needs exactly one repository; pass scope.repos (sources span ${target.join(", ")})`)
        }
        e.scope.repos = target
      }
      e.scope.level = next
    }
    if (changes.replace_tags) {
      if (changes.concepts) e.concepts = uniq(changes.concepts)
      if (changes.aliases) e.aliases = uniq(changes.aliases)
      if (changes.symbols) e.symbols = uniq(changes.symbols)
      if (changes.paths) e.paths = uniq(changes.paths)
      if (changes.scope?.repos) e.scope.repos = uniq(changes.scope.repos.map((r) => normalizeRepo(r) ?? r))
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

- \`entries/<owner>/<repo>/<id>--<slug>.md\` - lessons scoped to one repository
- \`entries/_global/<id>--<slug>.md\` - lessons that apply across repositories
- \`index.jsonl\` - generated search index (rebuild: \`feedback reindex\`)
- \`state/sources.json\` - review-comment keys already captured (tombstones included)
- \`state/sessions/\` - per-session capture receipts used for the footer

Searches cover one repository plus _global (the repository defaults to the
current directory's GitHub remote); --all-repos searches every partition:

    feedback search "cache authorization tenant" --repo owner/repo
    feedback show fb-20261005-abc123

Hand edits are fine, including changing an entry's scope; run
\`feedback reindex\` afterwards and it moves the file to the right partition.
`

// --- CLI ---------------------------------------------------------------------

const BOOLEAN_FLAGS = new Set(["all", "all-repos"])

function parseFlags(argv: string[]) {
  const flags: Record<string, string | boolean> = {}
  const positional: string[] = []
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a.startsWith("--")) {
      const [k, v] = a.slice(2).split("=", 2)
      if (v !== undefined) flags[k] = v
      else if (BOOLEAN_FLAGS.has(k)) flags[k] = true
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
  feedback search <query...> [--repo owner/repo | --all-repos] [--paths a,b]
                             [--symbols x,y] [--kind KIND] [--limit N] [--offset N]
                             [--all] [--json]
  feedback show <id...>
  feedback recent [--limit N] [--repo owner/repo]
  feedback capture --json '<CaptureInput>'     (or JSON on stdin)
  feedback revise <id> --note "why" --json '<changes>'
  feedback retire <id> --reason "why" [--superseded-by <id>]
  feedback reindex
  feedback path

Entries are partitioned by repository. search covers --repo (default: the
current directory's GitHub remote) plus cross-repository lessons; --all-repos
searches everything. --all includes retired and superseded entries.

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
        repo: typeof flags.repo === "string" ? flags.repo : inferRepo(process.cwd()),
        all_repos: Boolean(flags["all-repos"]),
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
      console.log(
        JSON.stringify(await recent(flags.limit ? Number(flags.limit) : 10, typeof flags.repo === "string" ? flags.repo : undefined), null, 2),
      )
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
