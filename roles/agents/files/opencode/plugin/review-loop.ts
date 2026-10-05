// review-loop - PR review and feedback-memory tools for OpenCode.
//
// - pr_context: read-only, paginated PR context (overview, threads, diff, files)
// - feedback_*: search and maintain ~/.feedback, with capture receipts
// - review_*: launch and track agent reviews in dedicated worktrees/sessions
//
// It also keeps the loop automatic: loading open feedback on one of Hogan's
// PRs triggers capture, captured items are announced with a footer at the end
// of the response, and finished child reviews are surfaced to the parent.

import type { Plugin } from "@opencode-ai/plugin"
import { existsSync } from "node:fs"
import { rename, writeFile } from "node:fs/promises"
import { join } from "node:path"
import * as fb from "../lib/feedback-store.ts"
import * as prc from "../lib/pr-context.ts"
import * as core from "../lib/review-loop-core.ts"

// This file is symlinked into ~/.config/opencode/plugin, so bare-specifier
// resolution can start from the dotfiles checkout, which has no node_modules.
// Fall back to the copy OpenCode installs in its config directory.
const { tool } = (await import("@opencode-ai/plugin").catch(
  () => import(`${process.env.HOME}/.config/opencode/node_modules/@opencode-ai/plugin/dist/index.js`),
)) as typeof import("@opencode-ai/plugin")

const ME = (process.env.FEEDBACK_GITHUB_LOGIN || "hoganmcdonald").toLowerCase()
const RUN_DIR = process.env.REVIEW_RUN_DIR || ""
const RUN_ID = process.env.REVIEW_RUN_ID || ""
const REVIEW_BIN = process.env.REVIEW_BIN || `${process.env.HOME}/.config/zsh/bin/review`
const POLL_MS = 20000

type Receipt = { id: string; notice: string; action: string; pr?: string; at: string; shown: boolean; via?: string }

type Ledger = {
  session: string
  pending: Record<string, { open: number; total: number; detected_at: string }>
  receipts: Receipt[]
  launched_runs: string[]
  notified_runs: string[]
  relayed_runs: string[]
  unsummarized: { run_id: string; line: string; injected?: boolean }[]
}

const s = tool.schema
const z = {
  severity: s.enum(core.SEVERITIES),
  threadState: s.enum(fb.THREAD_STATES),
  disposition: s.enum(fb.DISPOSITIONS),
  kind: s.enum(fb.KINDS),
  status: s.enum(fb.STATUSES),
  confidence: s.enum(fb.CONFIDENCES),
  level: s.enum(fb.SCOPE_LEVELS),
}

const scopeSchema = s
  .object({
    level: z.level.describe("global = any codebase; language; repository; subsystem = one area of one repo"),
    repos: s.array(s.string()).optional().describe("owner/repo slugs"),
    languages: s.array(s.string()).optional(),
    subsystems: s.array(s.string()).optional().describe("areas such as query-cache, auth, billing-ui"),
  })
  .describe("Where the lesson applies. Do not widen a repository convention to global.")

const entryFields = {
  title: s.string().describe("Specific, imperative title, at most 100 characters"),
  notice: s.string().describe("At most 10 words; shown in the '💡 feedback captured' footer"),
  summary: s.string().describe("One sentence stating the lesson"),
  kind: z.kind,
  confidence: z.confidence.optional().describe("confirmed when the author agreed or fixed it"),
  status: z.status.optional(),
  scope: scopeSchema.optional(),
  concepts: s.array(s.string()).describe("Canonical topics, e.g. authorization, caching"),
  aliases: s
    .array(s.string())
    .describe("Synonyms, symptoms, abbreviations, and phrasings a future search might use (aim for 5+)"),
  symbols: s.array(s.string()).optional().describe("Functions, types, flags, tables involved"),
  paths: s.array(s.string()).optional().describe("Repository path globs, e.g. src/cache/**"),
  lesson: s.string().describe("The reusable rule, in one or two sentences"),
  applies_when: s.string().optional(),
  why: s.string().optional(),
  check: s.string().optional().describe("A concrete check a reviewer or author can perform"),
  exceptions: s.string().optional(),
}

export default (async ({ client, directory }) => {
  const ledgers = new Map<string, Ledger>()
  const parents = new Map<string, string | null>()
  const prChecked = new Map<string, number>()
  let runSession = ""
  let poller: ReturnType<typeof setInterval> | undefined

  // --- Sessions and ledgers ---------------------------------------------------

  async function rootOf(sessionID: string): Promise<string> {
    let id = sessionID
    for (let depth = 0; depth < 8; depth++) {
      let parent = parents.get(id)
      if (parent === undefined) {
        try {
          const res: any = await client.session.get({ path: { id } } as any)
          parent = res?.data?.parentID ?? null
        } catch {
          parent = null
        }
        parents.set(id, parent ?? null)
      }
      if (!parent) return id
      id = parent
    }
    return id
  }

  async function ledger(sessionID: string): Promise<Ledger> {
    const hit = ledgers.get(sessionID)
    if (hit) return hit
    const empty: Ledger = {
      session: sessionID,
      pending: {},
      receipts: [],
      launched_runs: [],
      notified_runs: [],
      relayed_runs: [],
      unsummarized: [],
    }
    let loaded = empty
    try {
      loaded = { ...empty, ...(await fb.readJson<Partial<Ledger>>(fb.sessionStatePath(sessionID), {})) } as Ledger
    } catch {
      // An unexpected session id format just means no persisted ledger.
    }
    ledgers.set(sessionID, loaded)
    return loaded
  }

  async function save(l: Ledger) {
    try {
      await fb.writeJson(fb.sessionStatePath(l.session), l)
    } catch (err) {
      log("warn", `could not persist ledger: ${err}`)
    }
  }

  function log(level: "debug" | "info" | "warn" | "error", message: string) {
    client.app?.log?.({ body: { service: "review-loop", level, message } } as any).catch?.(() => {})
  }

  function addReceipt(l: Ledger, r: fb.Receipt, via?: string) {
    if (l.receipts.some((x) => x.id === r.id && !x.shown)) return
    l.receipts.push({ id: r.id, notice: r.notice, action: r.action, pr: r.pr, at: new Date().toISOString(), shown: false, via })
  }

  // --- Raw server access (message parts) ---------------------------------------

  async function request(method: "GET" | "PATCH", url: string, path: Record<string, string>, body?: unknown) {
    const raw = (client as any)._client ?? (client as any).client
    const call = raw?.[method.toLowerCase()]
    if (typeof call !== "function") throw new Error("OpenCode client does not expose raw requests")
    const res = await call.call(raw, {
      url,
      path,
      query: { directory },
      body,
      headers: body ? { "Content-Type": "application/json" } : undefined,
    })
    if (res?.error) throw new Error(`${method} ${url}: ${JSON.stringify(res.error).slice(0, 200)}`)
    return res?.data
  }

  // Append the capture footer to the end of the last assistant message.
  async function enforceFooter(sessionID: string) {
    const l = await ledger(sessionID)
    const unshown = l.receipts.filter((r) => !r.shown)
    if (!unshown.length) return
    try {
      const messages: any[] = (await request("GET", "/session/{id}/message", { id: sessionID })) ?? []
      const last = [...messages].reverse().find((m) => m?.info?.role === "assistant")
      const textPart = last && [...(last.parts ?? [])].reverse().find((p: any) => p?.type === "text" && !p.synthetic)
      if (!textPart) return
      const next = core.appendFooter(String(textPart.text ?? ""), unshown)
      if (next !== null) {
        await request(
          "PATCH",
          "/session/{sessionID}/message/{messageID}/part/{partID}",
          { sessionID, messageID: textPart.messageID, partID: textPart.id },
          { ...textPart, text: next },
        )
      }
      for (const r of unshown) r.shown = true
      await save(l)
    } catch (err) {
      log("warn", `footer enforcement failed: ${err}`)
    }
  }

  // --- Feedback-read detection ---------------------------------------------------

  function captureNotice(pr: prc.PrRef, open: number, total: number): string {
    return [
      "",
      `[feedback-loop] ${pr.repo}#${pr.number} is authored by @${ME} and has ${open} open of ${total} review threads.`,
      "Load the `feedback-accumulator` skill now and capture actionable feedback with `feedback_capture`",
      "(or call `feedback_mark_reviewed` if nothing is actionable). Capture is part of loading feedback;",
      "do it even if the user asked for something else, then continue with their request.",
    ].join("\n")
  }

  // Returns the notice to append when a feedback read concerns one of Hogan's PRs.
  async function checkOwnPr(sessionID: string, hit: core.FeedbackRead, cwd: string): Promise<string> {
    let pr: prc.PrRef
    try {
      pr = await prc.resolvePr(hit.ref, cwd, hit.repo)
    } catch {
      return ""
    }
    const key = `${sessionID}:${pr.url}`
    if (Date.now() - (prChecked.get(key) ?? 0) < 5 * 60000) return ""
    prChecked.set(key, Date.now())
    try {
      const o = await prc.fetchOverview(pr, cwd, 120000)
      if (o.author.toLowerCase() !== ME) return ""
      if (o.threads.open === 0 && o.review_decision !== "CHANGES_REQUESTED") return ""
      const root = await rootOf(sessionID)
      const l = await ledger(root)
      l.pending[pr.url] = { open: o.threads.open, total: o.threads.total, detected_at: new Date().toISOString() }
      await save(l)
      return captureNotice(pr, o.threads.open, o.threads.total)
    } catch (err) {
      log("debug", `own-PR check failed for ${pr.url}: ${err}`)
      return ""
    }
  }

  function clearPending(l: Ledger, prUrl?: string) {
    const url = prUrl ? (prc.parsePrUrl(prUrl)?.url ?? prUrl) : undefined
    if (url && l.pending[url]) delete l.pending[url]
  }

  // --- Review CLI bridge -----------------------------------------------------------

  async function reviewCli(args: string[], cwd: string, parse = true): Promise<any> {
    if (!existsSync(REVIEW_BIN)) throw new Error(`review CLI not found at ${REVIEW_BIN}`)
    const proc = Bun.spawn([REVIEW_BIN, ...args], {
      cwd,
      stdout: "pipe",
      stderr: "pipe",
      env: prc.toolEnv({ REVIEW_COLOR: "never" }),
    })
    const [out, err, code] = await Promise.all([new Response(proc.stdout).text(), new Response(proc.stderr).text(), proc.exited])
    if (code !== 0) throw new Error((err.trim() || out.trim() || `review ${args[0]} failed (exit ${code})`).slice(0, 2000))
    if (!parse) return [out.trim(), err.trim()].filter(Boolean).join("\n")
    try {
      return JSON.parse(out)
    } catch {
      throw new Error(`unexpected output from review ${args[0]}: ${out.slice(0, 500)}`)
    }
  }

  function startPoller() {
    if (poller || RUN_DIR) return
    poller = setInterval(() => {
      pollRuns().catch((err) => log("debug", `poll failed: ${err}`))
    }, POLL_MS)
    ;(poller as any).unref?.()
  }

  // Announce finished child reviews to the session that launched them, and
  // keep the queue moving when earlier reviews end without dispatching.
  async function pollRuns() {
    const watching = [...ledgers.values()].filter((l) => l.launched_runs.some((id) => !l.notified_runs.includes(id)))
    if (!watching.length) {
      if (poller) clearInterval(poller)
      poller = undefined
      return
    }
    const status = await reviewCli(["status", "--json", "--all"], directory)
    const runs: core.RunRecord[] = status.runs ?? []
    for (const l of watching) {
      let changed = false
      for (const r of runs) {
        if (!l.launched_runs.includes(r.run_id) || l.notified_runs.includes(r.run_id)) continue
        if (!core.TERMINAL_RUN_STATES.includes(r.status)) continue
        l.notified_runs.push(r.run_id)
        changed = true
        // Stopped runs were cancelled on purpose; announcing them is noise.
        if (r.status === "stopped") continue
        l.unsummarized.push({ run_id: r.run_id, line: core.formatRun(r) })
        const verdict = r.result ? `${r.result.verdict} · ${core.formatCounts(r.result.counts)}` : r.status
        client.tui
          ?.showToast?.({
            body: {
              title: `Review #${r.pr} ${r.status}`,
              message: `${verdict}. Ask for a summary or run: review attach ${r.pr}`,
              variant: r.status === "completed" ? "success" : "warning",
              duration: 10000,
            },
          } as any)
          ?.catch?.(() => {})
      }
      if (changed) await save(l)
    }
    if ((status.counts?.queued ?? 0) > 0) await reviewCli(["dispatch", "--json"], directory).catch(() => {})
  }

  // --- Child review run status ---------------------------------------------------------

  async function writeRunFile(name: string, content: string) {
    if (!RUN_DIR) return
    const file = join(RUN_DIR, name)
    const tmp = `${file}.tmp.${process.pid}`
    await writeFile(tmp, content, "utf8")
    await rename(tmp, file)
  }

  async function writeRunStatus(status: string, detail?: string) {
    if (!RUN_DIR || !runSession) return
    // A submitted report is final; later idle turns (follow-up chat) keep it completed.
    if (existsSync(join(RUN_DIR, "result.json"))) {
      status = "completed"
      detail = undefined
    }
    await writeRunFile(
      "status.json",
      JSON.stringify(
        {
          status,
          detail: detail ?? null,
          opencode_session_id: runSession,
          pid: process.pid,
          run_id: RUN_ID,
          updated_at: new Date().toISOString(),
        },
        null,
        2,
      ) + "\n",
    ).catch((err) => log("warn", `could not write run status: ${err}`))
  }

  function spawnDispatch() {
    try {
      const proc = Bun.spawn([REVIEW_BIN, "dispatch", "--json"], {
        cwd: directory,
        stdout: "ignore",
        stderr: "ignore",
        env: prc.toolEnv({ REVIEW_RUN_DIR: "", REVIEW_RUN_ID: "" }),
      })
      proc.unref()
    } catch (err) {
      log("warn", `could not dispatch queued reviews: ${err}`)
    }
  }

  // --- Tools ------------------------------------------------------------------------------

  const tools = {
    pr_context: tool({
      description: [
        "Read-only GitHub pull request context, fetched in bounded slices and pinned to the PR's head/base SHAs.",
        "ops: overview (metadata, description, commits, changed files, checks, Linear ids, thread counts);",
        "threads (every review thread with replies, resolved/outdated state, review summaries, conversation comments, and source_key values for feedback capture);",
        "diff (unified diff; filter with path, paginate with offset/limit); file (file at head|base|sha with line windows);",
        "grep (git grep at a revision; requires the commits locally, e.g. inside the review worktree).",
        "pr accepts a URL, owner/repo#N, or a number in the current repository; omit it for the current branch's PR.",
      ].join(" "),
      args: {
        op: s.enum(["overview", "threads", "diff", "file", "grep"]),
        pr: s.string().optional(),
        state: s.enum(["all", "open", "resolved", "outdated"]).optional().describe("threads: filter (default all)"),
        path: s.string().optional().describe("diff/file/grep/threads: repository-relative path or prefix"),
        ref: s.string().optional().describe("file/grep: head (default), base, or a commit SHA"),
        start: s.number().int().optional().describe("file: first line"),
        end: s.number().int().optional().describe("file: last line"),
        pattern: s.string().optional().describe("grep: extended regular expression"),
        offset: s.number().int().optional().describe("diff: character offset for pagination"),
        limit: s.number().int().optional().describe("diff: characters per page; grep: max lines"),
        include_bots: s.boolean().optional().describe("threads: include bot comments"),
      },
      async execute(args, ctx) {
        const res: any = await prc.context(args as prc.ContextArgs, ctx.directory || directory)
        let text: string = res.text
        if (args.op === "threads" && res.discussion) {
          const d: prc.Discussion = res.discussion
          const open = d.threads.filter((t) => !t.resolved).length
          if (d.author.toLowerCase() === ME && open > 0) {
            const root = await rootOf(ctx.sessionID)
            const l = await ledger(root)
            l.pending[d.ref.url] = { open, total: d.threads.length, detected_at: new Date().toISOString() }
            await save(l)
            prChecked.set(`${ctx.sessionID}:${d.ref.url}`, Date.now())
            text += `\n${captureNotice(d.ref, open, d.threads.length)}`
          }
        }
        return text
      },
    }),

    feedback_search: tool({
      description: [
        "Search the local review-feedback memory (~/.feedback) for lessons relevant to code being reviewed or written.",
        "Returns compact matches only; call feedback_show for the few that apply.",
        "Recall beats precision here: use several terms (behaviour, failure mode, subsystem, symbols, synonyms),",
        "search more than once as the work reveals new areas, and broaden or page with offset when results are thin.",
      ].join(" "),
      args: {
        query: s.string().describe("Free text: concepts, symptoms, subsystem names, synonyms"),
        repo: s.string().optional().describe("owner/repo to boost repository-scoped lessons"),
        paths: s.array(s.string()).optional().describe("Changed file paths to match lesson path globs"),
        symbols: s.array(s.string()).optional(),
        kind: z.kind.optional(),
        limit: s.number().int().optional(),
        offset: s.number().int().optional(),
        include_inactive: s.boolean().optional().describe("Also return retired and superseded lessons"),
      },
      async execute(args) {
        return fb.formatSearch(await fb.search(args as fb.SearchOptions))
      },
    }),

    feedback_show: tool({
      description: "Read full feedback entries (lesson, rationale, checks, exceptions, source PR links) by id.",
      args: { ids: s.array(s.string()).min(1).max(10) },
      async execute(args) {
        return fb.show(args.ids)
      },
    }),

    feedback_capture: tool({
      description: [
        "Record one actionable lesson from review feedback on Hogan's PRs into ~/.feedback.",
        "Pass the comment's source (key from pr_context threads output, PR URL, comment URL, reviewer, thread state, disposition).",
        "A source key seen before only updates its handling state. A new lesson needs `entry`;",
        "if similar lessons exist you get candidates back: retry with merge_into=<id> for a recurrence or force_new=true for a distinct lesson.",
        "Use the feedback-accumulator skill for what qualifies and how to scope it.",
      ].join(" "),
      args: {
        source: s.object({
          key: s.string().describe("e.g. github:owner/repo#123:thread:PRRT_abc (from pr_context threads)"),
          pr: s.string().describe("URL of the PR where the feedback was given"),
          url: s.string().describe("URL of the specific comment or review (printed under each comment by pr_context)"),
          reviewer: s.string().describe("GitHub login of the reviewer who raised it"),
          thread_state: z.threadState,
          disposition: z.disposition.describe("pending until there is evidence it was addressed, declined, or disputed"),
          handled_pr: s.string().optional().describe("PR where it was handled"),
          handled_url: s.string().optional().describe("Evidence: fixing commit or reply URL"),
          excerpt: s.string().optional().describe("Short quote of the reviewer's point (<= 300 chars)"),
        }),
        entry: s.object(entryFields).optional(),
        merge_into: s.string().optional(),
        force_new: s.boolean().optional(),
      },
      async execute(args, ctx) {
        const res = await fb.capture(args as fb.CaptureInput)
        const root = await rootOf(ctx.sessionID)
        const l = await ledger(root)
        clearPending(l, args.source.pr)
        if ("receipt" in res) addReceipt(l, res.receipt)
        await save(l)
        const reminder =
          "receipt" in res
            ? `\nEnd your final response with the footer:\n${core.formatFooter(l.receipts.filter((r) => !r.shown))}`
            : ""
        return JSON.stringify(res, null, 2) + reminder
      },
    }),

    feedback_mark_reviewed: tool({
      description: "Mark loaded feedback on one of Hogan's PRs as processed when nothing in it is worth capturing.",
      args: { pr: s.string().describe("PR URL"), note: s.string().describe("Why nothing was captured") },
      async execute(args, ctx) {
        const l = await ledger(await rootOf(ctx.sessionID))
        clearPending(l, args.pr)
        await save(l)
        return `Marked ${args.pr} as processed: ${args.note}`
      },
    }),

    feedback_revise: tool({
      description:
        "Edit an existing feedback entry when the user asks, or when a lesson is clearly wrong, too broad, or poorly tagged. Tags merge unless replace_tags is true.",
      args: {
        id: s.string(),
        note: s.string().describe("Why the entry changed"),
        changes: s
          .object({
            ...Object.fromEntries(Object.entries(entryFields).map(([k, v]) => [k, (v as any).optional()])),
            replace_tags: s.boolean().optional(),
          })
          .describe("Only the fields to change"),
      },
      async execute(args) {
        return JSON.stringify(await fb.revise(args.id, args.changes as fb.ReviseInput, args.note), null, 2)
      },
    }),

    feedback_retire: tool({
      description:
        "Retire a feedback entry that no longer applies, or mark it superseded by another. Retired sources are never re-captured.",
      args: { id: s.string(), reason: s.string(), superseded_by: s.string().optional() },
      async execute(args) {
        return JSON.stringify(await fb.retire(args.id, args.reason, args.superseded_by), null, 2)
      },
    }),

    review_start: tool({
      description: [
        "Launch agent code reviews, each in its own detached review worktree and tmux session (your tmux client is not switched).",
        "Pass PR refs (numbers, URLs, branches, Linear ids) and/or next=N to take the next N PRs awaiting your review.",
        "Runs beyond the active limit are queued. Duplicate or already-reviewed heads are reused, not relaunched (force=true re-reviews).",
        "Finished reviews are announced here; use review_status and review_result to follow up.",
      ].join(" "),
      args: {
        refs: s.array(s.string()).optional(),
        next: s.number().int().min(1).max(20).optional(),
        max_active: s.number().int().min(1).max(10).optional(),
        force: s.boolean().optional(),
      },
      async execute(args, ctx) {
        if (RUN_DIR) return "This session is itself an agent review run; do not launch nested reviews. Review the PR here."
        const cli = ["start", "--json", "--parent-session", ctx.sessionID]
        if (args.next) cli.push("--next", String(args.next))
        if (args.max_active) cli.push("--max-active", String(args.max_active))
        if (args.force) cli.push("--force")
        cli.push(...(args.refs ?? []))
        const res = await reviewCli(cli, ctx.directory || directory)
        const l = await ledger(await rootOf(ctx.sessionID))
        for (const r of res.runs ?? []) {
          if (r.run_id && !l.launched_runs.includes(r.run_id)) l.launched_runs.push(r.run_id)
          // Already-finished runs are reported now, so do not announce them again.
          if (r.run_id && core.TERMINAL_RUN_STATES.includes(r.status) && !l.notified_runs.includes(r.run_id)) {
            l.notified_runs.push(r.run_id)
          }
        }
        await save(l)
        startPoller()
        return [
          `Review runs (max ${res.max_active} running at once):`,
          ...(res.runs ?? []).map((r: core.RunRecord) => core.formatRun(r)),
          "",
          "Sessions run independently; you will be notified as they finish. `review attach <pr>` opens one.",
        ].join("\n")
      },
    }),

    review_status: tool({
      description: "Show agent review runs for this repository: queued, running, waiting on input, completed, failed, or interrupted.",
      args: { all: s.boolean().optional().describe("Include older runs, not just the latest per PR") },
      async execute(args, ctx) {
        const res = await reviewCli(["status", "--json", ...(args.all ? ["--all"] : [])], ctx.directory || directory)
        const runs: core.RunRecord[] = res.runs ?? []
        if (!runs.length) return "No agent review runs in this repository."
        const counts = Object.entries(res.counts ?? {})
          .map(([k, v]) => `${v} ${k}`)
          .join(", ")
        return [`${runs.length} run(s): ${counts} (max ${res.max_active} running)`, ...runs.map(core.formatRun)].join("\n")
      },
    }),

    review_result: tool({
      description:
        "Get the latest agent review result for a PR (or a run id): verdict, finding counts, summary, captured feedback, and optionally the full report.",
      args: { ref: s.string(), full: s.boolean().optional().describe("Include the full markdown report") },
      async execute(args, ctx) {
        const r = await reviewCli(["result", args.ref, "--json", ...(args.full ? ["--full"] : [])], ctx.directory || directory)
        const l = await ledger(await rootOf(ctx.sessionID))
        l.unsummarized = l.unsummarized.filter((u) => u.run_id !== r.run_id)
        const captured: core.ReceiptLike[] = r.result?.feedback_captured ?? []
        if (captured.length && !l.relayed_runs.includes(r.run_id)) {
          l.relayed_runs.push(r.run_id)
          for (const c of captured) {
            addReceipt(l, { action: "created", id: c.id, notice: c.notice, title: c.notice, file: "" }, `relayed:${r.run_id}`)
          }
        }
        await save(l)
        const lines = [core.formatRun(r)]
        if (r.head_sha && r.result?.head_sha_reviewed && r.result.head_sha_reviewed !== r.head_sha) {
          lines.push(`  note: reviewed ${r.result.head_sha_reviewed.slice(0, 10)}, launched at ${r.head_sha.slice(0, 10)}`)
        }
        if (captured.length) lines.push(`  feedback captured in that session: ${captured.map((c) => c.notice).join("; ")}`)
        if (r.report) lines.push(`  report: ${r.report}`)
        if (r.report_markdown) lines.push("", r.report_markdown)
        return lines.join("\n")
      },
    }),

    review_cleanup: tool({
      description: [
        "Kill, stop, cancel, or clean up agent reviews and review sessions created by the review CLI / review_start in this repository.",
        "Omit ref to clean up every review here. By default this cancels queued reviews, stops running ones, kills their tmux sessions,",
        "and removes their .worktrees/reviews/pr-<n> worktrees. Review results are kept and branches are never touched.",
        "Worktrees with local changes are skipped and reported unless force_dirty=true (only with the user's go-ahead).",
        "keep_worktrees=true only stops the agents. dry_run=true previews without changing anything.",
      ].join(" "),
      args: {
        ref: s.string().optional().describe("One PR (number, URL, branch, Linear id); omit for all reviews"),
        keep_worktrees: s.boolean().optional().describe("Only stop agents; leave worktrees and sessions"),
        force_dirty: s.boolean().optional().describe("Also remove review worktrees that have local changes"),
        dry_run: s.boolean().optional(),
      },
      async execute(args, ctx) {
        if (RUN_DIR) return "This session is an agent review run; run cleanup from the main worktree instead."
        const cwd = ctx.directory || directory
        // Tearing down the session this agent runs in would kill it mid-call.
        if (/\/\.worktrees\/reviews\/pr-\d+(\/|$)/.test(cwd)) {
          return "This session runs inside a review worktree, so cleanup would kill it. Run it from the main worktree, or in a shell: review clear --stop"
        }
        let out: string
        if (args.keep_worktrees) {
          if (args.dry_run) {
            const st = await reviewCli(["status", "--json"], cwd)
            const active = (st.runs ?? []).filter((r: core.RunRecord) => !core.TERMINAL_RUN_STATES.includes(r.status))
            out = active.length
              ? `Would stop:\n${active.map(core.formatRun).join("\n")}`
              : "No active agent reviews."
          } else {
            out = await reviewCli(args.ref ? ["stop", args.ref] : ["stop", "--all"], cwd, false)
          }
        } else {
          const cli = ["clear", "--stop"]
          if (args.force_dirty) cli.push("--force")
          if (args.dry_run) cli.push("--dry-run")
          if (args.ref) cli.push(args.ref)
          out = await reviewCli(cli, cwd, false)
        }
        return out || "Nothing to clean up."
      },
    }),

    review_submit: tool({
      description: [
        "Submit the final report of this agent review run so the requesting session and `review result` can see it.",
        "Call once at the end of a review (again only if you revise the review). Outside a review run this just reminds you to present the report in chat.",
      ].join(" "),
      args: {
        verdict: s.enum(["approve", "comment", "request_changes"]),
        summary: s.string().describe("Two or three sentences: overall assessment and the most important risks"),
        head_sha_reviewed: s.string().describe("The PR head SHA the review actually covered"),
        findings: s
          .array(
            s.object({
              severity: z.severity,
              title: s.string(),
              location: s.string().optional().describe("path:line"),
              status: s.enum(["new", "existing", "regression"]).optional().describe("existing = already raised in a PR thread"),
              thread_url: s.string().optional(),
            }),
          )
          .describe("Every finding in the report, in report order"),
        coverage: s.string().describe("What was and was not reviewed, and any missing context"),
        report: s.string().describe("The full markdown report exactly as presented to the user"),
      },
      async execute(args, ctx) {
        if (!RUN_DIR) return "Not inside an agent review run; present the report directly in the conversation."
        const l = await ledger(await rootOf(ctx.sessionID))
        const result = {
          run_id: RUN_ID,
          pr_url: process.env.REVIEW_PR_URL ?? null,
          verdict: args.verdict,
          summary: args.summary,
          head_sha_reviewed: args.head_sha_reviewed,
          head_sha_launched: process.env.REVIEW_HEAD_SHA ?? null,
          counts: core.countFindings(args.findings),
          findings: args.findings,
          coverage: args.coverage,
          feedback_captured: l.receipts.map((r) => ({ id: r.id, notice: r.notice })),
          opencode_session_id: runSession || ctx.sessionID,
          submitted_at: new Date().toISOString(),
        }
        await writeRunFile("report.md", args.report.trimEnd() + "\n")
        await writeRunFile("result.json", JSON.stringify(result, null, 2) + "\n")
        await writeRunStatus("completed")
        spawnDispatch()
        return `Report saved for run ${RUN_ID} (${core.formatCounts(result.counts)}). The requesting session will be notified. Present the report to the user as your final response.`
      },
    }),
  }

  // --- Hooks -------------------------------------------------------------------------------

  return {
    tool: tools,

    event: async ({ event }) => {
      const e = event as any
      const type = e.type as string
      const props = e.properties ?? {}

      if (type === "session.created" || type === "session.updated") {
        const info = props.info
        if (info?.id) parents.set(info.id, info.parentID ?? null)
        if (type === "session.created" && RUN_DIR && !runSession && info?.id && !info.parentID) {
          runSession = info.id
          await writeRunStatus("starting")
        }
        return
      }

      if (type === "session.idle") {
        const id = props.sessionID
        if (!id || (parents.get(id) ?? null) !== null) return
        await enforceFooter(id)
        // Completion notices are shown for one turn; review_status recovers them.
        const l = ledgers.get(id)
        if (l?.unsummarized.some((u) => u.injected)) {
          l.unsummarized = l.unsummarized.filter((u) => !u.injected)
          await save(l)
        }
        if (RUN_DIR && id === runSession) await writeRunStatus("idle", "agent finished its turn without submitting a report")
        return
      }

      if (!RUN_DIR || !runSession) return
      const sid = props.sessionID ?? props.info?.sessionID
      if (type === "session.status" && sid === runSession) {
        const st = props.status?.type
        if (st === "busy" || st === "retry") await writeRunStatus("running")
      } else if ((type === "permission.asked" || type === "permission.updated" || type === "question.asked") && sid) {
        if ((await rootOf(sid)) === runSession) await writeRunStatus("waiting", "waiting for user input in the review session")
      } else if ((type === "permission.replied" || type === "question.replied" || type === "question.rejected") && sid) {
        if ((await rootOf(sid)) === runSession) await writeRunStatus("running")
      } else if (type === "session.error" && sid === runSession) {
        const name = props.error?.name ?? "error"
        if (name !== "MessageAbortedError") {
          await writeRunStatus("failed", `${name}: ${String(props.error?.data?.message ?? "").slice(0, 300)}`)
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      if (input.tool === "bash") {
        const hit = core.detectFeedbackRead(input.args?.command ?? "")
        if (!hit) return
        const notice = await checkOwnPr(input.sessionID, hit, input.args?.workdir || directory)
        if (notice) output.output = `${output.output ?? ""}\n${notice}`
      } else if (input.tool === "webfetch") {
        const hit = core.detectFeedbackUrl(input.args?.url ?? "")
        if (!hit) return
        const notice = await checkOwnPr(input.sessionID, hit, directory)
        if (notice) output.output = `${output.output ?? ""}\n${notice}`
      }
    },

    "experimental.chat.system.transform": async (input, output) => {
      const id = input.sessionID
      if (!id) return
      if ((parents.get(id) ?? null) !== null) return
      const l = ledgers.get(id) ?? (existsSync(fb.sessionStatePath(id)) ? await ledger(id) : undefined)
      if (!l) return
      const lines: string[] = []
      const pending = Object.entries(l.pending)
      if (pending.length) {
        lines.push(
          `[feedback-loop] Review feedback loaded on @${ME}'s PRs has not been processed: ${pending
            .map(([url, p]) => `${url} (${p.open} open threads)`)
            .join(", ")}. Load the feedback-accumulator skill and capture it with feedback_capture, or call feedback_mark_reviewed when nothing is actionable.`,
        )
      }
      const unshown = l.receipts.filter((r) => !r.shown)
      if (unshown.length) {
        lines.push(
          `[feedback-loop] Feedback was captured in this session. End your final response to the user with exactly:\n${core.formatFooter(unshown)}`,
        )
      }
      if (l.unsummarized.length) {
        for (const u of l.unsummarized) u.injected = true
        lines.push(
          `[review-loop] Agent reviews you launched have finished:\n${l.unsummarized.map((u) => u.line).join("\n")}\nTell the user, and use review_result for details they ask about.`,
        )
      }
      if (lines.length) output.system.push(lines.join("\n\n"))
    },

    "experimental.session.compacting": async (input, output) => {
      const l = ledgers.get(input.sessionID)
      if (!l) return
      const notes: string[] = []
      if (Object.keys(l.pending).length) notes.push(`Unprocessed feedback on own PRs: ${Object.keys(l.pending).join(", ")}`)
      const unshown = l.receipts.filter((r) => !r.shown)
      if (unshown.length) notes.push(`Feedback captured but not yet announced: ${unshown.map((r) => `${r.id} (${r.notice})`).join("; ")}`)
      const active = l.launched_runs.filter((id) => !l.notified_runs.includes(id))
      if (active.length) notes.push(`Agent review runs launched and still in progress: ${active.join(", ")}`)
      if (l.unsummarized.length) notes.push(`Finished review runs not yet summarised: ${l.unsummarized.map((u) => u.run_id).join(", ")}`)
      if (notes.length) output.context.push(`## Review and feedback loop state\n${notes.map((n) => `- ${n}`).join("\n")}`)
    },
  }
}) satisfies Plugin
