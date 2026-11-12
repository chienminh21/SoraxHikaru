-- Auth/Services/Custom.lua
-- Your own check. Two ways to use it:
--
--   { Type = "custom", Name = "Sora Auth", Verify = function(key, info) return true, "Welcome" end }
--       info = { Hwid = "...", Config = <this entry> }. Return success, message, data.
--
--   { Type = "custom", Name = "Sora Auth", Endpoint = "https://your-server/verify" }
--       POST with JSON { "Key": "...", "Hwid": "..." }
--       Answer (JSON): { "Valid": true, "Message": "optional", "Data": { ... optional } }
--       Check the key on your server. Do not put admin credentials or signing secrets in this script.
--
-- Optional: GetKeyLink = "https://..." enables the Get Key button.

local Custom = {}

function Custom.new(config, context)
    local util = context.Util

    local verifier = config.Verify or config.Handler
    if verifier ~= nil and type(verifier) ~= "function" then
        return nil, "Verify must be a function"
    end

    local endpoint = config.Endpoint
    if verifier == nil and endpoint == nil then
        return nil, "needs a Verify function or an https Endpoint (a Name alone is not enough)"
    end
    if endpoint ~= nil and (type(endpoint) ~= "string" or not string.match(endpoint, "^https://[^%s]+$")) then
        return nil, "Endpoint must be an https:// URL"
    end

    local self = { Name = config.Name or "Custom" }

    local function verifyAtEndpoint(key)
        local encoded, body = util.jsonEncode({ Key = key, Hwid = util.getHwid() })
        if not encoded then
            return util.serviceError("Could not build the request.")
        end

        local response, requestError = util.request({
            Url = endpoint,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
        if not response then
            return util.serviceError(requestError)
        end

        if response.StatusCode == 429 then
            local headers = response.Headers or {}
            local retryAfter = tonumber(headers["Retry-After"] or headers["retry-after"]) or 20
            return util.serviceError("The server is rate limiting requests.", { RetryAfter = retryAfter })
        end
        if response.StatusCode ~= 200 then
            return util.serviceError("The server answered with HTTP " .. tostring(response.StatusCode) .. ".")
        end

        local decoded, answer = util.jsonDecode(response.Body)
        if not decoded or type(answer) ~= "table" or type(answer.Valid) ~= "boolean" then
            return util.serviceError("The server sent an unexpected answer.")
        end

        if answer.Valid then
            return true, answer.Message or "Key accepted.", answer.Data
        end
        return false, answer.Message or "Invalid key."
    end

    function self:Verify(key)
        if verifier then
            return verifier(key, { Hwid = util.getHwid(), Config = config })
        end
        return verifyAtEndpoint(key)
    end

    if type(config.GetKeyLink) == "string" and config.GetKeyLink ~= "" then
        function self:Copy()
            if util.copy(config.GetKeyLink) then
                return true, "Key link copied."
            end
            return false, "Clipboard is not available. Open: " .. config.GetKeyLink
        end
    end

    return self
end

return Custom
