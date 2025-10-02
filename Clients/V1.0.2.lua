-- Death's Control Menu (refactor)
-- Single-file LocalScript (client)
-- Key improvements:
-- 1) No event/instance creation inside RenderStepped
-- 2) State-change only updates (debounced updates)
-- 3) Adornments cached and reused
-- 4) Fly uses BodyVelocity (clean enable/disable)
-- 5) Config deep-merge; client avoids direct DataStore usage (use RemoteEvent on server)
-- 6) UI placed into PlayerGui when testing; CoreGui otherwise (subject to client permissions)

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

-- Default config (same structure as yours, trimmed where appropriate)
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
            speed = { enabled = false, defaultSpeed = nil, speed = 32 }, -- defaultSpeed set later
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

-- runtime state
local state = {
    cfg = {},
    adornments = { esp = {}, chams = {}, tracers = {} }, -- caches keyed by player
    flyBV = nil, -- BodyVelocity instance if flying
    prev = {}, -- previous toggle states for debounced updates
    lastAutoClick = 0,
}

-- utility: deep-merge table b into a (non-destructive for a)
local function deepMerge(a, b)
    for k, v in pairs(b) do
        if type(v) == "table" then
            if type(a[k]) ~= "table" then a[k] = {} end
            deepMerge(a[k], v)
        else
            a[k] = v
        end
    end
end

-- initialize config: merge defaultConfig with any client-side saved config exposed via ReplicatedStorage
do
    state.cfg = {}
    deepMerge(state.cfg, defaultConfig)

    -- copy some defaults that depend on local humanoid (set later when char exists)
end

-- Character & Humanoid helpers
local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end
local function getHumanoid()
    local c = getCharacter()
    return c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = getCharacter()
    return c:FindFirstChild("HumanoidRootPart")
end

-- set defaultSpeed/defaultPower from the loaded character/humanoid
local function initDefaultsFromHumanoid()
    local hum = getHumanoid()
    if hum then
        if state.cfg.mods.movement.speed.defaultSpeed == nil then
            state.cfg.mods.movement.speed.defaultSpeed = hum.WalkSpeed
        end
        if state.cfg.mods.movement.jump.defaultPower == nil then
            state.cfg.mods.movement.jump.defaultPower = hum.JumpPower or 50
        end
        -- JumpHeight may not exist in all versions; keep defaultHeight if present
        if state.cfg.mods.movement.jump.defaultHeight == nil then
            state.cfg.mods.movement.jump.defaultHeight = hum.JumpHeight or 0
        end
    end
end

-- Attempt to load client-side saved config from ReplicatedStorage (ModuleScript or Value) - safer than DataStore on client
local function loadClientConfigIfPresent()
    local module = ReplicatedStorage:FindFirstChild("DC_ClientConfig")
    if module and module:IsA("ModuleScript") then
        local ok, remoteCfg = pcall(require, module)
        if ok and type(remoteCfg) == "table" then
            deepMerge(state.cfg, remoteCfg)
        end
    else
        -- Optionally, look for a Value object with JSON string
        local val = ReplicatedStorage:FindFirstChild("DC_ClientConfig_JSON")
        if val and val:IsA("StringValue") then
            local ok, parsed = pcall(function() return HttpService:JSONDecode(val.Value) end)
            if ok and type(parsed) == "table" then
                deepMerge(state.cfg, parsed)
            end
        end
    end
end

-- Save config client-side: prefer sending to server RemoteEvent for persistent storage
local function saveConfigToServer()
    local ev = ReplicatedStorage:FindFirstChild("DC_SaveConfig")
    if ev and ev:IsA("RemoteEvent") then
        local ok, payload = pcall(function() return HttpService:JSONEncode(state.cfg) end)
        if ok then
            ev:FireServer(payload)
        end
    else
        -- No server saver available; do nothing (client cannot use DataStore safely)
        -- If you want to persist between sessions for testing, create ReplicatedStorage objects from the server
    end
end

-- UI creation (simple, same layout; parent respects testing flag)
local ScreenGui
local function createMenu()
    local parent
    if state.cfg.testing then
        parent = playerGui
    else
        -- CoreGui parenting may be restricted (roblox security). Try CoreGui but fallback to PlayerGui.
        parent = playerGui
        -- If you want CoreGui, add additional checks and permission handling on the server side.
    end

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
        local Button = Instance.new("TextButton", parent)
        Button.Size = UDim2.new(1,-10,0,30)
        Button.BackgroundColor3 = theme.background
        Button.TextColor3 = theme.text
        Button.Text = name .. ": " .. tostring(settingTable.enabled)
        Button.MouseButton1Click:Connect(function()
            settingTable.enabled = not settingTable.enabled
            Button.Text = name .. ": " .. tostring(settingTable.enabled)
            -- apply immediate effect on toggle
            applyToggleEffects(name, settingTable)
        end)
    end

    -- openCategory needs to reference the config subtable; we'll create after function is declared
    local function openCategory(catName, catTable)
        clearContent()
        for featureName, feature in pairs(catTable) do
            if type(feature) == "table" and feature.enabled ~= nil then
                createToggle(Content, featureName, feature)
            end
        end
    end

    -- create tabs
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

-- ------------ EFFECT APPLICATION / STATE MANAGEMENT ---------------

-- A simple dispatcher to apply changes when a toggle is flipped
function applyToggleEffects(featureName, featureTable)
    -- Movement toggles
    if featureName == "fly" then
        if featureTable.enabled then enableFly() else disableFly() end
    elseif featureName == "speed" then
        updateWalkSpeed(featureTable.enabled and featureTable.speed or featureTable.defaultSpeed)
    elseif featureName == "jump" then
        updateJumpSettings(featureTable.enabled and featureTable.power or featureTable.defaultPower)
    elseif featureName == "noClip" then
        setNoClip(featureTable.enabled)
    elseif featureName == "esp" or featureName == "chams" or featureName == "tracers" then
        updateAllVisuals() -- create/remove adornments as needed
    elseif featureName == "fpsBoost" then
        applyFPSBoost(featureTable.enabled)
    end
end

-- Debounced/no-op helpers
local function safeSpawn(fn) task.spawn(fn) end

-- WALK SPEED / JUMP updates (apply only when changed)
function updateWalkSpeed(value)
    local hum = getHumanoid()
    if hum and value then
        hum.WalkSpeed = value
    end
end

function updateJumpSettings(power)
    local hum = getHumanoid()
    if hum and power then
        -- keep JumpPower only; JumpHeight is inconsistent across Rbx versions
        hum.JumpPower = power
    end
end

-- NOCLIP (apply on toggle)
local function setNoClip(enabled)
    local char = getCharacter()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = not enabled end)
        end
    end
end

-- FLY using BodyVelocity (smoother and avoids constant Velocity writes)
function enableFly()
    if state.flyBV and state.flyBV.Parent then return end
    local hrp = getHRP()
    if not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "DC_FlyBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = hrp
    state.flyBV = bv
end

function disableFly()
    if state.flyBV then
        pcall(function() state.flyBV:Destroy() end)
        state.flyBV = nil
    end
end

-- VISUALS (ESP / Chams / Tracers) - cache per player
local function createESPForPlayer(plr)
    if state.adornments.esp[plr] then return end
    local character = plr.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- BoxHandleAdornment for body
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "DC_ESPBox"
    box.Adornee = hrp
    box.Size = Vector3.new(2,5,1)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Parent = Workspace -- adornments render when parented to Workspace

    state.adornments.esp[plr] = { box = box }
end

local function removeESPForPlayer(plr)
    local t = state.adornments.esp[plr]
    if t and t.box then pcall(function() t.box:Destroy() end) end
    state.adornments.esp[plr] = nil
end

local function createChamsForPlayer(plr)
    if state.adornments.chams[plr] then return end
    local character = plr.Character
    if not character then return end
    local chamTable = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local adorn = Instance.new("BoxHandleAdornment")
            adorn.Name = "DC_Cham"
            adorn.Adornee = part
            adorn.Size = part.Size + Vector3.new(0.05,0.05,0.05)
            adorn.Transparency = state.cfg.mods.visual.chams.transparency
            adorn.AlwaysOnTop = true
            adorn.Parent = Workspace
            table.insert(chamTable, adorn)
        end
    end
    state.adornments.chams[plr] = chamTable
end

local function removeChamsForPlayer(plr)
    local arr = state.adornments.chams[plr]
    if arr then
        for _, a in ipairs(arr) do pcall(function() a:Destroy() end) end
    end
    state.adornments.chams[plr] = nil
end

local function createTracerForPlayer(plr)
    if state.adornments.tracers[plr] then return end
    local character = plr.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local line = Instance.new("LineHandleAdornment")
    line.Name = "DC_Tracer"
    line.Adornee = Workspace:FindFirstChild("HumanoidRootPart") or hrp -- placeholder
    line.From = getHRP() and getHRP().Position or Vector3.new(0,0,0)
    line.To = hrp.Position
    line.Thickness = state.cfg.mods.visual.tracers.thickness
    line.AlwaysOnTop = true
    line.Parent = Workspace
    state.adornments.tracers[plr] = line
end

local function removeTracerForPlayer(plr)
    local a = state.adornments.tracers[plr]
    if a then pcall(function() a:Destroy() end) end
    state.adornments.tracers[plr] = nil
end

local function updateAllVisuals()
    -- iterate players and create/remove adornments based on toggles
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == player then
            -- skip local player adornments
        else
            -- team check logic
            local skip = false
            if state.cfg.mods.visual.esp.teamCheck and plr.Team == player.Team then
                skip = true
            end

            if state.cfg.mods.visual.esp.enabled and not skip then
                createESPForPlayer(plr)
            else
                removeESPForPlayer(plr)
            end

            if state.cfg.mods.visual.chams.enabled and not skip then
                createChamsForPlayer(plr)
            else
                removeChamsForPlayer(plr)
            end

            if state.cfg.mods.visual.tracers.enabled and not skip then
                createTracerForPlayer(plr)
            else
                removeTracerForPlayer(plr)
            end
        end
    end
end

-- apply FPS boost (one-time)
function applyFPSBoost(enabled)
    if enabled then
        for setting, value in pairs(state.cfg.mods.misc.fpsBoost.settings.Rendering) do pcall(function() Lighting[setting] = value end) end
        -- Effects and Performance changes are best applied server-side or via UserSettings on the client with caution
    else
        -- no revert implemented; you can store previous values if needed
    end
end

-- AutoClicker using VirtualUser (respect CPS)
local function runAutoClicker()
    local ac = state.cfg.mods.combat.autoClicker
    if not ac.enabled then return end
    local key = ac.keybind
    if UserInputService:IsKeyDown(key) then
        local now = tick()
        local interval = 1 / math.max(ac.cps, 1)
        if now - state.lastAutoClick >= interval then
            state.lastAutoClick = now
            -- simulate mouse click using VirtualUser
            pcall(function()
                VirtualUser:Button1Down(Vector2.new(0,0))
                task.wait(0.01)
                VirtualUser:Button1Up(Vector2.new(0,0))
            end)
        end
    end
end

-- Triggerbot (simple: check mouse.Target and use virtual click)
local function runTriggerbot()
    local tb = state.cfg.mods.combat.triggerbot
    if not tb.enabled then return end
    local target = player:GetMouse().Target
    if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") then
        local targetPlr = Players:GetPlayerFromCharacter(target.Parent)
        if targetPlr and targetPlr ~= player then
            if tb.teamCheck and targetPlr.Team == player.Team then return end
            -- small delay then click
            task.spawn(function()
                task.wait(tb.delay)
                pcall(function()
                    VirtualUser:Button1Down(Vector2.new(0,0))
                    task.wait(0.01)
                    VirtualUser:Button1Up(Vector2.new(0,0))
                end)
            end)
        end
    end
end

-- FLY control update per-frame (BodyVelocity target velocity)
local function updateFlyMovement(dt)
    if not state.cfg.mods.movement.fly.enabled then return end
    if not state.flyBV then enableFly() end
    local hrp = getHRP()
    if not hrp or not state.flyBV then return end

    local flySpeed = state.cfg.mods.movement.fly.speed or 100
    local dir = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + hrp.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - hrp.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - hrp.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + hrp.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end

    if dir.Magnitude > 0 then
        state.flyBV.Velocity = dir.Unit * flySpeed
    else
        state.flyBV.Velocity = Vector3.new(0,0,0)
    end
end

-- update adornments per-frame where necessary (e.g., tracers line endpoints)
local function updateAdornments()
    for plr, line in pairs(state.adornments.tracers) do
        local chr = plr.Character
        local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
        if hrp and line then
            local myHRP = getHRP()
            if myHRP then
                pcall(function()
                    line.From = myHRP.Position
                    line.To = hrp.Position
                end)
            end
        end
    end
end

-- ---------- ONE-TIME EVENT CONNECTIONS (not in frame loop) ----------
-- Init defaults when char exists or respawns
player.CharacterAdded:Connect(function()
    initDefaultsFromHumanoid()
    -- reapply toggles when respawned
    if state.cfg.mods.movement.fly.enabled then enableFly() end
    if state.cfg.mods.utility.noClip.enabled then setNoClip(true) end
    updateAllVisuals()
end)
pcall(initDefaultsFromHumanoid)

-- Anti-AFK
player.Idled:Connect(function()
    if state.cfg.mods.utility.antiAfk.enabled then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0,0))
        end)
    end
end)

-- Infinite jump
local humanoid = getHumanoid()
if humanoid then
    humanoid.Jumping:Connect(function(active)
        if state.cfg.mods.utility.infiniteJump.enabled and active then
            local h = getHumanoid()
            if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == state.cfg.mods.binds.toggleMenu then
        if ScreenGui and ScreenGui:FindFirstChild("MainFrame") then
            ScreenGui.MainFrame.Visible = not ScreenGui.MainFrame.Visible
        end
        return
    end

    for catName, catTable in pairs(state.cfg.mods) do
        for featName, featTable in pairs(catTable) do
            if type(featTable) == "table" and featTable.enabled ~= nil then
                local bindKey = state.cfg.mods.binds[featName]
                if bindKey and input.KeyCode == bindKey then
                    featTable.enabled = not featTable.enabled
                    applyToggleEffects(featName, featTable)
                    if catName == "visual" then updateAllVisuals() end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESPForPlayer(plr)
    removeChamsForPlayer(plr)
    removeTracerForPlayer(plr)
end)

Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    updateAllVisuals()
end)

createMenu()

-- load any client config available
loadClientConfigIfPresent()
initDefaultsFromHumanoid()
updateAllVisuals()

-- ---------- MAIN FRAME UPDATE ----------
RunService.RenderStepped:Connect(function(dt)
    if state.cfg.mods.movement.fly.enabled then
        updateFlyMovement(dt)
    else
        if state.flyBV then disableFly() end
    end

    local speedCfg = state.cfg.mods.movement.speed
    if speedCfg then
        local desired = speedCfg.enabled and speedCfg.speed or speedCfg.defaultSpeed
        local hum = getHumanoid()
        if hum and hum.WalkSpeed ~= desired then hum.WalkSpeed = desired end
    end

    local jumpCfg = state.cfg.mods.movement.jump
    if jumpCfg then
        local desiredJump = jumpCfg.enabled and jumpCfg.power or jumpCfg.defaultPower
        local hum = getHumanoid()
        if hum and hum.JumpPower ~= desiredJump then hum.JumpPower = desiredJump end
    end

    if state.cfg.mods.utility.noClip.enabled then
        local char = getCharacter()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.CanCollide then pcall(function() part.CanCollide = false end) end
                end
            end
        end
    end
        
    runAutoClicker()
    runTriggerbot()

   
    updateAdornments()

    -- Spin (fun)
    if state.cfg.mods.fun.spin.enabled then
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(state.cfg.mods.fun.spin.speed) * dt * 60, 0)
        end
    end


end)

local saveDebounce = false
local function requestSaveConfig()
    if saveDebounce then return end
    saveDebounce = true
    task.delay(2, function()
        saveConfigToServer()
        saveDebounce = false
    end)
end

local oldApply = applyToggleEffects
function applyToggleEffects(featureName, featureTable)
    oldApply(featureName, featureTable)
    requestSaveConfig()
end

print("[DC] Client Loaded!")

-- EOF
