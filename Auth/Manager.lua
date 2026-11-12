-- Auth/Manager.lua
-- Verification logic: provider selection, result normalization, timeouts, attempt limits and the saved key.
-- No UI in this file.

local Manager = {}
Manager.__index = Manager

Manager.Kind = {
    Ok = "ok",
    Rejected = "rejected", -- the provider said the key is not valid
    Error = "error",       -- the provider could not answer (network, setup, bad response)
    Timeout = "timeout",
    Locked = "locked",
    Busy = "busy",
    Empty = "empty",
    Disposed = "disposed",
}
local Kind = Manager.Kind

local function firstLine(text)
    return (string.match(tostring(text), "^[^\n]*"))
end

-- options: Providers (list of provider objects), Util, Timeout, MaxAttempts, LockSeconds,
-- Storage (see Manager.fileStorage), Deps = { wait, clock, spawn } (defaults: task.wait, os.clock, task.spawn)
function Manager.new(options)
    local deps = options.Deps or {}
    local self = setmetatable({}, Manager)

    self._util = options.Util
    self._providers = options.Providers or {}
    self._selected = 1
    self._timeout = options.Timeout or 15
    self._maxAttempts = options.MaxAttempts or 5
    self._lockSeconds = options.LockSeconds or 30
    self._storage = options.Storage
    self._wait = deps.wait or task.wait
    self._clock = deps.clock or os.clock
    self._spawn = deps.spawn or task.spawn

    self._attempts = 0
    self._lockedUntil = 0
    self._busy = false
    self._disposed = false
    return self
end

function Manager:Providers()
    local list = {}
    for index, provider in ipairs(self._providers) do
        list[index] = {
            Index = index,
            Type = provider.Type,
            Name = provider.Name,
            CanCopy = type(provider.Copy) == "function",
        }
    end
    return list
end

function Manager:Select(index)
    if self._providers[index] then
        self._selected = index
        return true
    end
    return false
end

function Manager:Selected()
    return self._selected
end

function Manager:IsBusy()
    return self._busy
end

-- Seconds until checks are allowed again (0 when not locked)
function Manager:LockedFor()
    return math.max(0, math.ceil(self._lockedUntil - self._clock()))
end

-- After this, running checks are ignored and new ones are refused
function Manager:Dispose()
    self._disposed = true
end

local function failure(kind, message, data)
    return { Success = false, Kind = kind, Message = message, Data = data }
end

-- Runs callback in its own thread and waits at most the timeout. A timeout only stops waiting:
-- the request itself keeps running in the background and its late answer is ignored.
function Manager:_run(callback)
    local state = { finished = false }

    self._spawn(function()
        state.packed = table.pack(pcall(callback))
        state.finished = true
    end)

    local deadline = self._clock() + self._timeout
    while not state.finished and not self._disposed and self._clock() < deadline do
        self._wait(0.05)
    end
    return state
end

-- Accepts: success, message, data   or   { Success = boolean, Message, Data }. Anything else is malformed.
local function readProviderResult(first, second, third)
    if type(first) == "boolean" then
        return first, second ~= nil and tostring(second) or nil, third
    end
    if type(first) == "table" and type(first.Success) == "boolean" then
        return first.Success, first.Message ~= nil and tostring(first.Message) or nil, first.Data
    end
    return nil
end

function Manager:_lock(seconds)
    self._lockedUntil = self._clock() + seconds
end

function Manager:_callProvider(provider, key)
    local state = self:_run(function()
        return provider:Verify(key)
    end)

    if self._disposed then
        return failure(Kind.Disposed, "The key window was closed.")
    end
    if not state.finished then
        return failure(Kind.Timeout, string.format(
            "%s did not answer within %d seconds. The request may still finish in the background; its answer is ignored.",
            provider.Name, self._timeout))
    end

    local packed = state.packed
    if not packed[1] then
        return failure(Kind.Error, provider.Name .. " failed: " .. firstLine(packed[2]))
    end

    local success, message, data = readProviderResult(packed[2], packed[3], packed[4])
    if success == nil then
        return failure(Kind.Error, provider.Name .. " returned an unexpected response (" .. type(packed[2]) .. ").")
    end

    if success then
        return { Success = true, Kind = Kind.Ok, Message = message or "Key accepted.", Data = data }
    end

    local isServiceError = type(data) == "table" and data.ServiceError == true
    return failure(isServiceError and Kind.Error or Kind.Rejected, message or "Invalid key.", data)
end

-- options.CountAttempt = false keeps a wrong key from counting (used for a saved key)
-- Returns { Success, Kind, Message, Data, Provider, Type, LockedFor?, AttemptsLeft? }
function Manager:Verify(key, providerIndex, options)
    if self._disposed then
        return failure(Kind.Disposed, "The key window was closed.")
    end

    key = self._util.trim(key or "")
    if key == "" then
        return failure(Kind.Empty, "Enter a key first.")
    end
    if self._busy then
        return failure(Kind.Busy, "A key check is already running.")
    end

    local locked = self:LockedFor()
    if locked > 0 then
        local result = failure(Kind.Locked, string.format("Too many attempts. Wait %d seconds.", locked))
        result.LockedFor = locked
        return result
    end

    local provider = self._providers[providerIndex or self._selected]
    if not provider then
        return failure(Kind.Error, "No key provider is selected.")
    end

    self._busy = true
    local ok, result = pcall(self._callProvider, self, provider, key)
    self._busy = false

    if not ok then
        result = failure(Kind.Error, "The key check failed: " .. firstLine(result))
    end
    result.Provider = provider.Name
    result.Type = provider.Type

    if self._disposed then
        return failure(Kind.Disposed, "The key window was closed.")
    end

    local countAttempt = not (options and options.CountAttempt == false)
    if result.Kind == Kind.Rejected and countAttempt then
        self._attempts = self._attempts + 1
        if self._attempts >= self._maxAttempts then
            self._attempts = 0
            self:_lock(self._lockSeconds)
            result.LockedFor = self._lockSeconds
            result.Message = result.Message .. string.format(" Too many wrong keys, wait %d seconds.", self._lockSeconds)
        else
            result.AttemptsLeft = self._maxAttempts - self._attempts
        end
    elseif result.Kind == Kind.Ok then
        self._attempts = 0
    end

    local retryAfter = type(result.Data) == "table" and tonumber(result.Data.RetryAfter)
    if retryAfter and retryAfter > 0 then
        self:_lock(retryAfter)
        result.LockedFor = retryAfter
    end

    return result
end

-- Returns ok, message. Providers without a Copy method have no key link.
function Manager:Copy(providerIndex)
    local provider = self._providers[providerIndex or self._selected]
    if not provider then
        return false, "No key provider is selected."
    end
    if type(provider.Copy) ~= "function" then
        return false, provider.Name .. " does not offer a key link."
    end

    local state = self:_run(function()
        return provider:Copy()
    end)
    if self._disposed then
        return false, "The key window was closed."
    end
    if not state.finished then
        return false, "Getting the key link timed out."
    end

    local packed = state.packed
    if not packed[1] then
        return false, firstLine(packed[2])
    end
    if packed[2] == false then
        return false, packed[3] or "Could not copy the key link."
    end
    return true, packed[3] or "Key link copied."
end

-- Saved key ---------------------------------------------------------

function Manager:_indexOfType(typeName)
    for index, provider in ipairs(self._providers) do
        if provider.Type == typeName then
            return index
        end
    end
    return nil
end

function Manager:SaveKey(key, typeName)
    if not self._storage then
        return false
    end
    return self._storage:Write({ Type = typeName, Key = key })
end

function Manager:ForgetKey()
    if self._storage then
        self._storage:Delete()
    end
end

-- Checks the saved key. Returns nil when nothing is saved, otherwise result, providerIndex.
-- A wrong key is forgotten; a network or provider failure keeps it for the next start.
function Manager:TrySavedKey()
    if not self._storage then
        return nil
    end
    local record = self._storage:Read()
    if not record then
        return nil
    end

    local index = self:_indexOfType(record.Type) or self._selected
    local result = self:Verify(record.Key, index, { CountAttempt = false })

    if result.Kind == Kind.Rejected then
        self._storage:Delete()
    elseif result.Success then
        self._selected = index
    end
    return result, index
end

-- Saved key file: <folder>/auth_<scope>.json with { Type, Key }. Never provider settings or secrets.
-- options: Folder, Scope, Util, Fs = { isfile, readfile, writefile, delfile, makefolder, isfolder }
function Manager.fileStorage(options)
    local util = options.Util
    local fs = options.Fs or {
        isfile = isfile,
        readfile = readfile,
        writefile = writefile,
        delfile = delfile,
        makefolder = makefolder,
        isfolder = isfolder,
    }
    local folder = options.Folder
    local path = folder .. "/auth_" .. util.sanitize(options.Scope or "default") .. ".json"

    local storage = {}

    function storage:Available()
        return type(fs.writefile) == "function" and type(fs.readfile) == "function" and type(fs.isfile) == "function"
    end

    function storage:Read()
        if not self:Available() then
            return nil
        end
        local ok, text = pcall(function()
            if fs.isfile(path) then
                return fs.readfile(path)
            end
        end)
        if not ok or type(text) ~= "string" then
            return nil
        end

        local decoded, record = util.jsonDecode(text)
        if decoded and type(record) == "table" and type(record.Key) == "string" and record.Key ~= "" then
            return record
        end
        return nil
    end

    function storage:Write(record)
        if not self:Available() then
            return false
        end
        local encoded, text = util.jsonEncode(record)
        if not encoded then
            return false
        end
        return (pcall(function()
            if fs.makefolder and fs.isfolder and not fs.isfolder(folder) then
                fs.makefolder(folder)
            end
            fs.writefile(path, text)
        end))
    end

    function storage:Delete()
        pcall(function()
            if fs.delfile and fs.isfile and fs.isfile(path) then
                fs.delfile(path)
            end
        end)
    end

    return storage
end

return Manager

