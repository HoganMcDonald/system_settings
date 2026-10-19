// feedback-backfill - Prefill ~/.feedback from review feedback on merged PRs.
//
// plan   lists merged PRs with review discussion (no model involved) and stores
//        a resumable queue in ~/.feedback/state/backfill/<owner>__<repo>.json
// run    processes queued PRs one at a time, oldest first, each in a fresh
//        headless OpenCode session running the feedback-backfill agent
// status shows progress; purge removes everything a backfill captured
//
// PRs run sequentially on purpose: an older lesson exists before a later PR
// repeats it, so recurrences merge instead of duplicating.

import { existsSync } from "node:fs"
import { mkdir, readFile, rm, writeFile } from "node:fs/promises"
import { basename, join } from "node:path"
import * as fb from "./feedback-store.ts"
import * as prc from "./pr-context.ts"
import { FOOTER_TITLE, countLine } from "./review-loop-core.ts"

export const BACKFILL_AGENT = "feedback-backfill"
const DEFAULT_TIMEOUT_MIN = 30

export type BackfillPr = {
  number: number
  url: string
  title: string
  merged_at: string
  human_threads: number
  bot_threads: number
  human_comments: number
  status: "pending" | "running" | "done" | "failed"
  attempts: number
  started_at?: string
  finished_at?: string
  captured?: number
  results?: Record<string, number>
  session_id?: string
  error?: string
}

export type BackfillState = {
  repo: string
  author: string
  since: string
  planned_at: string
  prs: BackfillPr[]
  runs?: BackfillRun[]
}

export type BackfillRun = { started_at: string; finished_at?: string; prs: number[]; processed: number; failed: number; captured: number }

// --- Paths -----------------------------------------------------------------------

function slug(repo: string) {
  return repo.replace("/", "__")
}

export function statePath(repo: string, home = fb.feedbackHome()) {
  return join(home, "state", "backfill", `${slug(repo)}.json`)
}

export function logDir(repo: string, home = fb.feedbackHome()) {
  return join(home, "state", "backfill", "logs", slug(repo))
}

function requireRepo(repo: string | undefined): string {
  const r = fb.normalizeRepo(repo)
  if (!r) throw new Error("--repo owner/repo is required")
  return r
}

export async function readState(repo: string, home = fb.feedbackHome()): Promise<BackfillState | null> {
  const file = statePath(repo, home)
  if (!existsSync(file)) return null
  return JSON.parse(await readFile(file, "utf8"))
}

async function writeState(state: BackfillState, home = fb.feedbackHome()) {
  await mkdir(join(home, "state", "backfill"), { recursive: true })
  await fb.writeJson(statePath(state.repo, home), state)
}

// --- Plan --------------------------------------------------------------------------

export function monthsAgo(months: number, from = new Date()): string {
  const d = new Date(from)
  d.setMonth(d.getMonth() - months)
  return d.toISOString().slice(0, 10)
}

const PLAN_QUERY = `query($q:String!,$after:String){ search(query:$q,type:ISSUE,first:40,after:$after){
  pageInfo{hasNextPage endCursor}
  nodes{ ... on PullRequest{ number url title mergedAt
    reviewThreads(first:100){ nodes{ comments(first:1){ nodes{ author{login __typename} } } } }
    reviews(first:100){ nodes{ body author{login __typename} } }
    comments(first:100){ nodes{ body author{login __typename} } } } } } }`

// Count the discussion worth reading on one PR, from the plan query's shape.
export function countFeedback(node: any, author: string) {
  const mine = (a: any) => String(a?.login ?? "").toLowerCase() === author.toLowerCase()
  const bot = (a: any) => prc.isBot(a?.login ?? "", a?.__typename)
  let human_threads = 0
  let bot_threads = 0
  for (const t of node.reviewThreads?.nodes ?? []) {
    const a = t.comments?.nodes?.[0]?.author
    if (!a || mine(a)) continue
    if (bot(a)) bot_threads++
    else human_threads++
  }
  const human_comments = [...(node.reviews?.nodes ?? []), ...(node.comments?.nodes ?? [])].filter(
    (c: any) => String(c.body ?? "").trim() && c.author && !mine(c.author) && !bot(c.author),
  ).length
  return { human_threads, bot_threads, human_comments }
}

export function mergePlan(previous: BackfillPr[] | undefined, fresh: Omit<BackfillPr, "status" | "attempts">[]): BackfillPr[] {
  const prior = new Map((previous ?? []).map((p) => [p.number, p]))
  const out = fresh.map((p) => {
    const old = prior.get(p.number)
    return old ? { ...old, ...p, status: old.status === "running" ? "pending" : old.status } : { ...p, status: "pending" as const, attempts: 0 }
  })
  // Keep progress for PRs that dropped out of the window (e.g. a later --since).
  for (const old of previous ?? []) if (!out.some((p) => p.number === old.number) && old.status === "done") out.push(old)
  return out.sort((a, b) => a.merged_at.localeCompare(b.merged_at))
}

export async function plan(opts: { repo: string; since?: string; author?: string; cwd?: string }) {
  const repo = requireRepo(opts.repo)
  const author = opts.author ?? (process.env.FEEDBACK_GITHUB_LOGIN || "hoganmcdonald")
  const since = opts.since ?? monthsAgo(9)
  if (!/^\d{4}-\d{2}-\d{2}$/.test(since)) throw new Error("--since must be YYYY-MM-DD")
  const cwd = opts.cwd ?? process.cwd()

  const fresh: Omit<BackfillPr, "status" | "attempts">[] = []
  let total = 0
  let after: string | undefined
  for (;;) {
    const args = ["api", "graphql", "-f", `query=${PLAN_QUERY}`, "-f", `q=repo:${repo} author:${author} is:pr is:merged merged:>=${since}`]
    if (after) args.push("-f", `after=${after}`)
    const proc = Bun.spawnSync(["gh", ...args], { cwd, env: prc.toolEnv(), stdout: "pipe", stderr: "pipe" })
    if (proc.exitCode !== 0) throw new Error(`gh api graphql failed: ${new TextDecoder().decode(proc.stderr).trim()}`)
    const res = JSON.parse(new TextDecoder().decode(proc.stdout))
    if (res.errors?.length) throw new Error(res.errors.map((e: any) => e.message).join("; "))
    const page = res.data.search
    for (const n of page.nodes) {
      if (!n?.number) continue
      total++
      const counts = countFeedback(n, author)
      if (counts.human_threads + counts.bot_threads + counts.human_comments === 0) continue
      fresh.push({ number: n.number, url: n.url, title: n.title, merged_at: n.mergedAt, ...counts })
    }
    if (!page.pageInfo.hasNextPage) break
    after = page.pageInfo.endCursor
  }

  const previous = await readState(repo)
  const state: BackfillState = { repo, author, since, planned_at: new Date().toISOString(), prs: mergePlan(previous?.prs, fresh) }
  await writeState(state)
  return { state, merged_prs: total, with_feedback: fresh.length }
}

// --- Run ---------------------------------------------------------------------------

export function childPrompt(pr: BackfillPr, repo: string): string {
  return [
    `Backfill feedback memory from merged pull request ${pr.url} (${repo}#${pr.number}, merged ${pr.merged_at.slice(0, 10)}).`,
    `It has ${pr.human_threads} human review thread(s), ${pr.bot_threads} bot-raised thread(s), and ${pr.human_comments} human review summaries/comments.`,
    "Follow the feedback-accumulator skill and its reference/backfill.md exactly.",
    "Finish by capturing every qualifying lesson with feedback_capture, or call feedback_mark_reviewed if nothing qualifies.",
  ].join(" ")
}

export type ResultLine = { kind: string; id?: string; notice?: string }

export function summarizeResults(lines: ResultLine[]) {
  const results: Record<string, number> = {}
  const captured = new Set<string>()
  for (const l of lines) {
    results[l.kind] = (results[l.kind] ?? 0) + 1
    if (["created", "merged", "updated"].includes(l.kind) && l.id) captured.add(`${l.kind}:${l.id}`)
  }
  const processed = lines.some((l) => ["created", "merged", "updated", "unchanged", "skipped", "reviewed"].includes(l.kind))
  return { results, captured: captured.size, processed }
}

async function readResults(file: string): Promise<ResultLine[]> {
  const text = await readFile(file, "utf8").catch(() => "")
  return text
    .split("\n")
    .filter(Boolean)
    .flatMap((l) => {
      try {
        return [JSON.parse(l)]
      } catch {
        return []
      }
    })
}

// A pid lock per repository so two runners never interleave the same queue.
async function lock(repo: string, home = fb.feedbackHome()) {
  const file = `${statePath(repo, home)}.lock`
  if (existsSync(file)) {
    const pid = Number((await readFile(file, "utf8")).trim())
    let alive = false
    try {
      process.kill(pid, 0)
      alive = true
    } catch {}
    if (alive) throw new Error(`a backfill for ${repo} is already running (pid ${pid})`)
  }
  await writeFile(file, String(process.pid))
  return async () => rm(file, { force: true })
}

export async function runningPid(repo: string, home = fb.feedbackHome()): Promise<number | null> {
  const file = `${statePath(repo, home)}.lock`
  if (!existsSync(file)) return null
  const pid = Number((await readFile(file, "utf8")).trim())
  try {
    process.kill(pid, 0)
    return pid
  } catch {
    return null
  }
}

export function selectPrs(state: BackfillState, opts: { prs?: number[]; limit?: number; retryFailed?: boolean }): BackfillPr[] {
  if (opts.prs?.length) {
    const missing = opts.prs.filter((n) => !state.prs.some((p) => p.number === n))
    if (missing.length) throw new Error(`PR(s) ${missing.join(", ")} are not in the plan (no review discussion, or outside the window)`)
    return opts.prs.map((n) => state.prs.find((p) => p.number === n)!).sort((a, b) => a.merged_at.localeCompare(b.merged_at))
  }
  const queue = state.prs.filter((p) => p.status === "pending" || (opts.retryFailed && p.status === "failed"))
  return opts.limit ? queue.slice(0, opts.limit) : queue
}

export type RunOptions = {
  repo: string
  prs?: number[]
  limit?: number
  retryFailed?: boolean
  dir?: string
  timeoutMin?: number
  model?: string
  variant?: string
  log?: (line: string) => void
}

export async function run(opts: RunOptions) {
  const repo = requireRepo(opts.repo)
  const log = opts.log ?? ((l: string) => console.log(l))
  const state = await readState(repo)
  if (!state) throw new Error(`no backfill plan for ${repo}; run: feedback backfill plan --repo ${repo}`)
  const selected = selectPrs(state, opts)
  if (!selected.length) {
    log("Nothing to do: every planned PR has been processed.")
    return { processed: 0, captured: 0, failed: 0 }
  }

  const unlock = await lock(repo)
  const dir = opts.dir ?? process.cwd()
  const logs = logDir(repo)
  await mkdir(logs, { recursive: true })
  const timeoutMs = (opts.timeoutMin ?? DEFAULT_TIMEOUT_MIN) * 60000
  let captured = 0
  let failed = 0
  let processed = 0
  const record: BackfillRun = { started_at: new Date().toISOString(), prs: selected.map((p) => p.number), processed: 0, failed: 0, captured: 0 }
  state.runs = [...(state.runs ?? []), record].slice(-20)

  const save = async () => {
    // Re-read so a concurrent `plan` (new PRs) is not overwritten.
    const latest = (await readState(repo)) ?? state
    for (const p of state.prs) {
      const i = latest.prs.findIndex((x) => x.number === p.number)
      if (i >= 0) latest.prs[i] = p
    }
    Object.assign(record, { processed, failed, captured })
    latest.runs = state.runs
    await writeState(latest)
  }

  try {
    for (const [i, pr] of selected.entries()) {
      log(`[${i + 1}/${selected.length}] ${repo}#${pr.number} ${pr.title}`)
      const results = join(logs, `pr-${pr.number}.results.jsonl`)
      const transcript = join(logs, `pr-${pr.number}.jsonl`)
      await rm(results, { force: true })
      pr.status = "running"
      pr.attempts++
      pr.started_at = new Date().toISOString()
      pr.error = undefined
      await save()

      const cmd = ["opencode", "run", "--agent", BACKFILL_AGENT, "--format", "json", "--title", `Feedback backfill ${repo}#${pr.number}`]
      if (opts.model) cmd.push("--model", opts.model)
      if (opts.variant) cmd.push("--variant", opts.variant)
      cmd.push(childPrompt(pr, repo))
      const child = Bun.spawn(cmd, {
        cwd: dir,
        stdout: Bun.file(transcript),
        stderr: Bun.file(`${transcript}.stderr`),
        env: prc.toolEnv({
          FEEDBACK_CAPTURE_VIA: "backfill",
          FEEDBACK_RESULTS_FILE: results,
          FEEDBACK_FOOTER_MODE: "count",
          REVIEW_RUN_DIR: "",
          REVIEW_RUN_ID: "",
        }),
      })
      let timedOut = false
      const timer = setTimeout(() => {
        timedOut = true
        child.kill()
      }, timeoutMs)
      const code = await child.exited
      clearTimeout(timer)

      const summary = summarizeResults(await readResults(results))
      pr.results = summary.results
      pr.captured = summary.captured
      pr.finished_at = new Date().toISOString()
      pr.session_id = await sessionIdFrom(transcript)
      if (timedOut) pr.error = `timed out after ${opts.timeoutMin ?? DEFAULT_TIMEOUT_MIN} minutes`
      else if (code !== 0) pr.error = `opencode exited with ${code}; see ${basename(transcript)}.stderr`
      else if (!summary.processed) pr.error = "agent finished without capturing feedback or marking the PR reviewed"
      pr.status = pr.error ? "failed" : "done"
      if (pr.error) failed++
      else processed++
      captured += summary.captured
      await save()
      log(`    ${pr.status}${pr.error ? `: ${pr.error}` : ""} · ${summary.captured} captured · ${formatResults(summary.results)}`)
    }
  } finally {
    // An interrupted run leaves no PR stuck in "running".
    for (const p of state.prs) if (p.status === "running") p.status = "pending"
    record.finished_at = new Date().toISOString()
    await save().catch(() => {})
    await unlock()
  }

  const remaining = (await readState(repo))!.prs.filter((p) => p.status === "pending").length
  log("")
  log(`Processed ${processed} PR(s), ${failed} failed, ${remaining} still pending.`)
  if (captured > 0) log(`\n${FOOTER_TITLE}\n${countLine(captured)}`)
  return { processed, captured, failed, remaining }
}

async function sessionIdFrom(transcript: string): Promise<string | undefined> {
  const text = await readFile(transcript, "utf8").catch(() => "")
  return text.match(/"sessionID"\s*:\s*"(ses_[A-Za-z0-9]+)"/)?.[1]
}

function formatResults(results: Record<string, number>): string {
  const parts = Object.entries(results).map(([k, v]) => `${v} ${k}`)
  return parts.length ? parts.join(", ") : "no tool results"
}

// --- Status and purge -----------------------------------------------------------------

export async function status(repo: string) {
  const r = requireRepo(repo)
  const state = await readState(r)
  if (!state) return { repo: r, planned: false }
  const counts: Record<string, number> = {}
  for (const p of state.prs) counts[p.status] = (counts[p.status] ?? 0) + 1
  const captured = state.prs.reduce((n, p) => n + (p.captured ?? 0), 0)
  const pid = await runningPid(r)
  return {
    repo: r,
    planned: true,
    since: state.since,
    planned_at: state.planned_at,
    prs: state.prs.length,
    counts,
    captured,
    running: pid ? { pid, pr: state.prs.find((p) => p.status === "running")?.number ?? null } : null,
    failed: state.prs.filter((p) => p.status === "failed").map((p) => ({ number: p.number, error: p.error })),
    logs: logDir(r),
  }
}

export function formatStatus(s: Awaited<ReturnType<typeof status>>): string {
  if (!s.planned) return `No backfill plan for ${s.repo}. Run: feedback backfill plan --repo ${s.repo}`
  const st = s as Exclude<typeof s, { planned: false }>
  const lines = [
    `Backfill ${st.repo} (merged since ${st.since}): ${st.prs} PRs with review discussion`,
    `  ${Object.entries(st.counts)
      .map(([k, v]) => `${v} ${k}`)
      .join(", ")} · ${st.captured} feedback items captured so far`,
  ]
  if (st.running) lines.push(`  running now (pid ${st.running.pid})${st.running.pr ? ` on #${st.running.pr}` : ""}`)
  for (const f of st.failed.slice(0, 10)) lines.push(`  failed #${f.number}: ${f.error}`)
  lines.push(`  logs: ${st.logs}`)
  return lines.join("\n")
}

export async function purge(repo: string, dryRun = false) {
  const r = requireRepo(repo)
  if (await runningPid(r)) throw new Error(`a backfill for ${r} is running; stop it before purging`)
  const res = await fb.purgeBackfill(r, dryRun)
  if (!dryRun) {
    const state = await readState(r)
    if (state) {
      for (const p of state.prs) {
        p.status = "pending"
        p.attempts = 0
        p.captured = undefined
        p.results = undefined
        p.error = undefined
      }
      await writeState(state)
    }
    await rm(logDir(r), { recursive: true, force: true })
  }
  return res
}

// --- Detached runs ---------------------------------------------------------------------

// Run in a detached tmux session so the backfill survives the caller.
export async function detach(args: string[], dir: string, repo: string): Promise<string> {
  const session = `feedback-backfill/${repo.split("/")[1]}`
  const exists = Bun.spawnSync(["tmux", "has-session", "-t", `=${session}`]).exitCode === 0
  if (exists) throw new Error(`tmux session '${session}' already exists; attach to it or kill it first`)
  const self = `${process.env.HOME}/.config/zsh/bin/feedback`
  const quoted = [self, "backfill", "run", ...args.filter((a) => a !== "--detach")].map((a) => `'${a.replace(/'/g, `'\\''`)}'`).join(" ")
  const make = Bun.spawnSync(["tmux", "new-session", "-d", "-s", session, "-c", dir], { env: prc.toolEnv() })
  if (make.exitCode !== 0) throw new Error(`could not create tmux session: ${new TextDecoder().decode(make.stderr)}`)
  Bun.spawnSync(["tmux", "send-keys", "-t", `=${session}:`, quoted, "Enter"])
  return session
}

// --- CLI ---------------------------------------------------------------------------------

const HELP = `feedback backfill - prefill feedback memory from merged PRs

Usage:
  feedback backfill plan   --repo owner/repo [--since YYYY-MM-DD] [--author LOGIN]
  feedback backfill run    --repo owner/repo [--prs 1,2,3 | --limit N] [--retry-failed]
                           [--dir PATH] [--timeout MIN] [--model P/M] [--variant V] [--detach]
  feedback backfill status --repo owner/repo [--json]
  feedback backfill purge  --repo owner/repo [--dry-run]

plan lists your merged PRs since --since (default: 9 months ago) that have
review discussion and queues them, oldest first. run processes queued PRs one
at a time in fresh headless OpenCode sessions (the feedback-backfill agent);
it is resumable and safe to re-run. --dir is where those sessions run (use a
checkout of the repository). --detach runs in a tmux session instead.
purge removes everything a backfill captured and requeues every PR.
`

export async function main(argv: string[]) {
  const [cmd, ...rest] = argv
  const flags: Record<string, string | boolean> = {}
  for (let i = 0; i < rest.length; i++) {
    const a = rest[i]
    if (!a.startsWith("--")) continue
    const [k, v] = a.slice(2).split("=", 2)
    if (v !== undefined) flags[k] = v
    else if (["json", "detach", "dry-run", "retry-failed"].includes(k)) flags[k] = true
    else if (rest[i + 1] !== undefined && !rest[i + 1].startsWith("--")) flags[k] = rest[++i]
    else flags[k] = true
  }
  const str = (k: string) => (typeof flags[k] === "string" ? (flags[k] as string) : undefined)
  const num = (k: string) => (str(k) ? Number(str(k)) : undefined)
  const repo = str("repo") ?? fb.inferRepo(process.cwd()) ?? ""

  switch (cmd) {
    case "plan": {
      const res = await plan({ repo, since: str("since"), author: str("author") })
      const s = res.state
      const pending = s.prs.filter((p) => p.status === "pending")
      console.log(
        `Planned ${s.repo}: ${res.merged_prs} merged PRs since ${s.since}, ${res.with_feedback} with review discussion.\n` +
          `  queued: ${pending.length} · human threads ${pending.reduce((n, p) => n + p.human_threads, 0)} · bot threads ${pending.reduce((n, p) => n + p.bot_threads, 0)} · human summaries/comments ${pending.reduce((n, p) => n + p.human_comments, 0)}\n` +
          `  state: ${statePath(s.repo)}`,
      )
      return
    }
    case "run": {
      const r = requireRepo(repo)
      if (flags.detach) {
        const session = await detach(rest, str("dir") ?? process.cwd(), r)
        console.log(`Backfill running in tmux session '${session}'. Check progress: feedback backfill status --repo ${r}`)
        return
      }
      await run({
        repo: r,
        prs: str("prs")
          ?.split(",")
          .map((x) => Number(x.trim().replace("#", "")))
          .filter(Boolean),
        limit: num("limit"),
        retryFailed: Boolean(flags["retry-failed"]),
        dir: str("dir"),
        timeoutMin: num("timeout"),
        model: str("model"),
        variant: str("variant"),
      })
      return
    }
    case "status": {
      const s = await status(repo)
      console.log(flags.json ? JSON.stringify(s, null, 2) : formatStatus(s))
      return
    }
    case "purge": {
      console.log(JSON.stringify(await purge(repo, Boolean(flags["dry-run"])), null, 2))
      return
    }
    case undefined:
    case "-h":
    case "--help":
    case "help":
      console.log(HELP)
      return
    default:
      throw new Error(`unknown backfill command '${cmd}'\n\n${HELP}`)
  }
}

if (import.meta.main) {
  main(process.argv.slice(2)).catch((err) => {
    console.error(`feedback backfill: ${err?.message ?? err}`)
    process.exit(1)
  })
}
