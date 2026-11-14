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
    self.Id = def.Id or sanitize(self.Name)
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
    for _, row in ipairs(requested.Custom or def.Custom or {}) do
        self._rows[#self._rows + 1] = copyValue(row)
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
    for _, row in ipairs(requested.Custom or def.Custom or {}) do
        self._defaults.Custom[row.Id] = copyValue(row.Default)
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
            for id in pairs(self._defaults.Custom) do
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
        if self._defaults.Custom[row.Id] ~= nil or (row.Default ~= nil and row.Type ~= "Button") then
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
    if self._defaults.Custom[id] ~= nil or self._settings.Custom[id] ~= nil then
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
    local custom = findRow(self._rows, id)
    if custom and self._defaults.Custom[id] ~= nil or custom and custom.Default ~= nil then
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
    for id in pairs(self._defaults.Custom) do
        local row = findRow(self._rows, id)
        if row and type(row.Callback) == "function" then
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
