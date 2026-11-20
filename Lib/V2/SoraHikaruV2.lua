--[[
    Sora x Hikaru | SoraHikaruV2.lua
    UI v2 in one file: no other V2 file is needed and nothing is downloaded while it runs.

        local V2 = loadstring(readfile("SoraHikaruV2.lua"))()      -- or loadstring(game:HttpGet(<url of this file>))()
        local Window = V2.new({ Library = Library })               -- Library (UI v1) is optional: icons and notifications
        local Combat = Window:AddTab("Combat", "swords")
        local card = Combat:AddFeature({ Name = "Auto Parry", Description = "...", Setting = true, Notification = true, Callback = function(state, source) end })

    No tabs exist until you add them with Window:AddTab(name, icon). A tab named GUI gets the Appearance section
    and a tab named Config gets the configuration buttons.
    Window:AddTab / tab:AddFeature / card:AddToggle, AddSlider, AddDropdown, AddButton, AddText, AddDivider,
    Window:Search / SetOpen / IsOpen / Show / Hide / Toggle / Minimize / Destroy, and the UI v1 style create_tab /
    create_module methods (Compat) keep their V2 behavior.
    The window is open at 698 x 479 and collapses to 150 x 40. The title bar (logo and name), the floating logo
    button and the toggle key (Insert) all switch the same state.
    V2.new options: Library, Folder, Preset ("Dark" | "Light" | "Pure Black" | "Midnight"), Title, Version,
    Categories (optional list of { name, icon } to create at start), ToggleKey, NotificationSoundId, Transparency,
    Logo, GalacticText.
]]

local modules = {}

modules.Janitor = (function()
-- Lib/V2/Janitor.lua
-- Collects things that must be cleaned up together (connections, instances, functions, threads).

local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
    return setmetatable({ _items = {} }, Janitor)
end

local function member(item, name)
    local ok, value = pcall(function()
        return item[name]
    end)
    if ok then
        return value
    end
    return nil
end

local function release(item)
    local kind = type(item)
    if kind == "function" then
        item()
    elseif kind == "thread" then
        task.cancel(item)
    elseif kind == "table" or kind == "userdata" then
        if member(item, "Destroy") then
            item:Destroy()
        elseif member(item, "Disconnect") then
            item:Disconnect()
        end
    end
end

-- Returns the item so it can be written as: local connection = janitor:Add(signal:Connect(...))
function Janitor:Add(item)
    if item ~= nil then
        table.insert(self._items, item)
    end
    return item
end

function Janitor:Connect(signal, handler)
    return self:Add(signal:Connect(handler))
end

-- Runs everything in reverse order. A failing item does not stop the others.
function Janitor:Cleanup()
    local failures = 0
    while #self._items > 0 do
        local item = table.remove(self._items)
        if not pcall(release, item) then
            failures = failures + 1
        end
    end
    return failures
end

function Janitor:Count()
    return #self._items
end

return Janitor
end)()

modules.Store = (function()
-- Lib/V2/Store.lua
-- One JSON file with everything v2 remembers: theme, per-feature settings, window and button positions.
-- Writes are delayed a moment so dragging or typing does not hit the disk on every change.

local Store = {}
Store.__index = Store

local function copyValue(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, inner in pairs(value) do
        result[key] = copyValue(inner)
    end
    return result
end

local function splitPath(path)
    local parts = {}
    for part in string.gmatch(path, "[^%.]+") do
        parts[#parts + 1] = part
    end
    return parts
end

-- options: Path ("Folder/v2.json"), Json = { Encode, Decode } (default: HttpService), Fs = { isfile, readfile,
-- writefile, makefolder, isfolder } (default: executor functions), Delay = function(seconds, fn) (default task.delay),
-- Debounce (seconds, default 1)
function Store.new(options)
    local self = setmetatable({}, Store)
    self._path = options.Path
    self._folder = string.match(options.Path, "^(.*)/[^/]+$")
    self._debounce = options.Debounce or 1
    self._delay = options.Delay or task.delay
    self._fs = options.Fs or {
        isfile = isfile,
        readfile = readfile,
        writefile = writefile,
        makefolder = makefolder,
        isfolder = isfolder,
    }

    if options.Json then
        self._json = options.Json
    else
        local http = game:GetService("HttpService")
        self._json = {
            Encode = function(value) return http:JSONEncode(value) end,
            Decode = function(text) return http:JSONDecode(text) end,
        }
    end

    self._data = {}
    self._dirty = false
    self._scheduled = false
    self._destroyed = false
    self:Load()
    return self
end

function Store:Available()
    return type(self._fs.writefile) == "function" and type(self._fs.readfile) == "function" and type(self._fs.isfile) == "function"
end

-- Reads the file. A missing or unreadable file starts empty and never raises.
function Store:Load()
    self._data = {}
    if not self:Available() then
        return false
    end

    local ok, text = pcall(function()
        if self._fs.isfile(self._path) then
            return self._fs.readfile(self._path)
        end
    end)
    if not ok or type(text) ~= "string" or text == "" then
        return false
    end

    local decoded, value = pcall(self._json.Decode, text)
    if decoded and type(value) == "table" then
        self._data = value
        return true
    end
    return false
end

function Store:Get(path, default)
    local node = self._data
    for _, part in ipairs(splitPath(path)) do
        if type(node) ~= "table" then
            return default
        end
        node = node[part]
    end
    if node == nil then
        return default
    end
    return copyValue(node)
end

function Store:Set(path, value)
    local parts = splitPath(path)
    local node = self._data
    for index = 1, #parts - 1 do
        local part = parts[index]
        if type(node[part]) ~= "table" then
            node[part] = {}
        end
        node = node[part]
    end
    node[parts[#parts]] = copyValue(value)
    self:_markDirty()
end

function Store:Delete(path)
    self:Set(path, nil)
end

function Store:_markDirty()
    self._dirty = true
    if self._scheduled or self._destroyed then
        return
    end
    self._scheduled = true
    self._delay(self._debounce, function()
        self._scheduled = false
        if self._dirty then
            self:Flush()
        end
    end)
end

-- Writes now. Returns true when the file was written.
function Store:Flush()
    if not self._dirty then
        return true
    end
    if not self:Available() then
        return false
    end

    local encoded, text = pcall(self._json.Encode, self._data)
    if not encoded then
        return false
    end

    local ok = pcall(function()
        local fs = self._fs
        if self._folder and fs.makefolder and fs.isfolder and not fs.isfolder(self._folder) then
            fs.makefolder(self._folder)
        end
        fs.writefile(self._path, text)
    end)
    if ok then
        self._dirty = false
    end
    return ok
end

-- Flushes and stops scheduling
function Store:Destroy()
    self._destroyed = true
    self:Flush()
end

return Store
end)()

modules.Theme = (function()
-- Lib/V2/Theme.lua
-- The six colors every part of the interface is painted with. Changing one notifies every subscriber,
-- so the whole interface updates at once.

local Theme = {}
Theme.__index = Theme

Theme.Keys = { "MainColor", "Secondary", "Accent", "Stroke", "Text", "SubText" }

local validKeys = {}
for _, key in ipairs(Theme.Keys) do
    validKeys[key] = true
end

-- Hex strings, so presets can be stored and edited as plain text.
-- Dark and Light are the UI v1 palettes (Dark is the default).
Theme.Presets = {
    Dark = {
        MainColor = "#0C0D0F",
        Secondary = "#161C26",
        Accent = "#98B5FF",
        Stroke = "#344259",
        Text = "#FFFFFF",
        SubText = "#98B5FF",
    },
    Light = {
        MainColor = "#F5F7FA",
        Secondary = "#FFFFFF",
        Accent = "#6366F1",
        Stroke = "#DCE1EB",
        Text = "#1E1E28",
        SubText = "#5A5A6E",
    },
    ["Pure Black"] = {
        MainColor = "#060607",
        Secondary = "#121214",
        Accent = "#E23E3E",
        Stroke = "#28282C",
        Text = "#F0F0F4",
        SubText = "#96969F",
    },
    Midnight = {
        MainColor = "#0E0E16",
        Secondary = "#14141E",
        Accent = "#6C70F0",
        Stroke = "#2D3042",
        Text = "#ECECF6",
        SubText = "#9698B8",
    },
}
Theme.DefaultPreset = "Dark"

function Theme.toHex(color)
    local function channel(value)
        return math.floor(value * 255 + 0.5)
    end
    return string.format("#%02X%02X%02X", channel(color.R), channel(color.G), channel(color.B))
end

-- Returns a Color3, or nil when the text is not #RRGGBB
function Theme.fromHex(hex)
    if type(hex) ~= "string" then
        return nil
    end
    local red, green, blue = string.match(hex, "^#?(%x%x)(%x%x)(%x%x)$")
    if not red then
        return nil
    end
    return Color3.fromRGB(tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16))
end

-- Mix two colors: amount 0 = a, 1 = b
function Theme.mix(a, b, amount)
    return Color3.new(
        a.R + (b.R - a.R) * amount,
        a.G + (b.G - a.G) * amount,
        a.B + (b.B - a.B) * amount
    )
end

-- options: Store (Lib/V2/Store.lua, optional), Preset (name, default "Pure Black")
function Theme.new(options)
    options = options or {}
    local self = setmetatable({}, Theme)
    self._store = options.Store
    self._listeners = {}
    self._colors = {}
    self._preset = Theme.Presets[options.Preset] and options.Preset or Theme.DefaultPreset

    self:_applyPreset(self._preset)

    -- Saved colors win over the preset
    local saved = self._store and self._store:Get("theme")
    if type(saved) == "table" then
        if Theme.Presets[saved.Preset] then
            self._preset = saved.Preset
        end
        for _, key in ipairs(Theme.Keys) do
            local color = Theme.fromHex(saved[key])
            if color then
                self._colors[key] = color
            end
        end
    end
    return self
end

function Theme:_applyPreset(name)
    for _, key in ipairs(Theme.Keys) do
        self._colors[key] = Theme.fromHex(Theme.Presets[name][key])
    end
end

function Theme:_save()
    if not self._store then
        return
    end
    local record = { Preset = self._preset }
    for _, key in ipairs(Theme.Keys) do
        record[key] = Theme.toHex(self._colors[key])
    end
    self._store:Set("theme", record)
end

function Theme:_notify(key)
    for _, listener in ipairs({ table.unpack(self._listeners) }) do
        pcall(listener, key, self._colors[key])
    end
end

function Theme:Get(key)
    return self._colors[key]
end

function Theme:GetAll()
    local copy = {}
    for key, color in pairs(self._colors) do
        copy[key] = color
    end
    return copy
end

function Theme:GetPreset()
    return self._preset
end

-- Changes one color and repaints. Returns false for an unknown key or a value that is not a color.
function Theme:Set(key, color)
    if not validKeys[key] or type(color) ~= "userdata" and type(color) ~= "table" then
        return false
    end
    if color.R == nil or color.G == nil or color.B == nil then
        return false
    end
    self._colors[key] = color
    self:_save()
    self:_notify(key)
    return true
end

function Theme:SetPreset(name)
    if not Theme.Presets[name] then
        return false
    end
    self._preset = name
    self:_applyPreset(name)
    self:_save()
    for _, key in ipairs(Theme.Keys) do
        self:_notify(key)
    end
    return true
end

function Theme:Reset()
    return self:SetPreset(self._preset)
end

-- listener(key, color). Returns a function that removes the listener.
function Theme:Subscribe(listener)
    table.insert(self._listeners, listener)
    return function()
        for index, value in ipairs(self._listeners) do
            if value == listener then
                table.remove(self._listeners, index)
                return
            end
        end
    end
end

return Theme
end)()

modules.Feature = (function()
-- Lib/V2/Feature.lua
-- Everything a feature does, without any UI: the main state, per-feature settings, notification rules,
-- keybind behaviour (toggle / hold) and what is saved. The three parts stay independent:
-- the main toggle, the settings and the notification options never depend on each other.

local Feature = {}
Feature.__index = Feature

local defaultNotifications = { Enabled = true, OnEnabled = true, OnDisabled = true, Sound = false, Duration = 3 }
local activationModes = { Toggle = true, Hold = true }
local startupStates = { On = true, Off = true }

local function copyValue(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, inner in pairs(value) do
        result[key] = copyValue(inner)
    end
    return result
end

local function sanitize(text)
    return (string.gsub(string.lower(tostring(text)), "[^%w]+", "_"))
end

-- Rows the settings panel can show. A feature turns them on with Settings = { Keybind = true, ... }.
local defaultSettingRows = {
    { Id = "Keybind", Type = "Keybind", Name = "Keybind" },
    { Id = "ActivationMode", Type = "Segmented", Name = "Activation Mode", Options = { "Toggle", "Hold" } },
    { Id = "StartupState", Type = "Segmented", Name = "Startup State", Options = { "On", "Off" } },
    { Id = "ShowStatus", Type = "Toggle", Name = "Show Status" },
    { Id = "ShowButton", Type = "Toggle", Name = "Show Button" },
    { Id = "Reset", Type = "Button", Name = "Reset Settings" },
}

local defaultRowIds = {}
for _, row in ipairs(defaultSettingRows) do
    defaultRowIds[row.Id] = true
end

local notificationRows = {
    { Id = "Enabled", Type = "Toggle", Name = "Enabled" },
    { Id = "OnEnabled", Type = "Toggle", Name = "On Enabled" },
    { Id = "OnDisabled", Type = "Toggle", Name = "On Disabled" },
    { Id = "Sound", Type = "Toggle", Name = "Sound" },
    { Id = "Duration", Type = "Slider", Name = "Duration", Min = 1, Max = 10, Step = 0.5 },
}

-- def: { Id, Name, Description, DefaultState, Callback(state, source), Setting, Notification,
--        Settings = { Keybind, ActivationMode, StartupState, ShowStatus, ShowButton, Reset, Custom = { rows } },
--        Notifications = { Enabled, OnEnabled, OnDisabled, Sound, Duration } }
-- deps: Store (optional), Notify(title, text, duration, sound, state) (optional)
function Feature.new(def, deps)
    deps = deps or {}
    local self = setmetatable({}, Feature)

    self.Name = def.Name or "Feature"
    self.Id = sanitize(def.Id or self.Name)
    self.Description = def.Description or ""
    self.HasSettingsButton = def.Setting == true
    self.HasNotificationButton = def.Notification == true

    self._callback = def.Callback
    self._store = deps.Store
    self._notify = deps.Notify
    self._listeners = {}
    self._state = false
    self._storePath = "features." .. self.Id

    -- Which default rows the settings panel shows, and the feature specific rows
    local requested = def.Settings
    if requested == nil and def.Setting == true then
        requested = { Keybind = true, ActivationMode = true, StartupState = true, ShowStatus = true, ShowButton = true, Reset = true }
    end
    requested = requested or {}
    self._rows = {}
    for _, row in ipairs(defaultSettingRows) do
        if requested[row.Id] then
            self._rows[#self._rows + 1] = copyValue(row)
        end
    end
    self._customIds = {}
    for _, row in ipairs(requested.Custom or def.Custom or {}) do
        if defaultRowIds[row.Id] or self._customIds[row.Id] then
            warn("[Sora x Hikaru] feature '" .. self.Name .. "': custom setting id '" .. tostring(row.Id) .. "' is already used and was skipped")
        else
            self._customIds[row.Id] = true
            self._rows[#self._rows + 1] = copyValue(row)
        end
    end

    -- Defaults
    self._defaults = {
        Keybind = def.Keybind,
        ActivationMode = "Toggle",
        StartupState = def.DefaultState and "On" or "Off",
        ShowStatus = true,
        ShowButton = false,
        Custom = {},
    }
    for _, row in ipairs(self._rows) do
        if self._customIds[row.Id] then
            self._defaults.Custom[row.Id] = copyValue(row.Default)
        end
    end
    self._notificationDefaults = {}
    for key, value in pairs(defaultNotifications) do
        self._notificationDefaults[key] = value
    end
    for key, value in pairs(def.Notifications or {}) do
        if defaultNotifications[key] ~= nil then
            self._notificationDefaults[key] = value
        end
    end

    self._settings = copyValue(self._defaults)
    self._notifications = copyValue(self._notificationDefaults)
    self:_loadSaved()
    return self
end

function Feature:_loadSaved()
    local saved = self._store and self._store:Get(self._storePath)
    if type(saved) ~= "table" then
        return
    end

    local settings = saved.Settings
    if type(settings) == "table" then
        if type(settings.Keybind) == "string" then
            self._settings.Keybind = settings.Keybind
        elseif settings.Keybind == false then
            self._settings.Keybind = nil
        end
        if activationModes[settings.ActivationMode] then
            self._settings.ActivationMode = settings.ActivationMode
        end
        if startupStates[settings.StartupState] then
            self._settings.StartupState = settings.StartupState
        end
        if type(settings.ShowStatus) == "boolean" then
            self._settings.ShowStatus = settings.ShowStatus
        end
        if type(settings.ShowButton) == "boolean" then
            self._settings.ShowButton = settings.ShowButton
        end
        if type(settings.Custom) == "table" then
            for id in pairs(self._customIds) do
                if settings.Custom[id] ~= nil then
                    self._settings.Custom[id] = settings.Custom[id]
                end
            end
        end
    end

    local notifications = saved.Notifications
    if type(notifications) == "table" then
        for key, default in pairs(defaultNotifications) do
            if type(notifications[key]) == type(default) then
                self._notifications[key] = notifications[key]
            end
        end
    end
end

function Feature:_save()
    if not self._store then
        return
    end
    self._store:Set(self._storePath, {
        Settings = {
            Keybind = self._settings.Keybind or false,
            ActivationMode = self._settings.ActivationMode,
            StartupState = self._settings.StartupState,
            ShowStatus = self._settings.ShowStatus,
            ShowButton = self._settings.ShowButton,
            Custom = self._settings.Custom,
        },
        Notifications = self._notifications,
    })
end

function Feature:_emit(eventName, ...)
    for _, listener in ipairs({ table.unpack(self._listeners) }) do
        pcall(listener, eventName, ...)
    end
end

-- listener(eventName, ...) with events: "state"(state, source), "setting"(id, value),
-- "notification"(id, value), "reset"(). Returns a function that removes the listener.
function Feature:Subscribe(listener)
    table.insert(self._listeners, listener)
    return function()
        for index, value in ipairs(self._listeners) do
            if value == listener then
                table.remove(self._listeners, index)
                return
            end
        end
    end
end

-- State ---------------------------------------------------------------

function Feature:GetState()
    return self._state
end

-- source: "toggle", "keybind", "startup", "api". Returns true when the state changed.
function Feature:SetState(state, source)
    state = state and true or false
    if state == self._state then
        return false
    end
    self._state = state
    source = source or "api"

    if self._callback then
        local ok, err = pcall(self._callback, state, source)
        if not ok then
            warn("[Sora x Hikaru] feature '" .. self.Name .. "' callback failed: " .. tostring(err))
        end
    end
    self:_emit("state", state, source)

    -- Notification rules only decide whether a message is shown, never the state itself
    local options = self._notifications
    local wanted = options.Enabled and ((state and options.OnEnabled) or (not state and options.OnDisabled))
    if wanted and source ~= "startup" and self._notify then
        pcall(self._notify, self.Name, state and "Enabled" or "Disabled", options.Duration, options.Sound, state)
    end
    return true
end

function Feature:Toggle(source)
    return self:SetState(not self._state, source or "toggle")
end

-- Applies the startup state once, when the interface is built
function Feature:Start()
    if self._settings.StartupState == "On" then
        self:SetState(true, "startup")
    end
end

-- Keybind pressed (isDown = true) or released. Toggle mode flips on press, Hold mode follows the key.
function Feature:PressKey(isDown)
    if self._settings.ActivationMode == "Hold" then
        self:SetState(isDown, "keybind")
    elseif isDown then
        self:SetState(not self._state, "keybind")
    end
end

-- Settings ------------------------------------------------------------

-- Rows for the settings panel, each with its current value. The panel only draws what is listed here.
function Feature:GetSettingsSchema()
    local schema = {}
    for _, row in ipairs(self._rows) do
        local entry = copyValue(row)
        if self._customIds[row.Id] then
            entry.Value = self._settings.Custom[row.Id]
        elseif row.Id ~= "Reset" then
            entry.Value = self._settings[row.Id]
        end
        schema[#schema + 1] = entry
    end
    return schema
end

function Feature:GetNotificationSchema()
    local schema = {}
    for _, row in ipairs(notificationRows) do
        local entry = copyValue(row)
        entry.Value = self._notifications[row.Id]
        schema[#schema + 1] = entry
    end
    return schema
end

function Feature:GetSetting(id)
    if self._customIds[id] then
        return self._settings.Custom[id]
    end
    return self._settings[id]
end

local function findRow(rows, id)
    for _, row in ipairs(rows) do
        if row.Id == id then
            return row
        end
    end
    return nil
end

-- Returns true when the value was accepted
function Feature:SetSetting(id, value)
    if self._customIds[id] then
        local custom = findRow(self._rows, id)
        self._settings.Custom[id] = value
        if type(custom.Callback) == "function" then
            pcall(custom.Callback, value)
        end
    elseif id == "Keybind" then
        if value ~= nil and type(value) ~= "string" then
            return false
        end
        self._settings.Keybind = value
    elseif id == "ActivationMode" then
        if not activationModes[value] then
            return false
        end
        self._settings.ActivationMode = value
    elseif id == "StartupState" then
        if not startupStates[value] then
            return false
        end
        self._settings.StartupState = value
    elseif id == "ShowStatus" or id == "ShowButton" then
        if type(value) ~= "boolean" then
            return false
        end
        self._settings[id] = value
    else
        return false
    end

    self:_save()
    self:_emit("setting", id, value)
    return true
end

function Feature:GetNotification(id)
    return self._notifications[id]
end

function Feature:SetNotification(id, value)
    local default = defaultNotifications[id]
    if default == nil or type(value) ~= type(default) then
        return false
    end
    if id == "Duration" then
        value = math.max(0.5, math.min(30, value))
    end
    self._notifications[id] = value
    self:_save()
    self:_emit("notification", id, value)
    return true
end

-- Restores the settings (not the notification options and not the current state)
function Feature:ResetSettings()
    self._settings = copyValue(self._defaults)
    self:_save()
    self:_emit("reset")
    for id in pairs(self._customIds) do
        local row = findRow(self._rows, id)
        if type(row.Callback) == "function" then
            pcall(row.Callback, self._settings.Custom[id])
        end
    end
end

function Feature:ResetNotifications()
    self._notifications = copyValue(self._notificationDefaults)
    self:_save()
    self:_emit("reset")
end

-- Keybind router -----------------------------------------------------
-- One input connection for the whole window: it asks the router which features own the key.

local Router = {}
Router.__index = Router
Feature.Router = Router

function Router.new()
    return setmetatable({ _features = {} }, Router)
end

function Router:Register(feature)
    table.insert(self._features, feature)
end

function Router:Unregister(feature)
    for index, value in ipairs(self._features) do
        if value == feature then
            table.remove(self._features, index)
            return
        end
    end
end

-- Returns how many features reacted
function Router:Handle(keyName, isDown)
    local count = 0
    for _, feature in ipairs({ table.unpack(self._features) }) do
        if feature._settings.Keybind == keyName then
            feature:PressKey(isDown)
            count = count + 1
        end
    end
    return count
end

return Feature
end)()

modules.Components = (function()
local Components = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local fontFamily = "rbxasset://fonts/families/GothamSSm.json"
local arrowImage = "rbxassetid://84232453189324"

local function merge(defaults, overrides)
    local result = {}
    for key, value in pairs(defaults) do
        result[key] = value
    end
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end
Components.merge = merge

-- Same typeface family as UI v1
function Components.font(weight)
    return Font.new(fontFamily, weight or Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
end
local font = Components.font

function Components.create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end
local create = Components.create

function Components.tween(instance, properties, seconds)
    TweenService:Create(instance, TweenInfo.new(seconds or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties):Play()
end
local tween = Components.tween

-- Same context with another janitor (one per card or panel, so closing it cleans only its own widgets)
function Components.child(ctx, janitor)
    local copy = {}
    for key, value in pairs(ctx) do
        copy[key] = value
    end
    copy.Janitor = janitor
    return copy
end

function Components.contrast(color)
    local brightness = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
    return brightness > 0.6 and Color3.fromRGB(12, 12, 14) or Color3.fromRGB(255, 255, 255)
end
local contrast = Components.contrast

-- bindings: { Property = "ThemeKey" | function(theme) return value end }. Repaints on every theme change.
function Components.bind(ctx, instance, bindings)
    local function paint()
        for property, source in pairs(bindings) do
            if type(source) == "function" then
                instance[property] = source(ctx.Theme)
            else
                instance[property] = ctx.Theme:Get(source)
            end
        end
    end
    paint()
    ctx.Janitor:Add(ctx.Theme:Subscribe(paint))
end
local bind = Components.bind

function Components.corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

function Components.stroke(ctx, parent, key, transparency)
    local stroke = create("UIStroke", {
        Thickness = 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
    bind(ctx, stroke, { Color = key or "Stroke" })
    return stroke
end


-- Text uses the v1 typeface unless the caller picks Font / FontFace itself
function Components.label(ctx, parent, properties, colorKey)
    local merged = merge({
        BackgroundTransparency = 1,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "",
    }, properties)
    if merged.Font == nil and merged.FontFace == nil then
        merged.FontFace = font()
    end
    local label = create("TextLabel", merged, parent)
    bind(ctx, label, { TextColor3 = colorKey or "Text" })
    return label
end

-- Lucide icon by name; a text fallback is drawn when the icon library is not available
function Components.icon(ctx, parent, properties)
    local size = properties.Size or 16
    local colorKey = properties.Color or "SubText"

    local image = create("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = properties.AnchorPoint,
        Position = properties.Position,
        Size = UDim2.fromOffset(size, size),
        ScaleType = Enum.ScaleType.Fit,
    }, parent)

    if ctx.ApplyIcon(image, properties.Name) then
        bind(ctx, image, { ImageColor3 = colorKey })
        return image
    end

    image:Destroy()
    local fallback = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = properties.AnchorPoint,
        Position = properties.Position,
        Size = UDim2.fromOffset(size, size),
        FontFace = font(Enum.FontWeight.Bold),
        TextSize = size - 2,
        Text = properties.Fallback or "",
    }, parent)
    bind(ctx, fallback, { TextColor3 = colorKey })
    return fallback
end

-- Icon button (gear, bell...). properties: Icon, Fallback, Size, OnClick
function Components.iconButton(ctx, parent, properties)
    local size = properties.Size or 26
    local button = create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(size, size),
    }, parent)

    local icon = Components.icon(ctx, button, {
        Name = properties.Icon,
        Fallback = properties.Fallback,
        Size = size - 10,
        Color = "SubText",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
    })

    local function setHover(hovered)
        local color = ctx.Theme:Get(hovered and "Text" or "SubText")
        if icon:IsA("ImageLabel") then
            tween(icon, { ImageColor3 = color }, 0.2)
        else
            tween(icon, { TextColor3 = color }, 0.2)
        end
    end
    ctx.Janitor:Connect(button.MouseEnter, function() setHover(true) end)
    ctx.Janitor:Connect(button.MouseLeave, function() setHover(false) end)
    ctx.Janitor:Connect(button.MouseButton1Click, function()
        if properties.OnClick then
            properties.OnClick()
        end
    end)
    return button
end

-- On/off switch drawn like the v1 module toggle: a dim track and a round knob that takes the accent color.
-- properties: Value, OnChanged(state). Returns { Instance, Set(value, silent), Get() }
function Components.switch(ctx, parent, properties)
    local state = properties.Value == true

    local track = create("TextButton", {
        Name = "Switch",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(30, 15),
    }, parent)
    Components.corner(track, 8)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 0.2,
        Size = UDim2.fromOffset(15, 15),
        BorderSizePixel = 0,
    }, track)
    Components.corner(knob, 8)

    local function paint(animate)
        local theme = ctx.Theme
        local accent = theme:Get("Accent")
        local trackColor = state and accent or Color3.new(0, 0, 0)
        local knobColor = state and accent or ctx.Mix(theme:Get("Stroke"), accent, 0.2)
        local position = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)

        if animate then
            tween(track, { BackgroundColor3 = trackColor }, 0.4)
            tween(knob, { Position = position, BackgroundColor3 = knobColor }, 0.4)
        else
            track.BackgroundColor3 = trackColor
            knob.Position = position
            knob.BackgroundColor3 = knobColor
        end
    end
    paint(false)
    ctx.Janitor:Add(ctx.Theme:Subscribe(function()
        paint(false)
    end))

    local handle = { Instance = track }

    function handle.Set(value, silent)
        value = value == true
        if value == state then
            return
        end
        state = value
        paint(true)
        if not silent and properties.OnChanged then
            properties.OnChanged(state)
        end
    end

    function handle.Get()
        return state
    end

    ctx.Janitor:Connect(track.MouseButton1Click, function()
        handle.Set(not state)
    end)
    return handle
end

-- Slider with the v1 look: a thin accent track, a soft fill and a small knob.
-- properties: Min, Max, Step, Value, OnChanged(value), OnDone(value). Returns { Instance, Set(value, silent), Get() }
function Components.slider(ctx, parent, properties)
    local minimum = properties.Min or 0
    local maximum = properties.Max or 100
    local step = properties.Step
    local value = math.clamp(properties.Value or minimum, minimum, maximum)

    local holder = create("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1 }, parent)
    local bar = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
    }, holder)
    Components.corner(bar, 2)
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundTransparency = 0.5, BorderSizePixel = 0 }, bar)
    Components.corner(fill, 2)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        BorderSizePixel = 0,
    }, bar)
    Components.corner(knob, 4)

    bind(ctx, bar, { BackgroundColor3 = "Accent" })
    bind(ctx, fill, { BackgroundColor3 = "Accent" })
    bind(ctx, knob, { BackgroundColor3 = "Text" })

    local function render()
        local fraction = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
        tween(fill, { Size = UDim2.fromScale(fraction, 1) }, 0.2)
        tween(knob, { Position = UDim2.fromScale(fraction, 0.5) }, 0.2)
    end
    render()

    local handle = { Instance = holder }

    function handle.Set(newValue, silent)
        newValue = math.clamp(newValue, minimum, maximum)
        if step and step > 0 then
            newValue = math.clamp(math.floor(newValue / step + 0.5) * step, minimum, maximum)
        end
        if newValue == value then
            return
        end
        value = newValue
        render()
        if not silent and properties.OnChanged then
            properties.OnChanged(value)
        end
    end

    function handle.Get()
        return value
    end

    local dragging = false
    local function fromInput(position)
        local fraction = math.clamp((position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        handle.Set(minimum + (maximum - minimum) * fraction)
    end

    ctx.Janitor:Connect(holder.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromInput(input.Position)
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input.Position)
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if properties.OnDone then
                properties.OnDone(value)
            end
        end
    end)
    return handle
end

-- Row of options with one selected. properties: Options, Value, OnChanged(option)
function Components.segmented(ctx, parent, properties)
    local frame = create("Frame", {
        Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
    }, parent)
    Components.corner(frame, 4)
    bind(ctx, frame, { BackgroundColor3 = "Accent" })
    create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
    create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, frame)

    local value = properties.Value
    local buttons = {}

    local function paint()
        for option, button in pairs(buttons) do
            local selected = option == value
            local accent = ctx.Theme:Get("Accent")
            button.BackgroundTransparency = selected and 0.7 or 1
            button.BackgroundColor3 = accent
            button.TextColor3 = ctx.Theme:Get("Text")
            button.TextTransparency = selected and 0.1 or 0.6
        end
    end

    for index, option in ipairs(properties.Options) do
        local button = create("TextButton", {
            AutoButtonColor = false,
            Size = UDim2.fromOffset(0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            BorderSizePixel = 0,
            FontFace = font(),
            TextSize = 10,
            Text = tostring(option),
            LayoutOrder = index,
        }, frame)
        Components.corner(button, 3)
        create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, button)
        buttons[option] = button
        ctx.Janitor:Connect(button.MouseButton1Click, function()
            if value ~= option then
                value = option
                paint()
                if properties.OnChanged then
                    properties.OnChanged(option)
                end
            end
        end)
    end
    paint()
    ctx.Janitor:Add(ctx.Theme:Subscribe(paint))

    local handle = { Instance = frame }
    function handle.Set(option)
        value = option
        paint()
    end
    return handle
end

-- Dropdown with the v1 look; the options open inside the same box. properties: Options, Value, OnChanged(option)
function Components.dropdown(ctx, parent, properties)
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    Components.corner(box, 4)
    bind(ctx, box, { BackgroundColor3 = "Accent" })
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, box)

    local header = create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        LayoutOrder = 1,
    }, box)
    local current = Components.label(ctx, header, {
        Position = UDim2.new(0.05, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0.8, 0, 0, 13),
        TextSize = 10,
        TextTransparency = 0.2,
        Text = tostring(properties.Value or ""),
    })
    local arrow = create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0.91, 0.5),
        Size = UDim2.fromOffset(8, 8),
        BackgroundTransparency = 1,
        Image = arrowImage,
    }, header)

    local list = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 2,
    }, box)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingBottom = UDim.new(0, 4) }, list)

    local value = properties.Value
    local optionLabels = {}

    local function paintOptions()
        for option, label in pairs(optionLabels) do
            label.TextTransparency = option == value and 0.2 or 0.6
        end
    end

    local function setOpen(open)
        list.Visible = open
        tween(arrow, { Rotation = open and 180 or 0 }, 0.3)
    end

    for index, option in ipairs(properties.Options) do
        local item = create("TextButton", {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            FontFace = font(),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(option),
            LayoutOrder = index,
        }, list)
        bind(ctx, item, { TextColor3 = "Text" })
        optionLabels[option] = item
        ctx.Janitor:Connect(item.MouseButton1Click, function()
            value = option
            current.Text = tostring(option)
            paintOptions()
            setOpen(false)
            if properties.OnChanged then
                properties.OnChanged(option)
            end
        end)
    end
    paintOptions()

    ctx.Janitor:Connect(header.MouseButton1Click, function()
        setOpen(not list.Visible)
    end)

    local handle = { Instance = box }
    function handle.Set(option)
        value = option
        current.Text = tostring(option)
        paintOptions()
    end
    return handle
end

-- Records a key, shown as a v1 keybind chip. Backspace or Escape clears it.
-- properties: Value (key name or nil), OnChanged(keyName or nil)
function Components.keybind(ctx, parent, properties)
    local current = properties.Value
    local listening = false

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(72, 20),
        FontFace = font(),
        TextSize = 10,
    }, parent)
    Components.corner(button, 3)
    bind(ctx, button, { BackgroundColor3 = "Accent", TextColor3 = "Text" })

    local function show()
        button.Text = listening and "..." or (current or "None")
    end
    show()

    ctx.Janitor:Connect(button.MouseButton1Click, function()
        if listening then
            return
        end
        listening = true
        ctx.State.Capturing = true
        show()

        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode == Enum.KeyCode.Unknown then
                return
            end
            connection:Disconnect()
            listening = false
            -- the router sees this same key press: keep ignoring input until the frame is over
            task.defer(function()
                ctx.State.Capturing = false
            end)

            if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                current = nil
            else
                current = input.KeyCode.Name
            end
            show()
            if properties.OnChanged then
                properties.OnChanged(current)
            end
        end)
        ctx.Janitor:Add(connection)
    end)

    local handle = { Instance = button }
    function handle.Set(keyName)
        current = keyName
        show()
    end
    return handle
end

-- Text button in the v1 style: a soft accent fill that becomes solid on hover. properties: Text, OnClick, Primary
function Components.button(ctx, parent, properties)
    local button = create("TextButton", {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26),
        FontFace = font(Enum.FontWeight.Bold),
        TextSize = 12,
        Text = properties.Text or "Button",
        BackgroundTransparency = properties.Primary and 0 or 0.15,
    }, parent)
    Components.corner(button, 6)
    if properties.Primary then
        bind(ctx, button, {
            BackgroundColor3 = "Accent",
            TextColor3 = function(theme) return contrast(theme:Get("Accent")) end,
        })
    else
        bind(ctx, button, { BackgroundColor3 = "Accent", TextColor3 = "Text" })
        Components.stroke(ctx, button, "Accent", 0.6)
    end

    ctx.Janitor:Connect(button.MouseEnter, function()
        tween(button, { BackgroundTransparency = properties.Primary and 0.1 or 0 }, 0.2)
    end)
    ctx.Janitor:Connect(button.MouseLeave, function()
        tween(button, { BackgroundTransparency = properties.Primary and 0 or 0.15 }, 0.2)
    end)
    ctx.Janitor:Connect(button.MouseButton1Click, function()
        if properties.OnClick then
            properties.OnClick()
        end
    end)
    return button
end

-- Drag `target` by grabbing `handle`. onDrop(position) runs when the drag ends.
function Components.draggable(ctx, handle, target, onDrop)
    local dragStart, startPosition = nil, nil

    ctx.Janitor:Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPosition = target.Position
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputChanged, function(input)
        if not dragStart then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputEnded, function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragStart = nil
            if onDrop then
                onDrop(target.Position)
            end
        end
    end)
end

return Components
end)()

modules.ColorPicker = (function()
-- Lib/V2/ColorPicker.lua
-- Expandable color picker: 2D saturation/value area, hue slider and a preview swatch.
-- ColorPicker.new builds the picker itself, ColorPicker.row builds an Appearance row that expands to it.

local ColorPicker = {}

local UserInputService = game:GetService("UserInputService")

-- properties: Value (Color3), OnChanged(color). Returns { Instance, Set(color) }
function ColorPicker.new(ctx, parent, properties)
    local Components = ctx.Components
    local create = Components.create

    local hue, saturation, value = properties.Value:ToHSV()

    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, parent)
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, holder)

    local area = create("Frame", {
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, holder)
    Components.corner(area, 8)

    local whiteLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, area)
    Components.corner(whiteLayer, 8)
    create("UIGradient", {
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
    }, whiteLayer)

    local blackLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, area)
    Components.corner(blackLayer, 8)
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
    }, blackLayer)

    local areaKnob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, area)
    Components.corner(areaKnob, 6)
    create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5 }, areaKnob)

    local hueBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, holder)
    Components.corner(hueBar, 7)
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
    }, hueBar)

    local hueKnob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(6, 20),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, hueBar)
    Components.corner(hueKnob, 3)
    create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }, hueKnob)

    local function render()
        area.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        areaKnob.Position = UDim2.fromScale(saturation, 1 - value)
        hueKnob.Position = UDim2.fromScale(hue, 0.5)
    end
    render()

    local function announce()
        if properties.OnChanged then
            properties.OnChanged(Color3.fromHSV(hue, saturation, value))
        end
    end

    local mode = nil
    local function update(position)
        if mode == "area" then
            saturation = math.clamp((position.X - area.AbsolutePosition.X) / math.max(area.AbsoluteSize.X, 1), 0, 1)
            value = 1 - math.clamp((position.Y - area.AbsolutePosition.Y) / math.max(area.AbsoluteSize.Y, 1), 0, 1)
        elseif mode == "hue" then
            hue = math.clamp((position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
        else
            return
        end
        render()
        announce()
    end

    local function isPress(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end

    ctx.Janitor:Connect(area.InputBegan, function(input)
        if isPress(input) then
            mode = "area"
            update(input.Position)
        end
    end)
    ctx.Janitor:Connect(hueBar.InputBegan, function(input)
        if isPress(input) then
            mode = "hue"
            update(input.Position)
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputChanged, function(input)
        if mode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position)
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputEnded, function(input)
        if mode and isPress(input) then
            mode = nil
        end
    end)

    local handle = { Instance = holder }
    function handle.Set(color)
        hue, saturation, value = color:ToHSV()
        render()
    end
    return handle
end

-- Appearance row: name, chevron and swatch. Clicking it expands the picker; only one row is open at a time.
-- properties: Name, Key (a theme color name)
function ColorPicker.row(ctx, parent, properties)
    local Components = ctx.Components
    local create = Components.create
    local theme = ctx.Theme

    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, parent)
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)

    local header = create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = 1,
    }, row)
    Components.label(ctx, header, {
        Size = UDim2.new(1, -130, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Text = properties.Name,
    })
    local chevron = Components.label(ctx, header, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -104, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Text = "v",
    }, "Accent")

    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(90, 24),
        BorderSizePixel = 0,
    }, header)
    Components.corner(swatch, 6)
    Components.stroke(ctx, swatch)

    local body = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 2,
    }, row)

    local picker = ColorPicker.new(ctx, body, {
        Value = theme:Get(properties.Key),
        OnChanged = function(color)
            theme:Set(properties.Key, color)
        end,
    })

    -- Presets or other rows can change the color: keep the swatch and the picker in step
    local function sync()
        local color = theme:Get(properties.Key)
        swatch.BackgroundColor3 = color
        picker.Set(color)
    end
    sync()
    ctx.Janitor:Add(theme:Subscribe(function(key)
        if key == properties.Key then
            sync()
        end
    end))

    local function setOpen(open)
        body.Visible = open
        chevron.Text = open and "^" or "v"
    end
    local closer = function() setOpen(false) end

    ctx.Janitor:Connect(header.MouseButton1Click, function()
        local opening = not body.Visible
        local state = ctx.State
        if opening and state.OpenColorRow and state.OpenColorRow ~= closer then
            state.OpenColorRow()
        end
        setOpen(opening)
        state.OpenColorRow = opening and closer or nil
    end)

    return row
end

return ColorPicker
end)()

modules.Panels = (function()
-- Lib/V2/Panels.lua
-- The Settings panel (gear) and the Notification panel (bell). One implementation draws both:
-- it reads the rows a feature reports (Feature:GetSettingsSchema / GetNotificationSchema), so a feature
-- with its own settings simply reports different rows.

local Panels = {}

local UserInputService = game:GetService("UserInputService")

-- ctx needs Components, NewJanitor. root is the frame the panel is shown over.
function Panels.new(ctx, root)
    local Components = ctx.Components
    local create = Components.create
    local manager = {}
    local current = nil

    function manager.Close()
        if not current then
            return
        end
        local open = current
        current = nil
        open.janitor:Cleanup()
        open.scrim:Destroy()
    end

    -- One row of the schema: name on the left and the control on the right (sliders and dropdowns go below the name)
    local function addRow(body, rowCtx, row, setValue, resetAction, order)
        local line = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order,
        }, body)
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, line)

        if row.Type == "Button" then
            Components.button(rowCtx, line, { Text = row.Name, OnClick = resetAction })
            return
        end

        local header = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 1 }, line)
        local nameLabel = Components.label(rowCtx, header, {
            Size = UDim2.new(1, -110, 1, 0),
            TextSize = 12,
            Text = row.Name,
        })

        local function dock(instance)
            instance.AnchorPoint = Vector2.new(1, 0.5)
            instance.Position = UDim2.new(1, 0, 0.5, 0)
        end

        if row.Type == "Toggle" then
            local switch = Components.switch(rowCtx, header, {
                Value = row.Value == true,
                OnChanged = function(state) setValue(row.Id, state) end,
            })
            dock(switch.Instance)
        elseif row.Type == "Keybind" then
            local keybind = Components.keybind(rowCtx, header, {
                Value = row.Value,
                OnChanged = function(keyName) setValue(row.Id, keyName) end,
            })
            dock(keybind.Instance)
        elseif row.Type == "Segmented" then
            local segmented = Components.segmented(rowCtx, header, {
                Options = row.Options,
                Value = row.Value,
                OnChanged = function(option) setValue(row.Id, option) end,
            })
            dock(segmented.Instance)
        elseif row.Type == "Slider" then
            local valueLabel = Components.label(rowCtx, header, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(60, 20),
                TextXAlignment = Enum.TextXAlignment.Right,
                Text = tostring(row.Value),
            }, "SubText")
            local slider = Components.slider(rowCtx, line, {
                Min = row.Min,
                Max = row.Max,
                Step = row.Step,
                Value = row.Value,
                OnChanged = function(number)
                    valueLabel.Text = tostring(number)
                    setValue(row.Id, number)
                end,
            })
            slider.Instance.LayoutOrder = 2
        elseif row.Type == "Dropdown" then
            local dropdown = Components.dropdown(rowCtx, line, {
                Options = row.Options,
                Value = row.Value,
                OnChanged = function(option) setValue(row.Id, option) end,
            })
            dropdown.Instance.LayoutOrder = 2
        else
            nameLabel.Text = row.Name .. " (unsupported row type " .. tostring(row.Type) .. ")"
        end
    end

    -- build(body, rowCtx) fills the body. It runs again when the feature reports "reset".
    local function open(feature, subtitle, build)
        manager.Close()

        local janitor = ctx.NewJanitor()
        local panelCtx = Components.child(ctx, janitor)

        local scrim = create("TextButton", {
            Name = "PanelScrim",
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            ZIndex = 50,
        }, root)
        current = { scrim = scrim, janitor = janitor }

        local panel = create("Frame", {
            Name = "Panel",
            Active = true,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(320, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 51,
        }, scrim)
        Components.corner(panel, 14)
        Components.bind(panelCtx, panel, { BackgroundColor3 = "Secondary" })
        panel.BackgroundTransparency = 0.02
        Components.stroke(panelCtx, panel, "Stroke", 0.3)
        create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, panel)
        create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, panel)

        local header = create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 1 }, panel)
        Components.label(panelCtx, header, {
            Size = UDim2.new(1, -40, 0, 18),
            FontFace = Components.font(Enum.FontWeight.Bold),
            TextSize = 15,
            Text = feature.Name,
        })
        Components.label(panelCtx, header, {
            Position = UDim2.fromOffset(0, 19),
            Size = UDim2.new(1, -40, 0, 14),
            TextSize = 11,
            Text = subtitle,
        }, "SubText")
        local closeButton = Components.iconButton(panelCtx, header, { Icon = "x", Fallback = "x", Size = 26, OnClick = manager.Close })
        closeButton.AnchorPoint = Vector2.new(1, 0)
        closeButton.Position = UDim2.fromScale(1, 0)

        local body = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 3,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = 2,
        }, panel)
        local bodyLayout = create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, body)
        create("UIPadding", { PaddingRight = UDim.new(0, 8) }, body)

        -- The body is as tall as its rows, but never taller than the window leaves room for
        -- (the header, the panel padding and a margin take 104): longer content scrolls.
        local maxBodyHeight = math.max(120, root.Size.Y.Offset - 104)
        local function fitBody()
            body.Size = UDim2.new(1, 0, 0, math.min(bodyLayout.AbsoluteContentSize.Y, maxBodyHeight))
        end
        janitor:Connect(bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"), fitBody)

        local rowsJanitor = ctx.NewJanitor()
        janitor:Add(function()
            rowsJanitor:Cleanup()
        end)

        local function render()
            rowsJanitor:Cleanup()
            for _, child in ipairs(body:GetChildren()) do
                if child:IsA("GuiObject") then
                    child:Destroy()
                end
            end
            build(body, Components.child(ctx, rowsJanitor))
            fitBody()
        end
        render()

        janitor:Add(feature:Subscribe(function(eventName)
            if eventName == "reset" then
                render()
            end
        end))
        janitor:Connect(scrim.MouseButton1Click, manager.Close)
        janitor:Connect(UserInputService.InputBegan, function(input)
            if input.KeyCode == Enum.KeyCode.Escape and not ctx.State.Capturing then
                manager.Close()
            end
        end)
    end

    function manager.OpenSettings(feature)
        open(feature, "Settings", function(body, rowCtx)
            local schema = feature:GetSettingsSchema()
            for index, row in ipairs(schema) do
                addRow(body, rowCtx, row, function(id, value)
                    feature:SetSetting(id, value)
                end, function()
                    feature:ResetSettings()
                end, index)
            end
            if #schema == 0 then
                Components.label(rowCtx, body, { Size = UDim2.new(1, 0, 0, 20), Text = "This feature has no settings." }, "SubText")
            end
        end)
    end

    function manager.OpenNotifications(feature)
        open(feature, "Notifications", function(body, rowCtx)
            local schema = feature:GetNotificationSchema()
            for index, row in ipairs(schema) do
                addRow(body, rowCtx, row, function(id, value)
                    feature:SetNotification(id, value)
                end, nil, index)
            end
            local resetRow = { Id = "ResetNotifications", Type = "Button", Name = "Reset Notifications" }
            addRow(body, rowCtx, resetRow, nil, function()
                feature:ResetNotifications()
            end, #schema + 1)
        end)
    end

    return manager
end

return Panels
end)()

modules.FloatingButton = (function()
-- Lib/V2/FloatingButton.lua
-- A small draggable card that toggles one feature from anywhere on screen (the "Show Button" setting).
-- Same idea as b/button.lua: title, one big ON/OFF button, drag to move. The position is saved in the v2 file.

local FloatingButton = {}

local width, height = 150, 85

-- Offsets of the saved position are clamped so a button never ends up off screen
local function clampToScreen(position)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local x = math.clamp(position.XS * viewport.X + position.XO, 0, math.max(viewport.X - width, 0))
    local y = math.clamp(position.YS * viewport.Y + position.YO, 0, math.max(viewport.Y - height, 0))
    return UDim2.fromOffset(x, y)
end

-- gui: the ScreenGui to put the button in. index staggers the default positions.
function FloatingButton.new(ctx, feature, gui, index)
    local Components = ctx.Components
    local create = Components.create

    local janitor = ctx.NewJanitor()
    local buttonCtx = Components.child(ctx, janitor)

    local card = create("Frame", {
        Name = "FloatingButton",
        Active = true,
        Size = UDim2.fromOffset(width, height),
        BorderSizePixel = 0,
    }, gui)
    Components.corner(card, 10)
    Components.bind(buttonCtx, card, { BackgroundColor3 = "Secondary" })
    card.BackgroundTransparency = 0.1
    Components.stroke(buttonCtx, card, "Stroke", 0.3)

    local saved = ctx.Store:Get("positions." .. feature.Id)
    if type(saved) == "table" and saved.XS and saved.XO and saved.YS and saved.YO then
        card.Position = clampToScreen(saved)
    else
        card.Position = UDim2.new(0.5, -width / 2 + (index - 1) * 12, 0.75, (index - 1) * (height + 10))
    end

    Components.label(buttonCtx, card, {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(1, -20, 0, 16),
        FontFace = Components.font(Enum.FontWeight.Bold),
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = feature.Name,
    }, "Accent")

    local button = create("TextButton", {
        AutoButtonColor = false,
        Position = UDim2.fromOffset(10, 32),
        Size = UDim2.new(1, -20, 0, 40),
        BorderSizePixel = 0,
        FontFace = Components.font(Enum.FontWeight.Bold),
        TextSize = 14,
    }, card)
    Components.corner(button, 8)

    local function paint()
        local theme = ctx.Theme
        local state = feature:GetState()
        local accent = theme:Get("Accent")
        if feature:GetSetting("ShowStatus") then
            button.Text = state and "ON" or "OFF"
        else
            button.Text = "Toggle"
        end
        button.BackgroundColor3 = state and accent or ctx.Mix(theme:Get("Secondary"), theme:Get("Stroke"), 0.5)
        button.TextColor3 = state and Components.contrast(accent) or theme:Get("SubText")
    end
    paint()
    janitor:Add(ctx.Theme:Subscribe(paint))
    janitor:Add(feature:Subscribe(function(eventName)
        if eventName == "state" or eventName == "setting" or eventName == "reset" then
            paint()
        end
    end))

    janitor:Connect(button.MouseButton1Click, function()
        feature:Toggle("toggle")
    end)

    Components.draggable(buttonCtx, card, card, function(position)
        ctx.Store:Set("positions." .. feature.Id, {
            XS = position.X.Scale,
            XO = position.X.Offset,
            YS = position.Y.Scale,
            YO = position.Y.Offset,
        })
    end)

    local handle = {}
    function handle.Destroy()
        janitor:Cleanup()
        card:Destroy()
    end
    return handle
end

return FloatingButton
end)()

modules.Window = (function()
local Window = {}
Window.__index = Window

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local windowWidth, windowHeight = 698, 479
local collapsedWidth, collapsedHeight = 150, 40
local sidebarWidth, dragBandHeight, contentTop = 164, 44, 40
local logoImage = "rbxassetid://107819132007001"

local colorRows = {
    { "Main Color", "MainColor" },
    { "Secondary", "Secondary" },
    { "Accent", "Accent" },
    { "Stroke", "Stroke" },
    { "Text", "Text" },
    { "SubText", "SubText" },
}

local function sanitize(text)
    return (string.gsub(string.lower(tostring(text)), "[^%w]+", "_"))
end

local function guiParent()
    local ok, hidden = pcall(function()
        return gethui and gethui()
    end)
    return (ok and hidden) or CoreGui
end

local function positionRecord(position)
    return { XS = position.X.Scale, XO = position.X.Offset, YS = position.Y.Scale, YO = position.Y.Offset }
end

local function textWidth(text, size, weight)
    return TextService:GetTextSize(tostring(text), size, Enum.Font.GothamSemibold, Vector2.new(400, 40)).X
end

-- options: Modules (defaults to the modules of this file), Theme, Store, Library (UI v1, optional: icons and
-- notifications), Title, Version, Categories (list of { name, lucide icon } or false), ToggleKey,
-- NotificationSoundId, Transparency (window background, default 0.15), Logo (image or false),
-- GalacticText (animated gradient on the name, default true)
function Window.new(options)
    local modules = options.Modules or modules
    local Components = modules.Components
    local create = Components.create

    local self = setmetatable({}, Window)
    self._modules = modules
    self._library = options.Library
    self._soundId = options.NotificationSoundId
    self._toggleKey = options.ToggleKey or Enum.KeyCode.Insert
    self._janitor = modules.Janitor.new()
    self._router = modules.Feature.Router.new()
    self._features = {}
    self._cards = {}
    self._floating = {}
    self._floatingCount = 0
    self._tabs = {}
    self._tabList = {}
    self._selected = nil
    self._destroyed = false
    self._open = true
    self._topControls = {}
    self.Theme = options.Theme
    self.Store = options.Store

    local library = options.Library
    local ctx = {
        Theme = options.Theme,
        Janitor = self._janitor,
        Store = options.Store,
        Components = Components,
        ColorPicker = modules.ColorPicker,
        Mix = modules.Theme.mix,
        State = { Capturing = false },
        NewJanitor = modules.Janitor.new,
        ApplyIcon = function(image, name)
            if library and library.ApplyIcon and name then
                return library.ApplyIcon(image, name) == true
            end
            return false
        end,
    }
    self._ctx = ctx

    self._gui = create("ScreenGui", {
        Name = "SxH_V2",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 500,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent())

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local windowScale = math.clamp(math.min((viewport.X - 24) / windowWidth, (viewport.Y - 24) / windowHeight), 0.35, 1)

    local root = create("Frame", {
        Name = "Root",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(windowWidth, windowHeight),
        BackgroundTransparency = options.Transparency or 0.15,
        ClipsDescendants = true,
        BorderSizePixel = 0,
    }, self._gui)
    Components.corner(root, 12)
    Components.bind(ctx, root, { BackgroundColor3 = "MainColor" })
    Components.stroke(ctx, root, "Stroke", 0.3)
    self._scale = create("UIScale", { Scale = windowScale }, root)
    self._root = root

    local savedPosition = options.Store:Get("window.Position")
    if type(savedPosition) == "table" and savedPosition.XS then
        root.Position = UDim2.new(savedPosition.XS, savedPosition.XO, savedPosition.YS, savedPosition.YO)
    else
        root.Position = UDim2.fromScale(0.5, 0.5)
    end

    self._panels = modules.Panels.new(ctx, root)

    -- Drag band across the top: grab it to move the window
    local dragBand = create("Frame", { Name = "DragBand", Size = UDim2.new(1, 0, 0, dragBandHeight), BackgroundTransparency = 1, Active = true }, root)
    Components.draggable(ctx, dragBand, root, function(position)
        options.Store:Set("window.Position", positionRecord(position))
    end)

    local body = create("Frame", { Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, root)
    self._body = body

    -- Clicking the title bar (the logo and name area) switches between open and collapsed.
    -- Moving the pointer more than a few pixels is a drag of the window, not a click.
    local function isPress(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end
    local titlePress = nil
    self._janitor:Connect(dragBand.InputBegan, function(input)
        if not isPress(input) then
            return
        end
        local localX = (input.Position.X - root.AbsolutePosition.X) / self._scale.Scale
        if localX >= 0 and localX <= sidebarWidth then
            titlePress = { position = input.Position, moved = false }
        end
    end)
    self._janitor:Connect(UserInputService.InputChanged, function(input)
        if titlePress and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if (input.Position - titlePress.position).Magnitude > 5 then
                titlePress.moved = true
            end
        end
    end)
    self._janitor:Connect(UserInputService.InputEnded, function(input)
        if titlePress and isPress(input) then
            local press = titlePress
            titlePress = nil
            if not press.moved then
                self:Toggle()
            end
        end
    end)

    -- Sidebar header: logo and the name
    local nameX = 15
    if options.Logo ~= false then
        local logo = create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(15, 26),
            Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1,
            Image = options.Logo or logoImage,
            ScaleType = Enum.ScaleType.Fit,
        }, body)
        Components.bind(ctx, logo, { ImageColor3 = "Accent" })
        nameX = 43
    end

    local nameLabel = create("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(nameX, 26),
        Size = UDim2.fromOffset(sidebarWidth - nameX - 6, 18),
        BackgroundTransparency = 1,
        FontFace = Components.font(),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.new(1, 1, 1),
        Text = options.Title or "Sora x Hikaru",
    }, body)
    if options.GalacticText == false then
        Components.bind(ctx, nameLabel, { TextColor3 = "Accent" })
    else
        local first, second = Color3.fromRGB(99, 102, 241), Color3.fromRGB(236, 72, 153)
        local gradient = create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, first),
                ColorSequenceKeypoint.new(0.5, second),
                ColorSequenceKeypoint.new(1, first),
            }),
        }, nameLabel)
        local offset = 0
        self._janitor:Connect(RunService.Heartbeat, function(deltaTime)
            offset = offset + deltaTime * 0.9
            if offset > 1 then
                offset = -1
            end
            gradient.Offset = Vector2.new(offset, 0)
        end)
    end

    local divider = create("Frame", { Position = UDim2.fromOffset(sidebarWidth, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0 }, body)
    Components.bind(ctx, divider, { BackgroundColor3 = "Stroke" })

    -- Tabs
    local nav = create("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(10, 55),
        Size = UDim2.fromOffset(sidebarWidth - 20, 330),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
    }, body)
    create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, nav)
    self._nav = nav

    -- The pin slides to the selected tab
    self._pin = create("Frame", { Position = UDim2.fromOffset(10, 66), Size = UDim2.fromOffset(2, 16), BorderSizePixel = 0, Visible = false, ZIndex = 3 }, body)
    Components.corner(self._pin, 1)
    Components.bind(ctx, self._pin, { BackgroundColor3 = "Accent" })

    self:_buildInfoCard(body)

    -- Pages
    self._pages = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(sidebarWidth + 1, contentTop),
        Size = UDim2.new(1, -(sidebarWidth + 1), 1, -contentTop),
        BackgroundTransparency = 1,
    }, body)

    -- Search, minimize and close in the top right corner
    local function circleButton(iconName, fallback, rightOffset, onClick)
        local circle = create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, rightOffset, 0, 8),
            Size = UDim2.fromOffset(26, 26),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
        }, root)
        Components.corner(circle, 13)
        Components.bind(ctx, circle, { BackgroundColor3 = "Secondary" })
        Components.stroke(ctx, circle, "Stroke", 0.5)
        local button = Components.iconButton(ctx, circle, { Icon = iconName, Fallback = fallback, Size = 26, OnClick = onClick })
        button.Position = UDim2.fromScale(0, 0)
        return circle
    end
    table.insert(self._topControls, circleButton("x", "x", -12, function() self:Hide() end))
    table.insert(self._topControls, circleButton("minus", "-", -44, function() self:Minimize(true) end))

    local searchBox = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -78, 0, 8),
        Size = UDim2.fromOffset(190, 26),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, root)
    Components.corner(searchBox, 13)
    Components.bind(ctx, searchBox, { BackgroundColor3 = "Secondary" })
    Components.stroke(ctx, searchBox, "Stroke", 0.5)
    table.insert(self._topControls, searchBox)
    Components.icon(ctx, searchBox, { Name = "search", Fallback = "?", Size = 14, Position = UDim2.fromOffset(10, 6) })
    local searchInput = create("TextBox", {
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -38, 1, 0),
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        FontFace = Components.font(),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "Search...",
        Text = "",
    }, searchBox)
    Components.bind(ctx, searchInput, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })
    self._janitor:Connect(searchInput:GetPropertyChangedSignal("Text"), function()
        self:Search(searchInput.Text)
    end)

    -- Floating button with the logo: always visible, switches the window between open and collapsed.
    -- It can be dragged; a press that moves is a drag, not a click.
    self._launcher = create("TextButton", {
        Name = "Launcher",
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(44, 44),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, self._gui)
    Components.corner(self._launcher, 22)
    Components.bind(ctx, self._launcher, { BackgroundColor3 = "Secondary" })
    Components.stroke(ctx, self._launcher, "Accent", 0.3)
    local launcherLogo = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Image = options.Logo or logoImage,
        ScaleType = Enum.ScaleType.Fit,
    }, self._launcher)
    Components.bind(ctx, launcherLogo, { ImageColor3 = "Accent" })

    local launcherSaved = options.Store:Get("positions.launcher")
    if type(launcherSaved) == "table" and launcherSaved.XS then
        self._launcher.Position = UDim2.new(launcherSaved.XS, launcherSaved.XO, launcherSaved.YS, launcherSaved.YO)
    else
        self._launcher.Position = UDim2.new(0, 16, 0.5, -22)
    end
    Components.draggable(ctx, self._launcher, self._launcher, function(position)
        options.Store:Set("positions.launcher", positionRecord(position))
    end)

    local launcherPress = nil
    self._janitor:Connect(self._launcher.InputBegan, function(input)
        if isPress(input) then
            launcherPress = { position = input.Position, moved = false }
        end
    end)
    self._janitor:Connect(UserInputService.InputChanged, function(input)
        if launcherPress and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if (input.Position - launcherPress.position).Magnitude > 5 then
                launcherPress.moved = true
            end
        end
    end)
    self._janitor:Connect(UserInputService.InputEnded, function(input)
        if launcherPress and isPress(input) then
            local press = launcherPress
            launcherPress = nil
            if not press.moved then
                self:Toggle()
            end
        end
    end)

    -- Keybinds for features and the window toggle key. A recorded key or a focused textbox is ignored.
    self._janitor:Connect(UserInputService.InputBegan, function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard or ctx.State.Capturing then
            return
        end
        if input.KeyCode == self._toggleKey and not processed then
            self:Toggle()
            return
        end
        if not processed then
            self._router:Handle(input.KeyCode.Name, true)
        end
    end)
    self._janitor:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and not ctx.State.Capturing then
            self._router:Handle(input.KeyCode.Name, false)
        end
    end)

    -- No tabs are created for you: add them with Window:AddTab(name, icon).
    -- Categories (optional) is a list of { name, icon } to create right away.
    if type(options.Categories) == "table" then
        for _, category in ipairs(options.Categories) do
            self:AddTab(category[1], category[2])
        end
    end

    self._version = options.Version or "v2.0"
    return self
end

-- Bottom of the sidebar: the name with the version, and the key that shows / hides the window
function Window:_buildInfoCard(parent)
    local Components = self._modules.Components
    local create = Components.create
    local ctx = self._ctx

    local card = create("Frame", { Position = UDim2.fromOffset(10, 397), Size = UDim2.fromOffset(sidebarWidth - 20, 44), BackgroundTransparency = 0.15, BorderSizePixel = 0 }, parent)
    Components.corner(card, 9)
    Components.bind(ctx, card, { BackgroundColor3 = "Secondary" })
    Components.stroke(ctx, card, "Stroke", 0.3)

    local dot = create("Frame", { Position = UDim2.fromOffset(10, 14), Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0 }, card)
    Components.corner(dot, 8)
    Components.bind(ctx, dot, { BackgroundColor3 = "Accent" })
    local letter = Components.label(ctx, dot, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, FontFace = Components.font(Enum.FontWeight.Bold), TextSize = 11, Text = "i" })
    Components.bind(ctx, letter, { TextColor3 = function(theme) return Components.contrast(theme:Get("Accent")) end })

    self._infoTitle = Components.label(ctx, card, { Position = UDim2.fromOffset(34, 8), Size = UDim2.new(1, -40, 0, 14), TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Text = "Sora x Hikaru v2.0" })
    Components.label(ctx, card, { Position = UDim2.fromOffset(34, 23), Size = UDim2.new(1, -40, 0, 12), TextSize = 9, TextTruncate = Enum.TextTruncate.AtEnd, Text = "Have a good day!" }, "SubText")

    local keyName = self._toggleKey.Name
    local keyWidth = textWidth(keyName, 10) + 14
    local function chip(text, x, width)
        local label = Components.label(ctx, parent, {
            Position = UDim2.fromOffset(x, 452),
            Size = UDim2.fromOffset(width, 18),
            BackgroundTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextSize = 10,
            Text = text,
        })
        Components.corner(label, 5)
        Components.bind(ctx, label, { BackgroundColor3 = "Secondary" })
        return label
    end
    chip("*", 14, 18)
    chip(keyName, 36, keyWidth)
    Components.label(ctx, parent, { Position = UDim2.fromOffset(36 + keyWidth + 6, 452), Size = UDim2.fromOffset(70, 18), Text = "to toggle UI" }, "SubText")
end

function Window:Notify(title, text, duration, sound)
    local library = self._library
    if library and library.Notify and library.Notify.Send then
        library.Notify.Send({ title = title, text = text, duration = duration, type = "info" })
    else
        print("[Sora x Hikaru] " .. tostring(title) .. ": " .. tostring(text))
    end

    if sound and self._soundId then
        local clip = Instance.new("Sound")
        clip.SoundId = self._soundId
        clip.Volume = 0.5
        clip.Parent = game:GetService("SoundService")
        clip.Ended:Once(function()
            clip:Destroy()
        end)
        clip:Play()
    end
end

-- Tabs ----------------------------------------------------------------

function Window:_movePin()
    local tab = self._selected
    if not tab or not self._pin.Parent or not self._open then
        return
    end
    local y = (tab.Button.AbsolutePosition.Y - self._root.AbsolutePosition.Y) / self._scale.Scale + 11
    self._pin.Visible = true
    self._modules.Components.tween(self._pin, { Position = UDim2.fromOffset(10, y) }, 0.4)
end

function Window:_paintTabs()
    local theme = self.Theme
    for _, tab in ipairs(self._tabList) do
        local selected = tab == self._selected
        tab.Button.BackgroundTransparency = selected and 0.5 or 1
        tab.Button.BackgroundColor3 = theme:Get("Secondary")
        tab.Label.TextColor3 = theme:Get(selected and "Accent" or "Text")
        tab.Label.TextTransparency = selected and 0.2 or 0.7
        if tab.Icon:IsA("ImageLabel") then
            tab.Icon.ImageColor3 = theme:Get(selected and "Accent" or "Text")
            tab.Icon.ImageTransparency = selected and 0.2 or 0.8
        else
            tab.Icon.TextColor3 = theme:Get(selected and "Accent" or "Text")
            tab.Icon.TextTransparency = selected and 0.2 or 0.8
        end
    end
end

function Window:SelectTab(name)
    local tab = self._tabs[name]
    if not tab then
        return false
    end
    self._selected = tab
    for _, other in ipairs(self._tabList) do
        other.Page.Visible = other == tab
    end
    self:_paintTabs()
    task.defer(function()
        if not self._destroyed then
            self:_movePin()
        end
    end)
    return true
end

-- Creates a page and its sidebar entry. The same name returns the existing tab.
function Window:AddTab(name, icon)
    if self._tabs[name] then
        return self._tabs[name]
    end

    local Components = self._modules.Components
    local create = Components.create
    local ctx = self._ctx

    local button = create("TextButton", {
        Name = "Tab",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 38),
        BorderSizePixel = 0,
        LayoutOrder = #self._tabList + 1,
    }, self._nav)
    Components.corner(button, 5)
    local tabIcon = Components.icon(ctx, button, { Name = icon, Fallback = string.sub(name, 1, 1), Size = 14, Position = UDim2.new(0.1, 0, 0.5, -7) })
    local label = Components.label(ctx, button, {
        Position = UDim2.new(0.24, 0, 0, 0),
        Size = UDim2.new(0.74, 0, 1, 0),
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = name,
    })

    local page = create("ScrollingFrame", {
        Name = "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false,
    }, self._pages)
    create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20) }, page)

    local columnsFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, page)
    create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 11), SortOrder = Enum.SortOrder.LayoutOrder }, columnsFrame)
    local columns = {}
    for order = 1, 2 do
        local column = create("Frame", { Size = UDim2.new(0.5, -5.5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, columnsFrame)
        create("UIListLayout", { Padding = UDim.new(0, 11), SortOrder = Enum.SortOrder.LayoutOrder }, column)
        columns[order] = column
    end

    local empty = Components.label(ctx, page, { Size = UDim2.new(1, 0, 0, 30), TextSize = 12, Text = "No features here yet." }, "SubText")

    local tab = {
        Name = name,
        Button = button,
        Icon = tabIcon,
        Label = label,
        Page = page,
        Columns = columns,
        CardCount = { 0, 0 },
        Empty = empty,
        Window = self,
    }
    self._tabs[name] = tab
    table.insert(self._tabList, tab)

    self._janitor:Connect(button.MouseButton1Click, function()
        self:SelectTab(name)
    end)
    -- Registered after the widgets above so the selected look wins when the theme changes
    self._janitor:Add(self.Theme:Subscribe(function()
        self:_paintTabs()
    end))

    -- def: see Feature.new. Column = 1 or 2 picks a column, otherwise the emptier one is used.
    function tab:AddFeature(def)
        return self.Window:_addFeatureCard(self, def)
    end

    -- A tab you name GUI gets the Appearance section, one named Config gets the configuration buttons
    if name == "GUI" then
        self:_buildAppearance(tab)
    elseif name == "Config" then
        self:_buildConfig(tab)
    end

    if not self._selected then
        self:SelectTab(name)
    end
    return tab
end

-- Search ---------------------------------------------------------------

-- Hides the cards that do not match. Jumps to another tab when the open one has no match.
function Window:Search(query)
    query = string.lower(query or "")
    local terms = {}
    for term in string.gmatch(query, "%S+") do
        table.insert(terms, term)
    end

    local firstMatchTab = nil
    local matchesInSelected = false
    for _, card in ipairs(self._cards) do
        local visible = true
        for _, term in ipairs(terms) do
            if not string.find(card.Text, term, 1, true) then
                visible = false
                break
            end
        end
        card.Frame.Visible = visible
        if visible and #terms > 0 then
            firstMatchTab = firstMatchTab or card.Tab
            if card.Tab == self._selected then
                matchesInSelected = true
            end
        end
    end

    if #terms > 0 and not matchesInSelected and firstMatchTab then
        self:SelectTab(firstMatchTab.Name)
    end
end

-- Features -------------------------------------------------------------

function Window:GetFeature(id)
    return self._features[id]
end

function Window:_getFloatingGui()
    if not self._floatingGui then
        self._floatingGui = self._modules.Components.create("ScreenGui", {
            Name = "SxH_V2_Floating",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 450,
        }, guiParent())
    end
    return self._floatingGui
end

function Window:_syncFloating(feature)
    local wanted = feature:GetSetting("ShowButton") == true
    local existing = self._floating[feature.Id]
    if wanted and not existing then
        self._floatingCount = self._floatingCount + 1
        self._floating[feature.Id] = self._modules.FloatingButton.new(self._ctx, feature, self:_getFloatingGui(), self._floatingCount)
    elseif not wanted and existing then
        existing.Destroy()
        self._floating[feature.Id] = nil
    end
end

-- Creates the Feature object (logic), registers its keybind and its floating button.
function Window:_newFeature(def, parentId)
    local base = def.Id or sanitize((parentId and (parentId .. "_") or "") .. (def.Name or "feature"))
    local id, suffix = base, 1
    while self._features[id] do
        suffix = suffix + 1
        id = base .. "_" .. suffix
    end
    if suffix > 1 then
        warn("[Sora x Hikaru] feature id '" .. base .. "' is already used, using '" .. id .. "'")
    end

    local copy = table.clone(def)
    copy.Id = id
    local feature = self._modules.Feature.new(copy, {
        Store = self.Store,
        Notify = function(title, text, duration, sound)
            self:Notify(title, text, duration, sound)
        end,
    })

    self._features[id] = feature
    self._router:Register(feature)
    self._janitor:Add(function()
        self._router:Unregister(feature)
    end)
    self._janitor:Add(feature:Subscribe(function(eventName, settingId)
        if (eventName == "setting" and settingId == "ShowButton") or eventName == "reset" then
            self:_syncFloating(feature)
        end
    end))
    return feature
end

-- Gear, bell and the main switch of one feature, left to right inside `parent`
function Window:_addControls(parent, cardCtx, feature)
    local Components = self._modules.Components
    local panels = self._panels

    if feature.HasSettingsButton then
        Components.iconButton(cardCtx, parent, { Icon = "settings", Fallback = "G", Size = 24, OnClick = function() panels.OpenSettings(feature) end })
    end
    if feature.HasNotificationButton then
        Components.iconButton(cardCtx, parent, { Icon = "bell", Fallback = "N", Size = 24, OnClick = function() panels.OpenNotifications(feature) end })
    end

    local switch = Components.switch(cardCtx, parent, {
        Value = feature:GetState(),
        OnChanged = function(state)
            feature:SetState(state, "toggle")
        end,
    })
    cardCtx.Janitor:Add(feature:Subscribe(function(eventName, state)
        if eventName == "state" then
            switch.Set(state, true)
        end
    end))
    return switch
end

-- Runs when the widgets of a feature exist: shows its floating button and applies the startup state
function Window:_activate(feature)
    self:_syncFloating(feature)
    feature:Start()
end

local function hasKeybindRow(feature)
    for _, row in ipairs(feature:GetSettingsSchema()) do
        if row.Id == "Keybind" then
            return true
        end
    end
    return false
end

-- Header and divider of a card in the UI v1 module style. Returns the card frame and its body.
function Window:_cardFrame(tab, column, title, description, cardCtx)
    local Components = self._modules.Components
    local create = Components.create

    local frame = create("Frame", {
        Name = "FeatureCard",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, tab.Columns[column])
    Components.corner(frame, 5)
    Components.bind(cardCtx, frame, { BackgroundColor3 = "Secondary" })
    Components.stroke(cardCtx, frame, "Stroke", 0.5)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, frame)

    local hasDescription = description ~= nil and description ~= ""
    local header = create("Frame", { Size = UDim2.new(1, 0, 0, hasDescription and 56 or 38), BackgroundTransparency = 1, LayoutOrder = 1 }, frame)
    Components.label(cardCtx, header, {
        Position = UDim2.fromOffset(17, hasDescription and 10 or 11),
        Size = UDim2.new(1, -34, 0, 16),
        TextSize = 13,
        TextTransparency = 0.2,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = title,
    }, "Accent")
    if hasDescription then
        Components.label(cardCtx, header, {
            Position = UDim2.fromOffset(17, 30),
            Size = UDim2.new(1, -34, 0, 14),
            TextSize = 10,
            TextTransparency = 0.3,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = description,
        }, "Accent")
    end

    local line = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 2 }, frame)
    Components.bind(cardCtx, line, { BackgroundColor3 = "Stroke" })

    local body = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 4 }, frame)
    create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 17), PaddingRight = UDim.new(0, 17) }, body)
    create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, body)
    return frame, body
end

function Window:_addFeatureCard(tab, def)
    local Components = self._modules.Components
    local create = Components.create
    local feature = self:_newFeature(def)

    local janitor = self._modules.Janitor.new()
    self._janitor:Add(function()
        janitor:Cleanup()
    end)
    local cardCtx = Components.child(self._ctx, janitor)

    local columnIndex = def.Column
    if columnIndex ~= 1 and columnIndex ~= 2 then
        columnIndex = tab.CardCount[1] <= tab.CardCount[2] and 1 or 2
    end
    tab.CardCount[columnIndex] = tab.CardCount[columnIndex] + 1
    tab.Empty.Visible = false

    local frame, body = self:_cardFrame(tab, columnIndex, feature.Name, feature.Description, cardCtx)
    table.insert(self._cards, { Frame = frame, Tab = tab, Text = string.lower(feature.Name .. " " .. feature.Description) })

    -- Control row: the keybind chip on the left, gear / bell / switch on the right
    local controlRow = create("Frame", { Size = UDim2.new(1, 0, 0, 37), BackgroundTransparency = 1, LayoutOrder = 3 }, frame)

    if hasKeybindRow(feature) then
        local chip = create("TextButton", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 17, 0.5, 0),
            Size = UDim2.fromOffset(33, 15),
            AutoButtonColor = false,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            FontFace = Components.font(),
            TextSize = 10,
        }, controlRow)
        Components.corner(chip, 3)
        Components.bind(cardCtx, chip, { BackgroundColor3 = "Accent", TextColor3 = "Text" })
        local function showKey()
            local keyName = feature:GetSetting("Keybind") or "None"
            chip.Text = keyName
            chip.Size = UDim2.fromOffset(math.max(33, textWidth(keyName, 10) + 10), 15)
        end
        showKey()
        janitor:Add(feature:Subscribe(function(eventName)
            if eventName == "setting" or eventName == "reset" then
                showKey()
            end
        end))
        janitor:Connect(chip.MouseButton1Click, function()
            self._panels.OpenSettings(feature)
        end)
    end

    local cluster = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
    }, controlRow)
    create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, cluster)
    self:_addControls(cluster, cardCtx, feature)

    local card = { Feature = feature, Frame = frame, Content = body, Window = self }
    local rowCount = 0

    local function nextRow()
        rowCount = rowCount + 1
        body.Visible = true
        return rowCount
    end

    local function controlId(settings)
        return sanitize(settings.Id or (feature.Id .. "_" .. (settings.Name or "control")))
    end

    -- Another feature inside the card: name on the left, gear / bell / switch on the right
    function card:AddToggle(subDef)
        local sub = self.Window:_newFeature(subDef, feature.Id)
        local row = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = nextRow() }, body)
        Components.label(cardCtx, row, { Size = UDim2.new(1, -120, 1, 0), TextTransparency = 0.2, Text = sub.Name })
        local subCluster = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, row)
        create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, subCluster)
        self.Window:_addControls(subCluster, cardCtx, sub)
        table.insert(self.Window._cards, { Frame = row, Tab = tab, Text = string.lower(sub.Name .. " " .. sub.Description .. " " .. feature.Name) })
        self.Window:_activate(sub)
        return sub
    end

    -- settings: Name, Min, Max, Step, Default, Callback(value), Id
    function card:AddSlider(settings)
        local id = controlId(settings)
        local savedValue = self.Window.Store:Get("controls." .. id)
        local start = type(savedValue) == "number" and savedValue or settings.Default or settings.Min or 0

        local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextRow() }, body)
        create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, row)
        local top = create("Frame", { Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1, LayoutOrder = 1 }, row)
        Components.label(cardCtx, top, { Size = UDim2.new(1, -60, 1, 0), TextTransparency = 0.2, Text = settings.Name })
        local valueLabel = Components.label(cardCtx, top, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(60, 13), TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, TextTransparency = 0.2, Text = tostring(start) })
        local slider = Components.slider(cardCtx, row, {
            Min = settings.Min or 0,
            Max = settings.Max or 100,
            Step = settings.Step,
            Value = start,
            OnChanged = function(value)
                valueLabel.Text = tostring(value)
                if settings.Callback then
                    settings.Callback(value)
                end
            end,
            OnDone = function(value)
                self.Window.Store:Set("controls." .. id, value)
            end,
        })
        slider.Instance.LayoutOrder = 2
        table.insert(self.Window._cards, { Frame = row, Tab = tab, Text = string.lower(settings.Name .. " " .. feature.Name) })
        if settings.Callback then
            settings.Callback(slider.Get())
        end
        return slider
    end

    -- settings: Name, Options, Default, Callback(option), Id
    function card:AddDropdown(settings)
        local id = controlId(settings)
        local savedValue = self.Window.Store:Get("controls." .. id)
        local start = settings.Default or settings.Options[1]
        for _, option in ipairs(settings.Options) do
            if option == savedValue then
                start = option
            end
        end

        local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextRow() }, body)
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, row)
        Components.label(cardCtx, row, { Size = UDim2.new(1, 0, 0, 13), TextTransparency = 0.2, Text = settings.Name }).LayoutOrder = 1
        local dropdown = Components.dropdown(cardCtx, row, {
            Options = settings.Options,
            Value = start,
            OnChanged = function(option)
                self.Window.Store:Set("controls." .. id, option)
                if settings.Callback then
                    settings.Callback(option)
                end
            end,
        })
        dropdown.Instance.LayoutOrder = 2
        table.insert(self.Window._cards, { Frame = row, Tab = tab, Text = string.lower(settings.Name .. " " .. feature.Name) })
        if settings.Callback then
            settings.Callback(start)
        end
        return dropdown
    end

    function card:AddButton(settings)
        local button = Components.button(cardCtx, body, {
            Text = settings.Name,
            OnClick = function()
                if settings.Callback then
                    settings.Callback()
                end
            end,
        })
        button.LayoutOrder = nextRow()
        return button
    end

    function card:AddText(settings)
        local label = Components.label(cardCtx, body, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextSize = 10,
            Text = settings.Text or settings.Name or "",
        }, "SubText")
        label.LayoutOrder = nextRow()
        return label
    end

    function card:AddDivider()
        local line = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = nextRow() }, body)
        Components.bind(cardCtx, line, { BackgroundColor3 = "Stroke" })
        return line
    end

    self:_activate(feature)
    return card
end

-- Built-in sections ---------------------------------------------------

-- A plain card (not a feature) with the same look. Returns its body.
function Window:_plainCard(tab, titleText, column)
    local cardCtx = self._ctx
    local frame, body = self:_cardFrame(tab, column or 1, titleText, nil, cardCtx)
    body.Visible = true
    tab.Empty.Visible = false
    table.insert(self._cards, { Frame = frame, Tab = tab, Text = string.lower(titleText) })
    return body
end

-- Appearance: the six theme colors, each expands to a color picker; changes repaint everything at once
function Window:_buildAppearance(tab)
    local Components = self._modules.Components
    local ctx = self._ctx
    local body = self:_plainCard(tab, "Appearance", 1)

    for index, entry in ipairs(colorRows) do
        local row = self._modules.ColorPicker.row(ctx, body, { Name = entry[1], Key = entry[2] })
        row.LayoutOrder = index
    end

    local order = #colorRows + 1
    local presetNames = {}
    for name in pairs(self._modules.Theme.Presets) do
        table.insert(presetNames, name)
    end
    table.sort(presetNames)
    for _, name in ipairs(presetNames) do
        local button = Components.button(ctx, body, {
            Text = "Preset: " .. name,
            OnClick = function()
                self.Theme:SetPreset(name)
            end,
        })
        button.LayoutOrder = order
        order = order + 1
    end
    local reset = Components.button(ctx, body, { Text = "Reset colors", Primary = true, OnClick = function() self.Theme:Reset() end })
    reset.LayoutOrder = order
end

function Window:_buildConfig(tab)
    local Components = self._modules.Components
    local ctx = self._ctx
    local body = self:_plainCard(tab, "Configuration", 1)

    Components.button(ctx, body, {
        Text = "Save now",
        OnClick = function()
            local saved = self.Store:Flush()
            self:Notify("Configuration", saved and "Saved." or "Could not write the file.", 2, false)
        end,
    }).LayoutOrder = 1
    Components.button(ctx, body, {
        Text = "Reset every feature's settings",
        OnClick = function()
            for _, feature in pairs(self._features) do
                feature:ResetSettings()
                feature:ResetNotifications()
            end
            self:Notify("Configuration", "All feature settings were reset.", 2, false)
        end,
    }).LayoutOrder = 2
end

-- Window state -----------------------------------------------------------

function Window:IsOpen()
    return self._open
end

-- The one place that changes the state. The title bar, the floating button, the toggle key and the
-- top right buttons all end up here: open is 698 x 479, collapsed is 150 x 40.
function Window:SetOpen(state)
    state = state == true
    if state == self._open then
        return
    end
    self._open = state

    if not state then
        self._panels.Close()
        for _, control in ipairs(self._topControls) do
            control.Visible = false
        end
    end

    local goal = state and UDim2.fromOffset(windowWidth, windowHeight) or UDim2.fromOffset(collapsedWidth, collapsedHeight)
    local tween = TweenService:Create(self._root, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = goal })
    tween:Play()

    if state then
        -- the top right controls are anchored to the window edge: show them once it is full size again
        tween.Completed:Once(function()
            if self._open and not self._destroyed then
                for _, control in ipairs(self._topControls) do
                    control.Visible = true
                end
                self:_movePin()
            end
        end)
    end
end

function Window:Show()
    self:SetOpen(true)
end

function Window:Hide()
    self:SetOpen(false)
end

function Window:Toggle()
    self:SetOpen(not self._open)
end

-- Minimize(true) collapses, Minimize(false) opens
function Window:Minimize(state)
    self:SetOpen(state ~= true)
end

-- Removes every widget, connection, subscription and floating button, then saves
function Window:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true

    self._panels.Close()
    for _, floating in pairs(self._floating) do
        floating.Destroy()
    end
    self._floating = {}
    self._janitor:Cleanup()

    self._gui:Destroy()
    if self._floatingGui then
        self._floatingGui:Destroy()
    end
    self.Store:Destroy()
end

return Window
end)()

modules.Compat = (function()
-- Lib/V2/Compat.lua
-- Lets code written for UI v1 run on v2: window:create_tab(title, icon):create_module{...} becomes a feature card and
-- create_checkbox / create_slider / create_dropdown / create_button / create_divider / create_paragraph / create_text
-- keep their v1 arguments and callbacks. Other v1 controls are reported, not silently dropped.
-- Differences: a module toggle is a feature switch (startup state comes from its settings, not the saved v1 flag),
-- and multi-select dropdowns are not supported yet.

local Compat = {}

local function unsupported(name)
    return function()
        warn("[Sora x Hikaru] UI v2: " .. name .. " is not available in v2 yet and was skipped")
        return {}
    end
end

function Compat.apply(window)
    function window:create_tab(title, icon)
        local tab = self:AddTab(title, icon)
        local v1Tab = { Native = tab }

        function v1Tab:create_module(settings)
            settings = settings or {}
            local card = tab:AddFeature({
                Id = settings.flag,
                Name = settings.title or "Module",
                Description = settings.description or "",
                Callback = settings.callback,
                Setting = true,
                Notification = true,
                Column = settings.section == "right" and 2 or 1,
            })

            local module = { Native = card }

            function module:create_checkbox(options)
                return card:AddToggle({ Id = options.flag, Name = options.title, Callback = options.callback, Setting = true, Notification = true })
            end

            function module:create_slider(options)
                return card:AddSlider({
                    Id = options.flag,
                    Name = options.title,
                    Min = options.minimum_value,
                    Max = options.maximum_value,
                    Default = options.value,
                    Step = options.round_number and 1 or 0.1,
                    Callback = options.callback,
                })
            end

            function module:create_dropdown(options)
                if options.multi_dropdown then
                    warn("[Sora x Hikaru] UI v2: multi-select dropdowns are not available yet ('" .. tostring(options.title) .. "' skipped)")
                    return {}
                end
                return card:AddDropdown({ Id = options.flag, Name = options.title, Options = options.options, Callback = options.callback })
            end

            function module:create_button(options)
                return card:AddButton({ Name = options.title, Callback = options.callback })
            end

            function module:create_divider()
                return card:AddDivider()
            end

            function module:create_paragraph(options)
                return card:AddText({ Text = options.text or options.title })
            end

            function module:create_text(options)
                return card:AddText({ Text = options.text })
            end

            for _, name in ipairs({ "create_textbox", "create_colorpicker", "create_range_slider", "create_keybind", "create_code", "create_image", "create_feature", "create_section", "create_playerlist", "create_tooltip", "create_space" }) do
                module[name] = unsupported(name)
            end
            return module
        end

        return v1Tab
    end

    -- v1 builds everything first and then calls load()
    function window:load()
        return self
    end

    function window:UIVisiblity()
        self:Toggle()
    end
end

return Compat
end)()

local function globalConfig()
    local env = (getgenv and getgenv()) or _G
    return env.GG or {}
end

local V2 = { Version = "v2.0" }

-- Opens the saved settings file, builds the theme and the window
function V2.new(options)
    options = options or {}
    local gg = globalConfig()

    local folder = options.Folder or gg.FolderName or "SoraHikaru"
    local store = modules.Store.new({ Path = folder .. "/v2.json" })
    local theme = modules.Theme.new({ Store = store, Preset = options.Preset })

    local window = modules.Window.new({
        Theme = theme,
        Store = store,
        Library = options.Library,
        Title = options.Title or gg.UIName,
        Version = options.Version or V2.Version,
        Categories = options.Categories,
        ToggleKey = options.ToggleKey or gg.ToggleKey,
        NotificationSoundId = options.NotificationSoundId,
        Transparency = options.Transparency or gg.Transparency,
        Logo = options.Logo,
        GalacticText = options.GalacticText,
    })
    modules.Compat.apply(window)
    return window
end

for name, module in pairs(modules) do
    V2[name] = module
end

return V2
