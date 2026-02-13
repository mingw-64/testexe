--[[
    Mobile-First Crosshair Detector
    Tự động scale theo màn hình
    LocalScript → StarterGui
    
    Hoạt động trên: Mobile / Tablet / PC
    + Name Tags bên dưới mỗi box
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-------------------------------------------------
-- AUTO DETECT DEVICE
-------------------------------------------------
local IS_MOBILE  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IS_TABLET  = IS_MOBILE and (Camera.ViewportSize.X > 1000)
local IS_PC      = UserInputService.KeyboardEnabled

local DEVICE_NAME = IS_MOBILE and (IS_TABLET and "Tablet" or "Phone") or "PC"

-------------------------------------------------
-- RESPONSIVE CONFIG
-------------------------------------------------
local function getScale()
    local vp = Camera.ViewportSize
    local shortSide = math.min(vp.X, vp.Y)
    if shortSide < 400 then return 0.65 end
    if shortSide < 600 then return 0.75 end
    if shortSide < 900 then return 0.85 end
    return 1
end

local UI_SCALE = getScale()

local function S(pixels)
    return math.floor(pixels * UI_SCALE)
end

local DETECT = {
    CENTER_RADIUS_TIGHT  = 40,
    CENTER_RADIUS_MEDIUM = 80,
    CENTER_RADIUS_WIDE   = 150,
    MAX_CROSSHAIR_SIZE   = 120,
    MIN_CROSSHAIR_SIZE   = 1,
    THIN_THRESHOLD       = 8,
    CROSS_GAP_TOLERANCE  = 15,
    MIN_CONFIDENCE       = 40,
}

-------------------------------------------------
-- GUI CREATION
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "MobileCrosshairDetector"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 99999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = PlayerGui

-- ═══════════════════════════════════════
-- TOGGLE BUTTON
-- ═══════════════════════════════════════
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name              = "ToggleBtn"
ToggleBtn.BackgroundColor3  = Color3.fromRGB(180, 30, 30)
ToggleBtn.TextColor3        = Color3.new(1, 1, 1)
ToggleBtn.Font              = Enum.Font.GothamBold
ToggleBtn.BorderSizePixel   = 0
ToggleBtn.ZIndex            = 100
ToggleBtn.Text              = "🎯 OFF"
ToggleBtn.Parent            = ScreenGui

if IS_MOBILE then
    ToggleBtn.Size     = UDim2.new(0, S(120), 0, S(50))
    ToggleBtn.Position = UDim2.new(0, S(10), 0, S(40))
    ToggleBtn.TextSize = S(14)
else
    ToggleBtn.Size     = UDim2.new(0, 140, 0, 40)
    ToggleBtn.Position = UDim2.new(1, -150, 0, 10)
    ToggleBtn.TextSize = 14
end
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, S(10))
local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = Color3.new(1,1,1); tStroke.Transparency = 0.5; tStroke.Thickness = S(2)

-- ═══════════════════════════════════════
-- MAIN PANEL
-- ═══════════════════════════════════════
local Panel = Instance.new("Frame")
Panel.Name              = "MainPanel"
Panel.BackgroundColor3  = Color3.fromRGB(10, 10, 20)
Panel.BorderSizePixel   = 0
Panel.Visible           = false
Panel.Active            = true
Panel.Parent            = ScreenGui
Panel.ZIndex            = 50
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, S(14))
local pStroke = Instance.new("UIStroke", Panel)
pStroke.Color = Color3.fromRGB(255, 60, 60); pStroke.Thickness = S(2)

if IS_MOBILE and not IS_TABLET then
    Panel.Size     = UDim2.new(0.95, 0, 0.8, 0)
    Panel.Position = UDim2.new(0.025, 0, 0.1, 0)
else
    Panel.Size     = UDim2.new(0, S(540), 0, S(580))
    Panel.Position = UDim2.new(0.5, -S(270), 0.5, -S(290))
end

-- ═══════════════════════════════════════
-- DRAGGING
-- ═══════════════════════════════════════
local dragging    = false
local dragStart   = nil
local startPos    = nil

local function onDragStart(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = Panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end

local function onDragMove(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        Panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, S(48))
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 51
TitleBar.Parent           = Panel
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, S(14))

local titleFix = Instance.new("Frame")
titleFix.Size             = UDim2.new(1, 0, 0, S(14))
titleFix.Position         = UDim2.new(0, 0, 1, -S(14))
titleFix.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
titleFix.BorderSizePixel  = 0
titleFix.ZIndex           = 51
titleFix.Parent           = TitleBar

TitleBar.InputBegan:Connect(onDragStart)
TitleBar.InputChanged:Connect(onDragMove)
UserInputService.InputChanged:Connect(onDragMove)

-- Title Label
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size                   = UDim2.new(1, -S(90), 1, 0)
TitleLabel.Position               = UDim2.new(0, S(12), 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font                   = Enum.Font.GothamBold
TitleLabel.TextColor3             = Color3.fromRGB(255, 80, 80)
TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
TitleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
TitleLabel.RichText               = true
TitleLabel.ZIndex                 = 52
TitleLabel.Parent                 = TitleBar

if IS_MOBILE and not IS_TABLET then
    TitleLabel.TextSize = S(13)
    TitleLabel.Text     = "🎯 Crosshair Detector"
else
    TitleLabel.TextSize = S(15)
    TitleLabel.Text     = "🎯 Crosshair Detector — " .. DEVICE_NAME
end

-- Device Badge
local DeviceBadge = Instance.new("TextLabel")
DeviceBadge.Size             = UDim2.new(0, S(70), 0, S(22))
DeviceBadge.Position         = UDim2.new(1, -S(110), 0.5, -S(11))
DeviceBadge.BackgroundColor3 = IS_MOBILE
    and Color3.fromRGB(0, 120, 200)
    or Color3.fromRGB(100, 60, 200)
DeviceBadge.TextColor3       = Color3.new(1, 1, 1)
DeviceBadge.Font             = Enum.Font.GothamBold
DeviceBadge.TextSize         = S(11)
DeviceBadge.Text             = IS_MOBILE and "📱 Mobile" or "💻 PC"
DeviceBadge.BorderSizePixel  = 0
DeviceBadge.ZIndex           = 52
DeviceBadge.Parent           = TitleBar
Instance.new("UICorner", DeviceBadge).CornerRadius = UDim.new(0, S(6))

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, S(38), 0, S(38))
CloseBtn.Position         = UDim2.new(1, -S(42), 0, S(5))
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.TextColor3       = Color3.new(1, 1, 1)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = S(20)
CloseBtn.Text             = "✕"
CloseBtn.BorderSizePixel  = 0
CloseBtn.ZIndex           = 52
CloseBtn.Parent           = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, S(8))

-- ═══════════════════════════════════════
-- INFO BAR
-- ═══════════════════════════════════════
local InfoBar = Instance.new("TextLabel")
InfoBar.Size                   = UDim2.new(1, -S(16), 0, S(45))
InfoBar.Position               = UDim2.new(0, S(8), 0, S(52))
InfoBar.BackgroundColor3       = Color3.fromRGB(20, 20, 35)
InfoBar.BackgroundTransparency = 0.3
InfoBar.TextColor3             = Color3.fromRGB(180, 180, 180)
InfoBar.Font                   = Enum.Font.RobotoMono
InfoBar.TextSize               = S(11)
InfoBar.TextXAlignment         = Enum.TextXAlignment.Left
InfoBar.TextYAlignment         = Enum.TextYAlignment.Top
InfoBar.TextWrapped            = true
InfoBar.RichText               = true
InfoBar.BorderSizePixel        = 0
InfoBar.ZIndex                 = 51
InfoBar.Text                   = ""
InfoBar.Parent                 = Panel
Instance.new("UICorner", InfoBar).CornerRadius = UDim.new(0, S(8))
local infoPad = Instance.new("UIPadding", InfoBar)
infoPad.PaddingLeft = UDim.new(0, S(8)); infoPad.PaddingTop = UDim.new(0, S(4))

-- ═══════════════════════════════════════
-- SCROLL FRAME
-- ═══════════════════════════════════════
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                   = UDim2.new(1, -S(12), 1, -S(105))
Scroll.Position               = UDim2.new(0, S(6), 0, S(100))
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel        = 0
Scroll.ScrollBarThickness     = IS_MOBILE and S(8) or S(6)
Scroll.ScrollBarImageColor3   = Color3.fromRGB(255, 80, 80)
Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
Scroll.ZIndex                 = 51
Scroll.ElasticBehavior        = Enum.ElasticBehavior.Always
Scroll.ScrollingDirection     = Enum.ScrollingDirection.Y
Scroll.Parent                 = Panel

local sPad = Instance.new("UIPadding", Scroll)
sPad.PaddingTop    = UDim.new(0, S(4))
sPad.PaddingBottom = UDim.new(0, S(4))
sPad.PaddingLeft   = UDim.new(0, S(2))
sPad.PaddingRight  = UDim.new(0, S(2))

local sLayout = Instance.new("UIListLayout", Scroll)
sLayout.Padding   = UDim.new(0, S(4))
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

-- ═══════════════════════════════════════════════
-- HELPER: Rút gọn path cho dễ đọc
-- ═══════════════════════════════════════════════
local function getShortPath(obj)
    local parts = {}
    local current = obj
    local count = 0
    while current and current ~= game and count < 5 do
        table.insert(parts, 1, current.Name)
        current = current.Parent
        count += 1
    end
    if current and current ~= game then
        table.insert(parts, 1, "…")
    end
    return table.concat(parts, " › ")
end

-- ═══════════════════════════════════════════════
-- HELPER: Emoji theo class
-- ═══════════════════════════════════════════════
local function getClassEmoji(className)
    local map = {
        ImageLabel  = "🖼️",
        ImageButton = "🖼️",
        TextLabel   = "📝",
        TextButton  = "🔘",
        TextBox     = "📦",
        Frame       = "📐",
        ViewportFrame = "🎥",
        VideoFrame  = "🎬",
        ScrollingFrame = "📜",
    }
    return map[className] or "◻️"
end

-------------------------------------------------
-- 9 DETECTION METHODS
-------------------------------------------------
local NAME_KEYWORDS = {
    high   = {"crosshair","reticle","aimpoint","gunsight","xhair"},
    medium = {"aim","cross","sight","scope","cursor","target","dot","hair"},
    low    = {"center","middle","point","marker","indicator","hud"},
}

local function scoreByName(obj)
    local name = obj.Name:lower()
    local score, reasons = 0, {}

    for _, kw in ipairs(NAME_KEYWORDS.high) do
        if name:find(kw) then
            score += 35; table.insert(reasons, "Name='"..kw.."' +35"); break
        end
    end
    for _, kw in ipairs(NAME_KEYWORDS.medium) do
        if name:find(kw) then
            score += 20; table.insert(reasons, "Name='"..kw.."' +20"); break
        end
    end
    for _, kw in ipairs(NAME_KEYWORDS.low) do
        if name:find(kw) then
            score += 10; table.insert(reasons, "Name='"..kw.."' +10"); break
        end
    end

    local p = obj.Parent
    if p and p:IsA("GuiObject") then
        local pn = p.Name:lower()
        for _, kw in ipairs(NAME_KEYWORDS.high) do
            if pn:find(kw) then
                score += 25; table.insert(reasons, "Parent='"..kw.."' +25"); break
            end
        end
        for _, kw in ipairs(NAME_KEYWORDS.medium) do
            if pn:find(kw) then
                score += 15; table.insert(reasons, "Parent='"..kw.."' +15"); break
            end
        end
    end

    if p and p.Parent and p.Parent:IsA("GuiObject") then
        local gn = p.Parent.Name:lower()
        for _, kw in ipairs(NAME_KEYWORDS.high) do
            if gn:find(kw) then
                score += 15; table.insert(reasons, "Grandparent='"..kw.."' +15"); break
            end
        end
    end

    return score, reasons
end

local function scoreByPosition(obj)
    local dist = distToCenter(obj)
    local score, reasons = 0, {}

    if dist < DETECT.CENTER_RADIUS_TIGHT then
        score += 30
        table.insert(reasons, string.format("Center %.0fpx +30", dist))
    elseif dist < DETECT.CENTER_RADIUS_MEDIUM then
        score += 20
        table.insert(reasons, string.format("Near center %.0fpx +20", dist))
    elseif dist < DETECT.CENTER_RADIUS_WIDE then
        score += 8
        table.insert(reasons, string.format("Center area %.0fpx +8", dist))
    end

    local pos = obj.Position
    if math.abs(pos.X.Scale - 0.5) < 0.05 and math.abs(pos.Y.Scale - 0.5) < 0.05 then
        score += 15
        table.insert(reasons, "Scale≈0.5 +15")
    end

    local anchor = obj.AnchorPoint
    if math.abs(anchor.X - 0.5) < 0.1 and math.abs(anchor.Y - 0.5) < 0.1 then
        score += 5
        table.insert(reasons, "Anchor≈0.5 +5")
    end

    return score, reasons
end

local function scoreBySize(obj)
    local s = obj.AbsoluteSize
    local maxD = math.max(s.X, s.Y)
    local minD = math.min(s.X, s.Y)
    local score, reasons = 0, {}

    if maxD < 5 and maxD >= 1 then
        score += 25
        table.insert(reasons, string.format("Dot %.0f×%.0f +25", s.X, s.Y))
    elseif maxD <= 50 then
        score += 20
        table.insert(reasons, string.format("Small %.0f×%.0f +20", s.X, s.Y))
    elseif maxD <= DETECT.MAX_CROSSHAIR_SIZE then
        score += 10
        table.insert(reasons, string.format("Medium %.0f×%.0f +10", s.X, s.Y))
    elseif maxD > 200 then
        score -= 15
        table.insert(reasons, string.format("Too big %.0f×%.0f -15", s.X, s.Y))
    end

    if maxD > 0 and maxD < 80 and minD/maxD > 0.8 then
        score += 5
        table.insert(reasons, "Square +5")
    end

    if minD <= DETECT.THIN_THRESHOLD and maxD > 5 and maxD < 80 then
        score += 15
        table.insert(reasons, string.format("Thin bar %d×%d +15", s.X, s.Y))
    end

    return score, reasons
end

local function scoreByImage(obj)
    local score, reasons = 0, {}
    if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then return score, reasons end

    local img = obj.Image:lower()
    if img == "" then return score, reasons end

    local imgKW = {"crosshair","reticle","aim","scope","dot","target","sight","cursor","xhair"}
    for _, kw in ipairs(imgKW) do
        if img:find(kw) then
            score += 25; table.insert(reasons, "Image='"..kw.."' +25"); break
        end
    end

    if img:find("rbxassetid") and distToCenter(obj) < DETECT.CENTER_RADIUS_MEDIUM then
        local s = obj.AbsoluteSize
        if math.max(s.X, s.Y) < DETECT.MAX_CROSSHAIR_SIZE then
            score += 10; table.insert(reasons, "Asset@center +10")
        end
    end

    return score, reasons
end

local function scoreByAppearance(obj)
    local score, reasons = 0, {}

    if obj.BackgroundTransparency >= 0.9 and distToCenter(obj) < DETECT.CENTER_RADIUS_MEDIUM then
        local s = obj.AbsoluteSize
        if math.max(s.X, s.Y) < DETECT.MAX_CROSSHAIR_SIZE then
            score += 5; table.insert(reasons, "Transparent@center +5")
        end
    end

    if obj.BackgroundTransparency < 0.5 then
        local c = obj.BackgroundColor3
        if c.R > 0.9 and c.G > 0.9 and c.B > 0.9 then
            score += 3; table.insert(reasons, "White +3")
        elseif c.R > 0.8 and c.G < 0.3 then
            score += 3; table.insert(reasons, "Red +3")
        elseif c.G > 0.8 and c.R < 0.3 then
            score += 3; table.insert(reasons, "Green +3")
        end
    end

    return score, reasons
end

local function scoreByLayer(obj)
    local score, reasons = 0, {}

    if obj.ZIndex >= 10 then
        score += 5; table.insert(reasons, "ZIndex="..obj.ZIndex.." +5")
    end

    local sg = obj:FindFirstAncestorOfClass("ScreenGui")
    if sg and sg.DisplayOrder >= 5 then
        score += 3; table.insert(reasons, "DisplayOrder="..sg.DisplayOrder.." +3")
    end

    if #obj:GetChildren() <= 1 then
        score += 3; table.insert(reasons, "Leaf node +3")
    end

    return score, reasons
end

local function findCrossPatterns(allObjs)
    local center = getScreenCenter()
    local patterns = {}
    local hBars, vBars = {}, {}

    for _, obj in ipairs(allObjs) do
        local s = obj.AbsoluteSize
        local d = (getAbsCenter(obj) - center).Magnitude

        if d < DETECT.CENTER_RADIUS_MEDIUM then
            if s.X > s.Y * 2 and s.Y <= DETECT.THIN_THRESHOLD and s.X < 100 then
                table.insert(hBars, obj)
            end
            if s.Y > s.X * 2 and s.X <= DETECT.THIN_THRESHOLD and s.Y < 100 then
                table.insert(vBars, obj)
            end
        end
    end

    for _, h in ipairs(hBars) do
        for _, v in ipairs(vBars) do
            local gap = (getAbsCenter(h) - getAbsCenter(v)).Magnitude
            if gap < DETECT.CROSS_GAP_TOLERANCE then
                table.insert(patterns, {h = h, v = v, gap = gap})
            end
        end
    end

    return patterns
end

local trackData = {}

local function scoreByTracking(obj)
    local key = obj:GetFullName()
    local score, reasons = 0, {}

    if not trackData[key] then
        trackData[key] = {center = 0, total = 0}
    end

    local d = trackData[key]
    d.total += 1
    if distToCenter(obj) < DETECT.CENTER_RADIUS_MEDIUM then
        d.center += 1
    end

    if d.total >= 3 then
        local ratio = d.center / d.total
        if ratio > 0.9 then
            score += 20
            table.insert(reasons, string.format("Always center %.0f%% +20", ratio*100))
        elseif ratio > 0.7 then
            score += 10
            table.insert(reasons, string.format("Often center %.0f%% +10", ratio*100))
        end
    end

    return score, reasons
end

local function detectMouse()
    local results = {}

    if Mouse.Icon ~= "" then
        table.insert(results, {
            info = "🖱️ Mouse.Icon = " .. Mouse.Icon,
            note = "Custom cursor"
        })
    end

    if not UserInputService.MouseIconEnabled then
        table.insert(results, {
            info = "🖱️ Mouse HIDDEN",
            note = "Ẩn chuột → chắc có custom crosshair"
        })
    end

    local mb = UserInputService.MouseBehavior
    if mb == Enum.MouseBehavior.LockCenter then
        table.insert(results, {
            info = "🖱️ Mouse LOCKED CENTER",
            note = "FPS mode → crosshair"
        })
    end

    return results
end

-------------------------------------------------
-- MASTER ANALYZE
-------------------------------------------------
local function analyze()
    local allVisible = {}

    for _, sg in ipairs(PlayerGui:GetChildren()) do
        if sg:IsA("ScreenGui") and sg ~= ScreenGui and sg.Enabled then
            for _, obj in ipairs(sg:GetDescendants()) do
                if obj:IsA("GuiObject") and isActuallyVisible(obj) then
                    table.insert(allVisible, obj)
                end
            end
        end
    end

    local patterns = findCrossPatterns(allVisible)
    local candidates = {}

    local patternObjs = {}
    for _, p in ipairs(patterns) do
        patternObjs[p.h] = true
        patternObjs[p.v] = true
    end

    for _, obj in ipairs(allVisible) do
        local totalScore = 0
        local allReasons = {}
        local methods    = {}

        local scoreFuncs = {
            {"📛", scoreByName},
            {"📍", scoreByPosition},
            {"📏", scoreBySize},
            {"🖼️", scoreByImage},
            {"🎨", scoreByAppearance},
            {"📊", scoreByLayer},
            {"⏱️", scoreByTracking},
        }

        for _, sf in ipairs(scoreFuncs) do
            local s, r = sf[2](obj)
            totalScore += s
            if s ~= 0 then
                table.insert(methods, sf[1])
                for _, reason in ipairs(r) do
                    table.insert(allReasons, reason)
                end
            end
        end

        if patternObjs[obj] then
            totalScore += 30
            table.insert(allReasons, "Cross pattern member +30")
            table.insert(methods, "✚")
        end

        if totalScore >= 15 then
            table.insert(candidates, {
                obj     = obj,
                score   = totalScore,
                reasons = allReasons,
                methods = methods,
                dist    = distToCenter(obj),
            })
        end
    end

    table.sort(candidates, function(a, b) return a.score > b.score end)

    return candidates, patterns, allVisible, detectMouse()
end

-------------------------------------------------
-- HIGHLIGHT
-------------------------------------------------
local highlights = {}

local function clearHighlights()
    for _, h in ipairs(highlights) do
        if h and h.Parent then h:Destroy() end
    end
    table.clear(highlights)
end

local function highlight(obj, color)
    pcall(function()
        local f = Instance.new("Frame")
        f.Name                   = "_CH_Highlight"
        f.Size                   = UDim2.new(1, 6, 1, 6)
        f.Position               = UDim2.new(0, -3, 0, -3)
        f.BackgroundTransparency = 1
        f.ZIndex                 = 99999
        f.Parent                 = obj

        local s = Instance.new("UIStroke", f)
        s.Color = color; s.Thickness = 2

        task.spawn(function()
            while f.Parent do
                s.Transparency = 0; task.wait(0.3)
                if not f.Parent then break end
                s.Transparency = 0.7; task.wait(0.3)
            end
        end)

        table.insert(highlights, f)
    end)
end

-------------------------------------------------
-- RENDER
-------------------------------------------------
local activeEntries = {}

local function clearEntries()
    for _, e in ipairs(activeEntries) do e:Destroy() end
    table.clear(activeEntries)
end

local function makeCard(order, text, bgColor)
    local card = Instance.new("TextLabel")
    card.Size                   = UDim2.new(1, -S(4), 0, 0)
    card.AutomaticSize          = Enum.AutomaticSize.Y
    card.BackgroundColor3       = bgColor or Color3.fromRGB(25, 25, 40)
    card.BackgroundTransparency = 0.15
    card.TextColor3             = Color3.fromRGB(220, 220, 220)
    card.Font                   = Enum.Font.RobotoMono
    card.TextSize               = S(12)
    card.TextXAlignment         = Enum.TextXAlignment.Left
    card.TextYAlignment         = Enum.TextYAlignment.Top
    card.TextWrapped            = true
    card.RichText               = true
    card.LayoutOrder            = order
    card.Text                   = text
    card.BorderSizePixel        = 0
    card.ZIndex                 = 51
    card.Parent                 = Scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, S(8))

    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft   = UDim.new(0, S(10))
    pad.PaddingRight  = UDim.new(0, S(10))
    pad.PaddingTop    = UDim.new(0, S(8))
    pad.PaddingBottom = UDim.new(0, S(8))

    table.insert(activeEntries, card)
    return card
end

-- ═══════════════════════════════════════════════════════════
-- ★ NEW: Name Tag dưới mỗi box - nổi bật, dễ phân biệt
-- ═══════════════════════════════════════════════════════════
local function makeNameTag(order, obj, idx, score)
    local emoji     = getClassEmoji(obj.ClassName)
    local shortPath = getShortPath(obj)
    local absSize   = obj.AbsoluteSize

    -- Chọn màu theo confidence
    local tagColor, textColor, borderColor
    if score >= 80 then
        tagColor    = Color3.fromRGB(80, 15, 15)
        textColor   = Color3.fromRGB(255, 100, 100)
        borderColor = Color3.fromRGB(255, 60, 60)
    elseif score >= 60 then
        tagColor    = Color3.fromRGB(70, 40, 10)
        textColor   = Color3.fromRGB(255, 180, 60)
        borderColor = Color3.fromRGB(255, 140, 0)
    elseif score >= 40 then
        tagColor    = Color3.fromRGB(60, 55, 10)
        textColor   = Color3.fromRGB(255, 230, 80)
        borderColor = Color3.fromRGB(200, 200, 0)
    else
        tagColor    = Color3.fromRGB(15, 25, 50)
        textColor   = Color3.fromRGB(130, 180, 255)
        borderColor = Color3.fromRGB(80, 120, 200)
    end

    -- Container frame
    local tag = Instance.new("Frame")
    tag.Name                   = "NameTag_" .. idx
    tag.Size                   = UDim2.new(1, -S(4), 0, 0)
    tag.AutomaticSize          = Enum.AutomaticSize.Y
    tag.BackgroundColor3       = tagColor
    tag.BackgroundTransparency = 0.05
    tag.BorderSizePixel        = 0
    tag.LayoutOrder            = order
    tag.ZIndex                 = 52
    tag.Parent                 = Scroll
    Instance.new("UICorner", tag).CornerRadius = UDim.new(0, S(10))

    local tagStroke = Instance.new("UIStroke", tag)
    tagStroke.Color     = borderColor
    tagStroke.Thickness = S(2)
    tagStroke.Transparency = 0.3

    local tagPad = Instance.new("UIPadding", tag)
    tagPad.PaddingLeft   = UDim.new(0, S(10))
    tagPad.PaddingRight  = UDim.new(0, S(10))
    tagPad.PaddingTop    = UDim.new(0, S(6))
    tagPad.PaddingBottom = UDim.new(0, S(6))

    local tagLayout = Instance.new("UIListLayout", tag)
    tagLayout.Padding       = UDim.new(0, S(2))
    tagLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    tagLayout.FillDirection = Enum.FillDirection.Vertical

    -- ─── Dòng 1: Index + Tên nổi bật ───
    local nameLine = Instance.new("TextLabel")
    nameLine.Size                   = UDim2.new(1, 0, 0, 0)
    nameLine.AutomaticSize          = Enum.AutomaticSize.Y
    nameLine.BackgroundTransparency = 1
    nameLine.Font                   = Enum.Font.GothamBold
    nameLine.TextSize               = S(14)
    nameLine.TextColor3             = textColor
    nameLine.TextXAlignment         = Enum.TextXAlignment.Left
    nameLine.TextWrapped            = true
    nameLine.RichText               = true
    nameLine.LayoutOrder            = 1
    nameLine.ZIndex                 = 53
    nameLine.Text                   = string.format(
        '%s  <font color="#FFFFFF"><b>#%d</b></font>  <font size="%d"><b>%s</b></font>',
        emoji, idx, S(16), obj.Name
    )
    nameLine.Parent = tag

    -- ─── Dòng 2: Class + Size + Score ───
    local detailLine = Instance.new("TextLabel")
    detailLine.Size                   = UDim2.new(1, 0, 0, 0)
    detailLine.AutomaticSize          = Enum.AutomaticSize.Y
    detailLine.BackgroundTransparency = 1
    detailLine.Font                   = Enum.Font.RobotoMono
    detailLine.TextSize               = S(10)
    detailLine.TextColor3             = Color3.fromRGB(170, 170, 190)
    detailLine.TextXAlignment         = Enum.TextXAlignment.Left
    detailLine.TextWrapped            = true
    detailLine.RichText               = true
    detailLine.LayoutOrder            = 2
    detailLine.ZIndex                 = 53
    detailLine.Text                   = string.format(
        '<font color="#888">[%s]</font>  <font color="#AADDFF">%.0f×%.0f px</font>  <font color="%s">Score: %d</font>',
        obj.ClassName,
        absSize.X, absSize.Y,
        score >= 60 and "#FF8844" or "#88AACC",
        score
    )
    detailLine.Parent = tag

    -- ─── Dòng 3: Path rút gọn ───
    local pathLine = Instance.new("TextLabel")
    pathLine.Size                   = UDim2.new(1, 0, 0, 0)
    pathLine.AutomaticSize          = Enum.AutomaticSize.Y
    pathLine.BackgroundTransparency = 1
    pathLine.Font                   = Enum.Font.Roboto
    pathLine.TextSize               = S(9)
    pathLine.TextColor3             = Color3.fromRGB(120, 120, 140)
    pathLine.TextXAlignment         = Enum.TextXAlignment.Left
    pathLine.TextWrapped            = true
    pathLine.RichText               = true
    pathLine.LayoutOrder            = 3
    pathLine.ZIndex                 = 53
    pathLine.Text                   = string.format(
        '<font color="#555">📂 %s</font>', shortPath
    )
    pathLine.Parent = tag

    table.insert(activeEntries, tag)
    return tag
end

local function getConfLabel(score)
    if score >= 80 then
        return '<font color="#FF0000"><b>🔴 CHẮC CHẮN CROSSHAIR</b></font>'
    elseif score >= 60 then
        return '<font color="#FF8800"><b>🟠 RẤT CÓ THỂ</b></font>'
    elseif score >= 40 then
        return '<font color="#FFDD00"><b>🟡 KHẢ NĂNG CAO</b></font>'
    elseif score >= 25 then
        return '<font color="#88CCFF">🔵 Có thể</font>'
    else
        return '<font color="#888888">⚪ Thấp</font>'
    end
end

local function render()
    clearEntries()
    clearHighlights()

    local candidates, patterns, allVisible, mouseInfo = analyze()
    local viewport = Camera.ViewportSize

    InfoBar.Text = string.format(
        '<font color="#00C8FF">📱 %s</font>  |  ' ..
        '<font color="#AAAAAA">Screen: %.0f×%.0f  Scale: %.0f%%</font>\n' ..
        '<font color="#FF4444">Found: %d candidates</font>  |  ' ..
        '<font color="#FFAA00">Cross patterns: %d</font>  |  ' ..
        '<font color="#888888">Total UI: %d</font>',
        DEVICE_NAME, viewport.X, viewport.Y, UI_SCALE * 100,
        #candidates, #patterns, #allVisible
    )

    local order = 0

    -- Mouse info
    if #mouseInfo > 0 then
        order += 1
        local mText = '<font color="#FF88FF"><b>🖱️ MOUSE / CURSOR</b></font>\n'
        for _, m in ipairs(mouseInfo) do
            mText ..= string.format(
                '<font color="#FFAAFF">%s</font>\n  → <i>%s</i>\n',
                m.info, m.note
            )
        end
        makeCard(order, mText, Color3.fromRGB(35, 15, 35))
    end

    -- Candidates
    if #candidates > 0 then
        order += 1
        makeCard(order,
            '<font color="#FF4444"><b>━━ 🎯 CROSSHAIR CANDIDATES ━━</b></font>',
            Color3.fromRGB(40, 10, 10)
        )

        for idx, c in ipairs(candidates) do
            if idx > 20 then break end

            local obj = c.obj
            local pos = obj.Position
            local siz = obj.Size

            -- ★ NAME TAG trước mỗi card (nổi bật, dễ tìm)
            order += 1
            makeNameTag(order, obj, idx, c.score)

            -- Detail card
            order += 1

            local lines = {}

            table.insert(lines, string.format(
                '%s  Score: <b>%d</b>',
                getConfLabel(c.score), c.score
            ))

            table.insert(lines, string.format(
                '<font color="#AAAAAA">Methods:</font> %s',
                table.concat(c.methods, " ")
            ))

            table.insert(lines, "")
            table.insert(lines, '<font color="#00DDFF"><b>📐 OFFSET & POSITION:</b></font>')

            table.insert(lines, string.format(
                '  <font color="#88CCFF">Position.X:</font> Scale=<b>%.3f</b>  Offset=<b>%d</b>',
                pos.X.Scale, pos.X.Offset
            ))
            table.insert(lines, string.format(
                '  <font color="#88CCFF">Position.Y:</font> Scale=<b>%.3f</b>  Offset=<b>%d</b>',
                pos.Y.Scale, pos.Y.Offset
            ))
            table.insert(lines, string.format(
                '  <font color="#88FFCC">Size.X:</font> Scale=<b>%.3f</b>  Offset=<b>%d</b>',
                siz.X.Scale, siz.X.Offset
            ))
            table.insert(lines, string.format(
                '  <font color="#88FFCC">Size.Y:</font> Scale=<b>%.3f</b>  Offset=<b>%d</b>',
                siz.Y.Scale, siz.Y.Offset
            ))

            table.insert(lines, "")
            table.insert(lines, string.format(
                '<font color="#FFAA44">Pixel:</font> Pos(%.0f, %.0f)  Size(%.0f, %.0f)',
                obj.AbsolutePosition.X, obj.AbsolutePosition.Y,
                obj.AbsoluteSize.X, obj.AbsoluteSize.Y
            ))
            table.insert(lines, string.format(
                '<font color="#FFAA44">Anchor:</font> (%.1f, %.1f)  '..
                '<font color="#FFAA44">Dist→Center:</font> %.1fpx',
                obj.AnchorPoint.X, obj.AnchorPoint.Y, c.dist
            ))

            table.insert(lines, string.format(
                '<font color="#888">ZIndex: %d  Rotation: %.1f°  Transp: %.2f</font>',
                obj.ZIndex, obj.Rotation, obj.BackgroundTransparency
            ))

            if obj.BackgroundTransparency < 1 then
                local bg = obj.BackgroundColor3
                table.insert(lines, string.format(
                    '<font color="#888">BgColor: (%d,%d,%d)</font>',
                    bg.R*255, bg.G*255, bg.B*255
                ))
            end

            if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.Image ~= "" then
                table.insert(lines, string.format(
                    '<font color="#AA88FF">Image: %s</font>', obj.Image
                ))
            end

            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text ~= "" then
                local t = obj.Text:sub(1,30):gsub("<","&lt;"):gsub(">","&gt;")
                table.insert(lines, string.format(
                    '<font color="#FFF">Text: "%s"</font>', t
                ))
            end

            table.insert(lines, "")
            table.insert(lines, '<font color="#666">Phát hiện bởi:</font>')
            for _, r in ipairs(c.reasons) do
                table.insert(lines, '<font color="#777">  • '..r..'</font>')
            end

            local bgC
            if c.score >= 80 then bgC = Color3.fromRGB(50, 12, 12)
            elseif c.score >= 60 then bgC = Color3.fromRGB(45, 28, 8)
            elseif c.score >= 40 then bgC = Color3.fromRGB(40, 38, 8)
            else bgC = Color3.fromRGB(22, 22, 38) end

            makeCard(order, table.concat(lines, "\n"), bgC)

            -- Highlight
            if c.score >= DETECT.MIN_CONFIDENCE then
                local hCol
                if c.score >= 80 then hCol = Color3.fromRGB(255,0,0)
                elseif c.score >= 60 then hCol = Color3.fromRGB(255,140,0)
                else hCol = Color3.fromRGB(255,255,0) end
                highlight(obj, hCol)
            end
        end
    else
        order += 1
        makeCard(order,
            '<font color="#FFAA00"><b>Không phát hiện crosshair nào</b></font>\n\n' ..
            '<font color="#AAA">Có thể game dùng:\n' ..
            '• BillboardGui trong 3D world\n' ..
            '• Drawing API (C++ level)\n' ..
            '• Mouse.Icon làm crosshair\n' ..
            '• Crosshair chưa spawn (chưa cầm vũ khí)</font>\n\n' ..
            '<font color="#888">💡 Thử: cầm vũ khí rồi scan lại</font>',
            Color3.fromRGB(35, 30, 10)
        )
    end

    -- Cross patterns
    if #patterns > 0 then
        order += 1
        makeCard(order,
            '<font color="#00FF88"><b>━━ ✚ CROSS PATTERNS ━━</b></font>',
            Color3.fromRGB(10, 35, 15)
        )
        for pi, pat in ipairs(patterns) do
            order += 1

            -- Name tag cho pattern
            order += 1
            local patTag = Instance.new("Frame")
            patTag.Name                   = "PatternTag_" .. pi
            patTag.Size                   = UDim2.new(1, -S(4), 0, 0)
            patTag.AutomaticSize          = Enum.AutomaticSize.Y
            patTag.BackgroundColor3       = Color3.fromRGB(10, 40, 25)
            patTag.BackgroundTransparency = 0.05
            patTag.BorderSizePixel        = 0
            patTag.LayoutOrder            = order
            patTag.ZIndex                 = 52
            patTag.Parent                 = Scroll
            Instance.new("UICorner", patTag).CornerRadius = UDim.new(0, S(8))

            local ptStroke = Instance.new("UIStroke", patTag)
            ptStroke.Color = Color3.fromRGB(0, 200, 100); ptStroke.Thickness = S(1)

            local ptPad = Instance.new("UIPadding", patTag)
            ptPad.PaddingLeft  = UDim.new(0, S(10))
            ptPad.PaddingRight = UDim.new(0, S(10))
            ptPad.PaddingTop   = UDim.new(0, S(6))
            ptPad.PaddingBottom= UDim.new(0, S(6))

            local ptLabel = Instance.new("TextLabel")
            ptLabel.Size                   = UDim2.new(1, 0, 0, 0)
            ptLabel.AutomaticSize          = Enum.AutomaticSize.Y
            ptLabel.BackgroundTransparency = 1
            ptLabel.Font                   = Enum.Font.GothamBold
            ptLabel.TextSize               = S(12)
            ptLabel.TextColor3             = Color3.fromRGB(100, 255, 150)
            ptLabel.TextXAlignment         = Enum.TextXAlignment.Left
            ptLabel.TextWrapped            = true
            ptLabel.RichText               = true
            ptLabel.ZIndex                 = 53
            ptLabel.Text                   = string.format(
                '✚ <font color="#FFFFFF"><b>Pattern #%d</b></font>  Gap: %.1fpx\n'..
                '  <font color="#88FFAA">H:</font> <font color="#FFD700"><b>%s</b></font> <font color="#888">[%s]</font> %.0f×%.0f\n'..
                '  <font color="#88FFAA">V:</font> <font color="#FFD700"><b>%s</b></font> <font color="#888">[%s]</font> %.0f×%.0f\n'..
                '<font color="#555">📂 H: %s</font>\n'..
                '<font color="#555">📂 V: %s</font>',
                pi, pat.gap,
                pat.h.Name, pat.h.ClassName, pat.h.AbsoluteSize.X, pat.h.AbsoluteSize.Y,
                pat.v.Name, pat.v.ClassName, pat.v.AbsoluteSize.X, pat.v.AbsoluteSize.Y,
                getShortPath(pat.h),
                getShortPath(pat.v)
            )
            ptLabel.Parent = patTag

            table.insert(activeEntries, patTag)
        end
    end
end

-------------------------------------------------
-- TOGGLE
-------------------------------------------------
local isOpen = false
local updateConn = nil

local function tweenBtn(props, duration)
    TweenService:Create(ToggleBtn, TweenInfo.new(duration or 0.2), props):Play()
end

local function setOpen(state)
    isOpen = state

    if isOpen then
        Panel.Visible = true
        ToggleBtn.Text = "🎯 ON"
        tweenBtn({BackgroundColor3 = Color3.fromRGB(0, 150, 70)})

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
        ToggleBtn.Text = "🎯 OFF"
        tweenBtn({BackgroundColor3 = Color3.fromRGB(180, 30, 30)})

        clearEntries()
        clearHighlights()
        Panel.Visible = false

        if updateConn then
            updateConn:Disconnect()
            updateConn = nil
        end
    end
end

-------------------------------------------------
-- INPUT
-------------------------------------------------
ToggleBtn.MouseButton1Click:Connect(function()
    setOpen(not isOpen)
end)

CloseBtn.MouseButton1Click:Connect(function()
    setOpen(false)
end)

if IS_PC then
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F3 then
            setOpen(not isOpen)
        end
    end)
end

-------------------------------------------------
-- VIEWPORT CHANGE
-------------------------------------------------
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    UI_SCALE = getScale()
    local vs = Camera.ViewportSize
    IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    IS_TABLET = IS_MOBILE and (vs.X > 1000)
end)

-------------------------------------------------
print("═══════════════════════════════════════")
print("  🎯 Mobile Crosshair Detector Loaded")
print("  Device: " .. DEVICE_NAME)
print("  Scale: " .. math.floor(UI_SCALE * 100) .. "%")
print("  Toggle: Button or F3 (PC)")
print("  ★ Name Tags enabled")
print("═══════════════════════════════════════")
