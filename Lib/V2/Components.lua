-- Lib/V2/Components.lua
-- Small reusable widgets. Every widget paints itself from the theme and registers its cleanup in ctx.Janitor.
-- ctx = { Theme, Janitor, Store, Mix, State = { Capturing }, ApplyIcon(label, name) -> boolean }

local Components = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function merge(defaults, overrides)
    local result = {}
    for key, value in pairs(defaults) do
        result[key] = value
    end
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end
Components.merge = merge

function Components.create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end
local create = Components.create

function Components.tween(instance, properties, seconds)
    TweenService:Create(instance, TweenInfo.new(seconds or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end
local tween = Components.tween

-- Same context with another janitor (one per card or panel, so closing it cleans only its own widgets)
function Components.child(ctx, janitor)
    local copy = {}
    for key, value in pairs(ctx) do
        copy[key] = value
    end
    copy.Janitor = janitor
    return copy
end

function Components.contrast(color)
    local brightness = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
    return brightness > 0.6 and Color3.fromRGB(12, 12, 14) or Color3.fromRGB(255, 255, 255)
end

-- bindings: { Property = "ThemeKey" | function(theme) return value end }. Repaints on every theme change.
function Components.bind(ctx, instance, bindings)
    local function paint()
        for property, source in pairs(bindings) do
            if type(source) == "function" then
                instance[property] = source(ctx.Theme)
            else
                instance[property] = ctx.Theme:Get(source)
            end
        end
    end
    paint()
    ctx.Janitor:Add(ctx.Theme:Subscribe(paint))
end
local bind = Components.bind

function Components.corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

function Components.stroke(ctx, parent, key)
    local stroke = create("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
    bind(ctx, stroke, { Color = key or "Stroke" })
    return stroke
end

function Components.label(ctx, parent, properties, colorKey)
    local label = create("TextLabel", merge({
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "",
    }, properties), parent)
    bind(ctx, label, { TextColor3 = colorKey or "Text" })
    return label
end

-- Lucide icon by name; a text fallback is drawn when the icon library is not available
function Components.icon(ctx, parent, properties)
    local size = properties.Size or 16
    local colorKey = properties.Color or "SubText"

    local image = create("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = properties.AnchorPoint,
        Position = properties.Position,
        Size = UDim2.fromOffset(size, size),
        ScaleType = Enum.ScaleType.Fit,
    }, parent)

    if ctx.ApplyIcon(image, properties.Name) then
        bind(ctx, image, { ImageColor3 = colorKey })
        return image
    end

    image:Destroy()
    local fallback = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = properties.AnchorPoint,
        Position = properties.Position,
        Size = UDim2.fromOffset(size, size),
        Font = Enum.Font.GothamBold,
        TextSize = size - 2,
        Text = properties.Fallback or "",
    }, parent)
    bind(ctx, fallback, { TextColor3 = colorKey })
    return fallback
end

-- Round icon button (gear, bell...). properties: Icon, Fallback, Size, OnClick
function Components.iconButton(ctx, parent, properties)
    local size = properties.Size or 26
    local button = create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(size, size),
    }, parent)

    local icon = Components.icon(ctx, button, {
        Name = properties.Icon,
        Fallback = properties.Fallback,
        Size = size - 8,
        Color = "SubText",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
    })

    local function setHover(hovered)
        local color = ctx.Theme:Get(hovered and "Text" or "SubText")
        if icon:IsA("ImageLabel") then
            icon.ImageColor3 = color
        else
            icon.TextColor3 = color
        end
    end
    ctx.Janitor:Connect(button.MouseEnter, function() setHover(true) end)
    ctx.Janitor:Connect(button.MouseLeave, function() setHover(false) end)
    ctx.Janitor:Connect(button.MouseButton1Click, function()
        if properties.OnClick then
            properties.OnClick()
        end
    end)
    return button
end

-- On/off switch. properties: Value, OnChanged(state). Returns { Instance, Set(value, silent), Get() }
function Components.switch(ctx, parent, properties)
    local state = properties.Value == true

    local track = create("TextButton", {
        Name = "Switch",
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(44, 22),
    }, parent)
    Components.corner(track, 11)
    local outline = create("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, track)
    local knob = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0 }, track)
    Components.corner(knob, 8)

    local function paint(animate)
        local theme = ctx.Theme
        local accent = theme:Get("Accent")
        local trackColor = state and accent or ctx.Mix(theme:Get("Secondary"), theme:Get("Text"), 0.1)
        local knobColor = state and Components.contrast(accent) or theme:Get("SubText")
        local position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)

        outline.Color = theme:Get("Stroke")
        if animate then
            tween(track, { BackgroundColor3 = trackColor })
            tween(knob, { Position = position, BackgroundColor3 = knobColor })
        else
            track.BackgroundColor3 = trackColor
            knob.Position = position
            knob.BackgroundColor3 = knobColor
        end
    end
    paint(false)
    ctx.Janitor:Add(ctx.Theme:Subscribe(function()
        paint(false)
    end))

    local handle = { Instance = track }

    function handle.Set(value, silent)
        value = value == true
        if value == state then
            return
        end
        state = value
        paint(true)
        if not silent and properties.OnChanged then
            properties.OnChanged(state)
        end
    end

    function handle.Get()
        return state
    end

    ctx.Janitor:Connect(track.MouseButton1Click, function()
        handle.Set(not state)
    end)
    return handle
end

-- Slider. properties: Min, Max, Step, Value, OnChanged(value), OnDone(value).
-- Returns { Instance, Set(value, silent), Get() }
function Components.slider(ctx, parent, properties)
    local minimum = properties.Min or 0
    local maximum = properties.Max or 100
    local step = properties.Step
    local value = math.clamp(properties.Value or minimum, minimum, maximum)

    local holder = create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1 }, parent)
    local bar = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 4),
        BorderSizePixel = 0,
    }, holder)
    Components.corner(bar, 2)
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, bar)
    Components.corner(fill, 2)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BorderSizePixel = 0,
    }, bar)
    Components.corner(knob, 6)

    bind(ctx, bar, { BackgroundColor3 = "Stroke" })
    bind(ctx, fill, { BackgroundColor3 = "Accent" })
    bind(ctx, knob, { BackgroundColor3 = "Text" })

    local function render()
        local fraction = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.fromScale(fraction, 1)
        knob.Position = UDim2.fromScale(fraction, 0.5)
    end
    render()

    local handle = { Instance = holder }

    function handle.Set(newValue, silent)
        newValue = math.clamp(newValue, minimum, maximum)
        if step and step > 0 then
            newValue = math.clamp(math.floor(newValue / step + 0.5) * step, minimum, maximum)
        end
        if newValue == value then
            return
        end
        value = newValue
        render()
        if not silent and properties.OnChanged then
            properties.OnChanged(value)
        end
    end

    function handle.Get()
        return value
    end

    local dragging = false
    local function fromInput(position)
        local fraction = math.clamp((position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        handle.Set(minimum + (maximum - minimum) * fraction)
    end

    ctx.Janitor:Connect(holder.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromInput(input.Position)
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input.Position)
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if properties.OnDone then
                properties.OnDone(value)
            end
        end
    end)
    return handle
end

-- Row of options with one selected. properties: Options, Value, OnChanged(option)
function Components.segmented(ctx, parent, properties)
    local frame = create("Frame", {
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
    }, parent)
    Components.corner(frame, 6)
    bind(ctx, frame, { BackgroundColor3 = function(theme) return ctx.Mix(theme:Get("Secondary"), theme:Get("Text"), 0.06) end })
    Components.stroke(ctx, frame)
    create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
    create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, frame)

    local value = properties.Value
    local buttons = {}

    local function paint()
        for option, button in pairs(buttons) do
            local selected = option == value
            local accent = ctx.Theme:Get("Accent")
            button.BackgroundTransparency = selected and 0 or 1
            button.BackgroundColor3 = accent
            button.TextColor3 = selected and Components.contrast(accent) or ctx.Theme:Get("SubText")
        end
    end

    for index, option in ipairs(properties.Options) do
        local button = create("TextButton", {
            AutoButtonColor = false,
            Size = UDim2.fromOffset(0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            Text = tostring(option),
            LayoutOrder = index,
        }, frame)
        Components.corner(button, 4)
        create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, button)
        buttons[option] = button
        ctx.Janitor:Connect(button.MouseButton1Click, function()
            if value ~= option then
                value = option
                paint()
                if properties.OnChanged then
                    properties.OnChanged(option)
                end
            end
        end)
    end
    paint()
    ctx.Janitor:Add(ctx.Theme:Subscribe(paint))

    local handle = { Instance = frame }
    function handle.Set(option)
        value = option
        paint()
    end
    return handle
end

-- Dropdown that opens below its header. properties: Options, Value, OnChanged(option)
function Components.dropdown(ctx, parent, properties)
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
    }, parent)
    Components.corner(box, 8)
    bind(ctx, box, { BackgroundColor3 = "Secondary" })
    Components.stroke(ctx, box)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, box)

    local header = create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = 1,
    }, box)
    local current = Components.label(ctx, header, {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -36, 1, 0),
        TextSize = 13,
        Text = tostring(properties.Value or ""),
    })
    local chevron = Components.label(ctx, header, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Text = "v",
    }, "SubText")

    local list = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 2,
    }, box)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

    local value = properties.Value
    local function setOpen(open)
        list.Visible = open
        chevron.Text = open and "^" or "v"
    end

    for index, option in ipairs(properties.Options) do
        local item = create("TextButton", {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(option),
            LayoutOrder = index,
        }, list)
        create("UIPadding", { PaddingLeft = UDim.new(0, 12) }, item)
        bind(ctx, item, { TextColor3 = function(theme) return theme:Get(option == value and "Accent" or "SubText") end })
        ctx.Janitor:Connect(item.MouseButton1Click, function()
            value = option
            current.Text = tostring(option)
            setOpen(false)
            for _, other in ipairs(list:GetChildren()) do
                if other:IsA("TextButton") then
                    other.TextColor3 = ctx.Theme:Get(other.Text == tostring(value) and "Accent" or "SubText")
                end
            end
            if properties.OnChanged then
                properties.OnChanged(option)
            end
        end)
    end

    ctx.Janitor:Connect(header.MouseButton1Click, function()
        setOpen(not list.Visible)
    end)

    local handle = { Instance = box }
    function handle.Set(option)
        value = option
        current.Text = tostring(option)
    end
    return handle
end

-- Records a key. Backspace or Escape clears it. properties: Value (key name or nil), OnChanged(keyName or nil)
function Components.keybind(ctx, parent, properties)
    local current = properties.Value
    local listening = false

    local button = create("TextButton", {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(84, 24),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
    }, parent)
    Components.corner(button, 6)
    bind(ctx, button, {
        BackgroundColor3 = function(theme) return ctx.Mix(theme:Get("Secondary"), theme:Get("Text"), 0.06) end,
        TextColor3 = "Text",
    })
    Components.stroke(ctx, button)

    local function show()
        button.Text = listening and "..." or (current or "None")
    end
    show()

    ctx.Janitor:Connect(button.MouseButton1Click, function()
        if listening then
            return
        end
        listening = true
        ctx.State.Capturing = true
        show()

        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode == Enum.KeyCode.Unknown then
                return
            end
            connection:Disconnect()
            listening = false
            -- the router sees this same key press: keep ignoring input until the frame is over
            task.defer(function()
                ctx.State.Capturing = false
            end)

            if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                current = nil
            else
                current = input.KeyCode.Name
            end
            show()
            if properties.OnChanged then
                properties.OnChanged(current)
            end
        end)
        ctx.Janitor:Add(connection)
    end)

    local handle = { Instance = button }
    function handle.Set(keyName)
        current = keyName
        show()
    end
    return handle
end

-- Text button. properties: Text, OnClick, Primary
function Components.button(ctx, parent, properties)
    local button = create("TextButton", {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Text = properties.Text or "Button",
    }, parent)
    Components.corner(button, 8)
    if properties.Primary then
        bind(ctx, button, {
            BackgroundColor3 = "Accent",
            TextColor3 = function(theme) return Components.contrast(theme:Get("Accent")) end,
        })
    else
        bind(ctx, button, {
            BackgroundColor3 = function(theme) return ctx.Mix(theme:Get("Secondary"), theme:Get("Text"), 0.06) end,
            TextColor3 = "Text",
        })
        Components.stroke(ctx, button)
    end
    ctx.Janitor:Connect(button.MouseButton1Click, function()
        if properties.OnClick then
            properties.OnClick()
        end
    end)
    return button
end

-- Drag `target` by grabbing `handle`. onDrop(position) runs when the drag ends.
function Components.draggable(ctx, handle, target, onDrop)
    local dragStart, startPosition = nil, nil

    ctx.Janitor:Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPosition = target.Position
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputChanged, function(input)
        if not dragStart then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
    ctx.Janitor:Connect(UserInputService.InputEnded, function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragStart = nil
            if onDrop then
                onDrop(target.Position)
            end
        end
    end)
end

return Components
