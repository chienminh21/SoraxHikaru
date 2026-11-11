-- Sora x Hikaru | Auth/KeySystem.lua
-- Multi-provider key window + validation.
-- Supports legacy config (Service / Keys) and WindUI-style API = { { Type = ... }, ... }.

local KeySystem = {}

local DEFAULT_SERVICES_BASE = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/Auth/Services/"
local REQUEST_TIMEOUT = 15
local VALIDATE_FIELDS = { "Validate", "Verify", "Check", "CheckKey", "Authenticate", "Auth", "Login" }

local SUCCESS_COLOR = Color3.fromRGB(80, 200, 120)
local ERROR_COLOR = Color3.fromRGB(240, 85, 85)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local state = {
    Unlocked = false,
    Info = nil,
    Running = false,
    SavePath = nil,
    Listeners = {},
}

-- Optional modules (loaded lazily so KeySystem still works standalone)
local Registry, Manager

local function new(class, props, parent)
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function trim(text)
    return (string.gsub(tostring(text), "^%s*(.-)%s*$", "%1"))
end

local function sanitize(text)
    return (string.gsub(string.lower(tostring(text)), "[^%w]+", "_"))
end

local function globalConfig()
    local env = (getgenv and getgenv()) or _G
    return env.GG or {}
end

local function guiParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    return (ok and ui) or CoreGui
end

local function getHwid()
    if gethwid then
        local ok, id = pcall(gethwid)
        if ok and id then return tostring(id) end
    end
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and tostring(id) or "unknown"
end

local function contrastText(color)
    local brightness = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
    return brightness > 0.6 and Color3.fromRGB(12, 13, 15) or Color3.fromRGB(255, 255, 255)
end

local function getColors(Library)
    local ok, colors = pcall(function() return Library.GetThemeColors() end)
    if ok and type(colors) == "table" and colors.Accent then
        return colors
    end
    return {
        Background = Color3.fromRGB(12, 13, 15),
        ModuleBackground = Color3.fromRGB(22, 28, 38),
        Card = Color3.fromRGB(32, 38, 51),
        Stroke = Color3.fromRGB(52, 66, 89),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(152, 181, 255),
        Accent = Color3.fromRGB(152, 181, 255),
    }
end

local function savePathFor(serviceName)
    local folder = globalConfig().FolderName or "SoraHikaru"
    return folder, folder .. "/key_" .. sanitize(serviceName) .. ".txt"
end

local function readSavedKey(path)
    if not (isfile and readfile) then return nil end
    local ok, value = pcall(function()
        if isfile(path) then return readfile(path) end
    end)
    if ok and type(value) == "string" and trim(value) ~= "" then
        return trim(value)
    end
    return nil
end

local function writeSavedKey(folder, path, key)
    if not writefile then return end
    pcall(function()
        if makefolder and isfolder and not isfolder(folder) then
            makefolder(folder)
        end
        writefile(path, key)
    end)
end

local function deleteSavedKey(path)
    pcall(function()
        if delfile and isfile and isfile(path) then
            delfile(path)
        end
    end)
end

local function pickValidator(service)
    if type(service) == "function" then return service end
    if type(service) == "table" then
        for _, field in ipairs(VALIDATE_FIELDS) do
            if type(service[field]) == "function" then
                return service[field]
            end
        end
    end
end

local function firstDefined(source, names)
    for _, name in ipairs(names) do
        if source[name] ~= nil then return source[name] end
    end
end

local function readResult(first, second, third)
    if type(first) == "table" then
        local flag = firstDefined(first, { "Success", "success", "Valid", "valid", "Authenticated", "authenticated", "ok", "Ok" })
        local message = firstDefined(first, { "Message", "message", "Reason", "reason", "Error", "error" })
        local data = firstDefined(first, { "Data", "data" }) or first
        return flag == true, message and tostring(message) or nil, data
    end
    return first == true, second and tostring(second) or nil, third
end

local function runWithTimeout(callback, seconds)
    local finished = false
    local results = nil
    task.spawn(function()
        results = table.pack(pcall(callback))
        finished = true
    end)
    local deadline = os.clock() + seconds
    while not finished and os.clock() < deadline do
        task.wait(0.05)
    end
    if not finished then
        return false, "the key service did not answer in time"
    end
    return table.unpack(results, 1, results.n)
end

local function makeKeyList(keys, caseSensitive)
    local lookup = {}
    for _, key in ipairs(keys) do
        local value = trim(key)
        lookup[caseSensitive and value or string.upper(value)] = true
    end
    return function(key)
        local value = caseSensitive and key or string.upper(key)
        if lookup[value] then
            return true, "Key accepted"
        end
        return false, "Invalid key"
    end
end

local function loadServiceFile(name, base)
    if not string.match(name, "^[%w_%-]+$") then
        return nil, 'invalid service name "' .. name .. '"'
    end
    if not string.match(base, "^https://raw%.githubusercontent%.com/") then
        return nil, "services must be loaded from raw.githubusercontent.com"
    end
    local downloaded, source = pcall(function()
        return game:HttpGet(base .. name .. ".lua")
    end)
    if not downloaded then
        return nil, "could not download the service: " .. tostring(source)
    end
    local compiled, compileError = loadstring(source, "=service:" .. name)
    if not compiled then
        return nil, "the service has a syntax error: " .. tostring(compileError)
    end
    local executed, service = pcall(compiled)
    if not executed then
        return nil, "the service failed to load: " .. tostring(service)
    end
    return service
end

-- Inline minimal Registry/Manager so Local multi-provider works offline.
-- Remote Auth/Registry.lua + Services/* are used when available.
local function buildInlineRegistry()
    local reg = { _providers = {} }
    local aliases = {
        ["local"] = "Local",
        ["custom"] = "Custom",
        ["platoboost"] = "Platoboost",
        ["panda"] = "PandaDevelopment",
        ["pandadevelopment"] = "PandaDevelopment",
        ["luarmor"] = "Luarmor",
        ["junkie"] = "JunkieDevelopment",
        ["junkiedevelopment"] = "JunkieDevelopment",
    }

    function reg.NormalizeType(name)
        if type(name) ~= "string" then return nil end
        local key = string.lower((string.gsub(name, "%s+", "")))
        return aliases[key] or name
    end

    function reg.Register(name, factory)
        reg._providers[reg.NormalizeType(name) or name] = factory
        return true
    end

    function reg.Get(name)
        local key = reg.NormalizeType(name)
        return key and reg._providers[key] or nil
    end

    function reg.Create(providerConfig)
        if type(providerConfig) ~= "table" then
            return nil, "provider config must be a table"
        end
        local typeName = reg.NormalizeType(providerConfig.Type or providerConfig.Provider or providerConfig.Name)
        if not typeName then
            return nil, "provider Type is required"
        end
        local factory = reg.Get(typeName)
        if not factory then
            return nil, 'unknown provider "' .. tostring(providerConfig.Type) .. '"'
        end
        local ok, service = pcall(factory, providerConfig)
        if not ok then
            return nil, "provider init failed: " .. tostring(service)
        end
        if type(service) ~= "table" then
            return nil, "provider did not return a service table"
        end
        service.Name = service.Name or typeName
        return service
    end

    -- Built-in Local factory (always available)
    reg.Register("Local", function(options)
        options = options or {}
        local keys = options.Keys or options.keys or {}
        local caseSensitive = options.CaseSensitive == true
        local lookup = {}
        for _, key in ipairs(keys) do
            local value = trim(key)
            if value ~= "" then
                lookup[caseSensitive and value or string.upper(value)] = true
            end
        end
        local function Validate(key)
            key = trim(key)
            if key == "" then return false, "Empty key" end
            local value = caseSensitive and key or string.upper(key)
            if lookup[value] then
                return true, "Key accepted", { Provider = "Local" }
            end
            return false, "Invalid key"
        end
        return {
            Name = "Local",
            Validate = Validate,
            Verify = Validate,
            GetKeyLink = options.GetKeyLink,
        }
    end)

    -- Custom factory
    reg.Register("Custom", function(options)
        options = options or {}
        local handler = options.Handler or options.Service or options.Validate
        local validator
        if type(handler) == "function" then
            validator = handler
        elseif type(handler) == "table" then
            for _, field in ipairs(VALIDATE_FIELDS) do
                if type(handler[field]) == "function" then
                    validator = handler[field]
                    break
                end
            end
        end
        if not validator then
            error("Custom provider needs Handler/Service with Validate")
        end
        return {
            Name = options.Name or "Custom",
            Validate = function(key, ctx) return validator(key, ctx) end,
            Verify = function(key, ctx) return validator(key, ctx) end,
            GetKeyLink = options.GetKeyLink,
        }
    end)

    return reg
end

local function ensureModules(config)
    if Registry and Manager then return true end

    local base = (config and config.AuthBase) or "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/Auth/"
    local function fetchModule(rel)
        local ok, src = pcall(function() return game:HttpGet(base .. rel) end)
        if not ok or type(src) ~= "string" or #src < 20 then return nil end
        -- GitHub 404 pages are HTML
        if string.find(src, "<!DOCTYPE html>", 1, true) or string.find(src, "404: Not Found", 1, true) then
            return nil
        end
        local fn = loadstring(src, "=" .. rel)
        if not fn then return nil end
        local ok2, mod = pcall(fn)
        if ok2 and type(mod) == "table" then return mod end
        return nil
    end

    local remoteRegistry = fetchModule("Registry.lua")
    local remoteManager = fetchModule("Manager.lua")

    Registry = remoteRegistry or buildInlineRegistry()
    Manager = remoteManager -- optional

    -- Register remote service modules when Registry exists
    if Registry and type(Registry.Register) == "function" then
        local servicesBase = (config and config.ServicesBase) or DEFAULT_SERVICES_BASE
        for _, name in ipairs({ "Platoboost", "PandaDevelopment", "Luarmor", "JunkieDevelopment", "Local", "Custom" }) do
            if not Registry.Get or not Registry.Get(name) then
                local mod = loadServiceFile(name, servicesBase)
                if type(mod) == "table" and type(mod.New) == "function" then
                    Registry.Register(name, mod.New)
                end
            end
        end
        -- Always ensure Local/Custom inline factories exist
        if not Registry.Get("Local") then
            local inline = buildInlineRegistry()
            Registry.Register("Local", inline.Get("Local"))
            Registry.Register("Custom", inline.Get("Custom"))
        end
    end

    return Registry ~= nil
end

local function resolveServices(config)
    local services = {}

    -- WindUI-style multi provider
    if type(config.API) == "table" and #config.API > 0 then
        ensureModules(config)
        if not Registry then
            return nil, "Registry failed to load for multi-provider API"
        end
        for index, entry in ipairs(config.API) do
            local service, err = Registry.Create(entry)
            if not service then
                return nil, "API[" .. index .. "]: " .. tostring(err)
            end
            table.insert(services, service)
        end
        return services
    end

    -- Legacy: Keys list
    if type(config.Keys) == "table" then
        table.insert(services, {
            Name = "Local",
            Validate = makeKeyList(config.Keys, config.CaseSensitive == true),
            GetKeyLink = config.GetKeyLink,
        })
        return services
    end

    -- Legacy: single Service
    local service = config.Service
    local label = "Custom"
    if type(service) == "string" then
        label = service
        local loaded, loadError = loadServiceFile(service, config.ServicesBase or DEFAULT_SERVICES_BASE)
        if not loaded then
            return nil, loadError
        end
        -- module may export .New or be a ready service table
        if type(loaded) == "table" and type(loaded.New) == "function" then
            local ok, inst = pcall(loaded.New, config.ServiceOptions or {})
            if not ok then
                return nil, tostring(inst)
            end
            service = inst
        else
            service = loaded
        end
    elseif type(service) == "function" then
        service = { Validate = service }
    end

    if type(service) ~= "table" or not pickValidator(service) then
        return nil, "the key service needs one of: " .. table.concat(VALIDATE_FIELDS, ", ")
    end
    service.Name = service.Name or label
    if config.GetKeyLink and not service.GetKeyLink then
        service.GetKeyLink = config.GetKeyLink
    end
    table.insert(services, service)
    return services
end

local function validateAgainst(services, key, config)
    local context = {
        Options = config.ServiceOptions or {},
        Hwid = getHwid(),
        Player = Players.LocalPlayer,
    }
    local timeout = config.Timeout or REQUEST_TIMEOUT

    if Manager and Manager.ValidateAny then
        return Manager.ValidateAny(services, key, context, timeout)
    end

    local errors = {}
    for _, service in ipairs(services) do
        local validator = pickValidator(service)
        context.ServiceName = service.Name
        local ok, first, second, third = runWithTimeout(function()
            return validator(key, context)
        end, timeout)
        if not ok then
            table.insert(errors, (service.Name or "?") .. ": " .. tostring(first))
        else
            local valid, message, data = readResult(first, second, third)
            if valid then
                return true, message, data, service.Name
            end
            table.insert(errors, (service.Name or "?") .. ": " .. tostring(message or "failed"))
        end
    end
    return false, table.concat(errors, " | ")
end

local function resolveKeyLink(services, config)
    if type(config.GetKeyLink) == "string" and config.GetKeyLink ~= "" then
        return config.GetKeyLink
    end
    if Manager and Manager.ResolveKeyLink then
        return Manager.ResolveKeyLink(services, config.GetKeyLink)
    end
    for _, service in ipairs(services) do
        local link = service.GetKeyLink
        if type(link) == "function" then
            local ok, value = pcall(link, { Options = config.ServiceOptions or {}, Hwid = getHwid() })
            if ok and type(value) == "string" and value ~= "" then
                return value
            end
        elseif type(link) == "string" and link ~= "" then
            return link
        end
    end
end

local function buildInfo(key, serviceName, message, data)
    local info = {
        Key = key,
        Service = serviceName,
        Message = message,
        Data = data,
        CheckedAt = os.time(),
    }
    if type(data) == "table" then
        local expires = firstDefined(data, { "ExpiresAt", "expiresAt", "Expires", "expires", "expire" })
        if tonumber(expires) then
            info.ExpiresAt = tonumber(expires)
        end
    end
    return info
end

local function buildWindow(Library, config, hasLink, canRemember, hooks)
    local colors = getColors(Library)
    local connections = {}
    local busy = false
    local locked = false
    local remember = canRemember
    local closed = false

    local screen = new("ScreenGui", {
        Name = "SxH_KeySystem",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent())

    local overlay = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, screen)

    local card = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = colors.ModuleBackground,
        BorderSizePixel = 0,
    }, overlay)
    new("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
    new("UIStroke", { Color = colors.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 18),
        PaddingBottom = UDim.new(0, 18),
        PaddingLeft = UDim.new(0, 18),
        PaddingRight = UDim.new(0, 18),
    }, card)
    new("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, card)

    local cardScale = new("UIScale", { Scale = 0.92 }, card)

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = colors.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(config.Title or config.Note or "Authentication"),
        LayoutOrder = 1,
    }, card)

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = colors.TextSecondary,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = tostring(config.Description or "Enter your key to unlock the features."),
        LayoutOrder = 2,
    }, card)

    local keyBox = new("TextBox", {
        Name = "KeyBox",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = colors.Card,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = colors.TextPrimary,
        PlaceholderText = "Enter your key",
        PlaceholderColor3 = colors.TextSecondary,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 3,
    }, card)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, keyBox)
    new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, keyBox)
    new("UIStroke", { Color = colors.Stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, keyBox)

    local statusLabel = new("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = colors.TextSecondary,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = "",
        LayoutOrder = 4,
    }, card)

    local rememberBox, rememberFill
    if canRemember then
        local row = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = 5,
        }, card)
        rememberBox = new("Frame", {
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            BackgroundColor3 = colors.Card,
            BorderSizePixel = 0,
        }, row)
        new("UICorner", { CornerRadius = UDim.new(0, 4) }, rememberBox)
        new("UIStroke", { Color = colors.Stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, rememberBox)
        rememberFill = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = remember and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
            BackgroundColor3 = colors.Accent,
            BorderSizePixel = 0,
        }, rememberBox)
        new("UICorner", { CornerRadius = UDim.new(0, 3) }, rememberFill)
        new("TextLabel", {
            Position = UDim2.fromOffset(24, 0),
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = colors.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Remember key",
        }, row)
        row.MouseButton1Click:Connect(function()
            remember = not remember
            TweenService:Create(rememberFill, TweenInfo.new(0.15), {
                Size = remember and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
            }):Play()
        end)
    end

    local buttonRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        LayoutOrder = 6,
    }, card)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, buttonRow)

    local function makeButton(text, order, primary, width)
        local button = new("TextButton", {
            Size = UDim2.new(width, -4, 1, 0),
            BackgroundColor3 = primary and colors.Accent or colors.Card,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = primary and contrastText(colors.Accent) or colors.TextPrimary,
            Text = text,
            LayoutOrder = order,
        }, buttonRow)
        new("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
        if not primary then
            new("UIStroke", { Color = colors.Stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
        end
        return button
    end

    local getKeyButton = hasLink and makeButton("Get Key", 1, false, 0.5) or nil
    local checkButton = makeButton("Check Key", 2, true, hasLink and 0.5 or 1)

    local skipButton = nil
    if config.AllowSkip then
        skipButton = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = colors.TextSecondary,
            Text = tostring(config.SkipText or "Continue without a key"),
            LayoutOrder = 7,
        }, card)
    end

    local closeButton = new("TextButton", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, -8, 0, -8),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = colors.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = colors.TextSecondary,
        Text = "X",
        ZIndex = 2,
    }, card)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, closeButton)

    local controller = {}

    function controller.SetStatus(text, kind)
        statusLabel.Text = tostring(text or "")
        if kind == "success" then
            statusLabel.TextColor3 = SUCCESS_COLOR
        elseif kind == "error" then
            statusLabel.TextColor3 = ERROR_COLOR
        else
            statusLabel.TextColor3 = colors.TextSecondary
        end
    end

    function controller.SetBusy(value)
        busy = value and true or false
        checkButton.Text = busy and "Checking..." or "Check Key"
    end

    function controller.SetLocked(seconds)
        locked = true
        task.spawn(function()
            local left = seconds
            while left > 0 and not closed do
                controller.SetStatus("Too many attempts. Wait " .. left .. "s", "error")
                task.wait(1)
                left -= 1
            end
            locked = false
            if not closed then
                controller.SetStatus("")
            end
        end)
    end

    function controller.Close()
        if closed then return end
        closed = true
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        local out = TweenService:Create(cardScale, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = 0.92 })
        out:Play()
        out.Completed:Wait()
        screen:Destroy()
    end

    function controller.IsClosed()
        return closed
    end

    if getKeyButton then
        getKeyButton.MouseButton1Click:Connect(function()
            if busy or locked or closed then return end
            if hooks.OnGetKey then hooks.OnGetKey() end
        end)
    end

    checkButton.MouseButton1Click:Connect(function()
        if busy or locked or closed then return end
        local key = trim(keyBox.Text)
        if key == "" then
            controller.SetStatus("Enter a key first.", "error")
            return
        end
        if hooks.OnSubmit then
            hooks.OnSubmit(key, remember)
        end
    end)

    if skipButton then
        skipButton.MouseButton1Click:Connect(function()
            if busy or closed then return end
            if hooks.OnSkip then hooks.OnSkip() end
        end)
    end

    closeButton.MouseButton1Click:Connect(function()
        if closed then return end
        if hooks.OnClose then hooks.OnClose() end
        controller.Close()
    end)

    keyBox.FocusLost:Connect(function(enter)
        if enter and not busy and not locked and not closed then
            local key = trim(keyBox.Text)
            if key ~= "" and hooks.OnSubmit then
                hooks.OnSubmit(key, remember)
            end
        end
    end)

    TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.45 }):Play()
    TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    return controller
end

local function notify(Library, kind, title, text)
    pcall(function()
        if Library and Library.Notify and Library.Notify[kind] then
            Library.Notify[kind](title, text, 4)
        end
    end)
end

local function markUnlocked(info, config)
    state.Unlocked = true
    state.Info = info
    if type(config.OnSuccess) == "function" then
        pcall(config.OnSuccess, info)
    end
    for _, listener in ipairs(table.clone(state.Listeners)) do
        pcall(listener, info)
    end
    table.clear(state.Listeners)
end

function KeySystem.IsUnlocked()
    if not state.Unlocked then return false end
    local info = state.Info
    return not (info and info.ExpiresAt and os.time() >= info.ExpiresAt)
end

function KeySystem.GetInfo()
    return state.Info
end

function KeySystem.OnUnlock(callback)
    if KeySystem.IsUnlocked() then
        pcall(callback, state.Info)
    else
        table.insert(state.Listeners, callback)
    end
end

function KeySystem.Require(Library, callback)
    if KeySystem.IsUnlocked() then
        return callback()
    end
    notify(Library, "Warn", "Key required", "Enter a valid key to use this feature.")
end

function KeySystem.Reset()
    state.Unlocked = false
    state.Info = nil
    if state.SavePath then
        deleteSavedKey(state.SavePath)
    end
end

--[[
    KeySystem.Run(Library, {
        Enabled = true,
        Title / Note / Description,
        -- Multi provider (WindUI style):
        API = {
            { Type = "Local", Keys = { "SORAXHIKARU-TEST" } },
            { Type = "PandaDevelopment", ServiceId = "..." },
            { Type = "Platoboost", ServiceId = "...", Secret = "..." },
            { Type = "Luarmor", ScriptId = "...", Discord = "https://discord.gg/..." },
        },
        -- Legacy:
        Service = "Remote" | table | function,
        Keys = { "KEY-1" },
        GetKeyLink = "https://...",
        SaveKey = true,
        AllowSkip = false,
        MaxAttempts = 5, LockSeconds = 30, Timeout = 15,
        OnSuccess = function(info) end,
    })
]]
function KeySystem.Run(Library, config)
    config = config or {}

    local enabled = config.Enabled
    if enabled == nil then
        enabled = globalConfig().KeySystem ~= false
    end
    if not enabled then
        local info = { Disabled = true }
        markUnlocked(info, config)
        return true, info
    end

    if KeySystem.IsUnlocked() then
        return true, state.Info
    end
    if state.Running then
        return false, "the key window is already open"
    end

    local services, serviceError = resolveServices(config)
    if not services then
        warn("[Sora x Hikaru] key system: " .. tostring(serviceError))
        notify(Library, "Error", "Key system", tostring(serviceError))
        return false, serviceError
    end

    state.Running = true

    local serviceLabel = services[1] and services[1].Name or "Key"
    if #services > 1 then
        serviceLabel = "Multi"
    end

    local folder, path = savePathFor(serviceLabel)
    local canRemember = config.SaveKey ~= false and writefile ~= nil
    state.SavePath = path

    local maxAttempts = config.MaxAttempts or 5
    local lockSeconds = config.LockSeconds or 30
    local attempts = 0
    local result = nil

    local savedKey = canRemember and readSavedKey(path) or nil
    if savedKey then
        local valid, message, data, used = validateAgainst(services, savedKey, config)
        if valid then
            local info = buildInfo(savedKey, used or serviceLabel, message, data)
            markUnlocked(info, config)
            state.Running = false
            notify(Library, "Success", "Key accepted", "Saved key is valid.")
            return true, info
        end
        deleteSavedKey(path)
    end

    local link = resolveKeyLink(services, config)
    local controller

    controller = buildWindow(Library, config, link ~= nil, canRemember, {
        OnSubmit = function(key, remember)
            if controller.IsClosed() then return end
            controller.SetBusy(true)
            controller.SetStatus("Checking key...")
            local valid, message, data, used = validateAgainst(services, key, config)
            if controller.IsClosed() then
                state.Running = false
                return
            end
            controller.SetBusy(false)

            if valid then
                local info = buildInfo(key, used or serviceLabel, message, data)
                if remember and canRemember then
                    writeSavedKey(folder, path, key)
                elseif not remember then
                    deleteSavedKey(path)
                end
                controller.SetStatus(message or "Key accepted.", "success")
                task.wait(0.55)
                markUnlocked(info, config)
                notify(Library, "Success", "Key accepted", message or "Features unlocked.")
                result = { ok = true, info = info }
                controller.Close()
                return
            end

            attempts += 1
            controller.SetStatus(message or "Invalid key.", "error")
            notify(Library, "Error", "Key rejected", message or "Invalid key.")
            if attempts >= maxAttempts then
                controller.SetLocked(lockSeconds)
                attempts = 0
            end
        end,
        OnGetKey = function()
            local current = resolveKeyLink(services, config) or link
            if current then
                if setclipboard then
                    pcall(setclipboard, current)
                    controller.SetStatus("Key link copied.", "success")
                else
                    controller.SetStatus(current)
                end
            else
                controller.SetStatus("No get-key link available.", "error")
            end
        end,
        OnSkip = function()
            local info = { Skipped = true }
            markUnlocked(info, config)
            result = { ok = true, info = info }
            controller.Close()
        end,
        OnClose = function()
            if not result then
                result = { ok = false, reason = "closed" }
            end
        end,
    })

    while not result and not controller.IsClosed() do
        task.wait(0.05)
    end

    if not controller.IsClosed() then
        controller.Close()
    end

    state.Running = false

    if result and result.ok then
        return true, result.info
    end
    return false, result and result.reason or "closed"
end

return KeySystem
