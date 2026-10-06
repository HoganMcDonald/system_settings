# Feedback entry format

Each lesson is one Markdown file with YAML frontmatter and fixed sections,
partitioned by repository:

- `~/.feedback/entries/<owner>/<repo>/` - `repository` and `subsystem` scope
- `~/.feedback/entries/_global/` - `global` and `language` scope

The tools choose the partition from the scope and the PR URL and move files
when scope changes; this describes what to pass to `feedback_capture`.

## Fields

| Field | Guidance |
|---|---|
| `title` | Imperative, specific, at most 100 chars. "Check authorization before serving cached results". |
| `notice` | At most 10 words. Shown in the `💡 feedback captured` footer. |
| `summary` | One sentence stating the lesson. |
| `kind` | `correctness`, `security`, `performance`, `reliability`, `data`, `api`, `design`, `testing`, `readability`, `naming`, `style`, `docs`, `ops`, `process`. |
| `confidence` | `confirmed` (reviewer and author agree, or fixed), `likely`, `tentative` (one reviewer's preference, unresolved). |
| `scope.level` | `global`, `language`, `repository`, or `subsystem`. Default to the narrowest that is true; it decides the partition. |
| `scope.repos` | Optional. Repository-scoped lessons always belong to the PR's repository; for global lessons it records where the lesson was seen (filled in automatically). |
| `scope.languages` / `subsystems` | `typescript`; `query-cache`. |
| `concepts` | 1-4 canonical topics: `authorization`, `caching`, `migrations`. |
| `aliases` | 5+ alternative search terms: synonyms, symptoms, abbreviations, the reviewer's words. |
| `symbols` | Functions, types, tables, flags, endpoints involved. |
| `paths` | Path globs where it applies: `src/cache/**`. |
| `lesson` | The reusable rule in one or two sentences. |
| `applies_when` | Conditions under which the lesson is relevant. |
| `why` | The failure it prevents. |
| `check` | A concrete step a reviewer or author can take. |
| `exceptions` | When it does not apply. |

## Source

| Field | Guidance |
|---|---|
| `key` | The `source_key` printed by `pr_context op=threads`, e.g. `github:owner/repo#123:thread:PRRT_abc`. One key per thread, review, or comment. |
| `pr` | URL of the PR where the feedback was given. |
| `url` | URL of the specific comment or review. |
| `reviewer` | GitHub login of the reviewer. |
| `thread_state` | `open`, `resolved`, `outdated`, or `none` (conversation comments and review summaries). |
| `disposition` | `pending`, `addressed`, `declined`, `disputed`, `acknowledged`. |
| `handled_pr` / `handled_url` | Where and how it was handled (fixing commit or reply). Only with evidence. |
| `excerpt` | Short quote of the reviewer's point, under 300 characters. |

## Example capture

```json
{
  "source": {
    "key": "github:acme/app#123:thread:PRRT_kwDOAbc",
    "pr": "https://github.com/acme/app/pull/123",
    "url": "https://github.com/acme/app/pull/123#discussion_r456",
    "reviewer": "alice",
    "thread_state": "open",
    "disposition": "pending",
    "excerpt": "This returns the cached value before we check the viewer can still see the project."
  },
  "entry": {
    "title": "Check authorization before serving cached results",
    "notice": "Preserve authorization checks before returning cached results",
    "summary": "Cache hits must not bypass current access checks.",
    "kind": "security",
    "confidence": "confirmed",
    "scope": { "level": "repository", "repos": ["acme/app"], "languages": ["typescript"], "subsystems": ["query-cache"] },
    "concepts": ["authorization", "caching"],
    "aliases": ["authz", "permissions", "access control", "cache hit", "stale permissions", "tenant isolation", "data leak"],
    "symbols": ["getCachedResult", "authorizeQuery"],
    "paths": ["src/cache/**"],
    "lesson": "Evaluate current access before returning a cached result.",
    "applies_when": "A cached response contains user- or tenant-scoped data.",
    "why": "Permissions can change while cached results remain available.",
    "check": "Trace both cache-hit and cache-miss paths through authorization.",
    "exceptions": "Public, non-user-scoped data."
  }
}
```

## Recording handling later

When the same thread is seen again after a fix, capture only the source with
its new state; no `entry` is needed:

```json
{
  "source": {
    "key": "github:acme/app#123:thread:PRRT_kwDOAbc",
    "pr": "https://github.com/acme/app/pull/123",
    "thread_state": "resolved",
    "disposition": "addressed",
    "handled_pr": "https://github.com/acme/app/pull/123",
    "handled_url": "https://github.com/acme/app/pull/123/commits/abc1234"
  }
}
```

## Recurrence

The same lesson from a different PR or reviewer in the same repository, or a
recurrence of a global lesson: capture with `"merge_into": "<existing id>"`
and the new `source`. Add any new aliases in `entry` (tags merge).

Merging a source from repository B into a repository-A lesson is refused.
If the lesson genuinely spans both, promote it first, then merge:

```json
{ "id": "fb-20261005-abc123", "note": "recurred in acme/web", "changes": { "scope": { "level": "global" } } }
```

Otherwise capture it as a separate lesson for repository B with
`"force_new": true`.
