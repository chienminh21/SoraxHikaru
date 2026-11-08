getgenv().GG = getgenv().GG or {}

-- Defaults 
GG.SelectedLanguage = GG.SelectedLanguage or "en"
GG.Theme = GG.Theme or "Dark"
GG.UIName = GG.UIName or "Sora x Hikaru"
GG.FolderName = GG.FolderName or "SoraHikaru"
GG.GuiName = GG.GuiName or "SoraHikaru"
GG.Transparency = GG.Transparency or 0.15
GG.Watermark = GG.Watermark ~= false
GG.ToggleKey = GG.ToggleKey or Enum.KeyCode.Insert  -- phím mở/đóng UI
GG.Animations = GG.Animations ~= false              -- bật/tắt tween
GG.TextColor = GG.TextColor or nil
GG.TextSecondaryColor = GG.TextSecondaryColor or nil
GG.AccentColor = GG.AccentColor or nil
GG.GalacticText = GG.GalacticText ~= false
GG.GalacticColor1 = GG.GalacticColor1 or Color3.fromRGB(99, 102, 241)
GG.GalacticColor2 = GG.GalacticColor2 or Color3.fromRGB(236, 72, 153)
GG.GalacticSpeed = GG.GalacticSpeed or 1.5
GG.Version = GG.Version or "v2.0"                   -- shown in the sidebar info card
GG.NotifyMode = GG.NotifyMode or nil                -- "new" (default) or "old"; nil = use the saved choice

local UI_NAME = GG.UIName
local FOLDER_NAME = GG.FolderName
local GUI_NAME = GG.GuiName
local VERSION = GG.Version

GG.Language = GG.Language or {
    CheckboxEnabled = "Enabled",
    CheckboxDisabled = "Disabled",
    SliderValue = "Value",
    DropdownSelect = "Select",
    DropdownNone = "None",
    DropdownSelected = "Selected",
    ButtonClick = "Click",
    TextboxEnter = "Enter",
    ModuleEnabled = "Enabled",
    ModuleDisabled = "Disabled",
    TabGeneral = "General",
    TabSettings = "Settings",
    Loading = "Loading...",
    Error = "Error",
    Success = "Success"
}

local SelectedLanguage = GG.SelectedLanguage or "en"

-- Theme Colors
local Theme = {
    Light = {
        Background = Color3.fromRGB(245, 247, 250),
        BackgroundSecondary = Color3.fromRGB(255, 255, 255),
        ModuleBackground = Color3.fromRGB(255, 255, 255),
        TextPrimary = Color3.fromRGB(30, 30, 40),
        TextSecondary = Color3.fromRGB(90, 90, 110),
        Accent = Color3.fromRGB(99, 102, 241),
        AccentHover = Color3.fromRGB(129, 140, 248),
        Stroke = Color3.fromRGB(220, 225, 235),
        Divider = Color3.fromRGB(230, 233, 240),
        ToggleOff = Color3.fromRGB(200, 200, 210),
        Card = Color3.fromRGB(235, 238, 245),
    },
    Dark = {
        Background = Color3.fromRGB(12, 13, 15),
        BackgroundSecondary = Color3.fromRGB(22, 28, 38),
        ModuleBackground = Color3.fromRGB(22, 28, 38),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(152, 181, 255),
        Accent = Color3.fromRGB(152, 181, 255),
        AccentHover = Color3.fromRGB(180, 200, 255),
        Stroke = Color3.fromRGB(52, 66, 89),
        Divider = Color3.fromRGB(52, 66, 89),
        ToggleOff = Color3.fromRGB(66, 80, 115),
        Card = Color3.fromRGB(32, 38, 51),
    }
}

local CurrentTheme = Theme[GG.Theme] or Theme.Dark

-- Apply custom colors if user set
if GG.TextColor then
    CurrentTheme.TextPrimary = GG.TextColor
end
if GG.TextSecondaryColor then
    CurrentTheme.TextSecondary = GG.TextSecondaryColor
end
if GG.AccentColor then
    CurrentTheme.Accent = GG.AccentColor
    CurrentTheme.AccentHover = GG.AccentColor:Lerp(Color3.new(1,1,1), 0.2)
end

local function applyThemeColors(target, source)
    for k, v in pairs(source) do
        target[k] = v
    end
    if GG.TextColor then target.TextPrimary = GG.TextColor end
    if GG.TextSecondaryColor then target.TextSecondary = GG.TextSecondaryColor end
    if GG.AccentColor then
        target.Accent = GG.AccentColor
        target.AccentHover = GG.AccentColor:Lerp(Color3.new(1,1,1), 0.2)
    end
end

function Library_SetTheme(name)
    name = name or "Dark"
    if name ~= "Dark" and name ~= "Light" then
        name = "Dark"
    end
    GG.Theme = name
    local src = Theme[name] or Theme.Dark
    applyThemeColors(CurrentTheme, src)

    -- Color picker popups are parented separately from the main interface.
    -- Update them explicitly whenever the active theme changes.
    for index = #Library._color_popups, 1, -1 do
        local updatePopupTheme = Library._color_popups[index]
        if updatePopupTheme then
            local success = pcall(updatePopupTheme)
            if not success then
                table.remove(Library._color_popups, index)
            end
        end
    end

    local gui = Library._ui
    if gui then
        local container = gui:FindFirstChild("Container")
        if container then
            container.BackgroundColor3 = CurrentTheme.Background
            local stroke = container:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = CurrentTheme.Stroke end
        end

        for _, obj in ipairs(gui:GetDescendants()) do
            if not obj:IsA("GuiObject") then
                continue
            end

            if obj.Name == "Module" and obj:IsA("Frame") then
                obj.BackgroundColor3 = CurrentTheme.ModuleBackground
                local st = obj:FindFirstChildOfClass("UIStroke")
                if st then st.Color = CurrentTheme.Stroke end
            elseif obj.Name == "Paragraph" or obj.Name == "Text" then
                obj.BackgroundColor3 = CurrentTheme.Card
            elseif obj.Name == "Divider" and obj:IsA("Frame") then
                obj.BackgroundColor3 = CurrentTheme.Stroke
            elseif obj:IsA("UIStroke") then
                if obj.Parent and (obj.Parent.Name == "Module" or obj.Parent.Name == "Container" or obj.Parent.Name == "Paragraph") then
                    obj.Color = CurrentTheme.Stroke
                end
            elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then
                local n = obj.Name
                if n == "ModuleName" or n == "ClientName" then
                    obj.TextColor3 = CurrentTheme.Accent
                elseif n == "Description" or n == "Value" or n == "CurrentOption" then
                    obj.TextColor3 = CurrentTheme.TextSecondary
                elseif n ~= "Option" and n ~= "KeybindLabel" then
                    -- general labels
                    if obj.TextTransparency < 0.5 then
                        obj.TextColor3 = CurrentTheme.TextPrimary
                    end
                end
            end
        end

        for _, data in ipairs(Library._all_modules or {}) do
            if data.frame then
                data.frame.BackgroundColor3 = CurrentTheme.ModuleBackground
            end
        end
    end

    -- Extra pieces (info card, key hint, watermark pill...) repaint themselves here
    for _, hook in ipairs(Library._theme_hooks or {}) do
        pcall(hook)
    end

    if Library.Notify then
        Library.Notify.Success("Theme", "Switched to " .. name, 2)
    end
    return true
end

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end

    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_SoraHikaru = CoreGui:FindFirstChild(GUI_NAME)

if old_SoraHikaru then
    Debris:AddItem(old_SoraHikaru, 0)
end

if not isfolder(FOLDER_NAME) then
    makefolder(FOLDER_NAME)
end

-- Small helper: create an Instance, set its properties, then parent it
local function mk(class, props, parent)
    local object = Instance.new(class)
    if props then
        for key, value in pairs(props) do
            object[key] = value
        end
    end
    if parent then
        object.Parent = parent
    end
    return object
end

local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
    
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end
    
            value:Disconnect()
        end
    end
}, Connections)


local Util = setmetatable({
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)

        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self: any)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y

        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)


local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur


function AcrylicBlur.new(object: GuiObject)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _frame = nil,
        _root = nil
    }, AcrylicBlur)

    self:setup()

    return self
end


function AcrylicBlur:create_folder()
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')

    if old_folder then
        Debris:AddItem(old_folder, 0)
    end

    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera

    self._folder = folder
end


function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting

    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then
            continue
        end

        if object == depth_of_fields then
            continue
        end

        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)

        object.FarIntensity = 0
    end
end


function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object

    self._frame = frame
end


function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)  -- Use a thin part
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder

    -- Create a SpecialMesh to simulate the acrylic blur effect
    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick  -- Use Brick mesh or another type suitable for the effect
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)  -- Small offset to prevent z-fighting
    specialMesh.Parent = part

    self._root = part  -- Store the part as root
end


function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    
    self:create_frame()
    self:render(0.001)

    self:check_quality_level()
end


function AcrylicBlur:render(distance: number)
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function update_positions(size: any, position: any)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function update()
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right

        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then
            return
        end

        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

        update_positions(size, position)
        task.spawn(update)
    end

    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)

    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    
    task.spawn(update)
end


function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then
        self:change_visiblity(false)
    end

    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value

        self:change_visiblity(quality_level >= 8)
    end)
end


function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end


local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile(FOLDER_NAME..'/'..file_name..'.json', flags)
        end)
    
        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfile(FOLDER_NAME..'/'..file_name..'.json') then
                self:save(file_name, config)
        
                return
            end
        
            local flags = readfile(FOLDER_NAME..'/'..file_name..'.json')
        
            if not flags then
                self:save(file_name, config)
        
                return
            end

            return HttpService:JSONDecode(flags)
        end)
    
        if not success_load then
            warn('failed to load config', result)
        end
    
        if not result then
            result = {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end
    
        return result
    end
}, Config)


local Library = {
    _config = Config:load(game.GameId),

    _choosing_keybind = false,
    _device = nil,

    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,

    _dragging = false,
    _drag_start = nil,
    _container_position = nil,

    _all_modules = {},  -- for Search
    _color_popups = {},
    _theme_hooks = {},  -- extra pieces that repaint themselves when the theme changes
}
Library.__index = Library
Library.SetTheme = Library_SetTheme

-- Make sure the config always has the sub tables the library expects
Library._config._flags = Library._config._flags or {}
Library._config._keybinds = Library._config._keybinds or {}
Library._config._library = Library._config._library or {}

-- Config Manager 
function Library.SaveConfig()
    Config:save(game.GameId, Library._config)
    if Library.Notify then
        Library.Notify.Success("Config", "Save config", 3)
    end
end

function Library.LoadConfig()
    Library._config = Config:load(game.GameId)
    if Library.Notify then
        Library.Notify.Info("Config", " load config (Reopen UI to fully apply)", 4)
    end
    return Library._config
end

function Library.ResetConfig()
    Library._config = {
        _flags = {},
        _keybinds = {},
        _library = {}
    }
    Config:save(game.GameId, Library._config)
    if Library.Notify then
        Library.Notify.Warn("Config", " reset config ", 3)
    end
end

function Library.ExportConfig()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(Library._config)
    end)
    if ok and encoded then
        if setclipboard then
            pcall(setclipboard, encoded)
            if Library.Notify then
                Library.Notify.Success("Config", "did copy config in clipboard", 3)
            end
        else
            if Library.Notify then
                Library.Notify.Info("Config", "Export OK (no copy in setclipboard)", 3)
            end
        end
        return encoded
    end
    if Library.Notify then
        Library.Notify.Error("Config", "Export wrong", 3)
    end
    return nil
end

function Library.ImportConfig(jsonString)
    if not jsonString or jsonString == "" then
        if Library.Notify then
            Library.Notify.Error("Config", "nothing config ", 3)
        end
        return false
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    if ok and typeof(data) == "table" then
        Library._config = data
        Config:save(game.GameId, Library._config)
        if Library.Notify then
            Library.Notify.Success("Config", "Import thành công (mở lại UI để áp dụng)", 4)
        end
        return true
    end
    if Library.Notify then
        Library.Notify.Error("Config", "Import wrong - JSON wrong", 3)
    end
    return false
end

function Library.GetKeybinds()
    local list = {}
    for flag, key in pairs(Library._config._keybinds or {}) do
        table.insert(list, {
            flag = flag,
            key = tostring(key):gsub("Enum.KeyCode.", "")
        })
    end
    return list
end

function Library.ClearKeybind(flag)
    if Library._config._keybinds then
        Library._config._keybinds[flag] = nil
        Config:save(game.GameId, Library._config)
    end
end

function Library.ClearAllKeybinds()
    Library._config._keybinds = {}
    Config:save(game.GameId, Library._config)
    if Library.Notify then
        Library.Notify.Warn("Keybinds", "del keybind", 3)
    end
end

-- Watermark (top-left label with the UI name and FPS)
function Library.DestroyWatermark()
    if Library._wm_connection then
        Library._wm_connection:Disconnect()
        Library._wm_connection = nil
    end
    if getgenv().SxH_Watermark then
        pcall(function() getgenv().SxH_Watermark:Destroy() end)
        getgenv().SxH_Watermark = nil
    end
end

function Library.CreateWatermark(text)
    Library.DestroyWatermark()

    local wmGui = Instance.new("ScreenGui")
    wmGui.Name = "SxH_Watermark"
    wmGui.ResetOnSpawn = false
    wmGui.IgnoreGuiInset = true
    wmGui.DisplayOrder = 50
    wmGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 0, 0, 28)
    frame.AutomaticSize = Enum.AutomaticSize.X
    frame.Position = UDim2.new(0, 12, 0, 12)
    frame.BackgroundColor3 = CurrentTheme.Card or CurrentTheme.BackgroundSecondary
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = wmGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = CurrentTheme.Accent
    stroke.Transparency = 0.5
    stroke.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 0, 1, 0)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = CurrentTheme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local showText = text or UI_NAME
    local fps = 0
    local frames = 0
    local last = os.clock()

    Library._wm_connection = RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - last >= 1 then
            fps = frames
            frames = 0
            last = now
            label.Text = string.format("%s  |  %d FPS", showText, fps)
        end
    end)
    label.Text = showText .. "  |  -- FPS"

    getgenv().SxH_Watermark = wmGui
    return wmGui
end

-- Turn the watermark on / off (also updates the "Show watermark" pill and saves the choice)
function Library.SetWatermark(state, silent)
    Library._watermark_on = state and true or false

    if Library._watermark_on then
        Library.CreateWatermark(UI_NAME)
    else
        Library.DestroyWatermark()
    end

    if Library._paint_watermark_pill then
        Library._paint_watermark_pill(Library._watermark_on)
    end

    if not silent then
        Library._config._library.watermark = Library._watermark_on
        Config:save(game.GameId, Library._config)
    end
end


function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)
    
    self:create_ui()

    return self
end

-- Dark text on light accents, white text on dark accents
local function contrastText(color)
    local brightness = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
    return brightness > 0.6 and Color3.fromRGB(12, 13, 15) or Color3.fromRGB(255, 255, 255)
end

--  Notification 
local Notify = {}
local MAX_VISIBLE = 5
local active = {}
local order = 0
local notifyConnections = {}

local function getNotifyParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    return (ok and ui) or CoreGui
end

-- 
if getgenv().SxH_Notify then
    pcall(function() getgenv().SxH_Notify.Destroy() end)
end

local notifyGui = Instance.new("ScreenGui")
notifyGui.Name = "SxH_Notify"
notifyGui.ResetOnSpawn = false
notifyGui.IgnoreGuiInset = true
notifyGui.DisplayOrder = 999
notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifyGui.Parent = getNotifyParent()

local holder = Instance.new("Frame")
holder.Name = "Holder"
holder.AnchorPoint = Vector2.new(1, 0)
holder.Position = UDim2.new(1, -12, 0, 12)
holder.Size = UDim2.new(0, 300, 1, -24)
holder.BackgroundTransparency = 1
holder.Parent = notifyGui

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.HorizontalAlignment = Enum.HorizontalAlignment.Right
list.Parent = holder

local uiScale = Instance.new("UIScale")
uiScale.Parent = holder

local function updateNotifyScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local w = cam.ViewportSize.X
    uiScale.Scale = UserInputService.TouchEnabled and math.clamp(w / 1100, 0.7, 1) or 1
end
updateNotifyScale()
if workspace.CurrentCamera then
    table.insert(notifyConnections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateNotifyScale))
end

local function getNotifyColors()
    local accent = CurrentTheme.Accent
    return {
        info = accent,
        success = Color3.fromRGB(95, 220, 140),
        warning = Color3.fromRGB(255, 190, 70),
        error = Color3.fromRGB(255, 95, 95),
        bg = CurrentTheme.Card or CurrentTheme.BackgroundSecondary,
        title = CurrentTheme.TextPrimary,
        body = CurrentTheme.TextSecondary,
    }
end

-- ===== OLD style (original notification: colored bar on the left + progress bar) =====
local function sendOld(settings)
    settings = settings or {}
    local colors = getNotifyColors()
    local kind = (settings.type and colors[settings.type]) and settings.type or "info"
    local color = colors[kind]
    local duration = tonumber(settings.duration) or 4
    order += 1

    local wrapper = Instance.new("Frame")
    wrapper.Name = "Notification"
    wrapper.BackgroundTransparency = 1
    wrapper.Size = UDim2.new(1, 0, 0, 0)
    wrapper.AutomaticSize = Enum.AutomaticSize.Y
    wrapper.LayoutOrder = order
    wrapper.Parent = holder

    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.Size = UDim2.new(1, 0, 0, 0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Position = UDim2.new(1, 40, 0, 0)
    inner.BackgroundColor3 = colors.bg
    inner.BackgroundTransparency = 1
    inner.BorderSizePixel = 0
    inner.ClipsDescendants = true
    inner.Active = true
    inner.Parent = wrapper

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = inner

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = 0.55
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = inner

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.ZIndex = 2
    accent.Parent = inner

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.Parent = inner

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local function makeLabel(text, font, size, col, layoutOrder)
        local lb = Instance.new("TextLabel")
        lb.BackgroundTransparency = 1
        lb.Size = UDim2.new(1, 0, 0, 0)
        lb.AutomaticSize = Enum.AutomaticSize.Y
        lb.Font = font
        lb.TextSize = size
        lb.TextColor3 = col
        lb.Text = text
        lb.TextWrapped = true
        lb.TextXAlignment = Enum.TextXAlignment.Left
        lb.TextYAlignment = Enum.TextYAlignment.Top
        lb.LayoutOrder = layoutOrder
        lb.Parent = content
        return lb
    end

    if settings.title and settings.title ~= "" then
        makeLabel(tostring(settings.title), Enum.Font.GothamBold, 14, colors.title, 1)
    end
    if settings.text and settings.text ~= "" then
        makeLabel(tostring(settings.text), Enum.Font.Gotham, 12, colors.body, 2)
    end

    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.AnchorPoint = Vector2.new(0, 1)
    progress.Position = UDim2.new(0, 0, 1, 0)
    progress.Size = UDim2.new(1, 0, 0, 2)
    progress.BackgroundColor3 = color
    progress.BackgroundTransparency = 0.25
    progress.BorderSizePixel = 0
    progress.ZIndex = 2
    progress.Parent = inner

    local closing = false
    local entry = {}

    local function dismiss()
        if closing then return end
        closing = true
        local idx = table.find(active, entry)
        if idx then table.remove(active, idx) end
        local tween = TweenService:Create(inner, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 40, 0, 0),
            BackgroundTransparency = 1,
        })
        tween:Play()
        tween.Completed:Once(function()
            wrapper:Destroy()
        end)
    end
    entry.Dismiss = dismiss

    table.insert(active, entry)
    if #active > MAX_VISIBLE then
        active[1].Dismiss()
    end

    inner.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dismiss()
        end
    end)

    TweenService:Create(inner, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.12,
    }):Play()

    TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2),
    }):Play()
    task.delay(duration, dismiss)

    return entry
end

-- ===== NEW style (rounded dark pill with a round icon on the left) =====
local function sendNew(settings)
    settings = settings or {}

    local accent = CurrentTheme.Accent
    local kinds = {
        info = { color = accent, symbol = "i" },
        success = { color = accent, symbol = "\226\156\147" },
        warning = { color = Color3.fromRGB(245, 180, 50), symbol = "!" },
        error = { color = Color3.fromRGB(240, 85, 85), symbol = "x" },
    }
    local kind = kinds[settings.type] and settings.type or "info"
    local style = kinds[kind]
    local duration = tonumber(settings.duration) or 4
    order += 1

    local wrapper = mk("Frame", {
        Name = "Notification",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order,
    }, holder)

    local inner = mk("Frame", {
        Name = "Inner",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1, 40, 0, 0),
        BackgroundColor3 = CurrentTheme.ModuleBackground,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
    }, wrapper)
    mk("UICorner", { CornerRadius = UDim.new(0, 14) }, inner)
    mk("UIStroke", { Color = CurrentTheme.Stroke, Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inner)

    -- Round icon on the left
    local icon = mk("Frame", {
        Name = "Icon",
        Position = UDim2.fromOffset(12, 9),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = style.color,
        BorderSizePixel = 0,
    }, inner)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, icon)
    mk("TextLabel", {
        Name = "Symbol",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = contrastText(style.color),
        Text = style.symbol,
    }, icon)

    local content = mk("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, inner)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 11),
        PaddingBottom = UDim.new(0, 11),
        PaddingLeft = UDim.new(0, 46),
        PaddingRight = UDim.new(0, 14),
    }, content)
    mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, content)

    local function label(text, font, size, textColor, layoutOrder)
        return mk("TextLabel", {
            Name = "NotifyText",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = font,
            TextSize = size,
            TextColor3 = textColor,
            Text = text,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = layoutOrder,
        }, content)
    end

    if settings.title and settings.title ~= "" then
        label(tostring(settings.title), Enum.Font.GothamMedium, 13, CurrentTheme.TextPrimary, 1)
    end
    if settings.text and settings.text ~= "" then
        label(tostring(settings.text), Enum.Font.Gotham, 11, CurrentTheme.TextSecondary, 2)
    end

    local closing = false
    local entry = {}

    local function dismiss()
        if closing then return end
        closing = true
        local idx = table.find(active, entry)
        if idx then table.remove(active, idx) end
        local out = TweenService:Create(inner, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 40, 0, 0),
            BackgroundTransparency = 1,
        })
        out:Play()
        out.Completed:Once(function()
            wrapper:Destroy()
        end)
    end
    entry.Dismiss = dismiss

    table.insert(active, entry)
    if #active > MAX_VISIBLE then
        active[1].Dismiss()
    end

    inner.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dismiss()
        end
    end)

    TweenService:Create(inner, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.03,
    }):Play()
    task.delay(duration, dismiss)

    return entry
end

-- Which style is active: GG.NotifyMode (if set), otherwise the saved choice, otherwise "new"
local function getNotifyMode()
    local mode = GG.NotifyMode
    if mode ~= "old" and mode ~= "new" then
        mode = Library._config._library and Library._config._library.notify_mode
    end
    return mode == "old" and "old" or "new"
end

function Notify.Send(settings)
    if getNotifyMode() == "old" then
        return sendOld(settings)
    end
    return sendNew(settings)
end

function Notify.Info(title, text, duration)
    return Notify.Send({ title = title, text = text, duration = duration, type = "info" })
end
function Notify.Success(title, text, duration)
    return Notify.Send({ title = title, text = text, duration = duration, type = "success" })
end
function Notify.Warn(title, text, duration)
    return Notify.Send({ title = title, text = text, duration = duration, type = "warning" })
end
function Notify.Error(title, text, duration)
    return Notify.Send({ title = title, text = text, duration = duration, type = "error" })
end

Notify.SendNotification = Notify.Send

function Notify.Clear()
    for _, e in ipairs(table.clone(active)) do
        e.Dismiss()
    end
end

function Notify.Destroy()
    for _, c in ipairs(notifyConnections) do c:Disconnect() end
    table.clear(notifyConnections)
    table.clear(active)
    notifyGui:Destroy()
    getgenv().SxH_Notify = nil
end

getgenv().SxH_Notify = Notify

-- 
function Library.SendNotification(settings)
    return Notify.Send(settings)
end

Library.Notify = Notify

-- Switch between the "old" and "new" notification style (saved in the config)
function Library.SetNotifyMode(mode)
    mode = (mode == "old") and "old" or "new"
    GG.NotifyMode = mode
    Library._config._library.notify_mode = mode
    Config:save(game.GameId, Library._config)
    Notify.Info("Notifications", "Style: " .. mode, 2)
    return mode
end

function Library.GetNotifyMode()
    return getNotifyMode()
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X

    self._ui_scale = viewport_size_x / 1400
end


function Library:get_device()
    local device = 'Unknown'

    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end

    self._device = device
end


function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end


function Library:flag_type(flag: any, flag_type: any)
    if not Library._config._flags[flag] then
        return
    end

    return typeof(Library._config._flags[flag]) == flag_type
end


function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end

        table.remove(__table, index)
    end
end


function Library:create_ui()
    local old_SoraHikaru = CoreGui:FindFirstChild(GUI_NAME)

    if old_SoraHikaru then
        Debris:AddItem(old_SoraHikaru, 0)
    end

    local MainGui = Instance.new('ScreenGui')
    MainGui.ResetOnSpawn = false
    MainGui.Name = GUI_NAME
    MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MainGui.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = GG.Transparency or 0.25
    Container.BackgroundColor3 = CurrentTheme.Background
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = MainGui
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = CurrentTheme.Stroke
    UIStroke.Transparency = 0.3
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 330)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026097271591424942, 0, 0.1111111119389534, 0)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextTransparency = 0
    ClientName.Text = UI_NAME
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 110, 0, 16)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.0560000017285347, 0, 0.054999999701976776, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.TextSize = 14
    ClientName.Parent = Handler
    
    -- Galactic Text Effect
    if GG.GalacticText then
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, GG.GalacticColor1),
            ColorSequenceKeypoint.new(0.5, GG.GalacticColor2),
            ColorSequenceKeypoint.new(1, GG.GalacticColor1)
        }
        UIGradient.Parent = ClientName

        --  gradient loop
        task.spawn(function()
            local offset = 0
            while ClientName and ClientName.Parent do
                offset = offset + 0.015 * (GG.GalacticSpeed or 1.5)
                if offset > 1 then offset = -1 end
                UIGradient.Offset = Vector2.new(offset, 0)
                task.wait()
            end
        end)
    else
        ClientName.TextColor3 = CurrentTheme.Accent
    end
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026000000536441803, 0, 0.13600000739097595, 0)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = CurrentTheme.Accent
    Pin.Parent = Handler
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = CurrentTheme.Accent
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://107819132007001'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.02500000037252903, 0, 0.054999999701976776, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon.Parent = Handler
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.23499999940395355, 0, 0, 0)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = CurrentTheme.Stroke
    Divider.Parent = Handler
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    ---------------------------------------------------------------
    -- Info card (bottom-left of the sidebar)
    ---------------------------------------------------------------
    local InfoCard = mk('Frame', {
        Name = 'InfoCard',
        Position = UDim2.fromOffset(10, 397),
        Size = UDim2.fromOffset(144, 44),
        BackgroundColor3 = CurrentTheme.ModuleBackground,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, Handler)
    mk('UICorner', { CornerRadius = UDim.new(0, 9) }, InfoCard)
    local InfoStroke = mk('UIStroke', {
        Color = CurrentTheme.Stroke,
        Transparency = 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, InfoCard)

    local InfoDot = mk('Frame', {
        Name = 'InfoDot',
        Position = UDim2.fromOffset(10, 14),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = CurrentTheme.Accent,
        BorderSizePixel = 0,
    }, InfoCard)
    mk('UICorner', { CornerRadius = UDim.new(1, 0) }, InfoDot)
    local InfoLetter = mk('TextLabel', {
        Name = 'InfoLetter',
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = contrastText(CurrentTheme.Accent),
        Text = 'i',
    }, InfoDot)

    local InfoTitle = mk('TextLabel', {
        Name = 'InfoTitle',
        Position = UDim2.fromOffset(34, 8),
        Size = UDim2.fromOffset(104, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = CurrentTheme.TextPrimary,
        Text = UI_NAME .. ' ' .. VERSION,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, InfoCard)
    local InfoSub = mk('TextLabel', {
        Name = 'InfoSub',
        Position = UDim2.fromOffset(34, 23),
        Size = UDim2.fromOffset(104, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = CurrentTheme.TextSecondary,
        Text = 'Have a good day! ♡',
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, InfoCard)

    ---------------------------------------------------------------
    -- Key hint: [*] [Insert] to toggle UI
    ---------------------------------------------------------------
    local toggleKeyName = (typeof(GG.ToggleKey) == 'EnumItem' and GG.ToggleKey.Name) or tostring(GG.ToggleKey or 'Insert')
    local keyWidth = TextService:GetTextSize(toggleKeyName, 10, Enum.Font.GothamMedium, Vector2.new(1000, 100)).X + 14

    local function makeChip(text, x, width)
        local chip = mk('TextLabel', {
            Name = 'KeyChip',
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = CurrentTheme.TextPrimary,
            BackgroundColor3 = CurrentTheme.Card,
            Position = UDim2.fromOffset(x, 452),
            Size = UDim2.fromOffset(width, 18),
            BorderSizePixel = 0,
        }, Handler)
        mk('UICorner', { CornerRadius = UDim.new(0, 5) }, chip)
        return chip
    end

    local StarChip = makeChip('*', 14, 18)
    local KeyChip = makeChip(toggleKeyName, 36, keyWidth)
    local HintLabel = mk('TextLabel', {
        Name = 'KeyHint',
        Text = 'to toggle UI',
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = CurrentTheme.TextSecondary,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(36 + keyWidth + 6, 452),
        Size = UDim2.fromOffset(60, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Handler)

    ---------------------------------------------------------------
    -- "Show watermark" pill (bottom-right of the window)
    ---------------------------------------------------------------
    local Pill = mk('Frame', {
        Name = 'WatermarkPill',
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -12, 1, -8),
        Size = UDim2.fromOffset(140, 28),
        BackgroundColor3 = CurrentTheme.ModuleBackground,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, Handler)
    mk('UICorner', { CornerRadius = UDim.new(0, 9) }, Pill)
    local PillStroke = mk('UIStroke', {
        Color = CurrentTheme.Stroke,
        Transparency = 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, Pill)
    local PillIcon = mk('TextLabel', {
        Name = 'PillIcon',
        Position = UDim2.fromOffset(9, 0),
        Size = UDim2.fromOffset(16, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = CurrentTheme.TextSecondary,
        Text = '\240\159\145\145',
    }, Pill)
    local PillText = mk('TextLabel', {
        Name = 'PillText',
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.fromOffset(76, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = CurrentTheme.TextPrimary,
        Text = 'Show watermark',
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Pill)

    local PillTrack = mk('TextButton', {
        Name = 'PillTrack',
        Text = '',
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(26, 14),
        BackgroundColor3 = CurrentTheme.ToggleOff,
        BorderSizePixel = 0,
    }, Pill)
    mk('UICorner', { CornerRadius = UDim.new(1, 0) }, PillTrack)
    local PillKnob = mk('Frame', {
        Name = 'PillKnob',
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, PillTrack)
    mk('UICorner', { CornerRadius = UDim.new(1, 0) }, PillKnob)

    local function paintPill(state)
        TweenService:Create(PillTrack, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.ToggleOff,
        }):Play()
        TweenService:Create(PillKnob, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        }):Play()
    end
    Library._paint_watermark_pill = paintPill

    PillTrack.MouseButton1Click:Connect(function()
        Library.SetWatermark(not Library._watermark_on)
    end)

    -- Repaint the extra pieces when the theme changes
    table.insert(Library._theme_hooks, function()
        InfoCard.BackgroundColor3 = CurrentTheme.ModuleBackground
        InfoStroke.Color = CurrentTheme.Stroke
        InfoDot.BackgroundColor3 = CurrentTheme.Accent
        InfoLetter.TextColor3 = contrastText(CurrentTheme.Accent)
        InfoTitle.TextColor3 = CurrentTheme.TextPrimary
        InfoSub.TextColor3 = CurrentTheme.TextSecondary
        StarChip.BackgroundColor3 = CurrentTheme.Card
        StarChip.TextColor3 = CurrentTheme.TextPrimary
        KeyChip.BackgroundColor3 = CurrentTheme.Card
        KeyChip.TextColor3 = CurrentTheme.TextPrimary
        HintLabel.TextColor3 = CurrentTheme.TextSecondary
        Pill.BackgroundColor3 = CurrentTheme.ModuleBackground
        PillStroke.Color = CurrentTheme.Stroke
        PillIcon.TextColor3 = CurrentTheme.TextSecondary
        PillText.TextColor3 = CurrentTheme.TextPrimary
        paintPill(Library._watermark_on)
    end)
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = MainGui
    Library._ui = MainGui  --  colorpicker 

    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a)
            end)
        end
    end

    function self:SetTransparency(value)
        value = math.clamp(tonumber(value) or 0.15, 0, 0.9)
        GG.Transparency = value
        Container.BackgroundTransparency = value
    end

    Library.SetTransparency = function(value)
        if Library._ui then
            local container = Library._ui:FindFirstChild("Container")
            if container then
                value = math.clamp(tonumber(value) or 0.15, 0, 0.9)
                GG.Transparency = value
                container.BackgroundTransparency = value
            end
        end
    end

    function self:UIVisiblity()
        MainGui.Enabled = not MainGui.Enabled;
    end;

    function self:change_visiblity(state: boolean)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end
    

    function self:load()
        local content = {}
    
        for _, object in MainGui:GetDescendants() do
            if not object:IsA('ImageLabel') then
                continue
            end
    
            table.insert(content, object)
        end
    
        ContentProvider:PreloadAsync(content)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
    
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
    
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()

        AcrylicBlur.new(Container)

        -- Watermark: the saved choice wins, otherwise GG.Watermark decides
        local savedWatermark = Library._config._library.watermark
        if savedWatermark == nil then
            savedWatermark = (GG.Watermark ~= false)
        end
        Library.SetWatermark(savedWatermark, true)

        self._ui_loaded = true
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3)

                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.135 + offset)
                    }):Play()    

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.2,
                        TextColor3 = CurrentTheme.Accent
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = CurrentTheme.Accent
                    }):Play()
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = CurrentTheme.TextPrimary
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end
        end
    end

    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true

                continue
            end

            object.Visible = false
        end
    end

    function self:create_tab(title: string, icon: string)
        local TabManager = {}

        local LayoutOrder = 0;

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = CurrentTheme.BackgroundSecondary
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = CurrentTheme.TextPrimary
        TextLabel.TextTransparency = 0.7 -- 0.800000011920929
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.2400001734495163, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab
        
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.800000011920929
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 412)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.2594326436519623, 0, 0.5, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 412)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.6290000081062317, 0, 0.5, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = RightSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = CurrentTheme.ModuleBackground
            Module.Parent = settings.section

            -- Track for Search
            table.insert(Library._all_modules, {
                frame = Module,
                title = string.lower(settings.title or "")
            })

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = CurrentTheme.Stroke
            UIStroke.Transparency = 0.5
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = CurrentTheme.Accent
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.699999988079071
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Icon.Parent = Header
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = CurrentTheme.Accent
            ModuleName.TextTransparency = 0.20000000298023224
            if not settings.rich then
                ModuleName.Text = settings.title or "Skibidi"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,0,0)'>" .. UI_NAME .. "</font> user"
            end;
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleName.TextSize = 13
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = CurrentTheme.Accent
            Description.TextTransparency = 0.699999988079071
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 10
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.699999988079071
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.20000000298023224
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(66, 80, 115)
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Keybind = Instance.new('Frame')
            Keybind.Name = 'Keybind'
            Keybind.BackgroundTransparency = 0.699999988079071
            Keybind.Position = UDim2.new(0.15000000596046448, 0, 0.7350000143051147, 0)
            Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = CurrentTheme.Accent
            Keybind.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind
            
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(209, 222, 255)
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.Text = 'None'
            TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            TextLabel.Size = UDim2.new(0, 25, 0, 13)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 10
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.Parent = Keybind
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = CurrentTheme.Stroke
            Divider.Parent = Header
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = CurrentTheme.Stroke
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if ModuleManager._state then
                    ModuleManager:refresh_size()
                end
            end)

            local function get_options_height()
                local layout = Options:FindFirstChildOfClass("UIListLayout")
                local contentY = layout and layout.AbsoluteContentSize.Y or 0
                local trackedHeight = ModuleManager._size or 0

                -- Keep enough room for layout padding and the last control.
                local measuredHeight = contentY + 20
                local fallbackHeight = trackedHeight + 20

                return math.max(measuredHeight, fallbackHeight)
            end

            function ModuleManager:refresh_size()
                if not ModuleManager._state then
                    return
                end

                local optionsHeight = get_options_height()

                Options.Size = UDim2.fromOffset(241, optionsHeight)
                Module.Size = UDim2.fromOffset(241, 93 + optionsHeight)
            end

            -- UIListLayout can update its content size one frame after a control
            -- is inserted. Recalculate after the layout has settled so the last
            -- control is not clipped by Module.ClipsDescendants.
            local function schedule_size_refresh()
                task.defer(function()
                    task.defer(function()
                        ModuleManager:refresh_size()
                    end)
                end)
            end

            Options.ChildAdded:Connect(schedule_size_refresh)
            Options.ChildRemoved:Connect(schedule_size_refresh)

            function ModuleManager:change_state(state: boolean)
                self._state = state

                if self._state then
                    local h = get_options_height()
                    Options.Size = UDim2.fromOffset(241, h)

                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + h)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = CurrentTheme.Accent
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = CurrentTheme.Accent,
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()

                    -- remeasure after layout updates
                    task.defer(function()
                        if self._state then
                            ModuleManager:refresh_size()
                            task.defer(function()
                                if self._state then
                                    ModuleManager:refresh_size()
                                end
                            end)
                        end
                    end)
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(66, 80, 115),
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end

                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)

                settings.callback(self._state)
            end
            
            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end

                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end
                    
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty: boolean)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')

                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    font_params.Size = 10
                    font_params.Width = 10000
            
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    
                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    TextLabel.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    TextLabel.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = true
                settings.callback(ModuleManager._state)

                Toggle.BackgroundColor3 = CurrentTheme.Accent
                Circle.BackgroundColor3 = CurrentTheme.Accent
                Circle.Position = UDim2.fromScale(0.53, 0.5)
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string

                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input: InputObject)
                if Library._choosing_keybind then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
                    return
                end
                
                Library._choosing_keybind = true
                
                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if input == Enum.UserInputState or input == Enum.UserInputType then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Backspace then
                        ModuleManager:scale_keybind(true)

                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)

                        TextLabel.Text = 'None'
                        
                        if Connections[settings.flag..'_keybind'] then
                            Connections[settings.flag..'_keybind']:Disconnect()
                            Connections[settings.flag..'_keybind'] = nil
                        end

                        Connections['keybind_choose_start']:Disconnect()
                        Connections['keybind_choose_start'] = nil

                        Library._choosing_keybind = false

                        return
                    end
                    
                    Connections['keybind_choose_start']:Disconnect()
                    Connections['keybind_choose_start'] = nil
                    
                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                    Config:save(game.GameId, Library._config)

                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end

                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                    
                    Library._choosing_keybind = false

                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;

                local ParagraphManager = {}
                
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 70
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                -- Container Frame
                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = CurrentTheme.Card
                Paragraph.BackgroundTransparency = 0.1
                Paragraph.Size = UDim2.new(0, 207, 0, 30) -- Initial size, auto-resized later
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y -- Support auto-resizing height
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule;
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph
            
                -- Title Label
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = CurrentTheme.TextPrimary
                Title.Text = settings.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.Parent = Paragraph
            
                -- Body Text
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = CurrentTheme.TextSecondary
                
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi"
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>" .. UI_NAME .. "</font> user"
                end
                
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph
            
                -- Hover effect for Paragraph (optional)
                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = CurrentTheme.Card:Lerp(CurrentTheme.Accent, 0.15)
                    }):Play()
                end)
            
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = CurrentTheme.Card
                    }):Play()
                end)

                return ParagraphManager
            end

            function ModuleManager:create_text(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextManager = {}
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 50 -- Adjust the default height for text elements
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                -- Container Frame
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = CurrentTheme.Card
                TextFrame.BackgroundTransparency = 0.1
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize) -- Initial size, auto-resized later
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y -- Support auto-resizing height
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame
            
                -- Body Text
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = CurrentTheme.TextSecondary
            
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi" -- Default text
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>" .. UI_NAME .. "</font> user" -- Default rich text
                end
            
                Body.Size = UDim2.new(1, -10, 1, 0)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame
            
                -- Hover effect for TextFrame (optional)
                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = CurrentTheme.Card:Lerp(CurrentTheme.Accent, 0.15)
                    }):Play()
                end)
            
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = CurrentTheme.Card
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Skibidi" -- Default text
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(255,0,0)'>" .. UI_NAME .. "</font> user" -- Default rich text
                    end
                end;
            
                return TextManager
            end
            function ModuleManager:create_textbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextboxManager = {
                    _text = ""
                }
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 32
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = CurrentTheme.TextPrimary
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.AnchorPoint = Vector2.new(0, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.BorderSizePixel = 0
                Label.Parent = Options
                Label.TextSize = 10;
                Label.LayoutOrder = LayoutOrderModule
            
                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = CurrentTheme.TextPrimary
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = CurrentTheme.Accent
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Textbox
            
                function TextboxManager:update_text(text: string)
                    self._text = text
                    Library._config._flags[settings.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._text)
                end
            
                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end
            
                Textbox.FocusLost:Connect(function()
                    TextboxManager:update_text(Textbox.Text)
                end)
            
                return TextboxManager
            end   

            function ModuleManager:create_checkbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                if SelectedLanguage == "th" then
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 13
                else
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 11
                end
                TitleLabel.TextColor3 = CurrentTheme.TextPrimary
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Skibidi"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox

                local KeybindBox = Instance.new("Frame")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(14, 14)
                KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
                KeybindBox.BackgroundColor3 = CurrentTheme.Accent
                KeybindBox.BorderSizePixel = 0
                KeybindBox.Parent = Checkbox
            
                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 4)
                KeybindCorner.Parent = KeybindBox
            
                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Name = "KeybindLabel"
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                KeybindLabel.TextScaled = false
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[settings.flag] 
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "") 
                    or "..."
                KeybindLabel.Parent = KeybindBox
            
                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = CurrentTheme.Accent
                Box.Parent = Checkbox
            
                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Parent = Box
            
                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = CurrentTheme.Accent
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._state)
                end
            
                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end
            
                Checkbox.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)
            
                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end
            
                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if processed then return end
                        if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if keyInput.KeyCode == Enum.KeyCode.Unknown then return end
            
                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            ModuleManager:scale_keybind(true)
                            Library._config._keybinds[settings.flag] = nil
                            Config:save(game.GameId, Library._config)
                            KeybindLabel.Text = "..."
                            if Connections[settings.flag .. "_keybind"] then
                                Connections[settings.flag .. "_keybind"]:Disconnect()
                                Connections[settings.flag .. "_keybind"] = nil
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end
            
                        chooseConnection:Disconnect()
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections[settings.flag .. "_keybind"] then
                            Connections[settings.flag .. "_keybind"]:Disconnect()
                            Connections[settings.flag .. "_keybind"] = nil
                        end
                        ModuleManager:connect_keybind()
                        ModuleManager:scale_keybind()
                        Library._choosing_keybind = false
            
                        local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        KeybindLabel.Text = keybind_string
                    end)
                end)
            
                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[settings.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CheckboxManager:change_state(not CheckboxManager._state)
                        end
                    end
                end)
                Connections[settings.flag .. "_keypress"] = keyPressConnection
            
                return CheckboxManager
            end

            function ModuleManager:create_divider(settings: any)
                -- Layout order management
                LayoutOrderModule = LayoutOrderModule + 1;
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 27
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                local dividerHeight = 1
                local dividerWidth = 207 -- Adjust this to fit your UI width
            
                -- Create the outer frame to control spacing above and below
                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, dividerWidth, 0, 20) -- Height here controls spacing above and below
                OuterFrame.BackgroundTransparency = 1 -- Fully invisible
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = CurrentTheme.TextPrimary -- 154, 182, 255
                    TextLabel.TextTransparency = 0
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    TextLabel.TextSize = 11
                    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;
                
                if not settings or settings and not settings.disableline then
                    -- Create the inner divider frame that will be placed in the middle of the OuterFrame
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White color
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2;
                    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2) -- Center the divider vertically in the OuterFrame
                
                    -- Add a UIGradient to the divider for left and right transparency
                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),  -- Start with white
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), -- Keep it white in the middle
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))  -- Fade to transparent on the right side
                    })
                    Gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),   
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    Gradient.Rotation = 0 -- Horizontal gradient (fade from left to right)
                
                    -- Optionally, you can add a corner radius for rounded ends
                    local UICorner = Instance.new('UICorner')
                    UICorner.CornerRadius = UDim.new(0, 2) -- Small corner radius for smooth edges
                    UICorner.Parent = Divider

                end;
            
                return true;
            end
            
            function ModuleManager:create_slider(settings: any)

                LayoutOrderModule = LayoutOrderModule + 1

                local SliderManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 27

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal);
                Slider.TextSize = 14;
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule
                
                local TextLabel = Instance.new('TextLabel')
                if SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = CurrentTheme.TextPrimary
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05000000074505806, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Slider
                
                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.8999999761581421
                Drag.Position = UDim2.new(0.5, 0, 0.949999988079071, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = CurrentTheme.Accent
                Drag.Parent = Slider
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag
                
                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = CurrentTheme.Accent
                Fill.Parent = Drag
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill
                
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 79, 79))
                }
                UIGradient.Parent = Fill
                
                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.Parent = Fill
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = CurrentTheme.TextPrimary
                Value.TextTransparency = 0.20000000298023224
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Value.TextSize = 10
                Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Value.Parent = Slider

                function SliderManager:set_percentage(percentage: number)
                    local rounded_number = 0

                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end

                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)
                    
                    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)
    
                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = number_threshold
    
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()
    
                    settings.callback(number_threshold)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()
    
                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)
                    
                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input: InputObject, process: boolean)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
    
                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)

                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config);
                        end;
                    end)
                end


                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag]);
                    else
                        SliderManager:set_percentage(settings.value);
                    end;
                else
                    SliderManager:set_percentage(settings.value);
                end;
    
                Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                return SliderManager
            end

            function ModuleManager:create_range_slider(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1

                local RangeSliderManager = {
                    min_value = settings.min_value or settings.minimum_value or 0,
                    max_value = settings.max_value or settings.maximum_value or 100,
                }

                if self._size == 0 then
                    self._size = 11
                end
                self._size += 27

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Slider.TextSize = 14
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'RangeSlider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local TextLabel = Instance.new('TextLabel')
                if SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 11
                end
                TextLabel.TextColor3 = CurrentTheme.TextPrimary
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title or "Range"
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.Parent = Slider

                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.9
                Drag.Position = UDim2.new(0.5, 0, 0.95, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = CurrentTheme.Accent
                Drag.Parent = Slider

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag

                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 0, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = CurrentTheme.Accent
                Fill.Parent = Drag

                local UICornerFill = Instance.new('UICorner')
                UICornerFill.CornerRadius = UDim.new(0, 3)
                UICornerFill.Parent = Fill

                local MinThumb = Instance.new('Frame')
                MinThumb.AnchorPoint = Vector2.new(0.5, 0.5)
                MinThumb.Name = 'MinThumb'
                MinThumb.Position = UDim2.new(0, 0, 0.5, 0)
                MinThumb.Size = UDim2.new(0, 8, 0, 8)
                MinThumb.BorderSizePixel = 0
                MinThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                MinThumb.Parent = Drag

                local MinCorner = Instance.new('UICorner')
                MinCorner.CornerRadius = UDim.new(1, 0)
                MinCorner.Parent = MinThumb

                local MaxThumb = Instance.new('Frame')
                MaxThumb.AnchorPoint = Vector2.new(0.5, 0.5)
                MaxThumb.Name = 'MaxThumb'
                MaxThumb.Position = UDim2.new(1, 0, 0.5, 0)
                MaxThumb.Size = UDim2.new(0, 8, 0, 8)
                MaxThumb.BorderSizePixel = 0
                MaxThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                MaxThumb.Parent = Drag

                local MaxCorner = Instance.new('UICorner')
                MaxCorner.CornerRadius = UDim.new(1, 0)
                MaxCorner.Parent = MaxThumb

                local ValueDisplay = Instance.new('TextLabel')
                ValueDisplay.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                ValueDisplay.TextColor3 = CurrentTheme.TextPrimary
                ValueDisplay.TextTransparency = 0.2
                ValueDisplay.Text = string.format("%.1f - %.1f", RangeSliderManager.min_value, RangeSliderManager.max_value)
                ValueDisplay.Name = 'Value'
                ValueDisplay.Size = UDim2.new(0, 80, 0, 13)
                ValueDisplay.AnchorPoint = Vector2.new(1, 0)
                ValueDisplay.Position = UDim2.new(1, 0, 0, 0)
                ValueDisplay.BackgroundTransparency = 1
                ValueDisplay.TextXAlignment = Enum.TextXAlignment.Right
                ValueDisplay.TextSize = 10
                ValueDisplay.Parent = Slider

                local min_val = settings.minimum_value or 0
                local max_val = settings.maximum_value or 100

                function RangeSliderManager:update_positions(animate)
                    local min_percent = math.clamp((self.min_value - min_val) / (max_val - min_val), 0, 1)
                    local max_percent = math.clamp((self.max_value - min_val) / (max_val - min_val), 0, 1)

                    if animate then
                        TweenService:Create(MinThumb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(min_percent, 0, 0.5, 0)}):Play()
                        TweenService:Create(MaxThumb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(max_percent, 0, 0.5, 0)}):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                            Size = UDim2.new(max_percent - min_percent, 0, 1, 0),
                            Position = UDim2.new(min_percent, 0, 0.5, 0)
                        }):Play()
                    else
                        MinThumb.Position = UDim2.new(min_percent, 0, 0.5, 0)
                        MaxThumb.Position = UDim2.new(max_percent, 0, 0.5, 0)
                        Fill.Size = UDim2.new(max_percent - min_percent, 0, 1, 0)
                        Fill.Position = UDim2.new(min_percent, 0, 0.5, 0)
                    end

                    if settings.round_number then
                        ValueDisplay.Text = string.format("%d - %d", math.floor(self.min_value), math.floor(self.max_value))
                    else
                        ValueDisplay.Text = string.format("%.1f - %.1f", self.min_value, self.max_value)
                    end

                    Library._config._flags[settings.flag .. "_min"] = self.min_value
                    Library._config._flags[settings.flag .. "_max"] = self.max_value
                    Config:save(game.GameId, Library._config)

                    if settings.callback then
                        settings.callback(self.min_value, self.max_value)
                    end
                end

                local active_thumb = nil

                Slider.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end

                    local mouse_pos = mouse.X - Drag.AbsolutePosition.X
                    local total_width = Drag.AbsoluteSize.X
                    local min_pixel = ((RangeSliderManager.min_value - min_val) / (max_val - min_val)) * total_width
                    local max_pixel = ((RangeSliderManager.max_value - min_val) / (max_val - min_val)) * total_width

                    if math.abs(mouse_pos - min_pixel) < math.abs(mouse_pos - max_pixel) then
                        active_thumb = "min"
                    else
                        active_thumb = "max"
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if not active_thumb then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

                    local mouse_pos = math.clamp(mouse.X - Drag.AbsolutePosition.X, 0, Drag.AbsoluteSize.X)
                    local percentage = mouse_pos / Drag.AbsoluteSize.X
                    local new_value = min_val + (max_val - min_val) * percentage

                    if active_thumb == "min" then
                        RangeSliderManager.min_value = math.clamp(new_value, min_val, RangeSliderManager.max_value)
                    else
                        RangeSliderManager.max_value = math.clamp(new_value, RangeSliderManager.min_value, max_val)
                    end
                    RangeSliderManager:update_positions(false)
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if active_thumb then
                            RangeSliderManager:update_positions(true)
                        end
                        active_thumb = nil
                    end
                end)

                if Library:flag_type(settings.flag .. "_min", "number") then
                    RangeSliderManager.min_value = Library._config._flags[settings.flag .. "_min"]
                    RangeSliderManager.max_value = Library._config._flags[settings.flag .. "_max"] or max_val
                end

                task.defer(function()
                    RangeSliderManager:update_positions(true)
                end)

                return RangeSliderManager
            end

            function ModuleManager:create_dropdown(settings: any)

                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1;
                end;

                local DropdownManager = {
                    _state = false,
                    _size = 0
                }

                if not settings.Order then
                    if self._size == 0 then
                        self._size = 11
                    end

                    self._size += 44
                end;

                if not settings.Order then
                    if ModuleManager._state then
                        Module.Size = UDim2.fromOffset(241, 93 + self._size)
                    end
                    Options.Size = UDim2.fromOffset(241, self._size)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 39)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Parent = Options

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule;
                else
                    Dropdown.LayoutOrder = settings.OrderValue;
                end;

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {};
                end;
                
                local TextLabel = Instance.new('TextLabel')
                if SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = CurrentTheme.TextPrimary
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Dropdown
                
                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.8999999761581421
                Box.Position = UDim2.new(0.5, 0, 1.2000000476837158, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = CurrentTheme.Accent
                Box.Parent = TextLabel
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Box
                
                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.BorderSizePixel = 0
                Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Header.Parent = Box
                
                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = CurrentTheme.TextPrimary
                CurrentOption.TextTransparency = 0.20000000298023224
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.04999988153576851, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
                CurrentOption.TextSize = 10
                CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.Parent = Header
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.704, 0),
                    NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                    NumberSequenceKeypoint.new(1, 1)
                }
                UIGradient.Parent = CurrentOption
                
                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.9100000262260437, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Arrow.Parent = Header
                
                local Options = Instance.new('ScrollingFrame')
                Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                Options.Active = true
                Options.ScrollBarImageTransparency = 1
                Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
                Options.ScrollBarThickness = 0
                Options.Name = 'Options'
                Options.Size = UDim2.new(0, 207, 0, 0)
                Options.BackgroundTransparency = 1
                Options.Position = UDim2.new(0, 0, 1, 0)
                Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Options.BorderSizePixel = 0
                Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                Options.Parent = Box
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Options
                
                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = Options
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Box

                function DropdownManager:update(option: string)
                    -- If multi-dropdown is enabled
                    if settings.multi_dropdown then
                        -- Split the CurrentOption.Text by commas into a table

                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {};
                        end;

                        local CurrentTargetValue = nil;
                        
                        if #Library._config._flags[settings.flag] > 0 then

                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag]);

                        end;

                        local selected = {}

                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do
                                -- Trim spaces around the option using string.match
                                local trimmedValue = value:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                                
                                -- Exclude any unwanted labels (e.g. "Label")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do
                                -- Trim spaces around the option using string.match
                                local trimmedValue = value:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                                
                                -- Exclude any unwanted labels (e.g. "Label")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        end;
                
                        local CurrentTextGet = convertStringToTable(CurrentOption.Text);

                        optionSkibidi = "nil";
                        if typeof(option) ~= 'string' then
                            optionSkibidi = option.Name;
                        else
                            optionSkibidi = option;
                        end;

                        local found = false
                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i);
                                break;
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}
                        -- Update the transparent effect of each option
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        CurrentTargetValue = convertStringToTable(CurrentOption.Text);

                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end;
                        end;

                        CurrentOption.Text = table.concat(selected, ", ");
                
                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text);
                    else
                        -- For single dropdown, just set the CurrentOption.Text to the selected option
                        CurrentOption.Text = (typeof(option) == "string" and option) or option.Name
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                -- Only update transparency for actual option text buttons
                                if object.Text == CurrentOption.Text then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end
                
                    -- Save the configuration state
                    Config:save(game.GameId, Library._config)
                
                    -- Callback with the updated option(s)
                    if settings.callback then
                        pcall(settings.callback, option)
                    end
                end
                
                local CurrentDropSizeState = 0;

                function DropdownManager:unfold_settings()
                    self._state = not self._state

                    if self._state then
                        ModuleManager._multiplier += self._size

                        CurrentDropSizeState = self._size;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39 + self._size)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22 + self._size)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180
                        }):Play()
                    else
                        ModuleManager._multiplier -= self._size

                        CurrentDropSizeState = 0;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0
                        }):Play()
                    end
                end

                if #settings.options > 0 then
                    DropdownManager._size = 3

                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6000000238418579
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = CurrentTheme.TextPrimary
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Parent = Options
                        
                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {};
                            end;

                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end

                            DropdownManager:update(value)
                        end)
    
                        if index > settings.maximum_options then
                            continue
                        end
    
                        DropdownManager._size += 16
                        Options.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                end

                function DropdownManager:New(value)
                    Dropdown:Destroy(true);
                    value.OrderValue = Dropdown.LayoutOrder
                    ModuleManager._multiplier -= CurrentDropSizeState
                    return ModuleManager:create_dropdown(value)
                end;

                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                else
                    DropdownManager:update(settings.options[1])
                end
    
                Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)

                return DropdownManager
            end

            function ModuleManager:create_feature(settings)

                local checked = false;
                
                LayoutOrderModule = LayoutOrderModule + 1
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size);
                end
            
                Options.Size = UDim2.fromOffset(241, self._size);
            
                local FeatureContainer = Instance.new("Frame")
                FeatureContainer.Size = UDim2.new(0, 207, 0, 16)
                FeatureContainer.BackgroundTransparency = 1
                FeatureContainer.Parent = Options
                FeatureContainer.LayoutOrder = LayoutOrderModule
            
                local UIListLayout = Instance.new("UIListLayout")
                UIListLayout.FillDirection = Enum.FillDirection.Horizontal
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = FeatureContainer
            
                local FeatureButton = Instance.new("TextButton")
                FeatureButton.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                FeatureButton.TextSize = 11;
                FeatureButton.Size = UDim2.new(1, -35, 0, 16)
                FeatureButton.BackgroundColor3 = CurrentTheme.Card
                FeatureButton.TextColor3 = CurrentTheme.TextPrimary
                FeatureButton.Text = "    " .. settings.title or "    " .. "Feature"
                FeatureButton.AutoButtonColor = false
                FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
                FeatureButton.TextTransparency = 0.2
                FeatureButton.Parent = FeatureContainer
            
                local RightContainer = Instance.new("Frame")
                RightContainer.Size = UDim2.new(0, 45, 0, 16)
                RightContainer.BackgroundTransparency = 1
                RightContainer.Parent = FeatureContainer
            
                local RightLayout = Instance.new("UIListLayout")
                RightLayout.Padding = UDim.new(0.1, 0)
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightContainer
            
                local KeybindBox = Instance.new("TextLabel")
                KeybindBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                KeybindBox.Size = UDim2.new(0, 15, 0, 15)
                KeybindBox.BackgroundColor3 = CurrentTheme.Accent
                KeybindBox.TextColor3 = CurrentTheme.TextPrimary
                KeybindBox.TextSize = 11
                KeybindBox.BackgroundTransparency = 1
                KeybindBox.LayoutOrder = 2;
                KeybindBox.Parent = RightContainer
            
                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(1, 0, 1, 0)
                KeybindButton.BackgroundTransparency = 1
                KeybindButton.TextTransparency = 1
                KeybindButton.Parent = KeybindBox

                local CheckboxCorner = Instance.new("UICorner", KeybindBox)
                CheckboxCorner.CornerRadius = UDim.new(0, 3)

                local UIStroke = Instance.new("UIStroke", KeybindBox)
                UIStroke.Color = CurrentTheme.Accent
                UIStroke.Thickness = 1
                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
                if not Library._config._flags then
                    Library._config._flags = {}
                end
            
                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {
                        checked = false,
                        BIND = settings.default or "Unknown"
                    }
                end
            
                checked = Library._config._flags[settings.flag].checked
                KeybindBox.Text = Library._config._flags[settings.flag].BIND

                if KeybindBox.Text == "Unknown" then
                    KeybindBox.Text = "...";
                end;

                local UseF_Var = nil;
            
                if not settings.disablecheck then
                    local Checkbox = Instance.new("TextButton")
                    Checkbox.Size = UDim2.new(0, 15, 0, 15)
                    Checkbox.BackgroundColor3 = checked and CurrentTheme.Accent or CurrentTheme.Card
                    Checkbox.Text = ""
                    Checkbox.Parent = RightContainer
                    Checkbox.LayoutOrder = 1;

                    local UIStroke = Instance.new("UIStroke", Checkbox)
                    UIStroke.Color = CurrentTheme.Accent
                    UIStroke.Thickness = 1
                    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                
                    local CheckboxCorner = Instance.new("UICorner")
                    CheckboxCorner.CornerRadius = UDim.new(0, 3)
                    CheckboxCorner.Parent = Checkbox
            
                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and CurrentTheme.Accent or CurrentTheme.Card
                        Library._config._flags[settings.flag].checked = checked
                        Config:save(game.GameId, Library._config)
                        if settings.callback then
                            settings.callback(checked)
                        end
                    end

                    UseF_Var = toggleState
                
                    Checkbox.MouseButton1Click:Connect(toggleState)

                else

                    UseF_Var = function()
                        settings.button_callback();
                    end;

                end;
            
                KeybindButton.MouseButton1Click:Connect(function()
                    KeybindBox.Text = "..."
                    local inputConnection
                    inputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode.Name
                            Library._config._flags[settings.flag].BIND = newKey
                            if newKey ~= "Unknown" then
                                KeybindBox.Text = newKey;
                            end;
                            Config:save(game.GameId, Library._config) -- Save new keybind
                            inputConnection:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                            Library._config._flags[settings.flag].BIND = "Unknown"
                            KeybindBox.Text = "..."
                            Config:save(game.GameId, Library._config)
                            inputConnection:Disconnect()
                        end
                    end)
                    Connections["keybind_input_" .. settings.flag] = inputConnection
                end)
            
                local keyPressConnection
                keyPressConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == Library._config._flags[settings.flag].BIND then
                            UseF_Var();
                        end
                    end
                end)
                Connections["keybind_press_" .. settings.flag] = keyPressConnection
            
                FeatureButton.MouseButton1Click:Connect(function()
                    if settings.button_callback then
                        settings.button_callback()
                    end
                end)

                if not settings.disablecheck then
                    settings.callback(checked);
                end;
            
                return FeatureContainer
            end

            -- ===================== Button =====================
            function ModuleManager:create_button(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then self._size = 11 end
                self._size += 28

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(0, 207, 0, 26)
                Button.BackgroundColor3 = CurrentTheme.Accent
                Button.BackgroundTransparency = 0.15
                Button.AutoButtonColor = false
                Button.Font = Enum.Font.GothamBold
                Button.TextSize = 12
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.Text = settings.title or "Button"
                Button.BorderSizePixel = 0
                Button.LayoutOrder = LayoutOrderModule
                Button.Parent = Options

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = Button

                local stroke = Instance.new("UIStroke")
                stroke.Color = CurrentTheme.Accent
                stroke.Transparency = 0.4
                stroke.Parent = Button

                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.2), {
                        BackgroundTransparency = 0
                    }):Play()
                end)
                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.2), {
                        BackgroundTransparency = 0.15
                    }):Play()
                end)

                Button.MouseButton1Click:Connect(function()
                    if settings.callback then
                        settings.callback()
                    end
                end)

                return Button
            end

            -- ===================== Color Picker =====================
            -- A swatch row that opens a popup: saturation/value square, hue bar,
            -- hex box with copy button, preset colors and Cancel / Confirm.
            -- settings: { title, flag, default = Color3, callback = function(color) end, notify = true }
            function ModuleManager:create_colorpicker(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then self._size = 11 end
                self._size += 26

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                -- Start from the saved color (stored as {R,G,B}), otherwise the default
                local current = settings.default or Color3.fromRGB(99, 102, 241)
                if Library:flag_type(settings.flag, "table") then
                    local saved = Library._config._flags[settings.flag]
                    if saved and saved.R then
                        current = Color3.new(saved.R, saved.G, saved.B)
                    end
                end

                local row = mk("Frame", {
                    Name = "ColorPickerRow",
                    Size = UDim2.new(0, 207, 0, 22),
                    BackgroundTransparency = 1,
                    LayoutOrder = LayoutOrderModule,
                }, Options)

                local title = mk("TextLabel", {
                    Name = "ColorTitle",
                    Size = UDim2.new(1, -44, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    TextColor3 = CurrentTheme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = settings.title or "Color",
                }, row)

                local swatch = mk("TextButton", {
                    Name = "Swatch",
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(36, 18),
                    BackgroundColor3 = current,
                    BorderSizePixel = 0,
                }, row)
                mk("UICorner", { CornerRadius = UDim.new(0, 5) }, swatch)
                local swatchStroke = mk("UIStroke", {
                    Color = CurrentTheme.Stroke,
                    Transparency = 0.3,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }, swatch)

                -- Apply a color: update the swatch, save it and fire the callback
                local function commit(color)
                    current = color
                    swatch.BackgroundColor3 = color
                    Library._config._flags[settings.flag] = { R = color.R, G = color.G, B = color.B }
                    Config:save(game.GameId, Library._config)
                    if settings.callback then
                        settings.callback(color)
                    end
                end

                -- Keep the row in sync with theme changes (called by Library_SetTheme)
                table.insert(Library._color_popups, function()
                    title.TextColor3 = CurrentTheme.TextPrimary
                    swatchStroke.Color = CurrentTheme.Stroke
                end)

                local function open_popup()
                    -- Only one popup can be open at a time
                    if Library._close_picker then
                        Library._close_picker()
                    end

                    local T = CurrentTheme
                    local h, sat, val = current:ToHSV()
                    local working = current
                    local dragMode = nil
                    local moveKey = "picker_move_" .. tostring(settings.flag)
                    local endKey = "picker_end_" .. tostring(settings.flag)
                    local viewport = workspace.CurrentCamera.ViewportSize
                    local accentB = T.Accent:Lerp(Color3.fromRGB(139, 92, 246), 0.55)

                    local Popup = mk("Frame", {
                        Name = "ColorPickerPopup",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.fromOffset(300, 288),
                        BackgroundColor3 = T.ModuleBackground,
                        BorderSizePixel = 0,
                        Active = true,
                        ZIndex = 50,
                    }, Library._ui or CoreGui)
                    mk("UICorner", { CornerRadius = UDim.new(0, 14) }, Popup)
                    mk("UIStroke", { Color = T.Stroke, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Popup)
                    -- Shrink on small screens
                    mk("UIScale", { Scale = math.clamp((viewport.X - 24) / 320, 0.55, 1) }, Popup)

                    -- Header: palette icon + title + close button
                    mk("TextLabel", {
                        Name = "PickerIcon",
                        Text = "\240\159\142\168",
                        TextSize = 16,
                        Position = UDim2.fromOffset(15, 12),
                        Size = UDim2.fromOffset(22, 24),
                        BackgroundTransparency = 1,
                    }, Popup)
                    mk("TextLabel", {
                        Name = "PickerTitle",
                        Font = Enum.Font.GothamBold,
                        TextSize = 15,
                        TextColor3 = T.TextPrimary,
                        Text = "Color Picker",
                        Position = UDim2.fromOffset(42, 12),
                        Size = UDim2.fromOffset(200, 24),
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, Popup)

                    local CloseButton = mk("TextButton", {
                        Text = "X",
                        Font = Enum.Font.GothamBold,
                        TextSize = 12,
                        TextColor3 = T.TextSecondary,
                        AutoButtonColor = false,
                        BackgroundColor3 = T.Card,
                        Position = UDim2.fromOffset(262, 8),
                        Size = UDim2.fromOffset(26, 26),
                        BorderSizePixel = 0,
                    }, Popup)
                    mk("UICorner", { CornerRadius = UDim.new(0, 6) }, CloseButton)

                    -- Saturation / value square
                    local SV = mk("Frame", {
                        Name = "SV",
                        Position = UDim2.fromOffset(15, 44),
                        Size = UDim2.fromOffset(270, 124),
                        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                        BorderSizePixel = 0,
                        Active = true,
                    }, Popup)
                    mk("UICorner", { CornerRadius = UDim.new(0, 10) }, SV)

                    -- White fades out to the right
                    local WhiteLayer = mk("Frame", {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                    }, SV)
                    mk("UICorner", { CornerRadius = UDim.new(0, 10) }, WhiteLayer)
                    mk("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                    }, WhiteLayer)

                    -- Black fades in towards the bottom
                    local BlackLayer = mk("Frame", {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundColor3 = Color3.new(0, 0, 0),
                        BorderSizePixel = 0,
                    }, SV)
                    mk("UICorner", { CornerRadius = UDim.new(0, 10) }, BlackLayer)
                    mk("UIGradient", {
                        Rotation = 90,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(1, 0),
                        }),
                    }, BlackLayer)

                    local SVKnob = mk("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.fromOffset(14, 14),
                        BackgroundColor3 = working,
                        BorderSizePixel = 0,
                        ZIndex = 3,
                    }, SV)
                    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, SVKnob)
                    mk("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, SVKnob)

                    -- Hue bar
                    local Hue = mk("Frame", {
                        Name = "Hue",
                        Position = UDim2.fromOffset(15, 182),
                        Size = UDim2.fromOffset(270, 16),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Active = true,
                    }, Popup)
                    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, Hue)
                    mk("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                        }),
                    }, Hue)

                    local HueKnob = mk("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.fromOffset(10, 26),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        ZIndex = 3,
                    }, Hue)
                    mk("UICorner", { CornerRadius = UDim.new(0, 4) }, HueKnob)
                    mk("UIStroke", { Color = T.Stroke, Thickness = 1 }, HueKnob)

                    -- Hex box + copy button
                    local HexBox = mk("TextBox", {
                        Name = "HexBox",
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextColor3 = T.TextPrimary,
                        PlaceholderText = "#RRGGBB",
                        PlaceholderColor3 = T.TextSecondary,
                        Text = "",
                        ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundColor3 = T.Card,
                        Position = UDim2.fromOffset(15, 212),
                        Size = UDim2.fromOffset(122, 28),
                        BorderSizePixel = 0,
                    }, Popup)
                    mk("UICorner", { CornerRadius = UDim.new(0, 6) }, HexBox)
                    mk("UIPadding", { PaddingLeft = UDim.new(0, 8) }, HexBox)

                    local CopyButton = mk("TextButton", {
                        Text = "",
                        AutoButtonColor = false,
                        BackgroundColor3 = T.Card,
                        Position = UDim2.fromOffset(141, 212),
                        Size = UDim2.fromOffset(30, 28),
                        BorderSizePixel = 0,
                    }, Popup)
                    mk("UICorner", { CornerRadius = UDim.new(0, 6) }, CopyButton)

                    -- Copy icon: two overlapping squares
                    local CopyBack = mk("Frame", {
                        Position = UDim2.fromOffset(10, 6),
                        Size = UDim2.fromOffset(10, 10),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                    }, CopyButton)
                    mk("UICorner", { CornerRadius = UDim.new(0, 2) }, CopyBack)
                    mk("UIStroke", { Color = T.TextSecondary, Thickness = 1.2 }, CopyBack)
                    local CopyFront = mk("Frame", {
                        Position = UDim2.fromOffset(7, 10),
                        Size = UDim2.fromOffset(10, 10),
                        BackgroundColor3 = T.Card,
                        BorderSizePixel = 0,
                    }, CopyButton)
                    mk("UICorner", { CornerRadius = UDim.new(0, 2) }, CopyFront)
                    mk("UIStroke", { Color = T.TextSecondary, Thickness = 1.2 }, CopyFront)

                    mk("Frame", {
                        Position = UDim2.fromOffset(180, 215),
                        Size = UDim2.fromOffset(1, 22),
                        BackgroundColor3 = T.Stroke,
                        BorderSizePixel = 0,
                    }, Popup)

                    -- Cancel / Confirm
                    local Cancel = mk("TextButton", {
                        Text = "Cancel",
                        Font = Enum.Font.GothamSemibold,
                        TextSize = 12,
                        TextColor3 = T.TextPrimary,
                        AutoButtonColor = false,
                        BackgroundColor3 = T.Card,
                        Position = UDim2.fromOffset(100, 251),
                        Size = UDim2.fromOffset(86, 26),
                        BorderSizePixel = 0,
                    }, Popup)
                    mk("UICorner", { CornerRadius = UDim.new(0, 6) }, Cancel)

                    local Confirm = mk("TextButton", {
                        Text = "Confirm",
                        Font = Enum.Font.GothamBold,
                        TextSize = 12,
                        TextColor3 = contrastText(T.Accent),
                        AutoButtonColor = false,
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        Position = UDim2.fromOffset(196, 251),
                        Size = UDim2.fromOffset(86, 26),
                        BorderSizePixel = 0,
                    }, Popup)
                    mk("UICorner", { CornerRadius = UDim.new(0, 6) }, Confirm)
                    mk("UIGradient", { Color = ColorSequence.new(T.Accent, accentB) }, Confirm)

                    ---------------------------------------------------
                    -- Logic
                    ---------------------------------------------------
                    -- Redraw knobs, hue tint and hex text. `exact` keeps an exact color (typed hex / presets)
                    local function refresh(exact)
                        working = exact or Color3.fromHSV(h, sat, val)
                        SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        SVKnob.Position = UDim2.fromScale(sat, 1 - val)
                        SVKnob.BackgroundColor3 = working
                        HueKnob.Position = UDim2.new(h, 0, 0.5, 0)
                        HexBox.Text = "#" .. string.upper(working:ToHex())
                    end

                    local function setColor(color)
                        h, sat, val = color:ToHSV()
                        refresh(color)
                    end

                    local function close()
                        Connections:disconnect(moveKey)
                        Connections:disconnect(endKey)
                        if Library._close_picker == close then
                            Library._close_picker = nil
                        end
                        Popup:Destroy()
                    end
                    Library._close_picker = close

                    -- Preset colors
                    local presets = { "6366F1", "EC4899", "EF4444", "A8A3C7", "D1D5DB" }
                    for index, hex in ipairs(presets) do
                        local presetColor = Color3.fromHex(hex)
                        local Dot = mk("TextButton", {
                            Text = "",
                            AutoButtonColor = false,
                            Position = UDim2.fromOffset(194 + (index - 1) * 19, 218),
                            Size = UDim2.fromOffset(14, 14),
                            BackgroundColor3 = presetColor,
                            BorderSizePixel = 0,
                        }, Popup)
                        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, Dot)
                        mk("UIStroke", { Color = T.Stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Dot)
                        Dot.MouseButton1Click:Connect(function()
                            setColor(presetColor)
                        end)
                    end

                    -- Dragging the square / hue bar (mouse and touch)
                    local function updateDrag(position)
                        if dragMode == "sv" then
                            sat = math.clamp((position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
                            val = 1 - math.clamp((position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
                            refresh()
                        elseif dragMode == "hue" then
                            h = math.clamp((position.X - Hue.AbsolutePosition.X) / Hue.AbsoluteSize.X, 0, 1)
                            refresh()
                        end
                    end

                    local function isPress(input)
                        return input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch
                    end

                    SV.InputBegan:Connect(function(input)
                        if isPress(input) then
                            dragMode = "sv"
                            updateDrag(input.Position)
                        end
                    end)

                    Hue.InputBegan:Connect(function(input)
                        if isPress(input) then
                            dragMode = "hue"
                            updateDrag(input.Position)
                        end
                    end)

                    Connections[moveKey] = UserInputService.InputChanged:Connect(function(input)
                        if not dragMode then return end
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            updateDrag(input.Position)
                        end
                    end)

                    Connections[endKey] = UserInputService.InputEnded:Connect(function(input)
                        if isPress(input) then
                            dragMode = nil
                        end
                    end)

                    -- Typed hex value
                    HexBox.FocusLost:Connect(function()
                        local text = (string.gsub(HexBox.Text, "[#%s]", ""))
                        local ok, parsed = pcall(Color3.fromHex, "#" .. text)
                        if ok and parsed then
                            setColor(parsed)
                        else
                            refresh(working) -- invalid input, restore the previous text
                        end
                    end)

                    CopyButton.MouseButton1Click:Connect(function()
                        local hexText = "#" .. string.upper(working:ToHex())
                        if setclipboard then
                            pcall(setclipboard, hexText)
                            Library.Notify.Info("Copied", hexText, 2)
                        else
                            Library.Notify.Warn("Copy not supported", "Your executor has no setclipboard", 3)
                        end
                    end)

                    CloseButton.MouseButton1Click:Connect(close)
                    Cancel.MouseButton1Click:Connect(close)

                    Confirm.MouseButton1Click:Connect(function()
                        commit(working)
                        if settings.notify ~= false then
                            Library.Notify.Success("Color updated!", nil, 2)
                        end
                        close()
                    end)

                    refresh(current)
                end

                swatch.MouseButton1Click:Connect(open_popup)

                title.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        open_popup()
                    end
                end)

                return {
                    Set = function(_, color)
                        commit(color)
                    end,
                    Get = function()
                        return current
                    end
                }
            end

            -- ===================== Section / Group =====================
            function ModuleManager:create_section(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 22

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local section = Instance.new("Frame")
                section.Size = UDim2.new(0, 207, 0, 18)
                section.BackgroundTransparency = 1
                section.LayoutOrder = LayoutOrderModule
                section.Parent = Options

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamBold
                label.TextSize = 11
                label.TextColor3 = CurrentTheme.Accent
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Text = settings.title or "Section"
                label.Parent = section

                local line = Instance.new("Frame")
                line.Size = UDim2.new(1, 0, 0, 1)
                line.Position = UDim2.new(0, 0, 1, 0)
                line.BackgroundColor3 = CurrentTheme.Stroke
                line.BackgroundTransparency = 0.4
                line.BorderSizePixel = 0
                line.Parent = section

                return section
            end

            -- ===================== Player List =====================
            function ModuleManager:create_playerlist(settings: any)
                local players = {}
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        table.insert(players, plr.Name)
                    end
                end
                if #players == 0 then
                    players = {"(no players)"}
                end

                local dd = ModuleManager:create_dropdown({
                    title = settings.title or "Player",
                    flag = settings.flag or "playerlist",
                    options = players,
                    multi_dropdown = settings.multi_dropdown or false,
                    maximum_options = settings.maximum_options or 8,
                    callback = settings.callback or function() end
                })

                -- refresh khi có người vào/ra
                Players.PlayerAdded:Connect(function()
                    -- dropdown không rebuild dễ, chỉ notify
                end)

                return dd
            end

            -- ===================== Tooltip helper =====================
            function ModuleManager:create_tooltip(guiObject, text)
                local tip = Instance.new("TextLabel")
                tip.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
                tip.BackgroundTransparency = 0.05
                tip.TextColor3 = Color3.fromRGB(230, 230, 240)
                tip.Font = Enum.Font.Gotham
                tip.TextSize = 11
                tip.Text = text or ""
                tip.Visible = false
                tip.ZIndex = 300
                tip.Size = UDim2.new(0, 0, 0, 22)
                tip.AutomaticSize = Enum.AutomaticSize.X
                tip.Parent = Library._ui or CoreGui

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 5)
                corner.Parent = tip

                local pad = Instance.new("UIPadding")
                pad.PaddingLeft = UDim.new(0, 8)
                pad.PaddingRight = UDim.new(0, 8)
                pad.Parent = tip

                local stroke = Instance.new("UIStroke")
                stroke.Color = CurrentTheme.Stroke
                stroke.Transparency = 0.4
                stroke.Parent = tip

                guiObject.MouseEnter:Connect(function()
                    tip.Visible = true
                end)
                guiObject.MouseLeave:Connect(function()
                    tip.Visible = false
                end)
                RunService.RenderStepped:Connect(function()
                    if tip.Visible then
                        tip.Position = UDim2.fromOffset(mouse.X + 14, mouse.Y + 12)
                    end
                end)

                return tip
            end

            return ModuleManager
        end

        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
        local toggleKey = GG.ToggleKey or Enum.KeyCode.Insert
        if typeof(toggleKey) == "string" then
            toggleKey = Enum.KeyCode[toggleKey] or Enum.KeyCode.Insert
        end
        if input.KeyCode ~= toggleKey then
            return
        end

        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    return self
end

return Library
