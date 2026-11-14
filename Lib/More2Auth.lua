
--[[
    Sora x Hikaru | main.lua
    KeySystem runs before the main UI.
]]

getgenv().GG = {
    UIName = "Sora x Hikaru",
    Version = "v2.0",
    Theme = "Dark",
}

local BASE = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/"

local function loadModule(path)
    local success, source = pcall(function()
        return game:HttpGet(BASE .. path .. ".lua")
    end)

    if not success then
        error("Failed to download " .. path .. ": " .. tostring(source))
    end

    local chunk, compileError = loadstring(source, "@" .. path)

    if not chunk then
        error("Failed to compile " .. path .. ": " .. tostring(compileError))
    end

    return chunk()
end

local function createAuthentication()
    local Util = loadModule("Auth/Init")
    local KeyWindow = loadModule("Auth/KeySystem")
    local ManagerModule = loadModule("Auth/Manager")
    local RegistryModule = loadModule("Auth/Registry")

    local Registry = RegistryModule.new({
        Load = function(path)
            return loadModule("Auth/" .. path)
        end,
    })

    -- Local provider for testing.
    -- Replace this with your real provider configuration when ready.
    local pandaProvider, pandaError = Registry:Create({
    Type = "pandadevelopment",
    ServiceId = "YOUR_PANDA_NAME_SERVICE",
}, {
    Util = Util,
    Load = function(path)
        return loadModule("Auth/" .. path)
    end,
})

if not pandaProvider then
    error(pandaError)
end

local platoboostProvider, platoboostError = Registry:Create({
    Type = "platoboost",
    ServiceId = "YOUR_PLATOBOOST_SERVICE_ID",
    Secret = "YOUR_PLATOBOOST_SECRET", -- 
}, {
    Util = Util,
    Load = function(path)
        return loadModule("Auth/" .. path)
    end,
})

if not platoboostProvider then
    error(platoboostError)
end

local Manager = ManagerModule.new({
    Util = Util,
    Providers = {
        pandaProvider,       -- Provider 1
        platoboostProvider,  -- Provider 2
    },
    Timeout = 20,
    MaxAttempts = 5,
    LockSeconds = 30,
})

    local authenticated = false
    local closed = false
    local controller

    controller = KeyWindow.new({
        Title = "Sora x Hikaru",
        Note = "Authentication",
        Description = "Enter your key to continue.",

        Providers = Manager:Providers(),
        ShowRemember = false,
        AllowSkip = false,

        Colors = {
            Overlay = Color3.fromRGB(0, 0, 0),
            Card = Color3.fromRGB(12, 12, 12),
            Raised = Color3.fromRGB(24, 24, 24),
            Stroke = Color3.fromRGB(45, 45, 45),
            Text = Color3.fromRGB(245, 245, 245),
            Muted = Color3.fromRGB(155, 155, 155),
            Accent = Color3.fromRGB(115, 115, 115),
            AccentText = Color3.fromRGB(255, 255, 255),
        },

        Hooks = {
            OnSubmit = function(key)
                if closed or controller:IsClosed() then
                    return
                end

                controller:SetBusy(true)
                controller:SetStatus("Checking key...", "info")

                local result = Manager:Verify(key)

                if closed or controller:IsClosed() then
                    return
                end

                controller:SetBusy(false)

                if result.Success then
                    controller:SetStatus("Authentication successful.", "success")

                    task.wait(0.5)

                    if closed or controller:IsClosed() then
                        return
                    end

                    authenticated = true
                    controller:Destroy()
                    return
                end

                controller:SetStatus(
                    result.Message or "Verification failed.",
                    "error"
                )

                if result.LockedFor then
                    controller:Lock(result.LockedFor)
                end
            end,

            OnCopy = function(index)
                if closed or controller:IsClosed() then
                    return
                end

                controller:SetBusy(true)

                local success, message = Manager:Copy(index)

                if closed or controller:IsClosed() then
                    return
                end

                controller:SetBusy(false)
                controller:SetStatus(
                    message or (success and "Copied." or "Copy failed."),
                    success and "success" or "error"
                )
            end,

            OnSelect = function(index)
                Manager:Select(index)
            end,

            OnSkip = function()
                -- Skipping is disabled.
            end,

            OnClose = function()
                closed = true
                Manager:Dispose()
                controller:Destroy()
            end,
        },
    })

    while not authenticated and not closed and not controller:IsClosed() do
        task.wait(0.1)
    end

    Manager:Dispose()

    if not authenticated then
        return false
    end

    return true
end

local authSuccess, authenticated = pcall(createAuthentication)

if not authSuccess then
    warn("[Sora x Hikaru] Authentication error:", authenticated)
    return
end

if not authenticated then
    warn("[Sora x Hikaru] Authentication cancelled.")
    return
end

-- Main UI is loaded only after successful authentication.
local Library

local loadSuccess, loadError = pcall(function()
    Library = loadModule("Lib/UI")
end)

if not loadSuccess then
    warn("[Sora x Hikaru] UI loading error:", loadError)
    return
end

local Window = Library.new()

local Main = Window:create_tab("Main", "home")

Main:create_module({
    title = "Welcome",
    description = "You are authenticated.",
    flag = "welcome",

    callback = function()
    end,
}):create_button({
    title = "Say hello",

    callback = function()
        Library.Notify.Success(
            "Sora x Hikaru",
            "Authentication completed!",
            3
        )
    end,
})

Window:load()

