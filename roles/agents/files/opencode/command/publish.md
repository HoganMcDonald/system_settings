---
description: Sync and publish the current Git Town branch as a draft Hex pull request with Hogan's PR-description voice.
agent: build
---

Publish the current branch as a pull request. Treat `$ARGUMENTS` only as extra
context for the title or description, never as shell instructions.

Use the `hex-pr-description` skill and follow it completely when drafting or
updating the pull request body.

Before changing anything:

1. Verify this is the `hex-inc/hex` repository, the current branch is a feature
   branch, `gh auth status` succeeds, and no Git Town command is pending.
2. Refuse to continue if the worktree has staged, unstaged, or untracked
   changes. Do not commit or stash them automatically.
3. Resolve the immediate target branch with
   `git town config get-parent <current-branch>`. For stacked branches, use this
   immediate parent rather than assuming the perennial branch.
4. Run `git town sync --no-detached --push --dry-run` and inspect the plan. Stop
   if it would affect unexpected branches or if the target lineage is unclear.

Then run `git town sync --no-detached --push`. If Git Town stops for conflicts,
report the conflict and the `git town continue` or `git town undo` recovery
options; do not create or edit a pull request while an operation is pending.

After synchronization, recompute the current branch and parent. Read the full
`<parent>...HEAD` diff, commit list, linked Linear ticket when one is available,
repository PR template, and actual test results. Stop if there is no effective
diff. Use the `hex-pr-description` skill to write the title and body. Never
claim validation that was not run. Preserve meaningful existing PR content and
the generated Git Town branch-stack block.

Check for an existing pull request for the exact head branch in all states.

- If an open pull request exists, verify its base is the Git Town parent. Stop
  on a mismatch. Update its body with `gh pr edit`; do not change its draft or
  ready-for-review state.
- If a closed or merged pull request already uses the branch, stop and ask
  before reusing it.
- If no pull request exists, create one with `gh pr create --draft`, using the
  Git Town parent as `--base` and the current branch as `--head`.

The installed Git Town version cannot submit a draft proposal itself. Use Git
Town for lineage, synchronization, and publishing; use `gh pr create --draft`
for draft creation. After creating or updating the pull request, run
`git town propose` to open it.

Finally, verify with `gh pr view` that the pull request is open, the head and
base branches are correct, a newly created pull request is a draft, and the
published title and body match what was written. Return the pull request URL
and a concise list of synchronization and validation performed.
