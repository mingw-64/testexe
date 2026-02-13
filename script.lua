--[[
    Crosshair Detector + ESP v5.0
    LocalScript → StarterGui
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
local PADDING = 15
local CHECK_PARTS = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }
local espOn = true

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
-- NOTIFICATION GUI
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
-- STATUS PANEL
-- ═══════════════════════════════════════════════
local StatusGui = Instance.new("ScreenGui")
StatusGui.Name           = "StatusPanel"
StatusGui.ResetOnSpawn   = false
StatusGui.DisplayOrder   = 99999
StatusGui.IgnoreGuiInset = true
StatusGui.Parent         = PlayerGui

local sFrame = Instance.new("Frame")
sFrame.Size                   = UDim2.new(0, 240, 0, 50)
sFrame.Position               = UDim2.new(0, 10, 0, 10)
sFrame.BackgroundColor3       = Color3.fromRGB(12, 12, 12)
sFrame.BackgroundTransparency = 0.15
sFrame.BorderSizePixel        = 0
sFrame.Parent                 = StatusGui
Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 10)

local esLbl = Instance.new("TextLabel")
esLbl.Size = UDim2.new(1, -10, 0, 20)
esLbl.Position = UDim2.new(0, 5, 0, 5)
esLbl.BackgroundTransparency = 1
esLbl.Font = Enum.Font.RobotoMono
esLbl.TextSize = 13
esLbl.TextXAlignment = Enum.TextXAlignment.Left
esLbl.RichText = true
esLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
esLbl.Parent = sFrame

local tgtLbl = esLbl:Clone()
tgtLbl.Position = UDim2.new(0, 5, 0, 26)
tgtLbl.Parent = sFrame

local currentTarget = nil

local function refreshStatus()
    esLbl.Text = espOn
        and '[F2] ESP: <font color="#00FF00">ON</font>'
        or  '[F2] ESP: <font color="#FF4444">OFF</font>'
    tgtLbl.Text = currentTarget
        and string.format('Target: <font color="#FF6644">%s</font>', currentTarget.Name)
        or  'Target: <font color="#666">None</font>'
end
refreshStatus()

-- ═══════════════════════════════════════════════
-- ESP SYSTEM (thread riêng, 0.3s/lần)
-- ═══════════════════════════════════════════════
local espCache = {}

local function destroyESP(player)
    local d = espCache[player]
    if not d then return end
    if d.highlight and d.highlight.Parent then d.highlight:Destroy() end
    if d.billboard and d.billboard.Parent then d.billboard:Destroy() end
    espCache[player] = nil
end

local function buildESP(player)
    if player == LocalPlayer then return end
    destroyESP(player)

    local char = player.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hum or not head then return end

    local col = getTeamColor(player)
    local tag = isEnemy(player) and "ENEMY" or "ALLY"

    local hl = Instance.new("Highlight")
    hl.FillColor           = col
    hl.FillTransparency    = 0.55
    hl.OutlineColor        = col
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled             = espOn
    hl.Adornee             = char
    hl.Parent              = char

    local bb = Instance.new("BillboardGui")
    bb.Adornee     = head
    bb.Size        = UDim2.new(0, 180, 0, 52)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Enabled     = espOn
    bb.Parent      = head

    local nameL = Instance.new("TextLabel")
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

-- ESP update — thread riêng
task.spawn(function()
    while true do
        task.wait(0.3)
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end

            local d    = espCache[player]
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")

            if not d and char and hum then
                pcall(buildESP, player)
                d = espCache[player]
            end
            if not d then continue end
            if not char or not hum then
                destroyESP(player)
                continue
            end

            pcall(function()
                d.highlight.Enabled = espOn
                d.billboard.Enabled = espOn
            end)
            if not espOn then continue end

            pcall(function()
                local col = getTeamColor(player)
                local tag = isEnemy(player) and "ENEMY" or "ALLY"
                d.highlight.FillColor    = col
                d.highlight.OutlineColor = col
                d.nameL.TextColor3       = col
                d.nameL.Text             = player.Name .. " [" .. tag .. "]"

                local hp  = math.floor(hum.Health)
                local max = math.floor(hum.MaxHealth)
                local dst = math.floor(getDistance(char))
                d.infoL.Text = string.format("HP %d/%d | %dm", hp, max, dst)

                local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                d.hpFill.Size = UDim2.new(r, 0, 1, 0)
                d.hpFill.BackgroundColor3 = r > 0.6
                    and Color3.fromRGB(0, 255, 0)
                    or r > 0.3
                    and Color3.fromRGB(255, 255, 0)
                    or Color3.fromRGB(255, 50, 50)
            end)
        end
    end
end)

-- Build ESP khi character spawn
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        if p.Character then task.defer(buildESP, p) end
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
-- CROSSHAIR DETECTION (Heartbeat — chỉ hiện tên)
-- ═══════════════════════════════════════════════
local overlapping = {}

RunService.Heartbeat:Connect(function()
    if NotifLabel.Visible and tick() > notifHideTime then
        NotifLabel.Visible = false
    end

    if not crosshairFrame or not crosshairFrame.Parent then return end
    if not crosshairFrame.Visible then return end

    Camera = workspace.CurrentCamera

    local pos  = crosshairFrame.AbsolutePosition
    local size = crosshairFrame.AbsoluteSize
    local x1   = pos.X - PADDING
    local y1   = pos.Y - PADDING
    local x2   = pos.X + size.X + PADDING
    local y2   = pos.Y + size.Y + PADDING

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if char and hum and hum.Health > 0 then
            local hitPart = nil

            for _, partName in ipairs(CHECK_PARTS) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
                    if onScreen
                       and sp.X >= x1 and sp.X <= x2
                       and sp.Y >= y1 and sp.Y <= y2
                    then
                        hitPart = partName
                        break
                    end
                end
            end

            if hitPart then
                if not overlapping[player.Name] then
                    overlapping[player.Name] = true
                    currentTarget = player
                    totalHits += 1

                    local enemy = isEnemy(player)
                    local d3    = math.floor(getDistance(char))
                    local hp    = math.floor(hum.Health)
                    local mhp   = math.floor(hum.MaxHealth)

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
            else
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
end)

-- ═══════════════════════════════════════════════
-- KEYBIND
-- ═══════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F2 then
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
end)

print("v5.0 loaded | [F2] ESP | Crosshair detect only")
