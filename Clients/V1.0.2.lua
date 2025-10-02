-- Core Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")

-- Player / GUI Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Teams = game:GetService("Teams")
local Chat = game:GetService("Chat")

-- Data & Storage
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")

-- Physics & Environment
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local PhysicsService = game:GetService("PhysicsService")
local Terrain = Workspace.Terrain

-- Replication / Networking
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagingService = game:GetService("MessagingService")

-- Monetization / Marketplace
local MarketplaceService = game:GetService("MarketplaceService")
local BadgeService = game:GetService("BadgeService")
local GamePassService = game:GetService("GamePassService") -- (alias of MarketplaceService)
local PolicyService = game:GetService("PolicyService")

-- Teleport / Cross-server
local TeleportService = game:GetService("TeleportService")
local FriendService = game:GetService("FriendService") -- legacy/deprecated

-- Social & Localization
local LocalizationService = game:GetService("LocalizationService")
local SocialService = game:GetService("SocialService")

-- Developer / Analytics
local AnalyticsService = game:GetService("AnalyticsService")
local ScriptContext = game:GetService("ScriptContext")
local TestService = game:GetService("TestService")

-- Miscellaneous
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Selection = game:GetService("Selection")

-- Player def
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum= char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()

-- Config
local config = {
    version = "1.0.2",
    testing = true,
    prefix = ".",
    owner = 123456789, -- replace with your user ID
    menuToggle = true,
    datafile = "DC_config",
    mods = {
        movement = {
            fly = {
                enabled = false,
                speed = 100
            },
            speed = {
                enabled = false,
                defaultSpeed = hum.WalkSpeed,
                speed = 32
            },
            jump = {
                enabled = false,
                defaultPower = hum.JumpPower,
                defaultHeight = hum.JumpHeight,
                power = 100,
                height = 50
            },
        },
        visual = {
            esp = {
                enabled = false,
                box = true,
                name = true,
                health = true,
                distance = true,
                teamCheck = true,
                team = nil
            },
            chams = {
                enabled = false,
                color = Color3.new(1, 0, 0),
                transparency = 0.5
            },
            tracers = {
                enabled = false,
                color = Color3.new(0, 1, 0),
                thickness = 1,
                teamCheck = true,
                team = nil
            },
            fov = {
                enabled = false,
                radius = 100,
                color = Color3.new(1, 1, 1),
                thickness = 1
            },
            wallhack = {
                enabled = false,
                transparency = 0.5
            }
        },
        utility = {
            antiAfk = {
                enabled = true
            },
            noClip = {
                enabled = false
            },
            infiniteJump = {
                enabled = false
            },
            teleport = {
                enabled = false,
                target = nil,
                saves = {
                    -- Place ID
                    --[[
                    123456789 = {
                        name = "start",
                        position = Vector3.new(0, 10, 0)
                    },
                    987654321 = {
                        name = "end",
                        position = Vector3.new(100, 10, 100)
                    }
                    ]]
                },
            },

        },
        combat = {
            aimbot = {
                enabled = false,
                fov = 30,
                smoothness = 0.5,
                teamCheck = true,
                targetPart = "Head",
                keybind = Enum.KeyCode.LeftAlt,
                target = nil
            },
            triggerbot = {
                enabled = false,
                delay = 0.1,
                teamCheck = true
            },
            silentAim = {
                enabled = false,
                fov = 30,
                teamCheck = true,
                targetPart = "Head",
                target = nil
            },
            autoClicker = {
                enabled = false,
                cps = 10,
                jitter = false,
                keybind = Enum.KeyCode.LeftControl
            }
        },
        fun = {
            fling = {
                enabled = false,
                target = nil,
                force = 1000
            },
            spin = {
                enabled = false,
                speed = 100
            },
            fakeLag = {
                enabled = false,
                amount = 0.1
            }
        },
        misc = {
            rejoin = {
                enabled = false
            },
            serverHop = {
                enabled = false,
                visited = {}
            },
            fpsBoost = {
                enabled = false,
                settings = {
                    ["Rendering"] = {
                        ["GlobalShadows"] = false,
                        ["QualityLevel"] = 1,
                        ["TerrainDecoration"] = false,
                        ["WaterWaveSize"] = 0,
                        ["WaterReflectance"] = 0,
                        ["WaterTransparency"] = 0,
                        ["ShadowSoftness"] = 0,
                        ["AtmosphereDensity"] = 0,
                        ["Brightness"] = 1
                    },
                    ["Effects"] = {
                        ["BlurEffect.Enabled"] = false,
                        ["SunRaysEffect.Enabled"] = false,
                        ["ColorCorrectionEffect.Enabled"] = false,
                        ["BloomEffect.Enabled"] = false,
                        ["DepthOfFieldEffect.Enabled"] = false
                    },
                    ["Performance"] = {
                        ["ImageQualityLevel"] = 1,
                        ["GraphicsMode"] = "Performance",
                        ["FrameRateManagerMethod"] = "Fixed",
                        ["VsyncEnabled"] = false
                    }
                }
            }
        },
        hubs = {
            list = {
                {
                    name = "ExampleHub",
                    url = "https://example.com/hub.lua"
                }
            }
        },
        themes = {
            current = "Red",
            list = {
                Light = {
                    background = Color3.fromRGB(255, 255, 255),
                    text = Color3.fromRGB(0, 0, 0),
                    accent = Color3.fromRGB(0, 120, 215)
                },
                Dark = {
                    background = Color3.fromRGB(30, 30, 30),
                    text = Color3.fromRGB(255, 255, 255),
                    accent = Color3.fromRGB(0, 120, 215)
                },
                Red = {
                    background = Color3.fromRGB(50, 0, 0),
                    text = Color3.fromRGB(255, 255, 255),
                    accent = Color3.fromRGB(255, 0, 0)
                },
                Blue = {
                    background = Color3.fromRGB(0, 0, 50),
                    text = Color3.fromRGB(255, 255, 255),
                    accent = Color3.fromRGB(0, 0, 255)
                },
                Green = {
                    background = Color3.fromRGB(0, 50, 0),
                    text = Color3.fromRGB(255, 255, 255),
                    accent = Color3.fromRGB(0, 255, 0)
                }
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

-- Config loader
local function loadConfig()
    local success, configData = pcall(function()
        return game:GetService("DataStoreService"):GetDataStore(config.datafile):GetAsync(player.UserId)
    end)

    if success and configData then
        config = configData
    else
        warn("Failed to load config: " .. tostring(configData))
    end
end

-- Create Menu
-- GUI Container
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "DC_Menu"

-- Theme
local theme = config.themes.list[config.themes.current]

-- Main Frame
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
MainFrame.BackgroundColor3 = theme.background
MainFrame.Visible = config.menuToggle

-- Draggable
MainFrame.Active = true
MainFrame.Draggable = true

-- Title
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Death's Control Menu v" .. config.version
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextColor3 = theme.accent

-- Tab Container
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(0, 120, 1, -40)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundColor3 = theme.background

-- Content Container
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -120, 1, -40)
Content.Position = UDim2.new(0, 120, 0, 40)
Content.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

-- UIListLayouts
local TabLayout = Instance.new("UIListLayout", TabContainer)
TabLayout.Padding = UDim.new(0, 5)

local ContentLayout = Instance.new("UIListLayout", Content)
ContentLayout.Padding = UDim.new(0, 5)

-- Function to clear content
local function clearContent()
    for _, v in ipairs(Content:GetChildren()) do
        if v:IsA("GuiObject") then v:Destroy() end
    end
end

-- Function to create toggle
local function createToggle(parent, name, settingTable)
    local Button = Instance.new("TextButton", parent)
    Button.Size = UDim2.new(1, -10, 0, 30)
    Button.BackgroundColor3 = theme.background
    Button.TextColor3 = theme.text
    Button.Text = name .. ": " .. tostring(settingTable.enabled)

    Button.MouseButton1Click:Connect(function()
        settingTable.enabled = not settingTable.enabled
        Button.Text = name .. ": " .. tostring(settingTable.enabled)
    end)
end

-- Function to open category
local function openCategory(catName, catTable)
    clearContent()
    for featureName, feature in pairs(catTable) do
        if typeof(feature) == "table" and feature.enabled ~= nil then
            createToggle(Content, featureName, feature)
        end
    end
end

-- Create Tabs
for categoryName, categoryTable in pairs(config.mods) do
    local Tab = Instance.new("TextButton", TabContainer)
    Tab.Size = UDim2.new(1, -10, 0, 30)
    Tab.BackgroundColor3 = theme.background
    Tab.TextColor3 = theme.text
    Tab.Text = categoryName

    Tab.MouseButton1Click:Connect(function()
        openCategory(categoryName, categoryTable)
    end)
end

-- Toggles
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == config.mods.binds.toggleMenu then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == config.mods.binds.toggleMenu then
        MainFrame.Visible = not MainFrame.Visible
        return
    end

    for modCategory, features in pairs(config.mods) do
        if typeof(features) == "table" then
            for featureName, feature in pairs(features) do
                if typeof(feature) == "table" then
                    -- Check if feature has a keybind entry in binds
                    local bindKey = config.mods.binds[featureName]
                    if bindKey and input.KeyCode == bindKey then
                        feature.enabled = not feature.enabled
                        print(featureName .. " set to " .. tostring(feature.enabled))
                    end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    -- MOVEMENT

    -- Fly
    if config.mods.movement.fly.enabled then
        local moveDirection = Vector3.new(0, 0, 0)
        local flySpeed = config.mods.movement.fly.speed

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + hrp.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - hrp.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - hrp.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + hrp.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

        if moveDirection.Magnitude > 0 then
            hrp.Velocity = moveDirection.Unit * flySpeed
        else
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end

    -- Speed Hack
    hum.WalkSpeed = config.mods.movement.speed.enabled and config.mods.movement.speed.speed or config.mods.movement.speed.defaultSpeed

    -- Jump Hack
    hum.JumpPower = config.mods.movement.jump.enabled and config.mods.movement.jump.power or config.mods.movement.jump.defaultPower
    hum.JumpHeight = config.mods.movement.jump.enabled and config.mods.movement.jump.height or config.mods.movement.jump.defaultHeight

    -- UTILITY

    -- NoClip
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not config.mods.utility.noClip.enabled
        end
    end

    -- Infinite Jump
    if config.mods.utility.infiniteJump.enabled then
        hum.Jumping:Connect(function(active)
            if active then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end

    -- Anti-AFK
    if config.mods.utility.antiAfk.enabled then
        player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end

    -- FUN

    -- Spin
    if config.mods.fun.spin.enabled then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(config.mods.fun.spin.speed), 0)
    end

    -- Fake Lag
    if config.mods.fun.fakeLag.enabled then
        task.wait(config.mods.fun.fakeLag.amount)
    end

    -- Fling (automatic, safe)
    if config.mods.fun.fling.enabled and config.mods.fun.fling.target then
        local targetPlayer = config.mods.fun.fling.target
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = targetPlayer.Character.HumanoidRootPart
            hrp.CFrame = CFrame.new(targetHRP.Position.X, targetHRP.Position.Y - 2, targetHRP.Position.Z)
            hrp.Velocity = Vector3.new(
                math.random(-1, 1) * config.mods.fun.fling.force,
                config.mods.fun.fling.force,
                math.random(-1, 1) * config.mods.fun.fling.force
            )
        end
    end

    -- COMBAT

    -- Triggerbot
    if config.mods.combat.triggerbot.enabled then
        if mouse.Target and mouse.Target.Parent and mouse.Target.Parent:FindFirstChild("Humanoid") then
            local targetPlayer = Players:GetPlayerFromCharacter(mouse.Target.Parent)
            if targetPlayer and targetPlayer ~= player then
                if config.mods.combat.triggerbot.teamCheck and targetPlayer.Team == player.Team then return end
                task.wait(config.mods.combat.triggerbot.delay)
                UserInputService.MouseButton1Down:Fire()
            end
        end
    end

    -- Auto Clicker
    if config.mods.combat.autoClicker.enabled then
        if UserInputService:IsKeyDown(config.mods.combat.autoClicker.keybind) then
            local cps = config.mods.combat.autoClicker.cps
            local interval = 1 / cps
            UserInputService.MouseButton1Down:Fire()
            task.wait(interval)
            UserInputService.MouseButton1Up:Fire()
        end
    end

    -- VISUAL

    -- ESP / Chams / Tracers / FOV / Wallhack
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            -- Team check
            if config.mods.visual.esp.teamCheck and plr.Team == player.Team then continue end

            local hrpTarget = plr.Character.HumanoidRootPart

            -- ESP Box
            if config.mods.visual.esp.enabled and config.mods.visual.esp.box then
                if not hrpTarget:FindFirstChild("ESP_Box") then
                    local box = Instance.new("BoxHandleAdornment", hrpTarget)
                    box.Name = "ESP_Box"
                    box.Adornee = hrpTarget
                    box.Size = Vector3.new(2, 5, 1)
                    box.Color3 = Color3.new(1, 0, 0)
                    box.Transparency = 0.5
                    box.AlwaysOnTop = true
                end
            end

            -- Chams
            if config.mods.visual.chams.enabled then
                for _, part in pairs(plr.Character:GetChildren()) do
                    if part:IsA("BasePart") and not part:FindFirstChild("Chams") then
                        local cham = Instance.new("BoxHandleAdornment", part)
                        cham.Name = "Chams"
                        cham.Adornee = part
                        cham.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
                        cham.Color3 = config.mods.visual.chams.color
                        cham.Transparency = config.mods.visual.chams.transparency
                        cham.AlwaysOnTop = true
                    end
                end
            end

            -- Tracers
            if config.mods.visual.tracers.enabled then
                local tracer = hrpTarget:FindFirstChild("ESP_Tracer")
                if not tracer then
                    tracer = Instance.new("LineHandleAdornment", hrpTarget)
                    tracer.Name = "ESP_Tracer"
                    tracer.Adornee = hrp
                    tracer.From = hrp.Position
                    tracer.To = hrpTarget.Position
                    tracer.Color3 = config.mods.visual.tracers.color
                    tracer.Thickness = config.mods.visual.tracers.thickness
                    tracer.AlwaysOnTop = true
                else
                    tracer.From = hrp.Position
                    tracer.To = hrpTarget.Position
                end
            end

            -- Wallhack
            if config.mods.visual.wallhack.enabled then
                for _, part in pairs(plr.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = config.mods.visual.wallhack.transparency
                    end
                end
            end
        end
    end

    -- FOV Circle
    local fovCircle = ScreenGui:FindFirstChild("FOV_Circle")
    if config.mods.visual.fov.enabled then
        if not fovCircle then
            fovCircle = Instance.new("Frame", ScreenGui)
            fovCircle.Name = "FOV_Circle"
            fovCircle.Size = UDim2.new(0, config.mods.visual.fov.radius*2, 0, config.mods.visual.fov.radius*2)
            fovCircle.Position = UDim2.new(0.5, -config.mods.visual.fov.radius, 0.5, -config.mods.visual.fov.radius)
            fovCircle.BackgroundColor3 = config.mods.visual.fov.color
            fovCircle.BorderSizePixel = 0
            local corner = Instance.new("UICorner", fovCircle)
            corner.CornerRadius = UDim.new(1, 0)
        else
            fovCircle.Size = UDim2.new(0, config.mods.visual.fov.radius*2, 0, config.mods.visual.fov.radius*2)
        end
    elseif fovCircle then fovCircle:Destroy() end

    -- MISC

    -- FPS Boost
    if config.mods.misc.fpsBoost.enabled then
        for setting, value in pairs(config.mods.misc.fpsBoost.settings.Rendering) do pcall(function() Lighting[setting] = value end) end
        for setting, value in pairs(config.mods.misc.fpsBoost.settings.Effects) do pcall(function() Lighting[setting] = value end) end
        for setting, value in pairs(config.mods.misc.fpsBoost.settings.Performance) do
            pcall(function() UserSettings():GetService("UserGameSettings")[setting] = value end)
        end
    end
end)

