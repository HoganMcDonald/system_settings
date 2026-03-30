---
name: role
description: >
  Scaffold a new Ansible role in the dotfiles repository with standard directory
  structure, wire it into dotfiles.yml, and add a placeholder section to CLAUDE.md.
disable-model-invocation: true
---

# Ansible Role Scaffolder

You are a dotfiles assistant that creates new Ansible roles following the conventions of this repository.

## Workflow

### 1. Determine the role name

If the user hasn't specified a name, ask for one. Names should be:
- lowercase, hyphens for separators
- descriptive of the tool or config being managed (e.g. `starship`, `ripgrep`, `wezterm`)

### 2. Scaffold the directory structure

Create the following files under `roles/<name>/`:

```
roles/<name>/
  tasks/
    main.yml
  defaults/
    main.yml
  files/
    .gitkeep
```

**`roles/<name>/tasks/main.yml`** — starter task:
```yaml
---
- name: Install <name>
  homebrew:
    name: <name>
    state: present
  tags: <name>
```

**`roles/<name>/defaults/main.yml`** — empty defaults:
```yaml
---
# Default variables for the <name> role
```

Do NOT create `handlers/`, `templates/`, `vars/`, or `meta/` unless the role clearly needs them.

### 3. Add the role to dotfiles.yml

Read `dotfiles.yml` and find the `roles:` list. Insert the new role in alphabetical order among similar roles (tool installs near other tool installs, config roles near other config roles).

```yaml
    - role: <name>
      tags: <name>
```

### 4. Add a section to CLAUDE.md

Read `CLAUDE.md` and find the `## Role-Specific Notes` section. Add a placeholder entry in alphabetical order:

```markdown
### <name>
-
```

### 5. Output

```
Created role: <name>

  roles/<name>/tasks/main.yml
  roles/<name>/defaults/main.yml
  roles/<name>/files/.gitkeep

  Added to: dotfiles.yml
  Documented in: CLAUDE.md

Next: flesh out roles/<name>/tasks/main.yml with the actual setup steps.
```

## Conventions in This Repo

- Use `homebrew` module for CLI tools (`state: present`)
- Use `homebrew_cask` module for GUI apps
- Use `copy` or `template` tasks for config files, sourcing from `files/` or `templates/`
- Config files typically go to `~/.config/<name>/`
- Always tag tasks with the role name so they can be run individually:
  ```bash
  bin/bootstrap <name>
  ```
- Keep `defaults/main.yml` for any user-configurable variables (paths, version pins, etc.)
