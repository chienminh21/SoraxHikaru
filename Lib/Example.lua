-- Sora x Hikaru | Complete V1 Example

-- Configuration

getgenv().GG = {
    UIName = "Sora x Hikaru",
    Version = "v1.0",

    Theme = "PureBlack",

    ToggleKey = Enum.KeyCode.Insert,
    NotifyMode = "new",

    Search = true,
    SearchKey = Enum.KeyCode.F,

    Transparency = 0.15,
    NotificationSoundId = nil,

    GalacticText = true,

    TextColor = Color3.fromRGB(225, 225, 230),
    TextSecondaryColor = Color3.fromRGB(155, 155, 165),
    AccentColor = Color3.fromRGB(205, 205, 215),

    GalacticColor1 = Color3.fromRGB(225, 225, 230),
    GalacticColor2 = Color3.fromRGB(120, 120, 130),
    GalacticSpeed = 1.2,

    Watermark = false,
    WatermarkIcon = "rbxassetid://76051962811019",
    WatermarkSize = 40,
    WatermarkPosition = "TopLeft",
    WatermarkTransparency = 0,
    WatermarkColor = Color3.fromRGB(220, 220, 230),
    WatermarkText = "{fps}",

    ImageBackground = "",
    ImageBackgroundStyle = "Crop",
    ImageBackgroundTransparency = 0.7,

    Themes = {
        PureBlack = {
            Base = "Dark",

            Background = Color3.fromRGB(3, 3, 3),
            BackgroundSecondary = Color3.fromRGB(12, 12, 12),
            ModuleBackground = Color3.fromRGB(19, 19, 19),

            TextPrimary = Color3.fromRGB(245, 245, 245),
            TextSecondary = Color3.fromRGB(155, 155, 165),

            Accent = Color3.fromRGB(205, 205, 215),
            AccentHover = Color3.fromRGB(235, 235, 240),

            Stroke = Color3.fromRGB(48, 48, 52),
            Divider = Color3.fromRGB(38, 38, 42),

            ToggleOff = Color3.fromRGB(65, 65, 70),
            Card = Color3.fromRGB(16, 16, 18),
        },
    },
}

-- Library

local BASE = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/"

local Library = loadstring(game:HttpGet(BASE .. "Lib/UI.lua"))()
local Window = Library.new()

local flags = Library._config._flags
local ready = false

-- Main tab

local Main = Window:create_tab("Main", "home")

local AutoParry = Main:create_module({
    title = "Auto Parry",
    description = "Example module with settings and notifications",
    flag = "auto_parry",
    section = "left",
    setting = true,
    notification = true,

    callback = function(state)
        print("Auto Parry:", state)
    end,
})

AutoParry:create_slider({
    title = "Accuracy",
    flag = "parry_accuracy",

    minimum_value = 0,
    maximum_value = 100,
    value = 70,

    round_number = true,

    left_color = Color3.fromRGB(255, 255, 255),
    max_color = Color3.fromRGB(0, 0, 0),

    callback = function(value)
        print("Accuracy:", value)
    end,
})

AutoParry:create_range_slider({
    title = "Parry Distance",
    flag = "parry_distance",

    minimum_value = 0,
    maximum_value = 50,
    min_value = 5,
    max_value = 30,

    round_number = true,

    left_color = Color3.fromRGB(255, 255, 255),
    max_color = Color3.fromRGB(0, 0, 0),

    callback = function(minValue, maxValue)
        print("Distance:", minValue, maxValue)
    end,
})

AutoParry:create_dropdown({
    title = "Parry Mode",
    flag = "parry_mode",

    options = {
        "Remote",
        "Keypress",
        "Hybrid",
    },

    maximum_options = 3,

    callback = function(option)
        print("Parry Mode:", option)
    end,
})

AutoParry:create_checkbox({
    title = "Randomize Accuracy",
    flag = "parry_random",

    callback = function(state)
        print("Randomize:", state)
    end,
})

AutoParry:create_mini_toggle({
    title = "Only When Target Is Near",
    flag = "parry_near",
    default = false,

    callback = function(state)
        print("Near Only:", state)
    end,
})

Main:create_module({
    title = "Kill Aura",
    description = "Module with settings",
    flag = "kill_aura",
    section = "right",
    setting = true,

    callback = function(state)
        print("Kill Aura:", state)
    end,
})

Main:create_module({
    title = "Auto Farm",
    description = "Module with notifications",
    flag = "auto_farm",
    section = "right",
    notification = true,

    callback = function(state)
        print("Auto Farm:", state)
    end,
})

Main:create_module({
    title = "Fullbright",
    description = "Standard module example",
    flag = "fullbright",
    icon = "sun",
    section = "left",

    callback = function(state)
        local Lighting = game:GetService("Lighting")
        Lighting.Brightness = state and 3 or 1
    end,
})

Main:create_module({
    title = "Example Module",
    description = "Basic toggle module",
    flag = "example_module",
    section = "right",

    callback = function(state)
        print("Example Module:", state)
    end,
})

-- Exp tab

local Exp = Window:create_tab("Exp", "sliders-horizontal")

-- Slider examples

local Sliders = Exp:create_module({
    title = "Sliders",
    description = "Standard and custom sliders",
    flag = "exp_sliders",
    section = "left",

    callback = function(state) end,
})

Sliders:create_slider({
    title = "Standard Slider",
    flag = "exp_slider",

    minimum_value = 0,
    maximum_value = 200,
    value = 50,

    round_number = true,

    callback = function(value)
        print("Slider:", value)
    end,
})

Sliders:create_slider({
    title = "Custom Color Slider",
    flag = "exp_slider_color",

    minimum_value = 0,
    maximum_value = 100,
    value = 30,

    round_number = true,

    left_color = Color3.fromRGB(255, 220, 80),
    max_color = Color3.fromRGB(255, 60, 60),

    callback = function(value)
        print("Custom Slider:", value)
    end,
})

Sliders:create_paragraph({
    title = "Slider Information",
    text = "Slider colors can be customized using left_color and max_color.",
})

-- Range slider examples

local RangeSliders = Exp:create_module({
    title = "Range Sliders",
    description = "Two-handle slider controls",
    flag = "exp_range_sliders",
    section = "right",

    callback = function(state) end,
})

RangeSliders:create_range_slider({
    title = "Standard Range",
    flag = "exp_range",

    minimum_value = 0,
    maximum_value = 100,
    min_value = 20,
    max_value = 80,

    round_number = true,

    callback = function(minValue, maxValue)
        print("Range:", minValue, maxValue)
    end,
})

RangeSliders:create_range_slider({
    title = "Custom Range",
    flag = "exp_range_custom",

    minimum_value = 0,
    maximum_value = 50,
    min_value = 5,
    max_value = 30,

    round_number = true,

    left_color = Color3.fromRGB(255, 255, 255),
    max_color = Color3.fromRGB(0, 0, 0),

    callback = function(minValue, maxValue)
        print("Custom Range:", minValue, maxValue)
    end,
})

-- Toggle and checkbox examples

local Toggles = Exp:create_module({
    title = "Toggles",
    description = "Checkbox and mini toggle examples",
    flag = "exp_toggles",
    section = "left",

    callback = function(state) end,
})

Toggles:create_checkbox({
    title = "Checkbox",
    flag = "exp_checkbox",

    callback = function(state)
        print("Checkbox:", state)
    end,
})

local miniToggle = Toggles:create_mini_toggle({
    title = "Mini Toggle",
    flag = "exp_mini_toggle",
    default = false,

    callback = function(state)
        print("Mini Toggle:", state)
    end,
})

Toggles:create_button({
    title = "Toggle Mini Toggle",

    callback = function()
        miniToggle:Toggle()
    end,
})

-- Dropdown examples

local Dropdowns = Exp:create_module({
    title = "Dropdowns",
    description = "Single and multiple selection",
    flag = "exp_dropdowns",
    section = "right",

    callback = function(state) end,
})

Dropdowns:create_dropdown({
    title = "Single Selection",
    flag = "exp_dropdown_single",

    options = {
        "TP",
        "Tween",
        "Walk",
    },

    maximum_options = 6,

    callback = function(option)
        print("Selected:", option)
    end,
})

Dropdowns:create_dropdown({
    title = "Multiple Selection",
    flag = "exp_dropdown_multi",

    options = {
        "Coin",
        "Gem",
        "Key",
        "Chest",
    },

    maximum_options = 6,
    multi_dropdown = true,

    callback = function(option)
        local selected = flags["exp_dropdown_multi"] or {}

        print("Last Selected:", option)
        print("All Selected:", table.concat(selected, ", "))
    end,
})

-- Player list

local PlayersModule = Exp:create_module({
    title = "Player List",
    description = "Select a player from the server",
    flag = "exp_players",
    section = "left",

    callback = function(state) end,
})

PlayersModule:create_playerlist({
    title = "Target Player",
    flag = "exp_target_player",

    callback = function(name)
        print("Target Player:", name)
    end,
})

-- Text input examples

local Inputs = Exp:create_module({
    title = "Text Inputs",
    description = "Textbox and text examples",
    flag = "exp_inputs",
    section = "right",

    callback = function(state) end,
})

Inputs:create_textbox({
    title = "Textbox",
    placeholder = "Enter text...",
    flag = "exp_textbox",

    callback = function(value)
        print("Textbox:", value)
    end,
})

local infoText = Inputs:create_text({
    text = "Status: Ready",
    CustomYSize = 30,
})

Inputs:create_button({
    title = "Update Text",

    callback = function()
        infoText:Set({
            text = "Status: Updated",
        })
    end,
})

Inputs:create_paragraph({
    title = "Paragraph",
    text = "This is an example paragraph. It can be used to display information or instructions.",
})

Inputs:create_divider({
    showtopic = true,
    title = "Text Components",
})

-- Button and feature examples

local Buttons = Exp:create_module({
    title = "Buttons and Features",
    description = "Buttons, keybinds and tooltips",
    flag = "exp_buttons",
    section = "left",

    callback = function(state) end,
})

local exampleButton = Buttons:create_button({
    title = "Example Button",

    callback = function()
        print("Button Clicked")
        Library.Notify.Info("Button", "You clicked the example button.", 2)
    end,
})

Buttons:create_tooltip(
    exampleButton,
    "Click to execute this example action."
)

Buttons:create_feature({
    title = "Feature Example",
    flag = "exp_feature",
    default = "G",

    callback = function(checked)
        print("Feature Checked:", checked)
    end,

    button_callback = function()
        print("Feature Key Pressed")
    end,
})

Buttons:create_section({
    title = "Additional Controls",
})

Buttons:create_button({
    title = "Second Button",

    callback = function()
        Library.Notify.Success("Success", "Second button clicked.", 2)
    end,
})

-- Color picker examples

local ColorPickers = Exp:create_module({
    title = "Color Pickers",
    description = "Custom color selection",
    flag = "exp_color_pickers",
    section = "right",

    callback = function(state) end,
})

local expColor = ColorPickers:create_colorpicker({
    title = "Default Color",
    flag = "exp_color_default",

    default = Color3.fromRGB(205, 205, 215),
    notify = false,

    callback = function(color)
        print("Selected Color:", color)
    end,
})

ColorPickers:create_colorpicker({
    title = "Red Color",
    flag = "exp_color_red",

    default = Color3.fromRGB(255, 70, 70),
    notify = false,

    callback = function(color)
        print("Red Picker:", color)
    end,
})

ColorPickers:create_button({
    title = "Reset First Color",

    callback = function()
        expColor:Set(Color3.fromRGB(205, 205, 215))
    end,
})

-- Themes tab

local Themes = Window:create_tab("Themes", "palette")

local ThemeMod = Themes:create_module({
    title = "Theme Selection",
    description = "Change the UI theme",
    flag = "theme_selection",
    section = "left",

    callback = function(state) end,
})

ThemeMod:create_dropdown({
    title = "Available Themes",
    flag = "theme_choice",

    options = Library.GetThemes(),
    maximum_options = 6,

    callback = function(option)
        if ready then
            Library.SetTheme(option)
        end
    end,
})

ThemeMod:create_button({
    title = "Restore PureBlack",

    callback = function()
        Library.SetTheme("PureBlack")
    end,
})

local ThemeColors = Themes:create_module({
    title = "Theme Colors",
    description = "Customize individual UI colors",
    flag = "theme_colors",
    section = "right",

    callback = function(state) end,
})

local initialColors = Library.GetThemeColors()

local function createThemeColorPicker(title, flag, colorKey)
    local defaultColor = initialColors[colorKey]

    if typeof(defaultColor) ~= "Color3" then
        warn("[Sora x Hikaru] Missing theme color:", colorKey)
        return
    end

    return ThemeColors:create_colorpicker({
        title = title,
        flag = flag,

        default = defaultColor,
        notify = false,

        callback = function(color)
            if ready then
                Library.SetThemeColor(colorKey, color)
            end
        end,
    })
end

createThemeColorPicker("Background", "theme_background", "Background")
createThemeColorPicker("Secondary Background", "theme_background_secondary", "BackgroundSecondary")
createThemeColorPicker("Module Background", "theme_module_background", "ModuleBackground")
createThemeColorPicker("Primary Text", "theme_text_primary", "TextPrimary")
createThemeColorPicker("Secondary Text", "theme_text_secondary", "TextSecondary")
createThemeColorPicker("Accent", "theme_accent", "Accent")
createThemeColorPicker("Accent Hover", "theme_accent_hover", "AccentHover")
createThemeColorPicker("Border", "theme_stroke", "Stroke")
createThemeColorPicker("Divider", "theme_divider", "Divider")
createThemeColorPicker("Toggle Off", "theme_toggle_off", "ToggleOff")
createThemeColorPicker("Card Background", "theme_card", "Card")

-- Appearance settings

local Appearance = Themes:create_module({
    title = "Appearance",
    description = "Transparency and background",
    flag = "theme_appearance",
    section = "left",

    callback = function(state) end,
})

Appearance:create_slider({
    title = "Window Transparency",
    flag = "theme_transparency",

    minimum_value = 0,
    maximum_value = 90,
    value = 15,

    round_number = true,

    left_color = Color3.fromRGB(255, 255, 255),
    max_color = Color3.fromRGB(0, 0, 0),

    callback = function(value)
        if ready then
            Library.SetTransparency(value / 100)
        end
    end,
})

Appearance:create_button({
    title = "Set Image Background",

    callback = function()
        Window:SetImageBackground(
            "rbxassetid://76051962811019",
            "Crop",
            0.7
        )
    end,
})

-- Settings tab

local Settings = Window:create_tab("Settings", "settings")

-- Notification examples

local Notifications = Settings:create_module({
    title = "Notifications",
    description = "Test notification types and styles",
    flag = "settings_notifications",
    section = "left",

    callback = function(state) end,
})

Notifications:create_button({
    title = "Info Notification",

    callback = function()
        Library.Notify.Info(
            "Information",
            "This is an information notification.",
            3
        )
    end,
})

Notifications:create_button({
    title = "Success Notification",

    callback = function()
        Library.Notify.Success(
            "Success",
            "Your action was completed.",
            3
        )
    end,
})

Notifications:create_button({
    title = "Warning Notification",

    callback = function()
        Library.Notify.Warn(
            "Warning",
            "Please check this message.",
            3
        )
    end,
})

Notifications:create_button({
    title = "Error Notification",

    callback = function()
        Library.Notify.Error(
            "Error",
            "Something went wrong.",
            3
        )
    end,
})

Notifications:create_dropdown({
    title = "Notification Style",
    flag = "settings_notify_style",

    options = {
        "new",
        "old",
        "dynamic",
    },

    maximum_options = 3,

    callback = function(mode)
        if ready then
            Library.SetNotifyMode(mode)
        end
    end,
})

Notifications:create_button({
    title = "Dynamic Island Live Activity",

    callback = function()
        if Library.GetNotifyMode() ~= "dynamic" then
            Library.Notify.Info(
                "Dynamic Island",
                "Select the dynamic notification style first.",
                3
            )
            return
        end

        local island = Library.GetDynamicIsland()

        if island then
            island:LiveActivity(
                "Downloading",
                "Fetching data...",
                5,
                "download"
            )
        end
    end,
})

Notifications:create_button({
    title = "Notification With Icon",

    callback = function()
        Library.Notify.Send({
            title = "Sora x Hikaru",
            text = "This notification uses a Lucide icon.",
            duration = 4,
            type = "info",
            icon = "rocket",
        })
    end,
})

-- Dialog examples

local Dialogs = Settings:create_module({
    title = "Dialogs",
    description = "Confirmation dialog examples",
    flag = "settings_dialogs",
    section = "right",

    callback = function(state) end,
})

Dialogs:create_button({
    title = "Open Confirmation Dialog",

    callback = function()
        Window:Dialog({
            Icon = "triangle-alert",
            IconThemed = true,

            Title = "Reset Configuration?",
            Content = "This action cannot be undone.",

            Dismissible = true,

            Buttons = {
                {
                    Title = "Cancel",
                    Variant = "Secondary",
                },

                {
                    Title = "Reset",
                    Variant = "Destructive",
                    Icon = "trash-2",

                    Callback = function()
                        Library.Notify.Success(
                            "Configuration",
                            "Reset confirmed.",
                            2
                        )
                    end,
                },
            },
        })
    end,
})

-- Progress bar

local Loading = Settings:ProgressBar({
    Title = "Loading",
    Desc = "Loading data...",
    Icon = "loader",

    Value = {
        Min = 0,
        Max = 100,
        Default = 0,
    },

    Visible = false,
    AutoHide = true,

    OnComplete = function()
        Library.Notify.Success(
            "Completed",
            "Loading finished.",
            2
        )
    end,
})

local Progress = Settings:create_module({
    title = "Progress Bar",
    description = "Progress bar controls",
    flag = "settings_progress",
    section = "left",

    callback = function(state) end,
})

Progress:create_button({
    title = "Run Progress Bar",

    callback = function()
        Loading:Reset()
        Loading:Run(5)
    end,
})

-- General settings

local General = Settings:create_module({
    title = "General",
    description = "Watermark and search settings",
    flag = "settings_general",
    section = "right",

    callback = function(state) end,
})

General:create_checkbox({
    title = "Show Watermark",
    flag = "settings_watermark",

    callback = function(state)
        Library.SetWatermark(state)
    end,
})

General:create_button({
    title = "Search For Speed",

    callback = function()
        Window:Search("speed")
    end,
})

General:create_paragraph({
    title = "Keyboard Shortcuts",
    text = "Insert: Show or hide the UI. Ctrl + F: Open search.",
})

-- Configuration settings

local Config = Settings:create_module({
    title = "Configuration",
    description = "Save, load, export and reset settings",
    flag = "settings_config",
    section = "left",

    callback = function(state) end,
})

Config:create_button({
    title = "Save Configuration",

    callback = function()
        Library.SaveConfig()
    end,
})

Config:create_button({
    title = "Load Configuration",

    callback = function()
        Library.LoadConfig()
    end,
})

Config:create_button({
    title = "Export Configuration",

    callback = function()
        Library.ExportConfig()
    end,
})

Config:create_button({
    title = "Reset Configuration",

    callback = function()
        Library.ResetConfig()
    end,
})

-- Load UI

Window:load()

Main:Select()

ready = true

Library.Notify.Success(
    "Sora x Hikaru",
    "PureBlack loaded successfully. Press Insert to hide or show the UI.",
    4
)
