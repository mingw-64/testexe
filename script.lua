--[[
    Crosshair Detector + Auto-Fire + ESP v3.0
    LocalScript → StarterGui
    [F1] Toggle Auto-Fire
    [F2] Toggle ESP
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

-- ═══════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════
local PADDING    = 15
local FIRE_RATE  = 0.1    -- giây giữa mỗi lần bắn

-- Chỉ check ít part → giảm lag
local CHECK_PARTS = {
    "Head", "HumanoidRootPart", "UpperTorso", "Torso",
}

local autofireOn = true
local espOn      = true

-- ═══════════════════════════════════════════════
-- TÌM CROSSHAIR
-- ═══════════════════════════════════════════════
local cursorGui      = PlayerGui:WaitForChild("cursor", 10)
local crosshairFrame = cursorGui and cursorGui:WaitForChild("Frame", 10)
if not crosshairFrame then
    warn("Khong tim thay cursor.Frame!")
    return
end

-- ═══════════════════════════════════════════════
-- TÌM NÚT FIRE
-- ═══════════════════════════════════════════════
local fireButton = nil

local function findFireButton()
    if fireButton and fireButton.Parent then return true end
    fireButton = nil
    local ok, _ = pcall(function()
        fireButton = PlayerGui
            :WaitForChild("mobile", 3)
            :WaitForChild("weapon", 3)
            :WaitForChild("fire", 3)
            :WaitForChild("fire", 3)
    end)
    return fireButton ~= nil
end

task.spawn(function()
    findFireButton()
    if fireButton then
        print("Fire button found:", fireButton:GetFullName())
    end
end)

-- ═══════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════
local function isEnemy(player)
    if LocalPlayer.Team and player.Team then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

local function getTeamColor(player)
    return isEnemy(player)
        and Color3.fromRGB(255, 0, 0)
        or  Color3.fromRGB(0, 255, 0)
end

local function getDistance(character)
    local myChar = LocalPlayer.Character
    if not myChar then return 999 end
    local a = myChar:FindFirstChild("HumanoidRootPart")
    local b = character:FindFirstChild("HumanoidRootPart")
    if a and b then return (a.Position - b.Position).Magnitude end
    return 999
end

-- ═══════════════════════════════════════════════
-- NOTIFICATION GUI (đơn giản)
-- ═══════════════════════════════════════════════
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name            = "CrosshairNotif"
NotifGui.ResetOnSpawn    = false
NotifGui.DisplayOrder    = 99998
NotifGui.IgnoreGuiInset  = true
NotifGui.Parent          = PlayerGui

local NotifLabel = Instance.new("TextLabel")
NotifLabel.Size                   = UDim2.new(0, 440, 0, 50)
NotifLabel.Position               = UDim2.new(0.5, -220, 0, 80)
NotifLabel.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
NotifLabel.BackgroundTransparency = 0.4
NotifLabel.TextColor3             = Color3.fromRGB(255, 80, 80)
NotifLabel.Font                   = Enum.Font.GothamBold
NotifLabel.TextSize               = 18
NotifLabel.Text                   = ""
NotifLabel.Visible                = false
NotifLabel.BorderSizePixel        = 0
NotifLabel.RichText               = true
NotifLabel.Parent                 = NotifGui
Instance.new("UICorner", NotifLabel).CornerRadius = UDim.new(0, 10)

local HitCounter = Instance.new("TextLabel")
HitCounter.Size                   = UDim2.new(0, 200, 0, 30)
HitCounter.Position               = UDim2.new(0.5, -100, 0, 135)
HitCounter.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
HitCounter.BackgroundTransparency = 0.5
HitCounter.TextColor3             = Color3.fromRGB(100, 255, 100)
HitCounter.Font                   = Enum.Font.RobotoMono
HitCounter.TextSize               = 14
HitCounter.Text                   = "Hits: 0"
HitCounter.Visible                = true
HitCounter.BorderSizePixel        = 0
HitCounter.RichText               = true
HitCounter.Parent                 = NotifGui
Instance.new("UICorner", HitCounter).CornerRadius = UDim.new(0, 8)

local notifHideTime = 0
local totalHits     = 0

local function showNotif(text, color)
    NotifLabel.Text       = text
    NotifLabel.TextColor3 = color or Color3.fromRGB(255, 80, 80)
    NotifLabel.Visible    = true
    notifHideTime         = tick() + 1.5
end

-- ═══════════════════════════════════════════════
-- STATUS PANEL (góc trên-trái)
-- ═══════════════════════════════════════════════
local StatusGui = Instance.new("ScreenGui")
StatusGui.Name           = "StatusPanel"
StatusGui.ResetOnSpawn   = false
StatusGui.DisplayOrder   = 99999
StatusGui.IgnoreGuiInset = true
StatusGui.Parent         = PlayerGui

local sFrame = Instance.new("Frame")
sFrame.Size                   = UDim2.new(0, 240, 0, 70)
sFrame.Position               = UDim2.new(0, 10, 0, 10)
sFrame.BackgroundColor3       = Color3.fromRGB(12, 12, 12)
sFrame.BackgroundTransparency = 0.15
sFrame.BorderSizePixel        = 0
sFrame.Parent                 = StatusGui
Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 10)

local afLbl = Instance.new("TextLabel")
afLbl.Size = UDim2.new(1, -10, 0, 20)
afLbl.Position = UDim2.new(0, 5, 0, 5)
afLbl.BackgroundTransparency = 1
afLbl.Font = Enum.Font.RobotoMono
afLbl.TextSize = 13
afLbl.TextXAlignment = Enum.TextXAlignment.Left
afLbl.RichText = true
afLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
afLbl.Parent = sFrame

local esLbl = afLbl:Clone()
esLbl.Position = UDim2.new(0, 5, 0, 26)
esLbl.Parent = sFrame

local tgtLbl = afLbl:Clone()
tgtLbl.Position = UDim2.new(0, 5, 0, 47)
tgtLbl.Parent = sFrame

local currentTarget = nil

local function refreshStatus()
    afLbl.Text = autofireOn
        and '[F1] AutoFire: <font color="#00FF00">ON</font>'
        or  '[F1] AutoFire: <font color="#FF4444">OFF</font>'
    esLbl.Text = espOn
        and '[F2] ESP: <font color="#00FF00">ON</font>'
        or  '[F2] ESP: <font color="#FF4444">OFF</font>'
    tgtLbl.Text = currentTarget
        and string.format('Target: <font color="#FF6644">%s</font>', currentTarget.Name)
        or  'Target: <font color="#666">None</font>'
end
refreshStatus()

-- ═══════════════════════════════════════════════
-- ESP SYSTEM (tách riêng, KHÔNG chạy trong RenderStepped)
-- ═══════════════════════════════════════════════
local espCache = {} -- [Player] = { highlight, billboard }

local function destroyESP(player)
    local d = espCache[player]
    if not d then return end
    if d.highlight then d.highlight:Destroy() end
    if d.billboard then d.billboard:Destroy() end
    espCache[player] = nil
end

local function buildESP(player)
    if player == LocalPlayer then return end
    destroyESP(player) -- xoá cũ trước

    local char = player.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hum or not head then return end

    local col = getTeamColor(player)
    local tag = isEnemy(player) and "ENEMY" or "ALLY"

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.FillColor           = col
    hl.FillTransparency    = 0.55
    hl.OutlineColor        = col
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled             = espOn
    hl.Adornee             = char
    hl.Parent              = char

    -- Billboard
    local bb = Instance.new("BillboardGui")
    bb.Adornee     = head
    bb.Size        = UDim2.new(0, 180, 0, 52)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Enabled     = espOn
    bb.Parent      = head -- parent vào head, tự huỷ khi char mất

    local nameL = Instance.new("TextLabel")
    nameL.Name                   = "N"
    nameL.Size                   = UDim2.new(1, 0, 0, 18)
    nameL.BackgroundTransparency = 1
    nameL.TextColor3             = col
    nameL.Font                   = Enum.Font.GothamBold
    nameL.TextSize               = 14
    nameL.Text                   = player.Name .. " [" .. tag .. "]"
    nameL.TextStrokeTransparency = 0
    nameL.TextStrokeColor3       = Color3.new(0, 0, 0)
    nameL.Parent                 = bb

    local infoL = Instance.new("TextLabel")
    infoL.Name                   = "I"
    infoL.Size                   = UDim2.new(1, 0, 0, 14)
    infoL.Position               = UDim2.new(0, 0, 0, 18)
    infoL.BackgroundTransparency = 1
    infoL.TextColor3             = Color3.fromRGB(220, 220, 220)
    infoL.Font                   = Enum.Font.RobotoMono
    infoL.TextSize               = 11
    infoL.Text                   = ""
    infoL.TextStrokeTransparency = 0
    infoL.TextStrokeColor3       = Color3.new(0, 0, 0)
    infoL.Parent                 = bb

    -- HP bar
    local hpBg = Instance.new("Frame")
    hpBg.Size                   = UDim2.new(0.8, 0, 0, 5)
    hpBg.Position               = UDim2.new(0.1, 0, 0, 34)
    hpBg.BackgroundColor3       = Color3.fromRGB(40, 40, 40)
    hpBg.BorderSizePixel        = 0
    hpBg.Parent                 = bb
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)

    local hpFill = Instance.new("Frame")
    hpFill.Size             = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    hpFill.BorderSizePixel  = 0
    hpFill.Parent           = hpBg
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 3)

    espCache[player] = {
        highlight = hl,
        billboard = bb,
        nameL     = nameL,
        infoL     = infoL,
        hpFill    = hpFill,
    }
end

-- Cập nhật ESP — gọi chậm, KHÔNG mỗi frame
local function updateAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local d    = espCache[player]
        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        -- Nếu chưa có cache nhưng có character → build
        if not d and char and hum then
            buildESP(player)
            d = espCache[player]
        end

        if not d then continue end

        -- Char đã mất
        if not char or not hum then
            destroyESP(player)
            continue
        end

        -- Toggle visibility
        if d.highlight and d.highlight.Parent then
            d.highlight.Enabled = espOn
        end
        if d.billboard and d.billboard.Parent then
            d.billboard.Enabled = espOn
        end

        if not espOn then continue end

        -- Cập nhật màu + info
        local col = getTeamColor(player)
        local tag = isEnemy(player) and "ENEMY" or "ALLY"

        if d.highlight and d.highlight.Parent then
            d.highlight.FillColor    = col
            d.highlight.OutlineColor = col
        end

        if d.nameL and d.nameL.Parent then
            d.nameL.TextColor3 = col
            d.nameL.Text       = player.Name .. " [" .. tag .. "]"
        end

        if d.infoL and d.infoL.Parent and hum then
            local hp  = math.floor(hum.Health)
            local max = math.floor(hum.MaxHealth)
            local dst = math.floor(getDistance(char))
            d.infoL.Text = string.format("HP %d/%d | %dm", hp, max, dst)
        end

        if d.hpFill and d.hpFill.Parent and hum then
            local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            d.hpFill.Size = UDim2.new(r, 0, 1, 0)
            if r > 0.6 then
                d.hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif r > 0.3 then
                d.hpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            else
                d.hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            end
        end
    end
end

-- ESP loop riêng — chạy mỗi 0.25 giây (KHÔNG phải mỗi frame)
task.spawn(function()
    while true do
        task.wait(0.25)
        local ok, err = pcall(updateAllESP)
        if not ok then
            warn("ESP error:", err)
        end
    end
end)

-- Khi player vào / có character → build ESP
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character then
        task.defer(buildESP, p)
    end
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            buildESP(p)
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        buildESP(p)
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    destroyESP(p)
end)

-- ═══════════════════════════════════════════════
-- AUTO-FIRE (đơn giản, không spam task.spawn)
-- ═══════════════════════════════════════════════
local lastFireTime = 0

local function tapFire()
    if not findFireButton() then return end
    if not fireButton or not fireButton.Parent then return end

    -- Cách 1: firetouchinterest
    local ok = pcall(function()
        firetouchinterest(fireButton, fireButton, 0)
        task.wait(0.04)
        firetouchinterest(fireButton, fireButton, 1)
    end)

    -- Cách 2: VirtualInputManager (fallback)
    if not ok then
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            local p   = fireButton.AbsolutePosition
            local s   = fireButton.AbsoluteSize
            local cx  = p.X + s.X / 2
            local cy  = p.Y + s.Y / 2
            VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.04)
            VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)
    end
end

-- ═══════════════════════════════════════════════
-- CROSSHAIR DETECTION (nhẹ, ít computation)
-- ═══════════════════════════════════════════════
local overlapping = {}

RunService.Heartbeat:Connect(function() -- Heartbeat thay vì RenderStepped
    -- Ẩn notif
    if NotifLabel.Visible and tick() > notifHideTime then
        NotifLabel.Visible = false
    end

    -- Guard
    if not crosshairFrame or not crosshairFrame.Parent then return end
    if not crosshairFrame.Visible then return end

    Camera = workspace.CurrentCamera

    local pos  = crosshairFrame.AbsolutePosition
    local size = crosshairFrame.AbsoluteSize
    local x1   = pos.X - PADDING
    local y1   = pos.Y - PADDING
    local x2   = pos.X + size.X + PADDING
    local y2   = pos.Y + size.Y + PADDING
    local cx   = pos.X + size.X / 2
    local cy   = pos.Y + size.Y / 2

    local anyEnemyHit = false

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if char and hum and hum.Health > 0 then
            local hitPart = nil

            -- Chỉ check 4 part chính → nhanh hơn 10x
            for _, partName in ipairs(CHECK_PARTS) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
                    if onScreen then
                        if sp.X >= x1 and sp.X <= x2
                           and sp.Y >= y1 and sp.Y <= y2 then
                            hitPart = partName
                            break -- tìm 1 cái là đủ
                        end
                    end
                end
            end

            if hitPart then
                -- CROSSHAIR TRÊN PLAYER
                local enemy = isEnemy(player)

                if not overlapping[player.Name] then
                    overlapping[player.Name] = true
                    currentTarget = player
                    totalHits += 1

                    local d3  = math.floor(getDistance(char))
                    local hp  = math.floor(hum.Health)
                    local mhp = math.floor(hum.MaxHealth)

                    showNotif(
                        string.format(
                            '<b>%s</b> [%s] | %s | HP %d/%d | %dm',
                            player.Name,
                            enemy and '<font color="#FF4444">ENEMY</font>'
                                   or '<font color="#44FF44">ALLY</font>',
                            hitPart, hp, mhp, d3
                        ),
                        enemy and Color3.fromRGB(255, 60, 60)
                              or  Color3.fromRGB(60, 255, 60)
                    )
                    HitCounter.Text = string.format(
                        '<font color="#00FF88">Hits: %d</font>', totalHits
                    )
                    refreshStatus()
                end

                -- AUTO-FIRE — chỉ bắn địch
                if enemy and autofireOn then
                    anyEnemyHit = true
                    local now = tick()
                    if now - lastFireTime >= FIRE_RATE then
                        lastFireTime = now
                        tapFire()
                    end
                end

            else
                -- RỜI KHỎI PLAYER
                if overlapping[player.Name] then
                    overlapping[player.Name] = nil
                    if currentTarget == player then
                        currentTarget = nil
                        refreshStatus()
                    end
                end
            end
        else
            if overlapping[player.Name] then
                overlapping[player.Name] = nil
            end
        end
    end

    if not anyEnemyHit and currentTarget then
        if not overlapping[currentTarget.Name] then
            currentTarget = nil
            refreshStatus()
        end
    end
end)

-- ═══════════════════════════════════════════════
-- KEYBINDS
-- ═══════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.F1 then
        autofireOn = not autofireOn
        refreshStatus()
        showNotif(
            autofireOn and "AutoFire: <b>ON</b>" or "AutoFire: <b>OFF</b>",
            autofireOn and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
        )
    elseif input.KeyCode == Enum.KeyCode.F2 then
        espOn = not espOn
        refreshStatus()
        showNotif(
            espOn and "ESP: <b>ON</b>" or "ESP: <b>OFF</b>",
            espOn and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
        )
    end
end)

-- ═══════════════════════════════════════════════
-- RESPAWN
-- ═══════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    Camera = workspace.CurrentCamera
    task.spawn(findFireButton)
end)

print("Crosshair Tools v3.0 loaded")
print("  [F1] AutoFire  [F2] ESP")
