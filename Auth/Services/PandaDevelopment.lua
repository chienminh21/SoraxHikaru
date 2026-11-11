-- Panda Development | https://pandadevelopment.net/
local HttpService = game:GetService("HttpService")
local PandaDevelopment = {}

function PandaDevelopment.New(options)
    options = type(options) == "table" and options or { ServiceId = options }
    local serviceId = options.ServiceId or options.ProductId
    if not serviceId then
        error("PandaDevelopment requires ServiceId")
    end

    local function hwid()
        if gethwid then
            local ok, id = pcall(gethwid)
            if ok and id then return tostring(id) end
        end
        local ok, id = pcall(function()
            return game:GetService("RbxAnalyticsService"):GetClientId()
        end)
        if ok and id then return tostring(id) end
        return tostring(game:GetService("Players").LocalPlayer.UserId)
    end

    local function httpRequest(req)
        local fn = request or http_request or syn_request
        if not fn then
            return nil, "No HTTP request function"
        end
        return fn(req)
    end

    local function Validate(key)
        key = tostring(key or "")
        if key == "" then
            return false, "Empty key"
        end

        local payload = HttpService:JSONEncode({
            ServiceID = tostring(serviceId),
            HWID = hwid(),
            Key = key,
        })

        local ok, response = pcall(function()
            return httpRequest({
                Url = "https://api.pandauth.com/api/v1/keys/validate",
                Method = "POST",
                Headers = {
                    ["User-Agent"] = "Roblox/Exploit",
                    ["Content-Type"] = "application/json",
                },
                Body = payload,
            })
        end)

        if not ok or not response then
            return false, "Request failed"
        end

        if response.Success == false and response.StatusCode and response.StatusCode >= 400 then
            return false, "HTTP " .. tostring(response.StatusCode)
        end

        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if not decodeOk or type(data) ~= "table" then
            return false, "Invalid response"
        end

        if data.Authenticated_Status == "Success" then
            return true, "Authenticated", data
        end
        return false, tostring(data.Note or "Authentication failed")
    end

    local function GetKeyLink()
        return "https://new.pandadevelopment.net/getkey/" .. tostring(serviceId) .. "?hwid=" .. hwid()
    end

    local function Copy()
        local link = GetKeyLink()
        if setclipboard then setclipboard(link)
        elseif toclipboard then toclipboard(link) end
        return link
    end

    return {
        Name = "PandaDevelopment",
        Validate = Validate,
        Verify = Validate,
        GetKeyLink = GetKeyLink,
        Copy = Copy,
    }
end

return PandaDevelopment

