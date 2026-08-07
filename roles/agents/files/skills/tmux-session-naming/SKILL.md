---
name: tmux-session-naming
description: Use when explicitly asked to rename the current tmux session, including through /rename-session or /hack. Derives a Linear ticket from the current branch when ticket context is not already available.
disable-model-invocation: true
---

# Tmux Session Naming

Rename the active tmux session so session pickers group work by its source
repository.

## Workflow

1. Check whether the current shell is inside tmux. If it is not, report that
   no session was renamed and stop.
2. Use supplied Linear ticket context when available. Otherwise, get the
   current branch with `git branch --show-current`, extract an identifier
   matching `[A-Z]+-[0-9]+`, and fetch that issue from Linear.
3. Before renaming, use the task tool to spawn the `tmux-session-namer`
   subagent with the Linear ticket title, identifier, labels, and relevant
   context.
4. Report the resulting session name.

## Error Handling

- If the checkout is detached, ask the user for the Linear ticket ID or title.
- If the branch has no ticket identifier and no ticket context was supplied,
  ask the user for the Linear ticket ID or title.
- If Linear cannot find the ticket, ask the user to verify the identifier.
- If not inside tmux, do not invoke the subagent.
