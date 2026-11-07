
getgenv().GG = {
    Theme = "Light",

    UIName     = "Sora x Hikaru",
    FolderName = "SoraHikaru",
    

    Transparency = 0.25,
    Watermark = false,

    TextColor = Color3.fromRGB(30, 30, 40),
    AccentColor = Color3.fromRGB(99, 102, 241),

    GalacticText = true,
    GalacticColor1 = Color3.fromRGB(99, 102, 241),
    GalacticColor2 = Color3.fromRGB(236, 72, 153),
    GalacticSpeed = 1.5,
}

--  load UI 
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/Lib/UI.lua"))()
local main = Library.new()

-- create tabs 
local combat_tab  = main:create_tab("Combat",  "rbxassetid://76499042599127")
local utility_tab = main:create_tab("Utility", "rbxassetid://126017907477623")
local config_tab  = main:create_tab("Config",  "rbxassetid://76499042599127")

-- combat
local Tab1 = combat_tab:create_module({
    title = "Toggle left",
    flag = "Toggle1",
    description = "this is desc",
    section = "left",
    callback = function(value)
        print("enabled:", value)
        Library.SendNotification({
            title = "Aimbot",
            text = value and "Enabled!" or "Disabled!",
            duration = 3,
            type = value and "success" or "info"
        })
    end
})

Tab1:create_dropdown({
    title = "dropdown left",
    flag = "dropdownleft",
    options = {"1", "2", "3"},
    multi_dropdown = false,
    maximum_options = 3,
    callback = function(value)
        print("Targeting:", value)
    end
})

Tab1:create_slider({
    title = "slider Left",
    flag = "sliderleft",
    maximum_value = 100,
    minimum_value = 10,
    value = 50,
    round_number = true,
    callback = function(value)
        print("Sensitivity:", value)
    end
})

Tab1:create_checkbox({
    title = "check box",
    flag = "checkbox1",
    callback = function(value)
        print("Checkbox:", value)
    end
})

-- Range Slider (min - max)
Tab1:create_range_slider({
    title = "Range (Min-Max)",
    flag = "range_combat",
    minimum_value = 0,
    maximum_value = 100,
    min_value = 20,
    max_value = 80,
    round_number = true,
    callback = function(min, max)
        print("Range:", min, "-", max)
    end
})

local Right = combat_tab:create_module({
    title = "Toggle Right",
    flag = "Toggle5",
    description = "this is desc",
    section = "right",
    callback = function(value)
        print("enabled:", value)
        Library.SendNotification({
            title = "Right",
            text = value and "Enabled!" or "Disabled!",
            duration = 3
        })
    end
})

Right:create_button({
    title = "Test Button",
    callback = function()
        Library.Notify.Success("Button", "Bạn vừa bấm nút!", 3)
    end
})

Right:create_colorpicker({
    title = "Aim Color",
    flag = "aim_color",
    default = Color3.fromRGB(255, 100, 100),
    callback = function(color)
        print("Aim Color:", color)
    end
})

-- utility
local ToggleLeft = utility_tab:create_module({
    title = "Toggle",
    flag = "util_toggle",
    description = "just toggle",
    section = "left",
    callback = function(value)
        print("Speed Hack:", value)
    end
})

local Toggleright = utility_tab:create_module({
    title = "Toggle and input",
    flag = "util_input_mod",
    description = "description hello",
    section = "right",
    callback = function(value)
        print("Speed Hack:", value)
    end
})

Toggleright:create_paragraph({
    title = "Info",
    text = "hello this is info"
})

Toggleright:create_textbox({
    title = "input",
    placeholder = "Enter...",
    flag = "input_text",
    callback = function(text)
        print("set to:", text)
    end
})

Toggleright:create_slider({
    title = "slider Value",
    flag = "slider_value",
    minimum_value = 1,
    maximum_value = 200,
    value = 50,
    round_number = true,
    callback = function(v)
        print("slider:", v)
    end
})

Toggleright:create_colorpicker({
    title = " Color",
    flag = "picker_color",
    default = Color3.fromRGB(255, 100, 100),
    callback = function(color)
        print("picker Color:", color)
    end
})

-- config tab
local ConfigMod = config_tab:create_module({
    title = "Config Manager",
    flag = "config_mod",
    description = "Save / Load / Reset config",
    section = "left",
    callback = function() end
})

ConfigMod:create_button({
    title = "Save Config",
    callback = function()
        Library.SaveConfig()
    end
})

ConfigMod:create_button({
    title = "Load Config",
    callback = function()
        Library.LoadConfig()
    end
})

ConfigMod:create_button({
    title = "Reset Config",
    callback = function()
        Library.ResetConfig()
    end
})

ConfigMod:create_paragraph({
    title = "info",
    text = "hello this is config"
})

-- loader ui
main:load()
