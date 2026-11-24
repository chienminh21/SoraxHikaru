

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

    Transparency = 0.75,

    IdleTransparency = 0.9,

    Duration = 4,

    IdleDelay = 8,

    Background = Color3.fromRGB(12, 12, 15),

    Text = Color3.fromRGB(255, 255, 255),

    SubText = Color3.fromRGB(165, 165, 175),

    Accent = Color3.fromRGB(225, 45, 65),

    -- Light Glass Button

    GlassButtonColor = Color3.fromRGB(235, 238, 245),

    GlassButtonText = Color3.fromRGB(250, 250, 255),

    GlassStrokeColor = Color3.fromRGB(255, 255, 255),

    GlassTransparency = 0.72,

    GlassStrokeTransparency = 0.58,

    ButtonPressScale = 0.94,

    ButtonShakeStrength = 2,

    SoundEnabled = false,

    SoundId = "rbxassetid://0",

    HapticEnabled = true,

    HapticSoundId = "rbxassetid://0",

    HapticVolume = 0.35,

    HapticStrength = 2,

    ExpandTime = 0.4,

    CollapseTime = 0.3,

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

local shimmerId = 0

local hapticId = 0

local islandTweens = {}

local shimmerTween = nil

local hapticTweens = {}

local Notify = {}

local function createTween(object, duration, properties, style, direction)

    local animation = TweenService:Create(

        object,

        TweenInfo.new(

            duration,

            style or Enum.EasingStyle.Quint,

            direction or Enum.EasingDirection.Out

        ),

        properties

    )

    animation:Play()

    return animation

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

    label.ZIndex = 3

    label.Parent = parent

    return label

end

local function cancelIslandTweens()

    for _, animation in ipairs(islandTweens) do

        animation:Cancel()

    end

    table.clear(islandTweens)

end

local function playIslandTween(object, duration, properties, style, direction)

    local animation = createTween(

        object,

        duration,

        properties,

        style,

        direction

    )

    table.insert(islandTweens, animation)

    return animation

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

--// Screen GUI

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "SoraDynamicIsland"

ScreenGui.IgnoreGuiInset = true

ScreenGui.ResetOnSpawn = false

ScreenGui.DisplayOrder = 999

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ScreenGui.Parent = PlayerGui

--// Main Island

local Island = Instance.new("Frame")

Island.Name = "Island"

Island.AnchorPoint = Vector2.new(0.5, 0)

Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)

Island.Size = UDim2.fromOffset(

    CONFIG.CompactWidth,

    CONFIG.CompactHeight

)

Island.BackgroundColor3 = CONFIG.Background

Island.BackgroundTransparency = CONFIG.Transparency

Island.BorderSizePixel = 0

Island.ClipsDescendants = true

Island.ZIndex = 1

Island.Parent = ScreenGui

createCorner(Island, 30)

local IslandStroke = Instance.new("UIStroke")

IslandStroke.Color = Color3.fromRGB(130, 130, 140)

IslandStroke.Transparency = 0.65

IslandStroke.Thickness = 1

IslandStroke.Parent = Island

local Highlight = Instance.new("Frame")

Highlight.Name = "Highlight"

Highlight.Position = UDim2.fromOffset(15, 1)

Highlight.Size = UDim2.new(1, -30, 0, 1)

Highlight.BackgroundColor3 = Color3.new(1, 1, 1)

Highlight.BackgroundTransparency = 0.65

Highlight.BorderSizePixel = 0

Highlight.ZIndex = 2

Highlight.Parent = Island

--// Compact Dot

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

--// Icon

local IconBackground = Instance.new("Frame")

IconBackground.Name = "IconBackground"

IconBackground.Position = UDim2.fromOffset(12, 19)

IconBackground.Size = UDim2.fromOffset(37, 37)

IconBackground.BackgroundColor3 = CONFIG.Accent

IconBackground.BackgroundTransparency = 0.65

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

--// Title

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

local TitleGradient = Instance.new("UIGradient")

TitleGradient.Color = ColorSequence.new({

    ColorSequenceKeypoint.new(0, CONFIG.Text),

    ColorSequenceKeypoint.new(0.5, CONFIG.Accent),

    ColorSequenceKeypoint.new(1, CONFIG.Text),

})

TitleGradient.Offset = Vector2.new(-1, 0)

TitleGradient.Parent = Title

--// Content

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

--// Time

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

--// Close Button

local CloseButton = Instance.new("TextButton")

CloseButton.Name = "CloseButton"

CloseButton.AnchorPoint = Vector2.new(1, 0)

CloseButton.Position = UDim2.new(1, -10, 0, 45)

CloseButton.Size = UDim2.fromOffset(20, 20)

CloseButton.BackgroundColor3 = Color3.fromRGB(65, 65, 72)

CloseButton.BackgroundTransparency = 0.25

CloseButton.Text = "×"

CloseButton.TextColor3 = CONFIG.Text

CloseButton.Font = Enum.Font.GothamMedium

CloseButton.TextSize = 16

CloseButton.AutoButtonColor = false

CloseButton.Visible = false

CloseButton.ZIndex = 6

CloseButton.Parent = Island

createCorner(CloseButton, 10)

--// Action Buttons Container

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

--// Progress

local ProgressBackground = Instance.new("Frame")

ProgressBackground.Name = "ProgressBackground"

ProgressBackground.Position = UDim2.new(0, 12, 1, -5)

ProgressBackground.Size = UDim2.new(1, -24, 0, 2)

ProgressBackground.BackgroundColor3 = Color3.fromRGB(100, 100, 110)

ProgressBackground.BackgroundTransparency = 0.65

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

--// Click Area

local ClickArea = Instance.new("TextButton")

ClickArea.Name = "ClickArea"

ClickArea.Size = UDim2.fromScale(1, 1)

ClickArea.BackgroundTransparency = 1

ClickArea.Text = ""

ClickArea.AutoButtonColor = false

ClickArea.ZIndex = 2

ClickArea.Parent = Island

--// Sounds

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

--// Haptic

local function cancelHapticTweens()

    hapticId += 1

    for _, animation in ipairs(hapticTweens) do

        animation:Cancel()

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

    for _, animation in ipairs(hapticTweens) do

        animation:Cancel()

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

            local animation = TweenService:Create(

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

            table.insert(hapticTweens, animation)

            animation:Play()

            animation.Completed:Wait()

        end

        if thisId == hapticId and not isDestroyed then

            Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)

            table.clear(hapticTweens)

        end

    end)

end

--// Light Glass Button Press Animation

local function playButtonPress(button)

    if not button or not button.Parent then

        return

    end

    playHaptic()

    local originalTransparency = button.BackgroundTransparency

    local originalRotation = button.Rotation

    local scale = button:FindFirstChildOfClass("UIScale")

    if not scale then

        scale = Instance.new("UIScale")

        scale.Scale = 1

        scale.Parent = button

    end

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

    createTween(button, 0.08, {

        BackgroundTransparency = math.max(

            originalTransparency - 0.12,

            0

        ),

    }, Enum.EasingStyle.Quad)

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

                BackgroundTransparency = originalTransparency,

            },

            Enum.EasingStyle.Quad

        )

    end)

end

--// Shimmer

local function stopShimmer()

    shimmerId += 1

    if shimmerTween then

        shimmerTween:Cancel()

        shimmerTween = nil

    end

end

local function startShimmer()

    stopShimmer()

    local thisId = shimmerId

    task.spawn(function()

        while not isDestroyed

            and thisId == shimmerId

            and isExpanded do

            TitleGradient.Offset = Vector2.new(-1, 0)

            local animation = createTween(

                TitleGradient,

                1.2,

                {

                    Offset = Vector2.new(1, 0),

                },

                Enum.EasingStyle.Sine

            )

            shimmerTween = animation

            animation.Completed:Wait()

            if thisId ~= shimmerId then

                break

            end

            task.wait(0.8)

        end

    end)

end

--// Island Appearance

local function restoreIsland()

    idleId += 1

    playIslandTween(Island, 0.2, {

        BackgroundTransparency = CONFIG.Transparency,

    })

    playIslandTween(IslandStroke, 0.2, {

        Transparency = 0.45,

    })

    playIslandTween(Highlight, 0.2, {

        BackgroundTransparency = 0.65,

    })

    playIslandTween(CompactDot, 0.2, {

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

        playIslandTween(Island, 1.5, {

            BackgroundTransparency = CONFIG.IdleTransparency,

        })

        playIslandTween(IslandStroke, 1.5, {

            Transparency = 0.92,

        })

        playIslandTween(Highlight, 1.5, {

            BackgroundTransparency = 1,

        })

        playIslandTween(CompactDot, 1.5, {

            BackgroundTransparency = 0.4,

        })

    end)

end

--// Clear Action Buttons

local function clearActionButtons()

    for _, child in ipairs(ButtonContainer:GetChildren()) do

        if child:IsA("TextButton") then

            child:Destroy()

        end

    end

end

--// Hide Notification Content

local function hideNotificationContent()

    stopShimmer()

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

    IconBackground.BackgroundTransparency = 0.65

    Progress.Size = UDim2.fromScale(1, 1)

    Progress.BackgroundTransparency = 0

    ProgressBackground.BackgroundTransparency = 0.65

    CompactDot.Visible = true

    CompactDot.BackgroundTransparency = 0

    clearActionButtons()

end

--// Expand / Collapse

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

        CompactDot.Visible = false

        startShimmer()

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

        stopShimmer()

        local fadeDuration = 0.14

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

            Island.BackgroundTransparency = CONFIG.Transparency

            IslandStroke.Transparency = 0.65

            Highlight.BackgroundTransparency = 0.65

        end)

    end

end

--// Create Light Glass Action Buttons

local function createActionButtons(buttons)

    clearActionButtons()

    if typeof(buttons) ~= "table" then

        return

    end

    for index, buttonData in ipairs(buttons) do

        if typeof(buttonData) ~= "table" then

            continue

        end

        local actionButton = Instance.new("TextButton")

        actionButton.Name = "Action_" .. index

        actionButton.Size = UDim2.fromOffset(82, 29)

        actionButton.BackgroundColor3 = buttonData.Color

            or CONFIG.GlassButtonColor

        actionButton.BackgroundTransparency = CONFIG.GlassTransparency

        actionButton.BorderSizePixel = 0

        actionButton.Text = buttonData.Text or "Action"

        actionButton.TextColor3 = CONFIG.GlassButtonText

        actionButton.Font = Enum.Font.GothamSemibold

        actionButton.TextSize = 10

        actionButton.AutoButtonColor = false

        actionButton.LayoutOrder = index

        actionButton.ZIndex = 6

        actionButton.Parent = ButtonContainer

        createCorner(actionButton, 10)

        -- Glass border

        local stroke = Instance.new("UIStroke")

        stroke.Color = CONFIG.GlassStrokeColor

        stroke.Transparency = CONFIG.GlassStrokeTransparency

        stroke.Thickness = 1

        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        stroke.Parent = actionButton

        -- Glass gradient

        local gradient = Instance.new("UIGradient")

        gradient.Rotation = 90

        gradient.Color = ColorSequence.new({

            ColorSequenceKeypoint.new(

                0,

                Color3.fromRGB(255, 255, 255)

            ),

            ColorSequenceKeypoint.new(

                1,

                Color3.fromRGB(155, 160, 175)

            ),

        })

        gradient.Transparency = NumberSequence.new({

            NumberSequenceKeypoint.new(0, 0.45),

            NumberSequenceKeypoint.new(1, 0.8),

        })

        gradient.Parent = actionButton

        -- Button scale

        local buttonScale = Instance.new("UIScale")

        buttonScale.Scale = 1

        buttonScale.Parent = actionButton

        -- Top glass reflection

        local reflection = Instance.new("Frame")

        reflection.Name = "GlassReflection"

        reflection.Position = UDim2.fromOffset(7, 2)

        reflection.Size = UDim2.new(1, -14, 0, 1)

        reflection.BackgroundColor3 = Color3.new(1, 1, 1)

        reflection.BackgroundTransparency = 0.55

        reflection.BorderSizePixel = 0

        reflection.ZIndex = 7

        reflection.Parent = actionButton

        createCorner(reflection, 5)

        -- Button callback

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

--// Expand Island Content

local function expandIsland(options)

    local notificationType = getNotificationType(options)

    local accent = options.Accent or notificationType.Accent

    CompactDot.Visible = false

    IconBackground.Visible = true

    Title.Visible = true

    Content.Visible = true

    TimeLabel.Visible = true

    ProgressBackground.Visible = true

    CloseButton.Visible = true

    Island.BackgroundTransparency = CONFIG.Transparency

    IslandStroke.Transparency = 0.45

    IconBackground.BackgroundColor3 = accent

    Progress.BackgroundColor3 = accent

    Title.Text = options.Title or "Sora x Hikaru"

    Content.Text = options.Content or "Notification"

    TimeLabel.Text = options.Time or "now"

    Icon.Image = options.Icon or notificationType.Icon

    Icon.ImageTransparency = 0

    Title.TextTransparency = 0

    Content.TextTransparency = 0

    TimeLabel.TextTransparency = 0

    Progress.Size = UDim2.fromScale(1, 1)

    Progress.BackgroundTransparency = 0

    createActionButtons(options.Buttons)

    if not isExpanded then

        setExpanded(true)

    else

        cancelIslandTweens()

        playIslandTween(Island, CONFIG.ExpandTime, {

            Size = UDim2.fromOffset(

                CONFIG.Width,

                getTargetHeight(options)

            ),

        })

    end

    if CONFIG.SoundEnabled

        and NotificationSound.SoundId ~= "rbxassetid://0" then

        NotificationSound:Play()

    end

end

--// Collapse Island

local function collapseIsland()

    isFinalizing = true

    stopShimmer()

    transitionId += 1

    local thisTransition = transitionId

    cancelIslandTweens()

    local fadeTweens = {}

    local function addFade(object, properties)

        local animation = TweenService:Create(

            object,

            TweenInfo.new(

                0.15,

                Enum.EasingStyle.Quad,

                Enum.EasingDirection.Out

            ),

            properties

        )

        table.insert(fadeTweens, animation)

        animation:Play()

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

    addFade(ButtonContainer, {

        BackgroundTransparency = 1,

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

    Island.BackgroundTransparency = CONFIG.Transparency

    IslandStroke.Transparency = 0.65

    Highlight.BackgroundTransparency = 0.65

    isExpanded = false

    isFinalizing = false

end

--// Notification Handler

local function showNotification(options)

    if isDestroyed then

        return

    end

    currentNotification = options

    currentNotification.dismissed = false

    restoreIsland()

    expandIsland(options)

    local duration = tonumber(options.Duration) or CONFIG.Duration

    duration = math.max(1, duration)

    local startTime = os.clock()

    local progressTween = createTween(

        Progress,

        duration,

        {

            Size = UDim2.new(0, 0, 1, 0),

        },

        Enum.EasingStyle.Linear

    )

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

--// Queue

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

            stopShimmer()

            isExpanded = false

            Island.Size = UDim2.fromOffset(

                CONFIG.CompactWidth,

                CONFIG.CompactHeight

            )

            hideNotificationContent()

        end

        task.wait(0.15)

    end

    isPlaying = false

    if not isDestroyed then

        scheduleIdleFade()

    end

end

--// Public API

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

end

function Notify:SetAccent(color)

    if typeof(color) ~= "Color3" then

        return

    end

    CONFIG.Accent = color

    CompactDot.BackgroundColor3 = color

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

    shimmerId += 1

    hapticId += 1

    stopShimmer()

    cancelIslandTweens()

    for _, animation in ipairs(hapticTweens) do

        animation:Cancel()

    end

    table.clear(hapticTweens)

    table.clear(queue)

    currentNotification = nil

    NotificationSound:Destroy()

    HapticSound:Destroy()

    ScreenGui:Destroy()

    if _G.SoraNotify == self then

        _G.SoraNotify = nil

    end

end

--// Main Interactions

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

_G.SoraNotify = Notify

local function setCompact()
    isExpanded = false
    isFinalizing = false
    cancelIslandTweens()
    hideNotificationContent()
    Island.Size = UDim2.fromOffset(
        CONFIG.CompactWidth,
        CONFIG.CompactHeight
    )
    Island.Position = UDim2.new(0.5, 0, 0, CONFIG.Top)

    Island.BackgroundTransparency = CONFIG.Transparency

    IslandStroke.Transparency = 0.65

    Highlight.BackgroundTransparency = 0.65

end

setCompact()

