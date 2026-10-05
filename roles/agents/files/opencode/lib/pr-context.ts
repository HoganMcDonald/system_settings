#!/usr/bin/env bun
//
// pr-context - Read-only, paginated, revision-pinned pull request context.
//
// Every GitHub call here is a fixed read query (GraphQL queries or REST GETs),
// so agents can inspect a PR in bounded slices without broad `gh api` access.
// Shared by the OpenCode plugin (`pr_context` tool) and the `pr-context` CLI.

// --- Types -------------------------------------------------------------------

export type PrRef = { owner: string; name: string; repo: string; number: number; url: string }

export type Commit = { oid: string; headline: string; body: string; author: string; date: string }
export type ChangedFile = { path: string; additions: number; deletions: number; change: string }
export type Check = { name: string; state: string }

export type Overview = {
  ref: PrRef
  title: string
  body: string
  state: string
  draft: boolean
  author: string
  created: string
  updated: string
  base_ref: string
  head_ref: string
  base_sha: string
  head_sha: string
  mergeable: string
  review_decision: string
  additions: number
  deletions: number
  labels: string[]
  closing_issues: string[]
  commits: Commit[]
  commits_total: number
  files: ChangedFile[]
  files_total: number
  checks_state: string
  checks: Check[]
  threads: { total: number; open: number; resolved: number; outdated: number }
  reviews: { author: string; state: string; submitted: string }[]
  conversation_comments: number
  linear_ids: string[]
  linear_candidates: string[]
}

export type ThreadComment = {
  id: string
  url: string
  author: string
  body: string
  created: string
  commit?: string
  outdated: boolean
}

export type Thread = {
  id: string
  path: string
  line: number | null
  original_line: number | null
  resolved: boolean
  outdated: boolean
  resolved_by?: string
  hunk: string
  comments: ThreadComment[]
}

export type Discussion = {
  ref: PrRef
  author: string
  head_sha: string
  threads: Thread[]
  comments: ThreadComment[]
  reviews: (ThreadComment & { state: string })[]
  bot_comments_hidden: number
}

// --- Process helpers ---------------------------------------------------------

// Environment for git/gh subprocesses. A tmux server started from a Nix shell
// leaks DEVELOPER_DIR/SDKROOT into every pane, which breaks Apple's /usr/bin/git
// shim ("tool 'git' not found"). None of these tools need an SDK.
export function toolEnv(extra: Record<string, string> = {}): Record<string, string> {
  const env: Record<string, string> = {}
  for (const [k, v] of Object.entries(process.env)) if (v !== undefined) env[k] = v
  delete env.DEVELOPER_DIR
  delete env.SDKROOT
  return { ...env, GH_PAGER: "", PAGER: "cat", ...extra }
}

async function run(cmd: string[], cwd: string, allowFail = false): Promise<{ code: number; out: string; err: string }> {
  const proc = Bun.spawn(cmd, { cwd, stdout: "pipe", stderr: "pipe", env: toolEnv() })
  const [out, err, code] = await Promise.all([new Response(proc.stdout).text(), new Response(proc.stderr).text(), proc.exited])
  if (code !== 0 && !allowFail) throw new Error(`${cmd.slice(0, 3).join(" ")} failed (exit ${code}): ${err.trim() || out.trim()}`)
  return { code, out, err }
}

async function gh(args: string[], cwd: string): Promise<string> {
  return (await run(["gh", ...args], cwd)).out
}

async function graphql(query: string, vars: Record<string, string | number | undefined>, cwd: string): Promise<any> {
  const args = ["api", "graphql", "-f", `query=${query}`]
  for (const [k, v] of Object.entries(vars)) {
    if (v === undefined || v === null) continue
    args.push(typeof v === "number" ? "-F" : "-f", `${k}=${v}`)
  }
  const res = JSON.parse(await gh(args, cwd))
  if (res.errors?.length) throw new Error(`GitHub GraphQL: ${res.errors.map((e: any) => e.message).join("; ")}`)
  return res.data
}

export async function hasLocalCommit(sha: string, cwd: string): Promise<boolean> {
  if (!/^[0-9a-f]{7,40}$/.test(sha)) return false
  return (await run(["git", "cat-file", "-e", `${sha}^{commit}`], cwd, true)).code === 0
}

// --- Ref resolution ------------------------------------------------------------

const PR_URL_RE = /^https?:\/\/(?:www\.)?github\.com\/([^/\s]+)\/([^/\s]+)\/pull\/(\d+)/
const repoCache = new Map<string, string>()

export function parsePrUrl(s: string): PrRef | null {
  const m = s.trim().match(PR_URL_RE)
  if (!m) return null
  const repo = `${m[1]}/${m[2]}`
  return { owner: m[1], name: m[2], repo, number: Number(m[3]), url: `https://github.com/${repo}/pull/${m[3]}` }
}

async function currentRepo(cwd: string): Promise<string> {
  const hit = repoCache.get(cwd)
  if (hit) return hit
  const repo = (await gh(["repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"], cwd)).trim()
  repoCache.set(cwd, repo)
  return repo
}

export async function resolvePr(ref: string | number | undefined, cwd: string, repoHint?: string): Promise<PrRef> {
  const s = String(ref ?? "").trim()
  const fromUrl = parsePrUrl(s)
  if (fromUrl) return fromUrl
  const short = s.match(/^([\w.-]+\/[\w.-]+)#(\d+)$/)
  if (short) {
    const [owner, name] = short[1].split("/")
    return { owner, name, repo: short[1], number: Number(short[2]), url: `https://github.com/${short[1]}/pull/${short[2]}` }
  }
  if (/^#?\d+$/.test(s)) {
    const repo = repoHint || (await currentRepo(cwd))
    const [owner, name] = repo.split("/")
    const number = Number(s.replace("#", ""))
    return { owner, name, repo, number, url: `https://github.com/${repo}/pull/${number}` }
  }
  if (s) throw new Error(`cannot resolve PR '${s}'; use a PR URL, owner/repo#N, or a number`)
  // No ref: the published PR for the current branch.
  const url = (await gh(["pr", "view", "--json", "url", "-q", ".url"], cwd)).trim()
  const parsed = parsePrUrl(url)
  if (!parsed) throw new Error("no published PR found for the current branch")
  return parsed
}

// --- Linear ids ------------------------------------------------------------------

const NOT_TICKETS = new Set(["UTF", "ISO", "SHA", "RFC", "CVE", "HTTP", "TLS", "SSL", "MD", "ES", "GPT", "PR"])

export function extractLinearIds(texts: string[]): string[] {
  const out = new Set<string>()
  for (const t of texts) {
    for (const m of (t ?? "").matchAll(/linear\.app\/[^/\s]+\/issue\/([A-Za-z][A-Za-z0-9]*-\d+)/g)) out.add(m[1].toUpperCase())
    for (const m of (t ?? "").matchAll(/(?<![A-Za-z0-9])([A-Za-z][A-Za-z0-9]{1,9})-(\d{1,6})(?![A-Za-z0-9])/g)) {
      const team = m[1].toUpperCase()
      if (NOT_TICKETS.has(team) || /^\d/.test(team)) continue
      // Lowercase matches only count inside branch-like strings (hogan/hex-123-fix).
      if (m[1] !== team && !/[/_]/.test(t)) continue
      out.add(`${team}-${m[2]}`)
    }
  }
  return [...out]
}

// --- Overview --------------------------------------------------------------------

const OVERVIEW_QUERY = `query($owner:String!,$name:String!,$number:Int!){
  repository(owner:$owner,name:$name){ pullRequest(number:$number){
    number title url state isDraft body createdAt updatedAt author{login}
    baseRefName headRefName baseRefOid headRefOid mergeable reviewDecision additions deletions
    labels(first:30){nodes{name}}
    closingIssuesReferences(first:10){nodes{url}}
    commits(first:100){ totalCount pageInfo{hasNextPage endCursor}
      nodes{ commit{ oid messageHeadline messageBody authoredDate author{name} } } }
    files(first:100){ totalCount pageInfo{hasNextPage endCursor} nodes{ path additions deletions changeType } }
    reviewThreads(first:100){ totalCount pageInfo{hasNextPage endCursor} nodes{ isResolved isOutdated } }
    reviews(last:50){ nodes{ state submittedAt author{login} } }
    comments{ totalCount }
    last: commits(last:1){ nodes{ commit{ statusCheckRollup{ state contexts(first:100){ nodes{
      __typename ... on CheckRun{ name status conclusion } ... on StatusContext{ context state } } } } } } }
  } } }`

const PAGE_QUERIES: Record<string, string> = {
  commits: `query($owner:String!,$name:String!,$number:Int!,$after:String){ repository(owner:$owner,name:$name){ pullRequest(number:$number){
    commits(first:100,after:$after){ pageInfo{hasNextPage endCursor} nodes{ commit{ oid messageHeadline messageBody authoredDate author{name} } } } } } }`,
  files: `query($owner:String!,$name:String!,$number:Int!,$after:String){ repository(owner:$owner,name:$name){ pullRequest(number:$number){
    files(first:100,after:$after){ pageInfo{hasNextPage endCursor} nodes{ path additions deletions changeType } } } } }`,
  reviewThreads: `query($owner:String!,$name:String!,$number:Int!,$after:String){ repository(owner:$owner,name:$name){ pullRequest(number:$number){
    reviewThreads(first:100,after:$after){ pageInfo{hasNextPage endCursor} nodes{ isResolved isOutdated } } } } }`,
}

async function drain(pr: PrRef, field: string, first: any, cwd: string): Promise<any[]> {
  const nodes = [...(first?.nodes ?? [])]
  let page = first?.pageInfo
  while (page?.hasNextPage) {
    const data = await graphql(PAGE_QUERIES[field], { owner: pr.owner, name: pr.name, number: pr.number, after: page.endCursor }, cwd)
    const conn = data.repository.pullRequest[field]
    nodes.push(...conn.nodes)
    page = conn.pageInfo
  }
  return nodes
}

const overviewCache = new Map<string, { at: number; value: Overview }>()

export async function fetchOverview(pr: PrRef, cwd: string, maxAgeMs = 0): Promise<Overview> {
  const key = `${pr.repo}#${pr.number}`
  const hit = overviewCache.get(key)
  if (hit && Date.now() - hit.at < maxAgeMs) return hit.value

  const data = await graphql(OVERVIEW_QUERY, { owner: pr.owner, name: pr.name, number: pr.number }, cwd)
  const p = data.repository?.pullRequest
  if (!p) throw new Error(`PR ${key} not found`)
  const commits = (await drain(pr, "commits", p.commits, cwd)).map((n: any) => ({
    oid: n.commit.oid,
    headline: n.commit.messageHeadline,
    body: n.commit.messageBody ?? "",
    author: n.commit.author?.name ?? "",
    date: n.commit.authoredDate,
  }))
  const files = (await drain(pr, "files", p.files, cwd)).map((n: any) => ({
    path: n.path,
    additions: n.additions,
    deletions: n.deletions,
    change: String(n.changeType ?? "").toLowerCase(),
  }))
  const threadNodes = await drain(pr, "reviewThreads", p.reviewThreads, cwd)
  const rollup = p.last?.nodes?.[0]?.commit?.statusCheckRollup
  const checks: Check[] = (rollup?.contexts?.nodes ?? []).map((c: any) =>
    c.__typename === "CheckRun"
      ? { name: c.name, state: String(c.conclusion ?? c.status ?? "").toLowerCase() }
      : { name: c.context, state: String(c.state ?? "").toLowerCase() },
  )
  const value: Overview = {
    ref: pr,
    title: p.title,
    body: p.body ?? "",
    state: p.state,
    draft: p.isDraft,
    author: p.author?.login ?? "ghost",
    created: p.createdAt,
    updated: p.updatedAt,
    base_ref: p.baseRefName,
    head_ref: p.headRefName,
    base_sha: p.baseRefOid,
    head_sha: p.headRefOid,
    mergeable: p.mergeable,
    review_decision: p.reviewDecision ?? "",
    additions: p.additions,
    deletions: p.deletions,
    labels: (p.labels?.nodes ?? []).map((l: any) => l.name),
    closing_issues: (p.closingIssuesReferences?.nodes ?? []).map((i: any) => i.url),
    commits,
    commits_total: p.commits.totalCount,
    files,
    files_total: p.files.totalCount,
    checks_state: String(rollup?.state ?? "none").toLowerCase(),
    checks,
    threads: {
      total: threadNodes.length,
      open: threadNodes.filter((t: any) => !t.isResolved).length,
      resolved: threadNodes.filter((t: any) => t.isResolved).length,
      outdated: threadNodes.filter((t: any) => t.isOutdated).length,
    },
    reviews: (p.reviews?.nodes ?? []).map((r: any) => ({ author: r.author?.login ?? "ghost", state: r.state, submitted: r.submittedAt })),
    conversation_comments: p.comments?.totalCount ?? 0,
    linear_ids: [],
    linear_candidates: [],
  }
  // Strong signals: title, branch, commit headlines, and explicit Linear links.
  // Bare IDs in prose ("LINUX-386") are only candidates to verify in Linear.
  const linkIds = extractLinearIds([...(p.body ?? "").matchAll(/https?:\/\/linear\.app\/\S+/g)].map((m) => m[0]))
  value.linear_ids = [...new Set([...extractLinearIds([p.title, p.headRefName, ...commits.map((c) => c.headline)]), ...linkIds])]
  value.linear_candidates = extractLinearIds([p.body ?? "", ...commits.map((c) => c.body)]).filter((id) => !value.linear_ids.includes(id))
  overviewCache.set(key, { at: Date.now(), value })
  return value
}

function clip(s: string, n: number): string {
  const t = (s ?? "").trim()
  return t.length > n ? `${t.slice(0, n)}… [+${t.length - n} chars]` : t
}

export function formatOverview(o: Overview): string {
  const failing = o.checks.filter((c) => /fail|error|cancel|timed_out|action_required/.test(c.state))
  const pending = o.checks.filter((c) => /pending|queued|in_progress|expected/.test(c.state))
  const lines = [
    `# ${o.ref.repo}#${o.ref.number}: ${o.title}`,
    `${o.ref.url}`,
    `author @${o.author} · ${o.state}${o.draft ? " (draft)" : ""} · decision ${o.review_decision || "none"} · mergeable ${o.mergeable}`,
    `base ${o.base_ref} @ ${o.base_sha}`,
    `head ${o.head_ref} @ ${o.head_sha}`,
    `+${o.additions}/-${o.deletions} across ${o.files_total} files · ${o.commits_total} commits`,
    `checks: ${o.checks_state}${failing.length ? ` · failing: ${failing.map((c) => c.name).join(", ")}` : ""}${pending.length ? ` · pending: ${pending.length}` : ""}`,
    `review threads: ${o.threads.open} open, ${o.threads.resolved} resolved (${o.threads.outdated} outdated) · conversation comments: ${o.conversation_comments}`,
    `reviews: ${o.reviews.map((r) => `@${r.author}:${r.state.toLowerCase()}`).join(", ") || "none"}`,
    `linear: ${o.linear_ids.join(", ") || "none detected"}${o.linear_candidates.length ? ` · unverified mentions: ${o.linear_candidates.slice(0, 8).join(", ")}` : ""}${o.closing_issues.length ? ` · closes: ${o.closing_issues.join(", ")}` : ""}`,
    o.labels.length ? `labels: ${o.labels.join(", ")}` : "",
    "",
    "## Description",
    clip(o.body, 6000) || "(empty)",
    "",
    "## Commits",
    ...o.commits.map((c) => `- ${c.oid.slice(0, 10)} ${c.headline}${c.body.trim() ? `\n  ${clip(c.body, 600).replace(/\n/g, "\n  ")}` : ""}`),
    o.commits.length < o.commits_total ? `(GitHub returned ${o.commits.length} of ${o.commits_total} commits)` : "",
    "",
    "## Changed files",
    ...o.files.map((f) => `- ${f.change.padEnd(8)} ${f.path} (+${f.additions}/-${f.deletions})`),
  ]
  return lines.filter((l, i, a) => !(l === "" && a[i - 1] === "")).join("\n")
}

// --- Discussion (threads, conversation comments, review summaries) ------------------

const THREADS_QUERY = `query($owner:String!,$name:String!,$number:Int!,$after:String){
  repository(owner:$owner,name:$name){ pullRequest(number:$number){
    author{login} headRefOid
    reviewThreads(first:40,after:$after){ pageInfo{hasNextPage endCursor} nodes{
      id isResolved isOutdated path line originalLine resolvedBy{login}
      comments(first:100){ pageInfo{hasNextPage endCursor} nodes{
        id url body createdAt outdated author{login} commit{oid} originalCommit{oid} diffHunk } } } } } } }`

const THREAD_COMMENTS_QUERY = `query($id:ID!,$after:String){ node(id:$id){ ... on PullRequestReviewThread{
  comments(first:100,after:$after){ pageInfo{hasNextPage endCursor} nodes{
    id url body createdAt outdated author{login} commit{oid} originalCommit{oid} diffHunk } } } } }`

const CONVERSATION_QUERY = `query($owner:String!,$name:String!,$number:Int!,$after:String){
  repository(owner:$owner,name:$name){ pullRequest(number:$number){
    comments(first:100,after:$after){ pageInfo{hasNextPage endCursor} nodes{ id url body createdAt author{login} } } } } }`

const REVIEWS_QUERY = `query($owner:String!,$name:String!,$number:Int!,$after:String){
  repository(owner:$owner,name:$name){ pullRequest(number:$number){
    reviews(first:100,after:$after){ pageInfo{hasNextPage endCursor} nodes{ id url body state submittedAt author{login} commit{oid} } } } } }`

function toComment(n: any): ThreadComment {
  return {
    id: n.id,
    url: n.url,
    author: n.author?.login ?? "ghost",
    body: n.body ?? "",
    created: n.createdAt ?? n.submittedAt ?? "",
    commit: n.commit?.oid ?? n.originalCommit?.oid,
    outdated: Boolean(n.outdated),
  }
}

function isBot(login: string): boolean {
  return /\[bot\]$|-bot$|^(github-actions|dependabot|codecov|vercel|linear|netlify|sonarcloud)/i.test(login)
}

export async function fetchDiscussion(pr: PrRef, cwd: string, includeBots = false): Promise<Discussion> {
  const vars = { owner: pr.owner, name: pr.name, number: pr.number }
  const threads: Thread[] = []
  let author = ""
  let head = ""
  let after: string | undefined
  for (;;) {
    const data = await graphql(THREADS_QUERY, { ...vars, after }, cwd)
    const p = data.repository.pullRequest
    author = p.author?.login ?? "ghost"
    head = p.headRefOid
    for (const t of p.reviewThreads.nodes) {
      const comments = [...t.comments.nodes]
      let page = t.comments.pageInfo
      while (page?.hasNextPage) {
        const more = await graphql(THREAD_COMMENTS_QUERY, { id: t.id, after: page.endCursor }, cwd)
        comments.push(...more.node.comments.nodes)
        page = more.node.comments.pageInfo
      }
      threads.push({
        id: t.id,
        path: t.path,
        line: t.line ?? null,
        original_line: t.originalLine ?? null,
        resolved: t.isResolved,
        outdated: t.isOutdated,
        resolved_by: t.resolvedBy?.login,
        hunk: comments[0]?.diffHunk ?? "",
        comments: comments.map(toComment),
      })
    }
    if (!p.reviewThreads.pageInfo.hasNextPage) break
    after = p.reviewThreads.pageInfo.endCursor
  }

  const collect = async (query: string, field: string) => {
    const out: any[] = []
    let cursor: string | undefined
    for (;;) {
      const conn = (await graphql(query, { ...vars, after: cursor }, cwd)).repository.pullRequest[field]
      out.push(...conn.nodes)
      if (!conn.pageInfo.hasNextPage) return out
      cursor = conn.pageInfo.endCursor
    }
  }
  const rawComments = (await collect(CONVERSATION_QUERY, "comments")).map(toComment)
  const rawReviews = (await collect(REVIEWS_QUERY, "reviews")).map((n) => ({ ...toComment(n), state: n.state }))
  const keep = (c: ThreadComment) => includeBots || !isBot(c.author)
  const comments = rawComments.filter(keep)
  const reviews = rawReviews.filter((r) => r.body.trim() && keep(r))
  return {
    ref: pr,
    author,
    head_sha: head,
    threads,
    comments,
    reviews,
    bot_comments_hidden: rawComments.length - comments.length + rawReviews.filter((r) => r.body.trim() && !keep(r)).length,
  }
}

export function sourceKey(pr: PrRef, kind: "thread" | "comment" | "review", id: string): string {
  return `github:${pr.repo}#${pr.number}:${kind}:${id}`
}

export type DiscussionFilter = { state?: "all" | "open" | "resolved" | "outdated"; path?: string; max_body?: number }

export function formatDiscussion(d: Discussion, f: DiscussionFilter = {}): string {
  const state = f.state ?? "all"
  const maxBody = f.max_body ?? 1500
  const open = d.threads.filter((t) => !t.resolved)
  const selected = d.threads.filter((t) => {
    if (f.path && !t.path.startsWith(f.path)) return false
    if (state === "open") return !t.resolved
    if (state === "resolved") return t.resolved
    if (state === "outdated") return t.outdated
    return true
  })
  // Open threads first: they are the ones that still need attention.
  selected.sort((a, b) => Number(a.resolved) - Number(b.resolved) || a.path.localeCompare(b.path) || (a.line ?? 0) - (b.line ?? 0))
  const lines = [
    `# Discussion for ${d.ref.repo}#${d.ref.number} (author @${d.author}, head ${d.head_sha.slice(0, 10)})`,
    `review threads: ${d.threads.length} total · ${open.length} open · ${d.threads.length - open.length} resolved · ${d.threads.filter((t) => t.outdated).length} outdated · showing ${state} (${selected.length})`,
    `conversation comments: ${d.comments.length} · review summaries with text: ${d.reviews.length}${d.bot_comments_hidden ? ` · ${d.bot_comments_hidden} bot comments hidden` : ""}`,
    "",
  ]
  for (const t of selected) {
    const where = `${t.path}:${t.line ?? t.original_line ?? "?"}${t.line === null && t.original_line ? " (original line)" : ""}`
    const flags = [t.resolved ? `resolved${t.resolved_by ? ` by @${t.resolved_by}` : ""}` : "OPEN", t.outdated ? "outdated" : ""].filter(Boolean)
    lines.push(`## [${flags.join(", ")}] ${where}`)
    lines.push(`source_key: ${sourceKey(d.ref, "thread", t.id)}`)
    const hunk = t.hunk.split("\n").slice(-6).join("\n")
    if (hunk.trim()) lines.push("```diff", hunk, "```")
    for (const c of t.comments) {
      lines.push(`- @${c.author} ${c.created.slice(0, 10)}${c.commit ? ` @${c.commit.slice(0, 7)}` : ""}: ${clip(c.body, maxBody).replace(/\n/g, "\n  ")}`)
      lines.push(`  ${c.url}`)
    }
    lines.push("")
  }
  if (d.reviews.length) {
    lines.push("# Review summaries")
    for (const r of d.reviews) {
      lines.push(`- @${r.author} ${r.state.toLowerCase()} ${r.created.slice(0, 10)}${r.commit ? ` @${r.commit.slice(0, 7)}` : ""}: ${clip(r.body, maxBody).replace(/\n/g, "\n  ")}`)
      lines.push(`  ${r.url} · source_key: ${sourceKey(d.ref, "review", r.id)}`)
    }
    lines.push("")
  }
  if (d.comments.length) {
    lines.push("# Conversation comments")
    for (const c of d.comments) {
      lines.push(`- @${c.author} ${c.created.slice(0, 10)}: ${clip(c.body, maxBody).replace(/\n/g, "\n  ")}`)
      lines.push(`  ${c.url} · source_key: ${sourceKey(d.ref, "comment", c.id)}`)
    }
  }
  return lines.join("\n").trimEnd()
}

// --- Code at a revision ------------------------------------------------------------

async function revision(pr: PrRef, which: string | undefined, cwd: string): Promise<string> {
  if (which && /^[0-9a-f]{7,40}$/.test(which)) return which
  const o = await fetchOverview(pr, cwd, 60000)
  return which === "base" ? o.base_sha : o.head_sha
}

export type DiffOptions = { path?: string; offset?: number; limit?: number }

export function sliceDiff(patch: string, opts: DiffOptions): string {
  const limit = Math.max(2000, Math.min(opts.limit ?? 60000, 200000))
  const offset = Math.max(0, opts.offset ?? 0)
  let text = patch
  if (opts.path) {
    const chunks = patch.split(/^(?=diff --git )/m)
    text = chunks.filter((c) => c.startsWith("diff --git") && c.split("\n")[0].includes(` b/${opts.path}`)).join("")
    if (!text) {
      const prefixed = chunks.filter((c) => c.split("\n")[0].includes(`/${opts.path}`))
      text = prefixed.join("")
    }
    if (!text) return `No diff for path '${opts.path}'.`
  }
  if (text.length <= offset + limit && offset === 0) return text
  const window = text.slice(offset, offset + limit)
  const files = [...text.matchAll(/^diff --git a\/(\S+)/gm)].map((m) => m[1])
  const footer =
    offset + limit < text.length
      ? `\n[diff truncated: showing chars ${offset}-${offset + window.length} of ${text.length}; continue with offset=${offset + limit}, or pass path= for one file. Files: ${files.length}]`
      : `\n[end of diff: chars ${offset}-${offset + window.length} of ${text.length}]`
  return window + footer
}

export async function diff(pr: PrRef, cwd: string, opts: DiffOptions = {}): Promise<string> {
  const o = await fetchOverview(pr, cwd, 60000)
  let patch: string
  if ((await hasLocalCommit(o.head_sha, cwd)) && (await hasLocalCommit(o.base_sha, cwd))) {
    patch = (await run(["git", "diff", "--no-color", "--no-ext-diff", `${o.base_sha}...${o.head_sha}`], cwd)).out
  } else {
    patch = await gh(["pr", "diff", String(pr.number), "--repo", pr.repo, "--color", "never"], cwd)
  }
  return `diff ${o.base_sha.slice(0, 10)}...${o.head_sha.slice(0, 10)}\n${sliceDiff(patch, opts)}`
}

export type FileOptions = { path: string; ref?: string; start?: number; end?: number }

export function numberLines(content: string, start = 1, end?: number): string {
  const all = content.split("\n")
  const s = Math.max(1, start)
  const e = Math.min(all.length, end ?? s + 399)
  const body = all
    .slice(s - 1, e)
    .map((l, i) => `${String(s + i).padStart(5)}  ${l}`)
    .join("\n")
  const more = e < all.length ? `\n[lines ${s}-${e} of ${all.length}; continue with start=${e + 1}]` : ""
  return body + more
}

export async function file(pr: PrRef, cwd: string, opts: FileOptions): Promise<string> {
  if (!opts.path || opts.path.includes("..")) throw new Error("path is required and must be repository-relative")
  const sha = await revision(pr, opts.ref, cwd)
  let content: string
  if (await hasLocalCommit(sha, cwd)) {
    const r = await run(["git", "show", `${sha}:${opts.path}`], cwd, true)
    if (r.code !== 0) throw new Error(`${opts.path} does not exist at ${sha.slice(0, 10)}`)
    content = r.out
  } else {
    const encoded = opts.path.split("/").map(encodeURIComponent).join("/")
    content = await gh(["api", "-H", "Accept: application/vnd.github.raw", `repos/${pr.repo}/contents/${encoded}?ref=${sha}`], cwd)
  }
  return `${opts.path} @ ${sha.slice(0, 10)}\n${numberLines(content, opts.start, opts.end)}`
}

export type GrepOptions = { pattern: string; ref?: string; path?: string; limit?: number }

export async function grep(pr: PrRef, cwd: string, opts: GrepOptions): Promise<string> {
  if (!opts.pattern) throw new Error("pattern is required")
  const sha = await revision(pr, opts.ref, cwd)
  if (!(await hasLocalCommit(sha, cwd))) {
    throw new Error(`commit ${sha.slice(0, 10)} is not available locally; run inside the PR's review worktree or use op=file`)
  }
  const args = ["git", "grep", "-n", "-I", "-E", "--max-count=50", "-e", opts.pattern, sha]
  if (opts.path) args.push("--", opts.path)
  const r = await run(args, cwd, true)
  if (r.code === 1) return `No matches for /${opts.pattern}/ at ${sha.slice(0, 10)}.`
  if (r.code !== 0) throw new Error(r.err.trim())
  const lines = r.out.split("\n").filter(Boolean).map((l) => l.replace(`${sha}:`, ""))
  const limit = Math.min(opts.limit ?? 200, 500)
  return `${lines.length} match(es) at ${sha.slice(0, 10)}\n${lines.slice(0, limit).join("\n")}${lines.length > limit ? `\n[${lines.length - limit} more; narrow the pattern or path]` : ""}`
}

// --- Single entry point used by the tool and CLI ------------------------------------

export type ContextOp = "overview" | "threads" | "diff" | "file" | "grep"

export type ContextArgs = {
  op: ContextOp
  pr?: string
  repo?: string
  state?: DiscussionFilter["state"]
  path?: string
  ref?: string
  start?: number
  end?: number
  pattern?: string
  offset?: number
  limit?: number
  include_bots?: boolean
}

export async function context(args: ContextArgs, cwd: string) {
  const pr = await resolvePr(args.pr, cwd, args.repo)
  switch (args.op) {
    case "overview": {
      const o = await fetchOverview(pr, cwd)
      return { pr, overview: o, text: formatOverview(o) }
    }
    case "threads": {
      const d = await fetchDiscussion(pr, cwd, args.include_bots)
      return { pr, discussion: d, text: formatDiscussion(d, { state: args.state, path: args.path }) }
    }
    case "diff":
      return { pr, text: await diff(pr, cwd, args) }
    case "file":
      return { pr, text: await file(pr, cwd, { path: args.path ?? "", ref: args.ref, start: args.start, end: args.end }) }
    case "grep":
      return { pr, text: await grep(pr, cwd, { pattern: args.pattern ?? "", ref: args.ref, path: args.path, limit: args.limit }) }
    default:
      throw new Error(`unknown op '${(args as any).op}'`)
  }
}

const HELP = `pr-context - read-only pull request context for reviews

Usage:
  pr-context overview [PR]
  pr-context threads  [PR] [--state all|open|resolved|outdated] [--path P] [--include-bots]
  pr-context diff     [PR] [--path P] [--offset N] [--limit N]
  pr-context file     [PR] --path P [--ref head|base|SHA] [--start N] [--end N]
  pr-context grep     [PR] --pattern RE [--ref head|base|SHA] [--path P]

PR is a URL, owner/repo#N, or a number in the current repository; omit it
to use the current branch's published PR. Add --json for raw data.
`

export async function main(argv: string[]) {
  const [op, ...rest] = argv
  if (!op || op === "-h" || op === "--help" || op === "help") {
    console.log(HELP)
    return
  }
  const flags: Record<string, string | boolean> = {}
  const positional: string[] = []
  for (let i = 0; i < rest.length; i++) {
    const a = rest[i]
    if (a.startsWith("--")) {
      const k = a.slice(2)
      if (rest[i + 1] !== undefined && !rest[i + 1].startsWith("--") && !["json", "include-bots"].includes(k)) flags[k] = rest[++i]
      else flags[k] = true
    } else positional.push(a)
  }
  const num = (v: unknown) => (typeof v === "string" ? Number(v) : undefined)
  const str = (v: unknown) => (typeof v === "string" ? v : undefined)
  const res = await context(
    {
      op: op as ContextOp,
      pr: positional[0],
      state: str(flags.state) as DiscussionFilter["state"],
      path: str(flags.path),
      ref: str(flags.ref),
      start: num(flags.start),
      end: num(flags.end),
      pattern: str(flags.pattern),
      offset: num(flags.offset),
      limit: num(flags.limit),
      include_bots: Boolean(flags["include-bots"]),
    },
    process.cwd(),
  )
  if (flags.json) {
    const { text, ...data } = res as any
    console.log(JSON.stringify(data, null, 2))
  } else console.log(res.text)
}

if (import.meta.main) {
  main(process.argv.slice(2)).catch((err) => {
    console.error(`pr-context: ${err?.message ?? err}`)
    process.exit(1)
  })
}
