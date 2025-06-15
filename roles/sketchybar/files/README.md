# SketchyBar Component Library

A modern, modular component system built on top of [SbarLua](https://github.com/FelixKratz/SbarLua) for creating maintainable and type-safe SketchyBar configurations.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
  - [Library Initialization](#library-initialization)
  - [Bar Class](#bar-class)
  - [Item Class](#item-class)
  - [Bracket Class](#bracket-class)
  - [Event Class](#event-class)
  - [Animation Class](#animation-class)
- [Examples](#examples)
- [Type Definitions](#type-definitions)
- [Contributing](#contributing)

## Installation

1. Ensure you have [SbarLua](https://github.com/FelixKratz/SbarLua) installed and configured
2. Copy the `lib/` directory to your SketchyBar configuration folder
3. Include the library in your configuration:

```lua
local sbar = require('sbar').get()
local lib = require('lib').init(sbar)
```

## Quick Start

```lua
-- Initialize library
local sbar = require('sbar').get()
local lib = require('lib').init(sbar)

-- Configure bar
local bar = lib.Bar:new()
bar:height(32)
   :color(0xff1e1e2e)
   :position("top")
   :apply()

-- Create items
local clock = lib.Item:new("item", "clock", "right")
clock:label_string(os.date("%H:%M"))
     :bg_color(0xff313244)
     :script("~/.config/sketchybar/plugins/clock.sh", 30)
```

---

## API Reference

### Library Initialization

#### `require('lib').init(sbar)`

Initializes the component library with a SbarLua instance.

**Parameters:**
- `sbar` (table): The SbarLua instance from `require('sbar').get()`

**Returns:**
- Library object with access to all component classes

**Example:**
```lua
local sbar = require('sbar').get()
local lib = require('lib').init(sbar)
```

---

### Bar Class

The Bar class handles global bar configuration and properties.

#### Constructor

##### `Bar:new(config?)`

Creates a new Bar instance.

**Parameters:**
- `config` (table, optional): Initial bar configuration

**Returns:**
- `Bar`: New Bar instance

#### Configuration Methods

All configuration methods support method chaining and return the Bar instance.

##### `Bar:configure(config)`

Apply configuration properties to the bar.

**Parameters:**
- `config` (table): Configuration object

##### `Bar:height(height)`

Set bar height.

**Parameters:**
- `height` (number): Height in pixels

##### `Bar:color(color)`

Set bar background color.

**Parameters:**
- `color` (number|string): Color value (hex or integer)

##### `Bar:border_color(color)`

Set bar border color.

**Parameters:**
- `color` (number|string): Border color value

##### `Bar:border_width(width)`

Set bar border width.

**Parameters:**
- `width` (number): Border width in pixels

##### `Bar:corner_radius(radius)`

Set bar corner radius.

**Parameters:**
- `radius` (number): Corner radius in pixels

##### `Bar:position(position)`

Set bar position.

**Parameters:**
- `position` ("top"|"bottom"): Bar position

##### `Bar:sticky(sticky)`

Set bar sticky behavior.

**Parameters:**
- `sticky` (boolean): Whether bar should be sticky

##### `Bar:padding(left, right)`

Set bar padding.

**Parameters:**
- `left` (number): Left padding in pixels
- `right` (number): Right padding in pixels

##### `Bar:margin(margin)`

Set bar margin.

**Parameters:**
- `margin` (number): Margin value in pixels

##### `Bar:y_offset(offset)`

Set bar y-offset.

**Parameters:**
- `offset` (number): Y-offset in pixels

##### `Bar:shadow(shadow)`

Enable/disable bar shadow.

**Parameters:**
- `shadow` (boolean): Whether to show shadow

##### `Bar:hide(hide)`

Hide/show the bar.

**Parameters:**
- `hide` (boolean): Whether to hide the bar

##### `Bar:topmost(topmost)`

Set bar topmost behavior.

**Parameters:**
- `topmost` (boolean): Whether bar should be topmost

##### `Bar:display(display)`

Configure bar for specific display.

**Parameters:**
- `display` (number): Display number (1-based)

#### Utility Methods

##### `Bar:apply()`

Apply the current configuration to the bar.

**Returns:**
- `Bar`: Self for method chaining

##### `Bar:reset()`

Reset bar configuration to defaults.

**Returns:**
- `Bar`: Self for method chaining

##### `Bar:get_config()`

Get current bar configuration.

**Returns:**
- `table`: Current configuration object

**Example:**
```lua
local bar = lib.Bar:new()
bar:height(32)
   :color(0xff1e1e2e)
   :border_width(1)
   :corner_radius(5)
   :position("top")
   :padding(10, 10)
   :apply()
```

---

### Item Class

The Item class handles creation and management of bar items.

#### Constructor

##### `Item:new(item_type?, name?, position?, config?)`

Creates a new Item instance.

**Parameters:**
- `item_type` (string, optional): Type of item ("item", "space", "alias"). Default: "item"
- `name` (string, optional): Item name/identifier
- `position` (string, optional): Position ("left", "right", "center", "q", "e"). Default: "right"
- `config` (table, optional): Initial item configuration

**Returns:**
- `Item`: New Item instance

#### Configuration Methods

##### `Item:set(properties)`

Set item properties.

**Parameters:**
- `properties` (table): Properties to set

**Returns:**
- `Item`: Self for method chaining

##### `Item:icon(icon_config)`

Set item icon properties.

**Parameters:**
- `icon_config` (table): Icon configuration

**Returns:**
- `Item`: Self for method chaining

##### `Item:label(label_config)`

Set item label properties.

**Parameters:**
- `label_config` (table): Label configuration

**Returns:**
- `Item`: Self for method chaining

##### `Item:background(bg_config)`

Set item background properties.

**Parameters:**
- `bg_config` (table): Background configuration

**Returns:**
- `Item`: Self for method chaining

#### Convenience Methods

##### `Item:icon_string(icon_str)`

Set icon text.

**Parameters:**
- `icon_str` (string): Icon string/text

##### `Item:icon_color(color)`

Set icon color.

**Parameters:**
- `color` (number|string): Icon color

##### `Item:icon_font(font, size?)`

Set icon font.

**Parameters:**
- `font` (string): Font family
- `size` (number, optional): Font size

##### `Item:label_string(label_str)`

Set label text.

**Parameters:**
- `label_str` (string): Label text

##### `Item:label_color(color)`

Set label color.

**Parameters:**
- `color` (number|string): Label color

##### `Item:label_font(font, size?)`

Set label font.

**Parameters:**
- `font` (string): Font family
- `size` (number, optional): Font size

##### `Item:bg_color(color)`

Set background color.

**Parameters:**
- `color` (number|string): Background color

##### `Item:bg_corner_radius(radius)`

Set background corner radius.

**Parameters:**
- `radius` (number): Corner radius in pixels

##### `Item:width(width)`

Set item width.

**Parameters:**
- `width` (number): Width in pixels

##### `Item:padding(left, right)`

Set item padding.

**Parameters:**
- `left` (number): Left padding
- `right` (number): Right padding

##### `Item:hide(hidden)`

Hide/show the item.

**Parameters:**
- `hidden` (boolean): Whether to hide the item

#### Scripting Methods

##### `Item:script(script_path, update_freq?)`

Set item update script.

**Parameters:**
- `script_path` (string): Path to the script
- `update_freq` (number, optional): Update frequency in seconds

##### `Item:click_script(script_path)`

Set item click script.

**Parameters:**
- `script_path` (string): Path to the click script

##### `Item:subscribe(event, callback)`

Subscribe to events.

**Parameters:**
- `event` (string): Event name
- `callback` (function): Callback function

#### Utility Methods

##### `Item:query(property?)`

Query item properties from sketchybar.

**Parameters:**
- `property` (string, optional): Specific property to query

**Returns:**
- `table`: Query results

##### `Item:clone(new_name)`

Clone the item with a new name.

**Parameters:**
- `new_name` (string): New item name

**Returns:**
- `Item`: New item instance

##### `Item:remove()`

Remove/delete the item.

**Example:**
```lua
local cpu_item = lib.Item:new("item", "cpu", "right")
cpu_item:icon_string("󰻠")
        :icon_color(0xff89b4fa)
        :label_string("0%")
        :label_color(0xffffffff)
        :bg_color(0xff1e1e2e)
        :bg_corner_radius(5)
        :script("~/.config/sketchybar/plugins/cpu.sh", 5)
```

---

### Bracket Class

The Bracket class handles grouping and styling multiple items together.

#### Constructor

##### `Bracket:new(name, members, config?)`

Creates a new Bracket instance.

**Parameters:**
- `name` (string): Bracket name/identifier
- `members` (table|string[]): List of item names to include in bracket
- `config` (table, optional): Initial bracket configuration

**Returns:**
- `Bracket`: New Bracket instance

#### Configuration Methods

##### `Bracket:set(properties)`

Set bracket properties.

**Parameters:**
- `properties` (table): Properties to set

##### `Bracket:background(bg_config)`

Set bracket background properties.

**Parameters:**
- `bg_config` (table): Background configuration

##### `Bracket:bg_color(color)`

Set background color.

**Parameters:**
- `color` (number|string): Background color

##### `Bracket:bg_corner_radius(radius)`

Set background corner radius.

**Parameters:**
- `radius` (number): Corner radius in pixels

##### `Bracket:hide(hidden)`

Hide/show the bracket.

**Parameters:**
- `hidden` (boolean): Whether to hide the bracket

#### Member Management

##### `Bracket:add_members(item_names)`

Add member items to the bracket.

**Parameters:**
- `item_names` (string|string[]): Item name(s) to add

##### `Bracket:remove_members(item_names)`

Remove member items from the bracket.

**Parameters:**
- `item_names` (string|string[]): Item name(s) to remove

##### `Bracket:set_members(members)`

Set bracket members (replaces existing members).

**Parameters:**
- `members` (string[]): List of item names

##### `Bracket:get_members()`

Get current bracket members.

**Returns:**
- `string[]`: List of member item names

#### Event Methods

##### `Bracket:subscribe(event, callback)`

Subscribe to events.

**Parameters:**
- `event` (string): Event name
- `callback` (function): Callback function

##### `Bracket:click_script(script_path)`

Set click script for the bracket.

**Parameters:**
- `script_path` (string): Path to the click script

**Example:**
```lua
local system_bracket = lib.Bracket:new("system_stats", {"cpu", "memory"})
system_bracket:bg_color(0xff1e1e2e)
              :bg_corner_radius(5)
              :bg_height(30)
```

---

### Event Class

The Event class handles creation and management of custom events.

#### Constructor

##### `Event:new(name)`

Creates a new Event instance.

**Parameters:**
- `name` (string): Event name/identifier

**Returns:**
- `Event`: New Event instance

#### Event Methods

##### `Event:trigger(data?)`

Trigger/fire the event.

**Parameters:**
- `data` (table, optional): Optional data to pass with the event

##### `Event:subscribe(callback)`

Subscribe a callback to this event.

**Parameters:**
- `callback` (function): Callback function to execute when event is triggered

#### Utility Methods

##### `Event:get_name()`

Get event name.

**Returns:**
- `string`: Event name

##### `Event:get_subscribers()`

Get list of subscribers.

**Returns:**
- `function[]`: List of callback functions

##### `Event:remove()`

Remove/delete the event.

**Example:**
```lua
local custom_event = lib.Event:new("my_custom_event")
custom_event:subscribe(function(env)
  print("Event triggered:", env.INFO)
end)

-- Later, trigger the event
custom_event:trigger({ custom_data = "value" })
```

---

### Animation Class

The Animation class provides utilities for creating animations.

#### Constructor

##### `Animation:new(name, duration, easing?)`

Creates a new Animation instance.

**Parameters:**
- `name` (string): Animation name/identifier
- `duration` (number): Animation duration in seconds
- `easing` (string, optional): Easing function. Default: "ease_in_out"

**Returns:**
- `Animation`: New Animation instance

#### Configuration Methods

##### `Animation:duration(duration)`

Set animation duration.

**Parameters:**
- `duration` (number): Duration in seconds

##### `Animation:easing(easing)`

Set easing function.

**Parameters:**
- `easing` (string): Easing function name

##### `Animation:set_properties(properties)`

Set animation properties.

**Parameters:**
- `properties` (table): Properties to animate

#### Animation Methods

##### `Animation:start(callback?)`

Start the animation.

**Parameters:**
- `callback` (function, optional): Optional callback to execute when animation completes

#### Static Factory Methods

##### `Animation.linear(name, duration)`

Create a linear animation.

##### `Animation.ease_in(name, duration)`

Create an ease-in animation.

##### `Animation.ease_out(name, duration)`

Create an ease-out animation.

##### `Animation.ease_in_out(name, duration)`

Create an ease-in-out animation.

##### `Animation.bounce(name, duration)`

Create a bounce animation.

##### `Animation.overshoot(name, duration)`

Create an overshoot animation.

**Example:**
```lua
local bounce_anim = lib.Animation.bounce("item_bounce", 0.5)
bounce_anim:set_properties({ y_offset = 10 })
           :start(function()
             print("Animation completed!")
           end)
```

---

## Examples

### Complete Bar Setup

```lua
local sbar = require('sbar').get()
local lib = require('lib').init(sbar)

-- Configure bar
local bar = lib.Bar:new()
bar:height(32)
   :color(0xff1e1e2e)
   :border_width(1)
   :border_color(0xff313244)
   :corner_radius(5)
   :position("top")
   :padding(10, 10)
   :apply()

-- Create clock item
local clock = lib.Item:new("item", "clock", "right")
clock:label_string(os.date("%H:%M"))
     :label_color(0xffffffff)
     :label_font("SF Pro Display", 14)
     :bg_color(0xff313244)
     :bg_corner_radius(5)
     :padding(10, 10)
     :script("~/.config/sketchybar/plugins/clock.sh", 30)

-- Create system monitoring items
local cpu = lib.Item:new("item", "cpu", "right")
cpu:icon_string("󰻠")
   :icon_color(0xff89b4fa)
   :label_string("0%")
   :label_color(0xffffffff)

local memory = lib.Item:new("item", "memory", "right")
memory:icon_string("󰍛")
      :icon_color(0xfff38ba8)
      :label_string("0%")
      :label_color(0xffffffff)

-- Group items with bracket
local system_bracket = lib.Bracket:new("system", {"cpu", "memory"})
system_bracket:bg_color(0xff1e1e2e)
              :bg_corner_radius(5)
              :bg_height(30)
```

### Custom Event Handling

```lua
-- Create custom event
local workspace_event = lib.Event:new("workspace_changed")

-- Subscribe to event
workspace_event:subscribe(function(env)
  local workspace = env.INFO
  print("Switched to workspace:", workspace)
  
  -- Update items based on workspace
  local workspace_item = lib.Item:new("item", "workspace", "left")
  workspace_item:label_string("󰍹 " .. workspace)
end)

-- Trigger event (typically from external script)
workspace_event:trigger({ workspace = "Desktop 2" })
```

---

## Type Definitions

### Configuration Tables

#### BarConfig
```lua
{
  height?: number,
  color?: number|string,
  border_color?: number|string,
  border_width?: number,
  corner_radius?: number,
  position?: "top"|"bottom",
  sticky?: boolean,
  padding_left?: number,
  padding_right?: number,
  margin?: number,
  y_offset?: number,
  shadow?: boolean,
  hidden?: boolean,
  topmost?: boolean,
  display?: number
}
```

#### ItemConfig
```lua
{
  icon?: IconConfig,
  label?: LabelConfig,
  background?: BackgroundConfig,
  script?: string,
  update_freq?: number,
  click_script?: string,
  width?: number,
  padding_left?: number,
  padding_right?: number,
  y_offset?: number,
  drawing?: boolean
}
```

#### IconConfig
```lua
{
  string?: string,
  color?: number|string,
  font?: FontConfig,
  padding_left?: number,
  padding_right?: number,
  y_offset?: number,
  width?: number
}
```

#### LabelConfig
```lua
{
  string?: string,
  color?: number|string,
  font?: FontConfig,
  padding_left?: number,
  padding_right?: number,
  y_offset?: number,
  width?: number,
  max_chars?: number
}
```

#### BackgroundConfig
```lua
{
  color?: number|string,
  border_color?: number|string,
  border_width?: number,
  corner_radius?: number,
  height?: number,
  padding_left?: number,
  padding_right?: number,
  y_offset?: number,
  drawing?: boolean
}
```

#### FontConfig
```lua
{
  family?: string,
  size?: number,
  style?: "Regular"|"Bold"|"Italic",
  smoothing?: boolean
}
```

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive documentation for new features
4. Include examples for new functionality
5. Submit a pull request

### Development Guidelines

- Maintain comprehensive LuaDoc annotations
- Follow existing code patterns and naming conventions
- Add examples for new features
- Test all functionality with actual SketchyBar configurations
- Keep the API consistent and intuitive