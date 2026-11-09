do
  
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local IsEnabled = false
local IsDragging = false
local DragStart
local StartPosition

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FloatingTogglePreview"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Container = Instance.new("Frame")
Container.Name = "ToggleCard"
Container.Size = UDim2.fromOffset(150, 85)
Container.Position = UDim2.new(0.5, -75, 0.5, -42)
Container.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
Container.BackgroundTransparency = 0.08
Container.BorderSizePixel = 0
Container.Active = true
Container.Parent = ScreenGui

local ContainerCorner = Instance.new("UICorner")
ContainerCorner.CornerRadius = UDim.new(0, 13)
ContainerCorner.Parent = Container

local ContainerStroke = Instance.new("UIStroke")
ContainerStroke.Color = Color3.fromRGB(65, 65, 65)
ContainerStroke.Thickness = 1
ContainerStroke.Transparency = 0.2
ContainerStroke.Parent = Container

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -12, 0, 25)
Title.Position = UDim2.fromOffset(6, 2)
Title.BackgroundTransparency = 1
Title.Text = "Manual Spam"
Title.TextColor3 = Color3.fromRGB(225, 225, 225)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.Parent = Container

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(1, -20, 0, 45)
ToggleButton.Position = UDim2.fromOffset(10, 32)
ToggleButton.BackgroundColor3 = Color3.fromRGB(55, 17, 17)
ToggleButton.BackgroundTransparency = 0
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "SPAM: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 13
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = Container

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 9)
ButtonCorner.Parent = ToggleButton

local function UpdateButton()
    ToggleButton.Text = IsEnabled and "SPAM: ON" or "SPAM: OFF"

    ToggleButton.BackgroundColor3 = IsEnabled
        and Color3.fromRGB(115, 30, 30)
        or Color3.fromRGB(55, 17, 17)
end

local function PlayPressEffect()
    TweenService:Create(
        ToggleButton,
        TweenInfo.new(0.08),
        { BackgroundTransparency = 0.3 }
    ):Play()

    task.delay(0.08, function()
        if ToggleButton.Parent then
            TweenService:Create(
                ToggleButton,
                TweenInfo.new(0.18),
                { BackgroundTransparency = 0 }
            ):Play()
        end
    end)
end

ToggleButton.Activated:Connect(function()
    IsEnabled = not IsEnabled

    UpdateButton()
    PlayPressEffect()

    print("Manual Spam:", IsEnabled and "ON" or "OFF")
end)

Container.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        IsDragging = true
        DragStart = Input.Position
        StartPosition = Container.Position
    end
end)

UserInputService.InputChanged:Connect(function(Input)
    if not IsDragging then
        return
    end

    if Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch then

        local Delta = Input.Position - DragStart

        Container.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        IsDragging = false
    end
end)

UpdateButton()

end
