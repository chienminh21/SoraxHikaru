-- Multi-provider validation manager
local Manager = {}

local VALIDATE_FIELDS = { "Validate", "Verify", "Check", "CheckKey", "Authenticate", "Auth", "Login" }

local function firstDefined(source, names)
    for _, name in ipairs(names) do
        if source[name] ~= nil then
            return source[name]
        end
    end
end

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

function Manager.RunWithTimeout(callback, seconds)
    local finished = false
    local results = nil
    task.spawn(function()
        results = table.pack(pcall(callback))
        finished = true
    end)
    local deadline = os.clock() + (seconds or 15)
    while not finished and os.clock() < deadline do
        task.wait(0.05)
    end
    if not finished then
        return false, "the key service did not answer in time"
    end
    return table.unpack(results, 1, results.n)
end

function Manager.ValidateService(service, key, context, timeout)
    local validator = pickValidator(service)
    if not validator then
        return false, "service has no validator"
    end
    local ok, first, second, third = Manager.RunWithTimeout(function()
        return validator(key, context)
    end, timeout)
    if not ok then
        return false, tostring(first)
    end
    return readResult(first, second, third)
end

-- Try providers in order until one succeeds
function Manager.ValidateAny(services, key, context, timeout)
    if type(services) ~= "table" or #services == 0 then
        return false, "no providers configured"
    end

    local errors = {}
    for _, service in ipairs(services) do
        local valid, message, data = Manager.ValidateService(service, key, context, timeout)
        if valid then
            return true, message, data, service.Name
        end
        table.insert(errors, (service.Name or "?") .. ": " .. tostring(message or "failed"))
    end
    return false, table.concat(errors, " | ")
end

function Manager.ResolveKeyLink(services, configLink)
    if type(configLink) == "string" and configLink ~= "" then
        return configLink
    end
    for _, service in ipairs(services or {}) do
        local link = service.GetKeyLink
        if type(link) == "function" then
            local ok, value = pcall(link)
            if ok and type(value) == "string" and value ~= "" then
                return value
            end
        elseif type(link) == "string" and link ~= "" then
            return link
        end
    end
    return nil
end

return Manager

