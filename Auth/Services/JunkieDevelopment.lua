
-- Auth/Services/JunkieDevelopment.lua
-- Junkie Development key service. Written from WindUI's adapter (src/utils/services/JunkieDevelopment.lua).
-- Junkie does not have a public HTTP API here: its own loader injects a global called JunkieProtected.
-- This provider only works when the script is started through Junkie's loader, and it has not been
-- tested against the real loader.
--
-- Entry: { Type = "junkiedevelopment", ServiceId = "...", ApiKey = "...", Provider = "..." }
-- ApiKey is part of Junkie's own client design, so treat it as visible to anyone who gets the script.
-- WindUI also calls a global load() after a valid key; here it is exposed as result.Data.Load instead.

local JunkieDevelopment = {}

function JunkieDevelopment.new(config, context)
    local util = context.Util
    local self = { Name = "Junkie Development" }

    local function getApi()
        local api = getgenv().JunkieProtected
        if type(api) ~= "table" then
            return nil, "JunkieProtected is not available. Start the script through Junkie Development's loader."
        end
        api.API_KEY = config.ApiKey
        api.PROVIDER = config.Provider
        api.SERVICE_ID = config.ServiceId
        return api
    end

    function self:Verify(key)
        local api, apiError = getApi()
        if not api then
            return util.serviceError(apiError)
        end
        if type(api.ValidateKey) ~= "function" then
            return util.serviceError("JunkieProtected has no ValidateKey function.")
        end

        local ok, result = pcall(api.ValidateKey, { Key = key })
        if not ok then
            return util.serviceError("Junkie Development failed: " .. util.firstLine(result))
        end
        if type(result) ~= "string" then
            return util.serviceError("Junkie Development sent an unexpected answer.")
        end

        if result == "valid" then
            local loader = getgenv().load
            return true, "Whitelisted!", {
                Load = type(loader) == "function" and loader or nil,
            }
        end
        return false, "Invalid key (" .. result .. ")."
    end

    function self:Copy()
        local api, apiError = getApi()
        if not api or type(api.GetKeyLink) ~= "function" then
            return false, apiError or "JunkieProtected has no GetKeyLink function."
        end

        local ok, link = pcall(api.GetKeyLink)
        if not ok or type(link) ~= "string" or link == "" then
            return false, "Junkie Development did not return a key link."
        end
        if util.copy(link) then
            return true, "Key link copied."
        end
        return false, "Clipboard is not available. Open: " .. link
    end

    return self
end

return JunkieDevelopment
