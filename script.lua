--[[
    UI Inspector - Phân tích & phân loại mọi UI trên màn hình
    Tự động nhận diện: Crosshair, HealthBar, Ammo, Button, v.v.
    LocalScript → StarterGui
]]

-------------------------------------------------
-- SERVICES
-------------------------------------------------
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
    REFRESH_RATE    = 1,
    MAX_DEPTH       = 15,
    HIGHLIGHT_COLOR = Color3.fromRGB(255, 50, 50),
    HEADER_COLOR    = "#00C8FF",
    CROSSHAIR_COLOR = "#FF4444",
    HEALTHBAR_COLOR = "#44FF44",
    BUTTON_COLOR    = "#FFAA00",
    TEXT_UI_COLOR   = "#FFFFFF",
    IMAGE_COLOR     = "#AA88FF",
    OTHER_COLOR     = "#888888",
}

-------------------------------------------------
-- UI CLASSIFICATION RULES
-------------------------------------------------
local function getScreenCenter()
    local vs = Camera.ViewportSize
    return Vector2.new(vs.X / 2, vs.Y / 2)
end

local function getAbsoluteCenter(guiObj)
    local pos  = guiObj.AbsolutePosition
    local size = guiObj.AbsoluteSize
    return Vector2.new(pos.X + size.X / 2, pos.Y + size.Y / 2)
end

local function nameContains(name, keywords)
    local lower = name:lower()
    for _, kw in ipairs(keywords) do
        if lower:find(kw) then
            return true
        end
    end
    return false
end

-- Hàm phân loại UI element
local function classifyUI(obj)
    local name   = obj.Name:lower()
    local class  = obj.ClassName
    local absPos = obj.AbsolutePosition
    local absSize = obj.AbsoluteSize
    local center  = getAbsoluteCenter(obj)
    local screenCenter = getScreenCenter()
    local distFromCenter = (center - screenCenter).Magnitude
    local viewport = Camera.ViewportSize

    local maxDim = math.max(absSize.X, absSize.Y)
    local minDim = math.min(absSize.X, absSize.Y)

    -- ═══ CROSSHAIR / RETICLE ═══
    -- Ở giữa màn hình, kích thước nhỏ
    local crosshairKeywords = {
        "cross", "hair", "crosshair", "reticle", "aim",
        "dot", "scope", "sight", "cursor", "target"
    }
    if nameContains(obj.Name, crosshairKeywords) then
        return "🎯 Crosshair", CONFIG.CROSSHAIR_COLOR
    end
    -- Phát hiện crosshair dựa trên vị trí + kích thước
    if distFromCenter < 50 and maxDim < 80 and maxDim > 2 then
        -- Nhỏ, ở chính giữa → rất có thể là crosshair
        if class == "ImageLabel" or class == "Frame" or class == "ImageButton" then
            return "🎯 Crosshair (auto-detect)", CONFIG.CROSSHAIR_COLOR
        end
    end

    -- ═══ HEALTH BAR ═══
    local healthKeywords = {
        "health", "hp", "hitpoint", "life", "heart",
        "healthbar", "hpbar", "lifebar"
    }
    if nameContains(obj.Name, healthKeywords) then
        return "❤️ Health Bar", CONFIG.HEALTHBAR_COLOR
    end

    -- ═══ AMMO / WEAPON ═══
    local ammoKeywords = {
        "ammo", "bullet", "mag", "magazine", "clip",
        "weapon", "gun", "reload", "round"
    }
    if nameContains(obj.Name, ammoKeywords) then
        return "🔫 Ammo/Weapon UI", "#FF8844"
    end

    -- ═══ STAMINA / ENERGY ═══
    local staminaKeywords = {
        "stamina", "energy", "mana", "power", "sprint",
        "endurance", "fatigue"
    }
    if nameContains(obj.Name, staminaKeywords) then
        return "⚡ Stamina/Energy", "#44AAFF"
    end

    -- ═══ MINIMAP ═══
    local minimapKeywords = {"minimap", "map", "radar", "compass"}
    if nameContains(obj.Name, minimapKeywords) then
        return "🗺️ Minimap", "#44FF88"
    end

    -- ═══ SCOREBOARD / LEADERBOARD ═══
    local scoreKeywords = {
        "score", "leader", "board", "rank", "stat",
        "kill", "death", "kd", "point"
    }
    if nameContains(obj.Name, scoreKeywords) then
        return "📊 Scoreboard", "#FFFF44"
    end

    -- ═══ NOTIFICATION ═══
    local notifKeywords = {
        "notif", "alert", "popup", "toast", "message",
        "announce", "info", "warning"
    }
    if nameContains(obj.Name, notifKeywords) then
        return "🔔 Notification", "#FF88FF"
    end

    -- ═══ INVENTORY / HOTBAR ═══
    local invKeywords = {
        "inventory", "hotbar", "slot", "item", "backpack",
        "toolbar", "quickbar"
    }
    if nameContains(obj.Name, invKeywords) then
        return "🎒 Inventory/Hotbar", "#88FFAA"
    end

    -- ═══ BUTTON ═══
    if class == "TextButton" or class == "ImageButton" then
        return "🔘 Button", CONFIG.BUTTON_COLOR
    end

    -- ═══ TEXT LABEL ═══
    if class == "TextLabel" or class == "TextBox" then
        return "📝 Text", CONFIG.TEXT_UI_COLOR
    end

    -- ═══ IMAGE ═══
    if class == "ImageLabel" then
        return "🖼️ Image", CONFIG.IMAGE_COLOR
    end

    -- ═══ FRAME (container) ═══
    if class == "Frame" then
        -- Thanh ngang mỏng → có thể là bar
        if absSize.X > absSize.Y * 3 and absSize.Y < 40 then
            return "📊 Bar (possible)", "#88CCFF"
        end
        return "📦 Frame", CONFIG.OTHER_COLOR
    end

    -- ═══ SCROLL ═══
    if class == "ScrollingFrame" then
        return "📜 ScrollFrame", "#AAAAFF"
    end

    -- ═══ VIDEO ═══
    if class == "VideoFrame" then
        return "🎬 Video", "#FF44FF"
    end

    -- ═══ VIEWPORT ═══
    if class == "ViewportFrame" then
        return "👁️ Viewport3D", "#44FFFF"
    end

    return "❓ Other (" .. class .. ")", CONFIG.OTHER_COLOR
end

-------------------------------------------------
-- FORMAT HELPERS
-------------------------------------------------
local function udim2Str(u)
    return string.format(
        "Scale(%.3f, %.3f) Offset(%d, %d)",
        u.X.Scale, u.Y.Scale, u.X.Offset, u.Y.Offset
    )
end

local function offsetOnly(u)
    return string.format("(%d, %d)", u.X.Offset, u.Y.Offset)
end

local function scaleOnly(u)
    return string.format("(%.3f, %.3f)", u.X.Scale, u.Y.Scale)
end

local function absStr(obj)
    return string.format(
        "(%.0f, %.0f)", obj.AbsolutePosition.X, obj.AbsolutePosition.Y
    )
end

local function absSizeStr(obj)
    return string.format(
        "(%.0f, %.0f)", obj.AbsoluteSize.X, obj.AbsoluteSize.Y
    )
end

local function colorStr(c)
    return string.format("(%d,%d,%d)",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

-------------------------------------------------
-- GUI CREATION
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "UIInspectorGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 9999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

-- ═══ TOGGLE BUTTON ═══
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size             = UDim2.new(0, 150, 0, 44)
ToggleBtn.Position         = UDim2.new(1, -160, 0, 60)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
ToggleBtn.TextColor3       = Color3.new(1, 1, 1)
ToggleBtn.Font             = Enum.Font.GothamBold
ToggleBtn.TextSize         = 14
ToggleBtn.Text             = "🔍 Inspector OFF"
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.Parent           = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)
local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = Color3.new(1,1,1); tStroke.Transparency = 0.6

-- ═══ MAIN PANEL ═══
local Panel = Instance.new("Frame")
Panel.Name              = "InspectorPanel"
Panel.Size              = UDim2.new(0, 520, 0, 560)
Panel.Position          = UDim2.new(0.5, -260, 0.5, -280)
Panel.BackgroundColor3  = Color3.fromRGB(15, 15, 25)
Panel.BorderSizePixel   = 0
Panel.Visible           = false
Panel.Active            = true
Panel.Draggable         = true
Panel.Parent            = ScreenGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)
local pStroke = Instance.new("UIStroke", Panel)
pStroke.Color = Color3.fromRGB(0, 200, 255); pStroke.Thickness = 2

-- Title
local Title = Instance.new("TextLabel")
Title.Size                  = UDim2.new(1, -50, 0, 40)
Title.Position              = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Font                  = Enum.Font.GothamBold
Title.TextSize              = 16
Title.TextColor3            = Color3.fromRGB(0, 200, 255)
Title.TextXAlignment        = Enum.TextXAlignment.Left
Title.Text                  = "🔍 UI Inspector — Offset & Classification"
Title.Parent                = Panel

-- Close button
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

-- Filter Bar
local FilterFrame = Instance.new("Frame")
FilterFrame.Size                  = UDim2.new(1, -16, 0, 34)
FilterFrame.Position              = UDim2.new(0, 8, 0, 42)
FilterFrame.BackgroundTransparency = 1
FilterFrame.Parent                = Panel

local filterLayout = Instance.new("UIListLayout", FilterFrame)
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.Padding       = UDim.new(0, 5)

local showOnlyVisible = true
local showHighlight   = true

local function makeFilterBtn(text, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 100, 0, 28)
    btn.BackgroundColor3 = default and Color3.fromRGB(0,160,70) or Color3.fromRGB(80,80,80)
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 11
    btn.Text             = text
    btn.BorderSizePixel  = 0
    btn.Parent           = FilterFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state 
            and Color3.fromRGB(0,160,70) 
            or Color3.fromRGB(80,80,80)
        callback(state)
    end)
    return btn
end

makeFilterBtn("Visible Only", true, function(s) showOnlyVisible = s end)
makeFilterBtn("Highlight", true, function(s) showHighlight = s end)

-- Search box
local SearchBox = Instance.new("TextBox")
SearchBox.Size                  = UDim2.new(0, 140, 0, 28)
SearchBox.BackgroundColor3      = Color3.fromRGB(40, 40, 60)
SearchBox.TextColor3            = Color3.new(1, 1, 1)
SearchBox.PlaceholderText       = "🔎 Search name..."
SearchBox.PlaceholderColor3     = Color3.fromRGB(120, 120, 120)
SearchBox.Font                  = Enum.Font.Gotham
SearchBox.TextSize              = 12
SearchBox.ClearTextOnFocus      = false
SearchBox.BorderSizePixel       = 0
SearchBox.Parent                = FilterFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

-- Stats line
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size                  = UDim2.new(1, -16, 0, 20)
StatsLabel.Position              = UDim2.new(0, 8, 0, 78)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Font                  = Enum.Font.RobotoMono
StatsLabel.TextSize              = 12
StatsLabel.TextColor3            = Color3.fromRGB(150, 150, 150)
StatsLabel.TextXAlignment        = Enum.TextXAlignment.Left
StatsLabel.Text                  = ""
StatsLabel.Parent                = Panel

-- Scroll Frame
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                   = UDim2.new(1, -16, 1, -108)
Scroll.Position               = UDim2.new(0, 8, 0, 100)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel        = 0
Scroll.ScrollBarThickness     = 6
Scroll.ScrollBarImageColor3   = Color3.fromRGB(0, 200, 255)
Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
Scroll.Parent                 = Panel

local scrollPad = Instance.new("UIPadding", Scroll)
scrollPad.PaddingTop    = UDim.new(0, 4)
scrollPad.PaddingBottom = UDim.new(0, 4)

local scrollLayout = Instance.new("UIListLayout", Scroll)
scrollLayout.Padding   = UDim.new(0, 3)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

-------------------------------------------------
-- HIGHLIGHT SYSTEM
-------------------------------------------------
local highlights = {}

local function clearHighlights()
    for _, h in ipairs(highlights) do
        if h and h.Parent then
            h:Destroy()
        end
    end
    table.clear(highlights)
end

local function highlightElement(guiObj)
    if not showHighlight then return end

    -- Tạo viền đỏ xung quanh element
    local h = Instance.new("Frame")
    h.Name                  = "_Highlight"
    h.Size                  = UDim2.new(1, 4, 1, 4)
    h.Position              = UDim2.new(0, -2, 0, -2)
    h.BackgroundTransparency = 1
    h.BorderSizePixel       = 0
    h.ZIndex                = 9999
    h.Parent                = guiObj

    local stroke = Instance.new("UIStroke", h)
    stroke.Color       = CONFIG.HIGHLIGHT_COLOR
    stroke.Thickness   = 2
    stroke.Transparency = 0

    table.insert(highlights, h)
end

-------------------------------------------------
-- ENTRY POOL
-------------------------------------------------
local entryPool   = {}
local activeItems = {}

local function getEntry()
    local e = table.remove(entryPool)
    if not e then
        e = Instance.new("TextButton")
        e.Size                  = UDim2.new(1, -6, 0, 0)
        e.AutomaticSize         = Enum.AutomaticSize.Y
        e.BackgroundColor3      = Color3.fromRGB(25, 25, 40)
        e.BackgroundTransparency = 0.3
        e.TextColor3            = Color3.fromRGB(220, 220, 220)
        e.Font                  = Enum.Font.RobotoMono
        e.TextSize              = 12
        e.TextXAlignment        = Enum.TextXAlignment.Left
        e.TextWrapped           = true
        e.RichText              = true
        e.AutoButtonColor       = true
        e.BorderSizePixel       = 0
        e.TextYAlignment        = Enum.TextYAlignment.Top

        Instance.new("UICorner", e).CornerRadius = UDim.new(0, 6)

        local pad = Instance.new("UIPadding", e)
        pad.PaddingLeft   = UDim.new(0, 8)
        pad.PaddingRight  = UDim.new(0, 8)
        pad.PaddingTop    = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)
    end
    return e
end

local function recycleEntry(e)
    e.Parent = nil
    -- Disconnect old connections
    table.insert(entryPool, e)
end

-------------------------------------------------
-- SCAN & BUILD DATA
-------------------------------------------------
local function isGuiVisible(obj)
    -- Kiểm tra xem element có thực sự hiển thị không
    local current = obj
    while current do
        if current:IsA("GuiObject") then
            if not current.Visible then return false end
            if current.BackgroundTransparency >= 1 then
                -- Frame trong suốt nhưng có thể có children
                if current:IsA("TextLabel") or current:IsA("TextButton") or current:IsA("TextBox") then
                    if current.TextTransparency >= 1 then
                        -- Cả text cũng trong suốt
                    end
                end
            end
        end
        if current:IsA("ScreenGui") then
            if not current.Enabled then return false end
            break
        end
        current = current.Parent
    end
    return true
end

local function scanUI()
    local results = {}
    local searchFilter = SearchBox.Text:lower()

    for _, screenGui in ipairs(PlayerGui:GetChildren()) do
        if screenGui:IsA("ScreenGui") and screenGui ~= ScreenGui then
            local guiName = screenGui.Name

            for _, obj in ipairs(screenGui:GetDescendants()) do
                if obj:IsA("GuiObject") and not obj.Name:find("_Highlight") then

                    -- Lọc visibility
                    if showOnlyVisible and not isGuiVisible(obj) then
                        continue
                    end

                    -- Lọc search
                    if searchFilter ~= "" then
                        local combined = (obj.Name .. " " .. obj.ClassName .. " " .. guiName):lower()
                        if not combined:find(searchFilter) then
                            continue
                        end
                    end

                    local category, color = classifyUI(obj)

                    local info = {
                        obj       = obj,
                        guiName   = guiName,
                        name      = obj.Name,
                        class     = obj.ClassName,
                        category  = category,
                        color     = color,
                        path      = obj:GetFullName(),
                        position  = obj.Position,
                        size      = obj.Size,
                        absPos    = obj.AbsolutePosition,
                        absSize   = obj.AbsoluteSize,
                        anchor    = obj.AnchorPoint,
                        visible   = obj.Visible,
                        zindex    = obj.ZIndex,
                        transparency = obj.BackgroundTransparency,
                        bgColor   = obj.BackgroundColor3,
                        rotation  = obj.Rotation,
                    }

                    -- Extra properties
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        info.text     = obj.Text
                        info.textSize = obj.TextSize
                    end
                    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                        info.image = obj.Image
                    end

                    table.insert(results, info)
                end
            end
        end
    end

    return results
end

-------------------------------------------------
-- RENDER RESULTS
-------------------------------------------------
local selectedObj = nil

local function renderResults()
    -- Clear old
    for _, e in ipairs(activeItems) do
        recycleEntry(e)
    end
    table.clear(activeItems)
    clearHighlights()

    local data = scanUI()

    -- Stats
    StatsLabel.Text = string.format(
        "Found: %d UI elements  |  ScreenGuis: %d  |  Viewport: %.0f×%.0f",
        #data,
        #PlayerGui:GetChildren() - 1,
        Camera.ViewportSize.X,
        Camera.ViewportSize.Y
    )

    -- Group by ScreenGui
    local grouped = {}
    for _, info in ipairs(data) do
        if not grouped[info.guiName] then
            grouped[info.guiName] = {}
        end
        table.insert(grouped[info.guiName], info)
    end

    local order = 0

    for guiName, items in pairs(grouped) do
        -- Header cho mỗi ScreenGui
        order += 1
        local headerEntry = getEntry()
        headerEntry.Text = string.format(
            '<font color="%s"><b>━━━ ScreenGui: %s (%d elements) ━━━</b></font>',
            CONFIG.HEADER_COLOR, guiName, #items
        )
        headerEntry.BackgroundColor3      = Color3.fromRGB(10, 30, 50)
        headerEntry.BackgroundTransparency = 0.2
        headerEntry.LayoutOrder           = order
        headerEntry.Parent                = Scroll
        table.insert(activeItems, headerEntry)

        for _, info in ipairs(items) do
            order += 1
            local entry = getEntry()

            -- Tạo nội dung chi tiết
            local lines = {}

            -- Dòng 1: Tên + Phân loại
            table.insert(lines, string.format(
                '<font color="%s"><b>%s</b></font>  <font color="#AAAAAA">[%s]</font>',
                info.color, info.category, info.class
            ))

            -- Dòng 2: Tên element + path ngắn
            table.insert(lines, string.format(
                '<font color="#FFD700">Name:</font> %s',
                info.name
            ))

            -- Dòng 3: Position breakdown
            table.insert(lines, string.format(
                '<font color="#88CCFF">Position:</font> %s',
                udim2Str(info.position)
            ))
            table.insert(lines, string.format(
                '  <font color="#66AADD">↳ Offset:</font> %s  <font color="#66AADD">Scale:</font> %s',
                offsetOnly(info.position), scaleOnly(info.position)
            ))

            -- Dòng 4: Size breakdown  
            table.insert(lines, string.format(
                '<font color="#88FFCC">Size:</font> %s',
                udim2Str(info.size)
            ))
            table.insert(lines, string.format(
                '  <font color="#66DDAA">↳ Offset:</font> %s  <font color="#66DDAA">Scale:</font> %s',
                offsetOnly(info.size), scaleOnly(info.size)
            ))

            -- Dòng 5: Absolute (pixel thực tế trên màn hình)
            table.insert(lines, string.format(
                '<font color="#FFAA44">AbsolutePos:</font> %s  <font color="#FFAA44">AbsoluteSize:</font> %s',
                absStr(info), absSizeStr(info)
            ))

            -- Dòng 6: Thông tin bổ sung
            table.insert(lines, string.format(
                '<font color="#AAAAAA">Anchor:</font> (%.1f,%.1f)  ' ..
                '<font color="#AAAAAA">ZIndex:</font> %d  ' ..
                '<font color="#AAAAAA">Rotation:</font> %.1f°  ' ..
                '<font color="#AAAAAA">Transp:</font> %.2f',
                info.anchor.X, info.anchor.Y,
                info.zindex,
                info.rotation,
                info.transparency
            ))

            -- Background color
            table.insert(lines, string.format(
                '<font color="#AAAAAA">BgColor:</font> %s  <font color="#AAAAAA">Visible:</font> %s',
                colorStr(info.bgColor),
                tostring(info.visible)
            ))

            -- Text content nếu có
            if info.text and info.text ~= "" then
                local displayText = info.text:sub(1, 60)
                if #info.text > 60 then displayText = displayText .. "..." end
                -- Escape rich text
                displayText = displayText:gsub("<", "&lt;"):gsub(">", "&gt;")
                table.insert(lines, string.format(
                    '<font color="#FFFFFF">Text:</font> "%s"  <font color="#AAAAAA">Size:</font> %d',
                    displayText, info.textSize or 0
                ))
            end

            -- Image nếu có
            if info.image and info.image ~= "" then
                local imgDisplay = info.image:sub(1, 50)
                table.insert(lines, string.format(
                    '<font color="%s">Image:</font> %s',
                    CONFIG.IMAGE_COLOR, imgDisplay
                ))
            end

            -- Full path
            table.insert(lines, string.format(
                '<font color="#666666">Path: %s</font>',
                info.path
            ))

            entry.Text        = table.concat(lines, "\n")
            entry.LayoutOrder = order
            entry.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
            entry.BackgroundTransparency = 0.3
            entry.Parent      = Scroll
            table.insert(activeItems, entry)

            -- Click để highlight element đó
            local capturedObj = info.obj
            entry.MouseButton1Click:Connect(function()
                clearHighlights()
                if capturedObj and capturedObj.Parent then
                    highlightElement(capturedObj)
                    selectedObj = capturedObj

                    -- Flash hiệu ứng trên entry
                    entry.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
                    task.delay(0.3, function()
                        if entry.Parent then
                            entry.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
                        end
                    end)
                end
            end)
        end
    end

    -- Nếu không tìm thấy gì
    if #data == 0 then
        order += 1
        local empty = getEntry()
        empty.Text = '<font color="#FF8888"><b>Không tìm thấy UI element nào.</b></font>\n' ..
                     '<font color="#AAAAAA">Thử tắt "Visible Only" hoặc xóa search filter.</font>'
        empty.LayoutOrder = order
        empty.Parent      = Scroll
        table.insert(activeItems, empty)
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
        ToggleBtn.Text             = "🔍 Inspector ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 70)

        renderResults()

        if updateConn then updateConn:Disconnect() end
        local elapsed = 0
        updateConn = RunService.Heartbeat:Connect(function(dt)
            elapsed += dt
            if elapsed >= CONFIG.REFRESH_RATE then
                elapsed = 0
                renderResults()
            end
        end)
    else
        ToggleBtn.Text             = "🔍 Inspector OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)

        clearHighlights()
        if updateConn then
            updateConn:Disconnect()
            updateConn = nil
        end
        for _, e in ipairs(activeItems) do
            recycleEntry(e)
        end
        table.clear(activeItems)
    end
end

-------------------------------------------------
-- EVENTS
-------------------------------------------------
ToggleBtn.MouseButton1Click:Connect(function()
    setOpen(not isOpen)
end)

CloseBtn.MouseButton1Click:Connect(function()
    setOpen(false)
end)

-- F3 shortcut (PC)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F3 then
        setOpen(not isOpen)
    end
end)

-------------------------------------------------
-- STARTUP
-------------------------------------------------
print("═══════════════════════════════════════════")
print("  🔍 UI Inspector Loaded")
print("  Toggle: Nút trên màn hình hoặc F3")
print("  Click vào element để highlight nó")
print("═══════════════════════════════════════════")
