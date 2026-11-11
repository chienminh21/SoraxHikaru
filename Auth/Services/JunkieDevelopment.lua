-- Junkie Development
-- Requires global JunkieProtected injected by their loader. Without it, validation fails clearly.
local JunkieDevelopment = {}

function JunkieDevelopment.New(options)
    options = type(options) == "table" and options or {}
    local serviceId = options.ServiceId
    local apiKey = options.ApiKey
    local provider = options.Provider

    if type(JunkieProtected) == "table" then
        if apiKey then JunkieProtected.API_KEY = apiKey end
        if provider then JunkieProtected.PROVIDER = provider end
        if serviceId then JunkieProtected.SERVICE_ID = serviceId end
    end

    local function Validate(key)
        if type(JunkieProtected) ~= "table" then
            return false, "JunkieProtected runtime not found"
        end
        key = tostring(key or "")
        if key == "" then
            return false, "No key provided"
        end

        if type(JunkieProtected.IsKeylessMode) == "function" then
            local keyless = JunkieProtected.IsKeylessMode()
            if type(keyless) == "table" and keyless.keyless_mode then
                return true, "Keyless mode enabled"
            end
        end

        if type(JunkieProtected.ValidateKey) ~= "function" then
            return false, "JunkieProtected.ValidateKey missing"
        end

        local result = JunkieProtected.ValidateKey({ Key = key })
        if result == "valid" then
            return true, "Key is valid!"
        end

        local link = ""
        if type(JunkieProtected.GetKeyLink) == "function" then
            link = tostring(JunkieProtected.GetKeyLink() or "")
        end
        return false, "Invalid key" .. (link ~= "" and (". Get one from: " .. link) or "")
    end

    local function GetKeyLink()
        if type(JunkieProtected) == "table" and type(JunkieProtected.GetKeyLink) == "function" then
            return JunkieProtected.GetKeyLink()
        end
        return nil
    end

    local function Copy()
        local link = GetKeyLink()
        if link and setclipboard then setclipboard(link) end
        return link
    end

    return {
        Name = "JunkieDevelopment",
        Validate = Validate,
        Verify = Validate,
        GetKeyLink = GetKeyLink,
        Copy = Copy,
    }
end

return JunkieDevelopment
