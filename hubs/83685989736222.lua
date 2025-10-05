-- Place ID: 83685989736222, Name: "+1 Stat point every second"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatUnlockGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.5, -150, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.Text = "+1 Stat / Unlock Zones"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = frame

-- Make frame draggable
local dragging, dragInput, dragStart, startPos
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- +1000 wins button
local statBtn = Instance.new("TextButton")
statBtn.Size = UDim2.new(0.9, 0, 0, 40)
statBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
statBtn.Text = "+1000 wins"
statBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
statBtn.TextColor3 = Color3.fromRGB(255,255,255)
statBtn.Font = Enum.Font.SourceSansBold
statBtn.TextSize = 18
statBtn.Parent = frame

statBtn.MouseButton1Click:Connect(function()
	local targetPart = Workspace:GetChildren()[385]
	if targetPart and targetPart:IsA("BasePart") then
		-- start 10 studs below the part
		root.CFrame = targetPart.CFrame - Vector3.new(0, 10, 0)
		-- tween up
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal = {CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)}
		local tween = TweenService:Create(root, tweenInfo, goal)
		tween:Play()
	else
		warn("Target part doesn't exist or isn't a BasePart!")
	end
end)

-- Unlock Zones button
local zoneBtn = Instance.new("TextButton")
zoneBtn.Size = UDim2.new(0.9, 0, 0, 40)
zoneBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
zoneBtn.Text = "Unlock All Zones"
zoneBtn.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
zoneBtn.TextColor3 = Color3.fromRGB(255,255,255)
zoneBtn.Font = Enum.Font.SourceSansBold
zoneBtn.TextSize = 18
zoneBtn.Parent = frame

zoneBtn.MouseButton1Click:Connect(function()
	for _, v in ipairs(Workspace:GetChildren()) do
		local name = v.Name
		if name == "CandyZone" 
			or name == "CaveZone" 
			or name == "CosmicZone" 
			or name == "DesertZone" 
			or name == "LavaZone" 
			or name == "OceanZone" then
			v:Destroy()
		end
	end
end)
