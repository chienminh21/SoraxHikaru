# Sora x Hikaru — Documentation

A modular Roblox UI library with customizable themes, tabs, modules, controls, notifications, keybinds, search, and configuration management\.

## Table of Contents

1. Installation
2. Configuration
3. Creating the Library
4. Creating a Window
5. Creating Tabs
6. Creating Modules
7. UI Controls
8. Module Settings
9. Themes
10. Notifications
11. Dialogs
12. Progress Bars
13. Search
14. Watermark
15. Image Background
16. Configuration Management
17. Keybind Management
18. Cleanup

## Test Example.lua
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/Lib/Example.lua"))()

```
## 1\. Installation

Load the library from your GitHub repository:

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/Lib/UI.lua"
))()
```

The library uses `getgenv().GG` for global configuration\.

## 2\. Configuration

Set configuration before loading the library\.

```lua
getgenv().GG = {
    UIName = "Sora x Hikaru",
    Version = "v2.0",

    FolderName = "SoraHikaru",
    GuiName = "SoraHikaru",

    Theme = "Dark",
    Transparency = 0.15,

    ToggleKey = Enum.KeyCode.Insert,
    Animations = true,

    Watermark = true,
    WatermarkIcon = "rbxassetid://76051962811019",
    WatermarkSize = 40,
    WatermarkPosition = "TopLeft",

    Search = true,
    SearchKey = Enum.KeyCode.F,

    GalacticText = true,
    GalacticSpeed = 1.5,

    NotifyMode = "new",
}
```

### Configuration options

|Option             |Description                       |
|-------------------|----------------------------------|
|`UIName`           |UI title                          |
|`Version`          |Version displayed in the interface|
|`FolderName`       |Folder used for saved data        |
|`GuiName`          |ScreenGui name                    |
|`Theme`            |Initial theme                     |
|`Transparency`     |UI transparency                   |
|`ToggleKey`        |UI visibility key                 |
|`Animations`       |Enable or disable animations      |
|`Watermark`        |Enable watermark                  |
|`WatermarkIcon`    |Watermark icon                    |
|`WatermarkSize`    |Watermark icon size               |
|`WatermarkPosition`|Watermark screen position         |
|`Search`           |Enable search                     |
|`SearchKey`        |Search shortcut                   |
|`GalacticText`     |Enable gradient title text        |
|`GalacticSpeed`    |Gradient animation speed          |
|`NotifyMode`       |Notification style                |

### Image background options

```lua
GG.ImageBackground = "rbxassetid://123456789"
GG.ImageBackgroundStyle = "Crop"
GG.ImageBackgroundTransparency = 0.7
```

Supported styles:

- `Stretch`
- `Fit`
- `Crop`
- `Tile`
- `FadeLeft`
- `FadeRight`
- `FadeTop`
- `FadeBottom`

### Custom theme configuration

```lua
GG.Themes = {
    Crimson = {
        Base = "Dark",
        Accent = Color3.fromRGB(180, 35, 45),
        AccentHover = Color3.fromRGB(220, 65, 75),
    }
}
```

Custom themes can also be registered using `Library.AddTheme`\.

## 3\. Creating the Library

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/Lib/UI.lua"
))()
```

## 4\. Creating a Window

```lua
local Window = Library.new()

Window:load()
```

`Library.new()` creates the library window\.

`Window:load()` loads the interface and its components\.

## 5\. Creating Tabs

Create tabs using `create_tab`\.

```lua
local Main = Window:create_tab({
    title = "Main",
    icon = "house",
})

local Settings = Window:create_tab({
    title = "Settings",
    icon = "settings",
})
```

Select a tab:

```lua
Main:Select()
```

## 6\. Creating Modules

Modules organize controls inside tabs\.

```lua
local MainModule = Main:create_module({
    title = "Example Module",
    description = "An example module",
})
```

You can add multiple modules to a tab\.

```lua
local FirstModule = Main:create_module({
    title = "First Module",
})

local SecondModule = Main:create_module({
    title = "Second Module",
})
```

## 7\. UI Controls

Controls are created through a module\.

### Paragraph

Displays informational text\.

```lua
MainModule:create_paragraph({
    title = "Information",
    content = "Welcome to Sora x Hikaru.",
})
```

### Text

Creates a text element\.

```lua
local Text = MainModule:create_text({
    title = "Status",
    text = "Ready",
})

Text:Set("Running")
```

### Checkbox

Creates an on/off control\.

```lua
MainModule:create_checkbox({
    title = "Enable Feature",
    flag = "EnableFeature",
    default = false,

    callback = function(value)
        print(value)
    end,
})
```

### Mini Toggle

Creates a compact toggle\.

```lua
local MiniToggle = MainModule:create_mini_toggle({
    title = "Mini Toggle",
    flag = "MiniToggle",
    default = false,

    callback = function(value)
        print(value)
    end,
})

MiniToggle:Set(true)
MiniToggle:Get()
MiniToggle:Toggle()
MiniToggle:SetTitle("Updated Toggle")
```

### Slider

Creates a numerical slider\.

```lua
MainModule:create_slider({
    title = "Walk Speed",
    flag = "WalkSpeed",

    min = 0,
    max = 100,
    default = 16,

    callback = function(value)
        print(value)
    end,
})
```

### Range Slider

Creates a slider with two values\.

```lua
MainModule:create_range_slider({
    title = "Value Range",
    flag = "ValueRange",

    min = 0,
    max = 100,
    default = {20, 80},

    callback = function(minValue, maxValue)
        print(minValue, maxValue)
    end,
})
```

### Dropdown

Creates an option selector\.

```lua
MainModule:create_dropdown({
    title = "Select Option",
    flag = "SelectedOption",

    options = {
        "Option 1",
        "Option 2",
        "Option 3",
    },

    callback = function(value)
        print(value)
    end,
})
```

For multiple selection:

```lua
MainModule:create_dropdown({
    title = "Multiple Options",
    flag = "MultipleOptions",

    options = {
        "Option 1",
        "Option 2",
        "Option 3",
    },

    multi_dropdown = true,
    maximum_options = 3,

    callback = function(value)
        print(value)
    end,
})
```

### Player List

Creates a dropdown containing available players\.

```lua
MainModule:create_playerlist({
    title = "Select Player",
    flag = "SelectedPlayer",

    callback = function(player)
        print(player)
    end,
})
```

### Textbox

Creates a text input\.

```lua
MainModule:create_textbox({
    title = "Enter Text",
    flag = "TextInput",
    placeholder = "Type here...",

    callback = function(value)
        print(value)
    end,
})
```

### Button

Creates a clickable button\.

```lua
MainModule:create_button({
    title = "Click Me",

    callback = function()
        print("Button clicked")
    end,
})
```

### Feature

Creates a feature control with module state and settings\.

```lua
MainModule:create_feature({
    title = "Example Feature",
    flag = "ExampleFeature",

    callback = function(enabled)
        print(enabled)
    end,
})
```

### Color Picker

Creates a color selection control\.

```lua
local ColorPicker = MainModule:create_colorpicker({
    title = "Accent Color",
    flag = "AccentColor",
    default = Color3.fromRGB(255, 50, 50),

    callback = function(color)
        print(color)
    end,
})

ColorPicker:Set(Color3.fromRGB(0, 170, 255))

local CurrentColor = ColorPicker:Get()
```

### Divider

Adds a divider between controls\.

```lua
MainModule:create_divider()
```

### Section

Creates a titled section\.

```lua
MainModule:create_section({
    title = "General Settings",
})
```

### Tooltip

Adds a tooltip to a GUI object\.

```lua
MainModule:create_tooltip(
    SomeGuiObject,
    "This is a tooltip"
)
```

## 8\. Module Settings

Modules support state management and keybind\-related functionality\.

The module implementation includes:

- Enable and disable state\.
- Keybind handling\.
- Hold\-mode handling\.
- Floating module controls\.
- Module settings\.
- Notification and sound options\.

Use the module’s `create_feature` control when you need a feature toggle with a callback\.

## 9\. Themes

Sora x Hikaru includes built\-in themes:

- `Dark`
- `Light`

Switch themes:

```lua
Library.SetTheme("Light")
Library.SetTheme("Dark")
```

Register a custom theme:

```lua
Library.AddTheme("Crimson", {
    Base = "Dark",
    Accent = Color3.fromRGB(180, 35, 45),
})
```

Get available themes:

```lua
local Themes = Library.GetThemes()
```

Get the active theme:

```lua
local CurrentTheme = Library.GetTheme()
```

Get theme colors:

```lua
local Colors = Library.GetThemeColors()
```

Change an individual theme color:

```lua
Library.SetThemeColor(
    "Accent",
    Color3.fromRGB(255, 50, 50)
)
```

## 10\. Notifications

Sora x Hikaru supports multiple notification styles\.

Set notification mode:

```lua
Library.SetNotifyMode("new")
Library.SetNotifyMode("old")
Library.SetNotifyMode("dynamic")
```

Available notification modes:

- `new`
- `old`
- `dynamic`

### Notification types

```lua
Library.Notify.Info(
    "Information",
    "This is an information message.",
    3
)

Library.Notify.Success(
    "Success",
    "Operation completed.",
    3
)

Library.Notify.Warn(
    "Warning",
    "Something needs attention.",
    3
)

Library.Notify.Error(
    "Error",
    "Something went wrong.",
    3
)
```

Send a custom notification:

```lua
Library.Notify.Send({
    title = "Custom Notification",
    description = "Notification message",
})
```

Clear notifications:

```lua
Library.Notify.Clear()
```

Additional notification functions:

```lua
Library.GetNotifyMode()
Library.GetDynamicIsland()
Library.Notify.ResetDynamic()
Library.Notify.Destroy()
Library.SendNotification()
```

## 11\. Dialogs

Create a dialog from the window\.

```lua
Window:Dialog({
    Title = "Confirmation",
    Content = "Do you want to continue?",

    Buttons = {
        {
            Title = "Confirm",
            Callback = function()
                print("Confirmed")
            end,
        },
        {
            Title = "Cancel",
            Callback = function()
                print("Cancelled")
            end,
        },
    },
})
```

Use the dialog options supported by the current implementation\.

## 12\. Progress Bars

Create a progress bar from a tab\.

```lua
local Progress = Main:ProgressBar({
    Title = "Loading",
    Description = "Please wait...",
    Min = 0,
    Max = 100,
    Default = 0,
})
```

Available manager methods:

```lua
Progress:Show()
Progress:Hide()
Progress:Destroy()

Progress:Set(50)
Progress:Increment(10)
Progress:Get()

Progress:SetTitle("Downloading")
Progress:SetDesc("Loading resources")
Progress:SetRange(0, 200)

Progress:Run()
Progress:Stop()
Progress:Reset()
```

## 13\. Search

Search can be enabled through configuration\.

```lua
GG.Search = true
GG.SearchKey = Enum.KeyCode.F
```

Search functions:

```lua
Window:Search()
Library.OpenSearch()
Library.CloseSearch()
```

The search system can locate available UI entries and navigate to matching controls\.

## 14\. Watermark

Watermark settings can be configured before loading the library\.

```lua
GG.Watermark = true
GG.WatermarkIcon = "rbxassetid://76051962811019"
GG.WatermarkSize = 40
GG.WatermarkPosition = "TopLeft"
GG.WatermarkOffset = Vector2.new(12, 12)
GG.WatermarkTransparency = 0
GG.WatermarkText = "{fps}"
```

Watermark functions:

```lua
Library.CreateWatermark()
Library.SetWatermark(true)
Library.SetWatermarkIcon("rbxassetid://123456789")
Library.SetWatermarkOptions({
    Position = "TopRight",
})
Library.DestroyWatermark()
```

## 15\. Image Background

Set the image background:

```lua
Library.SetImageBackground(
    "rbxassetid://123456789",
    "Crop",
    0.7
)
```

The background can also be configured through `GG.ImageBackground` before loading\.

## 16\. Configuration Management

Sora x Hikaru provides configuration functions\.

### Save

```lua
Library.SaveConfig()
```

### Load

```lua
Library.LoadConfig()
```

### Reset

```lua
Library.ResetConfig()
```

### Export

```lua
local ConfigData = Library.ExportConfig()
print(ConfigData)
```

### Import

```lua
Library.ImportConfig(ConfigData)
```

### Silent Save

```lua
Library.SaveSilent()
```

Configuration data is stored using the configured folder name\.

## 17\. Keybind Management

Get registered keybinds:

```lua
local Keybinds = Library.GetKeybinds()
```

Clear a keybind:

```lua
Library.ClearKeybind("FeatureName")
```

Clear all keybinds:

```lua
Library.ClearAllKeybinds()
```

## 18\. Cleanup

Destroy the watermark:

```lua
Library.DestroyWatermark()
```

Destroy the notification interface:

```lua
Library.Notify.Destroy()
```

Destroy the window:

```lua
Window:Destroy()
```

Use cleanup methods when removing the interface to avoid leaving unnecessary connections or GUI objects\.

## Credits & Inspiration

Sora x Hikaru was developed with inspiration from existing Roblox UI libraries, including [Allusive UI](https://github.com/MarchHubOnTopFr/Allusive-UI)\.

The project follows a modular UI approach while maintaining its own implementation, API structure, and customization options\.

Special thanks to the creators of Allusive UI for sharing their work with the Roblox development community\.

## Repository

[GitHub — Sora x Hikaru](https://github.com/chienminh21/SoraxHikaru)
