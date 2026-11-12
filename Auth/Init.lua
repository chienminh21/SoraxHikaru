
-- Auth/Util.lua
-- Shared helpers for the key system: strings, JSON, HTTP and clipboard.

local Util = {}

function Util.trim(text)
    return (string.gsub(tostring(text), "^%s*(.-)%s*$", "%1"))
end

function Util.sanitize(text)
    return (string.gsub(string.lower(tostring(text)), "[^%w]+", "_"))
end

function Util.firstLine(text)
    return (string.match(tostring(text), "^[^\n]*"))
end

-- Failure that is not about the key itself (network, HTTP status, parsing, setup).
-- The manager does not count these as wrong attempts.
-- extra.RetryAfter (seconds) asks the manager to pause new checks.
function Util.serviceError(message, extra)
    local data = { ServiceError = true }
    if extra then
        for field, value in pairs(extra) do
            data[field] = value
        end
    end
    return false, message, data
end

local function httpService()
    return game:GetService("HttpService")
end

-- Returns ok, value
function Util.jsonDecode(text)
    local ok, value = pcall(function()
        return httpService():JSONDecode(text)
    end)
    return ok, value
end

-- Returns ok, text
function Util.jsonEncode(value)
    local ok, text = pcall(function()
        return httpService():JSONEncode(value)
    end)
    return ok, text
end

function Util.urlEncode(text)
    return httpService():UrlEncode(text)
end

-- Best identifier available. gethwid is not part of every executor; the user id fallback is easy to spoof.
function Util.getHwid()
    if type(gethwid) == "function" then
        local ok, id = pcall(gethwid)
        if ok and id then
            return tostring(id)
        end
    end

    local ok, player = pcall(function()
        return game:GetService("Players").LocalPlayer
    end)
    if ok and player then
        return tostring(player.UserId)
    end
    return "unknown"
end

function Util.requestFunction()
    return (syn and syn.request) or request or http_request or syn_request
end

-- options: { Url, Method, Headers, Body }. Returns the response table, or nil and a reason.
-- Executors do not let a script cancel a running request, so callers can only stop waiting for it.
function Util.request(options)
    local send = Util.requestFunction()
    if not send then
        return nil, "this executor has no HTTP request function"
    end

    local ok, response = pcall(send, options)
    if not ok then
        return nil, "request failed: " .. Util.firstLine(response)
    end
    if type(response) ~= "table" then
        return nil, "the request returned no response"
    end
    return response
end

function Util.copy(text)
    local copy = setclipboard or toclipboard
    if not copy then
        return false
    end
    return (pcall(copy, text))
end

return Util
