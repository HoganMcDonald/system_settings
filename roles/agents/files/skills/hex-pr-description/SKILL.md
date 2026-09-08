---
name: hex-pr-description
description: Write or rewrite GitHub pull request descriptions in Hogan McDonald's voice. Use when Hogan asks to draft, publish, improve, or rewrite a PR description, especially in hex-inc/hex.
---

# Hogan's PR Description Voice

Write PR descriptions that sound like a pragmatic engineer explaining the change to another engineer. Make the problem easy to understand before describing the implementation.

## Workflow

1. Read the complete branch diff, commit list, linked ticket, and test results before drafting.
2. Identify the shortest concrete story that explains why the old behavior was wrong.
3. Describe the fix in terms of behavior and important implementation boundaries.
4. Include validation that was actually performed. Never imply an unrun check passed.
5. Preserve existing screenshots, Loom links, rollout warnings, and generated branch-stack blocks unless asked to remove them.
6. When editing an existing PR, update its body with `gh pr edit` and verify the result.

## Voice

- Lead with the real scenario, not an abstract summary. Prefer openings such as "When someone...", "Before...", or a direct statement of what could go wrong.
- Explain the causal chain. Name the user action, the mistaken decision in the code, and the resulting behavior.
- Use `The TL;DR is...` when a complex mechanism benefits from a plain-language restatement.
- Use contractions and ordinary language: "doesn't", "kept chugging along", "no questions asked", "Here's how it goes". Do not force colorful phrasing into a simple change.
- Keep exact identifiers, routes, permissions, and flags in backticks.
- State uncertainty candidly when it is real, including where reviewer expertise is needed. Never invent uncertainty as a stylistic flourish.
- Prefer short paragraphs for the narrative and bullets for multiple behaviors, affected paths, acceptance criteria, or tests.
- Use `Before:` / `Now:` when that is clearer than a chronological explanation.
- For security bugs, explain the actor and boundary being bypassed in concrete terms without sensationalizing.
- For a large change, add a review guide only when ordering the review materially helps. Point reviewers to the core decision first.
- For meaningful manual verification, use `How tested:` and `Finding:`. For ordinary automated checks, a short command list is enough.
- Default to an unheaded narrative. Hogan's PRs usually open with one or more short paragraphs that explain the problem and fix directly.
- Do not add `Why`, `What`, `Summary`, or `Validation` sections unless the user requests them or an explicit repository rule requires them.

## Structure

For a small or medium PR, use this shape without headings:

```markdown
[Concrete failure or motivation, followed by the causal explanation.]

[Direct explanation of the fix.]

- [Distinct behavior or implementation detail, if bullets improve clarity.]
```

Add a `Testing`, `Review guide`, or prominent merge-warning section only when the change genuinely needs it. If a repository mandates a description template, satisfy the minimum required structure while preserving this voice inside it.

## Avoid

- Generic openings such as "This PR aims to", "This change enhances", or "In order to".
- Repeating the title as the first sentence.
- Marketing claims, inflated impact, or adjectives like "robust", "seamless", and "comprehensive".
- Exhaustive file inventories when behavior and key boundaries explain the change better.
- A bullet-only description that never explains the failure.
- Imposing a standard `Why` / `What` / `Validation` template on Hogan's PRs.
- Restating the same point in `Why`, `What`, and a summary.
- Claiming tests, lint, typechecks, or manual verification that were not run.
- Adding screenshots, Loom links, ticket quotations, or branch-stack markup that do not already exist or were not supplied.

## Final Check

Before publishing, confirm that a reviewer can answer three questions after one read:

1. What went wrong or needed to change?
2. Why did it happen?
3. What behavior is different now?
