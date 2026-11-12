-- Auth/Services/PandaDevelopment.lua
-- Panda Development key service. Written from WindUI's adapter (src/utils/services/PandaDevelopment.lua):
-- same validate endpoint, request body, answer field and key link. It has only been run against a local
-- mock, not the live service. (Panda's older documented "v2_validation" endpoint is a different API.)
--
-- Entry: { Type = "pandadevelopment", ServiceId = "your-service-id" }
-- Needs an executor with an HTTP request function.

local PandaDevelopment = {}

local validateUrl = "https://api.pandauth.com/api/v1/keys/validate"
local keyLinkPattern = "https://new.pandadevelopment.net/getkey/%s?hwid=%s"

function PandaDevelopment.new(config, context)
    local util = context.Util
    local serviceId = tostring(config.ServiceId)

    local self = { Name = "Panda Development" }

    function self:Verify(key)
        local encoded, body = util.jsonEncode({
            ServiceID = serviceId,
            HWID = util.getHwid(),
            Key = key,
        })
        if not encoded then
            return util.serviceError("Could not build the request.")
        end

        local response, requestError = util.request({
            Url = validateUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
        if not response then
            return util.serviceError(requestError)
        end

        if response.StatusCode == 429 then
            return util.serviceError("Panda Development is rate limiting this client. Try again in a moment.", { RetryAfter = 20 })
        end

        local decoded, answer = util.jsonDecode(response.Body)
        if not decoded or type(answer) ~= "table" or answer.Authenticated_Status == nil then
            return util.serviceError("Panda Development sent an unexpected answer (HTTP " .. tostring(response.StatusCode) .. ").")
        end

        if answer.Authenticated_Status == "Success" then
            return true, "Key accepted.", answer
        end
        return false, tostring(answer.Note or "Invalid key.")
    end

    function self:Copy()
        local link = string.format(keyLinkPattern, util.urlEncode(serviceId), util.urlEncode(util.getHwid()))
        if util.copy(link) then
            return true, "Key link copied. Open it in your browser."
        end
        return false, "Clipboard is not available. Open: " .. link
    end

    return self
end

return PandaDevelopment

