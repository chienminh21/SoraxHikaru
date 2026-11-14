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

-- Hex strings, so presets can be stored and edited as plain text
Theme.Presets = {
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
Theme.DefaultPreset = "Pure Black"

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
