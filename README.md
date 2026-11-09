## Sora x Hikaru

Sora x Hikaru is an improved version of the original PhiPhai v2 script, featuring various improvements and a new name.
### Loader This Script: 
```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/v/Loader.lua'))()
```

### My discord Server:
```css
https://discord.gg/6y7TpYTBkW
```

### UI Library 


Sora x Hikaru

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=venom&height=220&color=0:171326,50:5741A8,100:AA83FF&text=Sora%20x%20Hikaru&fontColor=FFFFFF&fontSize=52&fontAlignY=45&animation=fadeIn" width="100%" />
</p>
<p align="center">
  <b>A customizable Roblox UI Library built with Luau.</b>
  <br>
  Designed for clean interfaces, flexible components, and straightforward development.
</p>
<p align="center">
  <a href="https://github.com/chienminh21/SoraxHikaru">
    <img src="https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github" />
  </a>
  <img src="https://img.shields.io/badge/Version-2.0-9675FF?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Language-Luau-00A2FF?style=for-the-badge" />
</p>

⸻

Introduction

Sora x Hikaru is a customizable UI Library for Roblox projects, written in Luau.

The project provides a collection of interface components that can be combined to create organized and configurable user interfaces.

Instead of manually building every interface element, developers can use the library’s API to create windows, tabs, modules, controls, notifications, dialogs, and other interface features.

The main goal is to provide a consistent development experience while keeping the API straightforward and customizable.

Contents

* Features
* Project Structure
* Requirements
* Installation
* Quick Start
* Configuration
* Core Concepts
* Components
* Notifications
* Dialogs
* Progress Bar
* Theme Management
* Background Customization
* Watermark
* Configuration Management
* Complete Example
* API Reference
* Troubleshooting
* Credits

⸻

Features

Interface

* Customizable interface name and version.
* Dark and Light themes.
* Adjustable window transparency.
* Custom toggle key.
* Image background support.
* Multiple background display styles.
* Watermark visibility control.

UI Components

* Tabs
* Modules
* Buttons
* Checkboxes
* Sliders
* Range sliders
* Dropdowns
* Multi-select dropdowns
* Textboxes
* Color pickers
* Dividers
* Paragraphs
* Text elements

Additional Systems

* Multiple notification types.
* Custom notification icons.
* Confirmation dialogs.
* Progress bar with completion callback.
* Configuration saving.
* Configuration exporting.
* Configuration resetting.
```lua
⸻

Project Structure

SoraxHikaru/
│
├── Lib/
│   └── UI.lua
│
├── Example.lua
│
└── README.md

File	Description
Lib/UI.lua	Main UI Library
Example.lua	Example implementation
README.md	Project documentation

⸻
```
Requirements

Before using the library, make sure your environment supports the APIs required by your implementation.

The loading example uses:

* Luau
* Roblox game services
* game:HttpGet()
* loadstring()
* getgenv()

Environment note: The loading example uses APIs commonly associated with compatible client execution environments. It is not a standard Roblox Studio LocalScript installation method.

⸻

Installation

1. Load the Library

Use the raw GitHub source to retrieve the main library file.
```lua
local BASE = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/"
local Library = loadstring(
    game:HttpGet(BASE .. "Lib/UI.lua")
)()
```
2. Create a Window
```lua
local Window = Library.new()
```
3. Create Tabs
```lua
local Main = Window:create_tab("Main", "home")
local Visuals = Window:create_tab("Visuals", "eye")
local Settings = Window:create_tab("Settings", "settings")
```
4. Load the Interface
```lua
Window:load()
```
⸻

Example test

The following example demonstrates the basic setup.
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/Lib/Example.lua"))()
```
⸻

Configuration

Configuration must be defined before loading the library.

All options are optional in the supplied example.
```lua
getgenv().GG = {
    UIName = "Sora x Hikaru",
    Version = "v2.0",
    Theme = "Dark",                  -- "Dark", "Light" or the name of a custom theme
    Themes = {                       -- custom themes: missing colors come from Base ("Dark" by default)
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
    TextColor = nil,                 -- optional: Color3 for all main UI text (dividers follow it)
    Transparency = 0.15,             -- window transparency (0 = solid)
    ToggleKey = Enum.KeyCode.Insert, -- key that shows / hides the window
    NotifyMode = "new",              -- notification style: "new" or "old"
    Watermark = true,                -- icon in a screen corner (also toggled by the "Show watermark" pill)
    WatermarkIcon = "rbxassetid://76051962811019", -- asset id / image URL / Lucide name
    WatermarkSize = 40,              -- icon size in pixels
    WatermarkPosition = "TopLeft",   -- TopLeft | TopRight | BottomLeft | BottomRight
    WatermarkTransparency = 0,       -- 0 = solid, 1 = invisible
    WatermarkText = "",              -- optional text next to the icon, "{fps}" shows the FPS
    ImageBackground = "",            -- "rbxassetid://..." / image URL / "" (none)
    ImageBackgroundStyle = "Crop",   -- Stretch | Fit | Crop | Tile | FadeLeft | FadeRight | FadeTop | FadeBottom
    ImageBackgroundTransparency = 0.7,
}
```
Configuration Options

Option	Type	Description
UIName	String	Interface name
Version	String	Interface version
Theme	String	Dark or Light
Transparency	Number	Window transparency
ToggleKey	Enum.KeyCode	Interface visibility key
NotifyMode	String	new or old
Watermark	Boolean	Enables or disables watermark
ImageBackground	String	Image asset ID or URL
ImageBackgroundStyle	String	Background display style
ImageBackgroundTransparency	Number	Background image transparency

⸻

Core Concepts

Window

The Window is the main container of the interface.
```lua
local Window = Library.new()
```
It is responsible for creating and loading the UI.

Tabs

Tabs organize different sections of the interface.
```lua
local Main = Window:create_tab("Main", "home")
local Visuals = Window:create_tab("Visuals", "eye")
local Settings = Window:create_tab("Settings", "settings")
```
The second argument accepts an icon identifier.

Modules

Modules organize related controls inside a tab.
```lua
local Example = Main:create_module({
    title = "Example",
    description = "Example module",
    flag = "example",
    section = "left",
    callback = function(state)
        print(state)
    end,
})
```
Module options:

Option	Description
title	Module title
description	Module description
flag	Unique configuration identifier
section	Module placement: left or right
callback	Called when module state changes

Use unique flags for different components to avoid configuration conflicts.

⸻

Components

Button

Creates an interactive button.
```lua
Example:create_button({
    title = "Execute",
    callback = function()
        print("Button clicked")
    end,
})
```
Checkbox

Creates a Boolean control.
```lua
Example:create_checkbox({
    title = "Enable Feature",
    flag = "enable_feature",
    callback = function(state)
        print("Enabled:", state)
    end,
})
```
Slider

Creates a numeric slider.
```lua
Example:create_slider({
    title = "Speed",
    flag = "speed",
    minimum_value = 1,
    maximum_value = 100,
    value = 50,
    round_number = true,
    callback = function(value)
        print("Speed:", value)
    end,
})
```
Option	Description
minimum_value	Minimum allowed value
maximum_value	Maximum allowed value
value	Initial value
round_number	Rounds the displayed value
callback	Receives the selected value

Range Slider

Creates a slider with two values.
```lua
Example:create_range_slider({
    title = "Delay",
    flag = "delay",
    minimum_value = 0,
    maximum_value = 10,
    min_value = 1,
    max_value = 3,
    callback = function(minValue, maxValue)
        print("Minimum:", minValue)
        print("Maximum:", maxValue)
    end,
})
```
The callback receives the selected minimum and maximum values.

Dropdown

Creates a single-selection dropdown.
```lua
Example:create_dropdown({
    title = "Target",
    flag = "target",
    options = {
        "Nearest",
        "Lowest HP",
        "Boss",
    },
    maximum_options = 6,
    callback = function(option)
        print("Selected:", option)
    end,
})
```
maximum_options is included in the supplied example and should be provided when creating a dropdown.

Multi-select Dropdown

Use multi_dropdown = true to enable multiple selections.
```lua
Example:create_dropdown({
    title = "Items",
    flag = "items",
    options = {
        "Coin",
        "Gem",
        "Key",
    },
    maximum_options = 6,
    multi_dropdown = true, 
    callback = function(option)
        local selected = Library._config._flags.items or {}
        print(table.concat(selected, ", "))
    end,
})

```

The selected list can be read from the configuration flags.

Textbox

Creates a text input.
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
Color Picker

Creates a color selection control.
```lua
local ColorPicker = Example:create_colorpicker({
    title = "Outline Color",
    flag = "outline_color",
    default = Color3.fromRGB(99, 102, 241),
    callback = function(color)
        print("Selected color:", color)
    end,
})
```
Read the selected color:
```lua
local currentColor = ColorPicker:Get()
```
Change the selected color:
```lua
ColorPicker:Set(Color3.fromRGB(255, 0, 0))
```
Divider

Creates a visual divider.
```lua
Example:create_divider({
    showtopic = true,
    title = "Settings",
})
```
Paragraph

Creates a paragraph for additional information.
```lua
Example:create_paragraph({
    title = "Information",
    text = "This is an example paragraph.",
    customScale = 70,
})
```
Text

Creates a text element that can be updated.
```lua
local Status = Example:create_text({
    text = "Status: Idle",
    CustomYSize = 24,
})
```
Update the text:
```lua
Status:Set({
    text = "Status: Ready",
})
```
⸻

Notifications

Sora x Hikaru provides several notification types.

Info
```lua
Library.Notify.Info(
    "Information",
    "Something happened.",
    3
)
```
Success
```lua
Library.Notify.Success(
    "Success",
    "Operation completed.",
    3
)
```
Warning
```
Library.Notify.Warn(
    "Warning",
    "Please be careful.",
    3
)
```
Error
```lua
Library.Notify.Error(
    "Error",
    "Something went wrong.",
    3
)
```
Custom Notification

Use Library.Notify.Send() to provide additional notification options.
```lua
Library.Notify.Send({
    title = "Sora x Hikaru",
    text = "Welcome!",
    type = "success",
    icon = "check-circle",
    duration = 3,
})
```
Property	Description
title	Notification title
text	Notification message
type	Notification type
icon	Icon identifier
duration	Display duration

⸻

Dialogs

Dialogs can be used to display information and request confirmation.
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
                Library.Notify.Success(
                    "Confirmed",
                    "Action completed.",
                    3
                )
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
Dialog Properties

Property	Description
Icon	Dialog icon
IconThemed	Applies theme styling to the icon
Title	Dialog title
Content	Dialog description
Buttons	List of dialog buttons

Each button can define a title, icon, variant, and callback.

⸻

Progress Bar

The progress bar provides a way to display progress for an operation.
```lua
local Progress = Main:ProgressBar({
    Title = "Download",
    Desc = "Downloading files...",
    Icon = "download",
    Value = {
        Min = 0,
        Max = 100,
        Default = 0,
    },
    Visible = false,
    AutoHide = true,
    OnComplete = function()
        Library.Notify.Success(
            "Download",
            "Finished!",
            3
        )
    end,
})
```
Progress Methods

Reset the progress:
```lua
Progress:Reset()

Set a specific value:

Progress:Set(50)

Increase progress:

Progress:Increment(10)

Run the progress animation:

Progress:Run(5)

The Run() example uses a duration of five seconds.
```
⸻

Theme Management

The library supports Dark and Light themes through its configuration and theme setter.

Set Theme
```lua
Library.SetTheme("Dark")
```
Or:
```lua
Library.SetTheme("Light")
```
Theme Dropdown
```lua
Interface:create_dropdown({
    title = "Theme",
    flag = "ui_theme",
    options = {
        "Dark",
        "Light",
    },
    maximum_options = 2,
    callback = function(option)
        if ready then
            Library.SetTheme(option)
        end
    end,
})
```
The ready flag prevents initialization callbacks from triggering additional side effects while the saved configuration is being loaded.

⸻

Transparency

Change the window transparency:
```lua
Library.SetTransparency(0.15)
```
A slider can be used to control transparency dynamically.
```lua
Interface:create_slider({
    title = "Window Transparency",
    flag = "ui_transparency",
    minimum_value = 0,
    maximum_value = 90,
    value = 15,
    round_number = true,
    callback = function(value)
        Library.SetTransparency(value / 100)
    end,
})
```
⸻

Background Customization

The library supports image backgrounds through Window:SetImageBackground().

Set Background
```lua
Window:SetImageBackground(
    "rbxassetid://123456789"
)
```
Set Background Style
```lua
Window:SetImageBackground(
    "rbxassetid://123456789",
    "Crop"
)
```
Set Background Transparency
```lua
Window:SetImageBackground(
    "rbxassetid://123456789",
    nil,
    0.7
)
```
Supported Styles

Style	Description
Crop	Crops the image to fit
Stretch	Stretches the image
Fit	Fits the image
Tile	Repeats the image
FadeLeft	Left fade
FadeRight	Right fade
FadeTop	Top fade
FadeBottom	Bottom fade

⸻

Watermark

The watermark can be controlled through the library.

Enable or Disable

Library.SetWatermark(true)
Library.SetWatermark(false)

Toggle

Library.SetWatermark(not Library._watermark_on)

The initial visibility can also be configured using:
```lua
getgenv().GG = {
    Watermark = true,
}
```
⸻

Notification Style

The notification mode can be configured with:
```lua
Library.SetNotifyMode("new")
```
Or:
```lua
Library.SetNotifyMode("old")
```
Available configuration values:

* new
* old

⸻

Configuration Management

The library includes configuration management methods.
```lua
Save Configuration

Library.SaveConfig()

Export Configuration

Library.ExportConfig()
```
Reset Configuration

Library.ResetConfig()

These methods can be connected to buttons inside a module.
```lua
local Config = Settings:create_module({
    title = "Config",
    description = "Manage your configuration",
    flag = "config",
    section = "right",
    callback = function() end,
})
Config:create_button({
    title = "Save Config",
    callback = Library.SaveConfig,
})
Config:create_button({
    title = "Export Config",
    callback = Library.ExportConfig,
})
```
⸻

Complete Example

A complete example demonstrating the library’s available components and systems is provided in:

Example.lua

The example includes:

* Library initialization
* Window creation
* Tab creation
* Module configuration
* UI component examples
* Notification examples
* Dialog examples
* Progress bar
* Theme settings
* Background customization
* Watermark controls
* Configuration management

⸻

API Reference
```lua
API	Description
Library.new()	Creates a new window
Window:create_tab()	Creates a tab
Window:load()	Loads the interface
Tab:create_module()	Creates a module
Module:create_button()	Creates a button
Module:create_checkbox()	Creates a checkbox
Module:create_slider()	Creates a slider
Module:create_range_slider()	Creates a range slider
Module:create_dropdown()	Creates a dropdown
Module:create_textbox()	Creates a textbox
Module:create_colorpicker()	Creates a color picker
Module:create_divider()	Creates a divider
Module:create_paragraph()	Creates a paragraph
Module:create_text()	Creates a text element
Window:Dialog()	Opens a dialog
Main:ProgressBar()	Creates a progress bar
Library.SetTheme()	Changes the theme
Library.SetTransparency()	Changes window transparency
Library.SetWatermark()	Changes watermark visibility
Library.SetNotifyMode()	Changes notification mode
Library.SaveConfig()	Saves configuration
Library.ExportConfig()	Exports configuration
Library.ResetConfig()	Resets configuration
```
⸻

Troubleshooting

The interface does not appear

Check the following:

* Verify that the raw GitHub URL is correct.
* Make sure Lib/UI.lua exists in the repository.
* Check whether the loading environment supports the APIs used by the example.
* Check the developer console for errors.

A component does not work

* Verify that the component is created from the correct module.
* Make sure every component that requires a flag has a unique flag.
* Check the callback arguments.
* Confirm that required options are provided.

Configuration does not behave as expected

* Define GG before loading the library.
* Check for duplicate flags.
* Verify the saved values.
* Make sure initialization callbacks do not trigger unwanted side effects.

⸻

Development

Sora x Hikaru is maintained as an evolving UI Library project.

The API and available components may change as development continues.

For implementation examples, refer to Example.lua.

Credits
Fork: https://github.com/MarchHubOnTopFr/Allusive-UI/tree/main

Developer: chienminh21

Project: Sora x Hikaru


* GitHub Repository: https://github.com/chienminh21/SoraxHikaru

⸻

<p align="center">
  <b>Sora x Hikaru</b>
  <br>
  Built with Luau.
  <br><br>
  <i>Clean interface. Flexible components. Simple development.</i>
</p>
