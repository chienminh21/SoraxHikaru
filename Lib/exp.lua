

getgenv().GG = {
    UIName = "Sora x Hikaru",
    Version = "v1.0",
    Theme = "Light",
    Transparency = 0.15,
    ToggleKey = Enum.KeyCode.Insert,
    NotifyMode = "old",
    Watermark = true,
    ImageBackground = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRUC6mkL_t6tMIErXnaEfZSHUn4A4dl0bu7JBVjCVhOXX6v9ERkdV3ViUXp&s=10",
    ImageBackgroundStyle = "Crop",
    ImageBackgroundTransparency = 0.7,
}

--[[
    2. Load the library and create the window
]]

local BASE = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/"
local Library = loadstring(game:HttpGet(BASE .. "Lib/UI.lua"))()

local Window = Library.new()

--[[
    Callbacks run once while the UI is being built.
    Use ready to prevent side effects during initialization.
]]

local ready = false

--[[
    3. Tabs

    Icon supports Lucide names, Roblox asset IDs and image URLs.
]]

local Main = Window:create_tab("Main", "home")
local Visuals = Window:create_tab("Visuals", "eye")
local Settings = Window:create_tab("Settings", "settings")

--[[
    4. Main tab

    Left column: a module with different controls.
]]

local Farm = Main:create_module({
    title = "Auto Farm",
    description = "Middle-click the header to set a key",
    flag = "auto_farm",
    section = "left",
    callback = function(state)
        print("Auto Farm:", state)
    end,
})

Farm:create_slider({
    title = "Speed",
    flag = "farm_speed",
    minimum_value = 1,
    maximum_value = 100,
    value = 50,
    round_number = true,
    callback = function(value)
        print("Speed:", value)
    end,
})

Farm:create_range_slider({
    title = "Delay (seconds)",
    flag = "farm_delay",
    minimum_value = 0,
    maximum_value = 10,
    min_value = 1,
    max_value = 3,
    callback = function(minValue, maxValue)
        print("Delay:", minValue, maxValue)
    end,
})

Farm:create_dropdown({
    title = "Target",
    flag = "farm_target",
    options = { "Nearest", "Lowest HP", "Boss" },
    maximum_options = 6,
    callback = function(option)
        print("Target:", option)
    end,
})

Farm:create_dropdown({
    title = "Items",
    flag = "farm_items",
    options = { "Coin", "Gem", "Key" },
    maximum_options = 6,
    multi_dropdown = true,
    callback = function(option)
        local selectedItems = Library._config._flags.farm_items or {}
        print("Selected:", table.concat(selectedItems, ", "))
    end,
})

Farm:create_checkbox({
    title = "Auto collect",
    flag = "farm_collect",
    callback = function(state)
        print("Auto collect:", state)
    end,
})

Farm:create_textbox({
    title = "Profile name",
    placeholder = "Type here...",
    flag = "farm_profile",
    callback = function(text)
        print("Profile:", text)
    end,
})

Farm:create_divider({
    showtopic = true,
    title = "Actions"
})

Farm:create_button({
    title = "Teleport to spawn",
    callback = function()
        Library.Notify.Info("Teleport", "Teleported to spawn", 3)
    end,
})

--[[
    Right column: notifications, dialog and progress bar.
]]

local Demo = Main:create_module({
    title = "Demo",
    description = "Notifications, dialog, progress",
    flag = "demo",
    section = "right",
    callback = function() end,
})

Demo:create_button({
    title = "Info",
    callback = function()
        Library.Notify.Info("Info", "Something happened", 3)
    end,
})

Demo:create_button({
    title = "Success",
    callback = function()
        Library.Notify.Success("Success", "It worked!", 3)
    end,
})

Demo:create_button({
    title = "Warning",
    callback = function()
        Library.Notify.Warn("Warning", "Be careful", 3)
    end,
})

Demo:create_button({
    title = "Error",
    callback = function()
        Library.Notify.Error("Error", "Something broke", 3)
    end,
})

Demo:create_button({
    title = "Notification with icon",
    callback = function()
        Library.Notify.Send({
            title = "Coins",
            text = "+100 coins",
            type = "success",
            icon = "coins",
            duration = 3
        })
    end,
})

Demo:create_button({
    title = "Open dialog",
    callback = function()
        Window:Dialog({
            Icon = "alert-circle",
            IconThemed = true,
            Title = "Confirm Delete",
            Content = "This action cannot be undone.",
            Buttons = {
                {
                    Title = "Delete",
                    Icon = "trash-2",
                    Variant = "Destructive",
                    Callback = function()
                        Library.Notify.Success("Deleted", "Item deleted", 2)
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
    end,
})

--[[
    Progress bar

    Appears in the top-right corner of the window.
]]

local Progress = Main:ProgressBar({
    Title = "Download",
    Desc = "Downloading files...",
    Icon = "download",
    Value = {
        Min = 0,
        Max = 100,
        Default = 0
    },
    Visible = false,
    AutoHide = true,
    OnComplete = function()
        Library.Notify.Success("Download", "Finished!", 3)
    end,
})

Demo:create_button({
    title = "Run progress (5s)",
    callback = function()
        Progress:Reset()
        Progress:Run(5)
    end,
})

--[[
    5. Visuals tab

    Color picker, paragraph and text.
]]

local Esp = Visuals:create_module({
    title = "ESP",
    description = "Colors and text",
    flag = "esp",
    section = "left",
    callback = function(state)
        print("ESP:", state)
    end,
})

local espColor = Esp:create_colorpicker({
    title = "Outline color",
    flag = "esp_color",
    default = Color3.fromRGB(99, 102, 241),
    callback = function(color)
        print("Color:", color)
    end,
})

--[[
    espColor:Get() returns the current Color3.
    espColor:Set(Color3) changes the selected color.
]]

Esp:create_paragraph({
    title = "Tip",
    text = "Paragraphs wrap long text automatically.",
    customScale = 70,
})

local status = Esp:create_text({
    text = "Status: idle",
    CustomYSize = 24
})

status:Set({
    text = "Status: ready"
})

--[[
    6. Settings tab

    Theme, transparency, watermark, background and config.
]]

local Interface = Settings:create_module({
    title = "Interface",
    description = "Theme, transparency, watermark",
    flag = "interface",
    section = "left",
    callback = function() end,
})

Interface:create_dropdown({
    title = "Theme",
    flag = "ui_theme",
    options = { "Dark", "Light" },
    maximum_options = 2,
    callback = function(option)
        if ready then
            Library.SetTheme(option)
        end
    end,
})

Interface:create_dropdown({
    title = "Notification style",
    flag = "ui_notify",
    options = { "new", "old" },
    maximum_options = 2,
    callback = function(option)
        if ready then
            Library.SetNotifyMode(option)
        end
    end,
})

Interface:create_slider({
    title = "Window transparency",
    flag = "ui_transparency",
    minimum_value = 0,
    maximum_value = 90,
    value = 15,
    round_number = true,
    callback = function(value)
        Library.SetTransparency(value / 100)
    end,
})

Interface:create_button({
    title = "Toggle watermark",
    callback = function()
        Library.SetWatermark(not Library._watermark_on)
    end,
})

--[[
    Background settings
]]

local Background = Settings:create_module({
    title = "Background",
    description = "Image behind the window",
    flag = "background",
    section = "right",
    callback = function() end,
})

Background:create_textbox({
    title = "Image (asset id or URL)",
    placeholder = "rbxassetid://...",
    flag = "bg_image",
    callback = function(text)
        Window:SetImageBackground(text)
    end,
})

Background:create_dropdown({
    title = "Style",
    flag = "bg_style",
    options = {
        "Crop",
        "Stretch",
        "Fit",
        "Tile",
        "FadeLeft",
        "FadeRight",
        "FadeTop",
        "FadeBottom"
    },
    maximum_options = 8,
    callback = function(option)
        Window:SetImageBackground(GG.ImageBackground, option)
    end,
})

Background:create_slider({
    title = "Image transparency",
    flag = "bg_transparency",
    minimum_value = 0,
    maximum_value = 100,
    value = 70,
    round_number = true,
    callback = function(value)
        Window:SetImageBackground(
            GG.ImageBackground,
            nil,
            value / 100
        )
    end,
})

--[[
    Config settings
]]

local Config = Settings:create_module({
    title = "Config",
    description = "Save, export, reset",
    flag = "config",
    section = "right",
    callback = function() end,
})

Config:create_button({
    title = "Save config",
    callback = Library.SaveConfig
})

Config:create_button({
    title = "Export to clipboard",
    callback = Library.ExportConfig
})

Config:create_button({
    title = "Reset config...",
    callback = function()
        Window:Dialog({
            Icon = "alert-circle",
            IconThemed = true,
            Title = "Reset config?",
            Content = "All saved settings and keybinds will be deleted.",
            Buttons = {
                {
                    Title = "Reset",
                    Icon = "trash-2",
                    Variant = "Destructive",
                    Callback = Library.ResetConfig
                },
                {
                    Title = "Cancel",
                    Icon = "x",
                    Variant = "Secondary"
                },
            },
        })
    end,
})

-- 7 loader



Window:load()
ready = true

Library.Notify.Success(
    "Sora x Hikaru",
    "Loaded. Press Insert to hide / show the window.",
    4
)
