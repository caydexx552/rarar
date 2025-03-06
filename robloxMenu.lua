-- Настройки
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

-- Переменные
local menuVisible = true
local dragging = false
local dragStartPos = Vector2.new(0, 0)
local menuStartPos = Vector2.new(0, 0)
local hitboxEnabled = false
local espEnabled = false
local spiderEnabled = false
local silentAimEnabled = false
local wallbangEnabled = false
local headSize = 1
local fov = 70

-- Звук при активации функций
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://123456" -- Замените на ID звука
sound.Volume = 1
sound.Parent = playerGui

-- Создание 3D-меню
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "TridentHackMenu"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0.3, 0, 0.6, 0)
frame.Position = UDim2.new(0.35, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = false

-- Эффекты для меню
local gradient = Instance.new("UIGradient", frame)
gradient.Rotation = 45
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 0)),
    ColorSequenceKeypoint.new(1, Color3.new(0, 0, 1))
})

local title = Instance.new("TextLabel", frame)
title.Text = "Trident Hack Menu"
title.Size = UDim2.new(1, 0, 0.1, 0)
title.Position = UDim2.new(0, 0, 0, 0)
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SciFi
title.TextSize = 20

-- Перемещение меню
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
        menuStartPos = Vector2.new(frame.Position.X.Scale, frame.Position.Y.Scale)
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

userInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
        frame.Position = UDim2.new(menuStartPos.X + delta.X / screenGui.AbsoluteSize.X, 0, menuStartPos.Y + delta.Y / screenGui.AbsoluteSize.Y, 0)
    end
end)

-- Закрытие меню на правый Shift
userInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        menuVisible = not menuVisible
        screenGui.Enabled = menuVisible
        sound:Play()
    end
end)

-- Функция Hitbox (увеличение головы)
local function updateHitbox()
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("Head") then
            otherPlayer.Character.Head.Size = Vector3.new(headSize, headSize, headSize)
            -- Сохраняем размер головы даже после смерти
            otherPlayer.CharacterAdded:Connect(function()
                if hitboxEnabled then
                    otherPlayer.Character:WaitForChild("Head").Size = Vector3.new(headSize, headSize, headSize)
                end
            end)
        end
    end
end

-- Функция ESP
local function enableESP()
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local highlight = Instance.new("Highlight", otherPlayer.Character)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.new(1, 0, 0)
        end
    end
end

local function disableESP()
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local highlight = otherPlayer.Character:FindFirstChild("Highlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
end

-- Функция Spider (ползание по стенам)
local function enableSpider()
    if spiderEnabled then
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
        end
    end
end

-- Функция Silent Aim
local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - otherPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = otherPlayer
            end
        end
    end
    return closestPlayer
end

local function silentAim()
    if silentAimEnabled then
        local closestPlayer = getClosestPlayer()
        if closestPlayer then
            local target = closestPlayer.Character.HumanoidRootPart.Position
            player.Character.HumanoidRootPart.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position, target)
        end
    end
end

-- Функция Wallbang (стрельба через стены)
local function wallbang()
    if wallbangEnabled then
        local mouse = player:GetMouse()
        local ray = Ray.new(mouse.Origin, mouse.UnitRay.Direction * 1000)
        local hit, position = workspace:FindPartOnRay(ray, player.Character)
        if hit and hit.Parent:FindFirstChild("Humanoid") then
            hit.Parent.Humanoid:TakeDamage(100) -- Убивает игрока
        end
    end
end

-- Функция FOV (изменение поля зрения)
local function updateFOV()
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = fov
    end
end

-- Галочки для активации функций
local function createToggle(text, position, callback)
    local toggleFrame = Instance.new("Frame", frame)
    toggleFrame.Size = UDim2.new(0.8, 0, 0.1, 0)
    toggleFrame.Position = position
    toggleFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    toggleFrame.BorderSizePixel = 0

    local toggleButton = Instance.new("TextButton", toggleFrame)
    toggleButton.Size = UDim2.new(0.2, 0, 1, 0)
    toggleButton.Position = UDim2.new(0.75, 0, 0, 0)
    toggleButton.Text = "Off"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.BackgroundColor3 = Color3.new(0.5, 0, 0)
    toggleButton.BorderSizePixel = 0

    local label = Instance.new("TextLabel", toggleFrame)
    label.Text = text
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SciFi
    label.TextSize = 14

    toggleButton.MouseButton1Click:Connect(function()
        if toggleButton.Text == "Off" then
            toggleButton.Text = "On"
            toggleButton.BackgroundColor3 = Color3.new(0, 0.5, 0)
            sound:Play()
            callback(true)
        else
            toggleButton.Text = "Off"
            toggleButton.BackgroundColor3 = Color3.new(0.5, 0, 0)
            sound:Play()
            callback(false)
        end
    end)
end

-- Текстовое поле для ввода размера головы
local function createTextBox(text, position, callback)
    local textBoxFrame = Instance.new("Frame", frame)
    textBoxFrame.Size = UDim2.new(0.8, 0, 0.1, 0)
    textBoxFrame.Position = position
    textBoxFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    textBoxFrame.BorderSizePixel = 0

    local textBox = Instance.new("TextBox", textBoxFrame)
    textBox.Size = UDim2.new(0.6, 0, 1, 0)
    textBox.Position = UDim2.new(0.2, 0, 0, 0)
    textBox.Text = ""
    textBox.PlaceholderText = text
    textBox.TextColor3 = Color3.new(1, 1, 1)
    textBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    textBox.BorderSizePixel = 0

    textBox.FocusLost:Connect(function()
        local value = tonumber(textBox.Text)
        if value then
            callback(value)
        end
    end)
end

-- Ползунок для настройки FOV
local function createSlider(text, position, value, min, max, callback)
    local sliderFrame = Instance.new("Frame", frame)
    sliderFrame.Size = UDim2.new(0.8, 0, 0.1, 0)
    sliderFrame.Position = position
    sliderFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    sliderFrame.BorderSizePixel = 0

    local sliderButton = Instance.new("TextButton", sliderFrame)
    sliderButton.Size = UDim2.new(0.2, 0, 1, 0)
    sliderButton.Position = UDim2.new(0.75, 0, 0, 0)
    sliderButton.Text = text .. ": " .. value
    sliderButton.TextColor3 = Color3.new(1, 1, 1)
    sliderButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    sliderButton.BorderSizePixel = 0

    sliderButton.MouseButton1Click:Connect(function()
        value = value + 10
        if value > max then
            value = min
        end
        sliderButton.Text = text .. ": " .. value
        callback(value)
    end)
end

-- Создание элементов меню
local yOffset = 0.15
createToggle("Hitbox", UDim2.new(0.1, 0, yOffset, 0), function(state)
    hitboxEnabled = state
    updateHitbox()
end)
yOffset = yOffset + 0.1

createTextBox("Head Size", UDim2.new(0.1, 0, yOffset, 0), function(value)
    headSize = value
    updateHitbox()
end)
yOffset = yOffset + 0.1

createToggle("ESP", UDim2.new(0.1, 0, yOffset, 0), function(state)
    espEnabled = state
    if state then
        enableESP()
    else
        disableESP()
    end
end)
yOffset = yOffset + 0.1

createToggle("Spider", UDim2.new(0.1, 0, yOffset, 0), function(state)
    spiderEnabled = state
    enableSpider()
end)
yOffset = yOffset + 0.1

createToggle("Silent Aim", UDim2.new(0.1, 0, yOffset, 0), function(state)
    silentAimEnabled = state
end)
yOffset = yOffset + 0.1

createToggle("Wallbang", UDim2.new(0.1, 0, yOffset, 0), function(state)
    wallbangEnabled = state
end)
yOffset = yOffset + 0.1

createSlider("FOV", UDim2.new(0.1, 0, yOffset, 0), fov, 50, 200, function(value)
    fov = value
    updateFOV()
end)

-- Silent Aim и Wallbang
runService.Heartbeat:Connect(function()
    silentAim()
    wallbang()
end)
