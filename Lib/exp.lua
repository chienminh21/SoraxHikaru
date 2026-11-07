-- Custom settings (set BEFORE loading the UI)
getgenv().GG = {
    Theme = "Dark",
    UIName = "Sora x Hikaru",
    FolderName = "SoraHikaru",
    GuiName = "SoraHikaru",
    Transparency = 0.15,
    Watermark = true,
    ToggleKey = Enum.KeyCode.Insert,
}

-- Load UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/Lib/UI.lua"))()
local main = Library.new()

-- Tabs
local tab1 = main:create_tab("Main", "rbxassetid://76499042599127")
local tab2 = main:create_tab("Settings", "rbxassetid://126017907477623")

-- MAIN TAB
-- section = "left"  -> left column
-- section = "right" -> right column

-- LEFT
local ToggleLeft = tab1:create_module({
    title = "Toggle Left",
    flag = "toggle_left",
    description = "Left column module",
    section = "left",
    callback = function(value)
        Library.SendNotification({
            title = "Toggle Left",
            text = value and "Enabled" or "Disabled",
            duration = 3
        })
    end
})

ToggleLeft:create_slider({
    title = "Slider Left",
    flag = "slider_left",
    minimum_value = 0,
    maximum_value = 100,
    value = 50,
    round_number = true,
    callback = function(value)
        print("Slider Left:", value)
    end
})

ToggleLeft:create_dropdown({
    title = "Dropdown Left",
    flag = "dropdown_left",
    options = {"Option 1", "Option 2", "Option 3"},
    multi_dropdown = false,
    maximum_options = 5,
    callback = function(value)
        print("Dropdown Left:", value)
    end
})

ToggleLeft:create_checkbox({
    title = "Checkbox Left",
    flag = "checkbox_left",
    callback = function(value)
        print("Checkbox Left:", value)
    end
})

-- RIGHT
local ToggleRight = tab1:create_module({
    title = "Toggle Right",
    flag = "toggle_right",
    description = "Right column module",
    section = "right",
    callback = function(value)
        Library.SendNotification({
            title = "Toggle Right",
            text = value and "Enabled" or "Disabled",
            duration = 3
        })
    end
})

ToggleRight:create_range_slider({
    title = "Range Slider",
    flag = "range_slider",
    minimum_value = 0,
    maximum_value = 100,
    min_value = 20,
    max_value = 80,
    round_number = true,
    callback = function(min, max)
        print("Range:", min, max)
    end
})

ToggleRight:create_textbox({
    title = "Textbox",
    placeholder = "Enter text...",
    flag = "textbox_right",
    callback = function(text)
        print("Textbox:", text)
    end
})

ToggleRight:create_colorpicker({
    title = "Color Picker",
    flag = "color_right",
    default = Color3.fromRGB(99, 102, 241),
    callback = function(color)
        print("Color:", color)
    end
})

ToggleRight:create_button({
    title = "Button",
    callback = function()
        Library.Notify.Success("Button", "Clicked", 2)
    end
})

-- SETTINGS TAB

-- LEFT
local SettingsLeft = tab2:create_module({
    title = "UI Settings",
    flag = "ui_settings",
    description = "Left column",
    section = "left",
    callback = function() end
})

SettingsLeft:create_dropdown({
    title = "Theme",
    flag = "theme_mode",
    options = {"Dark", "Light"},
    multi_dropdown = false,
    maximum_options = 2,
    callback = function(value)
        if Library.SetTheme then Library.SetTheme(value) else print("Theme:", value) end
    end
})

SettingsLeft:create_slider({
    title = "UI Transparency",
    flag = "ui_transparency",
    minimum_value = 0,
    maximum_value = 0.9,
    value = 0.15,
    round_number = false,
    callback = function(value)
        if Library.SetTransparency then Library.SetTransparency(value) else print("Transparency:", value) end
    end
})

SettingsLeft:create_paragraph({
    title = "Info",
    text = "0 = solid, 0.9 = very clear"
})

-- RIGHT
local ConfigRight = tab2:create_module({
    title = "Config",
    flag = "config_mod",
    description = "Right column",
    section = "right",
    callback = function() end
})

ConfigRight:create_button({
    title = "Save Config",
    callback = function()
        Library.SaveConfig()
    end
})

ConfigRight:create_button({
    title = "Load Config",
    callback = function()
        Library.LoadConfig()
    end
})

ConfigRight:create_button({
    title = "Reset Config",
    callback = function()
        Library.ResetConfig()
    end
})

ConfigRight:create_button({
    title = "Export Config",
    callback = function()
        Library.ExportConfig()
    end
})

-- Load UI
main:load()
