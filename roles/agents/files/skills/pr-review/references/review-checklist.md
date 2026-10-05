# Review prompts by change type

Use the sections that match the change; skip the rest.

## Any change
- Does the code do what the ticket and description claim? Anything missing or extra?
- What happens on invalid input, empty collections, nulls, timeouts, partial failure?
- Are errors surfaced, retried, or swallowed? Is retry safe (idempotent)?
- Are names, comments, and types still true after the change?

## APIs, schemas, events
- Who consumes this contract? Search for callers, generated clients, other services.
- Is the change backwards compatible for old clients and mixed-version deploys?
- Are new fields validated, defaulted, and documented?

## Data and migrations
- Migration safety on large tables: locks, rewrites, backfills, timeouts.
- Rollback path; code that tolerates both pre- and post-migration states.
- Indexes for new query patterns; N+1 queries; unbounded result sets.

## Authorization, privacy, security
- Every new read or write path checks access with current permissions.
- Tenant isolation in queries, caches, logs, and background jobs.
- Secrets, tokens, and personal data stay out of logs, errors, and client payloads.
- Injection: SQL, shell, HTML, path traversal, SSRF in user-controlled input.

## Concurrency and state
- Races between readers and writers; check-then-act; double submission.
- Cancellation and cleanup of in-flight work; resource leaks.
- Cache invalidation and staleness when the source of truth changes.

## Frontend
- Loading, empty, and error states; optimistic updates and rollback.
- Accessibility of new controls; keyboard and screen reader behaviour.
- Effects and subscriptions cleaned up; stale closures.

## Tests
- Do tests fail without the change? Do they cover failure modes, not just the happy path?
- Are mocks hiding the behaviour under test? Flaky timing assumptions?

## Operations
- Feature flags, metrics, logs, and alerts needed to roll out and observe it.
- Configuration defaults and their behaviour in every environment.
