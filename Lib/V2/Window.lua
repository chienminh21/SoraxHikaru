-- Lib/V2/Window.lua
-- The UI v2 main window: topbar (name, version, search, minimize, close), sidebar, pages with feature cards,
-- the Appearance section, floating buttons and the launcher. Feature logic lives in Feature.lua,
-- widgets in Components.lua, so this file only arranges things.

local Window = {}
Window.__index = Window

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local windowWidth, windowHeight, topbarHeight, sidebarWidth = 760, 500, 48, 176

local defaultCategories = {
    { "Combat", "swords" },
    { "Movement", "footprints" },
    { "Visuals", "eye" },
    { "Player", "user" },
    { "World", "globe" },
    { "Avatar", "shirt" },
    { "Remotes", "radio" },
    { "Teleports", "map-pin" },
    { "Misc", "ellipsis" },
    { "Scripts", "scroll-text" },
    { "Config", "sliders-horizontal" },
    { "GUI", "layout-dashboard" },
}

local colorRows = {
    { "Main Color", "MainColor" },
    { "Secondary", "Secondary" },
    { "Accent", "Accent" },
    { "Stroke", "Stroke" },
    { "Text", "Text" },
    { "SubText", "SubText" },
}

local function sanitize(text)
    return (string.gsub(string.lower(tostring(text)), "[^%w]+", "_"))
end

local function guiParent()
    local ok, hidden = pcall(function()
        return gethui and gethui()
    end)
    return (ok and hidden) or CoreGui
end

local function positionRecord(position)
    return { XS = position.X.Scale, XO = position.X.Offset, YS = position.Y.Scale, YO = position.Y.Offset }
end

-- options: Modules, Theme, Store, Library (v1 library, optional: icons and notifications), Title, Version,
-- Categories (list of { name, lucide icon } or false), ToggleKey, NotificationSoundId
function Window.new(options)
    local modules = options.Modules
    local Components = modules.Components
    local create = Components.create

    local self = setmetatable({}, Window)
    self._modules = modules
    self._library = options.Library
    self._soundId = options.NotificationSoundId
    self._toggleKey = options.ToggleKey or Enum.KeyCode.Insert
    self._janitor = modules.Janitor.new()
    self._router = modules.Feature.Router.new()
    self._features = {}
    self._cards = {}
    self._floating = {}
    self._floatingCount = 0
    self._tabs = {}
    self._tabList = {}
    self._selected = nil
    self._destroyed = false
    self._minimized = false
    self.Theme = options.Theme
    self.Store = options.Store

    local library = options.Library
    local ctx = {
        Theme = options.Theme,
        Janitor = self._janitor,
        Store = options.Store,
        Components = Components,
        ColorPicker = modules.ColorPicker,
        Mix = modules.Theme.mix,
        State = { Capturing = false },
        NewJanitor = modules.Janitor.new,
        ApplyIcon = function(image, name)
            if library and library.ApplyIcon and name then
                local ok, applied = pcall(library.ApplyIcon, image, name)
                return ok and applied == true
            end
            return false
        end,
    }
    self._ctx = ctx

    self._gui = create("ScreenGui", {
        Name = "SxH_V2",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 500,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent())

    -- Root frame (saved position, scaled down on small screens)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local root = create("Frame", {
        Name = "Root",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(windowWidth, windowHeight),
        ClipsDescendants = true,
        BorderSizePixel = 0,
    }, self._gui)
    Components.corner(root, 12)
    Components.bind(ctx, root, { BackgroundColor3 = "MainColor" })
    Components.stroke(ctx, root)
    create("UIScale", { Scale = math.clamp((viewport.X - 24) / (windowWidth + 24), 0.5, 1) }, root)
    self._root = root

    local saved = options.Store:Get("window.Position")
    if type(saved) == "table" and saved.XS then
        root.Position = UDim2.new(saved.XS, saved.XO, saved.YS, saved.YO)
    else
        root.Position = UDim2.fromScale(0.5, 0.5)
    end

    self._panels = modules.Panels.new(ctx, root)

    -- Topbar -------------------------------------------------------
    local topbar = create("Frame", { Name = "Topbar", Size = UDim2.new(1, 0, 0, topbarHeight), BackgroundTransparency = 1, Active = true }, root)
    local divider = create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0 }, topbar)
    Components.bind(ctx, divider, { BackgroundColor3 = "Stroke" })

    local title = Components.label(ctx, topbar, {
        Position = UDim2.fromOffset(20, 0),
        Size = UDim2.fromOffset(150, topbarHeight),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        Text = options.Title or "Sora x Hikaru",
    })
    Components.label(ctx, topbar, {
        Position = UDim2.fromOffset(20 + title.TextBounds.X + 8, 0),
        Size = UDim2.fromOffset(60, topbarHeight),
        TextSize = 12,
        Text = options.Version or "v2.0",
    }, "SubText")

    local searchBox = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -92, 0.5, 0),
        Size = UDim2.fromOffset(230, 32),
        BorderSizePixel = 0,
    }, topbar)
    Components.corner(searchBox, 16)
    Components.bind(ctx, searchBox, { BackgroundColor3 = "Secondary" })
    Components.stroke(ctx, searchBox)
    Components.icon(ctx, searchBox, { Name = "search", Fallback = "?", Size = 16, Position = UDim2.fromOffset(12, 8) })
    local searchInput = create("TextBox", {
        Position = UDim2.fromOffset(36, 0),
        Size = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "Search...",
        Text = "",
    }, searchBox)
    Components.bind(ctx, searchInput, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })
    self._janitor:Connect(searchInput:GetPropertyChangedSignal("Text"), function()
        self:Search(searchInput.Text)
    end)

    local minimizeButton = Components.iconButton(ctx, topbar, {
        Icon = "minus", Fallback = "-", Size = 32,
        OnClick = function() self:Minimize(not self._minimized) end,
    })
    minimizeButton.AnchorPoint = Vector2.new(1, 0.5)
    minimizeButton.Position = UDim2.new(1, -52, 0.5, 0)
    local closeButton = Components.iconButton(ctx, topbar, { Icon = "x", Fallback = "x", Size = 32, OnClick = function() self:Hide() end })
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.Position = UDim2.new(1, -14, 0.5, 0)

    Components.draggable(ctx, topbar, root, function(position)
        options.Store:Set("window.Position", positionRecord(position))
    end)

    -- Sidebar and pages --------------------------------------------
    local body = create("Frame", { Name = "Body", Position = UDim2.fromOffset(0, topbarHeight), Size = UDim2.new(1, 0, 1, -topbarHeight), BackgroundTransparency = 1 }, root)
    self._body = body

    local sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
    }, body)
    create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, sidebar)
    create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
    self._nav = sidebar

    self._pages = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(sidebarWidth, 0),
        Size = UDim2.new(1, -sidebarWidth, 1, 0),
        BackgroundTransparency = 1,
    }, body)

    -- Launcher: shown while the window is hidden (also the way back on devices without a keyboard)
    self._launcher = create("TextButton", {
        Name = "Launcher",
        Visible = false,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(44, 44),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Text = "SxH",
    }, self._gui)
    Components.corner(self._launcher, 22)
    Components.bind(ctx, self._launcher, {
        BackgroundColor3 = "Accent",
        TextColor3 = function(theme) return Components.contrast(theme:Get("Accent")) end,
    })
    local launcherSaved = options.Store:Get("positions.launcher")
    if type(launcherSaved) == "table" and launcherSaved.XS then
        self._launcher.Position = UDim2.new(launcherSaved.XS, launcherSaved.XO, launcherSaved.YS, launcherSaved.YO)
    else
        self._launcher.Position = UDim2.new(0, 16, 0.5, -22)
    end
    Components.draggable(ctx, self._launcher, self._launcher, function(position)
        options.Store:Set("positions.launcher", positionRecord(position))
    end)
    self._janitor:Connect(self._launcher.MouseButton1Click, function()
        self:Show()
    end)

    -- Keybinds for features and the window toggle key. A recorded key or a focused textbox is ignored.
    self._janitor:Connect(UserInputService.InputBegan, function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard or ctx.State.Capturing then
            return
        end
        if input.KeyCode == self._toggleKey and not processed then
            self:Toggle()
            return
        end
        if not processed then
            self._router:Handle(input.KeyCode.Name, true)
        end
    end)
    self._janitor:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and not ctx.State.Capturing then
            self._router:Handle(input.KeyCode.Name, false)
        end
    end)

    -- Default navigation
    local categories = options.Categories
    if categories == nil then
        categories = defaultCategories
    end
    if categories then
        for _, category in ipairs(categories) do
            self:AddTab(category[1], category[2])
        end
        if self._tabs.GUI then
            self:_buildAppearance(self._tabs.GUI)
        end
        if self._tabs.Config then
            self:_buildConfig(self._tabs.Config)
        end
    end
    if self._tabList[1] then
        self:SelectTab(self._tabList[1].Name)
    end

    return self
end

-- Notifications -----------------------------------------------------

function Window:Notify(title, text, duration, sound)
    local library = self._library
    if library and library.Notify and library.Notify.Send then
        pcall(library.Notify.Send, { title = title, text = text, duration = duration, type = "info" })
    else
        print("[Sora x Hikaru] " .. tostring(title) .. ": " .. tostring(text))
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

-- Tabs ----------------------------------------------------------------

function Window:_paintTabs()
    local theme = self.Theme
    for _, tab in ipairs(self._tabList) do
        local selected = tab == self._selected
        tab.Button.BackgroundTransparency = selected and 0 or 1
        tab.Button.BackgroundColor3 = self._ctx.Mix(theme:Get("MainColor"), theme:Get("Text"), 0.07)
        tab.Bar.Visible = selected
        tab.Label.TextColor3 = theme:Get(selected and "Text" or "SubText")
        if tab.Icon:IsA("ImageLabel") then
            tab.Icon.ImageColor3 = theme:Get(selected and "Text" or "SubText")
        else
            tab.Icon.TextColor3 = theme:Get(selected and "Text" or "SubText")
        end
    end
end

function Window:SelectTab(name)
    local tab = self._tabs[name]
    if not tab then
        return false
    end
    self._selected = tab
    for _, other in ipairs(self._tabList) do
        other.Page.Visible = other == tab
    end
    self:_paintTabs()
    return true
end

-- Creates a page and its sidebar entry. The same name returns the existing tab.
function Window:AddTab(name, icon)
    if self._tabs[name] then
        return self._tabs[name]
    end

    local Components = self._modules.Components
    local create = Components.create
    local ctx = self._ctx

    local button = create("TextButton", {
        Name = "Tab",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 38),
        BorderSizePixel = 0,
        LayoutOrder = #self._tabList + 1,
    }, self._nav)
    Components.corner(button, 8)
    local bar = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(3, 20), BorderSizePixel = 0, Visible = false }, button)
    Components.bind(ctx, bar, { BackgroundColor3 = "Accent" })
    local tabIcon = Components.icon(ctx, button, { Name = icon, Fallback = string.sub(name, 1, 1), Size = 18, Position = UDim2.fromOffset(14, 10) })
    local label = Components.label(ctx, button, {
        Position = UDim2.fromOffset(44, 0),
        Size = UDim2.new(1, -52, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        Text = name,
    }, "SubText")

    local page = create("ScrollingFrame", {
        Name = "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false,
    }, self._pages)
    create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, page)

    local columnsFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, page)
    create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, columnsFrame)
    local columns = {}
    for order = 1, 2 do
        local column = create("Frame", { Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, columnsFrame)
        create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, column)
        columns[order] = column
    end

    local empty = Components.label(ctx, page, { Size = UDim2.new(1, 0, 0, 30), TextSize = 13, Text = "No features here yet." }, "SubText")

    local tab = {
        Name = name,
        Button = button,
        Bar = bar,
        Icon = tabIcon,
        Label = label,
        Page = page,
        Columns = columns,
        CardCount = { 0, 0 },
        Empty = empty,
    }
    self._tabs[name] = tab
    table.insert(self._tabList, tab)

    self._janitor:Connect(button.MouseButton1Click, function()
        self:SelectTab(name)
    end)
    -- Registered after the widgets above so the selected look wins when the theme changes
    self._janitor:Add(self.Theme:Subscribe(function()
        self:_paintTabs()
    end))

    -- def: see Feature.new. Column = 1 or 2 picks a column, otherwise the emptier one is used.
    function tab:AddFeature(def)
        return self.Window:_addFeatureCard(self, def)
    end
    tab.Window = self

    return tab
end

-- Search ---------------------------------------------------------------

-- Hides the cards that do not match. Jumps to another tab when the open one has no match.
function Window:Search(query)
    query = string.lower(query or "")
    local terms = {}
    for term in string.gmatch(query, "%S+") do
        table.insert(terms, term)
    end

    local firstMatchTab = nil
    local matchesInSelected = false
    for _, card in ipairs(self._cards) do
        local visible = true
        for _, term in ipairs(terms) do
            if not string.find(card.Text, term, 1, true) then
                visible = false
                break
            end
        end
        card.Frame.Visible = visible
        if visible and #terms > 0 then
            firstMatchTab = firstMatchTab or card.Tab
            if card.Tab == self._selected then
                matchesInSelected = true
            end
        end
    end

    if #terms > 0 and not matchesInSelected and firstMatchTab then
        self:SelectTab(firstMatchTab.Name)
    end
end

-- Features -------------------------------------------------------------

function Window:GetFeature(id)
    return self._features[id]
end

function Window:_getFloatingGui()
    if not self._floatingGui then
        self._floatingGui = self._modules.Components.create("ScreenGui", {
            Name = "SxH_V2_Floating",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 450,
        }, guiParent())
    end
    return self._floatingGui
end

function Window:_syncFloating(feature)
    local wanted = feature:GetSetting("ShowButton") == true
    local existing = self._floating[feature.Id]
    if wanted and not existing then
        self._floatingCount = self._floatingCount + 1
        self._floating[feature.Id] = self._modules.FloatingButton.new(self._ctx, feature, self:_getFloatingGui(), self._floatingCount)
    elseif not wanted and existing then
        existing.Destroy()
        self._floating[feature.Id] = nil
    end
end

-- Creates the Feature object (logic), registers its keybind and its floating button.
function Window:_newFeature(def, parentId)
    local base = def.Id or sanitize((parentId and (parentId .. "_") or "") .. (def.Name or "feature"))
    local id, suffix = base, 1
    while self._features[id] do
        suffix = suffix + 1
        id = base .. "_" .. suffix
    end
    if suffix > 1 then
        warn("[Sora x Hikaru] feature id '" .. base .. "' is already used, using '" .. id .. "'")
    end

    local copy = table.clone(def)
    copy.Id = id
    local feature = self._modules.Feature.new(copy, {
        Store = self.Store,
        Notify = function(title, text, duration, sound)
            self:Notify(title, text, duration, sound)
        end,
    })

    self._features[id] = feature
    self._router:Register(feature)
    self._janitor:Add(function()
        self._router:Unregister(feature)
    end)
    self._janitor:Add(feature:Subscribe(function(eventName, settingId)
        if eventName == "setting" and settingId == "ShowButton" or eventName == "reset" then
            self:_syncFloating(feature)
        end
    end))
    return feature
end

-- Gear, bell and the main switch for one feature. Returns the switch.
function Window:_addControls(parent, cardCtx, feature)
    local Components = self._modules.Components
    local panels = self._panels

    if feature.HasSettingsButton then
        Components.iconButton(cardCtx, parent, { Icon = "settings", Fallback = "G", Size = 28, OnClick = function() panels.OpenSettings(feature) end })
    end
    if feature.HasNotificationButton then
        Components.iconButton(cardCtx, parent, { Icon = "bell", Fallback = "N", Size = 28, OnClick = function() panels.OpenNotifications(feature) end })
    end

    local switch = Components.switch(cardCtx, parent, {
        Value = feature:GetState(),
        OnChanged = function(state)
            feature:SetState(state, "toggle")
        end,
    })
    cardCtx.Janitor:Add(feature:Subscribe(function(eventName, state)
        if eventName == "state" then
            switch.Set(state, true)
        end
    end))
    return switch
end

-- Runs when the widgets of a feature exist: shows its floating button and applies the startup state
function Window:_activate(feature)
    self:_syncFloating(feature)
    feature:Start()
end

function Window:_addFeatureCard(tab, def)
    local Components = self._modules.Components
    local create = Components.create
    local feature = self:_newFeature(def)

    local janitor = self._modules.Janitor.new()
    self._janitor:Add(function()
        janitor:Cleanup()
    end)
    local cardCtx = Components.child(self._ctx, janitor)

    local columnIndex = def.Column
    if columnIndex ~= 1 and columnIndex ~= 2 then
        columnIndex = tab.CardCount[1] <= tab.CardCount[2] and 1 or 2
    end
    tab.CardCount[columnIndex] = tab.CardCount[columnIndex] + 1
    tab.Empty.Visible = false

    local frame = create("Frame", { Name = "FeatureCard", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0 }, tab.Columns[columnIndex])
    Components.corner(frame, 10)
    Components.bind(cardCtx, frame, { BackgroundColor3 = "Secondary" })
    Components.stroke(cardCtx, frame)
    create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, frame)
    create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
    table.insert(self._cards, { Frame = frame, Tab = tab, Text = string.lower(feature.Name .. " " .. feature.Description) })

    Components.label(cardCtx, frame, { Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 14, Text = feature.Name }).LayoutOrder = 1
    if feature.Description ~= "" then
        local description = Components.label(cardCtx, frame, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = feature.Description,
        }, "SubText")
        description.LayoutOrder = 2
    end

    -- Gear on the left, bell and the main switch on the right
    local controlRow = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 3 }, frame)
    local right = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, controlRow)
    create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, right)
    if feature.HasSettingsButton then
        local gear = Components.iconButton(cardCtx, controlRow, { Icon = "settings", Fallback = "G", Size = 28, OnClick = function() self._panels.OpenSettings(feature) end })
        gear.Position = UDim2.fromOffset(0, 0)
    end
    if feature.HasNotificationButton then
        Components.iconButton(cardCtx, right, { Icon = "bell", Fallback = "N", Size = 28, OnClick = function() self._panels.OpenNotifications(feature) end })
    end
    local switch = Components.switch(cardCtx, right, {
        Value = feature:GetState(),
        OnChanged = function(state)
            feature:SetState(state, "toggle")
        end,
    })
    janitor:Add(feature:Subscribe(function(eventName, state)
        if eventName == "state" then
            switch.Set(state, true)
        end
    end))

    local content = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 4 }, frame)
    create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, content)

    local card = { Feature = feature, Frame = frame, Content = content }
    local rowCount = 0

    local function nextOrder()
        rowCount = rowCount + 1
        return rowCount
    end

    local function controlId(settings)
        return settings.Id or sanitize(feature.Id .. "_" .. (settings.Name or "control"))
    end

    -- Another feature inside the card: name on the left, gear / bell / switch on the right
    function card:AddToggle(subDef)
        local sub = self.Window:_newFeature(subDef, feature.Id)
        local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, content)
        Components.label(cardCtx, row, { Size = UDim2.new(1, -120, 1, 0), TextSize = 13, Text = sub.Name })
        local cluster = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, row)
        create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, cluster)
        self.Window:_addControls(cluster, cardCtx, sub)
        table.insert(self.Window._cards, { Frame = row, Tab = tab, Text = string.lower(sub.Name .. " " .. sub.Description .. " " .. feature.Name) })
        self.Window:_activate(sub)
        return sub
    end

    -- settings: Name, Min, Max, Step, Default, Callback(value), Id
    function card:AddSlider(settings)
        local id = controlId(settings)
        local savedValue = self.Window.Store:Get("controls." .. id)
        local start = type(savedValue) == "number" and savedValue or settings.Default or settings.Min or 0

        local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, content)
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
        local top = create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 1 }, row)
        Components.label(cardCtx, top, { Size = UDim2.new(1, -60, 1, 0), TextSize = 13, Text = settings.Name })
        local valueLabel = Components.label(cardCtx, top, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(60, 18), TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(start) }, "SubText")
        local slider = Components.slider(cardCtx, row, {
            Min = settings.Min or 0,
            Max = settings.Max or 100,
            Step = settings.Step,
            Value = start,
            OnChanged = function(value)
                valueLabel.Text = tostring(value)
                if settings.Callback then
                    pcall(settings.Callback, value)
                end
            end,
            OnDone = function(value)
                self.Window.Store:Set("controls." .. id, value)
            end,
        })
        slider.Instance.LayoutOrder = 2
        table.insert(self.Window._cards, { Frame = row, Tab = tab, Text = string.lower(settings.Name .. " " .. feature.Name) })
        if settings.Callback then
            pcall(settings.Callback, slider.Get())
        end
        return slider
    end

    -- settings: Name, Options, Default, Callback(option), Id
    function card:AddDropdown(settings)
        local id = controlId(settings)
        local savedValue = self.Window.Store:Get("controls." .. id)
        local start = settings.Default or settings.Options[1]
        for _, option in ipairs(settings.Options) do
            if option == savedValue then
                start = option
            end
        end

        local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, content)
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
        Components.label(cardCtx, row, { Size = UDim2.new(1, 0, 0, 18), TextSize = 13, Text = settings.Name }).LayoutOrder = 1
        local dropdown = Components.dropdown(cardCtx, row, {
            Options = settings.Options,
            Value = start,
            OnChanged = function(option)
                self.Window.Store:Set("controls." .. id, option)
                if settings.Callback then
                    pcall(settings.Callback, option)
                end
            end,
        })
        dropdown.Instance.LayoutOrder = 2
        table.insert(self.Window._cards, { Frame = row, Tab = tab, Text = string.lower(settings.Name .. " " .. feature.Name) })
        if settings.Callback then
            pcall(settings.Callback, start)
        end
        return dropdown
    end

    function card:AddButton(settings)
        local button = Components.button(cardCtx, content, {
            Text = settings.Name,
            OnClick = function()
                if settings.Callback then
                    local ok, err = pcall(settings.Callback)
                    if not ok then
                        warn("[Sora x Hikaru] button '" .. tostring(settings.Name) .. "' failed: " .. tostring(err))
                    end
                end
            end,
        })
        button.LayoutOrder = nextOrder()
        return button
    end

    function card:AddText(settings)
        local label = Components.label(cardCtx, content, {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = settings.Text or settings.Name or "",
        }, "SubText")
        label.LayoutOrder = nextOrder()
        return label
    end

    function card:AddDivider()
        local line = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, LayoutOrder = nextOrder() }, content)
        Components.bind(cardCtx, line, { BackgroundColor3 = "Stroke" })
        return line
    end

    card.Window = self
    self:_activate(feature)
    return card
end

-- Built-in sections ---------------------------------------------------

-- A plain card (not a feature) with a colored title
function Window:_plainCard(tab, titleText, column)
    local Components = self._modules.Components
    local create = Components.create
    local ctx = self._ctx

    local frame = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0 }, tab.Columns[column or 1])
    Components.corner(frame, 10)
    Components.bind(ctx, frame, { BackgroundColor3 = "Secondary" })
    Components.stroke(ctx, frame)
    create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, frame)
    create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
    Components.label(ctx, frame, { Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold, TextSize = 14, Text = titleText }, "Accent").LayoutOrder = 1
    tab.Empty.Visible = false
    table.insert(self._cards, { Frame = frame, Tab = tab, Text = string.lower(titleText) })
    return frame
end

-- Appearance: the six theme colors, each expands to a color picker; changes repaint everything at once
function Window:_buildAppearance(tab)
    local Components = self._modules.Components
    local ctx = self._ctx
    local frame = self:_plainCard(tab, "Appearance", 1)

    for index, entry in ipairs(colorRows) do
        local row = self._modules.ColorPicker.row(ctx, frame, { Name = entry[1], Key = entry[2] })
        row.LayoutOrder = index + 1
    end

    local order = #colorRows + 2
    for name in pairs(self._modules.Theme.Presets) do
        local button = Components.button(ctx, frame, {
            Text = "Preset: " .. name,
            OnClick = function()
                self.Theme:SetPreset(name)
            end,
        })
        button.LayoutOrder = order
        order = order + 1
    end
    local reset = Components.button(ctx, frame, { Text = "Reset colors", Primary = true, OnClick = function() self.Theme:Reset() end })
    reset.LayoutOrder = order
end

function Window:_buildConfig(tab)
    local Components = self._modules.Components
    local ctx = self._ctx
    local frame = self:_plainCard(tab, "Configuration", 1)

    Components.button(ctx, frame, {
        Text = "Save now",
        OnClick = function()
            local saved = self.Store:Flush()
            self:Notify("Configuration", saved and "Saved." or "Could not write the file.", 2, false)
        end,
    }).LayoutOrder = 2
    Components.button(ctx, frame, {
        Text = "Reset every feature's settings",
        OnClick = function()
            for _, feature in pairs(self._features) do
                feature:ResetSettings()
                feature:ResetNotifications()
            end
            self:Notify("Configuration", "All feature settings were reset.", 2, false)
        end,
    }).LayoutOrder = 3
end

-- Window state -----------------------------------------------------------

function Window:Show()
    self._root.Visible = true
    self._launcher.Visible = false
end

function Window:Hide()
    self._panels.Close()
    self._root.Visible = false
    self._launcher.Visible = true
end

function Window:Toggle()
    if self._root.Visible then
        self:Hide()
    else
        self:Show()
    end
end

function Window:Minimize(state)
    self._minimized = state == true
    self._body.Visible = not self._minimized
    self._modules.Components.tween(self._root, {
        Size = UDim2.fromOffset(windowWidth, self._minimized and topbarHeight or windowHeight),
    }, 0.2)
end

-- Removes every widget, connection, subscription and floating button, then saves
function Window:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true

    self._panels.Close()
    for _, floating in pairs(self._floating) do
        floating.Destroy()
    end
    self._floating = {}
    self._janitor:Cleanup()

    self._gui:Destroy()
    if self._floatingGui then
        self._floatingGui:Destroy()
    end
    self.Store:Destroy()
end

return Window
