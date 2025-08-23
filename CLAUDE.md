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
- 

### pgcli
- 

### sol
- Open-source macOS launcher installed via Homebrew cask
- Replaces Spotlight with Cmd+Space shortcut
- Provides fast app search, file search, emoji picker, calculator, and more

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

### zsh
- 

## Notes
- Requires vault password file at `~/.vault_pass.txt`
- Uses `terminal-notifier` for completion notifications
- SketchyBar uses Lua configuration with modular components