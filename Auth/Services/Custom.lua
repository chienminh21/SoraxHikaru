-- Custom provider: wraps a user function or table with Validate/Verify
local Custom = {}

local VALIDATE_FIELDS = { "Validate", "Verify", "Check", "CheckKey", "Authenticate", "Auth", "Login" }

local function pick(service)
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
    return nil
end

function Custom.New(options)
    options = options or {}
    local handler = options.Handler or options.Service or options.Validate
    local validator = pick(handler)
    if not validator then
        error("Custom provider needs Handler/Service with Validate or a function")
    end

    local function Validate(key, context)
        return validator(key, context)
    end

    return {
        Name = options.Name or "Custom",
        Validate = Validate,
        Verify = Validate,
        GetKeyLink = options.GetKeyLink,
    }
end

return Custom

