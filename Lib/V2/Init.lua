-- Lib/V2/Init.lua
-- Entry point of UI v2. Loads the modules, opens the saved settings file and builds the window.
--
--   local V2 = loadstring(game:HttpGet(base .. "Lib/V2/Init.lua"))()
--   local Window = V2.new({ Library = Library })      -- Library (UI v1) is optional: icons and notifications
--   local Combat = Window:AddTab("Combat", "swords")  -- default tabs already exist, AddTab returns them
--   local card = Combat:AddFeature({ Name = "Auto Parry", Description = "...", Setting = true, Notification = true, Callback = function(state) end })

local Init = {}

Init.Version = "v2.0"

local moduleNames = { "Janitor", "Store", "Theme", "Feature", "Components", "ColorPicker", "Panels", "FloatingButton", "Window", "Compat" }

local function globalConfig()
    local env = (getgenv and getgenv()) or _G
    return env.GG or {}
end

-- Loads Lib/V2/<name>.lua from V2Base (raw.githubusercontent.com only) or from options.ModuleLoader
local function makeLoader(options)
    if type(options.ModuleLoader) == "function" then
        return options.ModuleLoader
    end

    local base = options.V2Base or globalConfig().V2Base or "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/Lib/V2/"
    if not string.match(base, "^https://raw%.githubusercontent%.com/") then
        error("V2Base must start with https://raw.githubusercontent.com/", 0)
    end
    if string.sub(base, -1) ~= "/" then
        base = base .. "/"
    end

    return function(name)
        local source = game:HttpGet(base .. name .. ".lua")
        local compiled, compileError = loadstring(source, "=V2/" .. name)
        if not compiled then
            error("V2/" .. name .. ".lua has a syntax error: " .. tostring(compileError), 0)
        end
        return compiled()
    end
end

-- options: Library (UI v1, optional), Folder, Preset ("Pure Black" | "Midnight"), Title, Version, Categories,
-- ToggleKey, NotificationSoundId, V2Base, ModuleLoader
function Init.new(options)
    options = options or {}
    local load = makeLoader(options)

    local modules = {}
    for _, name in ipairs(moduleNames) do
        modules[name] = load(name)
    end

    local folder = options.Folder or globalConfig().FolderName or "SoraHikaru"
    local store = modules.Store.new({ Path = folder .. "/v2.json" })
    local theme = modules.Theme.new({ Store = store, Preset = options.Preset })

    local window = modules.Window.new({
        Modules = modules,
        Theme = theme,
        Store = store,
        Library = options.Library,
        Title = options.Title or globalConfig().UIName,
        Version = options.Version or Init.Version,
        Categories = options.Categories,
        ToggleKey = options.ToggleKey or globalConfig().ToggleKey,
        NotificationSoundId = options.NotificationSoundId,
    })
    modules.Compat.apply(window)
    return window
end

return Init
