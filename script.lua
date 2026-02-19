--================================================================
--  ESP Script | PC + Mobile | GUI Toggle | Wall Check
--  PC: RightShift để ẩn/hiện menu
--  Mobile: Nhấn nút "ESP" trên thanh công cụ để bật/tắt
--================================================================

-- Dọn dẹp nếu chạy lại script
if _G._ESPClean then pcall(_G._ESPClean) end

--// Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local TextChatService  = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

--// Lưu connections để cleanup
local _conns    = {}
local _gui      = nil
local _folder   = nil
local ESPStore  = {}

--// Config
local CONFIG = {
    ESPEnabled = true,
    BoxESP     = true,
    NameESP    = true,
    HealthBar  = true,
    WallCheck  = true,
    TextSize   = 14,
    BoxThick   = 1,
    TeamColor  = Color3.fromRGB(0, 255, 0),
    EnemyColor = Color3.fromRGB(255, 0, 0),
    MaxDist    = 2000,
    FillAlpha  = 0.5,
    MenuKey    = Enum.KeyCode.RightShift,
}

--// Kiểm tra Mobile
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

--// Ẩn thanh điều hướng Roblox (cho Mobile)
if isMobile then
    StarterGui:SetCore("TopbarEnabled", false)
end

--// ========================
--// TEAM DETECTION
--// ========================
local TextChannels = TextChatService:WaitForChild("TextChannels", 10)
local team1 = TextChannels and TextChannels:WaitForChild("team1", 5)
local team2 = TextChannels and TextChannels:WaitForChild("team2", 5)

local function isSameTeam(p1, p2)
    if not team1 or not team2 then return false end
    local function getTeam(p)
        if team1:FindFirstChild(p.Name) then return 1 end
        if team2:FindFirstChild(p.Name) then return 2 end
        return nil
    end
    local a, b = getTeam(p1), getTeam(p2)
    return a and b and a == b
end

local function getColor(player)
    return isSameTeam(LocalPlayer, player)
        and CONFIG.TeamColor
        or  CONFIG.EnemyColor
end

--// ========================
--// WALL CHECK (Raycast)
--// ========================
local rayParams = RaycastParams.new()
rayParams.FilterType       = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function isVisible(character)
    local origin = Camera.CFrame.Position
    local filter = { character }
    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end
    rayParams.FilterDescendantsInstances = filter

    -- Kiểm tra nhiều bộ phận: nếu thấy 1 cái = Visible
    for _, name in ipairs({"Head", "HumanoidRootPart", "Torso", "UpperTorso"}) do
        local part = character:FindFirstChild(name)
        if part then
            local result = workspace:Raycast(origin, part.Position - origin, rayParams)
            if not result then
                return true
            end
        end
    end
    return false
end

--// ========================
--// GUI MENU (PC + Mobile)
--// ========================
local menuVisible = true

local function createMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name          = HttpService:GenerateGUID(false)
    gui.Parent        = CoreGui
    gui.ResetOnSpawn  = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true -- Tránh bị che bởi thanh điều hướng

    -- Main frame (responsive)
    local main = Instance.new("Frame")
    main.Size            = UDim2.new(0, isMobile and 220 or 240, 0, 10) -- Tự động resize
    main.Position        = UDim2.new(0.5, isMobile and -110 or -120, 0, 60)
    main.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    main.BorderSizePixel  = 0
    main.Parent           = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color          = Color3.fromRGB(110, 60, 210)
    stroke.Thickness      = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    --// Title bar (kéo thả)
    local titleBar = Instance.new("Frame")
    titleBar.Size            = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    titleBar.BorderSizePixel  = 0
    titleBar.Parent           = main
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

    -- Fix góc dưới title
    local fix = Instance.new("Frame")
    fix.Size            = UDim2.new(1, 0, 0, 12)
    fix.Position        = UDim2.new(0, 0, 1, -12)
    fix.BackgroundColor3 = titleBar.BackgroundColor3
    fix.BorderSizePixel  = 0
    fix.Parent           = titleBar

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size               = UDim2.new(1, 0, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text               = "⚡ ESP PANEL"
    titleLbl.TextColor3         = Color3.fromRGB(180, 130, 255)
    titleLbl.Font               = Enum.Font.GothamBold
    titleLbl.TextSize           = isMobile and 14 or 15
    titleLbl.Parent             = titleBar

    --// Dragging (PC + Mobile)
    local dragging, dragStart, startPos
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end

    titleBar.InputBegan:Connect(startDrag)
    table.insert(_conns, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end))

    --// Content
    local content = Instance.new("Frame")
    content.Size               = UDim2.new(1, -20, 0, 0)
    content.Position           = UDim2.new(0, 10, 0, 42)
    content.BackgroundTransparency = 1
    content.AutomaticSize      = Enum.AutomaticSize.Y
    content.Parent             = main

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding   = UDim.new(0, 5)
    list.Parent    = content

    --// Toggle factory (nút bấm lớn cho Mobile)
    local function addToggle(text, configKey, order)
        local row = Instance.new("Frame")
        row.Size            = UDim2.new(1, 0, 0, isMobile and 40 or 32)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        row.BorderSizePixel  = 0
        row.LayoutOrder      = order
        row.Parent           = content
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1, -80, 1, 0)
        lbl.Position           = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text               = text
        lbl.TextColor3         = Color3.fromRGB(210, 210, 220)
        lbl.Font               = Enum.Font.Gotham
        lbl.TextSize           = isMobile and 13 or 13
        lbl.TextXAlignment     = Enum.TextXAlignment.Left
        lbl.Parent             = row

        local btn = Instance.new("TextButton")
        btn.Size            = UDim2.new(0, isMobile and 60 or 50, 0, isMobile and 28 or 22)
        btn.Position        = UDim2.new(1, isMobile and -68 or -58, 0.5, isMobile and -14 or -11)
        btn.BorderSizePixel = 0
        btn.Font            = Enum.Font.GothamBold
        btn.TextSize        = isMobile and 12 or 11
        btn.TextColor3      = Color3.new(1, 1, 1)
        btn.AutoButtonColor = true
        btn.Parent          = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

        local function update()
            if CONFIG[configKey] then
                btn.Text            = "ON"
                btn.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
            else
                btn.Text            = "OFF"
                btn.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
            end
        end
        update()

        btn.MouseButton1Click:Connect(function()
            CONFIG[configKey] = not CONFIG[configKey]
            update()
        end)
    end

    addToggle("ESP Master",  "ESPEnabled", 1)
    addToggle("Box ESP",     "BoxESP",     2)
    addToggle("Name / Dist", "NameESP",    3)
    addToggle("Health Bar",  "HealthBar",  4)
    addToggle("Wall Check",  "WallCheck",  5)

    --// Auto-resize main frame
    local function resize()
        main.Size = UDim2.new(0, isMobile and 220 or 240, 0, 42 + content.AbsoluteSize.Y + 28)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
    task.defer(resize)

    --// Footer
    local hint = Instance.new("TextLabel")
    hint.Size               = UDim2.new(1, 0, 0, 16)
    hint.Position           = UDim2.new(0, 0, 1, -20)
    hint.BackgroundTransparency = 1
    hint.Text               = isMobile and "Tap 'ESP' to toggle" or "RightShift = toggle menu"
    hint.TextColor3         = Color3.fromRGB(85, 85, 100)
    hint.Font               = Enum.Font.Gotham
    hint.TextSize           = 10
    hint.Parent             = main

    --// Phím tắt ẩn/hiện (PC + Mobile)
    if isMobile then
        -- Tạo nút bấm trên thanh công cụ (Mobile)
        local mobileButton = Instance.new("TextButton")
        mobileButton.Name = "ESPButton"
        mobileButton.Size = UDim2.new(0, 60, 0, 30)
        mobileButton.Position = UDim2.new(1, -70, 0, 10)
        mobileButton.BackgroundColor3 = Color3.fromRGB(110, 60, 210)
        mobileButton.TextColor3 = Color3.new(1, 1, 1)
        mobileButton.Text = "ESP"
        mobileButton.Font = Enum.Font.GothamBold
        mobileButton.TextSize = 12
        mobileButton.Parent = gui
        Instance.new("UICorner", mobileButton).CornerRadius = UDim.new(0, 5)

        mobileButton.MouseButton1Click:Connect(function()
            menuVisible = not menuVisible
            main.Visible = menuVisible
        end)
    else
        -- Phím tắt PC
        table.insert(_conns, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == CONFIG.MenuKey then
                menuVisible = not menuVisible
                main.Visible = menuVisible
            end
        end))
    end

    return gui
end

_gui = createMenu()

--// ========================
--// ESP RENDERING
--// ========================

local useDrawing = pcall(function()
    local t = Drawing.new("Line"); t:Remove()
end)

-- ╔════════════════════════════════════════════╗
-- ║  METHOD 1: DRAWING API (PC + Mobile)      ║
-- ╚════════════════════════════════════════════╝
if useDrawing then

    local function w2s(pos)
        local v, vis = Camera:WorldToViewportPoint(pos)
        return Vector2.new(v.X, v.Y), vis, v.Z
    end

    local function make(player)
        local d = {
            BoxOut   = Drawing.new("Square"),
            Box      = Drawing.new("Square"),
            Name     = Drawing.new("Text"),
            Dist     = Drawing.new("Text"),
            HpBG     = Drawing.new("Square"),
            HpBar    = Drawing.new("Square"),
            HpOut    = Drawing.new("Square"),
            WallText = Drawing.new("Text"),
        }

        d.BoxOut.Thickness = CONFIG.BoxThick + 2
        d.BoxOut.Filled    = false
        d.BoxOut.Color     = Color3.new(0, 0, 0)
        d.BoxOut.ZIndex    = 1

        d.Box.Thickness = CONFIG.BoxThick
        d.Box.Filled    = false
        d.Box.ZIndex    = 2

        d.Name.Size    = CONFIG.TextSize
        d.Name.Center  = true
        d.Name.Outline = true
        d.Name.Font    = 2
        d.Name.ZIndex  = 3

        d.Dist.Size    = CONFIG.TextSize - 2
        d.Dist.Center  = true
        d.Dist.Outline = true
        d.Dist.Font    = 2
        d.Dist.Color   = Color3.new(1, 1, 1)
        d.Dist.ZIndex  = 3

        d.HpBG.Filled       = true
        d.HpBG.Color        = Color3.new(0, 0, 0)
        d.HpBG.Transparency = 0.5
        d.HpBG.ZIndex       = 1

        d.HpBar.Filled = true
        d.HpBar.ZIndex = 2

        d.HpOut.Filled    = false
        d.HpOut.Thickness = 1
        d.HpOut.Color     = Color3.new(0, 0, 0)
        d.HpOut.ZIndex    = 3

        d.WallText.Size    = CONFIG.TextSize - 1
        d.WallText.Center  = false
        d.WallText.Outline = true
        d.WallText.Font    = 2
        d.WallText.ZIndex  = 4

        for _, obj in pairs(d) do obj.Visible = false end
        ESPStore[player] = d
        return d
    end

    local function hide(d)
        for _, obj in pairs(d) do obj.Visible = false end
    end

    local function destroy(player)
        local d = ESPStore[player]
        if d then
            for _, obj in pairs(d) do pcall(obj.Remove, obj) end
            ESPStore[player] = nil
        end
    end

    --// RENDER LOOP
    table.insert(_conns, RunService.RenderStepped:Connect(function()
        Camera = workspace.CurrentCamera

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end

            local d = ESPStore[player] or make(player)

            -- Master toggle
            if not CONFIG.ESPEnabled then
                hide(d); continue
            end

            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and (char:FindFirstChild("HumanoidRootPart")
                                or char:FindFirstChild("Torso"))
            local head = char and char:FindFirstChild("Head")

            if not (char and hum and root and head and hum.Health > 0) then
                hide(d); continue
            end

            local dist = (root.Position - Camera.CFrame.Position).Magnitude
            if dist > CONFIG.MaxDist then hide(d); continue end

            local _, onScreen, depth = w2s(root.Position)
            if not onScreen or depth <= 0 then hide(d); continue end

            local color  = getColor(player)
            local topPos = w2s(head.Position + Vector3.new(0, 1, 0))
            local botPos = w2s(root.Position - Vector3.new(0, 3, 0))
            local midPos = w2s(root.Position)
            local h      = math.abs(topPos.Y - botPos.Y)
            local w      = h * 0.55
            local bxPos  = Vector2.new(midPos.X - w / 2, topPos.Y)
            local bxSize = Vector2.new(w, h)

            ------------------------------------------------
            -- BOX ESP
            ------------------------------------------------
            if CONFIG.BoxESP then
                d.BoxOut.Position = bxPos
                d.BoxOut.Size     = bxSize
                d.BoxOut.Visible  = true
                d.Box.Position = bxPos
                d.Box.Size     = bxSize
                d.Box.Color    = color
                d.Box.Visible  = true
            else
                d.BoxOut.Visible = false
                d.Box.Visible   = false
            end

            ------------------------------------------------
            -- NAME + DISTANCE
            ------------------------------------------------
            if CONFIG.NameESP then
                d.Name.Position = Vector2.new(midPos.X, topPos.Y - 18)
                d.Name.Text     = player.DisplayName
                d.Name.Color    = color
                d.Name.Visible  = true

                d.Dist.Position = Vector2.new(midPos.X, botPos.Y + 2)
                d.Dist.Text     = ("[%d studs]"):format(dist)
                d.Dist.Visible  = true
            else
                d.Name.Visible = false
                d.Dist.Visible = false
            end

            ------------------------------------------------
            -- HEALTH BAR
            ------------------------------------------------
            if CONFIG.HealthBar then
                local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local bw  = 3
                local bx  = bxPos.X - bw - 4

                d.HpOut.Position = Vector2.new(bx - 1, topPos.Y - 1)
                d.HpOut.Size     = Vector2.new(bw + 2, h + 2)
                d.HpOut.Visible  = true

                d.HpBG.Position = Vector2.new(bx, topPos.Y)
                d.HpBG.Size     = Vector2.new(bw, h)
                d.HpBG.Visible  = true

                d.HpBar.Position = Vector2.new(bx, topPos.Y + h * (1 - pct))
                d.HpBar.Size     = Vector2.new(bw, h * pct)
                d.HpBar.Color    = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
                d.HpBar.Visible  = true
            else
                d.HpOut.Visible = false
                d.HpBG.Visible  = false
                d.HpBar.Visible = false
            end

            ------------------------------------------------
            -- WALL CHECK
            ------------------------------------------------
            if CONFIG.WallCheck then
                local vis = isVisible(char)
                d.WallText.Position = Vector2.new(bxPos.X + bxSize.X + 5, midPos.Y - 7)
                if vis then
                    d.WallText.Text  = "[Visible]"
                    d.WallText.Color = Color3.fromRGB(0, 255, 100)
                else
                    d.WallText.Text  = "[Behind Wall]"
                    d.WallText.Color = Color3.fromRGB(255, 170, 0)
                end
                d.WallText.Visible = true
            else
                d.WallText.Visible = false
            end
        end
    end))

    table.insert(_conns, Players.PlayerRemoving:Connect(destroy))

-- ╔════════════════════════════════════════════╗
-- ║  METHOD 2: HIGHLIGHT FALLBACK (PC + Mobile) ║
-- ╚════════════════════════════════════════════╝
else

    _folder = Instance.new("Folder")
    _folder.Name   = HttpService:GenerateGUID(false)
    _folder.Parent = CoreGui

    local function createHL(character, player)
        if player == LocalPlayer then return end
        local hum = character:WaitForChild("Humanoid", 5)
        if not hum then return end

        -- Xóa cũ
        local tag = "E" .. player.UserId
        local old = _folder:FindFirstChild(tag)
        if old then old:Destroy() end
        local old2 = _folder:FindFirstChild("I" .. player.UserId)
        if old2 then old2:Destroy() end

        local hl     = Instance.new("Highlight")
        hl.Name      = tag
        hl.Adornee   = character
        hl.Parent    = _folder
        hl.FillTransparency    = CONFIG.FillAlpha
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        local headPart = character:WaitForChild("Head", 5)

        local bb = Instance.new("BillboardGui")
        bb.Name        = "I" .. player.UserId
        bb.Adornee     = headPart
        bb.Size        = UDim2.new(0, 200, 0, 60)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent      = _folder

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size               = UDim2.new(1, 0, 0.5, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text               = player.DisplayName
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextScaled         = true
        nameLbl.Font               = Enum.Font.GothamBold
        nameLbl.Parent             = bb

        local wallLbl = Instance.new("TextLabel")
        wallLbl.Size               = UDim2.new(1, 0, 0.4, 0)
        wallLbl.Position           = UDim2.new(0, 0, 0.55, 0)
        wallLbl.BackgroundTransparency = 1
        wallLbl.TextStrokeTransparency = 0
        wallLbl.TextScaled         = true
        wallLbl.Font               = Enum.Font.GothamBold
        wallLbl.Parent             = bb

        ESPStore[player] = {
            hl = hl, bb = bb, char = character,
            nameLbl = nameLbl, wallLbl = wallLbl,
        }

        hum.Died:Connect(function()
            task.delay(1, function()
                pcall(function() hl:Destroy() end)
                pcall(function() bb:Destroy() end)
            end)
        end)
    end

    -- Cập nhật mỗi frame cho highlight
    table.insert(_conns, RunService.RenderStepped:Connect(function()
        Camera = workspace.CurrentCamera
        for player, data in pairs(ESPStore) do
            if not CONFIG.ESPEnabled then
                data.hl.Enabled = false
                data.bb.Enabled = false
                continue
            end

            data.hl.Enabled = true
            data.bb.Enabled = CONFIG.NameESP

            local c = getColor(player)
            data.hl.FillColor    = c
            data.hl.OutlineColor = c
            data.nameLbl.TextColor3 = c

            if CONFIG.WallCheck and data.char and data.char.Parent then
                local vis = isVisible(data.char)
                data.wallLbl.Visible = true
                if vis then
                    data.wallLbl.Text       = "[Visible]"
                    data.wallLbl.TextColor3 = Color3.fromRGB(0, 255, 100)
                else
                    data.wallLbl.Text       = "[Behind Wall]"
                    data.wallLbl.TextColor3 = Color3.fromRGB(255, 170, 0)
                end
            else
                data.wallLbl.Visible = false
            end
        end
    end))

    local function onJoin(player)
        if player == LocalPlayer then return end
        table.insert(_conns, player.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            createHL(c, player)
        end))
        if player.Character then createHL(player.Character, player) end
    end

    for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
    table.insert(_conns, Players.PlayerAdded:Connect(onJoin))
    table.insert(_conns, Players.PlayerRemoving:Connect(function(p)
        local d = ESPStore[p]
        if d then
            pcall(function() d.hl:Destroy() end)
            pcall(function() d.bb:Destroy() end)
            ESPStore[p] = nil
        end
    end))
end

--// ========================
--// CLEANUP (cho lần chạy sau)
--// ========================
_G._ESPClean = function()
    -- Ngắt mọi connection
    for _, c in pairs(_conns) do
        pcall(function() c:Disconnect() end)
    end
    _conns = {}

    -- Xóa Drawing objects / Instances
    for _, d in pairs(ESPStore) do
        for _, obj in pairs(d) do
            pcall(function() obj:Remove() end)
            pcall(function() obj:Destroy() end)
        end
    end
    ESPStore = {}

    -- Xóa GUI + folder
    if _gui    then pcall(function() _gui:Destroy() end) end
    if _folder then pcall(function() _folder:Destroy() end) end

    -- Khôi phục thanh điều hướng (Mobile)
    if isMobile then
        StarterGui:SetCore("TopbarEnabled", true)
    end
end

print("[ESP] Loaded | PC: RightShift | Mobile: Tap 'ESP' button")
