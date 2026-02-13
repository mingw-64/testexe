--[[
    Crosshair-over-Player Detector
    Kiểm tra khi cursor.Frame quẹt qua bất kỳ player nào
    LocalScript → StarterGui
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

-------------------------------------------------
-- TÌM CROSSHAIR ELEMENT
-------------------------------------------------
local cursorGui      = PlayerGui:WaitForChild("cursor", 10)
local crosshairFrame = cursorGui and cursorGui:WaitForChild("Frame", 10)

if not crosshairFrame then
    warn("❌ Không tìm thấy cursor.Frame!")
    return
end

print("✅ Đã tìm thấy crosshair:", crosshairFrame:GetFullName())
print("   Size:", crosshairFrame.AbsoluteSize)
print("   Pos:", crosshairFrame.AbsolutePosition)

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local PADDING         = 15    -- thêm vùng chấp nhận xung quanh crosshair (px)
local BODY_PARTS      = {     -- các bộ phận check
    "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
    "Torso",  -- R6
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",  -- R6
    "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", -- R15
}
local COOLDOWN        = 0.3   -- giây giữa mỗi lần thông báo cùng 1 người
local SHOW_OFF_MSG    = true  -- hiện thông báo khi rời khỏi player

-------------------------------------------------
-- NOTIFICATION GUI (hiện trên màn hình)
-------------------------------------------------
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name         = "CrosshairNotif"
NotifGui.ResetOnSpawn = false
NotifGui.DisplayOrder = 99998
NotifGui.IgnoreGuiInset = true
NotifGui.Parent       = PlayerGui

local NotifLabel = Instance.new("TextLabel")
NotifLabel.Size                   = UDim2.new(0, 400, 0, 50)
NotifLabel.Position               = UDim2.new(0.5, -200, 0, 80)
NotifLabel.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
NotifLabel.BackgroundTransparency = 0.4
NotifLabel.TextColor3             = Color3.fromRGB(255, 80, 80)
NotifLabel.Font                   = Enum.Font.GothamBold
NotifLabel.TextSize               = 18
NotifLabel.Text                   = ""
NotifLabel.Visible                = false
NotifLabel.BorderSizePixel        = 0
NotifLabel.ZIndex                 = 100
NotifLabel.RichText               = true
NotifLabel.Parent                 = NotifGui
Instance.new("UICorner", NotifLabel).CornerRadius = UDim.new(0, 10)
local nStroke = Instance.new("UIStroke", NotifLabel)
nStroke.Color = Color3.fromRGB(255, 50, 50); nStroke.Thickness = 2

-- Bộ đếm hit
local HitCounter = Instance.new("TextLabel")
HitCounter.Size                   = UDim2.new(0, 200, 0, 35)
HitCounter.Position               = UDim2.new(0.5, -100, 0, 135)
HitCounter.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
HitCounter.BackgroundTransparency = 0.5
HitCounter.TextColor3             = Color3.fromRGB(100, 255, 100)
HitCounter.Font                   = Enum.Font.RobotoMono
HitCounter.TextSize               = 14
HitCounter.Text                   = "Hits: 0"
HitCounter.Visible                = true
HitCounter.BorderSizePixel        = 0
HitCounter.ZIndex                 = 100
HitCounter.RichText               = true
HitCounter.Parent                 = NotifGui
Instance.new("UICorner", HitCounter).CornerRadius = UDim.new(0, 8)

local notifHideTime = 0
local totalHits     = 0

local function showNotif(text, color)
    NotifLabel.Text       = text
    NotifLabel.TextColor3 = color or Color3.fromRGB(255, 80, 80)
    NotifLabel.Visible    = true
    nStroke.Color         = color or Color3.fromRGB(255, 50, 50)
    notifHideTime         = tick() + 1.5
end

-------------------------------------------------
-- TRACKING STATE
-------------------------------------------------
local overlapping = {}   -- [playerName] = true/false
local lastNotif   = {}   -- [playerName] = tick()

-------------------------------------------------
-- HELPERS
-------------------------------------------------

-- Lấy bounding box crosshair trên màn hình
local function getCrosshairBounds()
    local pos  = crosshairFrame.AbsolutePosition
    local size = crosshairFrame.AbsoluteSize

    return {
        x1 = pos.X - PADDING,
        y1 = pos.Y - PADDING,
        x2 = pos.X + size.X + PADDING,
        y2 = pos.Y + size.Y + PADDING,
        cx = pos.X + size.X / 2,
        cy = pos.Y + size.Y / 2,
    }
end

-- Kiểm tra 1 điểm có nằm trong bounds không
local function pointInBounds(px, py, bounds)
    return px >= bounds.x1 and px <= bounds.x2
       and py >= bounds.y1 and py <= bounds.y2
end

-- Lấy tất cả điểm body part trên màn hình của 1 character
local function getCharacterScreenPoints(character)
    local points = {}

    for _, partName in ipairs(BODY_PARTS) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
            if onScreen then
                table.insert(points, {
                    x    = screenPos.X,
                    y    = screenPos.Y,
                    part = partName,
                    dist = screenPos.Z,   -- khoảng cách 3D
                })
            end

            -- Thêm điểm trên + dưới của part (cho hitbox chính xác hơn)
            local top = part.Position + Vector3.new(0, part.Size.Y/2, 0)
            local bot = part.Position - Vector3.new(0, part.Size.Y/2, 0)

            local sp1, on1 = Camera:WorldToScreenPoint(top)
            if on1 then
                table.insert(points, {x = sp1.X, y = sp1.Y, part = partName.."_top", dist = sp1.Z})
            end

            local sp2, on2 = Camera:WorldToScreenPoint(bot)
            if on2 then
                table.insert(points, {x = sp2.X, y = sp2.Y, part = partName.."_bot", dist = sp2.Z})
            end
        end
    end

    return points
end

-- Tính khoảng cách 3D tới player
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

-------------------------------------------------
-- MAIN LOOP
-------------------------------------------------
RunService.RenderStepped:Connect(function()
    -- Ẩn notif sau thời gian
    if NotifLabel.Visible and tick() > notifHideTime then
        NotifLabel.Visible = false
    end

    -- Kiểm tra crosshair còn tồn tại
    if not crosshairFrame or not crosshairFrame.Parent then return end
    if not crosshairFrame.Visible then return end

    local bounds = getCrosshairBounds()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid  = character and character:FindFirstChildOfClass("Humanoid")

            if character and humanoid and humanoid.Health > 0 then
                local points   = getCharacterScreenPoints(character)
                local hitPart  = nil
                local bestDist = math.huge

                -- Tìm body part gần tâm crosshair nhất mà nằm trong bounds
                for _, pt in ipairs(points) do
                    if pointInBounds(pt.x, pt.y, bounds) then
                        local dToCH = math.sqrt(
                            (pt.x - bounds.cx)^2 + (pt.y - bounds.cy)^2
                        )
                        if dToCH < bestDist then
                            bestDist = dToCH
                            hitPart  = pt.part
                        end
                    end
                end

                if hitPart then
                    -- ═══ CROSSHAIR ĐANG TRÊN PLAYER ═══
                    if not overlapping[player.Name] then
                        overlapping[player.Name] = true

                        local dist3D = math.floor(getDistance(character))
                        local hp     = math.floor(humanoid.Health)
                        local maxHp  = math.floor(humanoid.MaxHealth)

                        -- ★ IN RA CONSOLE
                        print("═══════════════════════════════════════")
                        print(string.format(
                            "🎯 CROSSHAIR ON: %s", player.Name
                        ))
                        print(string.format(
                            "   💀 Part: %s  |  HP: %d/%d  |  Dist: %d studs",
                            hitPart, hp, maxHp, dist3D
                        ))
                        print("═══════════════════════════════════════")

                        -- ★ HIỆN TRÊN MÀN HÌNH
                        totalHits += 1
                        showNotif(
                            string.format(
                                "🎯 <b>%s</b>  |  %s  |  ❤️%d/%d  |  📏%dm",
                                player.Name, hitPart, hp, maxHp, dist3D
                            ),
                            Color3.fromRGB(255, 60, 60)
                        )
                        HitCounter.Text = string.format(
                            '<font color="#00FF88">Total Hits: %d</font>', totalHits
                        )
                    end
                else
                    -- ═══ CROSSHAIR RỜI KHỎI PLAYER ═══
                    if overlapping[player.Name] then
                        overlapping[player.Name] = nil

                        if SHOW_OFF_MSG then
                            print(string.format("   ❌ OFF: %s", player.Name))
                            showNotif(
                                string.format("❌ Rời <b>%s</b>", player.Name),
                                Color3.fromRGB(150, 150, 150)
                            )
                        end
                    end
                end
            else
                -- Player chết hoặc không có character
                if overlapping[player.Name] then
                    overlapping[player.Name] = nil
                end
            end
        end
    end
end)

-------------------------------------------------
-- CLEANUP KHI PLAYER RỜI
-------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    overlapping[player.Name] = nil
    lastNotif[player.Name]   = nil
end)

-------------------------------------------------
print("═══════════════════════════════════════")
print("  🎯 Crosshair-over-Player Detector")
print("  Tracking: cursor.Frame")
print("  Padding: ±" .. PADDING .. "px")
print("  Body parts: " .. #BODY_PARTS)
print("═══════════════════════════════════════")
