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
