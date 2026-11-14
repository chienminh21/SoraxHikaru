-- Lib/V2/Tests/Run.lua
-- Offline tests for the UI v2 logic modules (Janitor, Store, Theme, Feature, Router).
-- No Roblox needed: run with any Lua 5.3+ from the repository root:  texlua Lib/V2/Tests/Run.lua
-- The interface modules (Window, Components, Panels...) need Roblox and are not covered here.

local base = (arg and arg[0] and string.match(arg[0], "^(.*)/Tests/[^/]+$")) or "Lib/V2"

-- Minimal stand-ins for the Roblox globals the logic modules touch
Color3 = {
    fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end,
    new = function(r, g, b) return { R = r, G = g, B = b } end,
}
local warnings = {}
warn = function(message) warnings[#warnings + 1] = message end
local delayed = {}
task = {
    delay = function(seconds, fn) delayed[#delayed + 1] = fn end,
    cancel = function() end,
}
local function runDelayed()
    local pending = delayed
    delayed = {}
    for _, fn in ipairs(pending) do fn() end
end

-- Small JSON for the Store tests (sorted keys so output is stable)
local json = {}
local function encode(value)
    local kind = type(value)
    if kind == "table" then
        local isArray = #value > 0
        local parts = {}
        if isArray then
            for _, inner in ipairs(value) do parts[#parts + 1] = encode(inner) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys)
        for _, key in ipairs(keys) do parts[#parts + 1] = string.format("%q:%s", key, encode(value[key])) end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif kind == "string" then
        return string.format("%q", value)
    end
    return tostring(value)
end
local function decode(text)
    local position = 1
    local function skip() position = text:find("%S", position) or #text + 1 end
    local parseValue
    local function parseString()
        local close = text:find('"', position + 1, true)
        local result = text:sub(position + 1, close - 1)
        position = close + 1
        return result
    end
    function parseValue()
        skip()
        local char = text:sub(position, position)
        if char == "{" then
            position = position + 1
            local object = {}
            skip()
            if text:sub(position, position) == "}" then position = position + 1 return object end
            while true do
                skip()
                local key = parseString()
                skip(); position = position + 1 -- colon
                object[key] = parseValue()
                skip()
                local separator = text:sub(position, position)
                position = position + 1
                if separator == "}" then break end
            end
            return object
        elseif char == "[" then
            position = position + 1
            local array = {}
            skip()
            if text:sub(position, position) == "]" then position = position + 1 return array end
            while true do
                array[#array + 1] = parseValue()
                skip()
                local separator = text:sub(position, position)
                position = position + 1
                if separator == "]" then break end
            end
            return array
        elseif char == '"' then
            return parseString()
        elseif text:sub(position, position + 3) == "true" then
            position = position + 4 return true
        elseif text:sub(position, position + 4) == "false" then
            position = position + 5 return false
        end
        local number = text:match("^-?[%d%.eE+-]+", position)
        if not number then error("bad json at " .. position) end
        position = position + #number
        return tonumber(number)
    end
    local value = parseValue()
    return value
end
json.Encode, json.Decode = encode, decode

local function memoryFs(initial)
    local files = initial or {}
    local folders = {}
    local fs = { files = files, writes = 0 }
    fs.isfile = function(path) return files[path] ~= nil end
    fs.readfile = function(path) return files[path] end
    fs.writefile = function(path, text) files[path] = text; fs.writes = fs.writes + 1 end
    fs.makefolder = function(path) folders[path] = true end
    fs.isfolder = function(path) return folders[path] == true end
    return fs
end

-- Test runner
local results, failed = {}, 0
local function test(name, fn)
    warnings = {}
    delayed = {}
    local ok, err = pcall(fn)
    results[#results + 1] = { name = name, ok = ok, err = err }
    if not ok then failed = failed + 1 end
    print((ok and "PASS  " or "FAIL  ") .. name .. (ok and "" or ("\n      " .. tostring(err))))
end
local function eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
    end
end

local Janitor = dofile(base .. "/Janitor.lua")
local Store = dofile(base .. "/Store.lua")
local Theme = dofile(base .. "/Theme.lua")
local Feature = dofile(base .. "/Feature.lua")

-- Janitor ------------------------------------------------------------------
test("Janitor: cleans in reverse order and keeps going after a failure", function()
    local janitor = Janitor.new()
    local order = {}
    janitor:Add(function() order[#order + 1] = "first" end)
    janitor:Add(function() error("boom") end)
    janitor:Add(function() order[#order + 1] = "last" end)
    janitor:Add({ Destroy = function() order[#order + 1] = "destroyed" end })
    janitor:Add({ Disconnect = function() order[#order + 1] = "disconnected" end })
    eq(janitor:Count(), 5, "count")
    eq(janitor:Cleanup(), 1, "failures")
    eq(table.concat(order, ","), "disconnected,destroyed,last,first", "order")
    eq(janitor:Count(), 0, "empty after cleanup")
    eq(janitor:Cleanup(), 0, "second cleanup is a no-op")
end)

-- Store ------------------------------------------------------------------
test("Store: set / get nested paths and return copies", function()
    local store = Store.new({ Path = "Folder/v2.json", Json = json, Fs = memoryFs(), Delay = task.delay })
    store:Set("features.autoparry.Settings.Keybind", "G")
    eq(store:Get("features.autoparry.Settings.Keybind"), "G", "nested get")
    eq(store:Get("features.missing.value", "fallback"), "fallback", "default")
    local copy = store:Get("features.autoparry")
    copy.Settings.Keybind = "changed"
    eq(store:Get("features.autoparry.Settings.Keybind"), "G", "mutating a copy does not change the store")
end)

test("Store: writes are debounced into one file write", function()
    local fs = memoryFs()
    local store = Store.new({ Path = "Folder/v2.json", Json = json, Fs = fs, Delay = task.delay })
    store:Set("a", 1); store:Set("b", 2); store:Set("c", 3)
    eq(fs.writes, 0, "nothing written yet")
    runDelayed()
    eq(fs.writes, 1, "one write")
    eq(decode(fs.files["Folder/v2.json"]).b, 2, "content")
end)

test("Store: loads an existing file; a corrupt file starts empty", function()
    local fs = memoryFs({ ["Folder/v2.json"] = '{"positions":{"btn":{"X":10}}}' })
    local store = Store.new({ Path = "Folder/v2.json", Json = json, Fs = fs, Delay = task.delay })
    eq(store:Get("positions.btn.X"), 10, "loaded")
    local broken = Store.new({ Path = "Folder/v2.json", Json = { Encode = encode, Decode = function() error("bad") end }, Fs = fs, Delay = task.delay })
    eq(broken:Get("positions.btn.X"), nil, "corrupt file ignored")
end)

test("Store: Destroy flushes pending changes; no file system does not raise", function()
    local fs = memoryFs()
    local store = Store.new({ Path = "Folder/v2.json", Json = json, Fs = fs, Delay = task.delay })
    store:Set("x", true)
    store:Destroy()
    eq(fs.writes, 1, "flushed on destroy")
    local bare = Store.new({ Path = "Folder/v2.json", Json = json, Fs = {}, Delay = task.delay })
    bare:Set("x", true)
    eq(bare:Available(), false, "not available")
    eq(bare:Flush(), false, "flush reports false")
end)

-- Theme ------------------------------------------------------------------
test("Theme: default is pure black with a red accent", function()
    local theme = Theme.new()
    eq(Theme.toHex(theme:Get("MainColor")), "#060607", "main")
    eq(Theme.toHex(theme:Get("Accent")), "#E23E3E", "accent")
    eq(theme:GetPreset(), "Pure Black", "preset")
end)

test("Theme: Set notifies subscribers, saves, and rejects bad input", function()
    local fs = memoryFs()
    local store = Store.new({ Path = "F/v2.json", Json = json, Fs = fs, Delay = task.delay })
    local theme = Theme.new({ Store = store })
    local seen = {}
    local stop = theme:Subscribe(function(key, color) seen[#seen + 1] = key .. "=" .. Theme.toHex(color) end)
    eq(theme:Set("Accent", Color3.fromRGB(0, 128, 255)), true, "set accepted")
    eq(seen[1], "Accent=#0080FF", "listener")
    eq(theme:Set("Nope", Color3.fromRGB(1, 2, 3)), false, "unknown key")
    eq(theme:Set("Accent", "red"), false, "not a color")
    eq(store:Get("theme.Accent"), "#0080FF", "saved")
    stop()
    theme:Set("Text", Color3.fromRGB(255, 255, 255))
    eq(#seen, 1, "unsubscribed")
end)

test("Theme: presets, reset and saved colors", function()
    local store = Store.new({ Path = "F/v2.json", Json = json, Fs = memoryFs(), Delay = task.delay })
    local theme = Theme.new({ Store = store })
    local count = 0
    theme:Subscribe(function() count = count + 1 end)
    eq(theme:SetPreset("Midnight"), true, "preset")
    eq(count, 6, "all six colors announced")
    eq(Theme.toHex(theme:Get("Accent")), "#6C70F0", "midnight accent")
    eq(theme:SetPreset("Missing"), false, "unknown preset")
    theme:Set("Stroke", Color3.fromRGB(1, 2, 3))
    theme:Reset()
    eq(Theme.toHex(theme:Get("Stroke")), "#2D3042", "reset to preset")
    theme:Set("Accent", Color3.fromRGB(10, 20, 30))
    local reloaded = Theme.new({ Store = store })
    eq(Theme.toHex(reloaded:Get("Accent")), "#0A141E", "saved color survives")
    eq(reloaded:GetPreset(), "Midnight", "saved preset")
end)

test("Theme: hex helpers", function()
    eq(Theme.fromHex("zzz"), nil, "bad hex")
    eq(Theme.toHex(Theme.fromHex("#1a2B3c")), "#1A2B3C", "round trip")
end)

-- Feature ----------------------------------------------------------------
local function newFeature(def, options)
    options = options or {}
    local notes = {}
    local feature = Feature.new(def, {
        Store = options.Store,
        Notify = function(title, text, duration, sound) notes[#notes + 1] = { title, text, duration, sound } end,
    })
    return feature, notes
end

test("Feature: toggle runs the callback with the source", function()
    local calls = {}
    local feature = newFeature({ Name = "Auto Parry", Callback = function(state, source) calls[#calls + 1] = tostring(state) .. ":" .. source end })
    eq(feature:Toggle(), true, "changed")
    eq(feature:GetState(), true, "on")
    feature:SetState(true, "api")
    eq(#calls, 1, "no callback when the state does not change")
    feature:SetState(false, "api")
    eq(table.concat(calls, ","), "true:toggle,false:api", "calls")
end)

test("Feature: main toggle, settings and notifications stay independent", function()
    local feature, notes = newFeature({ Name = "Auto Parry", Setting = true, Notification = true })
    feature:SetNotification("Enabled", false)
    feature:Toggle()
    eq(feature:GetState(), true, "toggle works with notifications off")
    eq(#notes, 0, "no message")
    feature:SetSetting("Keybind", "G")
    eq(feature:GetState(), true, "changing the keybind does not touch the state")
    feature:SetSetting("ShowStatus", false)
    eq(feature:GetNotification("Enabled"), false, "settings do not touch notifications")
    feature:SetNotification("Enabled", true)
    feature:Toggle()
    eq(feature:GetSetting("Keybind"), "G", "notifications do not touch settings")
    eq(#notes, 1, "message after turning notifications on")
end)

test("Feature: notification rules (OnEnabled / OnDisabled / Duration / Sound)", function()
    local feature, notes = newFeature({ Name = "Spam", Notification = true, Notifications = { OnDisabled = false, Duration = 5, Sound = true } })
    feature:Toggle()
    eq(#notes, 1, "enabled message")
    eq(notes[1][3], 5, "duration")
    eq(notes[1][4], true, "sound")
    feature:Toggle()
    eq(#notes, 1, "no message when disabled (OnDisabled = false)")
    eq(feature:SetNotification("Duration", 99), true, "duration accepted")
    eq(feature:GetNotification("Duration"), 30, "duration clamped")
    eq(feature:SetNotification("Duration", "x"), false, "wrong type")
    eq(feature:SetNotification("Unknown", true), false, "unknown option")
end)

test("Feature: toggle and hold keybinds", function()
    local feature = newFeature({ Name = "Hold me", Setting = true })
    feature:SetSetting("Keybind", "F")
    feature:PressKey(true); feature:PressKey(false)
    eq(feature:GetState(), true, "toggle mode flips once per press")
    feature:PressKey(true)
    eq(feature:GetState(), false, "second press flips back")
    feature:SetSetting("ActivationMode", "Hold")
    feature:PressKey(true)
    eq(feature:GetState(), true, "hold: down = on")
    feature:PressKey(false)
    eq(feature:GetState(), false, "hold: up = off")
    eq(feature:SetSetting("ActivationMode", "Sometimes"), false, "invalid mode")
end)

test("Feature: startup state applies silently", function()
    local calls = {}
    local feature, notes = newFeature({ Name = "Boot", Setting = true, DefaultState = true, Callback = function(state, source) calls[#calls + 1] = source end })
    feature:Start()
    eq(feature:GetState(), true, "started on")
    eq(calls[1], "startup", "source")
    eq(#notes, 0, "no startup notification")
    local off = newFeature({ Name = "Quiet", Setting = true })
    off:Start()
    eq(off:GetState(), false, "default off")
end)

test("Feature: feature specific settings are not forced on other features", function()
    local seen = {}
    local parry = newFeature({ Name = "Auto Parry", Setting = true, Settings = {
        Keybind = true,
        Custom = {
            { Id = "Accuracy", Type = "Slider", Name = "Accuracy", Min = 0, Max = 100, Default = 50, Callback = function(v) seen[#seen + 1] = v end },
            { Id = "ParryMode", Type = "Dropdown", Name = "Parry Mode", Options = { "Remote", "Keypress" }, Default = "Remote" },
        },
    } })
    local plain = newFeature({ Name = "Plain", Setting = true })
    local parryIds, plainIds = {}, {}
    for _, row in ipairs(parry:GetSettingsSchema()) do parryIds[#parryIds + 1] = row.Id end
    for _, row in ipairs(plain:GetSettingsSchema()) do plainIds[#plainIds + 1] = row.Id end
    eq(table.concat(parryIds, ","), "Keybind,Accuracy,ParryMode", "parry rows")
    eq(table.concat(plainIds, ","), "Keybind,ActivationMode,StartupState,ShowStatus,ShowButton,Reset", "default rows")
    eq(parry:GetSetting("Accuracy"), 50, "custom default")
    parry:SetSetting("Accuracy", 80)
    eq(parry:GetSetting("Accuracy"), 80, "custom value")
    eq(seen[1], 80, "custom callback")
    eq(plain:GetSetting("Accuracy"), nil, "other feature has no such setting")
end)

test("Feature: ResetSettings restores settings only", function()
    local feature = newFeature({ Name = "Reset me", Setting = true, Notification = true, Settings = { Keybind = true, Reset = true, Custom = { { Id = "Level", Type = "Slider", Default = 3 } } } })
    feature:SetSetting("Keybind", "Q")
    feature:SetSetting("Level", 9)
    feature:SetNotification("Duration", 8)
    feature:Toggle()
    feature:ResetSettings()
    eq(feature:GetSetting("Keybind"), nil, "keybind cleared")
    eq(feature:GetSetting("Level"), 3, "custom restored")
    eq(feature:GetNotification("Duration"), 8, "notifications untouched")
    eq(feature:GetState(), true, "state untouched")
    feature:ResetNotifications()
    eq(feature:GetNotification("Duration"), 3, "notifications reset on request")
end)

test("Feature: settings and notifications persist through the Store", function()
    local fs = memoryFs()
    local store = Store.new({ Path = "F/v2.json", Json = json, Fs = fs, Delay = task.delay })
    local first = newFeature({ Id = "autoparry", Name = "Auto Parry", Setting = true, Notification = true }, { Store = store })
    first:SetSetting("Keybind", "G")
    first:SetSetting("ShowButton", true)
    first:SetSetting("StartupState", "On")
    first:SetNotification("Sound", true)
    store:Flush()
    local again = Store.new({ Path = "F/v2.json", Json = json, Fs = fs, Delay = task.delay })
    local second = newFeature({ Id = "autoparry", Name = "Auto Parry", Setting = true, Notification = true }, { Store = again })
    eq(second:GetSetting("Keybind"), "G", "keybind")
    eq(second:GetSetting("ShowButton"), true, "show button")
    eq(second:GetSetting("StartupState"), "On", "startup")
    eq(second:GetNotification("Sound"), true, "sound")
end)

test("Feature: Setting and Notification buttons are optional", function()
    local none = newFeature({ Name = "Bare" })
    eq(none.HasSettingsButton, false, "no settings button")
    eq(none.HasNotificationButton, false, "no notification button")
    local both = newFeature({ Name = "Full", Setting = true, Notification = true })
    eq(both.HasSettingsButton and both.HasNotificationButton, true, "both buttons")
end)

test("Feature: a failing callback is reported and does not break the feature", function()
    local feature = newFeature({ Name = "Crashy", Callback = function() error("bug in feature") end })
    eq(feature:Toggle(), true, "state still changes")
    eq(#warnings, 1, "warning printed")
    eq(feature:GetState(), true, "on")
end)

test("Feature: events reach subscribers until they unsubscribe", function()
    local feature = newFeature({ Name = "Events", Setting = true })
    local seen = {}
    local stop = feature:Subscribe(function(event, a) seen[#seen + 1] = event end)
    feature:Toggle(); feature:SetSetting("ShowStatus", false); feature:SetNotification("Sound", true); feature:ResetSettings()
    eq(table.concat(seen, ","), "state,setting,notification,reset", "events")
    stop()
    feature:Toggle()
    eq(#seen, 4, "no events after unsubscribe")
end)

test("Router: one key can drive several features; unregistered ones are ignored", function()
    local router = Feature.Router.new()
    local a = newFeature({ Name = "A", Setting = true })
    local b = newFeature({ Name = "B", Setting = true })
    local c = newFeature({ Name = "C", Setting = true })
    a:SetSetting("Keybind", "X"); b:SetSetting("Keybind", "X"); c:SetSetting("Keybind", "Y")
    router:Register(a); router:Register(b); router:Register(c)
    eq(router:Handle("X", true), 2, "two features react")
    eq(a:GetState() and b:GetState(), true, "both on")
    eq(c:GetState(), false, "other key ignored")
    router:Unregister(b)
    router:Handle("X", true)
    eq(a:GetState(), false, "a toggled back")
    eq(b:GetState(), true, "b no longer listens")
end)

print(string.format("\n%d tests, %d passed, %d failed", #results, #results - failed, failed))
os.exit(failed == 0 and 0 or 1)
