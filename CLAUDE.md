# CLAUDE.md

This is a macOS system setup repository containing an Ansible playbook for automated development environment configuration. The setup includes window management (AeroSpace), terminal emulators (Kitty/Ghostty), and text editor (Neovim) configurations.

## Quick Commands

### Setup & Bootstrap
- `bin/bootstrap` - Run full system setup
- `bin/bootstrap neovim` - Install/update specific component

### Common Tasks
- `ansible-playbook -i hosts dotfiles.yml --ask-become-pass --tags TAG` - Run specific role
- `stylua .` - Format Lua code (used for SketchyBar configs)

## Project Structure

### Configuration Roles
- **aerospace** - Window manager configuration
- **sketchybar** - Status bar with Lua components
- **neovim** - Text editor with LSP, plugins, and custom configs
- **kitty/ghostty** - Terminal emulators
- **tmux** - Terminal multiplexer with tmuxinator layouts
- **zellij** - Modern terminal workspace manager with Rust-based configuration
- **zsh** - Shell configuration with aliases and includes

### Development Tools
- **cli** - Command line tools installation
- **git** - Git configuration and custom scripts
- **asdf** - Version manager setup
- **ruby/javascript** - Language-specific configurations

### System Configuration
- **macos** - System preferences automation
- **karabiner** - Keyboard customization
- **homebrew** - Package management

## Key Files
- `dotfiles.yml` - Main Ansible playbook
- `bin/bootstrap` - Setup script
- `roles/*/tasks/main.yml` - Role installation tasks
- `vault/` - Encrypted configuration variables

## Testing & Validation
- Check individual roles: `bin/bootstrap ROLE_NAME`
- Verify SketchyBar: `sketchybar --reload`
- Test Neovim config: `nvim --version` and check plugin loading

## Role-Specific Notes

### aerospace
-

### agents
- Claude Code, Codex, and OpenCode configs; OpenCode files live in `roles/agents/files/opencode/` and shared skills in `roles/agents/files/skills/`
- `review` agent (`opencode/agent/review.md`): read-only PR reviewer on `openai/gpt-6.1-sol` with the `medium` variant; `/review` and `/feedback` commands
- `plugin/review-loop.ts` exposes `pr_context`, `feedback_*`, and `review_*` tools, triggers feedback capture on `hoganmcdonald`'s PRs, and appends the `💡 feedback captured` footer
- Shared logic in `opencode/lib/` (`feedback-store.ts`, `pr-context.ts`, `review-loop-core.ts`), also exposed as the `feedback` and `pr-context` CLIs
- Feedback memory lives in `~/.feedback` (never in git): one Markdown lesson per file, partitioned into `entries/<owner>/<repo>/` and `entries/_global/`, plus a generated index; searches cover one repo plus `_global`
- `plugin/schedule.ts` exposes `schedule_wakeup`, `schedule_list`, and `schedule_cancel`: the agent ends its turn and a timer re-prompts the same session later (e.g. "check CI in 30m") via `client.session.promptAsync`; pending wakeups persist in `~/.local/state/opencode-schedule/pending.json` (override with `OPENCODE_SCHEDULE_FILE`), re-arm on the next start in the same directory, and only fire while OpenCode is running; store logic in `opencode/lib/schedule-store.ts`
- `opencode-pty` (third-party, listed in `opencode.json`) provides `pty_spawn`/`pty_read`/`pty_write`/`pty_kill`; `pty_spawn` with `notifyOnExit` wakes the session when a background process exits (e.g. `gh run watch`)
- Tests: `bun test roles/agents/tests`
- `detritus` MCP server (local, from `~/detritus.nvim/bin/detritus-mcp.lua` via `nvim --headless --clean -l`) is registered for OpenCode in `opencode/opencode.json` and for Claude Code by a `claude mcp add --scope user` task in `tasks/main.yml` (`~/.claude.json` is outside the symlinked `~/.claude`); the Claude task is skipped if the plugin checkout is missing

### apps
- Installs general GUI applications via Homebrew casks
- Current apps: Linear, Figma, Brain.fm
- Add new apps to `roles/apps/defaults/main.yml`

### asdf
- 

### browsers
- 

### cli
- 

### config
- 

### ghostty
- 

### git
- 

### homebrew
- 

### javascript
- 

### karabiner
- 

### kitty
- 

### macos
- 

### mcp-hub
- 

### mycli
- 

### neovim
- Neovim installed via devbox global; `nnvim` launcher uses `NVIM_APPNAME=nnvim` with config from `roles/neovim/files-nnvim/`
- `detritus.nvim` (`~/detritus.nvim`, its own repo) is loaded lazily via `pack.dir` in `files-nnvim/lua/editor/detritus.lua`: a persistent plan panel in the right edgy bar (`<leader>pp` toggle, `pb` branch, `pc` clear, `pr` refresh) fed by its MCP server; opening it closes the CodeCompanion and neotest panels and vice versa
- Requires the `tree-sitter` CLI (installed via devbox global) for nvim-treesitter main branch parser builds

### pgcli
- 

### ruby
- 

### sketchybar
- **Architecture**: Modular Lua-based configuration built on top of SbarLua
- **Core Library (`lib/`)**: Custom object-oriented wrapper providing fluent API for sketchybar configuration
  - `Bar` - Global bar configuration (height, position, styling, blur, margins)
  - `Item` - Individual bar items with icon/label/background properties and event handling
  - `Bracket` - Groups items together with shared background styling
  - `Event` - Custom event system for inter-component communication
  - `Animation` - Animation framework with easing functions (linear, bounce, overshoot, etc.)
- **Component System (`bar/components/`)**: Modular components using the library
  - `battery.lua` - Battery status with charging indicator, updates every 120s
  - `clock.lua` - Time display component
  - `wifi.lua` - WiFi status indicator
  - `workspaces.lua` - AeroSpace workspace integration
  - `mode_indicator.lua` - AeroSpace mode display
- **Plugin Architecture**: Shell scripts in `plugins/` handle data fetching and system integration
- **Configuration Flow**: `init.lua` → `bar/init.lua` → individual components → shell plugins
- **Key Features**: Fluent method chaining, automatic SbarLua integration, modular design for easy component addition/removal

### tmux
- 

### zellij
- Modern terminal workspace manager written in Rust
- Configuration in KDL format with vim-like keybindings using Ctrl+g prefix
- Features: multiple panes, tabs, sessions, scrollback buffer, and plugin system
- Default keybindings: Ctrl+g+n (new tab), Ctrl+g+d/v (split panes), Ctrl+g+hjkl (navigation)

### zsh
- `bin/review` manages PR review worktrees and tmux sessions; `review start <ref>...|--next N` launches detached agent reviews with run state in `<git-common-dir>/review-runs/`; `review clear --stop` (or the `review_cleanup` tool) tears them all down
- Tests: `roles/zsh/tests/test_review.sh`

## Notes
- Requires vault password file at `~/.vault_pass.txt`
- Uses `terminal-notifier` for completion notifications
- SketchyBar uses Lua configuration with modular components
