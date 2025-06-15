# SketchyBar Component Library

A modular component system built on top of [SbarLua](https://github.com/FelixKratz/SbarLua) for creating dynamic and maintainable SketchyBar configurations.

## Overview

This library provides a clean, object-oriented interface for configuring SketchyBar with the following core classes:

- **Bar**: Global bar configuration and properties
- **Item**: Individual bar items (text, icons, spaces, aliases)
- **Bracket**: Grouping and styling multiple items together
- **Event**: Custom event creation and handling
- **Animation**: Animation utilities and effects

## Quick Start

```lua
-- Initialize the library
local sbar = require('sbar').get()
local lib = require('lib').init(sbar)

-- Configure the bar
local bar = lib.Bar:new()
bar:height(32)
   :color(0xff1e1e2e)
   :position("top")
   :apply()

-- Create a simple item
local clock = lib.Item:new("item", "clock", "right")
clock:label_string(os.date("%H:%M"))
     :label_color(0xffffffff)
     :bg_color(0xff313244)
     :script("path/to/clock.sh", 30)
```

## Library Structure

```
lib/
├── init.lua          # Main library entry point
├── bar.lua           # Bar class implementation
├── item.lua          # Item class implementation
├── bracket.lua       # Bracket class implementation
├── event.lua         # Event class implementation
└── animation.lua     # Animation class implementation

bar/
├── init.lua          # Example component implementations
└── README.md         # This file
```

## Usage Examples

See `bar/init.lua` for comprehensive examples including:

- Simple text/icon items
- System monitoring components
- Grouped items with brackets
- Custom event handling
- Animated components

## Class Documentation

All classes include comprehensive LuaDoc annotations for IDE support and documentation generation. Key features:

### Bar Class
- Fluent API for configuration
- Support for all SketchyBar bar properties
- Method chaining for clean configuration

### Item Class
- Support for all item types (item, space, alias)
- Icon, label, and background configuration
- Script execution and event subscription
- Item positioning and styling

### Bracket Class
- Dynamic member management
- Background styling for grouped items
- Event handling for bracket interactions

### Event Class
- Custom event creation
- Callback subscription
- Event triggering with data

### Animation Class
- Pre-defined easing functions
- Custom animation properties
- Callback support for animation completion

## Integration

To use this library in your SketchyBar configuration:

1. Place the `lib/` directory in your SketchyBar config folder
2. Update your main configuration to require and initialize the library
3. Create components using the provided classes
4. Customize styling and behavior as needed

## Benefits

- **Type Safety**: Full LuaDoc annotations for IDE support
- **Modularity**: Separate concerns into focused classes
- **Maintainability**: Clean, readable configuration code
- **Extensibility**: Easy to add new components and behaviors
- **Consistency**: Unified API across all SketchyBar features