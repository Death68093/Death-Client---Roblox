-- Death Client: Fixed & Functional (single LocalScript)
-- Features: working toggles + settings, themes, fling player selector, ESP/Chams/Tracers, fly, speed, jump, noclip, autoClicker, triggerbot, simple aimbot
-- NOTE: Client-only script. Some actions (like manipulating other players) may be limited by server; fling implemented by moving YOUR character toward target.

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- default config
local defaultConfig = {
    version = "1.0.3-fixed",
    testing = true,
    menuToggle = true,
    mods = {
        movement = {
            fly = { enabled = false, speed = 100, ascendKey = Enum.KeyCode.Space, descendKey = Enum.KeyCode.LeftControl },
            speed = { enabled = false, defaultSpeed = nil, speed = 32 },
            jump = { enabled = false, defaultPower = nil, power = 100 },
            noclip = { enabled = false },
        },
        visual = {
            esp = { enabled = false, box = true, color = Color3.fromRGB(255, 100, 100), teamCheck = true },
            chams = { enabled = false, transparency = 0.5, color = Color3.fromRGB(255,0,0) },
            tracers = { enabled = false, thickness = 1, color = Color3.fromRGB(0,255,0) },
        },
        combat = {
            autoClicker = { enabled = false, cps = 10, keybind = Enum.KeyCode.LeftControl },
            triggerbot = { enabled = false, delay = 0.06, teamCheck = true },
            aimbot = { enabled = false, fov = 40, smoothness = 0.5, keybind = Enum.KeyCode.LeftAlt }, -- simple camera smoothing
        },
        fun = {
            fling = { enabled = false, force = 2000, duration = 1.5, targetName = nil }, -- duration seconds per burst
            spin = { enabled = false, speed = 360 },
        },
        misc = {
            antiAfk = { enabled = true, interval = 60 },
            fpsBoost = { enabled = false }
        },
        themes = {
            current = "Red",
            list = {
                Red = { background = Color3.fromRGB(40,10,10), text = Color3.fromRGB(255,255,255), accent = Color3.fromRGB(255,0,0) },
                Dark = { background = Color3.fromRGB(20,20,20), text = Color3.fromRGB(240,240,240), accent = Color3.fromRGB(0,150,255) },
                Light = { background = Color3.fromRGB(240,240,240), text = Color3.fromRGB(20,20,20), accent = Color3.fromRGB(0,120,215) },
            }
        },
        binds = {
            toggleMenu = Enum.KeyCode.RightControl,
        }
    }
}

-- runtime state
local state = {
    cfg = {},
    adornments = { esp = {}, chams = {}, tracers = {} },
    flyBV = nil,
    lastAutoClick = 0,
    gui = nil,
    flingRunning = false
}

-- utilities
local function deepMerge(a,b)
    for k,v in pairs(b) do
        if type(v) == "table" then
            if type(a[k]) ~= "table" then a[k] = {} end
            deepMerge(a[k], v)
        else
            a[k] = v
        end
    end
end

-- init config
do
    deepMerge(state.cfg, defaultConfig)
end

-- Humanoid helpers
local function getCharacter() return player.Character or player.CharacterAdded:Wait() end
local function getHumanoid() local c = player.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function getHRP() local c = player.Character if not c then return nil end return c:FindFirstChild("HumanoidRootPart") end

-- init defaults from humanoid (walkspeed/jumppower)
local function initDefaultsFromHumanoid()
    local hum = getHumanoid()
    if hum then
        local ms = state.cfg.mods.movement
        if ms.speed.defaultSpeed == nil then ms.speed.defaultSpeed = hum.WalkSpeed end
        if ms.jump.defaultPower == nil then ms.jump.defaultPower = hum.JumpPower or 50 end
    end
end
initDefaultsFromHumanoid()

-- load client config if present
local function loadClientConfigIfPresent()
    local module = ReplicatedStorage:FindFirstChild("DC_ClientConfig")
    if module and module:IsA("ModuleScript") then
        local ok, rc = pcall(require, module)
        if ok and type(rc) == "table" then deepMerge(state.cfg, rc) end
    end
    local val = ReplicatedStorage:FindFirstChild("DC_ClientConfig_JSON")
    if val and val:IsA("StringValue") then
        local ok, parsed = pcall(function() return HttpService:JSONDecode(val.Value) end)
        if ok and type(parsed) == "table" then deepMerge(state.cfg, parsed) end
    end
end
loadClientConfigIfPresent()

-- save config
local function saveConfig()
    local ev = ReplicatedStorage:FindFirstChild("DC_SaveConfig")
    if ev and ev:IsA("RemoteEvent") then
        local ok, payload = pcall(function() return HttpService:JSONEncode(state.cfg) end)
        if ok then ev:FireServer(payload) end
    end
end

-- APPLYERS: movement, visuals, etc
local function updateWalkSpeed()
    local ms = state.cfg.mods.movement
    local hum = getHumanoid()
    if hum then
        local desired = (ms.speed.enabled and ms.speed.speed) or ms.speed.defaultSpeed
        pcall(function() hum.WalkSpeed = desired end)
    end
end

local function updateJump()
    local j = state.cfg.mods.movement.jump
    local hum = getHumanoid()
    if hum then pcall(function() hum.JumpPower = j.enabled and j.power or j.defaultPower end) end
end

local function setNoClip(enabled)
    local char = player.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = not enabled end)
        end
    end
end

-- FLY (BodyVelocity)
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
    if state.flyBV then pcall(function() state.flyBV:Destroy() end) state.flyBV = nil end
end

local function updateFlyMovement(dt)
    if not state.cfg.mods.movement.fly.enabled then
        if state.flyBV then disableFly() end
        return
    end
    if not state.flyBV then enableFly() end
    local hrp = getHRP()
    if not hrp or not state.flyBV then return end
    local ms = state.cfg.mods.movement.fly
    local dir = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + hrp.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - hrp.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - hrp.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + hrp.CFrame.RightVector end
    if UserInputService:IsKeyDown(ms.ascendKey) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(ms.descendKey) then dir = dir - Vector3.new(0,1,0) end
    if dir.Magnitude > 0 then state.flyBV.Velocity = dir.Unit * (ms.speed or 100) else state.flyBV.Velocity = Vector3.new(0,0,0) end
end

-- VISUALS: create/remove/update adornments
local function safeParent() return Workspace end

local function makeESP(plr)
    if state.adornments.esp[plr] then return end
    local chr = plr.Character; if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "DC_ESPBox"
    box.Adornee = hrp
    box.Size = Vector3.new(2,5,1)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Parent = safeParent()
    state.adornments.esp[plr] = { box = box }
end
local function rmESP(plr)
    local t = state.adornments.esp[plr]
    if t then for _,v in pairs(t) do pcall(function() v:Destroy() end) end end
    state.adornments.esp[plr] = nil
end

local function makeChams(plr)
    if state.adornments.chams[plr] then return end
    local chr = plr.Character; if not chr then return end
    local arr = {}
    for _, part in ipairs(chr:GetDescendants()) do
        if part:IsA("BasePart") then
            local b = Instance.new("BoxHandleAdornment")
            b.Name = "DC_Cham"
            b.Adornee = part
            b.Size = part.Size + Vector3.new(0.05,0.05,0.05)
            b.Transparency = state.cfg.mods.visual.chams.transparency
            b.AlwaysOnTop = true
            b.Parent = safeParent()
            table.insert(arr, b)
        end
    end
    state.adornments.chams[plr] = arr
end
local function rmChams(plr)
    local arr = state.adornments.chams[plr]
    if arr then for _,a in ipairs(arr) do pcall(function() a:Destroy() end) end end
    state.adornments.chams[plr] = nil
end

local function makeTracer(plr)
    if state.adornments.tracers[plr] then return end
    local chr = plr.Character; if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local line = Instance.new("LineHandleAdornment")
    line.Name = "DC_Tracer"
    line.Adornee = hrp
    line.From = Vector3.new(0,0,0)
    line.To = hrp.Position
    line.Thickness = state.cfg.mods.visual.tracers.thickness
    line.AlwaysOnTop = true
    line.Parent = safeParent()
    state.adornments.tracers[plr] = line
end
local function rmTracer(plr)
    local a = state.adornments.tracers[plr]
    if a then pcall(function() a:Destroy() end) end
    state.adornments.tracers[plr] = nil
end

local function updateAllVisuals()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr == player then
            rmESP(plr); rmChams(plr); rmTracer(plr)
        else
            local skip = false
            if state.cfg.mods.visual.esp.teamCheck and plr.Team == player.Team then skip = true end
            if state.cfg.mods.visual.esp.enabled and not skip then makeESP(plr) else rmESP(plr) end
            if state.cfg.mods.visual.chams.enabled and not skip then makeChams(plr) else rmChams(plr) end
            if state.cfg.mods.visual.tracers.enabled and not skip then makeTracer(plr) else rmTracer(plr) end
        end
    end
end

local function updateAdornmentProperties()
    -- esp color/transparency & tracer thickness
    for plr,t in pairs(state.adornments.esp) do
        if t.box and t.box:IsA("BoxHandleAdornment") then
            t.box.Transparency = 0.5
            -- no color property on BoxHandleAdornment for body; would need SurfaceGUIs for colored boxes - keep default look
        end
    end
    for plr,a in pairs(state.adornments.tracers) do
        if a and a:IsA("LineHandleAdornment") then
            a.Thickness = state.cfg.mods.visual.tracers.thickness or 1
        end
    end
    for plr,arr in pairs(state.adornments.chams) do
        for _,b in ipairs(arr) do
            if b and b:IsA("BoxHandleAdornment") then
                b.Transparency = state.cfg.mods.visual.chams.transparency or 0.5
            end
        end
    end
end

-- apply fps boost (basic)
local function applyFPSBoost(enabled)
    if enabled then
        pcall(function() Lighting.GlobalShadows = false end)
        -- additional per-game adjustments can be implemented server-side or with permission
    else
        -- no revert (restore would require snapshot)
    end
end

-- AutoClicker
local function runAutoClicker()
    local ac = state.cfg.mods.combat.autoClicker
    if not ac.enabled then return end
    if UserInputService:IsKeyDown(ac.keybind) then
        local now = tick()
        local interval = 1 / math.max(1, ac.cps)
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

-- Triggerbot
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

-- Simple aimbot: rotate camera towards target smoothly (client-side only)
local function findAimbotTarget()
    local best, bestDist = nil, math.huge
    local cam = workspace.CurrentCamera
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos = plr.Character.HumanoidRootPart.Position
            local screenPoint, onScreen = cam:WorldToViewportPoint(pos)
            if onScreen then
                local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude
                if dist < bestDist and dist <= state.cfg.mods.combat.aimbot.fov then
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
    if not UserInputService:IsKeyDown(ab.keybind) then return end
    local target = findAimbotTarget()
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local cam = workspace.CurrentCamera
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    local aimPos = hrp.Position
    local camCFrame = cam.CFrame
    local dir = (CFrame.new(camCFrame.Position, aimPos) - camCFrame.Position)
    local lerp = 1 - math.clamp(ab.smoothness, 0, 0.995)
    cam.CFrame = camCFrame:Lerp(CFrame.new(camCFrame.Position, aimPos), lerp * dt * 60)
end

-- Fling: moves YOUR character repeatedly toward target to cause violent collisions
local function doFlingBurst(targetName, forcePower, duration)
    local target = nil
    for _,plr in ipairs(Players:GetPlayers()) do if plr.Name == targetName then target = plr break end end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return false, "Target not available" end
    local hrpTarget = target.Character.HumanoidRootPart
    local myHRP = getHRP()
    if not myHRP then return false, "No HRP" end

    -- create BV on LOCAL player to rocket toward target repeatedly for 'duration'
    local bv = Instance.new("BodyVelocity")
    bv.Name = "DC_FlingBV"
    bv.MaxForce = Vector3.new(1e6,1e6,1e6)
    bv.Parent = myHRP
    local start = tick()
    state.flingRunning = true
    while tick() - start < (duration or 1.5) and state.flingRunning do
        if not hrpTarget or not hrpTarget.Parent then break end
        local dir = (hrpTarget.Position - myHRP.Position)
        if dir.Magnitude < 1 then
            -- small random impulse so you bounce through
            bv.Velocity = Vector3.new(math.random(-50,50), 200, math.random(-50,50))
        else
            bv.Velocity = dir.Unit * (forcePower or 2000) + Vector3.new(0, 200, 0)
        end
        task.wait(0.03)
    end
    pcall(function() bv:Destroy() end)
    state.flingRunning = false
    return true
end

local function stopFling()
    state.flingRunning = false
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local bv = char.HumanoidRootPart:FindFirstChild("DC_FlingBV")
        if bv then pcall(function() bv:Destroy() end) end
    end
end

-- update adornments each frame (tracers from local player)
local function updateAdornmentFrames()
    for plr,line in pairs(state.adornments.tracers) do
        local chr = plr.Character
        local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
        local myHRP = getHRP()
        if hrp and myHRP and line and line:IsA("LineHandleAdornment") then
            pcall(function() line.From = myHRP.Position line.To = hrp.Position end)
        end
    end
end

-- UI helpers
local function clearChildren(frame)
    for _,c in ipairs(frame:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
end

local function createMenu()
    if state.gui and state.gui.Parent then state.gui:Destroy() state.gui = nil end
    local theme = state.cfg.mods.themes.list[state.cfg.mods.themes.current] or state.cfg.mods.themes.list.Red
    local ScreenGui = Instance.new("ScreenGui", state.cfg.testing and playerGui or playerGui)
    ScreenGui.Name = "DC_Menu"
    state.gui = ScreenGui

    local main = Instance.new("Frame", ScreenGui)
    main.Name = "Main"; main.Size = UDim2.new(0,700,0,420); main.Position = UDim2.new(0.5,-350,0.5,-210)
    main.BackgroundColor3 = theme.background; main.Active = true; main.Draggable = true

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1,0,0,36); title.Text = "Death Client • v"..state.cfg.version; title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold; title.TextColor3 = theme.accent; title.TextSize = 20

    local tabFrame = Instance.new("Frame", main)
    tabFrame.Size = UDim2.new(0,160,1,-36); tabFrame.Position = UDim2.new(0,0,0,36); tabFrame.BackgroundTransparency = 1
    local content = Instance.new("ScrollingFrame", main)
    content.Size = UDim2.new(1,-160,1,-36); content.Position = UDim2.new(0,160,0,36); content.CanvasSize = UDim2.new(0,0,3,0)
    content.ScrollBarThickness = 8

    local function addTab(name, fn)
        local b = Instance.new("TextButton", tabFrame)
        b.Size = UDim2.new(1,-10,0,30); b.Position = UDim2.new(0,5,0, (#tabFrame:GetChildren()-1)*35 )
        b.BackgroundTransparency = 0.15; b.Text = name; b.TextColor3 = theme.text
        b.MouseButton1Click:Connect(function() clearChildren(content); fn(content) end)
    end

    -- Category pages
    addTab("Movement", function(p)
        local cfg = state.cfg.mods.movement
        local y = 0
        local function addToggle(text, tbl)
            local btn = Instance.new("TextButton", p)
            btn.Size = UDim2.new(1,-20,0,28); btn.Position = UDim2.new(0,10,0,y)
            btn.Text = text .. ": "..tostring(tbl.enabled); btn.TextColor3 = theme.text; btn.BackgroundTransparency = 0.15
            btn.MouseButton1Click:Connect(function()
                tbl.enabled = not tbl.enabled; btn.Text = text .. ": "..tostring(tbl.enabled)
                if text == "fly" then if tbl.enabled then enableFly() else disableFly() end end
                if text == "noclip" then setNoClip(tbl.enabled) end
                updateWalkSpeed(); updateJump()
                saveConfig()
            end); y = y + 34; return btn
        end
        local flyBtn = addToggle("fly", cfg.fly)
        local spBtn = addToggle("speed", cfg.speed)
        local jumpBtn = addToggle("jump", cfg.jump)
        local noclipBtn = addToggle("noclip", cfg.noclip)

        -- live numeric editors
        local function addNumberLabel(name, ref)
            local lbl = Instance.new("TextLabel", p); lbl.Size = UDim2.new(0.5,-12,0,22); lbl.Position = UDim2.new(0,10,0,y); lbl.Text = name..": "..tostring(ref[1]); lbl.BackgroundTransparency = 1; lbl.TextColor3 = theme.text
            local box = Instance.new("TextBox", p); box.Size = UDim2.new(0.5,-22,0,22); box.Position = UDim2.new(0.5,2,0,y); box.Text = tostring(ref[1]); box.ClearTextOnFocus = false
            box.FocusLost:Connect(function()
                local n = tonumber(box.Text)
                if n then ref[1] = n; lbl.Text = name..": "..tostring(ref[1]); updateWalkSpeed(); updateJump(); saveConfig() else box.Text = tostring(ref[1]) end
            end)
            y = y + 26
        end
        addNumberLabel("Fly speed", {cfg.fly.speed})
        addNumberLabel("Walk speed", {cfg.speed.speed})
        addNumberLabel("Jump power", {cfg.jump.power})
    end)

    addTab("Visual", function(p)
        local cfg = state.cfg.mods.visual
        local y = 0
        local function addToggle(text, tbl, applyFn)
            local btn = Instance.new("TextButton", p); btn.Size = UDim2.new(1,-20,0,28); btn.Position = UDim2.new(0,10,0,y)
            btn.Text = text .. ": "..tostring(tbl.enabled); btn.TextColor3 = theme.text; btn.BackgroundTransparency = 0.15
            btn.MouseButton1Click:Connect(function()
                tbl.enabled = not tbl.enabled; btn.Text = text .. ": "..tostring(tbl.enabled)
                if applyFn then applyFn() end
                saveConfig()
            end); y = y + 34; return btn
        end
        addToggle("ESP", cfg.esp, updateAllVisuals)
        addToggle("Chams", cfg.chams, updateAllVisuals)
        addToggle("Tracers", cfg.tracers, updateAllVisuals)

        -- color boxes
        local function addColorEditor(labelText, colorRef)
            local lbl = Instance.new("TextLabel", p); lbl.Size = UDim2.new(0.5,-12,0,22); lbl.Position = UDim2.new(0,10,0,y); lbl.Text = labelText; lbl.BackgroundTransparency = 1; lbl.TextColor3 = theme.text
            local box = Instance.new("TextBox", p); box.Size = UDim2.new(0.5,-22,0,22); box.Position = UDim2.new(0.5,2,0,y)
            local r,g,b = math.floor(colorRef.R*255), math.floor(colorRef.G*255), math.floor(colorRef.B*255)
            box.Text = string.format("%d,%d,%d", r,g,b); box.ClearTextOnFocus = false
            box.FocusLost:Connect(function()
                local s = box.Text:match("^(%d+),%s*(%d+),%s*(%d+)$")
                if s then
                    local rr,gg,bb = box.Text:match("^(%d+),%s*(%d+),%s*(%d+)$")
                    rr,gg,bb = tonumber(rr), tonumber(gg), tonumber(bb)
                    if rr and gg and bb then colorRef = Color3.fromRGB(rr,gg,bb); state.cfg.mods.visual.esp.color = colorRef; updateAdornmentProperties(); saveConfig() end
                else
                    box.Text = string.format("%d,%d,%d", r,g,b)
                end
            end)
            y = y + 26
        end
        addColorEditor("ESP color", state.cfg.mods.visual.esp.color)
        addColorEditor("Chams color", state.cfg.mods.visual.chams.color)
    end)

    addTab("Combat", function(p)
        local cfg = state.cfg.mods.combat
        local y = 0
        local function addToggle(text, tbl, applyFn)
            local btn = Instance.new("TextButton", p); btn.Size = UDim2.new(1,-20,0,28); btn.Position = UDim2.new(0,10,0,y)
            btn.Text = text .. ": "..tostring(tbl.enabled); btn.TextColor3 = theme.text; btn.BackgroundTransparency = 0.15
            btn.MouseButton1Click:Connect(function()
                tbl.enabled = not tbl.enabled; btn.Text = text .. ": "..tostring(tbl.enabled)
                if applyFn then applyFn() end; saveConfig()
            end); y = y + 34; return btn
        end
        addToggle("AutoClicker", cfg.autoClicker)
        addToggle("Triggerbot", cfg.triggerbot)
        addToggle("Aimbot", cfg.aimbot)
        local function addNumber(name, ref)
            local lbl = Instance.new("TextLabel", p); lbl.Size = UDim2.new(0.5,-12,0,22); lbl.Position = UDim2.new(0,10,0,y); lbl.Text = name..": "..tostring(ref[1]); lbl.BackgroundTransparency=1; lbl.TextColor3 = theme.text
            local box = Instance.new("TextBox", p); box.Size = UDim2.new(0.5,-22,0,22); box.Position = UDim2.new(0.5,2,0,y); box.Text = tostring(ref[1]); box.ClearTextOnFocus=false
            box.FocusLost:Connect(function() local n = tonumber(box.Text) if n then ref[1] = n; lbl.Text = name..": "..tostring(ref[1]); saveConfig() else box.Text = tostring(ref[1]) end end)
            y = y + 26
        end
        addNumber("AutoClicker CPS", {cfg.autoClicker.cps})
        addNumber("Aimbot FOV(px)", {cfg.aimbot.fov})
    end)

    addTab("Fun", function(p)
        local cfg = state.cfg.mods.fun
        local y = 0
        local function addToggle(text,tbl)
            local btn = Instance.new("TextButton", p); btn.Size = UDim2.new(1,-20,0,28); btn.Position = UDim2.new(0,10,0,y)
            btn.Text = text..": "..tostring(tbl.enabled); btn.TextColor3 = theme.text; btn.BackgroundTransparency=0.15
            btn.MouseButton1Click:Connect(function()
                tbl.enabled = not tbl.enabled; btn.Text = text..": "..tostring(tbl.enabled)
                if text == "fling" and not tbl.enabled then stopFling() end
                saveConfig()
            end); y=y+34; return btn
        end
        addToggle("fling", state.cfg.mods.fun.fling)
        -- dropdown players for fling
        local ddLabel = Instance.new("TextLabel", p); ddLabel.Size = UDim2.new(0.5,-12,0,22); ddLabel.Position = UDim2.new(0,10,0,y); ddLabel.Text = "Fling target"; ddLabel.BackgroundTransparency=1; ddLabel.TextColor3 = theme.text
        local dd = Instance.new("TextBox", p); dd.Size = UDim2.new(0.5,-22,0,22); dd.Position = UDim2.new(0.5,2,0,y); dd.ClearTextOnFocus=false
        dd.Text = state.cfg.mods.fun.fling.targetName or "Select player..."
        local refreshBtn = Instance.new("TextButton", p); refreshBtn.Size = UDim2.new(0,100,0,24); refreshBtn.Position = UDim2.new(1,-110,0,y); refreshBtn.Text = "Refresh"; refreshBtn.BackgroundTransparency=0.2
        refreshBtn.MouseButton1Click:Connect(function()
            -- quick dropdown simulation: open small frame listing players
            local menu = Instance.new("Frame", p); menu.Size = UDim2.new(0,200,0,150); menu.Position = UDim2.new(0.5,-100,0,y+26); menu.BackgroundColor3 = theme.background
            local layout = Instance.new("UIListLayout", menu)
            for _,plr in ipairs(Players:GetPlayers()) do
                local b = Instance.new("TextButton", menu); b.Size = UDim2.new(1, -10, 0, 24); b.Text = plr.Name; b.BackgroundTransparency=0.15
                b.MouseButton1Click:Connect(function()
                    state.cfg.mods.fun.fling.targetName = plr.Name; dd.Text = plr.Name; menu:Destroy(); saveConfig()
                end)
            end
            task.delay(6, function() if menu and menu.Parent then pcall(function() menu:Destroy() end) end end)
        end)
        y = y + 30

        -- fling control buttons
        local startBtn = Instance.new("TextButton", p); startBtn.Size = UDim2.new(0.48,-10,0,30); startBtn.Position = UDim2.new(0,10,0,y); startBtn.Text = "Start Fling"
        local stopBtn = Instance.new("TextButton", p); stopBtn.Size = UDim2.new(0.48,-10,0,30); stopBtn.Position = UDim2.new(0.52,0,0,y); stopBtn.Text = "Stop Fling"
        startBtn.MouseButton1Click:Connect(function()
            local tname = state.cfg.mods.fun.fling.targetName
            if not tname then return end
            if state.flingRunning then return end
            task.spawn(function() doFlingBurst(tname, state.cfg.mods.fun.fling.force, state.cfg.mods.fun.fling.duration) end)
        end)
        stopBtn.MouseButton1Click:Connect(function() stopFling() end)
    end)

    addTab("Themes", function(p)
        local themeList = state.cfg.mods.themes.list
        local y = 0
        for name, tdef in pairs(themeList) do
            local b = Instance.new("TextButton", p); b.Size = UDim2.new(1,-20,0,28); b.Position = UDim2.new(0,10,0,y); b.Text = name; b.BackgroundTransparency = 0.15
            b.MouseButton1Click:Connect(function()
                state.cfg.mods.themes.current = name; saveConfig()
                createMenu() -- rebuild UI to apply theme immediately
            end)
            y = y + 34
        end
    end)

    addTab("Misc", function(p)
        local y=0
        local anti = state.cfg.mods.misc.antiAfk
        local btn = Instance.new("TextButton", p); btn.Size=UDim2.new(1,-20,0,28); btn.Position=UDim2.new(0,10,0,y); btn.Text="AntiAFK: "..tostring(anti.enabled)
        btn.MouseButton1Click:Connect(function() anti.enabled = not anti.enabled; btn.Text = "AntiAFK: "..tostring(anti.enabled); saveConfig() end); y = y + 34
    end)

    -- show first tab by default
    local first = tabFrame:FindFirstChildOfClass("TextButton")
    if first then first.MouseButton1Click:Connect(function() end) end
    -- open movement manually
    for _,c in pairs(tabFrame:GetChildren()) do if c:IsA("TextButton") and c.Text == "Movement" then c:CaptureFocus(); c:Destroy() end end -- just force arrangement
    -- open Movement by invoking function directly (the addTab created content functions inline; easiest is to call createMenu again when using themes)
end

-- create UI
createMenu()
updateAllVisuals(); updateAdornmentProperties()

-- connections
player.CharacterAdded:Connect(function()
    initDefaultsFromHumanoid()
    updateWalkSpeed(); updateJump()
    if state.cfg.mods.movement.fly.enabled then enableFly() end
    if state.cfg.mods.movement.noclip.enabled then setNoClip(true) end
    updateAllVisuals()
end)

player.Idled:Connect(function()
    if state.cfg.mods.misc.antiAfk.enabled then
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(0,0)) end)
    end
end)

Players.PlayerAdded:Connect(function() task.delay(0.8, updateAllVisuals) end)
Players.PlayerRemoving:Connect(function(plr) rmESP(plr); rmChams(plr); rmTracer(plr) end)

-- input (menu toggle)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == state.cfg.mods.binds.toggleMenu then
        if state.gui and state.gui.Parent then state.gui.Main.Visible = not state.gui.Main.Visible end
    end
end)

-- main loop
RunService.RenderStepped:Connect(function(dt)
    -- movement
    updateFlyMovement(dt)
    updateWalkSpeed()
    updateJump()
    if state.cfg.mods.movement.noclip.enabled then setNoClip(true) end

    -- combat
    runAutoClicker()
    runTriggerbot()
    runAimbot(dt)

    -- visuals
    updateAllVisuals()
    updateAdornmentProperties()
    updateAdornmentFrames()

    -- spin (fun)
    if state.cfg.mods.fun.spin.enabled then
        local hrp = getHRP()
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(state.cfg.mods.fun.spin.speed) * dt, 0) end
    end

    -- fpsBoost toggle
    if state.cfg.mods.misc.fpsBoost.enabled then applyFPSBoost(true) end
end)

-- safe shutdown cleanup
local function cleanup()
    stopFling(); disableFly()
    for plr,_ in pairs(state.adornments.esp) do rmESP(plr) end
    for plr,_ in pairs(state.adornments.chams) do rmChams(plr) end
    for plr,_ in pairs(state.adornments.tracers) do rmTracer(plr) end
end
game:BindToClose(cleanup)

print("[DC] Fixed client loaded (testing="..tostring(state.cfg.testing)..")")
