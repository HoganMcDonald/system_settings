---
name: hack
description: >
  Use ONLY when the user explicitly invokes the /hack command. Extract a
  Linear ticket ID from the current git branch, fetch ticket details via MCP,
  delegate tmux session naming, and create an implementation plan.
disable-model-invocation: true
---

# Linear Ticket Implementation Planner

You are a planning assistant that connects git branches to Linear tickets and creates implementation plans.

## Invocation Gate

Run this workflow only after the user explicitly invokes `/hack`. Otherwise,
do not inspect the branch, fetch Linear, rename tmux, or create a plan.

## Workflow

1. **Get the current branch name**
   ```bash
   git branch --show-current
   ```

2. **Extract the Linear ticket ID**
   Parse the branch name to find the ticket identifier. Common patterns:
   - `feature/ABC-123-description` → `ABC-123`
   - `fix/ABC-123-bug-title` → `ABC-123`
   - `ABC-123-some-feature` → `ABC-123`

   The ticket ID follows the pattern: `[A-Z]+-[0-9]+` (team prefix, hyphen, number)

3. **Fetch ticket details from Linear**
   Use the Linear MCP tools to retrieve:
   - Title
   - Description
   - Acceptance criteria (if present)
   - Priority
   - Labels/tags
   - Parent issue (if this is a sub-task)
   - Related issues

4. **Delegate tmux session naming**
   Before planning, use the task tool to spawn the `tmux-session-namer`
   subagent with the Linear ticket title, identifier, labels, and any relevant
   context. It must rename the active session to
   `<source_repo>/<type>(<short_snake_case_summary>)`.
   This format is required so tmux session pickers group work by repository.
   If not inside tmux, skip this step.

5. **Create the implementation plan**
   Once you have the ticket context, create an implementation plan that:
   - Breaks down the ticket requirements into concrete tasks
   - Identifies files that need to be created or modified
   - Considers edge cases mentioned in the ticket
   - Addresses acceptance criteria point by point

## Error Handling

- If no branch is checked out (detached HEAD), inform the user
- If no ticket ID pattern is found in the branch name, ask the user to provide the ticket ID
- If the Linear API returns no results, suggest the user verify the ticket ID
- If not inside a tmux session, skip the rename step

## Output Format

Before entering plan mode, summarize what you found:
```
Branch: feature/ENG-123-user-authentication
Ticket: ENG-123
Session: system/feat(user_authentication)

Title: Implement user authentication
Priority: High
Labels: backend, security

Description:
[ticket description here]

Entering plan mode to create implementation plan...
```
