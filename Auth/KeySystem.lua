-- Auth/KeyWindow.lua
-- The key window (UI only). Dark background, red accent, thin borders.
-- KeyWindow.new(options) returns a controller:
--   SetStatus(text, kind)  kind: "info" | "success" | "error"
--   SetBusy(boolean), Lock(seconds), SetCanCopy(boolean), Destroy(), IsClosed()
-- options.Hooks: OnSubmit(key, remember), OnCopy(index), OnSelect(index), OnSkip(), OnClose()
-- options.Colors can override any color below.

local KeyWindow = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local defaultColors = {
    Overlay = Color3.fromRGB(0, 0, 0),
    Card = Color3.fromRGB(18, 18, 21),
    Raised = Color3.fromRGB(28, 28, 33),
    Stroke = Color3.fromRGB(44, 44, 52),
    Text = Color3.fromRGB(240, 240, 244),
    Muted = Color3.fromRGB(150, 150, 162),
    Accent = Color3.fromRGB(226, 66, 66),
    AccentText = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(80, 200, 120),
    Error = Color3.fromRGB(240, 100, 100),
}

local function create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end

local function guiParent()
    local ok, hidden = pcall(function()
        return gethui and gethui()
    end)
    return (ok and hidden) or CoreGui
end

function KeyWindow.new(options)
    local colors = {}
    for name, color in pairs(defaultColors) do
        colors[name] = (options.Colors and options.Colors[name]) or color
    end

    local hooks = options.Hooks
    local connections = {}
    local chips = {}
    local state = { busy = false, locked = false, closed = false, remember = options.Remember == true, selected = 1 }

    local function track(connection)
        connections[#connections + 1] = connection
        return connection
    end

    local screen = create("ScreenGui", {
        Name = "SxH_KeyWindow",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent())

    local overlay = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = colors.Overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
    }, screen)

    local card = create("Frame", {
        Name = "Card",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 360, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = colors.Card,
        BorderSizePixel = 0,
        Active = true,
    }, overlay)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
    create("UIStroke", { Color = colors.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
    }, card)
    create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, card)

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local cardScale = create("UIScale", { Scale = 0.94 }, card)
    local targetScale = math.clamp((viewport.X - 24) / 392, 0.6, 1)

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Active = true,
        LayoutOrder = 1,
    }, card)
    create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(3, 24),
        BackgroundColor3 = colors.Accent,
        BorderSizePixel = 0,
    }, header)
    create("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -44, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(options.Title or "Sora x Hikaru"),
    }, header)
    create("TextLabel", {
        Position = UDim2.fromOffset(12, 17),
        Size = UDim2.new(1, -44, 0, 13),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = colors.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(options.Note or "Authentication"),
    }, header)

    local closeButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = colors.Raised,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = colors.Muted,
        Text = "X",
    }, header)
    create("UICorner", { CornerRadius = UDim.new(0, 5) }, closeButton)

    if options.Description and options.Description ~= "" then
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = colors.Muted,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = tostring(options.Description),
            LayoutOrder = 2,
        }, card)
    end

    -- Provider chips, only when there is a choice
    local providers = options.Providers or {}
    if #providers > 1 then
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 3,
        }, card)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Wraps = true,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, row)

        for index, provider in ipairs(providers) do
            local chip = create("TextButton", {
                Size = UDim2.fromOffset(0, 26),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = colors.Raised,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = colors.Muted,
                Text = tostring(provider.Name),
                LayoutOrder = index,
            }, row)
            create("UICorner", { CornerRadius = UDim.new(0, 5) }, chip)
            create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, chip)
            local stroke = create("UIStroke", { Color = colors.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, chip)
            chips[index] = { button = chip, stroke = stroke }
        end
    end

    local keyBox = create("TextBox", {
        Name = "KeyBox",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = colors.Raised,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = colors.Text,
        PlaceholderText = "Enter your key",
        PlaceholderColor3 = colors.Muted,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 4,
    }, card)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, keyBox)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, keyBox)
    local keyStroke = create("UIStroke", { Color = colors.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, keyBox)

    local statusLabel = create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = colors.Muted,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = "",
        LayoutOrder = 5,
    }, card)

    local rememberFill = nil
    if options.ShowRemember then
        local row = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = 6,
        }, card)
        local box = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = colors.Raised,
            BorderSizePixel = 0,
        }, row)
        create("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
        create("UIStroke", { Color = colors.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, box)
        rememberFill = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = state.remember and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
            BackgroundColor3 = colors.Accent,
            BorderSizePixel = 0,
        }, box)
        create("UICorner", { CornerRadius = UDim.new(0, 3) }, rememberFill)
        create("TextLabel", {
            Position = UDim2.fromOffset(24, 0),
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = colors.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Remember key",
        }, row)

        track(row.MouseButton1Click:Connect(function()
            state.remember = not state.remember
            TweenService:Create(rememberFill, TweenInfo.new(0.15), {
                Size = state.remember and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
            }):Play()
        end))
    end

    local buttonRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        LayoutOrder = 7,
    }, card)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, buttonRow)

    local function createButton(text, order, primary)
        local button = create("TextButton", {
            Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = primary and colors.Accent or colors.Raised,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = primary and colors.AccentText or colors.Text,
            Text = text,
            LayoutOrder = order,
        }, buttonRow)
        create("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
        if not primary then
            create("UIStroke", { Color = colors.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
        end
        return button
    end

    local getKeyButton = createButton("Get Key", 1, false)
    local verifyButton = createButton("Verify", 2, true)

    local skipButton = nil
    if options.AllowSkip then
        skipButton = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = colors.Muted,
            Text = tostring(options.SkipText or "Continue without a key"),
            LayoutOrder = 8,
        }, card)
    end

    local controller = {}

    local function paintChips()
        for index, chip in ipairs(chips) do
            local selected = index == state.selected
            chip.stroke.Color = selected and colors.Accent or colors.Stroke
            chip.button.TextColor3 = selected and colors.Text or colors.Muted
        end
    end

    function controller:SetCanCopy(canCopy)
        getKeyButton.Visible = canCopy
        verifyButton.Size = canCopy and UDim2.new(0.5, -4, 1, 0) or UDim2.new(1, 0, 1, 0)
    end

    function controller:SetStatus(text, kind)
        statusLabel.Text = text or ""
        statusLabel.TextColor3 = (kind == "success" and colors.Success) or (kind == "error" and colors.Error) or colors.Muted
    end

    function controller:SetBusy(value)
        state.busy = value
        if not state.locked then
            verifyButton.Text = value and "Checking..." or "Verify"
        end
    end

    -- Disable Verify for `seconds` with a visible countdown
    function controller:Lock(seconds)
        state.locked = true
        task.spawn(function()
            for remaining = seconds, 1, -1 do
                if state.closed then
                    return
                end
                verifyButton.Text = string.format("Wait %ds", remaining)
                task.wait(1)
            end
            state.locked = false
            if not state.closed then
                verifyButton.Text = state.busy and "Checking..." or "Verify"
            end
        end)
    end

    function controller:IsClosed()
        return state.closed
    end

    function controller:Destroy()
        if state.closed then
            return
        end
        state.closed = true
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)

        TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        local out = TweenService:Create(cardScale, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = 0.94 })
        out:Play()
        out.Completed:Once(function()
            screen:Destroy()
        end)
    end

    local function submit()
        if state.busy or state.locked or state.closed then
            return
        end
        task.spawn(hooks.OnSubmit, keyBox.Text, state.remember)
    end

    track(verifyButton.MouseButton1Click:Connect(submit))
    track(keyBox.FocusLost:Connect(function(enterPressed)
        keyStroke.Color = colors.Stroke
        if enterPressed then
            submit()
        end
    end))
    track(keyBox.Focused:Connect(function()
        keyStroke.Color = colors.Accent
    end))

    track(getKeyButton.MouseButton1Click:Connect(function()
        if not state.closed then
            task.spawn(hooks.OnCopy, state.selected)
        end
    end))

    for index, chip in ipairs(chips) do
        track(chip.button.MouseButton1Click:Connect(function()
            state.selected = index
            paintChips()
            task.spawn(hooks.OnSelect, index)
        end))
    end

    if skipButton then
        track(skipButton.MouseButton1Click:Connect(function()
            task.spawn(hooks.OnSkip)
        end))
    end
    track(closeButton.MouseButton1Click:Connect(function()
        task.spawn(hooks.OnClose)
    end))

    -- Drag by the header
    local dragStart, startPosition = nil, nil
    track(header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPosition = card.Position
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragStart = nil
                    connection:Disconnect()
                end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragStart then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            card.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end))

    paintChips()
    controller:SetCanCopy(providers[1] ~= nil and providers[1].CanCopy)

    TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
    TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = targetScale }):Play()

    return controller
end

return KeyWindow
