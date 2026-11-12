-- Auth/Registry.lua
-- Maps provider types ("platoboost", "luarmor"...) to provider modules and creates provider objects.
-- Adding a provider: add a file under Auth/Services/ and one line to builtIn below,
-- or call Registry:Register(type, definition) at runtime.

local Registry = {}
Registry.__index = Registry

local aliases = {
    panda = "pandadevelopment",
    junkie = "junkiedevelopment",
}

-- Args are the entry fields that must be present. File is relative to Auth/.
local builtIn = {
    ["local"] = { Name = "Local", File = "Services/Local", Args = { "Keys" } },
    custom = { Name = "Custom", File = "Services/Custom", Args = {} },
    platoboost = { Name = "Platoboost", File = "Services/Platoboost", Args = { "ServiceId" } },
    pandadevelopment = { Name = "Panda Development", File = "Services/PandaDevelopment", Args = { "ServiceId" } },
    luarmor = { Name = "Luarmor", File = "Services/Luarmor", Args = { "ScriptId" } },
    junkiedevelopment = {
        Name = "Junkie Development",
        File = "Services/JunkieDevelopment",
        Args = { "ServiceId", "ApiKey", "Provider" },
    },
}

-- Field names people try because other libraries use them
local fieldHints = {
    pandadevelopment = { ProductId = "ServiceId" },
    luarmor = { ProjectId = "ScriptId" },
}

local function firstLine(text)
    return (string.match(tostring(text), "^[^\n]*"))
end

function Registry.normalizeType(name)
    if type(name) ~= "string" then
        return nil
    end
    local key = string.lower((string.gsub(name, "[%s_%-]+", "")))
    key = aliases[key] or key
    if key == "" then
        return nil
    end
    return key
end

-- options.Load(path) must return the module table for a file such as "Services/Local"
function Registry.new(options)
    local self = setmetatable({}, Registry)
    self._load = options and options.Load
    self._definitions = {}
    for typeName, definition in pairs(builtIn) do
        self._definitions[typeName] = {
            Name = definition.Name,
            File = definition.File,
            Args = definition.Args,
        }
    end
    return self
end

-- definition: { Name, Args = { "Field" }, new = function(entry, context) } or { File = "Services/X" }
function Registry:Register(typeName, definition)
    local normalized = Registry.normalizeType(typeName)
    if not normalized then
        error("the provider type must be a non-empty string", 2)
    end
    if type(definition) ~= "table" then
        error("the provider definition must be a table", 2)
    end

    local module = nil
    local constructor = definition.new or definition.New
    if type(constructor) == "function" then
        module = { new = constructor }
    elseif type(definition.File) ~= "string" then
        error("a provider needs a new() function or a File", 2)
    end

    self._definitions[normalized] = {
        Name = definition.Name or typeName,
        File = definition.File,
        Args = definition.Args or {},
        Module = module,
    }
end

function Registry:Has(typeName)
    return self._definitions[Registry.normalizeType(typeName) or ""] ~= nil
end

function Registry:List()
    local names = {}
    for typeName in pairs(self._definitions) do
        table.insert(names, typeName)
    end
    table.sort(names)
    return names
end

local function missingFields(definition, entry)
    local missing = {}
    for _, field in ipairs(definition.Args) do
        if entry[field] == nil or entry[field] == "" then
            table.insert(missing, field)
        end
    end
    return missing
end

function Registry:_module(typeName, definition)
    if definition.Module then
        return definition.Module
    end
    if not self._load then
        return nil, "no module loader was given to the registry"
    end

    local ok, loaded = pcall(self._load, definition.File)
    if not ok then
        return nil, string.format('could not load "%s": %s', definition.File, firstLine(loaded))
    end
    if type(loaded) ~= "table" then
        return nil, string.format('"%s" did not return a table', definition.File)
    end

    definition.Module = loaded
    return loaded
end

-- Returns the provider object, or nil and a message that says what is wrong.
-- context is given to the provider constructor (Util, Load, ...).
function Registry:Create(entry, context)
    if type(entry) ~= "table" then
        return nil, "a provider entry must be a table"
    end

    local typeName = Registry.normalizeType(entry.Type)
    if not typeName then
        return nil, "a provider entry needs a Type"
    end

    local definition = self._definitions[typeName]
    if not definition then
        return nil, string.format('unknown provider type "%s" (known: %s)', tostring(entry.Type), table.concat(self:List(), ", "))
    end

    local missing = missingFields(definition, entry)
    if #missing > 0 then
        local message = string.format('provider "%s" is missing: %s', typeName, table.concat(missing, ", "))
        for wrong, right in pairs(fieldHints[typeName] or {}) do
            if entry[wrong] ~= nil then
                message = message .. string.format(" (%s uses %s, not %s)", definition.Name, right, wrong)
            end
        end
        return nil, message
    end

    local module, moduleError = self:_module(typeName, definition)
    if not module then
        return nil, string.format('provider "%s": %s', typeName, moduleError)
    end

    local constructor = module.new or module.New
    if type(constructor) ~= "function" then
        return nil, string.format('provider "%s" has no new() function', typeName)
    end

    local ok, instance, constructorError = pcall(constructor, entry, context or {})
    if not ok then
        return nil, string.format('provider "%s" failed to start: %s', typeName, firstLine(instance))
    end
    if instance == nil then
        return nil, string.format('provider "%s": %s', typeName, tostring(constructorError or "it could not be created"))
    end
    if type(instance) ~= "table" or type(instance.Verify) ~= "function" then
        return nil, string.format('provider "%s" did not return an object with a Verify method', typeName)
    end

    instance.Type = typeName
    instance.Name = entry.Title or instance.Name or definition.Name
    return instance
end

return Registry

