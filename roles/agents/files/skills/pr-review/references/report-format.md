# Review report format

```markdown
## Review: owner/repo#123 — <title>

Reviewed head `abc1234` against `main` (`def5678`). Verdict: comment |
approve | request changes — one sentence on why.

### Findings

1. **[major] Cached results bypass authorization** — `src/cache/store.ts:88`
   - Scenario: a user loses access to a project; the next cache hit still
     returns its data for up to the 10-minute TTL.
   - Evidence: `getCachedResult` returns before `authorizeQuery`
     (`src/cache/store.ts:80-91`); the only caller is `queryHandler`
     (`src/api/query.ts:42`), which relies on it for access control.
   - Suggestion: check access before the cache lookup, or key the cache by
     the viewer's permission set.
   - Related: feedback fb-20261005-abc123; Linear HEX-4821 acceptance
     criterion 2.

2. **[minor] ...**

### Existing feedback

- [open, unaddressed] @alice: retry storm on 429s — <thread URL>. Head still
  retries without backoff (`src/client.ts:31`).
- [resolved, regression] @bob: missing index — <thread URL>. The migration
  that added it was dropped in `9f8e7d6`.

### Questions

- Is the 10-minute TTL intentional for permission-sensitive data?

### Coverage

Reviewed all 14 changed files; traced `queryHandler` and both cache callers.
Skipped `package-lock.json` (generated). Not verified: production cache TTL
configuration (not in this repository).
```

## Severity

- **blocker** — data loss, security or privacy exposure, broken build or
  migration, or a change that cannot ship as-is.
- **major** — incorrect behaviour in realistic conditions, missing handling of
  an important failure mode, or a contract change that breaks consumers.
- **minor** — edge-case bugs, weak tests for changed behaviour, maintainability
  problems likely to cause defects.
- **nit** — style and naming with no behavioural impact. Keep these few.
- **question** — something you cannot resolve from available context.

## Finding quality bar

- Name the concrete scenario and its impact; avoid "consider" without a reason.
- Cite the exact lines you read at the reviewed head.
- If you could not confirm a suspicion, phrase it as a question.
- One finding per root cause, even if it shows up in several places.
