
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("SoraDynamicIsland")
if oldGui then
    oldGui:Destroy()
end

local CONFIG = {
    Width = 290,
    Height = 76,

    CompactWidth = 92,
    CompactHeight = 27,

    ActionHeight = 112,
    Top = 9,

    Background = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0,

    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(165, 165, 175),

    Accent = Color3.fromRGB(225, 45, 65),

    ButtonColor = Color3.fromRGB(30, 30, 33),
    ButtonHoverColor = Color3.fromRGB(48, 48, 52),
    ButtonTextColor = Color3.fromRGB(255, 255, 255),

    StrokeColor = Color3.fromRGB(45, 45, 48),
    StrokeTransparency = 0.15,

    ButtonPressScale = 0.94,
    ButtonShakeStrength = 2,

    SoundEnabled = false,
    SoundId = "rbxassetid://0",

    HapticEnabled = true,
    HapticSoundId = "rbxassetid://0",
    HapticVolume = 0.35,
    HapticStrength = 2,

    Duration = 4,
    IdleDelay = 8,

    ExpandTime = 0.4,
    CollapseTime = 0.3,

    FadeTime = 0.6,
    FadeTransparency = 0.18,
    FadeStrokeTransparency = 0.55,
    FadeDotTransparency = 0.4,
}

local TYPES = {
    Success = {
        Accent = Color3.fromRGB(55, 210, 125),
        Icon = "rbxassetid://6031094678",
    },

    Error = {
        Accent = Color3.fromRGB(245, 75, 75),
        Icon = "rbxassetid://6031094679",
    },

    Warning = {
        Accent = Color3.fromRGB(255, 185, 65),
        Icon = "rbxassetid://6031071053",
    },

    Info = {
        Accent = Color3.fromRGB(80, 160, 255),
        Icon = "rbxassetid://6031075938",
    },
}

local queue = {}
local currentNotification = nil

local isPlaying = false
local isExpanded = false
local isFinalizing = false
local isDestroyed = false

local notificationId = 0
local transitionId = 0
local idleId = 0
local hapticId = 0

local islandTweens = {}
local appearanceTweens = {}
local hapticTweens = {}

local Notify = {}

local function createTween(object, duration, properties, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()
    return tween
end

local function createCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object

    return corner
end

local function createLabel(parent, name, position, size, fontSize, font, color)
    local label = Instance.new("TextLabel")

    label.Name = name
    label.Position = position
    label.Size = size

    label.BackgroundTransparency = 1

    label.Font = font
    label.TextSize = fontSize
    label.TextColor3 = color

    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center

    label.TextTruncate = Enum.TextTruncate.AtEnd

    label.ZIndex = 3
    label.Parent = parent

    return label
end

local function cancelIslandTweens()
    for _, tween in ipairs(islandTweens) do
        tween:Cancel()
    end

    table.clear(islandTweens)
end

local function cancelAppearanceTweens()
    for _, tween in ipairs(appearanceTweens) do
        tween:Cancel()
    end

    table.clear(appearanceTweens)
end

local function playIslandTween(object, duration, properties, style, direction)
    local tween = createTween(
        object,
        duration,
        properties,
        style,
        direction
    )

    table.insert(islandTweens, tween)
    return tween
end

local function playAppearanceTween(object, duration, properties)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        properties
    )

    table.insert(appearanceTweens, tween)
    tween:Play()

    return tween
end

local function safeCallback(callback)
    if typeof(callback) ~= "function" then
        return
    end

    task.spawn(function()
        local success, err = pcall(callback)

        if not success then
            warn("[Sora x Hikaru] Action callback:", err)
        end
    end)
end

local function getNotificationType(options)
    return TYPES[options.Type or "Info"] or TYPES.Info
end

local function getTargetHeight(options)
    if options
        and typeof(options.Buttons) == "table"
        and #options.Buttons > 0 then

        return CONFIG.ActionHeight
    end

    return CONFIG.Height
end

local function getNotificationAccent(options)
    local notificationType = getNotificationType(options)

    return options.Accent or notificationType.Accent
end

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "SoraDynamicIsland"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ScreenGui.Parent = PlayerGui

local Island = Instance.new("Frame")

Island.Name = "Island"

Island.AnchorPoint = Vector2.new(0.5, 0)
Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)

Island.Size = UDim2.fromOffset(
    CONFIG.CompactWidth,
    CONFIG.CompactHeight
)

Island.BackgroundColor3 = CONFIG.Background
Island.BackgroundTransparency = CONFIG.BackgroundTransparency

Island.BorderSizePixel = 0
Island.ClipsDescendants = true

Island.ZIndex = 1
Island.Parent = ScreenGui

createCorner(Island, 30)

local IslandStroke = Instance.new("UIStroke")

IslandStroke.Color = CONFIG.StrokeColor
IslandStroke.Transparency = CONFIG.StrokeTransparency
IslandStroke.Thickness = 1

IslandStroke.Parent = Island

local CompactDot = Instance.new("Frame")

CompactDot.Name = "CompactDot"

CompactDot.AnchorPoint = Vector2.new(0.5, 0.5)
CompactDot.Position = UDim2.fromScale(0.5, 0.5)

CompactDot.Size = UDim2.fromOffset(7, 7)

CompactDot.BackgroundColor3 = CONFIG.Accent
CompactDot.BorderSizePixel = 0

CompactDot.ZIndex = 3
CompactDot.Parent = Island

createCorner(CompactDot, 10)

local IconBackground = Instance.new("Frame")

IconBackground.Name = "IconBackground"

IconBackground.Position = UDim2.fromOffset(12, 19)
IconBackground.Size = UDim2.fromOffset(37, 37)

IconBackground.BackgroundColor3 = CONFIG.Accent
IconBackground.BackgroundTransparency = 0

IconBackground.BorderSizePixel = 0
IconBackground.Visible = false

IconBackground.ZIndex = 3
IconBackground.Parent = Island

createCorner(IconBackground, 11)

local Icon = Instance.new("ImageLabel")

Icon.Name = "Icon"

Icon.AnchorPoint = Vector2.new(0.5, 0.5)
Icon.Position = UDim2.fromScale(0.5, 0.5)

Icon.Size = UDim2.fromOffset(23, 23)

Icon.BackgroundTransparency = 1
Icon.Image = "rbxassetid://76051962811019"

Icon.ZIndex = 4
Icon.Parent = IconBackground

local Title = createLabel(
    Island,
    "Title",
    UDim2.fromOffset(59, 17),
    UDim2.new(1, -112, 0, 18),
    12,
    Enum.Font.GothamSemibold,
    CONFIG.Text
)

Title.Text = "Sora x Hikaru"
Title.Visible = false

local Content = createLabel(
    Island,
    "Content",
    UDim2.fromOffset(59, 39),
    UDim2.new(1, -76, 0, 18),
    10,
    Enum.Font.Gotham,
    CONFIG.SubText
)

Content.Text = "Dynamic Island ready."
Content.Visible = false

local TimeLabel = createLabel(
    Island,
    "Time",
    UDim2.new(1, -45, 0, 18),
    UDim2.fromOffset(35, 15),
    9,
    Enum.Font.Gotham,
    CONFIG.SubText
)

TimeLabel.Text = "now"
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLabel.Visible = false

local CloseButton = Instance.new("TextButton")

CloseButton.Name = "CloseButton"

CloseButton.AnchorPoint = Vector2.new(1, 0)
CloseButton.Position = UDim2.new(1, -10, 0, 45)

CloseButton.Size = UDim2.fromOffset(20, 20)

CloseButton.BackgroundColor3 = CONFIG.ButtonColor
CloseButton.BackgroundTransparency = 0

CloseButton.Text = "×"
CloseButton.TextColor3 = CONFIG.Text

CloseButton.Font = Enum.Font.GothamMedium
CloseButton.TextSize = 16

CloseButton.AutoButtonColor = false
CloseButton.Visible = false

CloseButton.ZIndex = 6
CloseButton.Parent = Island

createCorner(CloseButton, 10)

local ButtonContainer = Instance.new("Frame")

ButtonContainer.Name = "ActionButtons"

ButtonContainer.Position = UDim2.fromOffset(12, 75)
ButtonContainer.Size = UDim2.new(1, -24, 0, 29)

ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Visible = false

ButtonContainer.ZIndex = 5
ButtonContainer.Parent = Island

local ButtonLayout = Instance.new("UIListLayout")

ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center

ButtonLayout.Padding = UDim.new(0, 8)
ButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder

ButtonLayout.Parent = ButtonContainer

local ProgressBackground = Instance.new("Frame")

ProgressBackground.Name = "ProgressBackground"

ProgressBackground.Position = UDim2.new(0, 12, 1, -5)
ProgressBackground.Size = UDim2.new(1, -24, 0, 2)

ProgressBackground.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
ProgressBackground.BackgroundTransparency = 0

ProgressBackground.BorderSizePixel = 0
ProgressBackground.Visible = false

ProgressBackground.ZIndex = 4
ProgressBackground.Parent = Island

createCorner(ProgressBackground, 5)

local Progress = Instance.new("Frame")

Progress.Name = "Progress"

Progress.Size = UDim2.fromScale(1, 1)

Progress.BackgroundColor3 = CONFIG.Accent
Progress.BorderSizePixel = 0

Progress.ZIndex = 5
Progress.Parent = ProgressBackground

createCorner(Progress, 5)

local ClickArea = Instance.new("TextButton")

ClickArea.Name = "ClickArea"

ClickArea.Size = UDim2.fromScale(1, 1)

ClickArea.BackgroundTransparency = 1
ClickArea.Text = ""

ClickArea.AutoButtonColor = false
ClickArea.ZIndex = 2

ClickArea.Parent = Island

local NotificationSound = Instance.new("Sound")

NotificationSound.Name = "NotificationSound"
NotificationSound.SoundId = CONFIG.SoundId
NotificationSound.Volume = 0.5

NotificationSound.Parent = SoundService

local HapticSound = Instance.new("Sound")

HapticSound.Name = "HapticSound"
HapticSound.SoundId = CONFIG.HapticSoundId
HapticSound.Volume = CONFIG.HapticVolume

HapticSound.Parent = SoundService

local function cancelHapticTweens()
    hapticId += 1

    for _, tween in ipairs(hapticTweens) do
        tween:Cancel()
    end

    table.clear(hapticTweens)

    if not isDestroyed then
        Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)
    end
end

local function playHaptic()
    if isDestroyed or not CONFIG.HapticEnabled then
        return
    end

    hapticId += 1

    local thisId = hapticId
    local strength = math.clamp(CONFIG.HapticStrength, 1, 4)

    for _, tween in ipairs(hapticTweens) do
        tween:Cancel()
    end

    table.clear(hapticTweens)

    if HapticSound.SoundId ~= "rbxassetid://0" then
        HapticSound:Play()
    end

    local offsets = {
        strength,
        -strength,
        strength * 0.65,
        -strength * 0.65,
        0,
    }

    task.spawn(function()
        for _, offset in ipairs(offsets) do
            if isDestroyed or thisId ~= hapticId then
                return
            end

            local tween = TweenService:Create(
                Island,
                TweenInfo.new(
                    0.035,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.Out
                ),
                {
                    Position = UDim2.new(
                        0.5,
                        offset,
                        0,
                        CONFIG.Top
                    ),
                }
            )

            table.insert(hapticTweens, tween)

            tween:Play()
            tween.Completed:Wait()
        end

        if thisId == hapticId and not isDestroyed then
            Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)
            table.clear(hapticTweens)
        end
    end)
end

local function playButtonPress(button)
    if not button or not button.Parent then
        return
    end

    playHaptic()

    local scale = button:FindFirstChildOfClass("UIScale")

    if not scale then
        scale = Instance.new("UIScale")
        scale.Scale = 1
        scale.Parent = button
    end

    local originalColor = button.BackgroundColor3
    local originalRotation = button.Rotation

    createTween(
        button,
        0.08,
        {
            BackgroundColor3 = CONFIG.ButtonHoverColor,
        },
        Enum.EasingStyle.Quad
    )

    local pressTween = TweenService:Create(
        scale,
        TweenInfo.new(
            0.08,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Scale = CONFIG.ButtonPressScale,
        }
    )

    pressTween:Play()

    task.spawn(function()
        pressTween.Completed:Wait()

        if not button.Parent then
            return
        end

        local rotations = {
            CONFIG.ButtonShakeStrength,
            -CONFIG.ButtonShakeStrength,
            CONFIG.ButtonShakeStrength * 0.6,
            -CONFIG.ButtonShakeStrength * 0.6,
            0,
        }

        for _, rotation in ipairs(rotations) do
            if not button.Parent then
                return
            end

            local tween = TweenService:Create(
                button,
                TweenInfo.new(
                    0.035,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.Out
                ),
                {
                    Rotation = originalRotation + rotation,
                }
            )

            tween:Play()
            tween.Completed:Wait()
        end

        if not button.Parent then
            return
        end

        createTween(
            scale,
            0.16,
            {
                Scale = 1,
            },
            Enum.EasingStyle.Back
        )

        createTween(
            button,
            0.12,
            {
                Rotation = originalRotation,
                BackgroundColor3 = originalColor,
            },
            Enum.EasingStyle.Quad
        )
    end)
end

local function restoreIsland()
    idleId += 1
    cancelAppearanceTweens()

    if isDestroyed then
        return
    end

    playAppearanceTween(Island, 0.25, {
        BackgroundTransparency = CONFIG.BackgroundTransparency,
    })

    playAppearanceTween(IslandStroke, 0.25, {
        Transparency = CONFIG.StrokeTransparency,
    })

    playAppearanceTween(CompactDot, 0.25, {
        BackgroundTransparency = 0,
    })
end

local function scheduleIdleFade()
    idleId += 1

    local thisId = idleId

    task.delay(CONFIG.IdleDelay, function()
        if isDestroyed
            or thisId ~= idleId
            or currentNotification
            or isPlaying
            or isExpanded then

            return
        end

        cancelAppearanceTweens()

        playAppearanceTween(Island, CONFIG.FadeTime, {
            BackgroundTransparency = CONFIG.FadeTransparency,
        })

        playAppearanceTween(IslandStroke, CONFIG.FadeTime, {
            Transparency = CONFIG.FadeStrokeTransparency,
        })

        playAppearanceTween(CompactDot, CONFIG.FadeTime, {
            BackgroundTransparency = CONFIG.FadeDotTransparency,
        })
    end)
end

local function clearActionButtons()
    for _, child in ipairs(ButtonContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function hideNotificationContent()
    IconBackground.Visible = false
    Title.Visible = false
    Content.Visible = false
    TimeLabel.Visible = false

    CloseButton.Visible = false
    ButtonContainer.Visible = false
    ProgressBackground.Visible = false

    Icon.Image = ""
    Icon.ImageTransparency = 0

    Title.Text = ""
    Content.Text = ""
    TimeLabel.Text = ""

    Title.TextTransparency = 0
    Content.TextTransparency = 0
    TimeLabel.TextTransparency = 0

    IconBackground.BackgroundTransparency = 0

    Progress.Size = UDim2.fromScale(1, 1)
    Progress.BackgroundTransparency = 0

    ProgressBackground.BackgroundTransparency = 0

    CompactDot.Visible = true
    CompactDot.BackgroundTransparency = 0

    clearActionButtons()
end

local function createActionButtons(buttons)
    clearActionButtons()

    if typeof(buttons) ~= "table" then
        ButtonContainer.Visible = false
        return
    end

    for index, buttonData in ipairs(buttons) do
        if typeof(buttonData) ~= "table" then
            continue
        end

        local actionButton = Instance.new("TextButton")

        actionButton.Name = "Action_" .. index
        actionButton.Size = UDim2.fromOffset(82, 29)

        actionButton.BackgroundColor3 = buttonData.Color or CONFIG.ButtonColor
        actionButton.BackgroundTransparency = 0

        actionButton.BorderSizePixel = 0

        actionButton.Text = buttonData.Text or "Action"
        actionButton.TextColor3 = CONFIG.ButtonTextColor

        actionButton.Font = Enum.Font.GothamSemibold
        actionButton.TextSize = 10

        actionButton.AutoButtonColor = false
        actionButton.LayoutOrder = index

        actionButton.ZIndex = 6
        actionButton.Parent = ButtonContainer

        createCorner(actionButton, 10)

        local stroke = Instance.new("UIStroke")

        stroke.Color = CONFIG.StrokeColor
        stroke.Transparency = 0.2
        stroke.Thickness = 1

        stroke.Parent = actionButton

        local buttonScale = Instance.new("UIScale")
        buttonScale.Scale = 1
        buttonScale.Parent = actionButton

        actionButton.Activated:Connect(function()
            if isDestroyed or isFinalizing then
                return
            end

            playButtonPress(actionButton)
            safeCallback(buttonData.Callback)

            if buttonData.CloseOnClick ~= false
                and currentNotification then

                currentNotification.dismissed = true
            end
        end)
    end

    ButtonContainer.Visible = #buttons > 0
end

local function renderNotification(options)
    local notificationType = getNotificationType(options)
    local accent = getNotificationAccent(options)

    cancelAppearanceTweens()

    CompactDot.BackgroundColor3 = accent

    IconBackground.BackgroundColor3 = accent
    Progress.BackgroundColor3 = accent

    Title.Text = options.Title or "Sora x Hikaru"
    Content.Text = options.Content or "Notification"
    TimeLabel.Text = options.Time or "now"

    Icon.Image = options.Icon or notificationType.Icon

    Title.TextColor3 = CONFIG.Text
    Content.TextColor3 = CONFIG.SubText
    TimeLabel.TextColor3 = CONFIG.SubText

    Title.TextTransparency = 0
    Content.TextTransparency = 0
    TimeLabel.TextTransparency = 0

    Icon.ImageTransparency = 0
    IconBackground.BackgroundTransparency = 0

    Progress.Size = UDim2.fromScale(1, 1)
    Progress.BackgroundTransparency = 0

    Island.BackgroundColor3 = CONFIG.Background
    Island.BackgroundTransparency = 0

    IslandStroke.Color = CONFIG.StrokeColor
    IslandStroke.Transparency = CONFIG.StrokeTransparency

    CompactDot.BackgroundTransparency = 0

    createActionButtons(options.Buttons)
end

local function setExpanded(expanded, force)
    if isDestroyed then
        return
    end

    if not currentNotification and not force then
        return
    end

    if isFinalizing and not force then
        return
    end

    if isExpanded == expanded then
        return
    end

    isExpanded = expanded

    transitionId += 1

    local thisTransition = transitionId

    cancelIslandTweens()

    if expanded then
        restoreIsland()

        renderNotification(currentNotification)

        CompactDot.Visible = false

        IconBackground.Visible = true
        Title.Visible = true
        Content.Visible = true
        TimeLabel.Visible = true

        CloseButton.Visible = true
        ProgressBackground.Visible = true

        Island.Size = UDim2.fromOffset(
            CONFIG.CompactWidth,
            CONFIG.CompactHeight
        )

        playIslandTween(
            Island,
            CONFIG.ExpandTime,
            {
                Size = UDim2.fromOffset(
                    CONFIG.Width,
                    getTargetHeight(currentNotification)
                ),
            },
            Enum.EasingStyle.Back
        )
    else
        local fadeDuration = 0.12

        local function fade(object, properties)
            local tween = TweenService:Create(
                object,
                TweenInfo.new(
                    fadeDuration,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                properties
            )

            table.insert(islandTweens, tween)
            tween:Play()
        end

        fade(Icon, {
            ImageTransparency = 1,
        })

        fade(IconBackground, {
            BackgroundTransparency = 1,
        })

        fade(Title, {
            TextTransparency = 1,
        })

        fade(Content, {
            TextTransparency = 1,
        })

        fade(TimeLabel, {
            TextTransparency = 1,
        })

        fade(CloseButton, {
            BackgroundTransparency = 1,
            TextTransparency = 1,
        })

        fade(ProgressBackground, {
            BackgroundTransparency = 1,
        })

        fade(Progress, {
            BackgroundTransparency = 1,
        })

        task.spawn(function()
            task.wait(fadeDuration + 0.02)

            if isDestroyed
                or thisTransition ~= transitionId
                or isExpanded then

                return
            end

            hideNotificationContent()
            cancelIslandTweens()

            local tween = playIslandTween(
                Island,
                CONFIG.CollapseTime,
                {
                    Size = UDim2.fromOffset(
                        CONFIG.CompactWidth,
                        CONFIG.CompactHeight
                    ),
                }
            )

            tween.Completed:Wait()

            if isDestroyed
                or thisTransition ~= transitionId
                or isExpanded then

                return
            end

            Island.Size = UDim2.fromOffset(
                CONFIG.CompactWidth,
                CONFIG.CompactHeight
            )

            Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)

            restoreIsland()
        end)
    end
end

local function expandIsland(options)
    renderNotification(options)

    CompactDot.Visible = false

    IconBackground.Visible = true
    Title.Visible = true
    Content.Visible = true
    TimeLabel.Visible = true

    CloseButton.Visible = true
    ProgressBackground.Visible = true

    ButtonContainer.Visible =
        typeof(options.Buttons) == "table"
        and #options.Buttons > 0

    if not isExpanded then
        setExpanded(true)
    else
        cancelIslandTweens()

        playIslandTween(
            Island,
            CONFIG.ExpandTime,
            {
                Size = UDim2.fromOffset(
                    CONFIG.Width,
                    getTargetHeight(options)
                ),
            }
        )
    end

    if CONFIG.SoundEnabled
        and NotificationSound.SoundId ~= "rbxassetid://0" then

        NotificationSound:Play()
    end
end

local function collapseIsland()
    isFinalizing = true

    transitionId += 1

    local thisTransition = transitionId

    cancelIslandTweens()

    local fadeTweens = {}

    local function addFade(object, properties)
        local tween = TweenService:Create(
            object,
            TweenInfo.new(
                0.15,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            properties
        )

        table.insert(fadeTweens, tween)
        tween:Play()
    end

    addFade(Icon, {
        ImageTransparency = 1,
    })

    addFade(IconBackground, {
        BackgroundTransparency = 1,
    })

    addFade(Title, {
        TextTransparency = 1,
    })

    addFade(Content, {
        TextTransparency = 1,
    })

    addFade(TimeLabel, {
        TextTransparency = 1,
    })

    addFade(CloseButton, {
        BackgroundTransparency = 1,
        TextTransparency = 1,
    })

    addFade(ProgressBackground, {
        BackgroundTransparency = 1,
    })

    addFade(Progress, {
        BackgroundTransparency = 1,
    })

    task.wait(0.17)

    if isDestroyed or thisTransition ~= transitionId then
        return
    end

    hideNotificationContent()
    cancelIslandTweens()

    local collapseTween = playIslandTween(
        Island,
        CONFIG.CollapseTime,
        {
            Size = UDim2.fromOffset(
                CONFIG.CompactWidth,
                CONFIG.CompactHeight
            ),
        }
    )

    collapseTween.Completed:Wait()

    if isDestroyed or thisTransition ~= transitionId then
        return
    end

    Island.Size = UDim2.fromOffset(
        CONFIG.CompactWidth,
        CONFIG.CompactHeight
    )

    Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)

    restoreIsland()

    isExpanded = false
    isFinalizing = false
end

local function showNotification(options)
    if isDestroyed then
        return
    end

    currentNotification = options
    currentNotification.dismissed = false

    isFinalizing = false

    restoreIsland()
    expandIsland(options)

    local duration = tonumber(options.Duration) or CONFIG.Duration
    duration = math.max(1, duration)

    local progressTween = createTween(
        Progress,
        duration,
        {
            Size = UDim2.new(0, 0, 1, 0),
        },
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local startTime = os.clock()

    while not isDestroyed
        and currentNotification == options
        and not options.dismissed do

        if os.clock() - startTime >= duration then
            break
        end

        task.wait(0.05)
    end

    progressTween:Cancel()

    if isDestroyed or currentNotification ~= options then
        return
    end

    currentNotification = nil

    collapseIsland()

    if isDestroyed then
        return
    end

    if #queue == 0 then
        scheduleIdleFade()
    end
end

local function processQueue()
    if isPlaying or isDestroyed then
        return
    end

    isPlaying = true

    while #queue > 0 and not isDestroyed do
        local options = table.remove(queue, 1)

        local success, err = pcall(showNotification, options)

        if not success then
            warn("[Sora x Hikaru] Notification error:", err)

            currentNotification = nil
            isFinalizing = false

            transitionId += 1

            cancelIslandTweens()

            isExpanded = false

            Island.Size = UDim2.fromOffset(
                CONFIG.CompactWidth,
                CONFIG.CompactHeight
            )

            hideNotificationContent()
            restoreIsland()
        end

        task.wait(0.15)
    end

    isPlaying = false

    if not isDestroyed then
        scheduleIdleFade()
    end
end

function Notify:Send(options)
    if isDestroyed then
        return nil
    end

    if typeof(options) ~= "table" then
        options = {}
    end

    notificationId += 1

    local notification = table.clone(options)

    notification.id = notificationId
    notification.dismissed = false

    table.insert(queue, notification)

    idleId += 1

    restoreIsland()

    task.spawn(processQueue)

    return notification.id
end

function Notify:Success(content, duration)
    return self:Send({
        Type = "Success",
        Title = "Success",
        Content = content,
        Duration = duration,
    })
end

function Notify:Error(content, duration)
    return self:Send({
        Type = "Error",
        Title = "Error",
        Content = content,
        Duration = duration,
    })
end

function Notify:Warning(content, duration)
    return self:Send({
        Type = "Warning",
        Title = "Warning",
        Content = content,
        Duration = duration,
    })
end

function Notify:Info(content, duration)
    return self:Send({
        Type = "Info",
        Title = "Information",
        Content = content,
        Duration = duration,
    })
end

function Notify:Dismiss(id)
    if currentNotification
        and (id == nil or currentNotification.id == id) then

        currentNotification.dismissed = true
        return true
    end

    for index, notification in ipairs(queue) do
        if notification.id == id then
            table.remove(queue, index)
            return true
        end
    end

    return false
end

function Notify:Update(id, title, content)
    if currentNotification
        and currentNotification.id == id then

        if title ~= nil then
            currentNotification.Title = title
            Title.Text = title
        end

        if content ~= nil then
            currentNotification.Content = content
            Content.Text = content
        end

        return true
    end

    for _, notification in ipairs(queue) do
        if notification.id == id then
            if title ~= nil then
                notification.Title = title
            end

            if content ~= nil then
                notification.Content = content
            end

            return true
        end
    end

    return false
end

function Notify:LiveActivity(title, content, duration, icon)
    return self:Send({
        Title = title or "Live Activity",
        Content = content or "Activity in progress...",

        Duration = duration or 8,

        Icon = icon or "rbxassetid://76051962811019",

        Type = "Info",
        IsLiveActivity = true,
    })
end

function Notify:SetSound(enabled, soundId)
    CONFIG.SoundEnabled = enabled == true

    if typeof(soundId) == "string" then
        CONFIG.SoundId = soundId
        NotificationSound.SoundId = soundId
    end
end

function Notify:SetHaptic(enabled, soundId, volume, strength)
    CONFIG.HapticEnabled = enabled == true

    if typeof(soundId) == "string" then
        CONFIG.HapticSoundId = soundId
        HapticSound.SoundId = soundId
    end

    if typeof(volume) == "number" then
        CONFIG.HapticVolume = math.clamp(volume, 0, 1)
        HapticSound.Volume = CONFIG.HapticVolume
    end

    if typeof(strength) == "number" then
        CONFIG.HapticStrength = math.clamp(strength, 1, 4)
    end
end

function Notify:SetIdleDelay(seconds)
    if typeof(seconds) ~= "number" then
        return
    end

    CONFIG.IdleDelay = math.max(0, seconds)

    idleId += 1

    if not currentNotification and not isPlaying then
        scheduleIdleFade()
    end
end

function Notify:SetAccent(color)
    if typeof(color) ~= "Color3" then
        return
    end

    CONFIG.Accent = color

    CompactDot.BackgroundColor3 = color

    if currentNotification then
        currentNotification.Accent = color

        IconBackground.BackgroundColor3 = color
        Progress.BackgroundColor3 = color
    end
end

function Notify:ClearQueue()
    table.clear(queue)
end

function Notify:Destroy()
    if isDestroyed then
        return
    end

    isDestroyed = true

    transitionId += 1
    idleId += 1
    hapticId += 1

    cancelIslandTweens()
    cancelAppearanceTweens()
    cancelHapticTweens()

    table.clear(queue)

    currentNotification = nil

    if NotificationSound then
        NotificationSound:Destroy()
    end

    if HapticSound then
        HapticSound:Destroy()
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    if _G.SoraNotify == self then
        _G.SoraNotify = nil
    end
end

ClickArea.Activated:Connect(function()
    if isDestroyed
        or not currentNotification
        or isFinalizing then

        return
    end

    playHaptic()
    setExpanded(not isExpanded)
end)

CloseButton.Activated:Connect(function()
    if isDestroyed
        or not currentNotification
        or isFinalizing then

        return
    end

    playButtonPress(CloseButton)

    currentNotification.dismissed = true
end)

local function setCompact()
    isExpanded = false
    isFinalizing = false

    cancelIslandTweens()
    cancelAppearanceTweens()

    hideNotificationContent()

    Island.Size = UDim2.fromOffset(
        CONFIG.CompactWidth,
        CONFIG.CompactHeight
    )

    Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)

    restoreIsland()
end

setCompact()

_G.SoraNotify = Notify

return Notify

