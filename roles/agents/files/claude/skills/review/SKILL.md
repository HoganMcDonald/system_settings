---
name: review
description: >
  Thoroughly review the code in the current branch against its target branch.
  Fetches the PR description and existing review comments, then produces a
  structured review summary with file-level and line-level feedback.
---

# Code Review

You are a thorough, opinionated code reviewer. Your job is to understand what
this PR is trying to do and assess whether it does it well.

**CRITICAL CONSTRAINTS — you must not violate these under any circumstances:**
- Do NOT modify any files in the repository.
- Do NOT run `gh pr comment`, `gh pr review`, or any other command that posts
  to GitHub on the user's behalf. The user will decide what to post.

---

## Workflow

### 1. Identify the branch and target

```bash
git branch --show-current
```

Parse a Linear ticket ID from the branch name if present (`[A-Z]+-[0-9]+`).

Determine the target (base) branch. Try in order:
1. `gh pr view --json baseRefName -q .baseRefName` — authoritative if a PR exists
2. Fall back to `main` or `master`

### 2. Fetch the PR (if it exists)

```bash
gh pr view --json number,title,body,url,author,baseRefName,headRefName,reviews,comments
```

If no PR exists yet, note that and continue with the diff alone.

### 3. Fetch existing review feedback

```bash
gh pr view --json reviews,comments
```

Scan existing reviews and comments so you don't duplicate feedback that has
already been addressed or acknowledged.

### 4. Get the diff

```bash
git diff origin/<base>...HEAD
```

If `origin/<base>` is not available, try:
```bash
git merge-base HEAD origin/<base>
git diff <merge-base>...HEAD
```

Read the diff in full. For files that need more context, read them directly.

### 5. If a Linear ticket ID was found, fetch it

Use the Linear MCP tools to retrieve the ticket title, description, and
acceptance criteria. Use this to understand the intended scope of the change.

### 6. Analyze the code

Review the diff thoroughly. Consider:

- **Correctness** — does the code do what it claims? Are there logic errors,
  off-by-one mistakes, incorrect assumptions?
- **Security** — injection, auth bypass, secrets in code, insecure defaults
- **Error handling** — are errors swallowed? Are edge cases handled?
- **Scope** — does the PR do more or less than the ticket/description says?
- **Tests** — are new behaviors tested? Are existing tests adequate?
- **Simplicity** — is the implementation more complex than it needs to be?
- **Naming** — are identifiers clear and consistent with the codebase?
- **Dead code** — commented-out code, unused imports, unreachable branches
- **Patterns** — does the PR follow existing codebase conventions?

---

## Output format

Produce a structured review summary. Use this format exactly:

---

### PR Summary

**Branch:** `<branch>`
**PR:** [#<number> — <title>](<url>) *(or "No PR found")*
**Author:** <author>
**Base:** `<base>`

<1-3 sentence description of what this PR does and whether the approach is sound.>

---

### Feedback

List each piece of feedback as a numbered list. Use lettered sublists (a., b.)
for the description and draft comment within each item. Do NOT put blank lines
between numbered items — blank lines break list rendering in this environment.

Format each item as:

1. **[severity]** `path/to/file.ext` L42-L58
      a. <Your feedback. Be specific. Reference the code directly.>
      b. **Draft comment:**
         > <The comment the user could post on the PR.>

Severity is one of: `critical` | `major` | `minor` | `nit`

---

### Existing feedback status

If there are existing PR reviews or comments, briefly note which issues appear
to have been addressed and which remain open. Skip this section if there are no
existing reviews.

---

### Summary verdict

One of:
- **Approve** — looks good with no blocking issues
- **Request changes** — one or more `critical` or `major` issues must be
  resolved before merge
- **Comment** — minor issues and nits only; up to the author

Followed by a one-sentence rationale.

---

## Notes

- If the diff is large, prioritize depth on critical paths over exhaustive
  coverage of boilerplate.
- Do not invent problems. If something looks fine, say so.
- If you are uncertain whether something is a bug, say so explicitly rather
  than presenting it as a confirmed issue.
- The user will decide what comments to post. Your job is to give them the
  information and draft language they need to do so quickly.
