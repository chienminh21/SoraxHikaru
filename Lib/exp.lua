local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/Lib/UI.lua"))()
local main = Library.new()

-- Tabs
local combat_tab = main:create_tab("Combat", "rbxassetid://76499042599127")
local utility_tab = main:create_tab("Utility", "rbxassetid://126017907477623")
-- Đổi theme (trước khi tạo UI)
getgenv().GG.Theme = "Light"  -- hoặc "Dark"
-- Combat Module
local aimbot = combat_tab:create_module({
  title = "Aimbot",
  flag = "Aimbot",
  description = "Locks onto enemies",
  section = "left",
  callback = function(value)
    print("Aimbot enabled:", value)
    Library.SendNotification({title = "Aimbot", text = value and "Enabled!" or "Disabled!", duration = 3})
  end
})

aimbot:create_dropdown({
  title = "Target Part",
  flag = "Target_Part",
  options = {"Head", "Torso", "Random"},
  multi_dropdown = false,
  maximum_options = 1,
  callback = function(value) print("Targeting:", value) end
})

aimbot:create_slider({
  title = "Aimbot Sensitivity",
  flag = "Aimbot_Sensitivity",
  maximum_value = 100,
  minimum_value = 10,
  value = 50,
  round_number = true,
  callback = function(value) print("Sensitivity:", value) end
})

aimbot:create_checkbox({
  title = "Silent Aim",
  flag = "Silent_Aim",
  callback = function(value) print("Silent Aim:", value) end
})

-- Utility Module
local speedhack = utility_tab:create_module({
  title = "Speed Hack",
  flag = "Speed_Hack",
  description = "Increases player speed",
  section = "right",
  callback = function(value) print("Speed Hack:", value) end
})

speedhack:create_paragraph({
  title = "Info",
  text = "Use responsibly to avoid detection."
})

speedhack:create_textbox({
  title = "Speed Value",
  placeholder = "Enter speed...",
  flag = "Speed_Value",
  callback = function(text) print("Speed set to:", text) end
})

main:load()
