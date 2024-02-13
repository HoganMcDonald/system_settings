# macOS System Setup

This repo contains an ansible playbook for setting up new systems for development. It makes use of yabai for window management, Kitty terminal emulator, and neovim text editor.

## Images

![preview image](/docs/preview.png)

## Install

```
# clone this repo into your home directory
git clone git@github.com:HoganMcDonald/system_settings.git ~/dotfiles

cd dotfiles
bin/bootstrap # does a lot... please read before running
```

## Commands

```
# individual tags can be run individually
bin/bootstrap neovim
```

# TODO

- replace coq with cmp
- set up copilot with cmp
- set up gpt
- remove blankline highlights from nvim tree
<!-- - sketchybar spaces labels -->
- qutebrowser with 1password
- add screenshots to dock
- find a wallpaper and get it working in ansible
- replace nvim tree with sidebar.nvim
- dynamically cut off git blame in lualine
- rearrange lualine so that git is on left, diagnostics show up

- cokeline
- neotree

- investigate why it hangs at close
- tmux colors from checkhealth
