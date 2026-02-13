--[[
    Crosshair-on-Player Detector
    Phát hiện khi crosshair (aim element) quét qua player
    LocalScript → StarterGui
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

print("🎯 Crosshair Detector Loading...")

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local CONFIG = {
    -- Tên element cần theo dõi (có thể là nhiều tên)
    AIM_NAMES = {"aim", "Aim", "AIM", "crosshair", "Crosshair", "reticle"},
    
    -- Bán kính phát hiện (pixel) - crosshair gần player bao nhiêu thì tính là "on target"
    DETECTION_RADIUS = 50,
    
    -- Phần body nào để check (Head chính xác hơn)
    CHECK_PARTS = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"},
    
    -- Màu thông báo
    ON_TARGET_COLOR  = Color3.fromRGB(255, 50, 50),
    OFF_TARGET_COLOR = Color3.fromRGB(100, 100, 100),
}

-------------------------------------------------
-- TÌM AIM ELEMENT
-------------------------------------------------
local aimElement = nil
local searchAttempts = 0

local function findAimElement()
    for _, sg in ipairs(PlayerGui:GetChildren()) do
        if sg:IsA("ScreenGui") then
            for _, obj in ipairs(sg:GetDescendants()) do
                if obj:IsA("GuiObject") then
                    for _, name in ipairs(CONFIG.AIM_NAMES) do
                        if obj.Name:lower():find(name:lower()) then
                            print("✅ Found aim element:", obj:GetFullName())
                            return obj
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Tìm liên tục cho đến khi thấy
task.spawn(function()
    while not aimElement do
        aimElement = findAimElement()
        searchAttempts += 1
        
        if searchAttempts % 10 == 0 then
            print("⏳ Still searching for aim element... (attempt " .. searchAttempts .. ")")
        end
        
        task.wait(0.5)
    end
end)

-------------------------------------------------
-- GUI
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "CrosshairOnPlayerGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 999999
ScreenGui.IgnoreGuiInset = false
ScreenGui.Parent         = PlayerGui

-- Scale helper
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local function S(px) return math.floor(px * (IS_MOBILE and 0.8 or 1)) end

-------------------------------------------------
-- MAIN NOTIFICATION PANEL (góc trên)
-------------------------------------------------
local NotifPanel = Instance.new("Frame")
NotifPanel.Name              = "NotifPanel"
NotifPanel.Size              = UDim2.new(0, S(320), 0, S(120))
NotifPanel.Position          = UDim2.new(0.5, -S(160), 0, S(10))
NotifPanel.BackgroundColor3  = Color3.fromRGB(20, 20, 30)
NotifPanel.BackgroundTransparency = 0.2
NotifPanel.BorderSizePixel   = 0
NotifPanel.Parent            = ScreenGui
Instance.new("UICorner", NotifPanel).CornerRadius = UDim.new(0, S(12))
local nStroke = Instance.new("UIStroke", NotifPanel)
nStroke.Color = Color3.fromRGB(100, 100, 100); nStroke.Thickness = S(2)

-- Status Icon (to, ở giữa)
local StatusIcon = Instance.new("TextLabel")
StatusIcon.Name                  = "StatusIcon"
StatusIcon.Size                  = UDim2.new(1, 0, 0, S(40))
StatusIcon.Position              = UDim2.new(0, 0, 0, S(8))
StatusIcon.BackgroundTransparency = 1
StatusIcon.Font                  = Enum.Font.GothamBold
StatusIcon.TextSize              = S(28)
StatusIcon.TextColor3            = CONFIG.OFF_TARGET_COLOR
StatusIcon.Text                  = "⭕ NO TARGET"
StatusIcon.Parent                = NotifPanel

-- Target Name
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Name                  = "TargetLabel"
TargetLabel.Size                  = UDim2.new(1, -S(16), 0, S(24))
TargetLabel.Position              = UDim2.new(0, S(8), 0, S(48))
TargetLabel.BackgroundTransparency = 1
TargetLabel.Font                  = Enum.Font.GothamBold
TargetLabel.TextSize              = S(16)
TargetLabel.TextColor3            = Color3.new(1, 1, 1)
TargetLabel.Text                  = ""
TargetLabel.Parent                = NotifPanel

-- Info Label (distance, part)
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name                  = "InfoLabel"
InfoLabel.Size                  = UDim2.new(1, -S(16), 0, S(20))
InfoLabel.Position              = UDim2.new(0, S(8), 0, S(72))
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font                  = Enum.Font.RobotoMono
InfoLabel.TextSize              = S(11)
InfoLabel.TextColor3            = Color3.fromRGB(180, 180, 180)
InfoLabel.Text                  = ""
InfoLabel.Parent                = NotifPanel

-- Aim Element Status
local AimStatus = Instance.new("TextLabel")
AimStatus.Name                  = "AimStatus"
AimStatus.Size                  = UDim2.new(1, -S(16), 0, S(16))
AimStatus.Position              = UDim2.new(0, S(8), 0, S(96))
AimStatus.BackgroundTransparency = 1
AimStatus.Font                  = Enum.Font.Gotham
AimStatus.TextSize              = S(10)
AimStatus.TextColor3            = Color3.fromRGB(120, 120, 120)
AimStatus.Text                  = "Searching for aim element..."
AimStatus.Parent                = NotifPanel

-------------------------------------------------
-- HIT LOG (lịch sử các lần on-target)
-------------------------------------------------
local LogPanel = Instance.new("Frame")
LogPanel.Name              = "LogPanel"
LogPanel.Size              = UDim2.new(0, S(280), 0, S(200))
LogPanel.Position          = UDim2.new(1, -S(290), 0, S(10))
LogPanel.BackgroundColor3  = Color3.fromRGB(15, 15, 25)
LogPanel.BackgroundTransparency = 0.2
LogPanel.BorderSizePixel   = 0
LogPanel.Parent            = ScreenGui
Instance.new("UICorner", LogPanel).CornerRadius = UDim.new(0, S(10))
Instance.new("UIStroke", LogPanel).Color = Color3.fromRGB(80, 80, 100)

local LogTitle = Instance.new("TextLabel")
LogTitle.Size                  = UDim2.new(1, 0, 0, S(28))
LogTitle.BackgroundColor3      = Color3.fromRGB(30, 20, 20)
LogTitle.BackgroundTransparency = 0.5
LogTitle.Font                  = Enum.Font.GothamBold
LogTitle.TextSize              = S(12)
LogTitle.TextColor3            = Color3.fromRGB(255, 150, 150)
LogTitle.Text                  = "📋 HIT LOG"
LogTitle.Parent                = LogPanel
Instance.new("UICorner", LogTitle).CornerRadius = UDim.new(0, S(10))

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size                   = UDim2.new(1, -S(8), 1, -S(34))
LogScroll.Position               = UDim2.new(0, S(4), 0, S(30))
LogScroll.BackgroundTransparency = 1
LogScroll.BorderSizePixel        = 0
LogScroll.ScrollBarThickness     = S(4)
LogScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
LogScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
LogScroll.Parent                 = LogPanel

local logLayout = Instance.new("UIListLayout", LogScroll)
logLayout.Padding   = UDim.new(0, S(2))
logLayout.SortOrder = Enum.SortOrder.LayoutOrder

local logEntries = {}
local logCounter = 0

local function addLog(playerName, distance, part)
    logCounter += 1
    
    local entry = Instance.new("TextLabel")
    entry.Size                  = UDim2.new(1, -S(4), 0, S(18))
    entry.BackgroundColor3      = Color3.fromRGB(40, 20, 20)
    entry.BackgroundTransparency = 0.5
    entry.Font                  = Enum.Font.RobotoMono
    entry.TextSize              = S(10)
    entry.TextColor3            = Color3.fromRGB(255, 200, 200)
    entry.TextXAlignment        = Enum.TextXAlignment.Left
    entry.LayoutOrder           = -logCounter -- newest first
    entry.RichText              = true
    entry.Parent                = LogScroll
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, S(4))
    
    local pad = Instance.new("UIPadding", entry)
    pad.PaddingLeft = UDim.new(0, S(6))
    
    local timestamp = os.date("%H:%M:%S")
    entry.Text = string.format(
        '<font color="#888">%s</font> <font color="#FF6666">%s</font> <font color="#AAA">%.0fm %s</font>',
        timestamp, playerName, distance, part
    )
    
    table.insert(logEntries, entry)
    
    -- Giới hạn 50 entries
    if #logEntries > 50 then
        local old = table.remove(logEntries, 1)
        old:Destroy()
    end
end

-------------------------------------------------
-- CROSSHAIR POSITION INDICATOR (hiện vị trí aim)
-------------------------------------------------
local AimIndicator = Instance.new("Frame")
AimIndicator.Name              = "AimIndicator"
AimIndicator.Size              = UDim2.new(0, S(20), 0, S(20))
AimIndicator.AnchorPoint       = Vector2.new(0.5, 0.5)
AimIndicator.BackgroundColor3  = Color3.fromRGB(0, 255, 0)
AimIndicator.BackgroundTransparency = 0.5
AimIndicator.BorderSizePixel   = 0
AimIndicator.Visible           = false
AimIndicator.ZIndex            = 99999
AimIndicator.Parent            = ScreenGui
Instance.new("UICorner", AimIndicator).CornerRadius = UDim.new(1, 0) -- circle

local aimStroke = Instance.new("UIStroke", AimIndicator)
aimStroke.Color = Color3.fromRGB(0, 255, 0); aimStroke.Thickness = S(2)

-------------------------------------------------
-- PLAYER SCREEN POSITION MARKERS
-------------------------------------------------
local playerMarkers = {}

local function getOrCreateMarker(player)
    if playerMarkers[player] then
        return playerMarkers[player]
    end
    
    local marker = Instance.new("Frame")
    marker.Name              = "Marker_" .. player.Name
    marker.Size              = UDim2.new(0, S(60), 0, S(20))
    marker.AnchorPoint       = Vector2.new(0.5, 0.5)
    marker.BackgroundColor3  = Color3.fromRGB(50, 50, 200)
    marker.BackgroundTransparency = 0.5
    marker.BorderSizePixel   = 0
    marker.Visible           = false
    marker.ZIndex            = 9998
    marker.Parent            = ScreenGui
    Instance.new("UICorner", marker).CornerRadius = UDim.new(0, S(6))
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size                  = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font                  = Enum.Font.GothamBold
    nameLabel.TextSize              = S(10)
    nameLabel.TextColor3            = Color3.new(1, 1, 1)
    nameLabel.Text                  = player.Name
    nameLabel.TextTruncate          = Enum.TextTruncate.AtEnd
    nameLabel.Parent                = marker
    
    playerMarkers[player] = marker
    
    -- Cleanup when player leaves
    player.AncestryChanged:Connect(function()
        if not player.Parent then
            if playerMarkers[player] then
                playerMarkers[player]:Destroy()
                playerMarkers[player] = nil
            end
        end
    end)
    
    return marker
end

-------------------------------------------------
-- DETECTION LOGIC
-------------------------------------------------
local currentTarget = nil
local lastTarget    = nil
local onTargetTime  = 0

local function getAimCenter()
    if not aimElement or not aimElement.Parent then
        return nil
    end
    
    local absPos  = aimElement.AbsolutePosition
    local absSize = aimElement.AbsoluteSize
    
    return Vector2.new(
        absPos.X + absSize.X / 2,
        absPos.Y + absSize.Y / 2
    )
end

local function getPlayerScreenPos(player)
    local char = player.Character
    if not char then return nil, nil, nil end
    
    -- Thử các part khác nhau
    for _, partName in ipairs(CONFIG.CHECK_PARTS) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
            
            if onScreen then
                -- Tính distance
                local myChar = LocalPlayer.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local distance = 0
                if myHRP then
                    distance = (part.Position - myHRP.Position).Magnitude
                end
                
                return Vector2.new(screenPos.X, screenPos.Y), distance, partName
            end
        end
    end
    
    return nil, nil, nil
end

local function checkCrosshairOnPlayer()
    local aimCenter = getAimCenter()
    if not aimCenter then
        return nil, nil, nil, nil
    end
    
    local closestPlayer  = nil
    local closestDist    = math.huge
    local closestScreenDist = math.huge
    local closestPart    = nil
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local screenPos, worldDist, partName = getPlayerScreenPos(player)
            
            if screenPos then
                local screenDist = (screenPos - aimCenter).Magnitude
                
                -- Update marker
                local marker = getOrCreateMarker(player)
                marker.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                marker.Visible = true
                
                -- Check if within detection radius
                if screenDist < CONFIG.DETECTION_RADIUS then
                    if screenDist < closestScreenDist then
                        closestPlayer     = player
                        closestDist       = worldDist
                        closestScreenDist = screenDist
                        closestPart       = partName
                    end
                end
                
                -- Color marker based on distance to crosshair
                if screenDist < CONFIG.DETECTION_RADIUS then
                    marker.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                elseif screenDist < CONFIG.DETECTION_RADIUS * 2 then
                    marker.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
                else
                    marker.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
                end
            else
                -- Player not on screen
                local marker = playerMarkers[player]
                if marker then
                    marker.Visible = false
                end
            end
        end
    end
    
    return closestPlayer, closestDist, closestScreenDist, closestPart
end

-------------------------------------------------
-- MAIN UPDATE LOOP
-------------------------------------------------
local totalOnTargetTime = 0
local hitCount = 0

RunService.RenderStepped:Connect(function(dt)
    -- Update aim indicator position
    local aimCenter = getAimCenter()
    if aimCenter then
        AimIndicator.Position = UDim2.new(0, aimCenter.X, 0, aimCenter.Y)
        AimIndicator.Visible = true
        AimStatus.Text = string.format(
            "✅ Aim found: %s | Pos: (%.0f, %.0f)",
            aimElement.Name, aimCenter.X, aimCenter.Y
        )
    else
        AimIndicator.Visible = false
        AimStatus.Text = "⏳ Searching for aim element..."
        
        -- Try to find again
        if not aimElement then
            aimElement = findAimElement()
        end
        return
    end
    
    -- Check crosshair on player
    local targetPlayer, worldDist, screenDist, partName = checkCrosshairOnPlayer()
    
    if targetPlayer then
        -- ON TARGET!
        onTargetTime += dt
        totalOnTargetTime += dt
        
        StatusIcon.Text = "🎯 ON TARGET!"
        StatusIcon.TextColor3 = CONFIG.ON_TARGET_COLOR
        nStroke.Color = CONFIG.ON_TARGET_COLOR
        
        TargetLabel.Text = "👤 " .. targetPlayer.Name
        InfoLabel.Text = string.format(
            "Distance: %.1f studs | Part: %s | Screen: %.0fpx",
            worldDist, partName, screenDist
        )
        
        AimIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        aimStroke.Color = Color3.fromRGB(255, 0, 0)
        
        -- Log khi mới vào target (hoặc đổi target)
        if targetPlayer ~= lastTarget then
            hitCount += 1
            addLog(targetPlayer.Name, worldDist, partName)
            print(string.format(
                "🎯 ON TARGET: %s (%.1f studs, %s)",
                targetPlayer.Name, worldDist, partName
            ))
        end
        
        lastTarget = targetPlayer
        
    else
        -- OFF TARGET
        StatusIcon.Text = "⭕ NO TARGET"
        StatusIcon.TextColor3 = CONFIG.OFF_TARGET_COLOR
        nStroke.Color = CONFIG.OFF_TARGET_COLOR
        
        TargetLabel.Text = ""
        InfoLabel.Text = string.format(
            "Total on-target: %.1fs | Hits: %d",
            totalOnTargetTime, hitCount
        )
        
        AimIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        aimStroke.Color = Color3.fromRGB(0, 255, 0)
        
        onTargetTime = 0
        lastTarget = nil
    end
end)

-------------------------------------------------
-- TOGGLE VISIBILITY
-------------------------------------------------
local showMarkers = true

local ToggleMarkersBtn = Instance.new("TextButton")
ToggleMarkersBtn.Size             = UDim2.new(0, S(120), 0, S(35))
ToggleMarkersBtn.Position         = UDim2.new(0, S(10), 1, -S(50))
ToggleMarkersBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
ToggleMarkersBtn.TextColor3       = Color3.new(1, 1, 1)
ToggleMarkersBtn.Font             = Enum.Font.GothamBold
ToggleMarkersBtn.TextSize         = S(11)
ToggleMarkersBtn.Text             = "👁️ Markers ON"
ToggleMarkersBtn.BorderSizePixel  = 0
ToggleMarkersBtn.Parent           = ScreenGui
Instance.new("UICorner", ToggleMarkersBtn).CornerRadius = UDim.new(0, S(8))

ToggleMarkersBtn.MouseButton1Click:Connect(function()
    showMarkers = not showMarkers
    
    for _, marker in pairs(playerMarkers) do
        marker.Visible = showMarkers and marker.Visible
    end
    
    AimIndicator.Visible = showMarkers
    
    ToggleMarkersBtn.Text = showMarkers and "👁️ Markers ON" or "👁️ Markers OFF"
    ToggleMarkersBtn.BackgroundColor3 = showMarkers 
        and Color3.fromRGB(60, 60, 80) 
        or Color3.fromRGB(80, 40, 40)
end)

-------------------------------------------------
-- ADJUST RADIUS BUTTON
-------------------------------------------------
local RadiusBtn = Instance.new("TextButton")
RadiusBtn.Size             = UDim2.new(0, S(100), 0, S(35))
RadiusBtn.Position         = UDim2.new(0, S(140), 1, -S(50))
RadiusBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 40)
RadiusBtn.TextColor3       = Color3.new(1, 1, 1)
RadiusBtn.Font             = Enum.Font.GothamBold
RadiusBtn.TextSize         = S(11)
RadiusBtn.Text             = "Radius: " .. CONFIG.DETECTION_RADIUS
RadiusBtn.BorderSizePixel  = 0
RadiusBtn.Parent           = ScreenGui
Instance.new("UICorner", RadiusBtn).CornerRadius = UDim.new(0, S(8))

local radiusOptions = {30, 50, 80, 100, 150}
local radiusIndex = 2 -- default 50

RadiusBtn.MouseButton1Click:Connect(function()
    radiusIndex = (radiusIndex % #radiusOptions) + 1
    CONFIG.DETECTION_RADIUS = radiusOptions[radiusIndex]
    RadiusBtn.Text = "Radius: " .. CONFIG.DETECTION_RADIUS
end)

-------------------------------------------------
-- RAYCAST MODE (chính xác hơn)
-------------------------------------------------
local useRaycast = false

local RaycastBtn = Instance.new("TextButton")
RaycastBtn.Size             = UDim2.new(0, S(100), 0, S(35))
RaycastBtn.Position         = UDim2.new(0, S(250), 1, -S(50))
RaycastBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
RaycastBtn.TextColor3       = Color3.new(1, 1, 1)
RaycastBtn.Font             = Enum.Font.GothamBold
RaycastBtn.TextSize         = S(11)
RaycastBtn.Text             = "Raycast: OFF"
RaycastBtn.BorderSizePixel  = 0
RaycastBtn.Parent           = ScreenGui
Instance.new("UICorner", RaycastBtn).CornerRadius = UDim.new(0, S(8))

-- Raycast detection (thêm vào)
local function raycastFromCrosshair()
    local aimCenter = getAimCenter()
    if not aimCenter then return nil end
    
    -- Tạo ray từ camera qua vị trí crosshair
    local ray = Camera:ViewportPointToRay(aimCenter.X, aimCenter.Y)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    
    if result then
        local hitPart = result.Instance
        local hitChar = hitPart:FindFirstAncestorOfClass("Model")
        
        if hitChar then
            local player = Players:GetPlayerFromCharacter(hitChar)
            if player and player ~= LocalPlayer then
                return player, result.Distance, hitPart.Name
            end
        end
    end
    
    return nil
end

RaycastBtn.MouseButton1Click:Connect(function()
    useRaycast = not useRaycast
    RaycastBtn.Text = useRaycast and "Raycast: ON" or "Raycast: OFF"
    RaycastBtn.BackgroundColor3 = useRaycast 
        and Color3.fromRGB(40, 100, 60) 
        or Color3.fromRGB(40, 60, 80)
end)

-- Modified update for raycast
local raycastConn
raycastConn = RunService.RenderStepped:Connect(function()
    if useRaycast then
        local player, dist, partName = raycastFromCrosshair()
        if player then
            StatusIcon.Text = "🎯 RAYCAST HIT!"
            StatusIcon.TextColor3 = Color3.fromRGB(0, 255, 100)
            TargetLabel.Text = "👤 " .. player.Name .. " (Raycast)"
            InfoLabel.Text = string.format("Distance: %.1f | Hit: %s", dist, partName)
        end
    end
end)

-------------------------------------------------
print("═══════════════════════════════════════")
print("✅ Crosshair-on-Player Detector Loaded!")
print("📍 Looking for elements named:", table.concat(CONFIG.AIM_NAMES, ", "))
print("═══════════════════════════════════════")
