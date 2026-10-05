// review-loop-core - Pure helpers for the review-loop OpenCode plugin.
//
// Kept free of OpenCode and filesystem dependencies so they can be unit tested.

export const FOOTER_TITLE = "💡 feedback captured"

export type FeedbackRead = { ref?: string; repo?: string }

// Recognise shell commands that load review feedback for a pull request.
// Returns the PR ref when one can be extracted; an empty ref means "the
// current branch's PR".
export function detectFeedbackRead(command: string): FeedbackRead | null {
  const cmd = String(command ?? "")
  const segments = cmd.split(/&&|\|\||;|\n/)
  for (const seg of segments) {
    const s = seg.trim()
    const loadsFeedback =
      /\bgh\s+pr\s+view\b.*--comments\b/.test(s) ||
      /\bgh\s+pr\s+view\b.*--json\s+\S*\b(comments|reviews|reviewThreads|latestReviews|reviewDecision)\b/.test(s) ||
      /\bgh\s+api\b.*\bpulls\/\d+\/(comments|reviews)\b/.test(s) ||
      /\bgh\s+api\b.*\bissues\/\d+\/comments\b/.test(s) ||
      /\bgh\s+api\s+graphql\b[\s\S]*\breviewThreads\b/.test(cmd) ||
      /\bpr-context\s+threads\b/.test(s)
    if (!loadsFeedback) continue

    const url = s.match(/https?:\/\/(?:www\.)?github\.com\/[^/\s]+\/[^/\s]+\/pull\/\d+/)
    if (url) return { ref: url[0] }
    const api = s.match(/repos\/([^/\s]+\/[^/\s]+)\/(?:pulls|issues)\/(\d+)/)
    if (api) return { ref: api[2], repo: api[1] }
    const repoFlag = s.match(/(?:--repo|-R)[=\s]+([\w.-]+\/[\w.-]+)/)
    const number = s.match(/\bgh\s+pr\s+view\s+#?(\d+)\b/) ?? s.match(/\bpr-context\s+threads\s+#?(\d+)\b/)
    if (number) return { ref: number[1], repo: repoFlag?.[1] }
    const short = s.match(/\b([\w.-]+\/[\w.-]+#\d+)\b/)
    if (short) return { ref: short[1] }
    return { ref: undefined, repo: repoFlag?.[1] }
  }
  return null
}

export function detectFeedbackUrl(url: string): FeedbackRead | null {
  const m = String(url ?? "").match(/https?:\/\/(?:www\.)?github\.com\/[^/\s]+\/[^/\s]+\/pull\/\d+/)
  return m ? { ref: m[0] } : null
}

export type ReceiptLike = { id: string; notice: string }

export function formatFooter(receipts: ReceiptLike[]): string {
  const seen = new Set<string>()
  const lines: string[] = []
  for (const r of receipts) {
    if (seen.has(r.id)) continue
    seen.add(r.id)
    lines.push(`- ${r.notice}`)
  }
  return lines.length ? `${FOOTER_TITLE}\n${lines.join("\n")}` : ""
}

// Receipts whose notice does not already appear after the footer title.
export function missingFromFooter(text: string, receipts: ReceiptLike[]): ReceiptLike[] {
  const idx = text.lastIndexOf(FOOTER_TITLE)
  if (idx < 0) return receipts
  const tail = text.slice(idx).toLowerCase()
  const norm = (s: string) => s.toLowerCase().replace(/[^a-z0-9 ]/g, "").trim()
  return receipts.filter((r) => !norm(tail).includes(norm(r.notice)))
}

// Append a footer to an assistant message, or a supplement when the model
// wrote the footer but left some captured items out.
export function appendFooter(text: string, receipts: ReceiptLike[]): string | null {
  const missing = missingFromFooter(text, receipts)
  if (!missing.length) return null
  if (text.includes(FOOTER_TITLE)) {
    return `${text.trimEnd()}\n${missing.map((r) => `- ${r.notice}`).join("\n")}`
  }
  return `${text.trimEnd()}\n\n${formatFooter(missing)}`
}

export type Finding = { severity: string; title: string; location?: string; status?: string; thread_url?: string }

export const SEVERITIES = ["blocker", "major", "minor", "nit", "question"] as const

export function countFindings(findings: Finding[]): Record<string, number> {
  const counts: Record<string, number> = {}
  for (const s of SEVERITIES) counts[s] = 0
  for (const f of findings) counts[f.severity] = (counts[f.severity] ?? 0) + 1
  return counts
}

export function formatCounts(counts: Record<string, number> | undefined): string {
  const parts = Object.entries(counts ?? {})
    .filter(([, n]) => n > 0)
    .map(([k, n]) => `${n} ${k}`)
  return parts.length ? parts.join(", ") : "no findings"
}

export const TERMINAL_RUN_STATES = ["completed", "failed", "interrupted", "stopped"]

export type RunRecord = {
  run_id: string
  pr: number
  url?: string
  title?: string
  status: string
  tmux_session?: string
  head_sha?: string
  status_detail?: string | null
  report?: string | null
  result?: {
    verdict?: string
    summary?: string
    counts?: Record<string, number>
    head_sha_reviewed?: string
    feedback_captured?: ReceiptLike[]
  } | null
  action?: string
  detail?: string
}

export function formatRun(r: RunRecord): string {
  const head = `#${r.pr}${r.title ? ` ${r.title}` : ""}`
  const where = r.tmux_session ? ` · session ${r.tmux_session}` : ""
  const action = r.action ? `${r.action}: ` : ""
  let line = `- ${head} — ${action}${r.status ?? "-"}${where}${r.run_id ? ` · run ${r.run_id}` : ""}`
  if (r.result) line += `\n  ${r.result.verdict ?? "?"} · ${formatCounts(r.result.counts)} · ${r.result.summary ?? ""}`
  const detail = r.detail ?? r.status_detail
  if (detail) line += `\n  ${detail}`
  return line
}
