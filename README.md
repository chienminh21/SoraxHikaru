# Sora x Hikaru

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=venom&height=220&color=0:171326,50:5741A8,100:AA83FF&text=Sora%20x%20Hikaru&fontColor=FFFFFF&fontSize=52&fontAlignY=45&animation=fadeIn" width="100%" />
</p>

<p align="center">
  <b>A customizable Roblox UI library written in Luau.</b><br>
  Clean interfaces, flexible components, and a simple API.
</p>

<p align="center">
  <a href="https://github.com/chienminh21/SoraxHikaru">
    <img src="https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github" />
  </a>
  <img src="https://img.shields.io/badge/Version-2.0-9675FF?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Language-Luau-00A2FF?style=for-the-badge" />
</p>

Sora x Hikaru is an improved continuation of the original PhiPhai v2 project, with a new name and a clearer UI system.

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/v/Loader.lua"))()
```

## Discord

```
https://discord.gg/6y7TpYTBkW
```

## Introduction

Sora x Hikaru is a UI library for Roblox scripts written in Luau.

It gives you ready-made interface pieces so you can build windows, tabs, modules, controls, notifications, dialogs, and more without assembling every element by hand.

The goal is a consistent layout and a straightforward API that is still easy to customize.

## Features

**Interface**
- Custom name and version
- Dark and Light themes, plus custom themes
- Adjustable window transparency
- Custom toggle key
- Image backgrounds with multiple display styles
- Optional watermark

**Components**
- Tabs and modules
- Buttons, checkboxes, textboxes
- Sliders and range sliders
- Single and multi-select dropdowns
- Color pickers
- Dividers, paragraphs, and text labels

**Systems**
- Info / success / warn / error notifications
- Custom notification icons
- Confirmation dialogs
- Progress bar with completion callback
- Save, export, and reset configuration

## Project Structure

```text
SoraxHikaru/
├── Lib/
│   └── UI.lua
├── Example.lua
└── README.md
```

| File | Description |
|------|-------------|
| `Lib/UI.lua` | Main UI library |
| `Example.lua` | Full usage example |
| `README.md` | Documentation |

## Requirements

The load example expects an environment that supports:

- Luau
- Roblox services
- `game:HttpGet()`
- `loadstring()`
- `getgenv()`

This is not a standard Roblox Studio LocalScript install path. It targets client execution environments that expose those APIs.

## Installation

**1. Load the library**

```lua
local BASE = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/"
local Library = loadstring(game:HttpGet(BASE .. "Lib/UI.lua"))()
```

**2. Create a window**

```lua
local Window = Library.new()
```

**3. Create tabs**

```lua
local Main = Window:create_tab("Main", "home")
local Visuals = Window:create_tab("Visuals", "eye")
local Settings = Window:create_tab("Settings", "settings")
```

**4. Load the UI**

```lua
Window:load()
```

## Quick test

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/Lib/Example.lua"))()
```

## Configuration

Set `getgenv().GG` **before** loading the library. Every field is optional.

```lua
getgenv().GG = {
    UIName = "Sora x Hikaru",
    Version = "v2.0",
    Theme = "Dark",
    Themes = {
        Ocean = {
            Base = "Dark",
            Background = Color3.fromRGB(8, 16, 28),
            ModuleBackground = Color3.fromRGB(14, 28, 46),
            Card = Color3.fromRGB(22, 42, 66),
            Accent = Color3.fromRGB(0, 170, 255),
            TextSecondary = Color3.fromRGB(140, 200, 255),
            Stroke = Color3.fromRGB(34, 64, 96),
        },
    },
    TextColor = nil,
    Transparency = 0.15,
    ToggleKey = Enum.KeyCode.Insert,
    NotifyMode = "new",
    Search = true,
    SearchKey = Enum.KeyCode.F,
    Watermark = true,
    WatermarkIcon = "rbxassetid://76051962811019",
    WatermarkSize = 40,
    WatermarkPosition = "TopLeft",
    WatermarkTransparency = 0,
    WatermarkText = "",
    ImageBackground = "",
    ImageBackgroundStyle = "Crop",
    ImageBackgroundTransparency = 0.7,
}
```

| Option | Type | Description |
|--------|------|-------------|
| `UIName` | string | Window title |
| `Version` | string | Version label |
| `Theme` | string | `"Dark"`, `"Light"`, or a custom theme name |
| `Transparency` | number | Window transparency (`0` = solid) |
| `ToggleKey` | `Enum.KeyCode` | Show / hide key |
| `NotifyMode` | string | `"new"` or `"old"` |
| `Watermark` | boolean | Show watermark |
| `ImageBackground` | string | Asset id or URL |
| `ImageBackgroundStyle` | string | Background style |
| `ImageBackgroundTransparency` | number | Background image transparency |

## Core concepts

### Window

```lua
local Window = Library.new()
```

### Tabs

```lua
local Main = Window:create_tab("Main", "home")
```

The second argument is a Lucide icon name.

### Modules

Modules group related controls inside a tab.

```lua
local Example = Main:create_module({
    title = "Example",
    description = "Example module",
    flag = "example",
    section = "left",
    setting = true,
    notification = true,
    callback = function(state)
        print(state)
    end,
})
```

| Option | Description |
|--------|-------------|
| `title` | Module title |
| `description` | Short description |
| `flag` | Unique config key |
| `section` | `"left"` or `"right"` |
| `setting` | Gear menu (keybind, activation mode, startup…) |
| `notification` | Bell menu (notify on enable / disable) |
| `callback` | Called when the module is toggled |

Always use unique flags so saved values do not collide.

## Components

### Button

```lua
Example:create_button({
    title = "Execute",
    callback = function()
        print("Button clicked")
    end,
})
```

### Checkbox

```lua
Example:create_checkbox({
    title = "Enable Feature",
    flag = "enable_feature",
    callback = function(state)
        print("Enabled:", state)
    end,
})
```

### Slider

```lua
Example:create_slider({
    title = "Speed",
    flag = "speed",
    minimum_value = 1,
    maximum_value = 100,
    value = 50,
    round_number = true,
    left_color = Color3.fromRGB(255, 255, 255),
    max_color = Color3.fromRGB(0, 0, 0),
    callback = function(value)
        print("Speed:", value)
    end,
})
```

### Range slider

```lua
Example:create_range_slider({
    title = "Delay",
    flag = "delay",
    minimum_value = 0,
    maximum_value = 10,
    min_value = 1,
    max_value = 3,
    callback = function(minValue, maxValue)
        print(minValue, maxValue)
    end,
})
```

### Dropdown

```lua
Example:create_dropdown({
    title = "Target",
    flag = "target",
    options = { "Nearest", "Lowest HP", "Boss" },
    maximum_options = 6,
    callback = function(option)
        print("Selected:", option)
    end,
})
```

### Multi-select dropdown

```lua
Example:create_dropdown({
    title = "Items",
    flag = "items",
    options = { "Coin", "Gem", "Key" },
    maximum_options = 6,
    multi_dropdown = true,
    callback = function(option)
        local selected = Library._config._flags.items or {}
        print(table.concat(selected, ", "))
    end,
})
```

### Textbox

```lua
Example:create_textbox({
    title = "Username",
    placeholder = "Enter your name...",
    flag = "username",
    callback = function(text)
        print("Username:", text)
    end,
})
```

### Color picker

```lua
local ColorPicker = Example:create_colorpicker({
    title = "Outline Color",
    flag = "outline_color",
    default = Color3.fromRGB(99, 102, 241),
    callback = function(color)
        print(color)
    end,
})

local current = ColorPicker:Get()
ColorPicker:Set(Color3.fromRGB(255, 0, 0))
```

### Divider / paragraph / text

```lua
Example:create_divider({ showtopic = true, title = "Settings" })

Example:create_paragraph({
    title = "Information",
    text = "This is an example paragraph.",
    customScale = 70,
})

local Status = Example:create_text({
    text = "Status: Idle",
    CustomYSize = 24,
})
Status:Set({ text = "Status: Ready" })
```

## Notifications

```lua
Library.Notify.Info("Information", "Something happened.", 3)
Library.Notify.Success("Success", "Operation completed.", 3)
Library.Notify.Warn("Warning", "Please be careful.", 3)
Library.Notify.Error("Error", "Something went wrong.", 3)

Library.Notify.Send({
    title = "Sora x Hikaru",
    text = "Welcome!",
    type = "success",
    icon = "check-circle",
    duration = 3,
})
```

## Dialogs

```lua
Window:Dialog({
    Icon = "alert-circle",
    IconThemed = true,
    Title = "Confirm Action",
    Content = "Are you sure you want to continue?",
    Buttons = {
        {
            Title = "Confirm",
            Icon = "check",
            Variant = "Destructive",
            Callback = function()
                Library.Notify.Success("Confirmed", "Action completed.", 3)
            end,
        },
        {
            Title = "Cancel",
            Icon = "x",
            Variant = "Secondary",
            Callback = function()
                print("Cancelled")
            end,
        },
    },
})
```

## Progress bar

```lua
local Progress = Main:ProgressBar({
    Title = "Download",
    Desc = "Downloading files...",
    Icon = "download",
    Value = { Min = 0, Max = 100, Default = 0 },
    Visible = false,
    AutoHide = true,
    OnComplete = function()
        Library.Notify.Success("Download", "Finished!", 3)
    end,
})

Progress:Reset()
Progress:Set(50)
Progress:Increment(10)
Progress:Run(5)
```

## Theme and transparency

```lua
Library.SetTheme("Dark")
Library.SetTheme("Light")
Library.SetThemeColor("Accent", Color3.fromRGB(152, 181, 255))
Library.SetTransparency(0.15)
```

Use a `ready` flag so theme callbacks do not fire side effects while saved config is restored:

```lua
local ready = false

Interface:create_dropdown({
    title = "Theme",
    flag = "ui_theme",
    options = Library.GetThemes(),
    maximum_options = 6,
    callback = function(option)
        if ready then
            Library.SetTheme(option)
        end
    end,
})

Window:load()
ready = true
```

## Background

```lua
Window:SetImageBackground("rbxassetid://123456789")
Window:SetImageBackground("rbxassetid://123456789", "Crop")
Window:SetImageBackground("rbxassetid://123456789", nil, 0.7)
```

| Style | Description |
|-------|-------------|
| `Crop` | Crop to fit |
| `Stretch` | Stretch to fill |
| `Fit` | Fit inside |
| `Tile` | Repeat |
| `FadeLeft` / `FadeRight` / `FadeTop` / `FadeBottom` | Directional fade |

## Watermark

```lua
Library.SetWatermark(true)
Library.SetWatermark(false)
Library.SetWatermark(not Library._watermark_on)
Library.SetWatermarkIcon("rbxassetid://76051962811019")
```

## Notification style

```lua
Library.SetNotifyMode("new")
Library.SetNotifyMode("old")
```

## Configuration management

```lua
Library.SaveConfig()
Library.LoadConfig()
Library.ExportConfig()
Library.ResetConfig()
```

Example buttons:

```lua
local Config = Settings:create_module({
    title = "Config",
    description = "Manage your configuration",
    flag = "config",
    section = "right",
    callback = function() end,
})

Config:create_button({ title = "Save Config", callback = Library.SaveConfig })
Config:create_button({ title = "Export Config", callback = Library.ExportConfig })
Config:create_button({ title = "Reset Config", callback = Library.ResetConfig })
```

## API reference

| API | Description |
|-----|-------------|
| `Library.new()` | Create window |
| `Window:create_tab()` | Create tab |
| `Window:load()` | Show UI |
| `Tab:create_module()` | Create module |
| `Module:create_button()` | Button |
| `Module:create_checkbox()` | Checkbox |
| `Module:create_slider()` | Slider |
| `Module:create_range_slider()` | Range slider |
| `Module:create_dropdown()` | Dropdown |
| `Module:create_textbox()` | Textbox |
| `Module:create_colorpicker()` | Color picker |
| `Module:create_divider()` | Divider |
| `Module:create_paragraph()` | Paragraph |
| `Module:create_text()` | Text label |
| `Window:Dialog()` | Dialog |
| `Tab:ProgressBar()` | Progress bar |
| `Library.SetTheme()` | Set theme |
| `Library.SetTransparency()` | Window transparency |
| `Library.SetWatermark()` | Watermark visibility |
| `Library.SetNotifyMode()` | Notification style |
| `Library.SaveConfig()` | Save config |
| `Library.ExportConfig()` | Export config |
| `Library.ResetConfig()` | Reset config |

## Troubleshooting

**UI does not appear**
- Confirm the raw GitHub URL is correct
- Confirm `Lib/UI.lua` exists in the repo
- Confirm the executor supports `HttpGet` / `loadstring` / `getgenv`
- Check the developer console for errors

**A control does nothing**
- Create it from a module, not from the tab root
- Give every saved control a unique `flag`
- Check callback arguments
- Provide required fields such as `maximum_options` on dropdowns

**Config behaves oddly**
- Define `GG` before loading the library
- Avoid duplicate flags
- Use a `ready` flag so init callbacks do not run side effects

## Development

Sora x Hikaru is under active development. APIs and components may change.

See `Example.lua` for a full working sample.

## Credits

- Fork base: [Allusive UI](https://github.com/MarchHubOnTopFr/Allusive-UI/tree/main)
- Developer: [chienminh21](https://github.com/chienminh21)
- Project: [Sora x Hikaru](https://github.com/chienminh21/SoraxHikaru)

<p align="center">
  <b>Sora x Hikaru</b><br>
  Built with Luau.<br><br>
  <i>Clean interface. Flexible components. Simple development.</i>
</p>
