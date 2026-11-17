-- Sora x Hikaru V2 visual refresh
-- Keeps V2 feature logic and public methods intact while bringing the UI closer to Lib/UI.lua.

local Style = {}

local WINDOW_WIDTH = 698
local WINDOW_HEIGHT = 479
local SIDEBAR_WIDTH = 129
local TOPBAR_HEIGHT = 48

local function copyProperties(properties)
    local result = {}
    for key, value in pairs(properties or {}) do
        result[key] = value
    end
    return result
end

local function toHex(color)
    local function channel(value)
        return math.floor(value * 255 + 0.5)
    end

    return string.format(
        "#%02X%02X%02X",
        channel(color.R),
        channel(color.G),
        channel(color.B)
    )
end

local function fromHex(value)
    if type(value) ~= "string" then
        return nil
    end

    local hex = string.gsub(string.upper(value), "#", "")
    local red, green, blue = string.match(hex, "^(%x%x)(%x%x)(%x%x)$")
    if not red then
        return nil
    end

    return Color3.fromRGB(
        tonumber(red, 16),
        tonumber(green, 16),
        tonumber(blue, 16)
    )
end

local function setTextBoxColors(Components, ctx, textBox)
    Components.bind(ctx, textBox, {
        BackgroundColor3 = "MainColor",
        TextColor3 = "Text",
        PlaceholderColor3 = "SubText",
    })
end

local function applyComponentStyle(modules)
    local Components = modules.Components
    local originalCreate = Components.create
    local originalCorner = Components.corner
    local originalLabel = Components.label
    local originalButton = Components.button
    local originalIconButton = Components.iconButton

    Components.create = function(className, properties, parent)
        local styled = copyProperties(properties)

        if className == "Frame" and styled.Name == "Root" then
            styled.Size = UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT)
        elseif className == "ScrollingFrame" and styled.Name == "Sidebar" then
            styled.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
        elseif className == "Frame" and styled.Name == "Pages" then
            styled.Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0)
            styled.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0)
        elseif className == "Frame" and parent and parent.Name == "Topbar"
            and styled.Size and styled.Size.X.Offset == 230 then
            styled.Size = UDim2.fromOffset(190, 32)
        elseif className == "UIScale" then
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
            local scaleX = (viewport.X - 24) / (WINDOW_WIDTH + 24)
            local scaleY = (viewport.Y - 24) / (WINDOW_HEIGHT + 24)
            styled.Scale = math.clamp(math.min(scaleX, scaleY), 0.45, 1)
        elseif className == "TextButton" and styled.Name == "Tab" then
            styled.Size = UDim2.new(1, 0, 0, 30)
        elseif className == "Frame" and styled.Name == "FloatingButton" then
            styled.Size = UDim2.fromOffset(136, 68)
        elseif className == "TextButton" and parent and parent.Name == "FloatingButton" then
            styled.Position = UDim2.fromOffset(8, 30)
            styled.Size = UDim2.new(1, -16, 0, 30)
            styled.TextSize = 12
        elseif className == "UIPadding" and parent and parent.Name == "FeatureCard" then
            styled.PaddingTop = UDim.new(0, 10)
            styled.PaddingBottom = UDim.new(0, 10)
            styled.PaddingLeft = UDim.new(0, 10)
            styled.PaddingRight = UDim.new(0, 10)
        elseif className == "UIListLayout" and parent and parent.Name == "FeatureCard" then
            styled.Padding = UDim.new(0, 7)
        end

        return originalCreate(className, styled, parent)
    end

    Components.corner = function(parent, radius)
        if parent and parent.Name == "Root" then
            return originalCorner(parent, 12)
        elseif parent and parent.Name == "FeatureCard" then
            return originalCorner(parent, 4)
        end

        return originalCorner(parent, math.min(radius or 4, 6))
    end

    Components.label = function(ctx, parent, properties, colorKey)
        local styled = copyProperties(properties)

        if type(styled.TextSize) == "number" then
            if parent and parent.Name == "FeatureCard" then
                styled.TextSize = math.min(styled.TextSize, 12)
            else
                styled.TextSize = math.min(styled.TextSize, 14)
            end
        end

        return originalLabel(ctx, parent, styled, colorKey)
    end

    Components.button = function(ctx, parent, properties)
        local button = originalButton(ctx, parent, properties)
        button.Size = UDim2.new(1, 0, 0, 26)
        button.TextSize = 11
        return button
    end

    Components.iconButton = function(ctx, parent, properties)
        local button = originalIconButton(ctx, parent, properties)
        local size = math.min(properties.Size or 26, 24)
        button.Size = UDim2.fromOffset(size, size)

        local icon = button:FindFirstChildWhichIsA("ImageLabel")
            or button:FindFirstChildWhichIsA("TextLabel")

        if icon then
            icon.Size = UDim2.fromOffset(math.max(size - 8, 12), math.max(size - 8, 12))
            icon.Position = UDim2.fromScale(0.5, 0.5)
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
        end

        return button
    end

    -- Compact V1-style switch: 25x12 track and 12x12 thumb.
    Components.switch = function(ctx, parent, properties)
        local state = properties.Value == true
        local track = Components.create("TextButton", {
            Name = "Switch",
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(25, 12),
        }, parent)

        Components.corner(track, 6)

        local outline = Components.create("UIStroke", {
            Thickness = 0.8,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, track)

        local knob = Components.create("Frame", {
            Name = "Thumb",
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.fromOffset(12, 12),
            BorderSizePixel = 0,
        }, track)

        Components.corner(knob, 6)

        local function paint(animate)
            local theme = ctx.Theme
            local accent = theme:Get("Accent")
            local trackColor = state
                and accent
                or ctx.Mix(theme:Get("Secondary"), theme:Get("Text"), 0.1)
            local knobColor = state
                and Components.contrast(accent)
                or theme:Get("SubText")
            local position = state
                and UDim2.new(1, -12, 0.5, 0)
                or UDim2.new(0, 0, 0.5, 0)

            outline.Color = theme:Get("Stroke")

            if animate then
                Components.tween(track, { BackgroundColor3 = trackColor }, 0.12)
                Components.tween(knob, {
                    Position = position,
                    BackgroundColor3 = knobColor,
                }, 0.12)
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
end

local function applyWindowStyle(modules)
    local Window = modules.Window
    local originalNotify = Window.Notify

    Window.Minimize = function(self, state)
        self._minimized = state == true
        self._body.Visible = not self._minimized

        self._modules.Components.tween(self._root, {
            Size = UDim2.fromOffset(
                WINDOW_WIDTH,
                self._minimized and TOPBAR_HEIGHT or WINDOW_HEIGHT
            ),
        }, 0.2)
    end

    -- Reuse the notification renderer from V1, but give state changes a meaningful type.
    Window.Notify = function(self, title, message, duration, sound)
        local library = self._library
        local notificationType = "info"

        if message == "Enabled" then
            notificationType = "success"
        elseif message == "Disabled" then
            notificationType = "warning"
        end

        if library and library.Notify and library.Notify.Send then
            pcall(library.Notify.Send, {
                title = title,
                text = message,
                duration = duration,
                type = notificationType,
            })
        else
            print("[Sora x Hikaru] " .. tostring(title) .. ": " .. tostring(message))
        end

        if sound and self._soundId then
            pcall(function()
                local clip = Instance.new("Sound")
                clip.SoundId = self._soundId
                clip.Volume = 0.5
                clip.Parent = game:GetService("SoundService")
                clip.Ended:Once(function()
                    clip:Destroy()
                end)
                clip:Play()
            end)
        end
    end

    return originalNotify
end

local function applyColorPickerStyle(modules)
    local ColorPicker = modules.ColorPicker
    local Components = modules.Components
    local originalNew = ColorPicker.new

    ColorPicker.new = function(ctx, parent, properties)
        local handle = originalNew(ctx, parent, properties)
        local area = handle.Instance:FindFirstChildWhichIsA("Frame")

        if area then
            area.Size = UDim2.new(1, 0, 0, 88)
        end

        return handle
    end

    ColorPicker.row = function(ctx, parent, properties)
        local create = Components.create
        local theme = ctx.Theme

        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        }, parent)

        create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, row)

        local header = create("TextButton", {
            Name = "ColorHeader",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            LayoutOrder = 1,
        }, row)

        Components.label(ctx, header, {
            Size = UDim2.new(1, -88, 1, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            Text = properties.Name,
        })

        local chevron = Components.label(ctx, header, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -68, 0.5, 0),
            Size = UDim2.fromOffset(12, 14),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            Text = "v",
        }, "Accent")

        local swatch = create("Frame", {
            Name = "ColorSwatch",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(58, 20),
            BorderSizePixel = 0,
        }, header)

        Components.corner(swatch, 5)
        Components.stroke(ctx, swatch)

        local body = create("Frame", {
            Name = "ColorEditor",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false,
            BorderSizePixel = 0,
            LayoutOrder = 2,
        }, row)

        Components.corner(body, 5)
        Components.bind(ctx, body, { BackgroundColor3 = "Secondary" })
        Components.stroke(ctx, body)

        create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }, body)

        create("UIListLayout", {
            Padding = UDim.new(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, body)

        local selectedColor = theme:Get(properties.Key)
        local editing = false
        local picker
        local hexInput

        local function updatePreview(color)
            selectedColor = color
            swatch.BackgroundColor3 = color

            if hexInput and not hexInput:IsFocused() then
                hexInput.Text = toHex(color)
            end
        end

        picker = ColorPicker.new(ctx, body, {
            Value = selectedColor,
            OnChanged = updatePreview,
        })

        picker.Instance.LayoutOrder = 1

        local hexRow = create("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
        }, body)

        Components.label(ctx, hexRow, {
            Size = UDim2.fromOffset(34, 26),
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            Text = "HEX",
        }, "SubText")

        hexInput = create("TextBox", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(1, -40, 0, 26),
            ClearTextOnFocus = false,
            Text = toHex(selectedColor),
            PlaceholderText = "#RRGGBB",
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            BorderSizePixel = 0,
        }, hexRow)

        Components.corner(hexInput, 4)
        Components.stroke(ctx, hexInput)
        setTextBoxColors(Components, ctx, hexInput)

        ctx.Janitor:Connect(hexInput.FocusLost, function()
            local color = fromHex(hexInput.Text)
            if color then
                picker.Set(color)
                updatePreview(color)
            else
                hexInput.Text = toHex(selectedColor)
            end
        end)

        local actions = create("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
        }, body)

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, actions)

        local copyButton = Components.button(ctx, actions, {
            Text = "Copy",
            OnClick = function()
                local value = toHex(selectedColor)
                local copyFunction = setclipboard or toclipboard

                if type(copyFunction) == "function" then
                    pcall(copyFunction, value)
                else
                    hexInput.Text = value
                    hexInput:CaptureFocus()
                end
            end,
        })
        copyButton.Size = UDim2.fromOffset(52, 26)
        copyButton.LayoutOrder = 1

        local cancelButton = Components.button(ctx, actions, {
            Text = "Cancel",
            OnClick = function()
                selectedColor = theme:Get(properties.Key)
                picker.Set(selectedColor)
                updatePreview(selectedColor)
                editing = false
                body.Visible = false
                chevron.Text = "v"
            end,
        })
        cancelButton.Size = UDim2.fromOffset(58, 26)
        cancelButton.LayoutOrder = 2

        local applyButton = Components.button(ctx, actions, {
            Text = "Apply",
            Primary = true,
            OnClick = function()
                editing = false
                theme:Set(properties.Key, selectedColor)
                body.Visible = false
                chevron.Text = "v"
            end,
        })
        applyButton.Size = UDim2.fromOffset(58, 26)
        applyButton.LayoutOrder = 3

        local function setOpen(open)
            body.Visible = open
            chevron.Text = open and "^" or "v"

            if open then
                selectedColor = theme:Get(properties.Key)
                picker.Set(selectedColor)
                updatePreview(selectedColor)
                editing = true
            else
                editing = false
            end
        end

        local closer = function()
            setOpen(false)
            selectedColor = theme:Get(properties.Key)
            picker.Set(selectedColor)
            updatePreview(selectedColor)
        end

        ctx.Janitor:Connect(header.MouseButton1Click, function()
            local opening = not body.Visible
            local state = ctx.State

            if opening and state.OpenColorRow and state.OpenColorRow ~= closer then
                state.OpenColorRow()
            end

            setOpen(opening)
            state.OpenColorRow = opening and closer or nil
        end)

        ctx.Janitor:Add(theme:Subscribe(function(key)
            if key == properties.Key and not editing then
                selectedColor = theme:Get(properties.Key)
                picker.Set(selectedColor)
                updatePreview(selectedColor)
            end
        end))

        return row
    end
end

function Style.apply(modules)
    if modules.__SxHStyleApplied then
        return
    end

    modules.__SxHStyleApplied = true

    applyComponentStyle(modules)
    applyColorPickerStyle(modules)
    applyWindowStyle(modules)
end

return Style
