-- Platoboost | https://platoboost.com/
-- Public validate/start endpoints. Putting Secret in client scripts is not secure.
local HttpService = game:GetService("HttpService")
local Platoboost = {}

local function httpRequest(req)
    local fn = request or http_request or syn_request
    if not fn then return nil, "No HTTP request function" end
    return fn(req)
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

function Platoboost.New(options)
    options = type(options) == "table" and options or {}
    local serviceId = options.ServiceId
    local secret = options.Secret
    if not serviceId then
        error("Platoboost requires ServiceId")
    end

    local host = "https://api.platoboost.app"
    pcall(function()
        local res = httpRequest({ Url = host .. "/public/connectivity", Method = "GET" })
        if res and res.StatusCode and res.StatusCode ~= 200 and res.StatusCode ~= 429 then
            host = "https://api.platoboost.net"
        end
    end)

    local cachedLink, cachedTime = "", 0

    local function GetKeyLink()
        if cachedTime + 600 > os.time() and cachedLink ~= "" then
            return cachedLink
        end
        local ok, res = pcall(function()
            return httpRequest({
                Url = host .. "/public/start",
                Method = "POST",
                Body = HttpService:JSONEncode({
                    service = serviceId,
                    identifier = hwid(),
                }),
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "Roblox/Exploit",
                },
            })
        end)
        if not ok or not res or not res.Body then
            return nil
        end
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(res.Body)
        end)
        if decodeOk and type(data) == "table" and data.success and data.data and data.data.url then
            cachedLink = data.data.url
            cachedTime = os.time()
            return cachedLink
        end
        return nil
    end

    local function Validate(key)
        key = tostring(key or "")
        if key == "" then
            return false, "Empty key"
        end

        local body = {
            service = serviceId,
            key = key,
            identifier = hwid(),
        }
        if secret then
            body.secret = secret
        end

        local ok, res = pcall(function()
            return httpRequest({
                Url = host .. "/public/redeem",
                Method = "POST",
                Body = HttpService:JSONEncode(body),
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "Roblox/Exploit",
                },
            })
        end)

        if not ok or not res then
            return false, "Request failed"
        end
        if res.StatusCode == 429 then
            return false, "Rate limited, wait and try again"
        end

        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(res.Body or "")
        end)
        if not decodeOk or type(data) ~= "table" then
            return false, "Invalid response"
        end

        if data.success == true then
            return true, data.message or "Key accepted", data.data
        end
        return false, tostring(data.message or "Invalid key")
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
        Name = "Platoboost",
        Validate = Validate,
        Verify = Validate,
        GetKeyLink = GetKeyLink,
        Copy = Copy,
    }
end

return Platoboost

