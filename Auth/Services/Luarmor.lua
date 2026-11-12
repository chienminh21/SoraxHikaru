-- Auth/Services/Luarmor.lua
-- Luarmor key service. Written from WindUI's adapter (src/utils/services/Luarmor.lua).
-- Luarmor's client API is its own SDK, so the first check downloads and runs
-- https://sdkapi-public.luarmor.net/library.lua (fixed address, not configurable). That is third-party
-- code running in your script: only use this provider if you accept that.
--
-- Entry: { Type = "luarmor", ScriptId = "your-script-id", Discord = "https://discord.gg/...", KeyLink = "optional" }
-- Get Key copies KeyLink, or Discord when KeyLink is not set. Without either there is no Get Key button.
-- After a valid key, result.Data.LoadScript() runs the protected script through the SDK.

local Luarmor = {}

local sdkUrl = "https://sdkapi-public.luarmor.net/library.lua"

function Luarmor.new(config, context)
    local util = context.Util
    local scriptId = tostring(config.ScriptId)
    local sdk = nil

    local self = { Name = "Luarmor" }

    local function loadSdk()
        if sdk then
            return sdk
        end

        local ok, loaded = pcall(function()
            return loadstring(game:HttpGet(sdkUrl))()
        end)
        if not ok then
            return nil, util.firstLine(loaded)
        end
        if type(loaded) ~= "table" or type(loaded.check_key) ~= "function" then
            return nil, "the SDK did not return the expected API"
        end

        loaded.script_id = scriptId
        sdk = loaded
        return sdk
    end

    function self:Verify(key)
        local api, loadError = loadSdk()
        if not api then
            return util.serviceError("Could not load the Luarmor SDK: " .. loadError)
        end

        local ok, status = pcall(api.check_key, key)
        if not ok or type(status) ~= "table" or type(status.code) ~= "string" then
            return util.serviceError("Luarmor sent an unexpected answer.")
        end

        if status.code == "KEY_VALID" then
            return true, "Whitelisted!", {
                Code = status.code,
                Note = type(status.data) == "table" and status.data.note or nil,
                LoadScript = function()
                    getgenv().script_key = key -- the SDK reads this global
                    return api.load_script()
                end,
            }
        end
        if status.code == "KEY_HWID_LOCKED" then
            return false, "Key linked to a different HWID. Please reset it using the bot."
        end
        if status.code == "KEY_INCORRECT" then
            return false, "Key is wrong or deleted!"
        end
        return false, "Key check failed: " .. tostring(status.message) .. " (" .. status.code .. ")"
    end

    local keyLink = config.KeyLink or config.Discord
    if type(keyLink) == "string" and keyLink ~= "" then
        function self:Copy()
            if util.copy(keyLink) then
                return true, "Link copied."
            end
            return false, "Clipboard is not available. Open: " .. keyLink
        end
    end

    return self
end

return Luarmor
