--[[
    Auto-Fire + ESP System (Fixed)
    - Fire button = ImageLabel → dùng firetouchinterest
    - Giữ fire thay vì spam → không crash
    LocalScript → StarterGui
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local CONFIG = {
    CROSSHAIR_PADDING  = 18,
    FIRE_ONLY_ENEMY    = true,
    
    ESP_ENABLED        = true,
    ESP_MAX_DIST       = 1000,
    
    ENEMY_COLOR        = Color3.fromRGB(255, 50, 50),
    TEAM_COLOR         = Color3.fromRGB(50, 255, 50),
    ENEMY_FILL         = Color3.fromRGB(255, 0, 0),
    TEAM_FILL          = Color3.fromRGB(0, 255, 0),
}

local BODY_PARTS = {
    "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
    "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
    "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg",
}

-------------------------------------------------
-- TÌM CROSSHAIR + FIRE BUTTON
-------------------------------------------------
local cursorGui      = PlayerGui:WaitForChild("cursor", 10)
local crosshairFrame = cursorGui and cursorGui:WaitForChild("Frame", 10)

local mobileGui  = PlayerGui:WaitForChild("mobile", 10)
local weaponGui  = mobileGui and mobileGui:WaitForChild("weapon", 10)
local fireFolder = weaponGui and weaponGui:WaitForChild("fire", 10)
local fireBtn    = fireFolder and fireFolder:WaitForChild("fire", 10)

if not crosshairFrame then
    warn("❌ Không tìm thấy cursor.Frame!")
    return
end

if not fireBtn then
    warn("❌ Không tìm thấy fire button!")
    return
end

print("✅ Crosshair:", crosshairFrame:GetFullName())
print("✅ Fire button:", fireBtn:GetFullName(), "Class:", fireBtn.ClassName)

-------------------------------------------------
-- STATE
-------------------------------------------------
local autoFireEnabled = true
local espEnabled      = true
local isHoldingFire   = false   -- đang giữ nút fire?
local fireCount       = 0
local espObjects      = {}
local overlapping     = {}

-------------------------------------------------
-- GUI
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoFireESP"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 99999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = PlayerGui

-- Toggle Panel
local TogglePanel = Instance.new("Frame")
TogglePanel.Name                   = "Toggles"
TogglePanel.Size                   = UDim2.new(0, 160, 0, 130)
TogglePanel.Position               = UDim2.new(0, 10, 0, 120)
TogglePanel.BackgroundColor3       = Color3.fromRGB(10, 10, 20)
TogglePanel.BackgroundTransparency = 0.2
TogglePanel.BorderSizePixel        = 0
TogglePanel.ZIndex                 = 100
TogglePanel.Active                 = true
TogglePanel.Parent                 = ScreenGui
Instance.new("UICorner", TogglePanel).CornerRadius = UDim.new(0, 10)
local tpStroke = Instance.new("UIStroke", TogglePanel)
tpStroke.Color = Color3.fromRGB(255, 60, 60); tpStroke.Thickness = 2

-- Drag
local tDrag, tDragStart, tStartPos = false, nil, nil
TogglePanel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tDrag = true; tDragStart = input.Position; tStartPos = TogglePanel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then tDrag = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not tDrag then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - tDragStart
        TogglePanel.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + d.X, tStartPos.Y.Scale, tStartPos.Y.Offset + d.Y)
    end
end)

-- Title
local tTitle = Instance.new("TextLabel")
tTitle.Size = UDim2.new(1, 0, 0, 25)
tTitle.BackgroundTransparency = 1
tTitle.Font = Enum.Font.GothamBold
tTitle.TextSize = 13
tTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
tTitle.Text = "⚡ AUTO-FIRE + ESP"
tTitle.ZIndex = 101
tTitle.Parent = TogglePanel

-- Auto-Fire Toggle
local AutoFireBtn = Instance.new("TextButton")
AutoFireBtn.Size             = UDim2.new(1, -16, 0, 30)
AutoFireBtn.Position         = UDim2.new(0, 8, 0, 28)
AutoFireBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
AutoFireBtn.TextColor3       = Color3.new(1, 1, 1)
AutoFireBtn.Font             = Enum.Font.GothamBold
AutoFireBtn.TextSize         = 12
AutoFireBtn.Text             = "🔫 Auto-Fire: ON"
AutoFireBtn.BorderSizePixel  = 0
AutoFireBtn.ZIndex           = 101
AutoFireBtn.Parent           = TogglePanel
Instance.new("UICorner", AutoFireBtn).CornerRadius = UDim.new(0, 8)

-- ESP Toggle
local ESPBtn = Instance.new("TextButton")
ESPBtn.Size             = UDim2.new(1, -16, 0, 30)
ESPBtn.Position         = UDim2.new(0, 8, 0, 62)
ESPBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
ESPBtn.TextColor3       = Color3.new(1, 1, 1)
ESPBtn.Font             = Enum.Font.GothamBold
ESPBtn.TextSize         = 12
ESPBtn.Text             = "👁️ ESP: ON"
ESPBtn.BorderSizePixel  = 0
ESPBtn.ZIndex           = 101
ESPBtn.Parent           = TogglePanel
Instance.new("UICorner", ESPBtn).CornerRadius = UDim.new(0, 8)

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size                   = UDim2.new(1, -16, 0, 25)
StatusLabel.Position               = UDim2.new(0, 8, 0, 96)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font                   = Enum.Font.RobotoMono
StatusLabel.TextSize               = 10
StatusLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
StatusLabel.TextXAlignment         = Enum.TextXAlignment.Left
StatusLabel.RichText               = true
StatusLabel.Text                   = ""
StatusLabel.ZIndex                 = 101
StatusLabel.Parent                 = TogglePanel

-- Hit Notification
local HitNotif = Instance.new("TextLabel")
HitNotif.Size                   = UDim2.new(0, 350, 0, 45)
HitNotif.Position               = UDim2.new(0.5, -175, 0, 60)
HitNotif.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
HitNotif.BackgroundTransparency = 0.4
HitNotif.TextColor3             = Color3.fromRGB(255, 80, 80)
HitNotif.Font                   = Enum.Font.GothamBold
HitNotif.TextSize               = 16
HitNotif.Text                   = ""
HitNotif.Visible                = false
HitNotif.BorderSizePixel        = 0
HitNotif.ZIndex                 = 100
HitNotif.RichText               = true
HitNotif.Parent                 = ScreenGui
Instance.new("UICorner", HitNotif).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", HitNotif).Color = Color3.fromRGB(255, 50, 50)

local notifHideTime = 0

local function showNotif(text, color)
    HitNotif.Text       = text
    HitNotif.TextColor3 = color or Color3.fromRGB(255, 80, 80)
    HitNotif.Visible    = true
    notifHideTime       = tick() + 1.2
end

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function isEnemy(player)
    if player == LocalPlayer then return false end
    if LocalPlayer.Team and player.Team then
        return player.Team ~= LocalPlayer.Team
    end
    if LocalPlayer.TeamColor and player.TeamColor then
        if LocalPlayer.TeamColor ~= BrickColor.new("White") then
            return player.TeamColor ~= LocalPlayer.TeamColor
        end
    end
    return true
end

local function getDistance(character)
    local myChar = LocalPlayer.Character
    if not myChar then return math.huge end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local theirRoot = character:FindFirstChild("HumanoidRootPart")
    if myRoot and theirRoot then
        return (myRoot.Position - theirRoot.Position).Magnitude
    end
    return math.huge
end

local function getCrosshairBounds()
    local pos  = crosshairFrame.AbsolutePosition
    local size = crosshairFrame.AbsoluteSize
    return {
        x1 = pos.X - CONFIG.CROSSHAIR_PADDING,
        y1 = pos.Y - CONFIG.CROSSHAIR_PADDING,
        x2 = pos.X + size.X + CONFIG.CROSSHAIR_PADDING,
        y2 = pos.Y + size.Y + CONFIG.CROSSHAIR_PADDING,
        cx = pos.X + size.X / 2,
        cy = pos.Y + size.Y / 2,
    }
end

local function pointInBounds(px, py, bounds)
    return px >= bounds.x1 and px <= bounds.x2
       and py >= bounds.y1 and py <= bounds.y2
end

-------------------------------------------------
-- ★★★ FIRE SYSTEM (GIỮ / THẢ - KHÔNG SPAM) ★★★
-------------------------------------------------

local function startFire()
    if isHoldingFire then return end
    if not fireBtn or not fireBtn.Parent then return end

    isHoldingFire = true
    fireCount += 1

    pcall(function()
        -- ImageLabel → chỉ dùng firetouchinterest
        if firetouchinterest then
            firetouchinterest(fireBtn, fireBtn, 0) -- TouchBegan (giữ)
        end
    end)
end

local function stopFire()
    if not isHoldingFire then return end

    isHoldingFire = false

    pcall(function()
        if firetouchinterest then
            firetouchinterest(fireBtn, fireBtn, 1) -- TouchEnded (thả)
        end
    end)
end

-------------------------------------------------
-- ★★★ ESP SYSTEM ★★★
-------------------------------------------------
local function removeESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            pcall(function() obj:Destroy() end)
        end
        espObjects[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer then return end
    removeESP(player)

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local enemy   = isEnemy(player)
    local color   = enemy and CONFIG.ENEMY_COLOR or CONFIG.TEAM_COLOR
    local fillCol = enemy and CONFIG.ENEMY_FILL or CONFIG.TEAM_FILL

    local objects = {}

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name                = "ESP_HL"
    hl.Adornee             = character
    hl.FillColor           = fillCol
    hl.FillTransparency    = 0.7
    hl.OutlineColor        = color
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = character
    objects.highlight = hl

    -- Billboard
    local bb = Instance.new("BillboardGui")
    bb.Name           = "ESP_BB"
    bb.Adornee        = character:FindFirstChild("Head") or rootPart
    bb.Size           = UDim2.new(0, 200, 0, 80)
    bb.StudsOffset    = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop    = true
    bb.LightInfluence = 0
    bb.MaxDistance     = CONFIG.ESP_MAX_DIST
    bb.Parent         = character
    objects.billboard = bb

    local container = Instance.new("Frame")
    container.Size                   = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent                 = bb

    local layout = Instance.new("UIListLayout", container)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding             = UDim.new(0, 2)

    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size                   = UDim2.new(1, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextSize               = 14
    nameLabel.TextColor3             = color
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3       = Color3.new(0, 0, 0)
    nameLabel.Text                   = (enemy and "☠️ " or "👤 ") .. player.Name
    nameLabel.Parent                 = container
    objects.nameLabel = nameLabel

    -- HP bar
    local hpBg = Instance.new("Frame")
    hpBg.Size                   = UDim2.new(0.8, 0, 0, 6)
    hpBg.BackgroundColor3       = Color3.fromRGB(40, 40, 40)
    hpBg.BackgroundTransparency = 0.3
    hpBg.BorderSizePixel        = 0
    hpBg.Parent                 = container
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)
    objects.hpBg = hpBg

    local hpBar = Instance.new("Frame")
    hpBar.Size             = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    hpBar.BorderSizePixel  = 0
    hpBar.Parent           = hpBg
    Instance.new("UICorner", hpBar).CornerRadius = UDim.new(0, 3)
    objects.hpBar = hpBar

    -- HP text
    local hpText = Instance.new("TextLabel")
    hpText.Size                   = UDim2.new(1, 0, 0, 14)
    hpText.BackgroundTransparency = 1
    hpText.Font                   = Enum.Font.RobotoMono
    hpText.TextSize               = 11
    hpText.TextColor3             = Color3.new(1, 1, 1)
    hpText.TextStrokeTransparency = 0.3
    hpText.TextStrokeColor3       = Color3.new(0, 0, 0)
    hpText.Text                   = ""
    hpText.Parent                 = container
    objects.hpText = hpText

    -- Distance
    local distLabel = Instance.new("TextLabel")
    distLabel.Size                   = UDim2.new(1, 0, 0, 14)
    distLabel.BackgroundTransparency = 1
    distLabel.Font                   = Enum.Font.RobotoMono
    distLabel.TextSize               = 11
    distLabel.TextColor3             = Color3.fromRGB(200, 200, 200)
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextStrokeColor3       = Color3.new(0, 0, 0)
    distLabel.Text                   = ""
    distLabel.Parent                 = container
    objects.distLabel = distLabel

    espObjects[player] = objects
end

local function updateESP(player)
    local data = espObjects[player]
    if not data then return end

    local character = player.Character
    if not character then removeESP(player); return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then removeESP(player); return end

    local dist = getDistance(character)
    local show = dist <= CONFIG.ESP_MAX_DIST

    if data.billboard then data.billboard.Enabled = show end
    if data.highlight then data.highlight.Enabled = show end
    if not show then return end

    if data.hpBar then
        local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        data.hpBar.Size = UDim2.new(ratio, 0, 1, 0)
        if ratio > 0.6 then
            data.hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        elseif ratio > 0.3 then
            data.hpBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        else
            data.hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end

    if data.hpText then
        data.hpText.Text = string.format("❤️ %d/%d",
            math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
    end

    if data.distLabel then
        data.distLabel.Text = string.format("📏 %dm", math.floor(dist))
    end
end

local function setupPlayerESP(player)
    if player == LocalPlayer then return end

    local function onChar(character)
        task.wait(0.5)
        if espEnabled then createESP(player) end

        local hum = character:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function()
                task.wait(0.3)
                removeESP(player)
            end)
        end
    end

    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

-------------------------------------------------
-- ★ CROSSHAIR CHECK (throttled - không mỗi frame)
-------------------------------------------------
local function checkCrosshairOnEnemy()
    if not crosshairFrame or not crosshairFrame.Parent then return nil end
    if not crosshairFrame.Visible then return nil end

    local bounds = getCrosshairBounds()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not isEnemy(player) then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        for _, partName in ipairs(BODY_PARTS) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
                if onScreen and pointInBounds(sp.X, sp.Y, bounds) then
                    return player, partName, getDistance(character), humanoid
                end
            end
        end
    end

    return nil
end

-------------------------------------------------
-- ★★★ MAIN LOOP ★★★
-------------------------------------------------
local checkInterval   = 0
local CHECK_RATE      = 1 / 30   -- check 30 lần/giây thay vì 60 → giảm lag
local currentTarget   = nil

RunService.RenderStepped:Connect(function(dt)
    -- Ẩn notif
    if HitNotif.Visible and tick() > notifHideTime then
        HitNotif.Visible = false
    end

    -- ═══ UPDATE ESP (mỗi frame - nhẹ) ═══
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                updateESP(player)
            end
        end
    end

    -- ═══ AUTO-FIRE (throttled) ═══
    if not autoFireEnabled then
        if isHoldingFire then stopFire() end
        return
    end

    checkInterval += dt
    if checkInterval < CHECK_RATE then return end
    checkInterval = 0

    local hitPlayer, hitPart, dist, humanoid = checkCrosshairOnEnemy()

    if hitPlayer then
        -- ═══ ĐANG NGẮM ĐỊCH → GIỮ FIRE ═══
        startFire()

        if currentTarget ~= hitPlayer then
            currentTarget = hitPlayer

            local hp  = math.floor(humanoid.Health)
            local max = math.floor(humanoid.MaxHealth)

            showNotif(
                string.format(
                    "🔫 <b>%s</b> | %s | ❤️%d/%d | 📏%dm",
                    hitPlayer.Name, hitPart, hp, max, math.floor(dist)
                ),
                Color3.fromRGB(255, 50, 50)
            )

            print(string.format(
                "🔫 FIRE → %s [%s] HP:%d/%d Dist:%dm",
                hitPlayer.Name, hitPart, hp, max, math.floor(dist)
            ))
        end
    else
        -- ═══ KHÔNG NGẮM AI → THẢ FIRE ═══
        stopFire()

        if currentTarget then
            print("   ⏹️ Stop fire:", currentTarget.Name)
            currentTarget = nil
        end
    end

    -- Status
    StatusLabel.Text = string.format(
        '<font color="%s">%s</font> Fired:%d',
        isHoldingFire and "#FF4444" or "#88FF88",
        isHoldingFire and "🔴 FIRING" or "🟢 IDLE",
        fireCount
    )
end)

-------------------------------------------------
-- TOGGLES
-------------------------------------------------
AutoFireBtn.MouseButton1Click:Connect(function()
    autoFireEnabled = not autoFireEnabled
    if autoFireEnabled then
        AutoFireBtn.Text = "🔫 Auto-Fire: ON"
        AutoFireBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
    else
        AutoFireBtn.Text = "🔫 Auto-Fire: OFF"
        AutoFireBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        stopFire()
        currentTarget = nil
    end
end)

ESPBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        ESPBtn.Text = "👁️ ESP: ON"
        ESPBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                createESP(player)
            end
        end
    else
        ESPBtn.Text = "👁️ ESP: OFF"
        ESPBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        for _, player in ipairs(Players:GetPlayers()) do
            removeESP(player)
        end
    end
end)

-------------------------------------------------
-- PLAYER EVENTS
-------------------------------------------------
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayerESP(player)
end

Players.PlayerAdded:Connect(setupPlayerESP)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if currentTarget == player then
        stopFire()
        currentTarget = nil
    end
end)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    task.wait(0.5)
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                createESP(player)
            end
        end
    end
end)

-- Hotkey PC
if UserInputService.KeyboardEnabled then
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F4 then
            AutoFireBtn.MouseButton1Click:Fire()
        elseif input.KeyCode == Enum.KeyCode.F5 then
            ESPBtn.MouseButton1Click:Fire()
        end
    end)
end

-- ★ SAFETY: khi script bị unload → thả fire
game:BindToClose(function()
    stopFire()
end)

print("═══════════════════════════════════════")
print("  ⚡ Auto-Fire + ESP (Fixed)")
print("  🔫 Fire = ImageLabel → firetouchinterest")
print("  ✅ Giữ/Thả thay vì spam → không crash")
print("  👁️ ESP: ON | F4/F5 toggle")
print("═══════════════════════════════════════")
