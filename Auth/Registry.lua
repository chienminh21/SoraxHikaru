-- Provider registry for multi-provider KeySystem
local Registry = {
    _providers = {},
}

local ALIASES = {
    local = "Local",
    custom = "Custom",
    platoboost = "Platoboost",
    panda = "PandaDevelopment",
    pandadevelopment = "PandaDevelopment",
    pandadev = "PandaDevelopment",
    luarmor = "Luarmor",
    junkie = "JunkieDevelopment",
    junkiedevelopment = "JunkieDevelopment",
}

function Registry.NormalizeType(name)
    if type(name) ~= "string" then return nil end
    local key = string.lower((string.gsub(name, "%s+", "")))
    return ALIASES[key] or name
end

function Registry.Register(name, factory)
    if type(name) ~= "string" or type(factory) ~= "function" then
        return false, "Register needs name string and factory function"
    end
    Registry._providers[Registry.NormalizeType(name) or name] = factory
    return true
end

function Registry.Get(name)
    local key = Registry.NormalizeType(name)
    return key and Registry._providers[key] or nil
end

function Registry.List()
    local names = {}
    for name in pairs(Registry._providers) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Built-in factories (return module tables with .New)
local function tryRequire(path)
    local ok, mod = pcall(function()
        return require(path)
    end)
    if ok then return mod end
    return nil
end

function Registry.BootstrapBuiltins(loadServiceModule)
    -- loadServiceModule(name) -> module table with .New
    local builtins = {
        "Local",
        "Custom",
        "Platoboost",
        "PandaDevelopment",
        "Luarmor",
        "JunkieDevelopment",
    }
    for _, name in ipairs(builtins) do
        local mod = loadServiceModule and loadServiceModule(name)
        if mod and type(mod.New) == "function" then
            Registry.Register(name, mod.New)
        end
    end
end

function Registry.Create(providerConfig)
    if type(providerConfig) ~= "table" then
        return nil, "provider config must be a table"
    end

    local typeName = Registry.NormalizeType(providerConfig.Type or providerConfig.Provider or providerConfig.Name)
    if not typeName then
        return nil, "provider Type is required"
    end

    local factory = Registry.Get(typeName)
    if not factory then
        return nil, 'unknown provider "' .. tostring(providerConfig.Type) .. '"'
    end

    local ok, service = pcall(factory, providerConfig)
    if not ok then
        return nil, "provider init failed: " .. tostring(service)
    end
    if type(service) ~= "table" then
        return nil, "provider did not return a service table"
    end
    service.Name = service.Name or typeName
    return service
end

return Registry

