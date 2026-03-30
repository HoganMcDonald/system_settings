---
name: bar
description: >
  Add a new SketchyBar component to the status bar configuration. Scaffolds a
  Lua component file following the existing OOP library pattern and wires it
  into bar/init.lua.
disable-model-invocation: true
---

# SketchyBar Component Creator

You are a SketchyBar assistant that adds new components to the status bar using the existing Lua OOP library.

## Library Reference

The bar uses a custom OOP library at `roles/sketchybar/files/lib/`. Key classes:

- `Item:new('item', '<name>', '<position>')` — creates a bar item (`left`, `center`, `right`)
- `Bracket:new('<name>', { '<item1>', '<item2>' })` — groups items with shared background
- `Event:new('<event-name>')` — registers a custom event

Common `Item` methods (chainable):
- `:icon_string('<text>')`, `:icon_color(<color>)`, `:icon_font('<family>', <size>)`
- `:label_string('<text>')`, `:label_color(<color>)`, `:label_font('<family>', <size>)`
- `:padding(<left>, <right>)`
- `:script('<path>', <update_interval_seconds>)` — shell script for data
- `:subscribe('<event1>', '<event2>')` — events that trigger the script
- `:set({ key = 'value' })` — raw sketchybar properties

Colors are imported from `require('colors')`: `colors.text`, `colors.green`, `colors.red`, `colors.yellow`, `colors.blue`, `colors.surface0`, etc.

## Workflow

### 1. Clarify intent

Ask the user (or infer from context):
- Component name (e.g. `volume`, `cpu`, `spotify`)
- Position: `left`, `center`, or `right`
- Data source: does it need a shell plugin script, or is it static?
- Update trigger: time interval, system event, or manual

### 2. Create the component file

Create `roles/sketchybar/files/bar/components/<name>.lua`:

```lua
local Bracket = require('lib').Bracket
local Item = require('lib').Item
local colors = require('colors')

local function <name>()
  local <name>_widget = Item:new('item', '<name>', '<position>')
  <name>_widget
    :label_color(colors.text)
    :label_font('SF Pro Display', 14)
    :icon_color(colors.<color>)
    :icon_font('SF Pro Display', 16)
    :padding(5, 5)
    -- Add :script() and :subscribe() if data-driven

  local <name>_container = Bracket:new('<name>', { '<name>' })
  <name>_container:move_to('<position>')

  return {
    <name>_widget,
    <name>_container
  }
end

return <name>
```

### 3. Create a plugin script (if data-driven)

Create `roles/sketchybar/files/plugins/<name>.sh`:

```bash
#!/usr/bin/env bash

# Fetch data and update the bar item
sketchybar --set <name> label="<value>"
```

Make it executable by noting it needs `chmod +x` (the Ansible role handles this via the `copy` task with `mode: '0755'`).

### 4. Wire into bar/init.lua

Read `roles/sketchybar/files/bar/init.lua` and:

1. Add the require at the top with other component requires:
   ```lua
   local <name> = require('bar.components.<name>')
   ```

2. Add to `M.components` in `M.setup()`, in the appropriate position group (left/center/right):
   ```lua
   <name> = <name>(),
   ```

### 5. Output

```
Created component: <name>

  roles/sketchybar/files/bar/components/<name>.lua
  roles/sketchybar/files/plugins/<name>.sh  (if applicable)

  Wired into: bar/init.lua

Reload to test: sketchybar --reload
```

## Common Icon Strings (SF Symbols / Nerd Font)

- Battery: ``, CPU: `󰻠`, Memory: `󰍛`
- Volume: ``, Wifi: ``, Clock: ``
- Spotify/Music: ``, Network: `󰊗`
