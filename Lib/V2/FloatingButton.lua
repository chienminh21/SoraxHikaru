-- Lib/V2/FloatingButton.lua
-- A small draggable card that toggles one feature from anywhere on screen (the "Show Button" setting).
-- Same idea as b/button.lua: title, one big ON/OFF button, drag to move. The position is saved in the v2 file.

local FloatingButton = {}

local width, height = 150, 85

-- Offsets of the saved position are clamped so a button never ends up off screen
local function clampToScreen(position)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local x = math.clamp(position.XS * viewport.X + position.XO, 0, math.max(viewport.X - width, 0))
    local y = math.clamp(position.YS * viewport.Y + position.YO, 0, math.max(viewport.Y - height, 0))
    return UDim2.fromOffset(x, y)
end

-- gui: the ScreenGui to put the button in. index staggers the default positions.
function FloatingButton.new(ctx, feature, gui, index)
    local Components = ctx.Components
    local create = Components.create

    local janitor = ctx.NewJanitor()
    local buttonCtx = Components.child(ctx, janitor)

    local card = create("Frame", {
        Name = "FloatingButton",
        Active = true,
        Size = UDim2.fromOffset(width, height),
        BorderSizePixel = 0,
    }, gui)
    Components.corner(card, 10)
    Components.bind(buttonCtx, card, { BackgroundColor3 = "Secondary" })
    Components.stroke(buttonCtx, card)

    local saved = ctx.Store:Get("positions." .. feature.Id)
    if type(saved) == "table" and saved.XS and saved.XO and saved.YS and saved.YO then
        card.Position = clampToScreen(saved)
    else
        card.Position = UDim2.new(0.5, -width / 2 + (index - 1) * 12, 0.75, (index - 1) * (height + 10))
    end

    Components.label(buttonCtx, card, {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(1, -20, 0, 16),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = feature.Name,
    })

    local button = create("TextButton", {
        AutoButtonColor = false,
        Position = UDim2.fromOffset(10, 32),
        Size = UDim2.new(1, -20, 0, 40),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
    }, card)
    Components.corner(button, 8)

    local function paint()
        local theme = ctx.Theme
        local state = feature:GetState()
        local accent = theme:Get("Accent")
        if feature:GetSetting("ShowStatus") then
            button.Text = state and "ON" or "OFF"
        else
            button.Text = "Toggle"
        end
        button.BackgroundColor3 = state and accent or ctx.Mix(theme:Get("Secondary"), theme:Get("Text"), 0.1)
        button.TextColor3 = state and Components.contrast(accent) or theme:Get("SubText")
    end
    paint()
    janitor:Add(ctx.Theme:Subscribe(paint))
    janitor:Add(feature:Subscribe(function(eventName)
        if eventName == "state" or eventName == "setting" or eventName == "reset" then
            paint()
        end
    end))

    janitor:Connect(button.MouseButton1Click, function()
        feature:Toggle("toggle")
    end)

    Components.draggable(buttonCtx, card, card, function(position)
        ctx.Store:Set("positions." .. feature.Id, {
            XS = position.X.Scale,
            XO = position.X.Offset,
            YS = position.Y.Scale,
            YO = position.Y.Offset,
        })
    end)

    local handle = {}
    function handle.Destroy()
        janitor:Cleanup()
        card:Destroy()
    end
    return handle
end

return FloatingButton
