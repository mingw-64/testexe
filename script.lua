--[[
    Advanced Crosshair / Custom Aim Detector
    Phát hiện crosshair dù đặt tên gì, dùng cách gì
    LocalScript → StarterGui
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local Mouse            = Players.LocalPlayer:GetMouse()

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

-------------------------------------------------
-- DETECTION CONFIG
-------------------------------------------------
local DETECT = {
    -- Vùng trung tâm màn hình (pixel từ center)
    CENTER_RADIUS_TIGHT  = 40,   -- chắc chắn là crosshair
    CENTER_RADIUS_MEDIUM = 80,   -- khả năng cao
    CENTER_RADIUS_WIDE   = 150,  -- có thể

    -- Kích thước crosshair thường gặp
    MAX_CROSSHAIR_SIZE = 120,    -- pixel
    MIN_CROSSHAIR_SIZE = 1,      -- pixel

    -- Cross pattern detection
    THIN_THRESHOLD     = 8,      -- pixel, thanh mỏng
    CROSS_GAP_TOLERANCE = 15,    -- pixel, khoảng cách giữa các thanh

    -- Confidence threshold
    MIN_CONFIDENCE = 40,         -- % để coi là crosshair
}

-------------------------------------------------
-- GUI
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "CrosshairDetectorGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 99999
ScreenGui.Parent       = PlayerGui

-- Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size             = UDim2.new(0, 160, 0, 44)
ToggleBtn.Position         = UDim2.new(1, -170, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
ToggleBtn.TextColor3       = Color3.new(1, 1, 1)
ToggleBtn.Font             = Enum.Font.GothamBold
ToggleBtn.TextSize         = 13
ToggleBtn.Text             = "🎯 Detector OFF"
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.ZIndex           = 100
ToggleBtn.Parent           = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)

-- Main Panel
local Panel = Instance.new("Frame")
Panel.Size              = UDim2.new(0, 560, 0, 620)
Panel.Position          = UDim2.new(0.5, -280, 0.5, -310)
Panel.BackgroundColor3  = Color3.fromRGB(12, 12, 22)
Panel.BorderSizePixel   = 0
Panel.Visible           = false
Panel.Active            = true
Panel.Draggable         = true
Panel.Parent            = ScreenGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)
local ps = Instance.new("UIStroke", Panel)
ps.Color = Color3.fromRGB(255, 80, 80); ps.Thickness = 2

-- Title
local Title = Instance.new("TextLabel")
Title.Size                  = UDim2.new(1, -50, 0, 40)
Title.Position              = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Font                  = Enum.Font.GothamBold
Title.TextSize              = 15
Title.TextColor3            = Color3.fromRGB(255, 80, 80)
Title.TextXAlignment        = Enum.TextXAlignment.Left
Title.RichText              = true
Title.Text                  = "🎯 Custom Crosshair Detector — Advanced Analysis"
Title.Parent                = Panel

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 32, 0, 32)
CloseBtn.Position         = UDim2.new(1, -38, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.TextColor3       = Color3.new(1, 1, 1)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 18
CloseBtn.Text             = "✕"
CloseBtn.BorderSizePixel  = 0
CloseBtn.Parent           = Panel
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Stats
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size                  = UDim2.new(1, -16, 0, 50)
StatsLabel.Position              = UDim2.new(0, 8, 0, 40)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Font                  = Enum.Font.RobotoMono
StatsLabel.TextSize              = 12
StatsLabel.TextColor3            = Color3.fromRGB(180, 180, 180)
StatsLabel.TextXAlignment        = Enum.TextXAlignment.Left
StatsLabel.TextYAlignment        = Enum.TextYAlignment.Top
StatsLabel.RichText              = true
StatsLabel.TextWrapped           = true
StatsLabel.Text                  = ""
StatsLabel.Parent                = Panel

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                   = UDim2.new(1, -16, 1, -100)
Scroll.Position               = UDim2.new(0, 8, 0, 94)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel        = 0
Scroll.ScrollBarThickness     = 6
Scroll.ScrollBarImageColor3   = Color3.fromRGB(255, 80, 80)
Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
Scroll.Parent                 = Panel

Instance.new("UIPadding", Scroll).PaddingTop = UDim.new(0, 4)
local sLayout = Instance.new("UIListLayout", Scroll)
sLayout.Padding   = UDim.new(0, 4)
sLayout.SortOrder = Enum.SortOrder.LayoutOrder

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function getScreenCenter()
    local vs = Camera.ViewportSize
    return Vector2.new(vs.X / 2, vs.Y / 2)
end

local function getAbsCenter(obj)
    local p = obj.AbsolutePosition
    local s = obj.AbsoluteSize
    return Vector2.new(p.X + s.X/2, p.Y + s.Y/2)
end

local function distToCenter(obj)
    return (getAbsCenter(obj) - getScreenCenter()).Magnitude
end

local function isActuallyVisible(obj)
    local current = obj
    while current do
        if current:IsA("GuiObject") then
            if not current.Visible then return false end
        end
        if current:IsA("ScreenGui") then
            if not current.Enabled then return false end
            break
        end
        if current == game then break end
        current = current.Parent
    end
    return true
end

local function isPartOfInspector(obj)
    local current = obj
    while current do
        if current == ScreenGui then return true end
        current = current.Parent
    end
    return false
end

local function isPlayerChar(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

-------------------------------------------------
-- DETECTION METHOD 1: Tên gợi ý
-------------------------------------------------
local NAME_KEYWORDS = {
    -- Trực tiếp
    high = {"crosshair", "reticle", "aimpoint", "gunsight"},
    medium = {"aim", "cross", "sight", "scope", "cursor",
              "target", "dot", "hair", "recticle", "xhair"},
    low = {"center", "middle", "point", "marker", "indicator",
           "hud_center", "weapon_ui"},
}

local function scoreByName(obj)
    local name = obj.Name:lower()
    local score = 0
    local reason = {}

    for _, kw in ipairs(NAME_KEYWORDS.high) do
        if name:find(kw) then
            score += 35
            table.insert(reason, "Name chứa '" .. kw .. "' (+35)")
            break
        end
    end
    for _, kw in ipairs(NAME_KEYWORDS.medium) do
        if name:find(kw) then
            score += 20
            table.insert(reason, "Name chứa '" .. kw .. "' (+20)")
            break
        end
    end
    for _, kw in ipairs(NAME_KEYWORDS.low) do
        if name:find(kw) then
            score += 10
            table.insert(reason, "Name chứa '" .. kw .. "' (+10)")
            break
        end
    end

    -- Kiểm tra parent names
    local parent = obj.Parent
    if parent and parent:IsA("GuiObject") then
        local pname = parent.Name:lower()
        for _, kw in ipairs(NAME_KEYWORDS.high) do
            if pname:find(kw) then
                score += 25
                table.insert(reason, "Parent name '" .. kw .. "' (+25)")
                break
            end
        end
        for _, kw in ipairs(NAME_KEYWORDS.medium) do
            if pname:find(kw) then
                score += 15
                table.insert(reason, "Parent name '" .. kw .. "' (+15)")
                break
            end
        end
    end

    return score, reason
end

-------------------------------------------------
-- DETECTION METHOD 2: Vị trí (giữa màn hình)
-------------------------------------------------
local function scoreByPosition(obj)
    local dist = distToCenter(obj)
    local score = 0
    local reason = {}

    if dist < DETECT.CENTER_RADIUS_TIGHT then
        score += 30
        table.insert(reason, string.format("Rất gần center (%.0fpx) (+30)", dist))
    elseif dist < DETECT.CENTER_RADIUS_MEDIUM then
        score += 20
        table.insert(reason, string.format("Gần center (%.0fpx) (+20)", dist))
    elseif dist < DETECT.CENTER_RADIUS_WIDE then
        score += 8
        table.insert(reason, string.format("Vùng center (%.0fpx) (+8)", dist))
    end

    -- Bonus nếu AnchorPoint = (0.5, 0.5) VÀ Position scale ~0.5
    local pos = obj.Position
    if math.abs(pos.X.Scale - 0.5) < 0.05 and math.abs(pos.Y.Scale - 0.5) < 0.05 then
        score += 15
        table.insert(reason, "Position Scale ≈ (0.5, 0.5) (+15)")
    end

    local anchor = obj.AnchorPoint
    if math.abs(anchor.X - 0.5) < 0.1 and math.abs(anchor.Y - 0.5) < 0.1 then
        score += 5
        table.insert(reason, "AnchorPoint ≈ (0.5, 0.5) (+5)")
    end

    return score, reason
end

-------------------------------------------------
-- DETECTION METHOD 3: Kích thước (nhỏ)
-------------------------------------------------
local function scoreBySize(obj)
    local s = obj.AbsoluteSize
    local maxDim = math.max(s.X, s.Y)
    local minDim = math.min(s.X, s.Y)
    local score = 0
    local reason = {}

    if maxDim < 5 and maxDim >= 1 then
        -- Dot crosshair (chấm nhỏ)
        score += 25
        table.insert(reason, string.format("Rất nhỏ (dot) %.0f×%.0f (+25)", s.X, s.Y))
    elseif maxDim <= 50 then
        score += 20
        table.insert(reason, string.format("Nhỏ %.0f×%.0f (+20)", s.X, s.Y))
    elseif maxDim <= DETECT.MAX_CROSSHAIR_SIZE then
        score += 10
        table.insert(reason, string.format("Vừa %.0f×%.0f (+10)", s.X, s.Y))
    elseif maxDim > 200 then
        score -= 15
        table.insert(reason, string.format("Quá lớn %.0f×%.0f (-15)", s.X, s.Y))
    end

    -- Hình vuông hoặc gần vuông → có thể là dot/image crosshair
    if maxDim > 0 and maxDim < 80 then
        local ratio = minDim / maxDim
        if ratio > 0.8 then
            score += 5
            table.insert(reason, "Gần vuông/tròn (+5)")
        end
    end

    -- Thanh mỏng (cross line)
    if minDim <= DETECT.THIN_THRESHOLD and maxDim > 5 and maxDim < 80 then
        score += 15
        table.insert(reason, string.format("Thanh mỏng (cross line) %d×%d (+15)", s.X, s.Y))
    end

    return score, reason
end

-------------------------------------------------
-- DETECTION METHOD 4: Cross Pattern (nhiều thanh)
-------------------------------------------------
local function findCrossPattern(allObjs)
    local center = getScreenCenter()
    local patterns = {}

    -- Tìm các thanh mỏng gần center
    local horizontalBars = {}
    local verticalBars   = {}

    for _, obj in ipairs(allObjs) do
        local s = obj.AbsoluteSize
        local c = getAbsCenter(obj)
        local distC = (c - center).Magnitude

        if distC < DETECT.CENTER_RADIUS_MEDIUM then
            if s.X > s.Y * 2 and s.Y <= DETECT.THIN_THRESHOLD and s.X < 100 then
                table.insert(horizontalBars, obj)
            end
            if s.Y > s.X * 2 and s.X <= DETECT.THIN_THRESHOLD and s.Y < 100 then
                table.insert(verticalBars, obj)
            end
        end
    end

    -- Kiểm tra xem có cặp ngang + dọc không
    for _, hBar in ipairs(horizontalBars) do
        for _, vBar in ipairs(verticalBars) do
            local hCenter = getAbsCenter(hBar)
            local vCenter = getAbsCenter(vBar)
            local gap = (hCenter - vCenter).Magnitude

            if gap < DETECT.CROSS_GAP_TOLERANCE then
                table.insert(patterns, {
                    horizontal = hBar,
                    vertical   = vBar,
                    gap        = gap,
                    center     = (hCenter + vCenter) / 2,
                })
            end
        end
    end

    -- Tìm pattern 4 thanh (trên/dưới/trái/phải)
    -- Nhiều game dùng 4 Frame nhỏ thay vì 2
    local nearCenter = {}
    for _, obj in ipairs(allObjs) do
        local s = obj.AbsoluteSize
        local c = getAbsCenter(obj)
        local distC = (c - center).Magnitude
        local maxD = math.max(s.X, s.Y)
        local minD = math.min(s.X, s.Y)

        if distC < DETECT.CENTER_RADIUS_MEDIUM and minD <= 6 and maxD < 50 and maxD > 3 then
            table.insert(nearCenter, {obj = obj, center = c, size = s})
        end
    end

    if #nearCenter >= 4 then
        -- Tìm nhóm 4 thanh đối xứng
        for i = 1, #nearCenter do
            local group = {nearCenter[i]}
            local ref = nearCenter[i].center

            for j = 1, #nearCenter do
                if i ~= j then
                    local d = (nearCenter[j].center - ref).Magnitude
                    if d < 60 then
                        table.insert(group, nearCenter[j])
                    end
                end
            end

            if #group >= 4 then
                table.insert(patterns, {
                    type   = "4-line cross",
                    parts  = group,
                    count  = #group,
                })
            end
        end
    end

    return patterns
end

-------------------------------------------------
-- DETECTION METHOD 5: Image crosshair
-------------------------------------------------
local KNOWN_CROSSHAIR_IMAGES = {
    "crosshair", "reticle", "aim", "scope",
    "dot", "target", "sight", "cursor",
    "xhair", "cross_hair",
}

local function scoreByImage(obj)
    local score = 0
    local reason = {}

    if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
        return score, reason
    end

    local img = obj.Image:lower()
    if img == "" then return score, reason end

    -- Kiểm tra tên image asset
    for _, kw in ipairs(KNOWN_CROSSHAIR_IMAGES) do
        if img:find(kw) then
            score += 25
            table.insert(reason, "Image chứa '" .. kw .. "' (+25)")
            break
        end
    end

    -- rbxassetid nhỏ + ở center → có thể
    if img:find("rbxassetid") and distToCenter(obj) < DETECT.CENTER_RADIUS_MEDIUM then
        local s = obj.AbsoluteSize
        if math.max(s.X, s.Y) < DETECT.MAX_CROSSHAIR_SIZE then
            score += 10
            table.insert(reason, "Image asset nhỏ ở center (+10)")
        end
    end

    -- ImageTransparency thấp (đang hiện)
    if obj.ImageTransparency < 0.5 then
        score += 3
        table.insert(reason, "Image visible (+3)")
    end

    return score, reason
end

-------------------------------------------------
-- DETECTION METHOD 6: Transparency & Color
-------------------------------------------------
local function scoreByAppearance(obj)
    local score = 0
    local reason = {}

    -- Background transparency cao + ở center = overlay element
    if obj.BackgroundTransparency >= 0.9 then
        if distToCenter(obj) < DETECT.CENTER_RADIUS_MEDIUM then
            local s = obj.AbsoluteSize
            if math.max(s.X, s.Y) < DETECT.MAX_CROSSHAIR_SIZE then
                score += 5
                table.insert(reason, "Transparent overlay ở center (+5)")
            end
        end
    end

    -- Crosshair thường có màu trắng, đỏ, xanh lá, hoặc vàng
    local c = obj.BackgroundColor3
    local r, g, b = c.R, c.G, c.B
    if obj.BackgroundTransparency < 0.5 then
        -- Trắng
        if r > 0.9 and g > 0.9 and b > 0.9 then
            score += 3
            table.insert(reason, "Màu trắng (+3)")
        end
        -- Đỏ
        if r > 0.8 and g < 0.3 and b < 0.3 then
            score += 3
            table.insert(reason, "Màu đỏ (+3)")
        end
        -- Xanh lá
        if g > 0.8 and r < 0.3 and b < 0.3 then
            score += 3
            table.insert(reason, "Màu xanh lá (+3)")
        end
    end

    return score, reason
end

-------------------------------------------------
-- DETECTION METHOD 7: ZIndex & Hierarchy
-------------------------------------------------
local function scoreByLayer(obj)
    local score = 0
    local reason = {}

    -- ZIndex cao → overlay, có thể là HUD
    if obj.ZIndex >= 10 then
        score += 5
        table.insert(reason, string.format("ZIndex cao (%d) (+5)", obj.ZIndex))
    end

    -- Nằm trong ScreenGui có DisplayOrder cao
    local sg = obj:FindFirstAncestorOfClass("ScreenGui")
    if sg and sg.DisplayOrder >= 5 then
        score += 3
        table.insert(reason, string.format("ScreenGui DisplayOrder %d (+3)", sg.DisplayOrder))
    end

    -- Ít children → element cuối, không phải container
    if #obj:GetChildren() <= 1 then
        score += 3
        table.insert(reason, "Ít children (leaf node) (+3)")
    end

    return score, reason
end

-------------------------------------------------
-- DETECTION METHOD 8: Mouse Icon
-------------------------------------------------
local function detectMouseIcon()
    local results = {}

    -- Check Mouse.Icon
    local mouseIcon = Mouse.Icon
    if mouseIcon and mouseIcon ~= "" then
        table.insert(results, {
            method = "Mouse.Icon",
            value  = mouseIcon,
            note   = "Game đã thay đổi icon chuột"
        })
    end

    -- Check UserInputService.MouseIcon
    local uisIcon = UserInputService.MouseIconEnabled
    if not uisIcon then
        table.insert(results, {
            method = "MouseIcon Disabled",
            value  = "UserInputService.MouseIconEnabled = false",
            note   = "Game đã ẩn chuột → dùng custom crosshair"
        })
    end

    -- Check MouseBehavior
    local mb = UserInputService.MouseBehavior
    if mb == Enum.MouseBehavior.LockCenter then
        table.insert(results, {
            method = "MouseBehavior",
            value  = "LockCenter",
            note   = "Chuột bị khóa giữa → FPS mode, chắc chắn có crosshair"
        })
    elseif mb == Enum.MouseBehavior.LockCurrentPosition then
        table.insert(results, {
            method = "MouseBehavior",
            value  = "LockCurrentPosition",
            note   = "Chuột bị khóa vị trí"
        })
    end

    return results
end

-------------------------------------------------
-- DETECTION METHOD 9: Tracking qua thời gian
-------------------------------------------------
local trackingData = {} -- obj → {positions over time}

local function trackElement(obj)
    local key = obj:GetFullName()
    if not trackingData[key] then
        trackingData[key] = {
            positions = {},
            stayedCenter = 0,
            totalChecks  = 0,
        }
    end

    local data = trackingData[key]
    local c = getAbsCenter(obj)
    table.insert(data.positions, c)
    if #data.positions > 20 then
        table.remove(data.positions, 1)
    end

    data.totalChecks += 1
    if distToCenter(obj) < DETECT.CENTER_RADIUS_MEDIUM then
        data.stayedCenter += 1
    end

    return data
end

local function scoreByTracking(obj)
    local score = 0
    local reason = {}
    local key = obj:GetFullName()
    local data = trackingData[key]

    if not data or data.totalChecks < 3 then
        return score, reason
    end

    -- Luôn ở center qua nhiều frame
    local centerRatio = data.stayedCenter / data.totalChecks
    if centerRatio > 0.9 and data.totalChecks >= 5 then
        score += 20
        table.insert(reason, string.format(
            "Luôn ở center %.0f%% of %d checks (+20)",
            centerRatio * 100, data.totalChecks
        ))
    elseif centerRatio > 0.7 then
        score += 10
        table.insert(reason, string.format(
            "Thường ở center %.0f%% (+10)", centerRatio * 100
        ))
    end

    -- Kiểm tra có di chuyển không (crosshair thường đứng yên tại center)
    if #data.positions >= 3 then
        local totalMovement = 0
        for i = 2, #data.positions do
            totalMovement += (data.positions[i] - data.positions[i-1]).Magnitude
        end
        local avgMovement = totalMovement / (#data.positions - 1)

        if avgMovement < 2 then
            score += 8
            table.insert(reason, string.format(
                "Rất ít di chuyển (avg %.1fpx) (+8)", avgMovement
            ))
        end
    end

    return score, reason
end

-------------------------------------------------
-- MASTER ANALYSIS
-------------------------------------------------
local function analyzeAll()
    local center = getScreenCenter()
    local allVisible = {}
    local candidates = {}

    -- Thu thập tất cả visible GUI objects
    for _, sg in ipairs(PlayerGui:GetChildren()) do
        if sg:IsA("ScreenGui") and sg ~= ScreenGui and sg.Enabled then
            for _, obj in ipairs(sg:GetDescendants()) do
                if obj:IsA("GuiObject") and isActuallyVisible(obj) then
                    table.insert(allVisible, obj)
                end
            end
        end
    end

    -- Cross pattern detection
    local crossPatterns = findCrossPattern(allVisible)

    -- Phân tích từng element
    for _, obj in ipairs(allVisible) do
        local totalScore = 0
        local allReasons = {}
        local methods    = {}

        -- Method 1: Name
        local s1, r1 = scoreByName(obj)
        totalScore += s1
        if s1 > 0 then
            table.insert(methods, "📛 Name")
            for _, r in ipairs(r1) do table.insert(allReasons, r) end
        end

        -- Method 2: Position
        local s2, r2 = scoreByPosition(obj)
        totalScore += s2
        if s2 > 0 then
            table.insert(methods, "📍 Position")
            for _, r in ipairs(r2) do table.insert(allReasons, r) end
        end

        -- Method 3: Size
        local s3, r3 = scoreBySize(obj)
        totalScore += s3
        if s3 > 0 then
            table.insert(methods, "📏 Size")
            for _, r in ipairs(r3) do table.insert(allReasons, r) end
        end
        if s3 < 0 then
            totalScore += s3
            for _, r in ipairs(r3) do table.insert(allReasons, r) end
        end

        -- Method 4: Image
        local s4, r4 = scoreByImage(obj)
        totalScore += s4
        if s4 > 0 then
            table.insert(methods, "🖼️ Image")
            for _, r in ipairs(r4) do table.insert(allReasons, r) end
        end

        -- Method 5: Appearance
        local s5, r5 = scoreByAppearance(obj)
        totalScore += s5
        if s5 > 0 then
            table.insert(methods, "🎨 Look")
            for _, r in ipairs(r5) do table.insert(allReasons, r) end
        end

        -- Method 6: Layer
        local s6, r6 = scoreByLayer(obj)
        totalScore += s6
        if s6 > 0 then
            table.insert(methods, "📊 Layer")
            for _, r in ipairs(r6) do table.insert(allReasons, r) end
        end

        -- Method 7: Tracking
        trackElement(obj)
        local s7, r7 = scoreByTracking(obj)
        totalScore += s7
        if s7 > 0 then
            table.insert(methods, "⏱️ Track")
            for _, r in ipairs(r7) do table.insert(allReasons, r) end
        end

        -- Cross pattern bonus
        for _, pattern in ipairs(crossPatterns) do
            if pattern.horizontal == obj or pattern.vertical == obj then
                totalScore += 30
                table.insert(allReasons, "Là một phần của cross pattern (+30)")
                table.insert(methods, "✚ Cross")
            end
            if pattern.parts then
                for _, p in ipairs(pattern.parts) do
                    if p.obj == obj then
                        totalScore += 25
                        table.insert(allReasons, "Thuộc 4-line cross pattern (+25)")
                        table.insert(methods, "✚ Cross4")
                    end
                end
            end
        end

        -- Chỉ lưu nếu có score
        if totalScore >= 15 then
            table.insert(candidates, {
                obj        = obj,
                score      = totalScore,
                reasons    = allReasons,
                methods    = methods,
                dist       = distToCenter(obj),
                absPos     = obj.AbsolutePosition,
                absSize    = obj.AbsoluteSize,
                path       = obj:GetFullName(),
            })
        end
    end

    -- Sort theo score giảm dần
    table.sort(candidates, function(a, b) return a.score > b.score end)

    return candidates, crossPatterns, allVisible
end

-------------------------------------------------
-- RENDER
-------------------------------------------------
local activeEntries = {}
local highlightFrames = {}

local function clearAll()
    for _, e in ipairs(activeEntries) do e:Destroy() end
    table.clear(activeEntries)
    for _, h in ipairs(highlightFrames) do
        if h.Parent then h:Destroy() end
    end
    table.clear(highlightFrames)
end

local function addHighlight(obj, color)
    pcall(function()
        local h = Instance.new("Frame")
        h.Name                  = "_CrosshairHighlight"
        h.Size                  = UDim2.new(1, 6, 1, 6)
        h.Position              = UDim2.new(0, -3, 0, -3)
        h.BackgroundTransparency = 1
        h.ZIndex                = 99999
        h.Parent                = obj

        local s = Instance.new("UIStroke", h)
        s.Color     = color
        s.Thickness = 2

        -- Nhấp nháy
        task.spawn(function()
            while h.Parent do
                s.Transparency = 0
                task.wait(0.4)
                if not h.Parent then break end
                s.Transparency = 0.6
                task.wait(0.4)
            end
        end)

        table.insert(highlightFrames, h)
    end)
end

local function createEntry(parent, order, text, bgColor)
    local e = Instance.new("TextLabel")
    e.Size                  = UDim2.new(1, -6, 0, 0)
    e.AutomaticSize         = Enum.AutomaticSize.Y
    e.BackgroundColor3      = bgColor or Color3.fromRGB(25, 25, 40)
    e.BackgroundTransparency = 0.2
    e.TextColor3            = Color3.fromRGB(220, 220, 220)
    e.Font                  = Enum.Font.RobotoMono
    e.TextSize              = 12
    e.TextXAlignment        = Enum.TextXAlignment.Left
    e.TextYAlignment        = Enum.TextYAlignment.Top
    e.TextWrapped           = true
    e.RichText              = true
    e.LayoutOrder           = order
    e.Text                  = text
    e.BorderSizePixel       = 0
    e.Parent                = parent
    Instance.new("UICorner", e).CornerRadius = UDim.new(0, 6)
    local pad = Instance.new("UIPadding", e)
    pad.PaddingLeft   = UDim.new(0, 8)
    pad.PaddingRight  = UDim.new(0, 8)
    pad.PaddingTop    = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    table.insert(activeEntries, e)
    return e
end

local function getConfidenceLabel(score)
    if score >= 80 then
        return '<font color="#FF0000"><b>🔴 CHẮC CHẮN CROSSHAIR</b></font>'
    elseif score >= 60 then
        return '<font color="#FF8800"><b>🟠 RẤT CÓ THỂ LÀ CROSSHAIR</b></font>'
    elseif score >= 40 then
        return '<font color="#FFDD00"><b>🟡 KHẢ NĂNG LÀ CROSSHAIR</b></font>'
    elseif score >= 25 then
        return '<font color="#88CCFF">🔵 Có thể liên quan</font>'
    else
        return '<font color="#888888">⚪ Ít khả năng</font>'
    end
end

local function render()
    clearAll()

    local candidates, patterns, allVisible = analyzeAll()
    local mouseInfo = detectMouseIcon()

    -- Stats
    local statsLines = {}
    table.insert(statsLines, string.format(
        '<font color="#00C8FF">Scanned:</font> %d elements  |  '..
        '<font color="#FF4444">Candidates:</font> %d  |  '..
        '<font color="#FFAA00">Cross Patterns:</font> %d',
        #allVisible, #candidates, #patterns
    ))

    -- Mouse info
    for _, m in ipairs(mouseInfo) do
        table.insert(statsLines, string.format(
            '<font color="#FF88FF">%s:</font> %s — <i>%s</i>',
            m.method, m.value, m.note
        ))
    end

    StatsLabel.Text = table.concat(statsLines, "\n")

    local order = 0

    -- Nếu phát hiện mouse bị ẩn/khóa
    if #mouseInfo > 0 then
        order += 1
        local mouseText = '<font color="#FF88FF"><b>━━━ 🖱️ MOUSE/CURSOR INFO ━━━</b></font>\n'
        for _, m in ipairs(mouseInfo) do
            mouseText ..= string.format(
                '<font color="#FFAAFF">%s:</font> %s\n  → %s\n',
                m.method, m.value, m.note
            )
        end
        createEntry(Scroll, order, mouseText, Color3.fromRGB(40, 20, 40))
    end

    -- Crosshair candidates
    if #candidates > 0 then
        order += 1
        createEntry(Scroll, order,
            '<font color="#FF4444"><b>━━━ 🎯 CROSSHAIR CANDIDATES (sorted by confidence) ━━━</b></font>',
            Color3.fromRGB(40, 15, 15)
        )

        for idx, cand in ipairs(candidates) do
            if idx > 30 then break end
            order += 1

            local lines = {}

            -- Confidence + methods used
            table.insert(lines, string.format(
                '%s  Score: <font color="#FFFFFF"><b>%d</b></font>',
                getConfidenceLabel(cand.score), cand.score
            ))
            table.insert(lines, string.format(
                '<font color="#AAAAAA">Detection methods:</font> %s',
                table.concat(cand.methods, " + ")
            ))

            -- Object info
            table.insert(lines, string.format(
                '<font color="#FFD700">Name:</font> %s  <font color="#AAAAAA">[%s]</font>',
                cand.obj.Name, cand.obj.ClassName
            ))

            -- Position & Size
            local pos = cand.obj.Position
            local siz = cand.obj.Size
            table.insert(lines, string.format(
                '<font color="#88CCFF">Position:</font> Scale(%.3f, %.3f) Offset(%d, %d)',
                pos.X.Scale, pos.Y.Scale, pos.X.Offset, pos.Y.Offset
            ))
            table.insert(lines, string.format(
                '<font color="#88FFCC">Size:</font> Scale(%.3f, %.3f) Offset(%d, %d)',
                siz.X.Scale, siz.Y.Scale, siz.X.Offset, siz.Y.Offset
            ))
            table.insert(lines, string.format(
                '<font color="#FFAA44">Absolute:</font> Pos(%.0f,%.0f) Size(%.0f,%.0f)  '..
                '<font color="#FFAA44">Dist→Center:</font> %.1fpx',
                cand.absPos.X, cand.absPos.Y,
                cand.absSize.X, cand.absSize.Y,
                cand.dist
            ))

            -- Anchor, ZIndex
            local anchor = cand.obj.AnchorPoint
            table.insert(lines, string.format(
                '<font color="#AAAAAA">Anchor:</font> (%.1f,%.1f)  '..
                '<font color="#AAAAAA">ZIndex:</font> %d  '..
                '<font color="#AAAAAA">Rotation:</font> %.1f°  '..
                '<font color="#AAAAAA">BgTransp:</font> %.2f',
                anchor.X, anchor.Y,
                cand.obj.ZIndex,
                cand.obj.Rotation,
                cand.obj.BackgroundTransparency
            ))

            -- Image nếu có
            if cand.obj:IsA("ImageLabel") or cand.obj:IsA("ImageButton") then
                local img = cand.obj.Image
                if img ~= "" then
                    table.insert(lines, string.format(
                        '<font color="#AA88FF">Image:</font> %s', img
                    ))
                end
            end

            -- Text nếu có
            if (cand.obj:IsA("TextLabel") or cand.obj:IsA("TextButton")) then
                local txt = cand.obj.Text
                if txt ~= "" then
                    txt = txt:sub(1, 40):gsub("<", "&lt;"):gsub(">", "&gt;")
                    table.insert(lines, string.format(
                        '<font color="#FFFFFF">Text:</font> "%s"', txt
                    ))
                end
            end

            -- Reasons
            table.insert(lines, '<font color="#666666">Lý do phát hiện:</font>')
            for _, reason in ipairs(cand.reasons) do
                table.insert(lines, '  <font color="#888888">• ' .. reason .. '</font>')
            end

            -- Path
            table.insert(lines, string.format(
                '<font color="#555555">Path: %s</font>', cand.path
            ))

            -- Chọn màu background theo score
            local bgColor
            if cand.score >= 80 then
                bgColor = Color3.fromRGB(50, 15, 15)
            elseif cand.score >= 60 then
                bgColor = Color3.fromRGB(45, 30, 10)
            elseif cand.score >= 40 then
                bgColor = Color3.fromRGB(40, 40, 10)
            else
                bgColor = Color3.fromRGB(25, 25, 40)
            end

            createEntry(Scroll, order, table.concat(lines, "\n"), bgColor)

            -- Highlight trên màn hình
            if cand.score >= DETECT.MIN_CONFIDENCE then
                local hColor
                if cand.score >= 80 then
                    hColor = Color3.fromRGB(255, 0, 0)
                elseif cand.score >= 60 then
                    hColor = Color3.fromRGB(255, 140, 0)
                else
                    hColor = Color3.fromRGB(255, 255, 0)
                end
                addHighlight(cand.obj, hColor)
            end
        end
    else
        order += 1
        createEntry(Scroll, order,
            '<font color="#FFAA00"><b>Không phát hiện crosshair nào.</b></font>\n' ..
            '<font color="#AAAAAA">Có thể game dùng:\n' ..
            '• Drawing API (không detect được từ Lua)\n' ..
            '• Mouse.Icon thay đổi\n' ..
            '• BillboardGui trong 3D space\n' ..
            '• Crosshair chưa được tạo (chưa equip weapon)</font>',
            Color3.fromRGB(35, 30, 15)
        )
    end

    -- Cross pattern details
    if #patterns > 0 then
        order += 1
        createEntry(Scroll, order,
            '<font color="#00FF88"><b>━━━ ✚ CROSS PATTERNS DETECTED ━━━</b></font>',
            Color3.fromRGB(10, 40, 20)
        )
        for pidx, pat in ipairs(patterns) do
            order += 1
            local pText
            if pat.horizontal then
                pText = string.format(
                    '<font color="#00FF88">Cross Pattern #%d</font>\n' ..
                    '  Horizontal: %s (%.0f×%.0f)\n' ..
                    '  Vertical: %s (%.0f×%.0f)\n' ..
                    '  Gap: %.1fpx  Center: (%.0f, %.0f)',
                    pidx,
                    pat.horizontal.Name,
                    pat.horizontal.AbsoluteSize.X, pat.horizontal.AbsoluteSize.Y,
                    pat.vertical.Name,
                    pat.vertical.AbsoluteSize.X, pat.vertical.AbsoluteSize.Y,
                    pat.gap,
                    pat.center.X, pat.center.Y
                )
            else
                pText = string.format(
                    '<font color="#00FF88">Multi-Line Cross Pattern</font>\n' ..
                    '  Type: %s  Parts: %d',
                    pat.type or "unknown", pat.count or 0
                )
            end
            createEntry(Scroll, order, pText, Color3.fromRGB(15, 35, 20))
        end
    end
end

-------------------------------------------------
-- TOGGLE
-------------------------------------------------
local isOpen = false
local updateConn = nil

local function setOpen(state)
    isOpen = state
    Panel.Visible = isOpen

    if isOpen then
        ToggleBtn.Text = "🎯 Detector ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)

        render()

        if updateConn then updateConn:Disconnect() end
        local elapsed = 0
        updateConn = RunService.Heartbeat:Connect(function(dt)
            elapsed += dt
            if elapsed >= 1.5 then
                elapsed = 0
                render()
            end
        end)
    else
        ToggleBtn.Text = "🎯 Detector OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)

        clearAll()
        if updateConn then
            updateConn:Disconnect()
            updateConn = nil
        end
    end
end

ToggleBtn.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
CloseBtn.MouseButton1Click:Connect(function() setOpen(false) end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F3 then setOpen(not isOpen) end
end)

print("🎯 Crosshair Detector loaded — F3 or button to toggle")
