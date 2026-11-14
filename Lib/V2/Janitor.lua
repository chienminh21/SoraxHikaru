-- Lib/V2/Janitor.lua
-- Collects things that must be cleaned up together (connections, instances, functions, threads).

local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
    return setmetatable({ _items = {} }, Janitor)
end

local function member(item, name)
    local ok, value = pcall(function()
        return item[name]
    end)
    if ok then
        return value
    end
    return nil
end

local function release(item)
    local kind = type(item)
    if kind == "function" then
        item()
    elseif kind == "thread" then
        task.cancel(item)
    elseif kind == "table" or kind == "userdata" then
        if member(item, "Destroy") then
            item:Destroy()
        elseif member(item, "Disconnect") then
            item:Disconnect()
        end
    end
end

-- Returns the item so it can be written as: local connection = janitor:Add(signal:Connect(...))
function Janitor:Add(item)
    if item ~= nil then
        table.insert(self._items, item)
    end
    return item
end

function Janitor:Connect(signal, handler)
    return self:Add(signal:Connect(handler))
end

-- Runs everything in reverse order. A failing item does not stop the others.
function Janitor:Cleanup()
    local failures = 0
    while #self._items > 0 do
        local item = table.remove(self._items)
        if not pcall(release, item) then
            failures = failures + 1
        end
    end
    return failures
end

function Janitor:Count()
    return #self._items
end

return Janitor
