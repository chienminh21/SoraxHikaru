


getgenv().GG = {
    UIName = "Sora x Hikaru",
    Version = "v1.0",

    Theme = "DarkBlackPremium",

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
        DarkBlackPremium = {
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

local BASE = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/"

local Library = loadstring(game:HttpGet(BASE .. "Lib/UI.lua"))()
local Window = Library.new()

local flags = Library._config._flags
local ready = false

local Main = Window:create_tab("Main", "home")
local Controls = Window:create_tab("Controls", "sliders-horizontal")
local Settings = Window:create_tab("Settings", "settings")

local Intro = Main:create_module({
    title = "Module example",
    description = "Middle-click header to bind a key",
    flag = "module_example",
    section = "left",
    setting = true,
    notification = true,

    callback = function(state)
        print("Module:", state)
    end,
})

Intro:create_paragraph({
    title = "About modules",
    text = "A module is a toggle block. Controls below only show meaning when the module is on. Use unique flags for every saved control.",
})

local SliderMod = Controls:create_module({
    title = "Slider",
    description = "One value between min and max",
    flag = "mod_slider",
    section = "left",

    callback = function(state) end,
})

SliderMod:create_slider({
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

SliderMod:create_paragraph({
    title = "Slider color",
    text = "Customize the slider fill using left_color and max_color.",
})

local RangeMod = Controls:create_module({
    title = "Range slider",
    description = "Two handles: minimum and maximum",
    flag = "mod_range",
    section = "right",

    callback = function(state) end,
})

RangeMod:create_range_slider({
    title = "range slider",
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


RangeMod:create_paragraph({
    title = "Range slider color",
    text = "Customize the selected range using left_color and max_color.",
})

local DropSingle = Controls:create_module({
    title = "Dropdown (single)",
    description = "Select one option only",
    flag = "mod_drop_single",
    section = "left",

    callback = function(state) end,
})

DropSingle:create_dropdown({
    title = "Mode",
    flag = "mode_single",

    options = {
        "TP",
        "Tween",
        "Walk",
    },

    maximum_options = 6,

    callback = function(option)
        print("Single selected:", option)
    end,
})

DropSingle:create_paragraph({
    title = "How single works",
    text = "Select one item. The callback receives one string, and flags[flag] stores that string.",
})

local DropMulti = Controls:create_module({
    title = "Dropdown (multi)",
    description = "Select multiple options",
    flag = "mod_drop_multi",
    section = "right",

    callback = function(state) end,
})

DropMulti:create_dropdown({
    title = "Items",
    flag = "mode_multi",

    options = {
        "Coin",
        "Gem",
        "Key",
        "Chest",
    },

    maximum_options = 6,
    multi_dropdown = true,

    callback = function(option)
        local selected = flags["mode_multi"] or {}

        print("Last click:", option)
        print("All selected:", table.concat(selected, ", "))
    end,
})

DropMulti:create_paragraph({
    title = "How multi works",
    text = "Select multiple items. The callback receives the last clicked option. Read flags[flag] for the full selected list.",
})

local PlayerMod = Controls:create_module({
    title = "Player list",
    description = "Dropdown of current players",
    flag = "mod_players",
    section = "left",

    callback = function(state) end,
})

PlayerMod:create_playerlist({
    title = "Target",
    flag = "target_player",

    callback = function(name)
        print("Target:", name)
    end,
})

local CheckMod = Controls:create_module({
    title = "Checkbox",
    description = "On/off inside a module",
    flag = "mod_check",
    section = "right",

    callback = function(state) end,
})

CheckMod:create_checkbox({
    title = "Auto collect",
    flag = "auto_collect",

    callback = function(state)
        print("Auto collect:", state)
    end,
})

local TextMod = Controls:create_module({
    title = "Textbox",
    description = "Free text input",
    flag = "mod_text",
    section = "left",

    callback = function(state) end,
})

TextMod:create_textbox({
    title = "Profile",
    placeholder = "Type here...",
    flag = "profile_name",

    callback = function(text)
        print("Profile:", text)
    end,
})

local ButtonMod = Controls:create_module({
    title = "Button",
    description = "One-shot action",
    flag = "mod_button",
    section = "right",

    callback = function(state) end,
})

ButtonMod:create_button({
    title = "Run once",

    callback = function()
        Library.Notify.Info("Button", "Clicked", 2)
    end,
})

local FeatureMod = Controls:create_module({
    title = "Feature",
    description = "Checkbox row with a keybind",
    flag = "mod_feature",
    section = "left",

    callback = function(state) end,
})

FeatureMod:create_feature({
    title = "Quick action",
    flag = "quick_action",
    default = "G",

    callback = function(checked)
        print("Checked:", checked)
    end,

    button_callback = function()
        print("Key pressed")
    end,
})

local ColorMod = Controls:create_module({
    title = "Color picker",
    description = "Click row to expand picker",
    flag = "mod_color",
    section = "right",

    callback = function(state) end,
})

local colorRef = ColorMod:create_colorpicker({
    title = "ESP color",
    flag = "esp_color",

    default = Color3.fromRGB(205, 205, 215),
    notify = false,

    callback = function(color)
        print("ESP Color:", color)
    end,
})

local TextUiMod = Controls:create_module({
    title = "Text helpers",
    description = "Divider, paragraph, updatable label",
    flag = "mod_text_ui",
    section = "left",

    callback = function(state) end,
})

TextUiMod:create_divider({
    showtopic = true,
    title = "Section label",
})

TextUiMod:create_paragraph({
    title = "Paragraph",
    text = "Long help text wraps inside the module.",
    customScale = 70,
})

local status = TextUiMod:create_text({
    text = "Status: idle",
    CustomYSize = 24,
})

status:Set({
    text = "Status: ready",
})

local NotifyMod = Settings:create_module({
    title = "Notifications",
    description = "Info, success, warn, error",
    flag = "mod_notify",
    section = "left",

    callback = function(state) end,
})

NotifyMod:create_button({
    title = "Info",

    callback = function()
        Library.Notify.Info("Info", "Something happened", 3)
    end,
})

NotifyMod:create_button({
    title = "Success",

    callback = function()
        Library.Notify.Success("Success", "Done", 3)
    end,
})

NotifyMod:create_button({
    title = "Warn",

    callback = function()
        Library.Notify.Warn("Warning", "Be careful", 3)
    end,
})

NotifyMod:create_button({
    title = "Error",

    callback = function()
        Library.Notify.Error("Error", "Failed", 3)
    end,
})

local ThemeMod = Settings:create_module({
    title = "Theme",
    description = "Theme and transparency",
    flag = "mod_theme",
    section = "right",

    callback = function(state) end,
})

ThemeMod:create_dropdown({
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

ThemeMod:create_slider({
    title = "Transparency",
    flag = "ui_transparency",

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

local ThemeColorsMod = Settings:create_module({
    title = "Theme Colors",
    description = "Customize your Silver Black theme",
    flag = "mod_theme_colors",
    section = "left",

    callback = function(state) end,
})

local initialColors = Library.GetThemeColors()

local function createThemeColorPicker(title, flag, colorKey)
    local defaultColor = initialColors[colorKey]

    if typeof(defaultColor) ~= "Color3" then
        warn("[Sora x Hikaru] Missing theme color:", colorKey)
        return
    end

    return ThemeColorsMod:create_colorpicker({
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

createThemeColorPicker(
    "Background",
    "theme_background",
    "Background"
)

createThemeColorPicker(
    "Secondary Background",
    "theme_background_secondary",
    "BackgroundSecondary"
)

createThemeColorPicker(
    "Module Background",
    "theme_module_background",
    "ModuleBackground"
)

createThemeColorPicker(
    "Primary Text",
    "theme_text_primary",
    "TextPrimary"
)

createThemeColorPicker(
    "Secondary Text",
    "theme_text_secondary",
    "TextSecondary"
)

createThemeColorPicker(
    "Slider / Range Slider Accent",
    "theme_slider_accent",
    "Accent"
)

createThemeColorPicker(
    "Accent Hover",
    "theme_accent_hover",
    "AccentHover"
)

createThemeColorPicker(
    "Border",
    "theme_stroke",
    "Stroke"
)

createThemeColorPicker(
    "Divider",
    "theme_divider",
    "Divider"
)

createThemeColorPicker(
    "Toggle Off",
    "theme_toggle_off",
    "ToggleOff"
)

createThemeColorPicker(
    "Card Background",
    "theme_card",
    "Card"
)

local ConfigMod = Settings:create_module({
    title = "Config",
    description = "Save / export / reset",
    flag = "mod_config",
    section = "right",

    callback = function(state) end,
})

ConfigMod:create_button({
    title = "Save",

    callback = function()
        Library.SaveConfig()
    end,
})

ConfigMod:create_button({
    title = "Export",

    callback = function()
        Library.ExportConfig()
    end,
})

ConfigMod:create_button({
    title = "Reset",

    callback = function()
        Library.ResetConfig()
    end,
})

Window:load()

Main:Select()

ready = true

Library.Notify.Success(
    "Sora x Hikaru",
    "Loaded. Press Insert to hide / show the UI.",
    4
)
