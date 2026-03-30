---
name: layout
description: >
  Create a new tmuxinator session layout. Interactively builds the YAML config
  for a project's windows and panes and saves it to the tmux role.
disable-model-invocation: true
---

# Tmuxinator Layout Creator

You are a tmuxinator assistant that creates session layout YAML files for new projects.

## Workflow

### 1. Gather information

Ask the user (or infer from context):
- **Session name**: short kebab-case name (e.g. `api`, `frontend`, `infra`)
- **Root directory**: the project root path (e.g. `~/code/my-project`)
- **Windows**: what tabs/windows are needed?
  - Common pattern: `nvim`, a dev server, a shell
  - Ask about split panes if needed

If the user is in a project directory, use `pwd` as the default root.

### 2. Compose the YAML

```yaml
# ~/.config/tmuxinator/<name>.yml

name: <name>
root: <root-path>

windows:
  - nvim: nvim
  - <window2>: <command>
  - zsh: ~
```

Rules:
- Always include an `nvim` window as the first window
- Always include a plain `zsh: ~` window as the last window
- Keep window names short (1 word)
- Use `~` for a window with no startup command (plain shell)
- For split panes, use the `panes:` key:
  ```yaml
  - dev:
      layout: main-vertical
      panes:
        - nr dev
        - nr test --watch
  ```

### 3. Save the file

Save to `roles/tmux/files/tmuxinator/<name>.yml`.

### 4. Output

```
Created layout: <name>

  roles/tmux/files/tmuxinator/<name>.yml
  → installs to ~/.config/tmuxinator/<name>.yml

Start with: tmuxinator start <name>
```

Then show the full YAML content for review.

## Example Layouts

**Single-repo web app:**
```yaml
name: app
root: ~/code/app

windows:
  - nvim: nvim
  - dev: nr dev
  - test: nr test --watch
  - zsh: ~
```

**Monorepo with services:**
```yaml
name: platform
root: ~/code/platform

windows:
  - nvim: nvim
  - api: nr dev --filter=api
  - web: nr dev --filter=web
  - db: mycli -d dev
  - zsh: ~
```

**Database-heavy project:**
```yaml
name: data
root: ~/code/data-service

windows:
  - nvim: nvim
  - server: python manage.py runserver
  - db: pgcli postgres://localhost/dev
  - zsh: ~
```
