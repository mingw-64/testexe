--=============================================
-- AIM ASSIST - LocalScript (StarterPlayerScripts)
-- Built-in game feature for all players
--=============================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local LocalPlayer    = Players.LocalPlayer
local Camera         = workspace.CurrentCamera

--------- SETTINGS --------
local MAX_DISTANCE   = 200     -- max range (studs)
local SMOOTHNESS     = 0.5     -- 0 = instant snap, 1 = no movement (lerp factor)
----------------------------

local aimEnabled = false

-------------------------------------------------------
--                      UI
-------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AimAssistUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Name = "Toggle"
btn.AnchorPoint = Vector2.new(0, 0.5)
btn.Position = UDim2.new(0, 12, 0.5, 0)
btn.Size = UDim2.new(0, 140, 0, 50)
btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Text = "Aim Assist: OFF"
btn.AutoButtonColor = true
btn.Parent = gui

local corner = Instance.new("UICorner", btn)
corner.CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", btn)
stroke.Color = Color3.new(1, 1, 1)
stroke.Thickness = 2

-------------------------------------------------------
--                 TOGGLE LOGIC
-------------------------------------------------------
btn.MouseButton1Click:Connect(function()
	aimEnabled = not aimEnabled
	if aimEnabled then
		btn.Text = "Aim Assist: ON"
		btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
	else
		btn.Text = "Aim Assist: OFF"
		btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
end)

-------------------------------------------------------
--          FIND CLOSEST VISIBLE HEAD
-------------------------------------------------------
local function getClosestHead()
	local myChar = LocalPlayer.Character
	if not myChar then return nil end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local bestHead = nil
	local bestDist = MAX_DISTANCE

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end

		local char = player.Character
		if not char then continue end

		local head     = char:FindFirstChild("Head")
		local humanoid = char:FindFirstChildOfClass("Humanoid")

		if not head or not humanoid or humanoid.Health <= 0 then continue end

		local dist = (head.Position - myRoot.Position).Magnitude
		if dist > bestDist then continue end

		-- Visibility raycast (ignore local char + target char)
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {myChar, char}

		local origin    = Camera.CFrame.Position
		local direction = (head.Position - origin)
		local result    = workspace:Raycast(origin, direction, rayParams)

		if result == nil then          -- nothing blocking the view
			bestDist = dist
			bestHead = head
		end
	end

	return bestHead
end

-------------------------------------------------------
--               AIM EVERY FRAME
-------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not aimEnabled then return end

	local head = getClosestHead()
	if not head then return end

	local goal = CFrame.new(Camera.CFrame.Position, head.Position)

	-- Lerp for smooth tracking (set SMOOTHNESS = 0 for instant lock)
	Camera.CFrame = Camera.CFrame:Lerp(goal, 1 - SMOOTHNESS)
end)
