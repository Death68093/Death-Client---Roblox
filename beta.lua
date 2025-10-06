local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")
local cam = Workspace:FindFirstChildOfClass("Camera") or Workspace.CurrentCamera
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char.Humanoid
local hrp = char.HumanoidRootPart

local config = {
    version = "1.0.2",
    testing = true,
    prefix = ".",
    owner = 123456789,
    menuToggle = true,
    datafile = "DC_config",
    safeGames = true,
    mods = {
        movement = {
            fly = { enabled = false, speed = 100 },
            speed = { enabled = false, defaultSpeed = nil, speed = 32 },
            jump = { enabled = false, defaultPower = nil, defaultHeight = nil, power = 100, height = 50 },
        },
        visual = {
            esp = { enabled = false, box = true, name = true, health = true, distance = true, teamCheck = true, team = nil },
            chams = { enabled = false, color = Color3.new(1, 0, 0), transparency = 0.5 },
            tracers = { enabled = false, color = Color3.new(0, 1, 0), thickness = 1, teamCheck = true, team = nil },
            fov = { enabled = false, fov = 100, defaultFov = nil },
            wallhack = { enabled = false, transparency = 0.5 }
        },
        utility = {
            antiAfk = { enabled = true },
            noClip = { enabled = false },
            infiniteJump = { enabled = false },
            teleport = { enabled = false, target = nil, saves = {} },
        },
        combat = {
            aimbot = { enabled = false, fov = 30, smoothness = 0.5, teamCheck = true, targetPart = "Head", keybind = Enum.KeyCode.LeftAlt, target = nil },
            triggerbot = { enabled = false, delay = 0.1, teamCheck = true },
            autoClicker = { enabled = false, cps = 10, jitter = false, keybind = Enum.KeyCode.LeftControl },
        },
        fun = {
            fling = { enabled = false, target = nil, force = 1000 },
            spin = { enabled = false, speed = 100 },
            fakeLag = { enabled = false, amount = 0.1 },
        },
        misc = {
            rejoin = { enabled = false },
            serverHop = { enabled = false, visited = {} },
            fpsBoost = {
                enabled = false,
                settings = {
                    Rendering = {
                        GlobalShadows = false,
                        QualityLevel = 1,
                        TerrainDecoration = false,
                        WaterWaveSize = 0,
                        WaterReflectance = 0,
                        WaterTransparency = 0,
                        ShadowSoftness = 0,
                        AtmosphereDensity = 0,
                        Brightness = 1
                    },
                    Effects = {
                        ["BlurEffect.Enabled"] = false,
                        ["SunRaysEffect.Enabled"] = false,
                        ["ColorCorrectionEffect.Enabled"] = false,
                        ["BloomEffect.Enabled"] = false,
                        ["DepthOfFieldEffect.Enabled"] = false
                    },
                    Performance = {
                        ImageQualityLevel = 1,
                        GraphicsMode = "Performance",
                        FrameRateManagerMethod = "Fixed",
                        VsyncEnabled = false
                    }
                }
            }
        },
        hubs = { list = { { name = "ExampleHub", url = "https://example.com/hub.lua" } } },
        themes = {
            current = "Red",
            list = {
                Light = { background = Color3.fromRGB(255,255,255), text = Color3.fromRGB(0,0,0), accent = Color3.fromRGB(0,120,215) },
                Dark  = { background = Color3.fromRGB(30,30,30), text = Color3.fromRGB(255,255,255), accent = Color3.fromRGB(0,120,215) },
                Red   = { background = Color3.fromRGB(50,0,0), text = Color3.fromRGB(255,255,255), accent = Color3.fromRGB(255,0,0) },
            }
        },
        binds = {
            toggleMenu = Enum.KeyCode.RightControl,
            fly = Enum.KeyCode.F,
            speed = Enum.KeyCode.Z,
            jump = Enum.KeyCode.X,
            noclip = Enum.KeyCode.V,
            infiniteJump = Enum.KeyCode.H,
            aimbot = Enum.KeyCode.LeftAlt,
            autoClicker = Enum.KeyCode.LeftControl,
            fling = Enum.KeyCode.T,
            spin = Enum.KeyCode.G,
            rejoin = Enum.KeyCode.R,
            serverHop = Enum.KeyCode.K,
            fpsBoost = Enum.KeyCode.P,
            teleport = Enum.KeyCode.Y,
            esp = Enum.KeyCode.U,
            chams = Enum.KeyCode.I,
            saveTeleport = Enum.KeyCode.O,
            loadTeleport = Enum.KeyCode.L,
            wallhack = Enum.KeyCode.J,
            tracers = Enum.KeyCode.N,
            fov = Enum.KeyCode.M,
            triggerbot = Enum.KeyCode.B,
            silentAim = Enum.KeyCode.V,
            antiAfk = Enum.KeyCode.C,
        }
    },
    bans = {
        1537690962
    }
}

local mods = config.mods
local placeId = game.PlaceId

local loadingGui = Instance.new("ScreenGui")
loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loadingGui.DisplayOrder = 9999
loadingGui.Name = "DeathClientLoading"
loadingGui.ResetOnSpawn = false
loadingGui.Parent = playerGui

local bg = Instance.new("Frame", loadingGui)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

local title = Instance.new("TextLabel", bg)
title.Size = UDim2.new(1, 0, 0, 80)
title.Position = UDim2.new(0, 0, 0.4, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Death Client"
title.TextColor3 = Color3.fromRGB(255, 0, 0)
title.TextScaled = true

local subtitle = Instance.new("TextLabel", bg)
subtitle.Size = UDim2.new(1, 0, 0, 50)
subtitle.Position = UDim2.new(0, 0, 0.5, 0)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Loading Game..."
subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
subtitle.TextScaled = true

task.delay(3, function()
	for i = 1, 30 do
		bg.BackgroundTransparency = i / 30
		title.TextTransparency = i / 30
		subtitle.TextTransparency = i / 30
		task.wait(0.05)
	end
	if loadingGui and loadingGui.Parent then
		loadingGui:Destroy()
	end
end)

if not config.safeGames then
	for _, bannedId in ipairs(config.bans) do
		if placeId == bannedId then
			plr:Kick("Players have reported bans from this game. Rejoin with the 'NoSafe' version of the client to continue.")
		end
	end
end

local function notif(t, txt)
	StarterGui:SetCore("SendNotification", {
		Title = t;
		Text = txt;
		Duration = 3;
	})
end

local state = {
	cfg = {},
	adornments = { esp = {}, chams = {}, tracers = {} },
	flyBV = nil,
	prev = {},
	lastAutoClick = 0,
}

state.cfg = config
local function setDefaults()
	if hum and hrp and cam then
		mods.movement.speed.defaultSpeed = hum.WalkSpeed
		mods.movement.jump.defaultHeight = hum.JumpHeight
		mods.movement.jump.defaultPower = hum.JumpPower
		mods.visual.fov.defaultFov = cam.FieldOfView
	end
end

plr.CharacterAdded:Connect(function(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	hrp = c:WaitForChild("HumanoidRootPart")
	setDefaults()
end)

local lastTick = tick()



setDefaults()

local function safeGetAsync(url)
	local ok, res = pcall(function() return HttpService:GetAsync(url) end)
	if ok then
		return res
	end
	return nil
end

local function loadHubBtns(files)
	if not state then return end
	if not files then return end
	if not state.cfg then return end
	if not ScreenGui then
		ScreenGui = playerGui:FindFirstChild("DC_Menu")
	end
	if not ScreenGui then return end
	local main = ScreenGui:FindFirstChild("MainFrame")
	if not main then return end
	local content = main:FindFirstChild("Content")
	if not content then return end
	local theme = state.cfg.mods.themes and state.cfg.mods.themes.list[state.cfg.mods.themes.current]
				  or { background = Color3.fromRGB(20,20,20), text = Color3.fromRGB(255,255,255), accent = Color3.fromRGB(255,0,0) }
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("TextButton") and child.Name == "HubBtn" then
			child:Destroy()
		end
	end
	for _, file in ipairs(files) do
		if type(file) == "table" and file.type == "file" and file.name then
			local btn = Instance.new("TextButton")
			btn.Name = "HubBtn"
			btn.Size = UDim2.new(1, -10, 0, 30)
			btn.BackgroundColor3 = theme.background
			btn.TextColor3 = theme.text
			btn.Text = file.name
			btn.Parent = content
			btn.MouseButton1Click:Connect(function()
				btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
				btn.Text = file.name .. " (loading...)"
				local res = safeGetAsync(file.download_url)
				if not res then
					notif("Hub Load Failed", "Could not download " .. file.name)
					btn.BackgroundColor3 = theme.background
					btn.Text = file.name
					return
				end
				local code = res
				if type(loadstring) == "function" then
					local ok2, err = pcall(function()
						local fn = loadstring(code)
						if type(fn) == "function" then
							fn()
						end
					end)
					if not ok2 then
						notif("Hub Error", "Error running " .. file.name)
						btn.BackgroundColor3 = theme.background
						btn.Text = file.name
						return
					end
					notif("Hub Loaded", file.name .. " executed.")
				else
					table.insert(mods.hubs.list, { name = file.name, url = file.download_url })
					notif("Hub Saved", file.name .. " added to hubs list.")
				end
				btn.Text = file.name .. " (loaded)"
			end)
		end
	end
end

local function loadHubs()
	local hubs = 'https://api.github.com/repos/Death68093/Death-Client---Roblox/contents/hubs?ref=383ff1facba69636b7596ae69dfa35a504d73233'
	local data = safeGetAsync(hubs)
	if not data then return end
	local ok, files = pcall(function() return HttpService:JSONDecode(data) end)
	if ok and type(files) == "table" then
		loadHubBtns(files)
	end
end

local function applyChamsToModel(model)
	if not model or not model:IsA("Model") then return end
	local highlight = Instance.new("Highlight")
	highlight.Adornee = model
	highlight.Parent = workspace
	highlight.FillColor = mods.visual.chams.color or Color3.new(1,0,0)
	highlight.FillTransparency = mods.visual.chams.transparency or 0.5
	highlight.OutlineColor = Color3.new(0,0,0)
	highlight.OutlineTransparency = 0.5
	table.insert(state.adornments.chams, highlight)
	return highlight
end

local function createEspForPlayer(pl)
	if not pl or not pl.Character then return end
	local model = pl.Character
	local h = Instance.new("Highlight")
	h.Adornee = model
	h.Parent = workspace
	h.FillColor = mods.visual.chams.color or Color3.new(1,0,0)
	h.FillTransparency = mods.visual.chams.transparency or 0.5
	table.insert(state.adornments.esp, {player = pl, highlight = h})
	return h
end

Workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
		local otherPlayer = Players:GetPlayerFromCharacter(child)
		if mods.visual.chams.enabled then
			local fillColor = mods.visual.chams.color or Color3.new(1,0,0)
			if otherPlayer and otherPlayer.Team and plr.Team and otherPlayer.Team == plr.Team then
				fillColor = Color3.new(0,1,0)
			end
			local highlight = Instance.new("Highlight")
			highlight.Adornee = child
			highlight.Parent = workspace
			highlight.FillColor = fillColor
			highlight.FillTransparency = mods.visual.chams.transparency or 0.5
			highlight.OutlineColor = Color3.new(0,0,0)
			highlight.OutlineTransparency = 0.5
			table.insert(state.adornments.chams, highlight)
		end
	end
end)

local function createEsp()
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= plr and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
			createEspForPlayer(pl)
		end
	end
	Players.PlayerAdded:Connect(function(pl)
		pl.CharacterAdded:Connect(function()
			if mods.visual.esp.enabled then
				createEspForPlayer(pl)
			end
		end)
	end)
end

local function createMenu()
	local parent = playerGui
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "DC_Menu"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = parent
	local theme = state.cfg.mods.themes and state.cfg.mods.themes.list[state.cfg.mods.themes.current] or { background = Color3.fromRGB(20,20,20), text = Color3.fromRGB(255,255,255), accent = Color3.fromRGB(255,0,0) }
	local MainFrame = Instance.new("Frame", ScreenGui)
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 500, 0, 400)
	MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	MainFrame.BackgroundColor3 = theme.background
	MainFrame.Visible = state.cfg.menuToggle
	MainFrame.Active = true
	MainFrame.Draggable = true
	local Title = Instance.new("TextLabel", MainFrame)
	Title.Size = UDim2.new(1,0,0,40)
	Title.BackgroundTransparency = 1
	Title.Text = "Death's Control Menu v" .. state.cfg.version
	Title.Font = Enum.Font.SourceSansBold
	Title.TextSize = 20
	Title.TextColor3 = theme.accent
	local TabContainer = Instance.new("Frame", MainFrame)
	TabContainer.Size = UDim2.new(0,120,1,-40)
	TabContainer.Position = UDim2.new(0,0,0,40)
	TabContainer.BackgroundColor3 = theme.background
	local Content = Instance.new("Frame", MainFrame)
	Content.Name = "Content"
	Content.Size = UDim2.new(1,-120,1,-40)
	Content.Position = UDim2.new(0,120,0,40)
	Content.BackgroundColor3 = Color3.fromRGB(20,20,20)
	local TabLayout = Instance.new("UIListLayout", TabContainer)
	TabLayout.Padding = UDim.new(0,5)
	local ContentLayout = Instance.new("UIListLayout", Content)
	ContentLayout.Padding = UDim.new(0,5)
	local function clearContent()
		for _, v in ipairs(Content:GetChildren()) do
			if v:IsA("GuiObject") then v:Destroy() end
		end
	end
	local function createToggle(parent, name, settingTable)
		local Button = Instance.new("TextButton")
		Button.Parent = parent
		Button.Size = UDim2.new(1, -10, 0, 30)
		Button.BackgroundColor3 = theme.background
		Button.TextColor3 = theme.text
		Button.Text = name .. ": " .. tostring(settingTable.enabled)
		Button.MouseButton1Click:Connect(function()
			settingTable.enabled = not settingTable.enabled
			Button.Text = name .. ": " .. tostring(settingTable.enabled)
			Button.BackgroundColor3 = settingTable.enabled and Color3.fromRGB(0, 255, 0) or theme.background
		end)
	end
	local function openCategory(catName, catTable)
		clearContent()
		for featureName, feature in pairs(catTable) do
			if type(feature) == "table" and feature.enabled ~= nil then
				createToggle(Content, featureName, feature)
			end
		end
	end
	for categoryName, categoryTable in pairs(state.cfg.mods) do
		local Tab = Instance.new("TextButton", TabContainer)
		Tab.Size = UDim2.new(1,-10,0,30)
		Tab.BackgroundColor3 = theme.background
		Tab.TextColor3 = theme.text
		Tab.Text = categoryName
		Tab.MouseButton1Click:Connect(function()
			openCategory(categoryName, categoryTable)
		end)
	end
end

createMenu()
task.spawn(function() loadHubs() end)

local function safeTeleport(place)
	local ok, err = pcall(function() TeleportService:Teleport(place, plr) end)
end

RunService.RenderStepped:Connect(function()
	if not hum or not hrp then return end
	if mods.movement.speed.enabled then
		hum.WalkSpeed = mods.movement.speed.speed or hum.WalkSpeed
	else
		hum.WalkSpeed = mods.movement.speed.defaultSpeed or hum.WalkSpeed
	end
	if mods.movement.jump.enabled then
		hum.JumpHeight = mods.movement.jump.height or hum.JumpHeight
		hum.JumpPower = mods.movement.jump.power or hum.JumpPower
	else
		hum.JumpHeight = mods.movement.jump.defaultHeight or hum.JumpHeight
		hum.JumpPower = mods.movement.jump.defaultPower or hum.JumpPower
	end
	if mods.visual.fov.enabled and cam then
		cam.FieldOfView = mods.visual.fov.fov or cam.FieldOfView
	else
		if mods.visual.fov.defaultFov then
			cam.FieldOfView = mods.visual.fov.defaultFov
		end
	end
end)

if mods.utility.antiAfk.enabled then
	plr.Idled:Connect(function()
		VirtualUser:CaptureController()
		pcall(function() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
	end)
end

hum.Running:Connect(function(speed)
	if speed >= 0.1 then
		lastTick = tick()
	end
end)
hum.Jumping:Connect(function()
	lastTick = tick()
end)

task.spawn(function()
	while plr.Parent do
		local currentTime = tick()
		if (currentTime - lastTick) >= 60*20 then
			if config.safeGames then
				pcall(function() TeleportService:Teleport(placeId, plr) end)
			end
			lastTick = tick()
		end
		task.wait(5)
	end
end)

if mods.visual.esp.enabled then
	createEsp()
end

local aimbot = mods.combat.aimbot

local function isVisible(origin, targetPart)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {plr.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.IgnoreWater = true
	local dir = (targetPart.Position - origin)
	local ok, res = pcall(function() return Workspace:Raycast(origin, dir, params) end)
	if not ok or not res then return true end
	local hitModel = res.Instance and res.Instance:FindFirstAncestorOfClass("Model")
	return hitModel and hitModel == targetPart:FindFirstAncestorOfClass("Model")
end

local function getClosestTarget()
	if not cam then cam = Workspace.CurrentCamera end
	local origin = cam.CFrame.Position
	local best, bestAngle, bestDist = nil, math.huge, math.huge
	for _, pl in pairs(Players:GetPlayers()) do
		if pl ~= plr and pl.Character and pl.Character.Parent then
			local humanoid = pl.Character:FindFirstChild("Humanoid")
			local targetPart = pl.Character:FindFirstChild(aimbot.targetPart) or pl.Character:FindFirstChild("HumanoidRootPart")
			if humanoid and targetPart and humanoid.Health > 0 then
				if aimbot.teamCheck and pl.Team == plr.Team then
					continue
				end
				local toTarget = (targetPart.Position - origin)
				local dist = toTarget.Magnitude
				if aimbot.maxDistance and dist > aimbot.maxDistance then
					continue
				end
				local dir = cam.CFrame.LookVector
				local angle = math.acos( math.clamp( dir:Dot( toTarget.Unit ), -1, 1 ) ) * (180 / math.pi)
				if angle <= aimbot.fov and angle < bestAngle then
					if isVisible(origin, targetPart) then
						best = {player=pl, part=targetPart, dist=dist, angle=angle}
						bestAngle = angle
						bestDist = dist
					end
				end
			end
		end
	end
	return best
end

local holdKey = false
local function onInputBegan(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == aimbot.keybind then
		holdKey = true
	end
end
local function onInputEnded(input)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == aimbot.keybind then
		holdKey = false
	end
end
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

RunService.RenderStepped:Connect(function(dt)
	if not aimbot.enabled then return end
	if not plr.Character or not plr.Character:FindFirstChild("Humanoid") then return end
	if not cam then cam = Workspace.CurrentCamera end
	if holdKey then
		local best = getClosestTarget()
		if best and best.part then
			local targetPos = best.part.Position
			if aimbot.prediction and aimbot.prediction > 0 then
				local vel = best.part.AssemblyLinearVelocity or Vector3.new()
				targetPos = targetPos + vel * aimbot.prediction
			end
			local lookCFrame = CFrame.new(cam.CFrame.Position, targetPos)
			if aimbot.smoothness and aimbot.smoothness > 0 then
				local alpha = math.clamp(dt * (1 / aimbot.smoothness) * 60, 0, 1)
				cam.CFrame = cam.CFrame:Lerp(lookCFrame, alpha)
			else
				cam.CFrame = lookCFrame
			end
		end
	end
end)

notif("DeathClient", "Client Successfully Loaded")
