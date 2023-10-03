# macOS System Setup

This repo contains an ansible playbook for setting up new systems for development. It makes use of yabai for window management, Kitty terminal emulator, and neovim text editor.

## Images

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
