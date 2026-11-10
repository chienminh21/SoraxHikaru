-- Sora x Hikaru | Auth/KeySystem.lua
-- Key window + validation flow. Keys are checked by a service (Auth/Services/<Name>.lua),
-- by a function, or by a plain list of keys. The key system can be turned off completely.

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

local state = {
    Unlocked = false,
    Info = nil,
    Running = false,
    SavePath = nil,
    Listeners = {},
}

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
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and id or "unknown"
end

local function contrastText(color)
    local brightness = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
    return brightness > 0.6 and Color3.fromRGB(12, 13, 15) or Color3.fromRGB(255, 255, 255)
end

-- Colors follow the active UI theme when the library is available
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

-- Saved key (workspace/<FolderName>/key_<service>.txt)

local function savePathFor(serviceName)
    local folder = globalConfig().FolderName or "SoraHikaru"
    return folder, folder .. "/key_" .. sanitize(serviceName) .. ".txt"
end

local function readSavedKey(path)
    if not (isfile and readfile) then
        return nil
    end
    local ok, value = pcall(function()
        if isfile(path) then
            return readfile(path)
        end
    end)
    if ok and type(value) == "string" and trim(value) ~= "" then
        return trim(value)
    end
    return nil
end

local function writeSavedKey(folder, path, key)
    if not writefile then
        return
    end
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


-- Services
-- A service is a table (or function) that checks a key. Accepted validate names:
-- Validate, Verify, Check, CheckKey, Authenticate, Auth, Login.
-- It is called as validate(key, context) (no self) and may return:
--   true / false, message, data
--   or a table { Success | success | Valid | valid | ok, Message | message, Data | data }

local function pickValidator(service)
    if type(service) == "function" then
        return service
    end
    if type(service) == "table" then
        for _, field in ipairs(VALIDATE_FIELDS) do
            if type(service[field]) == "function" then
                return service[field]
            end
        end
    end
    return nil
end

local function firstDefined(source, names)
    for _, name in ipairs(names) do
        if source[name] ~= nil then
            return source[name]
        end
    end
    return nil
end

-- Turns the different return shapes into: success (boolean), message, data
local function readResult(first, second, third)
    if type(first) == "table" then
        local flag = firstDefined(first, { "Success", "success", "Valid", "valid", "Authenticated", "authenticated", "ok", "Ok" })
        local message = firstDefined(first, { "Message", "message", "Reason", "reason", "Error", "error" })
        local data = firstDefined(first, { "Data", "data" })
        if data == nil then
            data = first
        end
        return flag == true, message and tostring(message) or nil, data
    end
    return first == true, second and tostring(second) or nil, third
end

-- Runs callback in its own thread so a hanging request cannot freeze the window
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

local function resolveService(config)
    if type(config.Keys) == "table" then
        return { Name = "Local", Validate = makeKeyList(config.Keys, config.CaseSensitive == true) }
    end

    local service = config.Service
    local label = "Custom"

    if type(service) == "string" then
        label = service
        local loaded, loadError = loadServiceFile(service, config.ServicesBase or DEFAULT_SERVICES_BASE)
        if not loaded then
            return nil, loadError
        end
        service = loaded
    elseif type(service) == "function" then
        service = { Validate = service }
    end

    if type(service) ~= "table" or not pickValidator(service) then
        return nil, "the key service needs one of: " .. table.concat(VALIDATE_FIELDS, ", ")
    end

    service.Name = service.Name or label
    return service
end

local function validateKey(service, key, config)
    local validator = pickValidator(service)
    local context = {
        Options = config.ServiceOptions or {},
        Hwid = getHwid(),
        Player = Players.LocalPlayer,
        ServiceName = service.Name,
    }

    local ok, first, second, third = runWithTimeout(function()
        return validator(key, context)
    end, config.Timeout or REQUEST_TIMEOUT)

    if not ok then
        return false, tostring(first)
    end
    return readResult(first, second, third)
end

-- The "Get Key" link: config.GetKeyLink, otherwise the service's GetKeyLink (string or function)
local function resolveKeyLink(service, config)
    if type(config.GetKeyLink) == "string" and config.GetKeyLink ~= "" then
        return config.GetKeyLink
    end
    local link = service.GetKeyLink
    if type(link) == "function" then
        local ok, value = pcall(link, { Options = config.ServiceOptions or {}, Hwid = getHwid() })
        link = ok and value or nil
    end
    return type(link) == "string" and link ~= "" and link or nil
end

local function buildInfo(key, serviceName, message, data)
    local info = { Key = key, Service = serviceName, Message = message, Data = data, CheckedAt = os.time() }
    if type(data) == "table" then
        local expires = firstDefined(data, { "ExpiresAt", "expiresAt", "Expires", "expires", "expire" })
        if tonumber(expires) then
            info.ExpiresAt = tonumber(expires)
        end
    end
    return info
end

-- hooks: OnSubmit(key, remember), OnGetKey(), OnSkip(), OnClose()
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
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
    }, screen)

    local card = new("Frame", {
        Name = "Card",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 340, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = colors.ModuleBackground,
        BorderSizePixel = 0,
        Active = true,
    }, overlay)
    new("UICorner", { CornerRadius = UDim.new(0, 14) }, card)
    new("UIStroke", { Color = colors.Stroke, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 18),
        PaddingRight = UDim.new(0, 18),
    }, card)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, card)

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local cardScale = new("UIScale", { Scale = 0.92 }, card)
    local targetScale = math.clamp((viewport.X - 24) / 376, 0.6, 1)

    -- Header (drag handle): icon, title, close button
    local header = new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Active = true,
        LayoutOrder = 1,
    }, card)

    local titleX = 0
    local keyIcon = new("ImageLabel", {
        Name = "KeyIcon",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        ImageColor3 = colors.Accent,
    }, header)
    local iconOk = pcall(function()
        return Library.ApplyIcon(keyIcon, "key-round", colors.Accent)
    end) and keyIcon.Image ~= ""
    if iconOk then
        titleX = 28
    else
        keyIcon:Destroy()
    end

    new("TextLabel", {
        Position = UDim2.fromOffset(titleX, 0),
        Size = UDim2.new(1, -(titleX + 30), 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = colors.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(config.Title or globalConfig().UIName or "Key System"),
    }, header)

    local closeButton = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = colors.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = colors.TextSecondary,
        Text = "X",
    }, header)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, closeButton)

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

    -- Remember key
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

    -- Buttons
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

    -- Controller used by the flow
    local controller = {}

    function controller.SetStatus(text, kind)
        statusLabel.Text = text or ""
        statusLabel.TextColor3 = (kind == "success" and SUCCESS_COLOR) or (kind == "error" and ERROR_COLOR) or colors.TextSecondary
    end

    function controller.SetBusy(value)
        busy = value
        checkButton.Text = value and "Checking..." or "Check Key"
    end

    function controller.SetKey(text)
        keyBox.Text = text
    end

    -- Disable checking for `seconds` (too many wrong keys)
    function controller.Lock(seconds)
        locked = true
        task.spawn(function()
            for remaining = seconds, 1, -1 do
                if closed then return end
                checkButton.Text = string.format("Wait %ds", remaining)
                task.wait(1)
            end
            locked = false
            if not closed then
                checkButton.Text = busy and "Checking..." or "Check Key"
            end
        end)
    end

    function controller.Close()
        if closed then return end
        closed = true
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        local out = TweenService:Create(cardScale, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = 0.92 })
        out:Play()
        out.Completed:Once(function()
            screen:Destroy()
        end)
    end

    local function submit()
        if busy or locked or closed then
            return
        end
        local key = trim(keyBox.Text)
        if key == "" then
            controller.SetStatus("Enter a key first.", "error")
            return
        end
        task.spawn(hooks.OnSubmit, key, remember)
    end

    checkButton.MouseButton1Click:Connect(submit)
    table.insert(connections, keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            submit()
        end
    end))

    if getKeyButton then
        getKeyButton.MouseButton1Click:Connect(function()
            task.spawn(hooks.OnGetKey)
        end)
    end
    if skipButton then
        skipButton.MouseButton1Click:Connect(function()
            task.spawn(hooks.OnSkip)
        end)
    end
    closeButton.MouseButton1Click:Connect(function()
        task.spawn(hooks.OnClose)
    end)

    -- Drag the window by its header
    local dragging, dragStart, startPosition = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = card.Position
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            card.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end))

    TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.45 }):Play()
    TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = targetScale }):Play()

    return controller
end


-- State and public API
local function notify(Library, kind, title, text)
    pcall(function()
        Library.Notify[kind](title, text, 4)
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
    if not state.Unlocked then
        return false
    end
    local info = state.Info
    return not (info and info.ExpiresAt and os.time() >= info.ExpiresAt)
end

function KeySystem.GetInfo()
    return state.Info
end

-- Runs callback now when unlocked, otherwise right after a key is accepted
function KeySystem.OnUnlock(callback)
    if KeySystem.IsUnlocked() then
        pcall(callback, state.Info)
    else
        table.insert(state.Listeners, callback)
    end
end

-- Runs callback only with a valid key, otherwise tells the user
function KeySystem.Require(Library, callback)
    if KeySystem.IsUnlocked() then
        return callback()
    end
    notify(Library, "Warn", "Key required", "Enter a valid key to use this feature.")
end

-- Forget the unlock and the saved key
function KeySystem.Reset()
    state.Unlocked = false
    state.Info = nil
    if state.SavePath then
        deleteSavedKey(state.SavePath)
    end
end

--[[
    KeySystem.Run(Library, {
        Enabled = true,            -- false skips the key system (also GG.KeySystem = false)
        Title, Description,
        Service = "Remote",        -- file name in Auth/Services, a table or a function
        ServiceOptions = {},       -- given to the service as context.Options
        Keys = { "KEY-1" },        -- shortcut: a plain list of valid keys (no service needed)
        CaseSensitive = false,
        GetKeyLink = "https://...",
        SaveKey = true,
        AllowSkip = false, SkipText = "Continue without a key",
        MaxAttempts = 5, LockSeconds = 30, Timeout = 15,
        ServicesBase = "https://raw.githubusercontent.com/.../Auth/Services/",
        OnSuccess = function(info) end,
    })
    Returns true, info  when unlocked (or the key system is off)
            false, reason  when the window is closed, skipped or the service failed
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

    local service, serviceError = resolveService(config)
    if not service then
        warn("[Sora x Hikaru] key system: " .. tostring(serviceError))
        notify(Library, "Error", "Key system", tostring(serviceError))
        return false, serviceError
    end

    state.Running = true

    local folder, path = savePathFor(service.Name)
    local canRemember = config.SaveKey ~= false and writefile ~= nil
    state.SavePath = path

    local maxAttempts = config.MaxAttempts or 5
    local lockSeconds = config.LockSeconds or 30
    local attempts = 0
    local result = nil

    -- A saved key skips the window when it is still valid
    local savedStatus = nil
    local savedKey = canRemember and readSavedKey(path) or nil
    if savedKey then
        local valid, message, data = validateKey(service, savedKey, config)
        if valid then
            local info = buildInfo(savedKey, service.Name, message, data)
            markUnlocked(info, config)
            state.Running = false
            notify(Library, "Success", "Key accepted", "Saved key is valid.")
            return true, info
        end
        deleteSavedKey(path)
        savedStatus = "The saved key is no longer valid" .. (message and (": " .. message) or ".")
    end

    local link = resolveKeyLink(service, config)
    local controller

    controller = buildWindow(Library, config, link ~= nil, canRemember, {
        OnSubmit = function(key, remember)
            controller.SetBusy(true)
            controller.SetStatus("Checking key...")
            local valid, message, data = validateKey(service, key, config)
            controller.SetBusy(false)

            if valid then
                local info = buildInfo(key, service.Name, message, data)
                if remember and canRemember then
                    writeSavedKey(folder, path, key)
                end
                controller.SetStatus(message or "Key accepted.", "success")
                task.wait(0.6)
                markUnlocked(info, config)
                notify(Library, "Success", "Key accepted", message or "Features unlocked.")
                result = { ok = true, info = info }
                return
            end

            attempts += 1
            local left = maxAttempts - attempts
            if left <= 0 then
                controller.SetStatus((message or "Invalid key.") .. string.format(" Too many attempts, wait %d seconds.", lockSeconds), "error")
                controller.Lock(lockSeconds)
                attempts = 0
            else
                controller.SetStatus((message or "Invalid key.") .. string.format(" (%d attempt%s left)", left, left == 1 and "" or "s"), "error")
            end
        end,

        OnGetKey = function()
            if setclipboard then
                pcall(setclipboard, link)
                controller.SetStatus("Link copied. Open it in your browser to get a key.")
            else
                controller.SetStatus("Get your key here: " .. link)
            end
        end,

        OnSkip = function()
            result = { ok = false, reason = "skipped" }
        end,

        OnClose = function()
            result = { ok = false, reason = "closed" }
        end,
    })

    if savedStatus then
        controller.SetStatus(savedStatus, "error")
    end

    while result == nil do
        task.wait(0.1)
    end

    controller.Close()
    state.Running = false

    if result.ok then
        return true, result.info
    end
    return false, result.reason
end

return KeySystem

