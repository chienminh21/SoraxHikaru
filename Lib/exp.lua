local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/Lib/UI.lua"))()
local main = Library.new()

-- Tabs
local combat_tab = main:create_tab("Combat", "rbxassetid://76499042599127")
local utility_tab = main:create_tab("Utility", "rbxassetid://126017907477623")
-- Đổi theme (trước khi tạo UI)
getgenv().GG = {
    Theme = "Light",

    -- Tên & Folder
    UIName     = "Sora x Hikaru",   -- chữ hiện trên UI
    FolderName = "SoraHikaru",      -- folder lưu config
    

    -- Trong suốt
    Transparency = 0.25,

    -- Màu
    TextColor = Color3.fromRGB(30, 30, 40),
    AccentColor = Color3.fromRGB(99, 102, 241),

    -- Galactic
    GalacticText = true,
    GalacticColor1 = Color3.fromRGB(99, 102, 241),
    GalacticColor2 = Color3.fromRGB(236, 72, 153),
    GalacticSpeed = 1.5,
}
-- Combat Module
local aimbot = combat_tab:create_module({
  title = "Toggle left",
  flag = "Toggle1",
  description = "this is desc",
  section = "left",
  callback = function(value)
    print(" enabled:", value)
    Library.SendNotification({title = "Aimbot", text = value and "Enabled!" or "Disabled!", duration = 3})
  end
})

aimbot:create_dropdown({
  title = "dropdown left",
  flag = "dropdownleft",
  options = {"1", "2", "3"},
  multi_dropdown = false,
  maximum_options = 1,
  callback = function(value) print("Targeting:", value) end
})

aimbot:create_slider({
  title = "slider Left",
  flag = "sliderleft",
  maximum_value = 100,
  minimum_value = 10,
  value = 50,
  round_number = true,
  callback = function(value) print("Sensitivity:", value) end
})

aimbot:create_checkbox({
  title = "check box",
  flag = "checkbox",
  callback = function(value) print("Silent Aim:", value) end
})
local Right = combat_tab:create_module({
  title = "Toggle Right",
  flag = "Toggle5",
  description = "this is desc",
  section = "right",
  callback = function(value)
    print(" enabled:", value)
    Library.SendNotification({title = "on", text = value and "Enabled!" or "Disabled!", duration = 3})
  end
})
-- Utility Module
local ToggleLeft = utility_tab:create_module({
  title = "Toggle",
  flag = "Input",
  description = "just Toggle no slider",
  section = "left",
  callback = function(value) print("Speed Hack:", value) end
})
local Toggleright = utility_tab:create_module({
  title = "Toggle and input",
  flag = "Input",
  description = "Increases player speed",
  section = "right",
  callback = function(value) print("Speed Hack:", value) end
})

Toggleright:create_paragraph({
  title = "Info",
  text = "hello this is info"
})

Toggleright:create_textbox({
  title = "input",
  placeholder = "Enter...",
  flag = "input",
  callback = function(text) print(" set to:", text) end
})

main:load()
