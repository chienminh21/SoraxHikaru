local BASE = "https://raw.githubusercontent.com/chienminh21/SoraxHikaru/main/"



local Games = {
    [137826330724902] = "Games/LSSK.lua", 
    [128001665358186] = "Games/SK.lua", 
}

local function fetch(path)
    local ok, res = pcall(game.HttpGet, game, BASE .. path)
    if not ok then warn("[Sora x Hikaru] Loading error:", path) return end
    local fn, err = loadstring(res)
    if not fn then warn("[Sora x Hikaru] Syntax error:", err) return end
    return fn()
end

local path = Games[game.PlaceId]
if path then
    fetch(path)
else
    warn("[Sora x Hikaru] No Support")
end

