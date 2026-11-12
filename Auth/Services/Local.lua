-- Auth/Services/Local.lua
-- Checks keys against a list that lives in the script itself. Useful for testing and small private scripts.
-- Anyone who can read the script can read these keys, so this is not protection for a public script.
--
-- Entry: { Type = "local", Keys = { "KEY-1", "KEY-2" }, CaseSensitive = false, GetKeyLink = "https://..." }

local Local = {}

function Local.new(config, context)
    local util = context.Util
    local caseSensitive = config.CaseSensitive == true

    if type(config.Keys) ~= "table" or #config.Keys == 0 then
        return nil, "Keys must be a list with at least one key"
    end

    local function normalize(key)
        local value = util.trim(key)
        return caseSensitive and value or string.upper(value)
    end

    local lookup = {}
    for _, key in ipairs(config.Keys) do
        if type(key) == "string" and util.trim(key) ~= "" then
            lookup[normalize(key)] = true
        end
    end

    local self = { Name = "Local" }

    function self:Verify(key)
        if lookup[normalize(key)] then
            return true, "Key accepted."
        end
        return false, "Invalid key."
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

return Local
