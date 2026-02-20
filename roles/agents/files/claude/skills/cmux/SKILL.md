---
name: cmux
description: Analyze a project and generate a .cmux/setup bootstrap script for git worktrees
disable-model-invocation: true
---

# cmux Setup Generator

You are a project setup assistant that analyzes a repository and generates a `.cmux/setup` script for use with cmux (git worktree manager for Claude Code).

## Purpose

The `.cmux/setup` script runs automatically when a new worktree is created. It bootstraps the worktree so it is immediately usable -- symlinking environment files, installing dependencies, and running codegen or build steps.

## Workflow

1. **Check for existing setup**
   ```bash
   test -f .cmux/setup && cat .cmux/setup
   ```
   If `.cmux/setup` already exists, show its contents and ask the user whether to replace it, edit it, or leave it. Do not overwrite without confirmation.

2. **Scan the project**
   ```bash
   ls -1a
   cat .gitignore 2>/dev/null
   ```

   Identify three categories:

   **Environment files to symlink** -- Files that exist in the repo root but are gitignored and would be missing in a new worktree. Common patterns: `.env`, `.env.local`, `.env.development`, `.dev.vars`, `config/master.key`, `.secret*`. Verify each file actually exists before including it.

   **Dependency installation** -- Detect the package manager from lock files:
   | Lock file | Command |
   |---|---|
   | `package-lock.json` | `npm ci` |
   | `yarn.lock` | `yarn install --frozen-lockfile` |
   | `pnpm-lock.yaml` | `pnpm install --frozen-lockfile` |
   | `bun.lockb` | `bun install` |
   | `Gemfile.lock` | `bundle install` |
   | `Cargo.lock` | `cargo build` |
   | `go.sum` | `go mod download` |
   | `poetry.lock` | `poetry install` |
   | `uv.lock` | `uv sync` |

   **Codegen / build steps** -- Check for:
   - `prisma/schema.prisma` -> `npx prisma generate`
   - `codegen.yml` or `codegen.ts` -> `npx graphql-codegen`
   - `Makefile` with a `setup` or `generate` target -> `make setup`
   - Framework-specific generators

3. **Generate the script**

   Rules for the script:
   - First line: `#!/bin/bash`
   - Second line: `REPO_ROOT="$(git rev-parse --git-common-dir | xargs dirname)"`
   - Symlinks: `ln -sf "$REPO_ROOT/<file>" <file>` (use `-sf` for idempotency)
   - Only include steps relevant to THIS project
   - No echo statements, no status messages, no decorative output
   - Short inline comments only for non-obvious lines
   - No `cd` commands -- the script runs from within the worktree
   - No git commands
   - If the project needs no setup, output just the shebang and a comment

4. **Write the file**
   ```bash
   mkdir -p .cmux
   chmod +x .cmux/setup
   ```

5. **Show the result**
   ```bash
   cat .cmux/setup
   ```

## Important Rules

- ONLY symlink files that actually exist in the repo root
- NEVER hardcode absolute paths except through `$REPO_ROOT`
- Prefer `ln -sf` so re-running is safe
- If a `Makefile` has a `setup` target, prefer `make setup` over duplicating steps
- For monorepos, handle per-package env files with a loop over the relevant directories

## Output

After writing, summarize what the script does:
```
Created .cmux/setup

  Symlinks:  .env, .env.local
  Install:   npm ci
  Codegen:   npx prisma generate

Tip: commit .cmux/setup so it is available in new worktrees automatically.
```

Ask if the user wants any changes before committing.
