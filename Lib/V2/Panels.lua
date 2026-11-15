-- Lib/V2/Panels.lua
-- The Settings panel (gear) and the Notification panel (bell). One implementation draws both:
-- it reads the rows a feature reports (Feature:GetSettingsSchema / GetNotificationSchema), so a feature
-- with its own settings simply reports different rows.

local Panels = {}

local UserInputService = game:GetService("UserInputService")

-- ctx needs Components, NewJanitor. root is the frame the panel is shown over.
function Panels.new(ctx, root)
    local Components = ctx.Components
    local create = Components.create
    local manager = {}
    local current = nil

    function manager.Close()
        if not current then
            return
        end
        local open = current
        current = nil
        open.janitor:Cleanup()
        open.scrim:Destroy()
    end

    -- One row of the schema: name on the left and the control on the right (sliders and dropdowns go below the name)
    local function addRow(body, rowCtx, row, setValue, resetAction, order)
        local line = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order,
        }, body)
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, line)

        if row.Type == "Button" then
            Components.button(rowCtx, line, { Text = row.Name, OnClick = resetAction })
            return
        end

        local header = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 1 }, line)
        local nameLabel = Components.label(rowCtx, header, {
            Size = UDim2.new(1, -110, 1, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            Text = row.Name,
        })

        local function dock(instance)
            instance.AnchorPoint = Vector2.new(1, 0.5)
            instance.Position = UDim2.new(1, 0, 0.5, 0)
        end

        if row.Type == "Toggle" then
            local switch = Components.switch(rowCtx, header, {
                Value = row.Value == true,
                OnChanged = function(state) setValue(row.Id, state) end,
            })
            dock(switch.Instance)
        elseif row.Type == "Keybind" then
            local keybind = Components.keybind(rowCtx, header, {
                Value = row.Value,
                OnChanged = function(keyName) setValue(row.Id, keyName) end,
            })
            dock(keybind.Instance)
        elseif row.Type == "Segmented" then
            local segmented = Components.segmented(rowCtx, header, {
                Options = row.Options,
                Value = row.Value,
                OnChanged = function(option) setValue(row.Id, option) end,
            })
            dock(segmented.Instance)
        elseif row.Type == "Slider" then
            local valueLabel = Components.label(rowCtx, header, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(60, 20),
                TextXAlignment = Enum.TextXAlignment.Right,
                Text = tostring(row.Value),
            }, "SubText")
            local slider = Components.slider(rowCtx, line, {
                Min = row.Min,
                Max = row.Max,
                Step = row.Step,
                Value = row.Value,
                OnChanged = function(number)
                    valueLabel.Text = tostring(number)
                    setValue(row.Id, number)
                end,
            })
            slider.Instance.LayoutOrder = 2
        elseif row.Type == "Dropdown" then
            local dropdown = Components.dropdown(rowCtx, line, {
                Options = row.Options,
                Value = row.Value,
                OnChanged = function(option) setValue(row.Id, option) end,
            })
            dropdown.Instance.LayoutOrder = 2
        else
            nameLabel.Text = row.Name .. " (unsupported row type " .. tostring(row.Type) .. ")"
        end
    end

    -- build(body, rowCtx) fills the body. It runs again when the feature reports "reset".
    local function open(feature, subtitle, build)
        manager.Close()

        local janitor = ctx.NewJanitor()
        local panelCtx = Components.child(ctx, janitor)

        local scrim = create("TextButton", {
            Name = "PanelScrim",
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            ZIndex = 50,
        }, root)
        current = { scrim = scrim, janitor = janitor }

        local panel = create("Frame", {
            Name = "Panel",
            Active = true,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(360, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
            ZIndex = 51,
        }, scrim)
        Components.corner(panel, 12)
        Components.bind(panelCtx, panel, { BackgroundColor3 = "Secondary" })
        Components.stroke(panelCtx, panel)
        create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, panel)
        create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, panel)

        local header = create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 1 }, panel)
        Components.label(panelCtx, header, {
            Size = UDim2.new(1, -40, 0, 18),
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            Text = feature.Name,
        })
        Components.label(panelCtx, header, {
            Position = UDim2.fromOffset(0, 19),
            Size = UDim2.new(1, -40, 0, 14),
            TextSize = 11,
            Text = subtitle,
        }, "SubText")
        local closeButton = Components.iconButton(panelCtx, header, { Icon = "x", Fallback = "x", Size = 26, OnClick = manager.Close })
        closeButton.AnchorPoint = Vector2.new(1, 0)
        closeButton.Position = UDim2.fromScale(1, 0)

        local body = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 3,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 2,
        }, panel)
        create("UISizeConstraint", { MaxSize = Vector2.new(math.huge, 340) }, body)
        create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, body)
        create("UIPadding", { PaddingRight = UDim.new(0, 8) }, body)

        local rowsJanitor = ctx.NewJanitor()
        janitor:Add(function()
            rowsJanitor:Cleanup()
        end)

        local function render()
            rowsJanitor:Cleanup()
            for _, child in ipairs(body:GetChildren()) do
                if child:IsA("GuiObject") then
                    child:Destroy()
                end
            end
            build(body, Components.child(ctx, rowsJanitor))
        end
        render()

        janitor:Add(feature:Subscribe(function(eventName)
            if eventName == "reset" then
                render()
            end
        end))
        janitor:Connect(scrim.MouseButton1Click, manager.Close)
        janitor:Connect(UserInputService.InputBegan, function(input)
            if input.KeyCode == Enum.KeyCode.Escape and not ctx.State.Capturing then
                manager.Close()
            end
        end)
    end

    function manager.OpenSettings(feature)
        open(feature, "Settings", function(body, rowCtx)
            local schema = feature:GetSettingsSchema()
            for index, row in ipairs(schema) do
                addRow(body, rowCtx, row, function(id, value)
                    feature:SetSetting(id, value)
                end, function()
                    feature:ResetSettings()
                end, index)
            end
            if #schema == 0 then
                Components.label(rowCtx, body, { Size = UDim2.new(1, 0, 0, 20), Text = "This feature has no settings." }, "SubText")
            end
        end)
    end

    function manager.OpenNotifications(feature)
        open(feature, "Notifications", function(body, rowCtx)
            local schema = feature:GetNotificationSchema()
            for index, row in ipairs(schema) do
                addRow(body, rowCtx, row, function(id, value)
                    feature:SetNotification(id, value)
                end, nil, index)
            end
            local resetRow = { Id = "ResetNotifications", Type = "Button", Name = "Reset Notifications" }
            addRow(body, rowCtx, resetRow, nil, function()
                feature:ResetNotifications()
            end, #schema + 1)
        end)
    end

    return manager
end

return Panels
