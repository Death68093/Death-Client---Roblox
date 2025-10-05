-- Death Client v1.0.2 (Cleaned, layout-fixed, minimizable)
-- Paste as a single LocalScript under StarterPlayerScripts (or similar).
-- NOTE: Some features are client-only; server-side persistence requires a RemoteEvent named "DC_SaveConfig" in ReplicatedStorage.

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================
-- Default config (exact user config)
-- ============================
local defaultConfig = {
    version = "1.0.2",
    testing = true,
    prefix = ".",
    owner = 123456789,
    menuToggle = true,
    datafile = "DC_config",
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
            fov = { enabled = false, radius = 100, color = Color3.new(1, 1, 1), thickness = 1 },
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
    }
}

-- ============================
-- State + helpers
-- ============================
local state = {
    cfg = {},
    adornments = { esp = {}, chams = {}, tracers = {} },
    flyBV = nil,
    lastAutoClick = 0,
    gui = nil,
    minimized = false,
    flingRunning = false,
    fakeLagTick = 0,
}

-- deep merge function
local function deepMerge(a, b)
    for k,v in pairs(b) do
        if type(v) == "table" then
            if type(a[k]) ~= "table" then a[k] = {} end
            deepMerge(a[k], v)
        else
            a[k] = v
        end
    end
end

deepMerge(state.cfg, defaultConfig)

-- Character helpers
local function getCharacter() return player.Character or player.CharacterAdded:Wait() end
local function getHumanoid()
    local c = player.Character
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = player.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

-- init defaults from humanoid
local function initDefaultsFromHumanoid()
    local hum = getHumanoid()
    if hum then
        local m = state.cfg.mods.movement
        if m.speed.defaultSpeed == nil then m.speed.defaultSpeed = hum.WalkSpeed end
        if m.jump.defaultPower == nil then m.jump.defaultPower = hum.JumpPower or 50 end
        if m.jump.defaultHeight == nil then m.jump.defaultHeight = hum.JumpHeight or 0 end
    end
end
pcall(initDefaultsFromHumanoid)

-- load client config if present
local function loadClientConfigIfPresent()
    local module = ReplicatedStorage:FindFirstChild("DC_ClientConfig")
    if module and module:IsA("ModuleScript") then
        local ok, remoteCfg = pcall(require, module)
        if ok and type(remoteCfg) == "table" then deepMerge(state.cfg, remoteCfg) end
    end
    local val = ReplicatedStorage:FindFirstChild("DC_ClientConfig_JSON")
    if val and val:IsA("StringValue") then
        local ok, parsed = pcall(function() return HttpService:JSONDecode(val.Value) end)
        if ok and type(parsed) == "table" then deepMerge(state.cfg, parsed) end
    end
end
pcall(loadClientConfigIfPresent)

-- save config via RemoteEvent if available
local function saveConfigToServer()
    local ev = ReplicatedStorage:FindFirstChild("DC_SaveConfig")
    if ev and ev:IsA("RemoteEvent") then
        local ok, payload = pcall(function() return HttpService:JSONEncode(state.cfg) end)
        if ok then pcall(function() ev:FireServer(payload) end) end
    end
end

-- ============================
-- Core mod implementations
-- ============================
local function updateWalkSpeed(desired)
    local hum = getHumanoid()
    if hum and desired then pcall(function() hum.WalkSpeed = desired end) end
end
local function updateJumpPower(desired)
    local hum = getHumanoid()
    if hum and desired then pcall(function() hum.JumpPower = desired end) end
end

local function setNoClip(enabled)
    local char = getCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = not enabled end)
            if state.cfg.mods.visual.wallhack.enabled then
                pcall(function() part.Transparency = state.cfg.mods.visual.wallhack.transparency end)
            end
        end
    end
end

local function enableFly()
    if state.flyBV and state.flyBV.Parent then return end
    local hrp = getHRP()
    if not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "DC_FlyBV"
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = hrp
    state.flyBV = bv
end
local function disableFly()
    if state.flyBV then pcall(function() state.flyBV:Destroy() end) end
    state.flyBV = nil
end
local function updateFlyMovement(dt)
    if not state.cfg.mods.movement.fly.enabled then
        if state.flyBV then disableFly() end
        return
    end
    if not state.flyBV then enableFly() end
    local hrp = getHRP()
    if not hrp or not state.flyBV then return end
    local dir = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + hrp.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - hrp.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - hrp.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + hrp.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
    local sp = state.cfg.mods.movement.fly.speed or 100
    if dir.Magnitude > 0 then state.flyBV.Velocity = dir.Unit * sp else state.flyBV.Velocity = Vector3.new(0,0,0) end
end

local function bindInfiniteJump()
    local hum = getHumanoid()
    if not hum then return end
    hum.Jumping:Connect(function(active)
        if state.cfg.mods.utility.infiniteJump.enabled and active then
            local h = getHumanoid()
            if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end
    end)
end
pcall(bindInfiniteJump)

local function applyFPSBoost(enabled)
    if enabled then
        local s = state.cfg.mods.misc.fpsBoost.settings.Rendering
        pcall(function()
            if Lighting then
                for k,v in pairs(s) do
                    if Lighting[k] ~= nil then pcall(function() Lighting[k] = v end) end
                end
            end
        end)
    end
end

-- ============================
-- Visuals: ESP / Chams / Tracers / Wallhack
-- ============================
local function safeAdornParent() return Workspace end

local function createESPFor(plr)
    if state.adornments.esp[plr] then return end
    if not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "DC_ESPBox"
    box.Adornee = hrp
    box.AlwaysOnTop = true
    box.Size = Vector3.new(2,5,1)
    box.Transparency = 0.6
    box.Parent = safeAdornParent()
    state.adornments.esp[plr] = { box = box }
end
local function removeESPFor(plr)
    local t = state.adornments.esp[plr]
    if t then for _,v in pairs(t) do pcall(function() v:Destroy() end) end end
    state.adornments.esp[plr] = nil
end

local function createChamsFor(plr)
    if state.adornments.chams[plr] then return end
    if not plr.Character then return end
    local arr = {}
    for _,part in ipairs(plr.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            local adorn = Instance.new("BoxHandleAdornment")
            adorn.Name = "DC_Cham"
            adorn.Adornee = part
            adorn.Size = part.Size + Vector3.new(0.04,0.04,0.04)
            adorn.AlwaysOnTop = true
            adorn.Transparency = state.cfg.mods.visual.chams.transparency or 0.5
            adorn.Parent = safeAdornParent()
            table.insert(arr, adorn)
        end
    end
    state.adornments.chams[plr] = arr
end
local function removeChamsFor(plr)
    local arr = state.adornments.chams[plr]
    if arr then for _,a in ipairs(arr) do pcall(function() a:Destroy() end) end end
    state.adornments.chams[plr] = nil
end

local function createTracerFor(plr)
    if state.adornments.tracers[plr] then return end
    if not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local line = Instance.new("LineHandleAdornment")
    line.Name = "DC_Tracer"
    line.Adornee = hrp
    line.From = Vector3.new(0,0,0)
    line.To = hrp.Position
    line.Thickness = state.cfg.mods.visual.tracers.thickness or 1
    line.AlwaysOnTop = true
    line.Parent = safeAdornParent()
    state.adornments.tracers[plr] = line
end
local function removeTracerFor(plr)
    local a = state.adornments.tracers[plr]
    if a then pcall(function() a:Destroy() end) end
    state.adornments.tracers[plr] = nil
end

local function applyWallhack(enabled)
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            for _,part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.LocalTransparencyModifier = enabled and state.cfg.mods.visual.wallhack.transparency or 0 end)
                end
            end
        end
    end
end

local function updateAllVisuals()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr == player then
            removeESPFor(plr); removeChamsFor(plr); removeTracerFor(plr)
        else
            local skip = false
            if state.cfg.mods.visual.esp.teamCheck and plr.Team == player.Team then skip = true end
            if state.cfg.mods.visual.esp.enabled and not skip then createESPFor(plr) else removeESPFor(plr) end
            if state.cfg.mods.visual.chams.enabled and not skip then createChamsFor(plr) else removeChamsFor(plr) end
            if state.cfg.mods.visual.tracers.enabled and not skip then createTracerFor(plr) else removeTracerFor(plr) end
        end
    end
    applyWallhack(state.cfg.mods.visual.wallhack.enabled)
end

local function updateAdornmentPositions()
    for plr,line in pairs(state.adornments.tracers) do
        if line and line:IsA("LineHandleAdornment") and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local myHRP = getHRP()
            if myHRP then
                pcall(function() line.From = myHRP.Position; line.To = plr.Character.HumanoidRootPart.Position end)
            end
        end
    end
end

-- ============================
-- Combat: autclicker, triggerbot, aimbot
-- ============================
local function runAutoClicker()
    local ac = state.cfg.mods.combat.autoClicker
    if not ac.enabled then return end
    if UserInputService:IsKeyDown(ac.keybind or Enum.KeyCode.LeftControl) then
        local now = tick()
        local interval = 1 / math.max(1, ac.cps or 1)
        if now - state.lastAutoClick >= interval then
            state.lastAutoClick = now
            pcall(function()
                VirtualUser:Button1Down(Vector2.new(0,0))
                task.wait(0.01)
                VirtualUser:Button1Up(Vector2.new(0,0))
            end)
        end
    end
end

local function runTriggerbot()
    local tb = state.cfg.mods.combat.triggerbot
    if not tb.enabled then return end
    local mouse = player:GetMouse()
    local target = mouse and mouse.Target
    if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") then
        local targetPlr = Players:GetPlayerFromCharacter(target.Parent)
        if targetPlr and targetPlr ~= player then
            if tb.teamCheck and targetPlr.Team == player.Team then return end
            task.spawn(function()
                task.wait(tb.delay or 0)
                pcall(function()
                    VirtualUser:Button1Down(Vector2.new(0,0))
                    task.wait(0.01)
                    VirtualUser:Button1Up(Vector2.new(0,0))
                end)
            end)
        end
    end
end

local function findAimbotTarget()
    local best, bestDist = nil, math.huge
    local cam = workspace.CurrentCamera
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild(state.cfg.mods.combat.aimbot.targetPart or "Head") then
            local pos = plr.Character[state.cfg.mods.combat.aimbot.targetPart or "Head"].Position
            local screenPoint, onScreen = cam:WorldToViewportPoint(pos)
            if onScreen then
                local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude
                if dist < bestDist and dist <= (state.cfg.mods.combat.aimbot.fov or 30) then
                    bestDist = dist; best = plr
                end
            end
        end
    end
    return best
end

local function runAimbot(dt)
    local ab = state.cfg.mods.combat.aimbot
    if not ab.enabled then return end
    if not UserInputService:IsKeyDown(ab.keybind or Enum.KeyCode.LeftAlt) then return end
    local targ = findAimbotTarget()
    if not targ or not targ.Character then return end
    local part = targ.Character:FindFirstChild(ab.targetPart or "Head")
    if not part then return end
    local cam = workspace.CurrentCamera
    local targetCFrame = CFrame.new(cam.CFrame.Position, part.Position)
    local lerpFactor = 1 - math.clamp(ab.smoothness or 0.5, 0, 0.99)
    cam.CFrame = cam.CFrame:Lerp(targetCFrame, lerpFactor * dt * 60)
end

-- ============================
-- Fun: fling, spin, fakeLag
-- ============================
local function doFlingBurst(targetName, forceAmt, duration)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return false, "target missing" end
    local myHRP = getHRP()
    if not myHRP then return false, "no HRP" end
    local tHRP = target.Character.HumanoidRootPart
    state.flingRunning = true
    local bv = Instance.new("BodyVelocity")
    bv.Name = "DC_FlingBV"
    bv.MaxForce = Vector3.new(1e6,1e6,1e6)
    bv.Parent = myHRP
    local tstart = tick()
    while tick() - tstart < (duration or 1.5) and state.flingRunning do
        if not tHRP or not tHRP.Parent then break end
        local dir = (tHRP.Position - myHRP.Position)
        if dir.Magnitude < 1 then
            bv.Velocity = Vector3.new(math.random(-50,50), 200, math.random(-50,50))
        else
            bv.Velocity = dir.Unit * (forceAmt or 1000) + Vector3.new(0, 200, 0)
        end
        task.wait(0.03)
    end
    pcall(function() bv:Destroy() end)
    state.flingRunning = false
    return true
end

local function stopFling()
    state.flingRunning = false
    local hrp = getHRP()
    if hrp then
        local bv = hrp:FindFirstChild("DC_FlingBV")
        if bv then pcall(function() bv:Destroy() end) end
    end
end

local function applySpin(dt)
    if not state.cfg.mods.fun.spin.enabled then return end
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(state.cfg.mods.fun.spin.speed or 100) * dt, 0)
    end
end

local function applyFakeLag(dt)
    if not state.cfg.mods.fun.fakeLag.enabled then return end
    state.fakeLagTick = state.fakeLagTick + dt
    if state.fakeLagTick >= (state.cfg.mods.fun.fakeLag.amount or 0.1) then
        state.fakeLagTick = 0
        local hrp = getHRP()
        if hrp then
            local orig = hrp.CFrame
            pcall(function() hrp.CFrame = orig * CFrame.new(0, 0, 0.01) end)
        end
    end
end

-- ============================
-- Misc: rejoin, serverHop, teleport saves
-- ============================
local function doRejoin()
    local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
    return ok, err
end

local function doServerHop()
    local ok, err = pcall(function() TeleportService:Teleport(game.PlaceId) end)
    return ok, err
end

local function saveTeleport(name)
    local tp = state.cfg.mods.utility.teleport
    if not tp then return end
    local hrp = getHRP()
    if not hrp then return end
    tp.saves[name] = hrp.Position
    saveConfigToServer()
end
local function loadTeleport(name)
    local tp = state.cfg.mods.utility.teleport
    if not tp then return end
    local pos = tp.saves[name]
    if not pos then return false end
    local hrp = getHRP()
    if hrp then pcall(function() hrp.CFrame = CFrame.new(pos) end) end
    return true
end

-- ============================
-- UI helpers (single definition)
-- ============================
local function uiInstance(name, class, parent, props)
    local inst = Instance.new(class)
    inst.Name = name
    if parent then inst.Parent = parent end
    if props then for k,v in pairs(props) do pcall(function() inst[k] = v end) end end
    return inst
end
local function makeRounded(frame, radius)
    local cr = Instance.new("UICorner")
    cr.CornerRadius = UDim.new(0, radius or 8)
    cr.Parent = frame
end

-- new createMenu() using UIListLayout/UIPadding for proper formatting
local function createMenu()
    if state.gui and state.gui.Parent then pcall(function() state.gui:Destroy() end) end

    local themes = state.cfg.mods.themes
    local theme = themes and themes.list and (themes.list[themes.current] or themes.list.Red) or { background = Color3.fromRGB(30,30,30), text = Color3.fromRGB(255,255,255), accent = Color3.fromRGB(255,0,0) }

    local sg = uiInstance("DC_ScreenGui","ScreenGui",(state.cfg.testing and playerGui) or playerGui,{ResetOnSpawn = false})
    state.gui = sg

    local main = uiInstance("DC_Main","Frame", sg, {Size = UDim2.new(0,600,0,420), Position = UDim2.new(0.5,-300,0.5,-210), BackgroundColor3 = theme.background, ZIndex = 2})
    makeRounded(main, 12)

    -- header row
    local header = uiInstance("Header","Frame", main, {Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1})
    local title = uiInstance("Title","TextLabel", header, {Size = UDim2.new(0.7,0,1,0), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1, Text = "Death Client • v"..tostring(state.cfg.version), TextColor3 = theme.text, Font = Enum.Font.SourceSansBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left})
    local controlFrame = uiInstance("Controls","Frame", header, {Size = UDim2.new(0.28, -16, 1, 0), Position = UDim2.new(0.72, 8, 0, 0), BackgroundTransparency = 1})
    local miniBtn = uiInstance("Minimize","TextButton", controlFrame, {Size = UDim2.new(0,36,0,28), Position = UDim2.new(1,-88,0,10), BackgroundColor3 = theme.accent, Text = "—", TextColor3 = theme.background, AutoButtonColor = true})
    local closeBtn = uiInstance("Close","TextButton", controlFrame, {Size = UDim2.new(0,36,0,28), Position = UDim2.new(1,-44,0,10), BackgroundColor3 = Color3.fromRGB(40,40,40), Text = "X", TextColor3 = theme.text, AutoButtonColor = true})
    makeRounded(miniBtn, 6); makeRounded(closeBtn, 6)

    -- left tab column
    local tabCol = uiInstance("TabCol","Frame", main, {Size = UDim2.new(0,160,1,-48), Position = UDim2.new(0,0,0,48), BackgroundTransparency = 1})
    local tabPadding = Instance.new("UIPadding", tabCol); tabPadding.PaddingLeft = UDim.new(0,10); tabPadding.PaddingTop = UDim.new(0,8)
    local tabLayout = Instance.new("UIListLayout", tabCol); tabLayout.Padding = UDim.new(0,8); tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- right content (scrolling)
    local content = uiInstance("Content","ScrollingFrame", main, {Size = UDim2.new(1,-160,1,-48), Position = UDim2.new(0,160,0,48), BackgroundColor3 = theme.background, ScrollBarThickness = 8})
    makeRounded(content, 8)
    local contentPadding = Instance.new("UIPadding", content); contentPadding.PaddingLeft = UDim.new(0,12); contentPadding.PaddingRight = UDim.new(0,12); contentPadding.PaddingTop = UDim.new(0,12)
    local contentLayout = Instance.new("UIListLayout", content); contentLayout.Padding = UDim.new(0,8); contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function updateCanvas()
        task.spawn(function()
            local nextY = 0
            for _,obj in ipairs(content:GetChildren()) do
                if obj:IsA("GuiObject") and obj ~= contentLayout and obj ~= contentPadding then
                    nextY = nextY + (obj.AbsoluteSize.Y + contentLayout.Padding.Offset)
                end
            end
            content.CanvasSize = UDim2.new(0,0,0, math.max(nextY + 12, content.AbsoluteSize.Y))
        end)
    end
    content:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
    content.ChildAdded:Connect(updateCanvas)
    content.ChildRemoved:Connect(updateCanvas)

    local function tabButton(name, onClick)
        local btn = uiInstance("Tab_"..name, "TextButton", tabCol, {Size = UDim2.new(1, -20, 0, 36), BackgroundTransparency = 0.12, Text = name, TextColor3 = theme.text, AutoButtonColor = true, Font = Enum.Font.SourceSans, TextSize = 15})
        makeRounded(btn, 8)
        btn.MouseButton1Click:Connect(function()
            onClick()
            local ok, t = pcall(function() return TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 0.05}) end)
            if ok and t then t:Play(); task.delay(0.12, function() pcall(function() TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 0.12}):Play() end) end) end
        end)
        return btn
    end

    local function clearContent()
        for _,c in ipairs(content:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    end

    local function addHeader(txt)
        local lbl = uiInstance("Hdr","TextLabel", content, {Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, Text = txt, TextColor3 = theme.accent, Font = Enum.Font.SourceSansBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
        return lbl
    end
    local function addToggle(label, tbl, applyFn)
        local frame = uiInstance("Line","Frame", content, {Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
        local lbl = uiInstance("Lbl","TextLabel", frame, {Size = UDim2.new(0.68,0,1,0), Position = UDim2.new(0,6,0,0), BackgroundTransparency = 1, Text = label, TextColor3 = theme.text, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
        local btn = uiInstance("Btn","TextButton", frame, {Size = UDim2.new(0,92,0,28), Position = UDim2.new(1,-100,0,4), BackgroundColor3 = tbl.enabled and theme.accent or Color3.fromRGB(60,60,60), Text = tostring(tbl.enabled), TextColor3 = tbl.enabled and theme.background or theme.text, AutoButtonColor = true})
        makeRounded(btn, 6)
        btn.MouseButton1Click:Connect(function()
            tbl.enabled = not tbl.enabled
            btn.BackgroundColor3 = tbl.enabled and theme.accent or Color3.fromRGB(60,60,60)
            btn.Text = tostring(tbl.enabled)
            if applyFn then pcall(applyFn, tbl) end
            pcall(saveConfigToServer)
        end)
        return frame
    end
    local function addNumber(label, tbl, key, onChange)
        local frame = uiInstance("Num","Frame", content, {Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1})
        local lbl = uiInstance("Lbl","TextLabel", frame, {Size = UDim2.new(0.5,0,1,0), Position = UDim2.new(0,6,0,0), BackgroundTransparency = 1, Text = label, TextColor3 = theme.text, Font = Enum.Font.SourceSans, TextSize = 14})
        local box = uiInstance("Box","TextBox", frame, {Size = UDim2.new(0.45, -12, 1, 0), Position = UDim2.new(0.5, 6, 0, 0), Text = tostring(tbl[key] or ""), ClearTextOnFocus = false, TextColor3 = theme.text})
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then tbl[key] = n; if onChange then pcall(onChange) end pcall(saveConfigToServer) else box.Text = tostring(tbl[key]) end
        end)
        return frame
    end
    local function addButton(label, fn)
        local b = uiInstance("ActBtn","TextButton", content, {Size = UDim2.new(1,0,0,34), BackgroundColor3 = theme.accent, Text = label, TextColor3 = theme.background, Font = Enum.Font.SourceSans, TextSize = 14})
        makeRounded(b, 8)
        b.MouseButton1Click:Connect(function() pcall(fn) end)
        return b
    end

    -- Pages
    local function pageMovement()
        clearContent()
        addHeader("Movement")
        addToggle("Fly", state.cfg.mods.movement.fly, function(tbl) if tbl.enabled then enableFly() else disableFly() end end)
        addToggle("Speed", state.cfg.mods.movement.speed, function() updateWalkSpeed(state.cfg.mods.movement.speed.enabled and state.cfg.mods.movement.speed.speed or state.cfg.mods.movement.speed.defaultSpeed) end)
        addToggle("Jump", state.cfg.mods.movement.jump, function() updateJumpPower(state.cfg.mods.movement.jump.enabled and state.cfg.mods.movement.jump.power or state.cfg.mods.movement.jump.defaultPower) end)
        addNumber("Fly speed", state.cfg.mods.movement.fly, "speed", function() end)
        addNumber("Walk speed", state.cfg.mods.movement.speed, "speed", function() updateWalkSpeed(state.cfg.mods.movement.speed.speed) end)
        addNumber("Jump power", state.cfg.mods.movement.jump, "power", function() updateJumpPower(state.cfg.mods.movement.jump.power) end)
    end

    local function pageVisual()
        clearContent()
        addHeader("Visuals")
        addToggle("ESP", state.cfg.mods.visual.esp, function() updateAllVisuals() end)
        addToggle("Chams", state.cfg.mods.visual.chams, function() updateAllVisuals() end)
        addToggle("Tracers", state.cfg.mods.visual.tracers, function() updateAllVisuals() end)
        addToggle("Wallhack", state.cfg.mods.visual.wallhack, function() applyWallhack(state.cfg.mods.visual.wallhack.enabled) end)
        addNumber("Tracer thickness", state.cfg.mods.visual.tracers, "thickness", function() updateAllVisuals() end)
    end

    local function pageCombat()
        clearContent()
        addHeader("Combat")
        addToggle("Aimbot", state.cfg.mods.combat.aimbot, function() end)
        addToggle("Triggerbot", state.cfg.mods.combat.triggerbot, function() end)
        addToggle("AutoClicker", state.cfg.mods.combat.autoClicker, function() end)
        addNumber("Aimbot FOV", state.cfg.mods.combat.aimbot, "fov", function() end)
        addNumber("AutoClicker CPS", state.cfg.mods.combat.autoClicker, "cps", function() end)
    end

    local function pageFun()
        clearContent()
        addHeader("Fun")
        addToggle("Fling", state.cfg.mods.fun.fling, function() end)
        addNumber("Fling force", state.cfg.mods.fun.fling, "force", function() end)
        addToggle("Spin", state.cfg.mods.fun.spin, function() end)
        addNumber("Spin speed", state.cfg.mods.fun.spin, "speed", function() end)
        addToggle("FakeLag", state.cfg.mods.fun.fakeLag, function() end)

        -- fling controls (simple)
        addButton("Start fling at target name (set using config)", function()
            local t = state.cfg.mods.fun.fling.target
            if t and t ~= "" then task.spawn(function() doFlingBurst(t, state.cfg.mods.fun.fling.force, 2) end) end
        end)
        addButton("Stop fling", stopFling)
    end

    local function pageUtility()
        clearContent()
        addHeader("Utility")
        addToggle("AntiAFK", state.cfg.mods.utility.antiAfk, function() end)
        addToggle("NoClip", state.cfg.mods.utility.noClip, function() setNoClip(state.cfg.mods.utility.noClip.enabled) end)
        addToggle("Infinite Jump", state.cfg.mods.utility.infiniteJump, function() end)
        addButton("Save Position -> slot1", function() saveTeleport("slot1") end)
        addButton("Load slot1", function() loadTeleport("slot1") end)
    end

    local function pageMisc()
        clearContent()
        addHeader("Misc")
        addToggle("FPS Boost", state.cfg.mods.misc.fpsBoost, function(tbl) applyFPSBoost(tbl.enabled) end)
        addToggle("Rejoin (auto)", state.cfg.mods.misc.rejoin, function() end)
        addToggle("ServerHop (auto)", state.cfg.mods.misc.serverHop, function() end)
        addButton("Rejoin Now", function() doRejoin() end)
        addButton("ServerHop (attempt)", function() doServerHop() end)
    end

    local function pageThemes()
        clearContent()
        addHeader("Themes")
        for name,_ in pairs(state.cfg.mods.themes.list) do
            local b = uiInstance("Theme"..name,"TextButton", content, {Size = UDim2.new(1,0,0,34), Text = name, BackgroundTransparency = 0.12, TextColor3 = theme.text})
            makeRounded(b,8)
            b.MouseButton1Click:Connect(function()
                state.cfg.mods.themes.current = name
                saveConfigToServer()
                createMenu() -- rebuild to apply theme
            end)
        end
    end

    local tabs = {
        {"Movement", pageMovement},
        {"Visual", pageVisual},
        {"Combat", pageCombat},
        {"Fun", pageFun},
        {"Utility", pageUtility},
        {"Misc", pageMisc},
        {"Themes", pageThemes},
    }
    for i,t in ipairs(tabs) do
        local btn = tabButton(t[1], t[2])
        btn.LayoutOrder = i
    end

    miniBtn.MouseButton1Click:Connect(function()
        if state.minimized then
            state.minimized = false
            main.Size = UDim2.new(0,600,0,420)
            content.Visible = true
        else
            state.minimized = true
            content.Visible = false
            main.Size = UDim2.new(0,600,0,64)
        end
    end)
    closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

    pageMovement()
    task.defer(function() updateCanvas() end)
end

-- initial GUI + visuals
createMenu()
updateAllVisuals()

-- ============================
-- Events + render loop
-- ============================
player.CharacterAdded:Connect(function()
    initDefaultsFromHumanoid()
    updateWalkSpeed(state.cfg.mods.movement.speed.enabled and state.cfg.mods.movement.speed.speed or state.cfg.mods.movement.speed.defaultSpeed)
    updateJumpPower(state.cfg.mods.movement.jump.enabled and state.cfg.mods.movement.jump.power or state.cfg.mods.movement.jump.defaultPower)
    if state.cfg.mods.movement.fly.enabled then enableFly() end
    if state.cfg.mods.utility.noClip.enabled then setNoClip(true) end
    updateAllVisuals()
end)

player.Idled:Connect(function()
    if state.cfg.mods.utility.antiAfk.enabled then
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(0,0)) end)
    end
end)

Players.PlayerAdded:Connect(function() task.delay(1, updateAllVisuals) end)
Players.PlayerRemoving:Connect(function(plr) removeESPFor(plr); removeChamsFor(plr); removeTracerFor(plr) end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == state.cfg.mods.binds.toggleMenu then
        if state.gui and state.gui.Parent then
            local main = state.gui:FindFirstChild("DC_Main")
            if main then main.Visible = not main.Visible end
        end
        return
    end

    local binds = state.cfg.mods.binds
    local mods = state.cfg.mods
    for k,v in pairs(binds) do
        if type(v) == "EnumItem" and input.KeyCode == v then
            for catName,cat in pairs(mods) do
                for featName,feat in pairs(cat) do
                    if featName == k and type(feat) == "table" and feat.enabled ~= nil then
                        feat.enabled = not feat.enabled
                        if featName == "fly" then
                            if feat.enabled then enableFly() else disableFly() end
                        elseif featName == "speed" then
                            updateWalkSpeed(feat.enabled and feat.speed or feat.defaultSpeed)
                        elseif featName == "jump" then
                            updateJumpPower(feat.enabled and feat.power or feat.defaultPower)
                        elseif featName == "noClip" then
                            setNoClip(feat.enabled)
                        elseif featName == "fling" then
                            if not feat.enabled then stopFling() end
                        end
                        saveConfigToServer()
                    end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    updateFlyMovement(dt)
    updateWalkSpeed(state.cfg.mods.movement.speed.enabled and state.cfg.mods.movement.speed.speed or state.cfg.mods.movement.speed.defaultSpeed)
    updateJumpPower(state.cfg.mods.movement.jump.enabled and state.cfg.mods.movement.jump.power or state.cfg.mods.movement.jump.defaultPower)
    if state.cfg.mods.utility.noClip.enabled then setNoClip(true) end

    updateAllVisuals()
    updateAdornmentPositions()

    runAutoClicker()
    runTriggerbot()
    runAimbot(dt)

    applySpin(dt)
    applyFakeLag(dt)

    if state.cfg.mods.misc.fpsBoost.enabled then applyFPSBoost(true) end

    if state.cfg.mods.misc.rejoin.enabled then state.cfg.mods.misc.rejoin.enabled = false; doRejoin() end
    if state.cfg.mods.misc.serverHop.enabled then state.cfg.mods.misc.serverHop.enabled = false; doServerHop() end
end)

local function cleanup()
    stopFling()
    disableFly()
    for plr,_ in pairs(state.adornments.esp) do removeESPFor(plr) end
    for plr,_ in pairs(state.adornments.chams) do removeChamsFor(plr) end
    for plr,_ in pairs(state.adornments.tracers) do removeTracerFor(plr) end
end
game:BindToClose(cleanup)

print("[DC] Full client loaded (testing="..tostring(state.cfg.testing)..")")
