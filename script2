--[[
    Auto-Fire + ESP System
    - Crosshair quét qua ĐỊCH → auto bắn
    - ESP toàn bộ player: Xanh=Team, Đỏ=Địch
    LocalScript → StarterGui
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local CONFIG = {
    -- Auto Fire
    FIRE_COOLDOWN      = 0.08,    -- giây giữa mỗi lần bắn
    CROSSHAIR_PADDING  = 18,      -- px thêm xung quanh crosshair
    FIRE_ONLY_ENEMY    = true,    -- chỉ bắn địch
    
    -- ESP
    ESP_ENABLED        = true,
    ESP_BOX            = true,    -- hộp 2D
    ESP_NAME           = true,    -- tên player
    ESP_HEALTH         = true,    -- thanh máu
    ESP_DISTANCE       = true,    -- khoảng cách
    ESP_TRACERS        = false,   -- đường kẻ từ chân màn hình
    ESP_MAX_DIST       = 1000,    -- studs tối đa hiện ESP
    
    -- Colors
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
    warn("⚠️ Không tìm thấy nút fire! Auto-fire sẽ không hoạt động")
else
    print("✅ Fire button:", fireBtn:GetFullName(), "Class:", fireBtn.ClassName)
end

print("✅ Crosshair:", crosshairFrame:GetFullName())

-------------------------------------------------
-- STATE
-------------------------------------------------
local autoFireEnabled = true
local espEnabled      = true
local lastFireTime    = 0
local overlapping     = {}
local totalKills      = 0
local espObjects      = {}  -- [player] = {highlight, billboard, ...}

-------------------------------------------------
-- GUI
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoFireESP"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 99999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = PlayerGui

-- ═══ TOGGLE PANEL ═══
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

-- Dragging cho toggle panel
local tDrag, tDragStart, tStartPos = false, nil, nil
TogglePanel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tDrag = true; tDragStart = input.Position; tStartPos = TogglePanel.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then tDrag = false end end)
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

-- Status label
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

-- ═══ HIT NOTIFICATION (giữa màn hình) ═══
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

-------------------------------------------------
-- HELPERS
-------------------------------------------------

local function isEnemy(player)
    if player == LocalPlayer then return false end
    
    -- Nếu game có team
    if LocalPlayer.Team and player.Team then
        return player.Team ~= LocalPlayer.Team
    end
    
    -- Nếu game dùng TeamColor
    if LocalPlayer.TeamColor and player.TeamColor then
        if LocalPlayer.TeamColor ~= BrickColor.new("White") then
            return player.TeamColor ~= LocalPlayer.TeamColor
        end
    end
    
    -- Không có team → coi tất cả là địch (trừ bản thân)
    return true
end

local function isTeammate(player)
    if player == LocalPlayer then return true end
    return not isEnemy(player)
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

local function showNotif(text, color)
    HitNotif.Text       = text
    HitNotif.TextColor3 = color or Color3.fromRGB(255, 80, 80)
    HitNotif.Visible    = true
    notifHideTime        = tick() + 1.2
end

-------------------------------------------------
-- ★ FIRE BUTTON TRIGGER
-------------------------------------------------
local function triggerFire()
    if not fireBtn or not fireBtn.Parent then return end
    
    -- Method 1: firetouchinterest (mobile - phổ biến nhất)
    if firetouchinterest then
        firetouchinterest(fireBtn, fireBtn, 0)  -- TouchBegan
        task.defer(function()
            if fireBtn and fireBtn.Parent then
                firetouchinterest(fireBtn, fireBtn, 1)  -- TouchEnded
            end
        end)
        return true
    end
    
    -- Method 2: fireclick
    if fireclick then
        fireclick(fireBtn)
        return true
    end
    
    -- Method 3: Simulate via VirtualInputManager
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local pos = fireBtn.AbsolutePosition + fireBtn.AbsoluteSize / 2
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.defer(function()
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end)
    
    return true
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
    
    local enemy    = isEnemy(player)
    local color    = enemy and CONFIG.ENEMY_COLOR or CONFIG.TEAM_COLOR
    local fillCol  = enemy and CONFIG.ENEMY_FILL or CONFIG.TEAM_FILL
    
    local objects = {}
    
    -- ═══ HIGHLIGHT (viền sáng quanh character) ═══
    local highlight = Instance.new("Highlight")
    highlight.Name            = "ESP_Highlight"
    highlight.Adornee         = character
    highlight.FillColor       = fillCol
    highlight.FillTransparency = 0.7
    highlight.OutlineColor    = color
    highlight.OutlineTransparency = 0
    highlight.DepthMode       = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent          = character
    objects.highlight = highlight
    
    -- ═══ BILLBOARD GUI (tên + HP + khoảng cách) ═══
    local billboard = Instance.new("BillboardGui")
    billboard.Name            = "ESP_Info"
    billboard.Adornee         = character:FindFirstChild("Head") or rootPart
    billboard.Size            = UDim2.new(0, 200, 0, 80)
    billboard.StudsOffset     = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop     = true
    billboard.LightInfluence  = 0
    billboard.MaxDistance      = CONFIG.ESP_MAX_DIST
    billboard.Parent          = character
    objects.billboard = billboard
    
    -- Container
    local container = Instance.new("Frame")
    container.Size                   = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent                 = billboard
    
    local layout = Instance.new("UIListLayout", container)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding             = UDim.new(0, 2)
    
    -- ★ Tên player
    if CONFIG.ESP_NAME then
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
    end
    
    -- ★ Thanh máu
    if CONFIG.ESP_HEALTH then
        local hpBg = Instance.new("Frame")
        hpBg.Size                   = UDim2.new(0.8, 0, 0, 6)
        hpBg.BackgroundColor3       = Color3.fromRGB(40, 40, 40)
        hpBg.BackgroundTransparency = 0.3
        hpBg.BorderSizePixel        = 0
        hpBg.Parent                 = container
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)
        objects.hpBg = hpBg
        
        local hpBar = Instance.new("Frame")
        hpBar.Size                   = UDim2.new(1, 0, 1, 0)
        hpBar.BackgroundColor3       = Color3.fromRGB(0, 255, 0)
        hpBar.BackgroundTransparency = 0
        hpBar.BorderSizePixel        = 0
        hpBar.Parent                 = hpBg
        Instance.new("UICorner", hpBar).CornerRadius = UDim.new(0, 3)
        objects.hpBar = hpBar
        
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
    end
    
    -- ★ Khoảng cách
    if CONFIG.ESP_DISTANCE then
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
    end
    
    espObjects[player] = objects
end

-- Cập nhật ESP mỗi frame
local function updateESP(player)
    local data = espObjects[player]
    if not data then return end
    
    local character = player.Character
    if not character then removeESP(player); return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then removeESP(player); return end
    
    local dist = getDistance(character)
    if dist > CONFIG.ESP_MAX_DIST then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        return
    else
        if data.billboard then data.billboard.Enabled = true end
        if data.highlight then data.highlight.Enabled = true end
    end
    
    -- Update HP bar
    if data.hpBar then
        local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        data.hpBar.Size = UDim2.new(ratio, 0, 1, 0)
        
        -- Đổi màu thanh máu theo %
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

-- Tạo ESP cho player mới / respawn
local function setupPlayerESP(player)
    if player == LocalPlayer then return end
    
    local function onCharacterAdded(character)
        task.wait(0.5) -- đợi character load
        if espEnabled then
            createESP(player)
        end
        
        -- Khi chết → xoá ESP rồi tạo lại khi respawn
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.Died:Connect(function()
                task.wait(0.3)
                removeESP(player)
            end)
        end
    end
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

-------------------------------------------------
-- ★ CROSSHAIR → ENEMY DETECTION
-------------------------------------------------
local function checkCrosshairOnPlayers()
    if not crosshairFrame or not crosshairFrame.Parent then return nil end
    if not crosshairFrame.Visible then return nil end
    
    local bounds = getCrosshairBounds()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local character = player.Character
            if not character then continue end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end
            
            for _, partName in ipairs(BODY_PARTS) do
                local part = character:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
                    if onScreen and pointInBounds(screenPos.X, screenPos.Y, bounds) then
                        return player, partName, getDistance(character), humanoid
                    end
                    
                    -- Top/Bottom of part
                    local top = part.Position + Vector3.new(0, part.Size.Y/2, 0)
                    local sp1, on1 = Camera:WorldToScreenPoint(top)
                    if on1 and pointInBounds(sp1.X, sp1.Y, bounds) then
                        return player, partName, getDistance(character), humanoid
                    end
                end
            end
        end
    end
    
    return nil
end

-------------------------------------------------
-- ★★★ MAIN LOOP ★★★
-------------------------------------------------
local fireCount    = 0
local enemyOnAim   = nil
local aimStartTime = 0

RunService.RenderStepped:Connect(function()
    -- Hide notif
    if HitNotif.Visible and tick() > notifHideTime then
        HitNotif.Visible = false
    end
    
    -- ═══ UPDATE ESP ═══
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                updateESP(player)
            end
        end
    end
    
    -- ═══ AUTO-FIRE ═══
    if autoFireEnabled then
        local hitPlayer, hitPart, dist, humanoid = checkCrosshairOnPlayers()
        
        if hitPlayer then
            -- Crosshair trên địch!
            local now = tick()
            
            if enemyOnAim ~= hitPlayer then
                enemyOnAim   = hitPlayer
                aimStartTime = now
            end
            
            -- Fire nếu đủ cooldown
            if now - lastFireTime >= CONFIG.FIRE_COOLDOWN then
                local fired = triggerFire()
                if fired then
                    lastFireTime = now
                    fireCount   += 1
                end
                
                -- Notification
                if not overlapping[hitPlayer.Name] then
                    overlapping[hitPlayer.Name] = true
                    
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
                        "🔫 AUTO-FIRE → %s [%s] HP:%d/%d Dist:%dm",
                        hitPlayer.Name, hitPart, hp, max, math.floor(dist)
                    ))
                end
            end
        else
            -- Không ai trên crosshair
            if enemyOnAim then
                local name = enemyOnAim.Name
                if overlapping[name] then
                    overlapping[name] = nil
                end
                enemyOnAim = nil
            end
        end
    end
    
    -- ═══ STATUS UPDATE ═══
    StatusLabel.Text = string.format(
        '<font color="#FF8888">Fired: %d</font>',
        fireCount
    )
end)

-------------------------------------------------
-- TOGGLE BUTTONS
-------------------------------------------------
AutoFireBtn.MouseButton1Click:Connect(function()
    autoFireEnabled = not autoFireEnabled
    if autoFireEnabled then
        AutoFireBtn.Text = "🔫 Auto-Fire: ON"
        AutoFireBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
    else
        AutoFireBtn.Text = "🔫 Auto-Fire: OFF"
        AutoFireBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        overlapping = {}
        enemyOnAim  = nil
    end
end)

ESPBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        ESPBtn.Text = "👁️ ESP: ON"
        ESPBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
        -- Tạo lại ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                createESP(player)
            end
        end
    else
        ESPBtn.Text = "👁️ ESP: OFF"
        ESPBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        -- Xoá hết ESP
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

Players.PlayerAdded:Connect(function(player)
    setupPlayerESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    overlapping[player.Name] = nil
end)

-- Team change → update ESP color
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

-------------------------------------------------
-- HOTKEY (PC)
-------------------------------------------------
if UserInputService.KeyboardEnabled then
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        
        -- F4: Toggle Auto-Fire
        if input.KeyCode == Enum.KeyCode.F4 then
            AutoFireBtn.MouseButton1Click:Fire()
        end
        
        -- F5: Toggle ESP
        if input.KeyCode == Enum.KeyCode.F5 then
            ESPBtn.MouseButton1Click:Fire()
        end
    end)
end

-------------------------------------------------
print("═══════════════════════════════════════")
print("  ⚡ Auto-Fire + ESP System Loaded")
print("  🔫 Auto-Fire: ON (F4 toggle)")
print("  👁️ ESP: ON (F5 toggle)")
print("  🎯 Crosshair: cursor.Frame")
print("  🔘 Fire: mobile.weapon.fire.fire")
print("═══════════════════════════════════════")
