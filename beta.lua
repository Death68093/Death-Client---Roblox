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

-- Default config (expanded settings per-mod)
local defaultConfig = {
    version = "1.0.2",
    testing = true,
    prefix = ".",
    owner = 123456789,
    menuToggle = true,
    datafile = "DC_config",
    mods = {
        movement = {
            fly = { enabled = false, speed = 100, smooth = true, ascendKey = Enum.KeyCode.Space, descendKey = Enum.KeyCode.LeftControl },
            speed = { enabled = false, defaultSpeed = nil, speed = 32 },
            jump = { enabled = false, defaultPower = nil, defaultHeight = nil, power = 100, height = 50, infinite = false },
            noclip = { enabled = false, mode = "parts" }, -- mode: "parts" or "humanoid"
        },
        visual = {
            esp = { enabled = false, box = true, name = true, health = true, distance = true, teamCheck = true, team = nil, color = Color3.fromRGB(255,0,0), maxDistance = 1000 },
            chams = { enabled = false, material = Enum.Material.Neon, color = Color3.fromRGB(255,0,0), transparency = 0.5, alwaysOnTop = true },
            tracers = { enabled = false, color = Color3.fromRGB(0,255,0), thickness = 1, teamCheck = true, maxDistance = 1000 },
            fov = { enabled = false, radius = 100, color = Color3.fromRGB(255,255,255), thickness = 1 },
            wallhack = { enabled = false, transparency = 0.5 },
        },
        utility = {
            antiAfk = { enabled = true, interval = 60 },
            infiniteJump = { enabled = false },
            teleport = { enabled = false, target = nil, saves = {}, saveLimit = 12 },
            rejoin = { enabled = false, delay = 2 },
            serverHop = { enabled = false, visited = {}, delay = 3 },
        },
        combat = {
            aimbot = { enabled = false, fov = 30, smoothness = 0.5, teamCheck = true, targetPart = "Head", keybind = Enum.KeyCode.LeftAlt, priority = "closest" }, -- priority: "closest","lowestHealth","crosshair"
            triggerbot = { enabled = false, delay = 0.05, teamCheck = true },
            autoClicker = { enabled = false, cps = 10, jitter = false, jitterAmount = 1, keybind = Enum.KeyCode.LeftControl },
            silentAim = { enabled = false, fov = 20, keybind = Enum.KeyCode.V },
        },
        fun = {
            fling = { enabled = false, target = nil, force = 1000, mode = "velocity" },
            spin = { enabled = false, speed = 100, axis = "y" },
            fakeLag = { enabled = false, amount = 0.1 },
        },
        misc = {
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
            },
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
    ScreenGui = nil,
}

-- utility: deep-merge table b into a (non-destructive for a)
local function deepMerge(a, b)
    for k, v in pairs(b) do
        if type(v) == "table" and type(a[k]) == "table" then
            deepMerge(a[k], v)
        elseif type(v) == "table" and type(a[k]) ~= "table" then
            a[k] = {}
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
end

-- Character & Humanoid helpers
local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end
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
        if state.cfg.mods.movement.jump.defaultHeight == nil then
            state.cfg.mods.movement.jump.defaultHeight = hum.JumpHeight or 0
        end
    end
end

-- Attempt to load client-side saved config from ReplicatedStorage
local function loadClientConfigIfPresent()
    local module = ReplicatedStorage:FindFirstChild("DC_ClientConfig")
    if module and module:IsA("ModuleScript") then
        local ok, remoteCfg = pcall(require, module)
        if ok and type(remoteCfg) == "table" then
            deepMerge(state.cfg, remoteCfg)
        end
    else
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
    end
end

-- ---------- EFFECTS / HELPERS ----------

-- WALK SPEED / JUMP updates
local function updateWalkSpeed(value)
    local hum = getHumanoid()
    if hum and value then
        pcall(function() hum.WalkSpeed = value end)
    end
end

local function updateJumpSettings(power)
    local hum = getHumanoid()
    if hum and power then
        pcall(function() hum.JumpPower = power end)
    end
end

-- NOCLIP (apply on toggle)
local function setNoClip(enabled)
    local char = player.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = not enabled end)
        end
    end
end

-- FLY using BodyVelocity
local function enableFly()
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

local function disableFly()
    if state.flyBV then
        pcall(function() state.flyBV:Destroy() end)
        state.flyBV = nil
    end
end

-- VISUALS (ESP / Chams / Tracers)
local function safeAdornParent()
    -- Adornments should be parented to Workspace for rendering
    return Workspace
end

local function createESPForPlayer(plr)
    if state.adornments.esp[plr] then return end
    local character = plr.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "DC_ESPBox"
    box.Adornee = hrp
    box.Size = Vector3.new(2,5,1)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Parent = safeAdornParent()

    state.adornments.esp[plr] = { box = box }
end

local function removeESPForPlayer(plr)
    local t = state.adornments.esp[plr]
    if t then
        for _, v in pairs(t) do pcall(function() v:Destroy() end) end
    end
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
            adorn.AlwaysOnTop = state.cfg.mods.visual.chams.alwaysOnTop
            adorn.Parent = safeAdornParent()
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
    line.Adornee = hrp -- set adornee to some part (won't affect From/To)
    line.From = Vector3.new(0,0,0)
    line.To = hrp.Position
    line.Thickness = state.cfg.mods.visual.tracers.thickness
    line.AlwaysOnTop = true
    line.Parent = safeAdornParent()
    state.adornments.tracers[plr] = line
end

local function removeTracerForPlayer(plr)
    local a = state.adornments.tracers[plr]
    if a then pcall(function() a:Destroy() end) end
    state.adornments.tracers[plr] = nil
end

local function updateAllVisuals()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == player then
            -- skip local player
        else
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
local function applyFPSBoost(enabled)
    if enabled then
        for setting, value in pairs(state.cfg.mods.misc.fpsBoost.settings.Rendering) do
            pcall(function()
                if Lighting[setting] ~= nil then
                    Lighting[setting] = value
                else
                    -- Some settings might need different handling; ignore if missing
                end
            end)
        end
    end
end

-- AutoClicker using VirtualUser (respect CPS)
local function runAutoClicker()
    local ac = state.cfg.mods.combat.autoClicker
    if not ac.enabled then return end
    local key = ac.keybind
    if key and typeof(key) == "EnumItem" then
        if UserInputService:IsKeyDown(key) then
            local now = tick()
            local interval = 1 / math.max(ac.cps or 1, 1)
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
end

-- Triggerbot (simple)
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
    if UserInputService:IsKeyDown(state.cfg.mods.movement.fly.ascendKey or Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(state.cfg.mods.movement.fly.descendKey or Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end

    if dir.Magnitude > 0 then
        state.flyBV.Velocity = dir.Unit * flySpeed
    else
        state.flyBV.Velocity = Vector3.new(0,0,0)
    end
end

-- update adornments per-frame (tracers)
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

-- ---------- UI ----------

local function createTextLabel(parent, text, size)
    local t = Instance.new("TextLabel")
    t.Size = size or UDim2.new(1,0,0,24)
    t.BackgroundTransparency = 1
    t.Text = text or ""
    t.Font = Enum.Font.SourceSans
    t.TextSize = 14
    t.TextColor3 = Color3.fromRGB(255,255,255)
    t.Parent = parent
    return t
end

local function createButton(parent, text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-10,0,30)
    b.BackgroundTransparency = 0.15
    b.BorderSizePixel = 0
    b.Text = text or ""
    b.Font = Enum.Font.SourceSans
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Parent = parent
    return b
end

local function createToggleButton(parent, name, featureTable, theme)
    local btn = createButton(parent, name .. ": " .. tostring(featureTable.enabled))
    btn.MouseButton1Click:Connect(function()
        featureTable.enabled = not featureTable.enabled
        btn.Text = name .. ": " .. tostring(featureTable.enabled)
        if featureTable.enabled then
            btn.BackgroundColor3 = theme.accent
        else
            btn.BackgroundColor3 = theme.background
        end
        -- immediate effect
        if name == "fly" then
            if featureTable.enabled then enableFly() else disableFly() end
        elseif name == "speed" then
            updateWalkSpeed(featureTable.enabled and featureTable.speed or featureTable.defaultSpeed)
        elseif name == "jump" then
            updateJumpSettings(featureTable.enabled and featureTable.power or featureTable.defaultPower)
        elseif name == "noclip" then
            setNoClip(featureTable.enabled)
        elseif name == "esp" or name == "chams" or name == "tracers" then
            updateAllVisuals()
        elseif name == "fpsBoost" then
            applyFPSBoost(featureTable.enabled)
        end
        -- save
        pcall(function() saveConfigToServer() end)
    end)
    return btn
end

-- create controls for numeric/string/Color3 fields inside feature table
local function createSettingControls(parent, featureTable)
    for k, v in pairs(featureTable) do
        if k ~= "enabled" and type(v) ~= "table" then
            local typ = typeof(v)
            if type(v) == "number" then
                local label = createTextLabel(parent, k .. " (number)")
                local box = Instance.new("TextBox", parent)
                box.Size = UDim2.new(1,-10,0,24)
                box.Text = tostring(v)
                box.ClearTextOnFocus = false
                box.FocusLost:Connect(function(enter)
                    local n = tonumber(box.Text)
                    if n then
                        featureTable[k] = n
                        pcall(function() saveConfigToServer() end)
                    else
                        box.Text = tostring(featureTable[k])
                    end
                end)
            elseif type(v) == "string" then
                local label = createTextLabel(parent, k .. " (text)")
                local box = Instance.new("TextBox", parent)
                box.Size = UDim2.new(1,-10,0,24)
                box.Text = tostring(v)
                box.ClearTextOnFocus = false
                box.FocusLost:Connect(function()
                    featureTable[k] = box.Text
                    pcall(function() saveConfigToServer() end)
                end)
            elseif typ == "Color3" then
                local label = createTextLabel(parent, k .. " (Color3: R,G,B)")
                local box = Instance.new("TextBox", parent)
                box.Size = UDim2.new(1,-10,0,24)
                local r,g,b = math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)
                box.Text = string.format("%d,%d,%d", r,g,b)
                box.ClearTextOnFocus = false
                box.FocusLost:Connect(function()
                    local s = box.Text
                    local r2,g2,b2 = s:match("^(%d+),%s*(%d+),%s*(%d+)$")
                    if r2 and g2 and b2 then
                        r2,g2,b2 = tonumber(r2)/255, tonumber(g2)/255, tonumber(b2)/255
                        featureTable[k] = Color3.fromRGB(math.clamp(tonumber(r2*255),0,255), math.clamp(tonumber(g2*255),0,255), math.clamp(tonumber(b2*255),0,255))
                        pcall(function() saveConfigToServer() end)
                    else
                        local rr,gg,bb = math.floor(featureTable[k].R*255), math.floor(featureTable[k].G*255), math.floor(featureTable[k].B*255)
                        box.Text = string.format("%d,%d,%d", rr,gg,bb)
                    end
                end)
            else
                -- show read-only for enums / keybinds / userdata
                local label = createTextLabel(parent, k .. " = " .. tostring(v))
            end
        end
    end
end

-- create UI menu
local function createMenu()
    local parent
    if state.cfg.testing then
        parent = playerGui
    else
        -- CoreGui parenting may be restricted; fallback to PlayerGui
        parent = playerGui
    end

    -- if exists, destroy to recreate
    if state.ScreenGui and state.ScreenGui.Parent then
        state.ScreenGui:Destroy()
        state.ScreenGui = nil
    end

    local theme = state.cfg.mods.themes and state.cfg.mods.themes.list[state.cfg.mods.themes.current] or { background = Color3.fromRGB(20,20,20), text = Color3.fromRGB(255,255,255), accent = Color3.fromRGB(255,0,0) }

    local ScreenGui = Instance.new("ScreenGui", parent)
    ScreenGui.Name = "DC_Menu"
    ScreenGui.ResetOnSpawn = false
    state.ScreenGui = ScreenGui

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 640, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -320, 0.5, -210)
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
    TabContainer.Size = UDim2.new(0,160,1,-40)
    TabContainer.Position = UDim2.new(0,0,0,40)
    TabContainer.BackgroundColor3 = theme.background

    local Content = Instance.new("ScrollingFrame", MainFrame)
    Content.Name = "Content"
    Content.Size = UDim2.new(1,-160,1,-40)
    Content.Position = UDim2.new(0,160,0,40)
    Content.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Content.CanvasSize = UDim2.new(0,0,2,0)
    Content.ScrollBarThickness = 6

    local TabLayout = Instance.new("UIListLayout", TabContainer)
    TabLayout.Padding = UDim.new(0,5)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local ContentLayout = Instance.new("UIListLayout", Content)
    ContentLayout.Padding = UDim.new(0,5)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function clearContent()
        for _, v in ipairs(Content:GetChildren()) do
            if v:IsA("GuiObject") then v:Destroy() end
        end
    end

    local function openCategory(catName, catTable)
        clearContent()
        createTextLabel(Content, "Category: " .. catName, UDim2.new(1,0,0,28))
        for featureName, feature in pairs(catTable) do
            if type(feature) == "table" and feature.enabled ~= nil then
                local wrap = Instance.new("Frame", Content)
                wrap.Size = UDim2.new(1,-10,0,100)
                wrap.BackgroundTransparency = 1
                wrap.LayoutOrder = #Content:GetChildren()
                local toggle = createToggleButton(wrap, featureName, feature, theme)
                toggle.Position = UDim2.new(0,0,0,0)
                -- create settings container
                local settingsFrame = Instance.new("Frame", wrap)
                settingsFrame.Size = UDim2.new(1,0,0,68)
                settingsFrame.Position = UDim2.new(0,0,0,32)
                settingsFrame.BackgroundTransparency = 1
                createSettingControls(settingsFrame, feature)
            end
        end
    end

    -- create tabs
    for categoryName, categoryTable in pairs(state.cfg.mods) do
        if type(categoryTable) == "table" then
            local Tab = createButton(TabContainer, categoryName)
            Tab.MouseButton1Click:Connect(function()
                openCategory(categoryName, categoryTable)
            end)
        end
    end

    -- open first category by default
    for categoryName, categoryTable in pairs(state.cfg.mods) do
        openCategory(categoryName, categoryTable)
        break
    end
end

-- ---------- STATE DISPATCHER ----------
local function applyToggleEffects(featureName, featureTable)
    if featureName == "fly" then
        if featureTable.enabled then enableFly() else disableFly() end
    elseif featureName == "speed" then
        updateWalkSpeed(featureTable.enabled and featureTable.speed or featureTable.defaultSpeed)
    elseif featureName == "jump" then
        updateJumpSettings(featureTable.enabled and featureTable.power or featureTable.defaultPower)
    elseif featureName == "noclip" then
        setNoClip(featureTable.enabled)
    elseif featureName == "esp" or featureName == "chams" or featureName == "tracers" then
        updateAllVisuals()
    elseif featureName == "fpsBoost" then
        applyFPSBoost(featureTable.enabled)
    end
    -- persist asynchronously (server)
    pcall(function() saveConfigToServer() end)
end

-- continuous connections
player.CharacterAdded:Connect(function(char)
    task.defer(function()
        initDefaultsFromHumanoid()
        if state.cfg.mods.movement.fly.enabled then enableFly() end
        if state.cfg.mods.utility.noclip and state.cfg.mods.utility.noclip.enabled then setNoClip(true) end
        updateAllVisuals()
    end)
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

-- Infinite jump connection bound at character spawn
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
-- call once (if humanoid exists) and also on CharacterAdded earlier
pcall(bindInfiniteJump)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == state.cfg.mods.binds.toggleMenu then
        if state.ScreenGui and state.ScreenGui:FindFirstChild("MainFrame") then
            state.ScreenGui.MainFrame.Visible = not state.ScreenGui.MainFrame.Visible
        end
        return
    end

    for catName, catTable in pairs(state.cfg.mods) do
        if type(catTable) == "table" then
            for featName, featTable in pairs(catTable) do
                if type(featTable) == "table" and featTable.enabled ~= nil then
                    local bindKey = state.cfg.mods.binds[featName]
                    if bindKey and typeof(bindKey) == "EnumItem" and input.KeyCode == bindKey then
                        featTable.enabled = not featTable.enabled
                        applyToggleEffects(featName, featTable)
                        if catName == "visual" then updateAllVisuals() end
                    end
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

-- load config & init
createMenu()
loadClientConfigIfPresent()
initDefaultsFromHumanoid()
updateAllVisuals()

-- ---------- MAIN FRAME UPDATE ----------
RunService.RenderStepped:Connect(function(dt)
    -- Fly
    if state.cfg.mods.movement.fly.enabled then
        updateFlyMovement(dt)
    else
        if state.flyBV then disableFly() end
    end

    -- WalkSpeed enforcement
    local speedCfg = state.cfg.mods.movement.speed
    if speedCfg then
        local desired = speedCfg.enabled and speedCfg.speed or speedCfg.defaultSpeed
        local hum = getHumanoid()
        if hum and hum.WalkSpeed ~= desired then
            pcall(function() hum.WalkSpeed = desired end)
        end
    end

    -- Jump enforcement
    local jumpCfg = state.cfg.mods.movement.jump
    if jumpCfg then
        local desiredJump = jumpCfg.enabled and jumpCfg.power or jumpCfg.defaultPower
        local hum = getHumanoid()
        if hum and hum.JumpPower ~= desiredJump then
            pcall(function() hum.JumpPower = desiredJump end)
        end
    end

    -- NoClip per-frame fallback
    if state.cfg.mods.movement.noclip and state.cfg.mods.movement.noclip.enabled then
        local char = player.Character
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
            local ang = math.rad(state.cfg.mods.fun.spin.speed) * dt * 60
            if state.cfg.mods.fun.spin.axis == "x" then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(ang,0,0)
            elseif state.cfg.mods.fun.spin.axis == "z" then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0,0,ang)
            else
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0,ang,0)
            end
        end
    end
end)

-- Save debounce
local saveDebounce = false
local function requestSaveConfig()
    if saveDebounce then return end
    saveDebounce = true
    task.delay(2, function()
        saveConfigToServer()
        saveDebounce = false
    end)
end

-- Rewrap applyToggleEffects to also request save
local oldApply = applyToggleEffects
function applyToggleEffects(featureName, featureTable)
    oldApply(featureName, featureTable)
    requestSaveConfig()
end

print("[DC] Client Loaded!")

-- EOF
