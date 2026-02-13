--[[
    Auto-Fire + ESP + Crosshair Detection
    LocalScript → StarterGui
    
    ★ Auto-fire khi crosshair quẹt qua địch
    ★ ESP: Xanh lá = đồng đội, Đỏ = địch
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
    -- Auto-Fire
    FIRE_RATE        = 0.05,   -- giây giữa mỗi phát (0.05 = 20 phát/giây)
    CROSSHAIR_PAD    = 15,     -- padding quanh crosshair (px)

    -- ESP
    ESP_FILL_TRANSP  = 0.65,   -- độ trong suốt fill highlight
    ESP_OUT_TRANSP   = 0.1,    -- độ trong suốt outline
    HP_BAR_WIDTH     = 160,    -- chiều rộng thanh máu
    BILLBOARD_OFFSET = Vector3.new(0, 2.8, 0),

    -- Colors
    ENEMY_COLOR      = Color3.fromRGB(255, 30, 30),
    ALLY_COLOR       = Color3.fromRGB(30, 255, 30),

    -- Body parts để check crosshair
    BODY_PARTS = {
        "Head", "HumanoidRootPart",
        "UpperTorso", "LowerTorso", "Torso",
        "Left Arm", "Right Arm", "Left Leg", "Right Leg",
        "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
        "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg",
    },
}

-------------------------------------------------
-- STATE
-------------------------------------------------
local espEnabled      = true
local autoFireEnabled = true
local lastFireTime    = 0
local overlapping     = {}   -- [playerName] = true
local espData         = {}   -- [playerName] = {highlight, billboard, ...}
local totalHits       = 0

-------------------------------------------------
-- TÌM CROSSHAIR + FIRE BUTTON
-------------------------------------------------
local cursorGui = PlayerGui:WaitForChild("cursor", 15)
local crosshairFrame = cursorGui and cursorGui:WaitForChild("Frame", 10)

if not crosshairFrame then
    warn("❌ Không tìm thấy cursor.Frame!")
    return
end
print("✅ Crosshair:", crosshairFrame:GetFullName())

-- Fire button
local mobileGui   = PlayerGui:WaitForChild("mobile", 15)
local weaponFrame = mobileGui and mobileGui:WaitForChild("weapon", 10)
local fireParent  = weaponFrame and weaponFrame:WaitForChild("fire", 10)
local fireButton  = fireParent and fireParent:WaitForChild("fire", 10)

if not fireButton then
    warn("⚠️ Không tìm thấy fire button! Auto-fire sẽ không hoạt động.")
else
    print("✅ Fire button:", fireButton:GetFullName())
    print("   Class:", fireButton.ClassName)
    print("   Size:", fireButton.AbsoluteSize)
end

-------------------------------------------------
-- GUI
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoFireESP"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 99998
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

-- ═══════════════════════════════════════
-- TOGGLE BUTTONS
-- ═══════════════════════════════════════
local function makeToggle(name, text, posY, defaultOn, color)
    local btn = Instance.new("TextButton")
    btn.Name              = name
    btn.Size              = UDim2.new(0, 160, 0, 42)
    btn.Position           = UDim2.new(0, 12, 0, posY)
    btn.BackgroundColor3  = defaultOn and color or Color3.fromRGB(60, 60, 60)
    btn.TextColor3        = Color3.new(1, 1, 1)
    btn.Font              = Enum.Font.GothamBold
    btn.TextSize          = 13
    btn.Text              = text .. (defaultOn and " ON" or " OFF")
    btn.BorderSizePixel   = 0
    btn.ZIndex            = 100
    btn.Parent            = ScreenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.new(1,1,1); s.Transparency = 0.6; s.Thickness = 1.5
    return btn
end

local espBtn  = makeToggle("ESPToggle",  "👁️ ESP",  45, true,  Color3.fromRGB(0, 130, 70))
local fireBtn = makeToggle("FireToggle", "🔫 FIRE", 95, true,  Color3.fromRGB(180, 30, 30))

-- Notification label
local NotifLabel = Instance.new("TextLabel")
NotifLabel.Size                   = UDim2.new(0, 420, 0, 48)
NotifLabel.Position               = UDim2.new(0.5, -210, 0, 10)
NotifLabel.AnchorPoint            = Vector2.new(0, 0)
NotifLabel.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
NotifLabel.BackgroundTransparency = 0.4
NotifLabel.TextColor3             = Color3.fromRGB(255, 80, 80)
NotifLabel.Font                   = Enum.Font.GothamBold
NotifLabel.TextSize               = 16
NotifLabel.Text                   = ""
NotifLabel.Visible                = false
NotifLabel.BorderSizePixel        = 0
NotifLabel.ZIndex                 = 100
NotifLabel.RichText               = true
NotifLabel.Parent                 = ScreenGui
Instance.new("UICorner", NotifLabel).CornerRadius = UDim.new(0, 10)

-- Stats label
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size                   = UDim2.new(0, 160, 0, 30)
StatsLabel.Position               = UDim2.new(0, 12, 0, 145)
StatsLabel.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
StatsLabel.BackgroundTransparency = 0.5
StatsLabel.TextColor3             = Color3.fromRGB(100, 255, 100)
StatsLabel.Font                   = Enum.Font.RobotoMono
StatsLabel.TextSize               = 12
StatsLabel.Text                   = "Hits: 0  |  Firing: ❌"
StatsLabel.BorderSizePixel        = 0
StatsLabel.ZIndex                 = 100
StatsLabel.RichText               = true
StatsLabel.Parent                 = ScreenGui
Instance.new("UICorner", StatsLabel).CornerRadius = UDim.new(0, 8)

local notifHideTime = 0

local function showNotif(text, color)
    NotifLabel.Text       = text
    NotifLabel.TextColor3 = color or Color3.fromRGB(255, 80, 80)
    NotifLabel.Visible    = true
    notifHideTime         = tick() + 1.2
end

-------------------------------------------------
-- TEAM DETECTION
-------------------------------------------------
local function isEnemy(player)
    if player == LocalPlayer then return false end

    -- Nếu game có hệ thống Team
    if LocalPlayer.Team and player.Team then
        return player.Team ~= LocalPlayer.Team
    end

    -- Nếu không có team → xem tất cả là địch
    return true
end

local function getPlayerColor(player)
    if isEnemy(player) then
        return CONFIG.ENEMY_COLOR
    else
        return CONFIG.ALLY_COLOR
    end
end

-------------------------------------------------
-- ★ ESP SYSTEM
-------------------------------------------------
local function createESP(player)
    if player == LocalPlayer then return end
    if espData[player.Name] then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    local color  = getPlayerColor(player)
    local enemy  = isEnemy(player)

    -- ═══ Highlight ═══
    local hl = Instance.new("Highlight")
    hl.Name              = "_ESP_HL"
    hl.FillColor         = color
    hl.OutlineColor      = color
    hl.FillTransparency  = CONFIG.ESP_FILL_TRANSP
    hl.OutlineTransparency = CONFIG.ESP_OUT_TRANSP
    hl.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee           = character
    hl.Parent            = character

    -- ═══ BillboardGui ═══
    local bb = Instance.new("BillboardGui")
    bb.Name          = "_ESP_BB"
    bb.Adornee       = head
    bb.Size          = UDim2.new(0, CONFIG.HP_BAR_WIDTH, 0, 55)
    bb.StudsOffset   = CONFIG.BILLBOARD_OFFSET
    bb.AlwaysOnTop   = true
    bb.Parent        = character

    -- Team indicator
    local teamIcon = Instance.new("TextLabel")
    teamIcon.Size                   = UDim2.new(0, 20, 0, 16)
    teamIcon.Position               = UDim2.new(0, 0, 0, 0)
    teamIcon.BackgroundTransparency = 1
    teamIcon.Font                   = Enum.Font.GothamBold
    teamIcon.TextSize               = 14
    teamIcon.TextColor3             = color
    teamIcon.Text                   = enemy and "⚔️" or "🛡️"
    teamIcon.TextStrokeTransparency = 0
    teamIcon.TextStrokeColor3       = Color3.new(0, 0, 0)
    teamIcon.ZIndex                 = 10
    teamIcon.Parent                 = bb

    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name                   = "NameLabel"
    nameLabel.Size                   = UDim2.new(1, -22, 0, 16)
    nameLabel.Position               = UDim2.new(0, 22, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextSize               = 13
    nameLabel.TextColor3             = color
    nameLabel.Text                   = player.DisplayName
    nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3       = Color3.new(0, 0, 0)
    nameLabel.ZIndex                 = 10
    nameLabel.Parent                 = bb

    -- HP bar background
    local hpBg = Instance.new("Frame")
    hpBg.Name              = "HpBg"
    hpBg.Size              = UDim2.new(1, 0, 0, 7)
    hpBg.Position           = UDim2.new(0, 0, 0, 18)
    hpBg.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
    hpBg.BackgroundTransparency = 0.3
    hpBg.BorderSizePixel   = 0
    hpBg.ZIndex            = 10
    hpBg.Parent            = bb
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)
    local hpBgStroke = Instance.new("UIStroke", hpBg)
    hpBgStroke.Color = Color3.new(0,0,0); hpBgStroke.Thickness = 1

    -- HP bar fill
    local hpRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local hpFill = Instance.new("Frame")
    hpFill.Name              = "HpFill"
    hpFill.Size              = UDim2.new(hpRatio, 0, 1, 0)
    hpFill.BackgroundColor3  = Color3.fromRGB(0, 255, 0)
    hpFill.BorderSizePixel   = 0
    hpFill.ZIndex            = 11
    hpFill.Parent            = hpBg
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 3)

    -- HP text
    local hpText = Instance.new("TextLabel")
    hpText.Name                   = "HpText"
    hpText.Size                   = UDim2.new(1, 0, 0, 14)
    hpText.Position               = UDim2.new(0, 0, 0, 26)
    hpText.BackgroundTransparency = 1
    hpText.Font                   = Enum.Font.RobotoMono
    hpText.TextSize               = 11
    hpText.TextColor3             = Color3.fromRGB(220, 220, 220)
    hpText.Text                   = string.format("HP: %d/%d", humanoid.Health, humanoid.MaxHealth)
    hpText.TextStrokeTransparency = 0
    hpText.TextStrokeColor3       = Color3.new(0, 0, 0)
    hpText.ZIndex                 = 10
    hpText.Parent                 = bb

    -- Distance
    local distLabel = Instance.new("TextLabel")
    distLabel.Name                   = "DistLabel"
    distLabel.Size                   = UDim2.new(1, 0, 0, 14)
    distLabel.Position               = UDim2.new(0, 0, 0, 40)
    distLabel.BackgroundTransparency = 1
    distLabel.Font                   = Enum.Font.RobotoMono
    distLabel.TextSize               = 10
    distLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
    distLabel.Text                   = "[0m]"
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3       = Color3.new(0, 0, 0)
    distLabel.ZIndex                 = 10
    distLabel.Parent                 = bb

    -- HP change connection
    local hpConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        local r = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        hpFill.Size = UDim2.new(r, 0, 1, 0)

        if r > 0.6 then
            hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        elseif r > 0.3 then
            hpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        else
            hpFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end

        hpText.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
    end)

    -- Death → remove ESP
    local diedConn
    diedConn = humanoid.Died:Connect(function()
        removeESP(player.Name)
    end)

    espData[player.Name] = {
        highlight = hl,
        billboard = bb,
        hpFill    = hpFill,
        hpText    = hpText,
        distLabel = distLabel,
        nameLabel = nameLabel,
        hpConn    = hpConn,
        diedConn  = diedConn,
        player    = player,
        enemy     = enemy,
    }

    print(string.format("  📡 ESP created: %s [%s]",
        player.Name, enemy and "ENEMY 🔴" or "ALLY 🟢"))
end

function removeESP(playerName)
    local data = espData[playerName]
    if not data then return end

    pcall(function() data.hpConn:Disconnect() end)
    pcall(function() data.diedConn:Disconnect() end)
    pcall(function() data.highlight:Destroy() end)
    pcall(function() data.billboard:Destroy() end)

    espData[playerName] = nil
end

local function removeAllESP()
    for name, _ in pairs(espData) do
        removeESP(name)
    end
end

local function refreshAllESP()
    removeAllESP()
    if not espEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createESP(player)
        end
    end
end

local function updateESPVisibility()
    for _, data in pairs(espData) do
        if data.highlight and data.highlight.Parent then
            data.highlight.Enabled = espEnabled
        end
        if data.billboard and data.billboard.Parent then
            data.billboard.Enabled = espEnabled
        end
    end
end

-- Update distances
local function updateESPDistances()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, data in pairs(espData) do
        if data.distLabel and data.distLabel.Parent and data.player.Character then
            local theirRoot = data.player.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                local dist = math.floor((myRoot.Position - theirRoot.Position).Magnitude)
                data.distLabel.Text = string.format("[%dm]", dist)
            end
        end
    end
end

-------------------------------------------------
-- ★ FIRE BUTTON TRIGGER
-------------------------------------------------
local function triggerFireButton()
    if not fireButton then return false end
    if not fireButton.Parent then return false end

    -- Method 1: getconnections (exploit)
    local ok = pcall(function()
        for _, c in next, getconnections(fireButton.Activated) do
            c:Fire()
        end
    end)
    if ok then return true end

    -- Method 2: getconnections MouseButton1Click
    ok = pcall(function()
        for _, c in next, getconnections(fireButton.MouseButton1Click) do
            c:Fire()
        end
    end)
    if ok then return true end

    -- Method 3: getconnections MouseButton1Down
    ok = pcall(function()
        for _, c in next, getconnections(fireButton.MouseButton1Down) do
            c:Fire()
        end
    end)
    if ok then return true end

    -- Method 4: VirtualInputManager
    ok = pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local pos = fireButton.AbsolutePosition + fireButton.AbsoluteSize / 2
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.defer(function()
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end)
    if ok then return true end

    -- Method 5: Signal Fire (some executors)
    pcall(function()
        fireButton.MouseButton1Click:Fire()
    end)

    return false
end

-------------------------------------------------
-- CROSSHAIR DETECTION HELPERS
-------------------------------------------------
local function getScreenCenter()
    local vs = Camera.ViewportSize
    return Vector2.new(vs.X / 2, vs.Y / 2)
end

local function getCrosshairBounds()
    local pos  = crosshairFrame.AbsolutePosition
    local size = crosshairFrame.AbsoluteSize
    local pad  = CONFIG.CROSSHAIR_PAD
    return {
        x1 = pos.X - pad,
        y1 = pos.Y - pad,
        x2 = pos.X + size.X + pad,
        y2 = pos.Y + size.Y + pad,
        cx = pos.X + size.X / 2,
        cy = pos.Y + size.Y / 2,
    }
end

local function pointInBounds(px, py, bounds)
    return px >= bounds.x1 and px <= bounds.x2
       and py >= bounds.y1 and py <= bounds.y2
end

local function getCharScreenPoints(character)
    local points = {}
    for _, partName in ipairs(CONFIG.BODY_PARTS) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
            if onScreen then
                table.insert(points, {x = sp.X, y = sp.Y, part = partName})
            end
            -- Top + bottom
            local top = part.Position + Vector3.new(0, part.Size.Y / 2, 0)
            local bot = part.Position - Vector3.new(0, part.Size.Y / 2, 0)
            local sp1, on1 = Camera:WorldToScreenPoint(top)
            if on1 then table.insert(points, {x = sp1.X, y = sp1.Y, part = partName.."↑"}) end
            local sp2, on2 = Camera:WorldToScreenPoint(bot)
            if on2 then table.insert(points, {x = sp2.X, y = sp2.Y, part = partName.."↓"}) end
        end
    end
    return points
end

local function getDistance(character)
    local myChar = LocalPlayer.Character
    if not myChar then return math.huge end
    local a = myChar:FindFirstChild("HumanoidRootPart")
    local b = character:FindFirstChild("HumanoidRootPart")
    if a and b then return (a.Position - b.Position).Magnitude end
    return math.huge
end

-------------------------------------------------
-- ★★★ MAIN LOOP ★★★
-------------------------------------------------
local currentlyFiring = false

RunService.RenderStepped:Connect(function()
    -- Ẩn notif
    if NotifLabel.Visible and tick() > notifHideTime then
        NotifLabel.Visible = false
    end

    -- Update ESP distances
    if espEnabled then
        updateESPDistances()
    end

    -- Check crosshair
    if not crosshairFrame or not crosshairFrame.Parent then return end
    if not crosshairFrame.Visible then return end

    local bounds       = getCrosshairBounds()
    local anyEnemyHit  = false
    local hitEnemyName = ""
    local hitPart      = ""

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid  = character and character:FindFirstChildOfClass("Humanoid")

            if character and humanoid and humanoid.Health > 0 then
                local enemy  = isEnemy(player)
                local points = getCharScreenPoints(character)
                local hit    = false
                local bestPart = ""
                local bestDist = math.huge

                for _, pt in ipairs(points) do
                    if pointInBounds(pt.x, pt.y, bounds) then
                        local d = math.sqrt((pt.x - bounds.cx)^2 + (pt.y - bounds.cy)^2)
                        if d < bestDist then
                            bestDist = d
                            bestPart = pt.part
                            hit      = true
                        end
                    end
                end

                if hit then
                    -- ═══ CROSSHAIR ON PLAYER ═══
                    if not overlapping[player.Name] then
                        overlapping[player.Name] = true
                        totalHits += 1

                        local dist3D = math.floor(getDistance(character))
                        local hp     = math.floor(humanoid.Health)
                        local maxHp  = math.floor(humanoid.MaxHealth)
                        local tag    = enemy and "⚔️ ENEMY" or "🛡️ ALLY"

                        print("═══════════════════════════════════════")
                        print(string.format("🎯 %s: %s", tag, player.Name))
                        print(string.format("   Part: %s | HP: %d/%d | Dist: %dm",
                            bestPart, hp, maxHp, dist3D))
                        print("═══════════════════════════════════════")

                        showNotif(string.format(
                            "🎯 %s <b>%s</b> | %s | ❤️%d/%d | %dm",
                            tag, player.Name, bestPart, hp, maxHp, dist3D
                        ), enemy and CONFIG.ENEMY_COLOR or CONFIG.ALLY_COLOR)
                    end

                    -- ★ AUTO-FIRE: chỉ bắn địch
                    if enemy and autoFireEnabled then
                        anyEnemyHit  = true
                        hitEnemyName = player.Name
                        hitPart      = bestPart
                    end
                else
                    if overlapping[player.Name] then
                        overlapping[player.Name] = nil
                    end
                end
            else
                overlapping[player.Name] = nil
            end
        end
    end

    -- ═══ TRIGGER FIRE ═══
    if anyEnemyHit and autoFireEnabled then
        if tick() - lastFireTime >= CONFIG.FIRE_RATE then
            lastFireTime = tick()
            triggerFireButton()
            currentlyFiring = true
        end
    else
        currentlyFiring = false
    end

    -- Update stats
    StatsLabel.Text = string.format(
        '<font color="#88FF88">Hits:%d</font> | <font color="%s">Fire:%s</font>',
        totalHits,
        currentlyFiring and "#FF4444" or "#888888",
        currentlyFiring and "🔥" or "❌"
    )
end)

-------------------------------------------------
-- TOGGLE BUTTONS
-------------------------------------------------
local function updateBtnVisual(btn, isOn, onColor, label)
    btn.BackgroundColor3 = isOn and onColor or Color3.fromRGB(60, 60, 60)
    btn.Text = label .. (isOn and " ON" or " OFF")
end

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    updateBtnVisual(espBtn, espEnabled, Color3.fromRGB(0, 130, 70), "👁️ ESP")

    if espEnabled then
        refreshAllESP()
        showNotif("👁️ ESP <b>BẬT</b>", CONFIG.ALLY_COLOR)
    else
        removeAllESP()
        showNotif("👁️ ESP <b>TẮT</b>", Color3.fromRGB(150, 150, 150))
    end

    print("👁️ ESP:", espEnabled and "ON" or "OFF")
end)

fireBtn.MouseButton1Click:Connect(function()
    autoFireEnabled = not autoFireEnabled
    updateBtnVisual(fireBtn, autoFireEnabled, Color3.fromRGB(180, 30, 30), "🔫 FIRE")

    if autoFireEnabled then
        showNotif("🔫 Auto-Fire <b>BẬT</b>", CONFIG.ENEMY_COLOR)
    else
        currentlyFiring = false
        showNotif("🔫 Auto-Fire <b>TẮT</b>", Color3.fromRGB(150, 150, 150))
    end

    print("🔫 Auto-Fire:", autoFireEnabled and "ON" or "OFF")
end)

-------------------------------------------------
-- PLAYER EVENTS → ESP
-------------------------------------------------
local function onCharacterAdded(player, character)
    if player == LocalPlayer then return end

    -- Đợi humanoid load
    local humanoid = character:WaitForChild("Humanoid", 10)
    local head     = character:WaitForChild("Head", 10)
    if not humanoid or not head then return end

    task.wait(0.5) -- đợi model load đầy đủ

    if espEnabled then
        removeESP(player.Name)
        createESP(player)
    end
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end

    if player.Character then
        onCharacterAdded(player, player.Character)
    end

    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
end

local function onPlayerRemoving(player)
    removeESP(player.Name)
    overlapping[player.Name] = nil
end

-- Setup existing players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        onPlayerAdded(player)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Team change → refresh ESP colors
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    print("🔄 Team changed → refreshing ESP")
    task.wait(0.5)
    refreshAllESP()
end)

-------------------------------------------------
print("═══════════════════════════════════════")
print("  🎯 Auto-Fire + ESP Loaded")
print("  Crosshair: cursor.Frame")
print("  Fire btn:  mobile.weapon.fire.fire")
print("  Fire rate: " .. CONFIG.FIRE_RATE .. "s")
print("")
print("  👁️ ESP:       ON  (toggle button)")
print("  🔫 Auto-Fire: ON  (toggle button)")
print("  🟢 Ally = Green  |  🔴 Enemy = Red")
print("═══════════════════════════════════════")
