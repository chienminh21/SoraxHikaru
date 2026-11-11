-- Luarmor | https://luarmor.net
-- Loads official public SDK. Client-side only; not secure authorization.
local Luarmor = {}

function Luarmor.New(options)
    options = type(options) == "table" and options or { ScriptId = options }
    local scriptId = options.ScriptId or options.ProjectId
    local discord = options.Discord or options.GetKeyLink
    if not scriptId then
        error("Luarmor requires ScriptId")
    end

    local API
    local loadErr
    local ok = pcall(function()
        local src = game:HttpGet("https://sdkapi-public.luarmor.net/library.lua")
        API = loadstring(src)()
        API.script_id = scriptId
    end)
    if not ok or not API then
        loadErr = "Failed to load Luarmor SDK"
    end

    local function Validate(key)
        if loadErr then
            return false, loadErr
        end
        key = tostring(key or "")
        if key == "" then
            return false, "Empty key"
        end

        local status
        local checkOk, err = pcall(function()
            status = API.check_key(key)
        end)
        if not checkOk or type(status) ~= "table" then
            return false, "Key check failed: " .. tostring(err)
        end

        if status.code == "KEY_VALID" then
            return true, "Whitelisted!", status
        elseif status.code == "KEY_HWID_LOCKED" then
            return false, "Key linked to a different HWID"
        elseif status.code == "KEY_INCORRECT" then
            return false, "Key is wrong or deleted"
        end
        return false, tostring(status.message or status.code or "Unknown error")
    end

    local function GetKeyLink()
        return type(discord) == "string" and discord or nil
    end

    local function Copy()
        local link = GetKeyLink()
        if link then
            if setclipboard then setclipboard(link)
            elseif toclipboard then toclipboard(link) end
        end
        return link
    end

    return {
        Name = "Luarmor",
        Validate = Validate,
        Verify = Validate,
        GetKeyLink = GetKeyLink,
        Copy = Copy,
    }
end

return Luarmor

