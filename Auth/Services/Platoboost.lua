-- Auth/Services/Platoboost.lua
-- Platoboost key service. Written from WindUI's Platoboost adapter (src/utils/services/Platoboost.lua):
-- same hosts, endpoints, request bodies and integrity hash. No official Platoboost documentation was read,
-- and it has only been run against a local mock, not the live service.
--
-- Entry: { Type = "platoboost", ServiceId = 12345, Secret = "optional" }
-- Secret is only used to check that an answer was not tampered with. Anything shipped in a public
-- script can be read, so leave it out if the script is public (answers are then not integrity checked).
-- Needs an executor with an HTTP request function.

local Platoboost = {}

local hosts = { "https://api.platoboost.app", "https://api.platoboost.net" }
local linkLifetime = 600

function Platoboost.new(config, context)
    local util = context.Util
    local sha256 = context.Load("Sha256")

    local service = tonumber(config.ServiceId) or config.ServiceId
    local secret = type(config.Secret) == "string" and config.Secret ~= "" and config.Secret or nil
    local identifier = nil
    local host = nil
    local cachedLink = nil

    local self = { Name = "Platoboost" }

    local function getIdentifier()
        identifier = identifier or sha256.hash(util.getHwid())
        return identifier
    end

    -- The first host that answers /public/connectivity (200 or 429 both mean it is up)
    local function resolveHost()
        if host then
            return host
        end
        for _, candidate in ipairs(hosts) do
            local response = util.request({ Url = candidate .. "/public/connectivity", Method = "GET" })
            if response and (response.StatusCode == 200 or response.StatusCode == 429) then
                host = candidate
                return host
            end
        end
        return nil
    end

    local function generateNonce()
        local letters = {}
        for index = 1, 16 do
            letters[index] = string.char(math.random(97, 122))
        end
        return table.concat(letters)
    end

    local function postJson(path, body)
        local encoded, text = util.jsonEncode(body)
        if not encoded then
            return nil, "could not build the request"
        end
        return util.request({
            Url = host .. path,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = text,
        })
    end

    -- Returns a decoded table, or a (false, message, data) failure triple
    local function readBody(response)
        if response.StatusCode == 429 then
            return nil, util.serviceError("Platoboost is rate limiting this client. Try again in a moment.", { RetryAfter = 20 })
        end
        if response.StatusCode ~= 200 then
            return nil, util.serviceError("Platoboost answered with HTTP " .. tostring(response.StatusCode) .. ".")
        end

        local decoded, body = util.jsonDecode(response.Body)
        if not decoded or type(body) ~= "table" then
            return nil, util.serviceError("Platoboost sent an unreadable answer.")
        end
        return body
    end

    function self:Verify(key)
        if not resolveHost() then
            return util.serviceError("Platoboost is not reachable.")
        end

        local nonce = generateNonce()
        local response, requestError

        if string.sub(key, 1, 4) == "KEY_" then
            -- A key copied straight from the website is redeemed first
            response, requestError = postJson("/public/redeem/" .. tostring(service), {
                identifier = getIdentifier(),
                key = key,
                nonce = nonce,
            })
        else
            response, requestError = util.request({
                Url = string.format(
                    "%s/public/whitelist/%s?identifier=%s&key=%s&nonce=%s",
                    host, tostring(service), getIdentifier(), util.urlEncode(key), nonce
                ),
                Method = "GET",
            })
        end
        if not response then
            return util.serviceError(requestError)
        end

        local body, failureMessage, failureData = readBody(response)
        if not body then
            return false, failureMessage, failureData
        end
        if body.success ~= true or type(body.data) ~= "table" then
            return util.serviceError("Platoboost sent an unexpected answer.")
        end

        if body.data.valid ~= true then
            return false, "Invalid or expired key."
        end

        if secret and body.data.hash ~= sha256.hash("true-" .. nonce .. "-" .. secret) then
            return util.serviceError("Platoboost's answer failed the integrity check and was refused.")
        end
        return true, "Key accepted.", { IntegrityChecked = secret ~= nil }
    end

    function self:Copy()
        if not resolveHost() then
            return false, "Platoboost is not reachable."
        end

        if not cachedLink or cachedLink.expiresAt < os.time() then
            local response, requestError = postJson("/public/start", { service = service, identifier = getIdentifier() })
            if not response then
                return false, requestError
            end

            local body, failureMessage = readBody(response)
            if not body then
                return false, failureMessage
            end
            if body.success ~= true or type(body.data) ~= "table" or type(body.data.url) ~= "string" then
                return false, "Platoboost did not return a key link."
            end
            cachedLink = { url = body.data.url, expiresAt = os.time() + linkLifetime }
        end

        if util.copy(cachedLink.url) then
            return true, "Key link copied. Open it in your browser."
        end
        return false, "Clipboard is not available. Open: " .. cachedLink.url
    end

    return self
end

return Platoboost

