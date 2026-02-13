--[[
    Mobile Crosshair Detector - FIXED VERSION
    Nút to, ở giữa màn hình, dễ thấy
    LocalScript → StarterGui
]]

-- DEBUG: In ra console để biết script có chạy không
print("═══════════════════════════════════════")
print("🎯 SCRIPT ĐANG CHẠY...")
print("═══════════════════════════════════════")

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

-- Chờ camera load
repeat task.wait() until Camera and Camera.ViewportSize.X > 0

print("✅ Camera loaded:", Camera.ViewportSize)

-------------------------------------------------
-- DETECT DEVICE
-------------------------------------------------
local IS_MOBILE = UserInputService.TouchEnabled
local IS_PC     = UserInputService.KeyboardEnabled
local DEVICE    = IS_MOBILE and "📱 Mobile" or "💻 PC"

print("✅ Device:", DEVICE)
print("✅ Touch:", UserInputService.TouchEnabled)
print("✅ Keyboard:", UserInputService.KeyboardEnabled)

-------------------------------------------------
-- SCALE THEO MÀN HÌNH
-------------------------------------------------
local function getScale()
    local vp = Camera.ViewportSize
    local short = math.min(vp.X, vp.Y)
    if short < 400 then return 0.6 end
    if short < 600 then return 0.75 end
    if short < 900 then return 0.85 end
    return 1
end

local SCALE = getScale()
local function S(px) return math.floor(px * SCALE) end

print("✅ Scale:", SCALE)

-------------------------------------------------
-- XÓA GUI CŨ NẾU CÓ (tránh duplicate)
-------------------------------------------------
local oldGui = PlayerGui:FindFirstChild("CrosshairDetectorV2")
if oldGui then 
    oldGui:Destroy() 
    print("⚠️ Xóa GUI cũ")
end

-------------------------------------------------
-- TẠO SCREENGUI
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "CrosshairDetectorV2"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 999999  -- Rất cao để hiện trên mọi thứ
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = false   -- FALSE để tránh bị che bởi notch
ScreenGui.Parent         = PlayerGui

print("✅ ScreenGui created")

-------------------------------------------------
-- NÚT TOGGLE - TO, Ở GÓC PHẢI DƯỚI (dễ thấy trên mobile)
-------------------------------------------------
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name              = "ToggleButton"
ToggleBtn.Size              = UDim2.new(0, S(140), 0, S(55))
ToggleBtn.BackgroundColor3  = Color3.fromRGB(220, 50, 50)
ToggleBtn.TextColor3        = Color3.new(1, 1, 1)
ToggleBtn.Font              = Enum.Font.GothamBold
ToggleBtn.TextSize          = S(16)
ToggleBtn.Text              = "🎯 DETECTOR"
ToggleBtn.BorderSizePixel   = 0
ToggleBtn.ZIndex            = 9999
ToggleBtn.AutoButtonColor   = true
ToggleBtn.Parent            = ScreenGui

-- Vị trí: góc phải dưới, cách mép 20px
ToggleBtn.AnchorPoint = Vector2.new(1, 1)
ToggleBtn.Position    = UDim2.new(1, -S(15), 1, -S(80))

local tCorner = Instance.new("UICorner", ToggleBtn)
tCorner.CornerRadius = UDim.new(0, S(12))

local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color     = Color3.new(1, 1, 1)
tStroke.Thickness = S(3)

print("✅ Toggle button created at bottom-right")

-------------------------------------------------
-- MINI INDICATOR (góc trái trên để confirm script chạy)
-------------------------------------------------
local Indicator = Instance.new("TextLabel")
Indicator.Name                  = "Indicator"
Indicator.Size                  = UDim2.new(0, S(120), 0, S(30))
Indicator.Position              = UDim2.new(0, S(10), 0, S(40))
Indicator.BackgroundColor3      = Color3.fromRGB(0, 150, 0)
Indicator.BackgroundTransparency = 0.3
Indicator.TextColor3            = Color3.new(1, 1, 1)
Indicator.Font                  = Enum.Font.GothamBold
Indicator.TextSize              = S(11)
Indicator.Text                  = "🟢 Script OK"
Indicator.BorderSizePixel       = 0
Indicator.ZIndex                = 9999
Indicator.Parent                = ScreenGui
Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, S(8))

print("✅ Indicator created at top-left")

-------------------------------------------------
-- MAIN PANEL
-------------------------------------------------
local Panel = Instance.new("Frame")
Panel.Name              = "MainPanel"
Panel.BackgroundColor3  = Color3.fromRGB(15, 15, 25)
Panel.BorderSizePixel   = 0
Panel.Visible           = false
Panel.Active            = true
Panel.ZIndex            = 9000
Panel.Parent            = ScreenGui

-- Mobile: full screen, PC: centered window
if IS_MOBILE then
    Panel.Size     = UDim2.new(0.94, 0, 0.75, 0)
    Panel.Position = UDim2.new(0.03, 0, 0.12, 0)
else
    Panel.Size     = UDim2.new(0, S(520), 0, S(550))
    Panel.Position = UDim2.new(0.5, -S(260), 0.5, -S(275))
end

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, S(14))
local pStroke = Instance.new("UIStroke", Panel)
pStroke.Color = Color3.fromRGB(255, 80, 80); pStroke.Thickness = S(3)

print("✅ Panel created")

-------------------------------------------------
-- TITLE BAR (có thể kéo)
-------------------------------------------------
local TitleBar = Instance.new("Frame")
TitleBar.Name              = "TitleBar"
TitleBar.Size              = UDim2.new(1, 0, 0, S(50))
TitleBar.BackgroundColor3  = Color3.fromRGB(30, 15, 15)
TitleBar.BorderSizePixel   = 0
TitleBar.ZIndex            = 9001
TitleBar.Parent            = Panel
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, S(14))

-- Fix corners
local fix = Instance.new("Frame", TitleBar)
fix.Size = UDim2.new(1, 0, 0, S(14))
fix.Position = UDim2.new(0, 0, 1, -S(14))
fix.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
fix.BorderSizePixel = 0
fix.ZIndex = 9001

-- Dragging
local dragging, dragStart, startPos = false, nil, nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = Panel.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Title text
local TitleText = Instance.new("TextLabel")
TitleText.Size                  = UDim2.new(1, -S(60), 1, 0)
TitleText.Position              = UDim2.new(0, S(12), 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font                  = Enum.Font.GothamBold
TitleText.TextSize              = S(15)
TitleText.TextColor3            = Color3.fromRGB(255, 100, 100)
TitleText.TextXAlignment        = Enum.TextXAlignment.Left
TitleText.Text                  = "🎯 Crosshair Detector"
TitleText.ZIndex                = 9002
TitleText.Parent                = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, S(40), 0, S(40))
CloseBtn.Position         = UDim2.new(1, -S(45), 0, S(5))
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3       = Color3.new(1, 1, 1)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = S(22)
CloseBtn.Text             = "✕"
CloseBtn.BorderSizePixel  = 0
CloseBtn.ZIndex           = 9002
CloseBtn.Parent           = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, S(10))

-------------------------------------------------
-- INFO LABEL
-------------------------------------------------
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size                  = UDim2.new(1, -S(16), 0, S(50))
InfoLabel.Position              = UDim2.new(0, S(8), 0, S(54))
InfoLabel.BackgroundColor3      = Color3.fromRGB(25, 25, 40)
InfoLabel.BackgroundTransparency = 0.3
InfoLabel.TextColor3            = Color3.fromRGB(200, 200, 200)
InfoLabel.Font                  = Enum.Font.RobotoMono
InfoLabel.TextSize              = S(11)
InfoLabel.TextXAlignment        = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment        = Enum.TextYAlignment.Top
InfoLabel.TextWrapped           = true
InfoLabel.RichText              = true
InfoLabel.BorderSizePixel       = 0
InfoLabel.ZIndex                = 9001
InfoLabel.Text                  = ""
InfoLabel.Parent                = Panel
Instance.new("UICorner", InfoLabel).CornerRadius = UDim.new(0, S(8))
local infoPad = Instance.new("UIPadding", InfoLabel)
infoPad.PaddingLeft = UDim.new(0, S(8))
infoPad.PaddingTop  = UDim.new(0, S(6))

-------------------------------------------------
-- SCROLL FRAME
-------------------------------------------------
local Scroll = Instance.new("ScrollingFrame")
Scroll.Name                   = "ResultsScroll"
Scroll.Size                   = UDim2.new(1, -S(12), 1, -S(112))
Scroll.Position               = UDim2.new(0, S(6), 0, S(108))
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel        = 0
Scroll.ScrollBarThickness     = S(10)
Scroll.ScrollBarImageColor3   = Color3.fromRGB(255, 80, 80)
Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
Scroll.ZIndex                 = 9001
Scroll.ElasticBehavior        = Enum.ElasticBehavior.Always
Scroll.Parent                 = Panel

local scrollPad = Instance.new("UIPadding", Scroll)
scrollPad.PaddingTop    = UDim.new(0, S(4))
scrollPad.PaddingBottom = UDim.new(0, S(4))
scrollPad.PaddingLeft   = UDim.new(0, S(4))
scrollPad.PaddingRight  = UDim.new(0, S(4))

local scrollLayout = Instance.new("UIListLayout", Scroll)
scrollLayout.Padding   = UDim.new(0, S(5))
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

print("✅ Scroll created")

-------------------------------------------------
-- DETECTION HELPERS
-------------------------------------------------
local function getScreenCenter()
    local vs = Camera.ViewportSize
    return Vector2.new(vs.X / 2, vs.Y / 2)
end

local function getObjCenter(obj)
    local p = obj.AbsolutePosition
    local s = obj.AbsoluteSize
    return Vector2.new(p.X + s.X/2, p.Y + s.Y/2)
end

local function distToCenter(obj)
    return (getObjCenter(obj) - getScreenCenter()).Magnitude
end

local function isVisible(obj)
    local cur = obj
    while cur do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("ScreenGui") and not cur.Enabled then return false end
        if cur == game then break end
        cur = cur.Parent
    end
    return true
end

-------------------------------------------------
-- DETECTION CONFIG
-------------------------------------------------
local DETECT = {
    CENTER_TIGHT  = 40,
    CENTER_MEDIUM = 80,
    CENTER_WIDE   = 150,
    MAX_SIZE      = 120,
    THIN          = 8,
}

local NAME_KW = {
    {"crosshair","reticle","aimpoint","gunsight","xhair"}, -- +35
    {"aim","cross","sight","scope","cursor","target","dot","hair"}, -- +20
    {"center","middle","point","marker","hud"}, -- +10
}

-------------------------------------------------
-- SCORING FUNCTIONS
-------------------------------------------------
local function scoreByName(obj)
    local name = obj.Name:lower()
    local score, reasons = 0, {}

    for _, kw in ipairs(NAME_KW[1]) do
        if name:find(kw) then score += 35; table.insert(reasons, "Name '"..kw.."' +35"); break end
    end
    for _, kw in ipairs(NAME_KW[2]) do
        if name:find(kw) then score += 20; table.insert(reasons, "Name '"..kw.."' +20"); break end
    end
    for _, kw in ipairs(NAME_KW[3]) do
        if name:find(kw) then score += 10; table.insert(reasons, "Name '"..kw.."' +10"); break end
    end

    -- Parent
    local p = obj.Parent
    if p and p:IsA("GuiObject") then
        local pn = p.Name:lower()
        for _, kw in ipairs(NAME_KW[1]) do
            if pn:find(kw) then score += 25; table.insert(reasons, "Parent '"..kw.."' +25"); break end
        end
        for _, kw in ipairs(NAME_KW[2]) do
            if pn:find(kw) then score += 15; table.insert(reasons, "Parent '"..kw.."' +15"); break end
        end
    end

    return score, reasons
end

local function scoreByPosition(obj)
    local dist = distToCenter(obj)
    local score, reasons = 0, {}

    if dist < DETECT.CENTER_TIGHT then
        score += 30; table.insert(reasons, string.format("Center %.0fpx +30", dist))
    elseif dist < DETECT.CENTER_MEDIUM then
        score += 20; table.insert(reasons, string.format("Near center %.0fpx +20", dist))
    elseif dist < DETECT.CENTER_WIDE then
        score += 8; table.insert(reasons, string.format("Center area %.0fpx +8", dist))
    end

    local pos = obj.Position
    if math.abs(pos.X.Scale - 0.5) < 0.05 and math.abs(pos.Y.Scale - 0.5) < 0.05 then
        score += 15; table.insert(reasons, "Scale≈0.5 +15")
    end

    return score, reasons
end

local function scoreBySize(obj)
    local s = obj.AbsoluteSize
    local maxD = math.max(s.X, s.Y)
    local minD = math.min(s.X, s.Y)
    local score, reasons = 0, {}

    if maxD < 5 and maxD >= 1 then
        score += 25; table.insert(reasons, string.format("Dot %.0f×%.0f +25", s.X, s.Y))
    elseif maxD <= 50 then
        score += 20; table.insert(reasons, string.format("Small %.0f×%.0f +20", s.X, s.Y))
    elseif maxD <= DETECT.MAX_SIZE then
        score += 10; table.insert(reasons, string.format("Medium %.0f×%.0f +10", s.X, s.Y))
    elseif maxD > 200 then
        score -= 15; table.insert(reasons, string.format("Too big -15"))
    end

    if minD <= DETECT.THIN and maxD > 5 and maxD < 80 then
        score += 15; table.insert(reasons, "Thin bar +15")
    end

    return score, reasons
end

local function scoreByImage(obj)
    local score, reasons = 0, {}
    if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then return score, reasons end
    
    local img = obj.Image:lower()
    if img == "" then return score, reasons end

    local imgKW = {"crosshair","reticle","aim","scope","dot","target","sight"}
    for _, kw in ipairs(imgKW) do
        if img:find(kw) then score += 25; table.insert(reasons, "Image '"..kw.."' +25"); break end
    end

    return score, reasons
end

local function scoreByLayer(obj)
    local score, reasons = 0, {}
    if obj.ZIndex >= 10 then
        score += 5; table.insert(reasons, "ZIndex="..obj.ZIndex.." +5")
    end
    if #obj:GetChildren() <= 1 then
        score += 3; table.insert(reasons, "Leaf +3")
    end
    return score, reasons
end

-------------------------------------------------
-- FIND CROSS PATTERNS
-------------------------------------------------
local function findCrossPatterns(allObjs)
    local center = getScreenCenter()
    local patterns = {}
    local hBars, vBars = {}, {}

    for _, obj in ipairs(allObjs) do
        local s = obj.AbsoluteSize
        local d = (getObjCenter(obj) - center).Magnitude

        if d < DETECT.CENTER_MEDIUM then
            if s.X > s.Y * 2 and s.Y <= DETECT.THIN and s.X < 100 then
                table.insert(hBars, obj)
            end
            if s.Y > s.X * 2 and s.X <= DETECT.THIN and s.Y < 100 then
                table.insert(vBars, obj)
            end
        end
    end

    for _, h in ipairs(hBars) do
        for _, v in ipairs(vBars) do
            local gap = (getObjCenter(h) - getObjCenter(v)).Magnitude
            if gap < 15 then
                table.insert(patterns, {h = h, v = v})
            end
        end
    end

    return patterns
end

-------------------------------------------------
-- MOUSE INFO
-------------------------------------------------
local Mouse = LocalPlayer:GetMouse()

local function getMouseInfo()
    local info = {}

    if Mouse.Icon ~= "" then
        table.insert(info, "🖱️ Mouse.Icon = " .. Mouse.Icon)
    end

    if not UserInputService.MouseIconEnabled then
        table.insert(info, "🖱️ Mouse HIDDEN → likely custom crosshair")
    end

    local mb = UserInputService.MouseBehavior
    if mb == Enum.MouseBehavior.LockCenter then
        table.insert(info, "🖱️ Mouse LOCKED → FPS mode")
    end

    return info
end

-------------------------------------------------
-- ANALYZE
-------------------------------------------------
local function analyze()
    local allVisible = {}

    for _, sg in ipairs(PlayerGui:GetChildren()) do
        if sg:IsA("ScreenGui") and sg ~= ScreenGui and sg.Enabled then
            for _, obj in ipairs(sg:GetDescendants()) do
                if obj:IsA("GuiObject") and isVisible(obj) then
                    table.insert(allVisible, obj)
                end
            end
        end
    end

    local patterns = findCrossPatterns(allVisible)
    local patternObjs = {}
    for _, p in ipairs(patterns) do
        patternObjs[p.h] = true
        patternObjs[p.v] = true
    end

    local candidates = {}

    for _, obj in ipairs(allVisible) do
        local total = 0
        local allReasons = {}

        local s1, r1 = scoreByName(obj)
        total += s1; for _, r in ipairs(r1) do table.insert(allReasons, r) end

        local s2, r2 = scoreByPosition(obj)
        total += s2; for _, r in ipairs(r2) do table.insert(allReasons, r) end

        local s3, r3 = scoreBySize(obj)
        total += s3; for _, r in ipairs(r3) do table.insert(allReasons, r) end

        local s4, r4 = scoreByImage(obj)
        total += s4; for _, r in ipairs(r4) do table.insert(allReasons, r) end

        local s5, r5 = scoreByLayer(obj)
        total += s5; for _, r in ipairs(r5) do table.insert(allReasons, r) end

        if patternObjs[obj] then
            total += 30
            table.insert(allReasons, "Cross pattern +30")
        end

        if total >= 15 then
            table.insert(candidates, {
                obj     = obj,
                score   = total,
                reasons = allReasons,
                dist    = distToCenter(obj),
            })
        end
    end

    table.sort(candidates, function(a, b) return a.score > b.score end)

    return candidates, patterns, allVisible
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

local function addHighlight(obj, color)
    pcall(function()
        local f = Instance.new("Frame")
        f.Name = "_Highlight"
        f.Size = UDim2.new(1, 8, 1, 8)
        f.Position = UDim2.new(0, -4, 0, -4)
        f.BackgroundTransparency = 1
        f.ZIndex = 99999
        f.Parent = obj

        local stroke = Instance.new("UIStroke", f)
        stroke.Color = color
        stroke.Thickness = 3

        task.spawn(function()
            while f.Parent do
                stroke.Transparency = 0
                task.wait(0.3)
                if not f.Parent then break end
                stroke.Transparency = 0.7
                task.wait(0.3)
            end
        end)

        table.insert(highlights, f)
    end)
end

-------------------------------------------------
-- RENDER
-------------------------------------------------
local entries = {}

local function clearEntries()
    for _, e in ipairs(entries) do e:Destroy() end
    table.clear(entries)
end

local function makeCard(order, text, bgColor)
    local card = Instance.new("TextLabel")
    card.Size                  = UDim2.new(1, -S(4), 0, 0)
    card.AutomaticSize         = Enum.AutomaticSize.Y
    card.BackgroundColor3      = bgColor or Color3.fromRGB(25, 25, 40)
    card.BackgroundTransparency = 0.1
    card.TextColor3            = Color3.fromRGB(230, 230, 230)
    card.Font                  = Enum.Font.RobotoMono
    card.TextSize              = S(12)
    card.TextXAlignment        = Enum.TextXAlignment.Left
    card.TextYAlignment        = Enum.TextYAlignment.Top
    card.TextWrapped           = true
    card.RichText              = true
    card.LayoutOrder           = order
    card.Text                  = text
    card.BorderSizePixel       = 0
    card.ZIndex                = 9001
    card.Parent                = Scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, S(8))

    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft   = UDim.new(0, S(10))
    pad.PaddingRight  = UDim.new(0, S(10))
    pad.PaddingTop    = UDim.new(0, S(8))
    pad.PaddingBottom = UDim.new(0, S(8))

    table.insert(entries, card)
    return card
end

local function getConfLabel(score)
    if score >= 80 then
        return '<font color="#FF0000"><b>🔴 CHẮC CHẮN</b></font>'
    elseif score >= 60 then
        return '<font color="#FF8800"><b>🟠 RẤT CÓ THỂ</b></font>'
    elseif score >= 40 then
        return '<font color="#FFDD00"><b>🟡 KHẢ NĂNG</b></font>'
    else
        return '<font color="#88CCFF">🔵 Có thể</font>'
    end
end

local function render()
    clearEntries()
    clearHighlights()

    local candidates, patterns, allVisible = analyze()
    local mouseInfo = getMouseInfo()
    local vp = Camera.ViewportSize

    -- Info bar
    InfoLabel.Text = string.format(
        '<font color="#00C8FF">%s</font> | Screen: %.0f×%.0f | Scale: %.0f%%\n' ..
        '<font color="#FF4444">Found: %d</font> | Patterns: %d | Total UI: %d',
        DEVICE, vp.X, vp.Y, SCALE * 100,
        #candidates, #patterns, #allVisible
    )

    local order = 0

    -- Mouse info
    if #mouseInfo > 0 then
        order += 1
        local mText = '<font color="#FF88FF"><b>🖱️ MOUSE INFO</b></font>\n'
        for _, m in ipairs(mouseInfo) do
            mText ..= '<font color="#FFAAFF">' .. m .. '</font>\n'
        end
        makeCard(order, mText, Color3.fromRGB(40, 15, 40))
    end

    -- Candidates
    if #candidates > 0 then
        for i, c in ipairs(candidates) do
            if i > 15 then break end
            order += 1

            local obj = c.obj
            local pos = obj.Position
            local siz = obj.Size

            local lines = {}

            table.insert(lines, string.format(
                '%s  Score: <b>%d</b>',
                getConfLabel(c.score), c.score
            ))

            table.insert(lines, string.format(
                '<font color="#FFD700">%s</font> [%s]',
                obj.Name, obj.ClassName
            ))

            table.insert(lines, "")
            table.insert(lines, '<font color="#00DDFF"><b>📐 OFFSET:</b></font>')
            table.insert(lines, string.format(
                '  Pos X: Scale=<b>%.3f</b> Offset=<b>%d</b>',
                pos.X.Scale, pos.X.Offset
            ))
            table.insert(lines, string.format(
                '  Pos Y: Scale=<b>%.3f</b> Offset=<b>%d</b>',
                pos.Y.Scale, pos.Y.Offset
            ))
            table.insert(lines, string.format(
                '  Size X: Scale=<b>%.3f</b> Offset=<b>%d</b>',
                siz.X.Scale, siz.X.Offset
            ))
            table.insert(lines, string.format(
                '  Size Y: Scale=<b>%.3f</b> Offset=<b>%d</b>',
                siz.Y.Scale, siz.Y.Offset
            ))

            table.insert(lines, "")
            table.insert(lines, string.format(
                '<font color="#FFAA44">Pixel:</font> (%.0f,%.0f) Size(%.0f,%.0f)',
                obj.AbsolutePosition.X, obj.AbsolutePosition.Y,
                obj.AbsoluteSize.X, obj.AbsoluteSize.Y
            ))
            table.insert(lines, string.format(
                '<font color="#FFAA44">Dist→Center:</font> %.1fpx',
                c.dist
            ))

            table.insert(lines, "")
            for _, r in ipairs(c.reasons) do
                table.insert(lines, '<font color="#888">• '..r..'</font>')
            end

            local bgC
            if c.score >= 80 then bgC = Color3.fromRGB(50, 10, 10)
            elseif c.score >= 60 then bgC = Color3.fromRGB(45, 25, 5)
            elseif c.score >= 40 then bgC = Color3.fromRGB(40, 38, 5)
            else bgC = Color3.fromRGB(20, 20, 35) end

            makeCard(order, table.concat(lines, "\n"), bgC)

            -- Highlight
            if c.score >= 40 then
                local hCol
                if c.score >= 80 then hCol = Color3.fromRGB(255,0,0)
                elseif c.score >= 60 then hCol = Color3.fromRGB(255,140,0)
                else hCol = Color3.fromRGB(255,255,0) end
                addHighlight(obj, hCol)
            end
        end
    else
        order += 1
        makeCard(order,
            '<font color="#FFAA00"><b>Không tìm thấy crosshair</b></font>\n\n' ..
            '<font color="#AAA">Thử:\n' ..
            '• Cầm vũ khí/súng\n' ..
            '• Vào chế độ ngắm\n' ..
            '• Chờ game load xong</font>',
            Color3.fromRGB(35, 30, 10)
        )
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
        ToggleBtn.Text = "🎯 ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        Indicator.Text = "🟢 Scanning..."
        Indicator.BackgroundColor3 = Color3.fromRGB(50, 150, 50)

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
        ToggleBtn.Text = "🎯 DETECTOR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        Indicator.Text = "🟢 Ready"
        Indicator.BackgroundColor3 = Color3.fromRGB(0, 150, 0)

        clearEntries()
        clearHighlights()

        if updateConn then
            updateConn:Disconnect()
            updateConn = nil
        end
    end

    print("🎯 Detector:", isOpen and "ON" or "OFF")
end

-------------------------------------------------
-- EVENTS
-------------------------------------------------
ToggleBtn.MouseButton1Click:Connect(function()
    print("👆 Button tapped!")
    setOpen(not isOpen)
end)

ToggleBtn.TouchTap:Connect(function()
    print("👆 Touch tap!")
    setOpen(not isOpen)
end)

CloseBtn.MouseButton1Click:Connect(function()
    setOpen(false)
end)

-- PC: F3
if IS_PC then
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F3 then
            setOpen(not isOpen)
        end
    end)
end

-------------------------------------------------
print("═══════════════════════════════════════")
print("✅ SCRIPT LOADED SUCCESSFULLY!")
print("✅ Device:", DEVICE)
print("✅ Look for RED button at BOTTOM-RIGHT")
print("✅ Look for GREEN indicator at TOP-LEFT")
print("═══════════════════════════════════════")
