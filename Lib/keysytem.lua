
-- Sora x Hikaru | KeySystem Test

local KEY_SYSTEM_URL = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/refs/heads/main/Auth/KeySystem.lua"

local function loadKeySystem()
    local success, source = pcall(function()
        return game:HttpGet(KEY_SYSTEM_URL)
    end)

    if not success then
        return nil, "Download failed: " .. tostring(source)
    end

    if type(source) ~= "string" or #source == 0 then
        return nil, "Downloaded source is empty"
    end

    local compileSuccess, compiled = pcall(loadstring, source)

    if not compileSuccess or type(compiled) ~= "function" then
        return nil, "Compile failed: " .. tostring(compiled)
    end

    local executeSuccess, module = pcall(compiled)

    if not executeSuccess then
        return nil, "Module execution failed: " .. tostring(module)
    end

    if type(module) ~= "table" or type(module.Run) ~= "function" then
        return nil, "Invalid KeySystem module"
    end

    return module
end

local KeySystem, loadError = loadKeySystem()

if not KeySystem then
    warn("[SxH Test] " .. tostring(loadError))
    return
end

print("[SxH Test] KeySystem module loaded")

local success, result = KeySystem.Run({}, {
    Enabled = true,

    Title = "Sora x Hikaru",
    Description = "KeySystem functionality test.",

    Keys = {
        "1",
        "2",
    },

    CaseSensitive = false,
    SaveKey = false,

    GetKeyLink = "https://discord.gg/6y7TpYTBkW",

    MaxAttempts = 5,
    LockSeconds = 10,
    Timeout = 15,

    OnSuccess = function(info)
        print("[SxH Test] Authentication successful")
        print("Service:", info.Service)
        print("CheckedAt:", info.CheckedAt)
    end,
})

if success then
    print("[SxH Test] KEY SYSTEM PASSED")
    print("Authentication result:", result.Service)
else
    warn("[SxH Test] KeySystem returned:", result)
end
