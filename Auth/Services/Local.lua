-- Local key list provider (no network)
local Local = {}

local function trim(s)
    return (string.gsub(tostring(s or ""), "^%s*(.-)%s*$", "%1"))
end

function Local.New(options)
    options = options or {}
    local keys = options.Keys or options.keys or {}
    local caseSensitive = options.CaseSensitive == true
    local lookup = {}

    for _, key in ipairs(keys) do
        local value = trim(key)
        if value ~= "" then
            lookup[caseSensitive and value or string.upper(value)] = true
        end
    end

    local function Validate(key)
        key = trim(key)
        if key == "" then
            return false, "Empty key"
        end
        local value = caseSensitive and key or string.upper(key)
        if lookup[value] then
            return true, "Key accepted", { Provider = "Local" }
        end
        return false, "Invalid key"
    end

    return {
        Name = "Local",
        Validate = Validate,
        Verify = Validate,
        GetKeyLink = options.GetKeyLink,
    }
end

return Local

