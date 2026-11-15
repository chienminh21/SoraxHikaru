-- Lib/V2/ColorPicker.lua
-- Expandable color picker: 2D saturation/value area, hue slider and a preview swatch.
-- ColorPicker.new builds the picker itself, ColorPicker.row builds an Appearance row that expands to it.

local ColorPicker = {}

local UserInputService = game:GetService("UserInputService")

-- properties: Value (Color3), OnChanged(color). Returns { Instance, Set(color) }
function ColorPicker.new(ctx, parent, properties)
    local Components = ctx.Components
    local create = Components.create

    local hue, saturation, value = properties.Value:ToHSV()

    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, parent)
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, holder)

    local area = create("Frame", {
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, holder)
    Components.corner(area, 8)

    local whiteLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, area)
    Components.corner(whiteLayer, 8)
    create("UIGradient", {
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
    }, whiteLayer)

    local blackLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, area)
    Components.corner(blackLayer, 8)
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
    }, blackLayer)

    local areaKnob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, area)
    Components.corner(areaKnob, 6)
    create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5 }, areaKnob)

    local hueBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, holder)
    Components.corner(hueBar, 7)
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
    }, hueBar)

    local hueKnob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(6, 20),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, hueBar)
    Components.corner(hueKnob, 3)
    create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }, hueKnob)

    local function render()
        area.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        areaKnob.Position = UDim2.fromScale(saturation, 1 - value)
        hueKnob.Position = UDim2.fromScale(hue, 0.5)
    end
    render()

    local function announce()
        if properties.OnChanged then
            properties.OnChanged(Color3.fromHSV(hue, saturation, value))
        end
    end

    local mode = nil
    local function update(position)
        if mode == "area" then
            saturation = math.clamp((position.X - area.AbsolutePosition.X) / math.max(area.AbsoluteSize.X, 1), 0, 1)
            value = 1 - math.clamp((position.Y - area.AbsolutePosition.Y) / math.max(area.AbsoluteSize.Y, 1), 0, 1)
        elseif mode == "hue" then
            hue = math.clamp((position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
        else
            return
        end
        render()
        announce()
    end

    local function isPress(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end

    ctx.Janitor:Connect(area.InputBegan, function(input)
        if isPress(input) then
            mode = "area"
            update(input.Position)
        end
    end)
    ctx.Janitor:Connect(hueBar.InputBegan, function(input)
        if isPress(input) then
            mode = "hue"
            update(input.Position)
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputChanged, function(input)
        if mode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position)
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputEnded, function(input)
        if mode and isPress(input) then
            mode = nil
        end
    end)

    local handle = { Instance = holder }
    function handle.Set(color)
        hue, saturation, value = color:ToHSV()
        render()
    end
    return handle
end

-- Appearance row: name, chevron and swatch. Clicking it expands the picker; only one row is open at a time.
-- properties: Name, Key (a theme color name)
function ColorPicker.row(ctx, parent, properties)
    local Components = ctx.Components
    local create = Components.create
    local theme = ctx.Theme

    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, parent)
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)

    local header = create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = 1,
    }, row)
    Components.label(ctx, header, {
        Size = UDim2.new(1, -130, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Text = properties.Name,
    })
    local chevron = Components.label(ctx, header, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -104, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Text = "v",
    }, "Accent")

    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(90, 24),
        BorderSizePixel = 0,
    }, header)
    Components.corner(swatch, 6)
    Components.stroke(ctx, swatch)

    local body = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 2,
    }, row)

    local picker = ColorPicker.new(ctx, body, {
        Value = theme:Get(properties.Key),
        OnChanged = function(color)
            theme:Set(properties.Key, color)
        end,
    })

    -- Presets or other rows can change the color: keep the swatch and the picker in step
    local function sync()
        local color = theme:Get(properties.Key)
        swatch.BackgroundColor3 = color
        picker.Set(color)
    end
    sync()
    ctx.Janitor:Add(theme:Subscribe(function(key)
        if key == properties.Key then
            sync()
        end
    end))

    local function setOpen(open)
        body.Visible = open
        chevron.Text = open and "^" or "v"
    end
    local closer = function() setOpen(false) end

    ctx.Janitor:Connect(header.MouseButton1Click, function()
        local opening = not body.Visible
        local state = ctx.State
        if opening and state.OpenColorRow and state.OpenColorRow ~= closer then
            state.OpenColorRow()
        end
        setOpen(opening)
        state.OpenColorRow = opening and closer or nil
    end)

    return row
end

return ColorPicker
