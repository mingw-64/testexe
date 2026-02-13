--[[
    Crosshair Detector + Auto-Fire + ESP v2.0
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
local PADDING         = 15
local FIRE_RATE       = 0.08
local SHOW_OFF_MSG    = true

local BODY_PARTS = {
	"Head","HumanoidRootPart","UpperTorso","LowerTorso",
	"Torso","Left Arm","Right Arm","Left Leg","Right Leg",
	"LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
	"LeftLowerArm","RightLowerArm","LeftLowerLeg","RightLowerLeg",
	"LeftHand","RightHand","LeftFoot","RightFoot",
}

local autofireOn = true
local espOn      = true

-- ═══════════════════════════════════════════════
-- FIND CROSSHAIR
-- ═══════════════════════════════════════════════
local cursorGui      = PlayerGui:WaitForChild("cursor", 10)
local crosshairFrame = cursorGui and cursorGui:WaitForChild("Frame", 10)
if not crosshairFrame then
	warn("❌ Không tìm thấy cursor.Frame!")
	return
end
print("✅ Crosshair:", crosshairFrame:GetFullName())

-- ═══════════════════════════════════════════════
-- FIND FIRE BUTTON
-- ═══════════════════════════════════════════════
local fireButton = nil

local function findFireButton()
	if fireButton and fireButton.Parent then return true end
	fireButton = nil
	pcall(function()
		local m = PlayerGui:FindFirstChild("mobile")
		if not m then return end
		local w = m:FindFirstChild("weapon")
		if not w then return end
		local f = w:FindFirstChild("fire")
		if not f then return end
		fireButton = f:FindFirstChild("fire")
	end)
	return fireButton ~= nil
end

findFireButton()
if fireButton then
	print("✅ Fire button:", fireButton:GetFullName())
else
	warn("⚠️ Fire button chưa tìm thấy, sẽ tự thử lại...")
end

-- ═══════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════
local overlapping   = {}
local totalHits     = 0
local lastFireTime  = 0
local currentTarget = nil
local isFiringNow   = false

-- ═══════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════
local function isEnemy(player)
	if LocalPlayer.Team and player.Team then
		return player.Team ~= LocalPlayer.Team
	end
	return true  -- không có team → coi là địch
end

local function getTeamColor(player)
	return isEnemy(player)
		and Color3.fromRGB(255, 0, 0)
		or  Color3.fromRGB(0, 255, 0)
end

local function getTeamTag(player)
	return isEnemy(player) and "ENEMY" or "ALLY"
end

local function getDistance(character)
	local myChar = LocalPlayer.Character
	if not myChar then return math.huge end
	local a = myChar:FindFirstChild("HumanoidRootPart")
	local b = character:FindFirstChild("HumanoidRootPart")
	if a and b then return (a.Position - b.Position).Magnitude end
	return math.huge
end

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

local function pointInBounds(px, py, b)
	return px >= b.x1 and px <= b.x2 and py >= b.y1 and py <= b.y2
end

local function getCharScreenPoints(character)
	local pts = {}
	for _, name in ipairs(BODY_PARTS) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			local sp, on = Camera:WorldToScreenPoint(part.Position)
			if on then
				table.insert(pts, {x=sp.X, y=sp.Y, part=name, dist=sp.Z})
			end
			local top = part.Position + Vector3.new(0, part.Size.Y/2, 0)
			local bot = part.Position - Vector3.new(0, part.Size.Y/2, 0)
			local s1, o1 = Camera:WorldToScreenPoint(top)
			if o1 then table.insert(pts, {x=s1.X,y=s1.Y,part=name.."↑",dist=s1.Z}) end
			local s2, o2 = Camera:WorldToScreenPoint(bot)
			if o2 then table.insert(pts, {x=s2.X,y=s2.Y,part=name.."↓",dist=s2.Z}) end
		end
	end
	return pts
end

-- ═══════════════════════════════════════════════
-- GUI — NOTIFICATIONS
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
NotifLabel.BackgroundColor3       = Color3.fromRGB(0,0,0)
NotifLabel.BackgroundTransparency = 0.4
NotifLabel.TextColor3             = Color3.fromRGB(255,80,80)
NotifLabel.Font                   = Enum.Font.GothamBold
NotifLabel.TextSize               = 18
NotifLabel.Text                   = ""
NotifLabel.Visible                = false
NotifLabel.BorderSizePixel        = 0
NotifLabel.ZIndex                 = 100
NotifLabel.RichText               = true
NotifLabel.Parent                 = NotifGui
Instance.new("UICorner", NotifLabel).CornerRadius = UDim.new(0,10)
local nStroke        = Instance.new("UIStroke", NotifLabel)
nStroke.Color        = Color3.fromRGB(255,50,50)
nStroke.Thickness    = 2

local HitCounter = Instance.new("TextLabel")
HitCounter.Size                   = UDim2.new(0, 200, 0, 35)
HitCounter.Position               = UDim2.new(0.5, -100, 0, 135)
HitCounter.BackgroundColor3       = Color3.fromRGB(0,0,0)
HitCounter.BackgroundTransparency = 0.5
HitCounter.TextColor3             = Color3.fromRGB(100,255,100)
HitCounter.Font                   = Enum.Font.RobotoMono
HitCounter.TextSize               = 14
HitCounter.Text                   = "Hits: 0"
HitCounter.Visible                = true
HitCounter.BorderSizePixel        = 0
HitCounter.ZIndex                 = 100
HitCounter.RichText               = true
HitCounter.Parent                 = NotifGui
Instance.new("UICorner", HitCounter).CornerRadius = UDim.new(0,8)

local notifHideTime = 0
local function showNotif(text, color)
	NotifLabel.Text       = text
	NotifLabel.TextColor3 = color or Color3.fromRGB(255,80,80)
	NotifLabel.Visible    = true
	nStroke.Color         = color or Color3.fromRGB(255,50,50)
	notifHideTime         = tick() + 1.5
end

-- ═══════════════════════════════════════════════
-- GUI — STATUS PANEL  (góc trên-trái)
-- ═══════════════════════════════════════════════
local StatusGui = Instance.new("ScreenGui")
StatusGui.Name           = "StatusPanel"
StatusGui.ResetOnSpawn   = false
StatusGui.DisplayOrder   = 99999
StatusGui.IgnoreGuiInset = true
StatusGui.Parent         = PlayerGui

local sFrame = Instance.new("Frame")
sFrame.Size                   = UDim2.new(0, 260, 0, 95)
sFrame.Position               = UDim2.new(0, 10, 0, 10)
sFrame.BackgroundColor3       = Color3.fromRGB(12,12,12)
sFrame.BackgroundTransparency = 0.15
sFrame.BorderSizePixel        = 0
sFrame.Parent                 = StatusGui
Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0,10)
local ss = Instance.new("UIStroke", sFrame)
ss.Color = Color3.fromRGB(70,70,70); ss.Thickness = 1

local function makeLabel(name, order, parent)
	local l = Instance.new("TextLabel")
	l.Name                   = name
	l.Size                   = UDim2.new(1,-14,0,20)
	l.Position               = UDim2.new(0,7,0, 5 + order*21)
	l.BackgroundTransparency = 1
	l.Font                   = Enum.Font.RobotoMono
	l.TextSize               = 13
	l.TextXAlignment         = Enum.TextXAlignment.Left
	l.RichText               = true
	l.TextColor3             = Color3.fromRGB(220,220,220)
	l.Parent                 = parent
	return l
end

local titleLbl = makeLabel("Title",  0, sFrame)
titleLbl.Font      = Enum.Font.GothamBold
titleLbl.TextColor3 = Color3.fromRGB(255,200,50)
titleLbl.Text       = "🎯 CROSSHAIR TOOLS v2"

local afLbl  = makeLabel("AF",  1, sFrame)
local esLbl  = makeLabel("ESP", 2, sFrame)
local tgtLbl = makeLabel("TGT", 3, sFrame)

local function refreshStatus()
	afLbl.Text = autofireOn
		and '[F1] Auto-Fire: <font color="#00FF00">ON</font>'
		or  '[F1] Auto-Fire: <font color="#FF4444">OFF</font>'
	esLbl.Text = espOn
		and '[F2] ESP: <font color="#00FF00">ON</font>'
		or  '[F2] ESP: <font color="#FF4444">OFF</font>'
	if currentTarget then
		tgtLbl.Text = string.format('🎯 <font color="#FF6644">%s</font>', currentTarget.Name)
	else
		tgtLbl.Text = '🎯 <font color="#666">None</font>'
	end
end
refreshStatus()

-- ═══════════════════════════════════════════════
-- AUTO-FIRE
-- ═══════════════════════════════════════════════
local function tapFire()
	if not findFireButton() then return end

	task.spawn(function()
		local usedTouch = false

		-- Thử firetouchinterest (executor function)
		pcall(function()
			firetouchinterest(fireButton, fireButton, 0)
			usedTouch = true
		end)

		-- Fallback: VirtualInputManager
		if not usedTouch then
			pcall(function()
				local VIM = game:GetService("VirtualInputManager")
				local p   = fireButton.AbsolutePosition
				local s   = fireButton.AbsoluteSize
				VIM:SendMouseButtonEvent(p.X + s.X/2, p.Y + s.Y/2, 0, true, game, 1)
			end)
		end

		task.wait(0.05)

		-- Release
		if usedTouch then
			pcall(function() firetouchinterest(fireButton, fireButton, 1) end)
		else
			pcall(function()
				local VIM = game:GetService("VirtualInputManager")
				local p   = fireButton.AbsolutePosition
				local s   = fireButton.AbsoluteSize
				VIM:SendMouseButtonEvent(p.X + s.X/2, p.Y + s.Y/2, 0, false, game, 1)
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════
local espFolder = Instance.new("Folder")
espFolder.Name   = "ESP_Holder"
espFolder.Parent = PlayerGui

local espCache = {}   -- [Player] = { highlight, billboard, nameL, infoL, hpFill }
local espConns = {}   -- [Player] = { connections }

local function destroyESP(player)
	local d = espCache[player]
	if d then
		pcall(function() d.highlight:Destroy() end)
		pcall(function() d.billboard:Destroy() end)
		espCache[player] = nil
	end
	local c = espConns[player]
	if c then
		for _, cn in ipairs(c) do pcall(function() cn:Disconnect() end) end
		espConns[player] = nil
	end
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
	local tag = getTeamTag(player)

	-- ─── Highlight ───
	local hl = Instance.new("Highlight")
	hl.Name                = "ESP_HL"
	hl.FillColor           = col
	hl.FillTransparency    = 0.5
	hl.OutlineColor        = col
	hl.OutlineTransparency = 0
	hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Enabled             = espOn
	hl.Parent              = char

	-- ─── Billboard ───
	local bb = Instance.new("BillboardGui")
	bb.Name         = "ESP_BB"
	bb.Adornee      = head
	bb.Size         = UDim2.new(0, 200, 0, 58)
	bb.StudsOffset  = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop  = true
	bb.Enabled      = espOn
	bb.Parent       = espFolder

	local nameL = Instance.new("TextLabel")
	nameL.Name                   = "N"
	nameL.Size                   = UDim2.new(1,0,0,18)
	nameL.BackgroundTransparency = 1
	nameL.TextColor3             = col
	nameL.Font                   = Enum.Font.GothamBold
	nameL.TextSize               = 14
	nameL.Text                   = player.Name .. " [" .. tag .. "]"
	nameL.TextStrokeTransparency = 0
	nameL.TextStrokeColor3       = Color3.new(0,0,0)
	nameL.Parent                 = bb

	local infoL = Instance.new("TextLabel")
	infoL.Name                   = "I"
	infoL.Size                   = UDim2.new(1,0,0,16)
	infoL.Position               = UDim2.new(0,0,0,18)
	infoL.BackgroundTransparency = 1
	infoL.TextColor3             = Color3.fromRGB(220,220,220)
	infoL.Font                   = Enum.Font.RobotoMono
	infoL.TextSize               = 12
	infoL.Text                   = ""
	infoL.TextStrokeTransparency = 0
	infoL.TextStrokeColor3       = Color3.new(0,0,0)
	infoL.Parent                 = bb

	-- HP bar
	local hpBg = Instance.new("Frame")
	hpBg.Size                   = UDim2.new(0.8,0,0,5)
	hpBg.Position               = UDim2.new(0.1,0,0,36)
	hpBg.BackgroundColor3       = Color3.fromRGB(40,40,40)
	hpBg.BorderSizePixel        = 0
	hpBg.Parent                 = bb
	Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0,3)

	local hpFill = Instance.new("Frame")
	hpFill.Name              = "F"
	hpFill.Size              = UDim2.new(1,0,1,0)
	hpFill.BackgroundColor3  = Color3.fromRGB(0,255,0)
	hpFill.BorderSizePixel   = 0
	hpFill.Parent            = hpBg
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0,3)

	-- Tracer line (từ chân màn hình tới player) — tuỳ chọn thêm
	-- (bỏ qua để giữ gọn)

	espCache[player] = {
		highlight = hl,
		billboard = bb,
		nameL     = nameL,
		infoL     = infoL,
		hpFill    = hpFill,
	}
end

local function refreshESP(player)
	local d = espCache[player]
	if not d then return end

	local char = player.Character
	if not char then destroyESP(player) return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	-- Bật / tắt
	pcall(function() d.highlight.Enabled = espOn end)
	pcall(function() d.billboard.Enabled = espOn end)
	if not espOn then return end

	-- Cập nhật màu team (phòng đổi team giữa trận)
	local col = getTeamColor(player)
	local tag = getTeamTag(player)
	pcall(function()
		d.highlight.FillColor    = col
		d.highlight.OutlineColor = col
		d.nameL.TextColor3       = col
		d.nameL.Text             = player.Name .. " [" .. tag .. "]"
	end)

	-- HP bar
	pcall(function()
		local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		d.hpFill.Size = UDim2.new(r, 0, 1, 0)
		if r > 0.6 then
			d.hpFill.BackgroundColor3 = Color3.fromRGB(0,255,0)
		elseif r > 0.3 then
			d.hpFill.BackgroundColor3 = Color3.fromRGB(255,255,0)
		else
			d.hpFill.BackgroundColor3 = Color3.fromRGB(255,50,50)
		end
	end)

	-- Info text
	pcall(function()
		local hp  = math.floor(hum.Health)
		local max = math.floor(hum.MaxHealth)
		local dst = math.floor(getDistance(char))
		d.infoL.Text = string.format("HP %d/%d  |  %d m", hp, max, dst)
	end)
end

-- ─── Khởi tạo ESP cho tất cả player ───
local function initPlayerESP(player)
	if player == LocalPlayer then return end
	local conns = {}

	table.insert(conns, player.CharacterAdded:Connect(function()
		task.wait(1)
		buildESP(player)
	end))

	-- Nếu character đã tồn tại
	if player.Character then
		task.defer(function() buildESP(player) end)
	end

	espConns[player] = conns
end

for _, p in ipairs(Players:GetPlayers()) do
	initPlayerESP(p)
end

Players.PlayerAdded:Connect(initPlayerESP)

Players.PlayerRemoving:Connect(function(p)
	destroyESP(p)
	overlapping[p.Name] = nil
end)

-- ═══════════════════════════════════════════════
-- KEY BINDS
-- ═══════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Enum.KeyCode.F1 then
		autofireOn = not autofireOn
		refreshStatus()
		showNotif(
			autofireOn and "🔫 Auto-Fire: <b>ON</b>" or "🔫 Auto-Fire: <b>OFF</b>",
			autofireOn and Color3.fromRGB(80,255,80) or Color3.fromRGB(255,80,80)
		)

	elseif input.KeyCode == Enum.KeyCode.F2 then
		espOn = not espOn
		refreshStatus()
		showNotif(
			espOn and "👁 ESP: <b>ON</b>" or "👁 ESP: <b>OFF</b>",
			espOn and Color3.fromRGB(80,255,80) or Color3.fromRGB(255,80,80)
		)
		-- Ẩn/hiện ngay
		for _, d in pairs(espCache) do
			pcall(function() d.highlight.Enabled = espOn end)
			pcall(function() d.billboard.Enabled = espOn end)
		end
	end
end)

-- ═══════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	-- Ẩn notification
	if NotifLabel.Visible and tick() > notifHideTime then
		NotifLabel.Visible = false
	end

	-- Guard
	if not crosshairFrame or not crosshairFrame.Parent then return end
	if not crosshairFrame.Visible then return end

	Camera = workspace.CurrentCamera
	local bounds      = getCrosshairBounds()
	local enemyOnCH   = false   -- có địch đang nằm trên crosshair?

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end

		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")

		-- Nếu chưa có ESP cache thì build
		if char and not espCache[player] then
			buildESP(player)
		end

		if char and hum and hum.Health > 0 then
			-- Cập nhật ESP
			refreshESP(player)

			-- ─── Crosshair detection ───
			local points  = getCharScreenPoints(char)
			local hitPart = nil
			local best    = math.huge

			for _, pt in ipairs(points) do
				if pointInBounds(pt.x, pt.y, bounds) then
					local d = math.sqrt((pt.x - bounds.cx)^2 + (pt.y - bounds.cy)^2)
					if d < best then
						best    = d
						hitPart = pt.part
					end
				end
			end

			local enemy = isEnemy(player)

			if hitPart then
				-- ═══ CROSSHAIR TRÊN PLAYER ═══
				if not overlapping[player.Name] then
					overlapping[player.Name] = true

					local d3  = math.floor(getDistance(char))
					local hp  = math.floor(hum.Health)
					local mhp = math.floor(hum.MaxHealth)

					print("═══════════════════════════════════════")
					print(string.format("🎯 ON: %s [%s]  Part:%s  HP:%d/%d  Dist:%d",
						player.Name, enemy and "ENEMY" or "ALLY", hitPart, hp, mhp, d3))
					print("═══════════════════════════════════════")

					totalHits += 1
					currentTarget = player
					refreshStatus()

					showNotif(
						string.format(
							'🎯 <b>%s</b> [%s] | %s | ❤️%d/%d | 📏%dm',
							player.Name,
							enemy and '<font color="#FF4444">ENEMY</font>'
							       or '<font color="#44FF44">ALLY</font>',
							hitPart, hp, mhp, d3
						),
						enemy and Color3.fromRGB(255,60,60)
						      or  Color3.fromRGB(60,255,60)
					)
					HitCounter.Text = string.format(
						'<font color="#00FF88">Total Hits: %d</font>', totalHits
					)
				end

				-- ─── AUTO-FIRE (chỉ bắn địch) ───
				if enemy and autofireOn then
					enemyOnCH = true
					local now = tick()
					if now - lastFireTime >= FIRE_RATE then
						lastFireTime = now
						tapFire()
					end
				end

			else
				-- ═══ RỜI KHỎI PLAYER ═══
				if overlapping[player.Name] then
					overlapping[player.Name] = nil
					if currentTarget == player then
						currentTarget = nil
						refreshStatus()
					end
					if SHOW_OFF_MSG then
						print(string.format("   ❌ OFF: %s", player.Name))
						showNotif(
							string.format("❌ Rời <b>%s</b>", player.Name),
							Color3.fromRGB(150,150,150)
						)
					end
				end
			end
		else
			-- Dead / no char
			refreshESP(player)
			if overlapping[player.Name] then
				overlapping[player.Name] = nil
				if currentTarget == player then
					currentTarget = nil
					refreshStatus()
				end
			end
		end
	end

	-- Nếu không còn địch trên crosshair → clear target
	if not enemyOnCH and currentTarget and not overlapping[currentTarget.Name] then
		currentTarget = nil
		refreshStatus()
	end
end)

-- ═══════════════════════════════════════════════
-- RESPAWN HANDLER
-- ═══════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	Camera = workspace.CurrentCamera
	findFireButton()
end)

-- ═══════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════
print("═══════════════════════════════════════")
print("  🎯 Crosshair Tools v2.0")
print("  ✦ Crosshair Detection")
print("  ✦ Auto-Fire  [F1 toggle]")
print("  ✦ ESP         [F2 toggle]")
print("  Padding  : ±" .. PADDING .. "px")
print("  FireRate : " .. FIRE_RATE .. "s")
print("  Parts    : " .. #BODY_PARTS)
print("═══════════════════════════════════════")
