# GitHub CLI — PR Review Reference

## Fetch PR review comments
```bash
gh api repos/OWNER/REPO/pulls/PR_NUM/reviews \
  --jq '.[] | {id: .id, user: .user.login, state: .state, body: .body}'

gh api repos/OWNER/REPO/pulls/PR_NUM/comments \
  --jq '.[] | {id: .id, user: .user.login, path: .path, line: .original_line, body: .body}'
```

## Fetch PR diff
```bash
gh pr diff PR_NUM --repo OWNER/REPO
```

## CI checks
```bash
# Summary
gh pr checks PR_NUM --repo OWNER/REPO

# Re-run failed checks
gh run rerun RUN_ID --repo OWNER/REPO --failed

# Get run ID from a PR
gh run list --repo OWNER/REPO --branch BRANCH --limit 5 --json databaseId,status,conclusion,name
```

## Resolve a review comment (mark as resolved)
```bash
# Not available via gh CLI — must use gh api
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: {threadId: "THREAD_ID"}) {
      thread { isResolved }
    }
  }
'
```

## Get PR branch name
```bash
gh pr view PR_NUM --repo OWNER/REPO --json headRefName --jq '.headRefName'
```

## Get repo clone URL
```bash
gh repo view OWNER/REPO --json sshUrl --jq '.sshUrl'
```
