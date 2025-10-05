-- Death Client V2.0
-- LocalScript
local Version = "2.0"
local Testing = false -- true = PlayerGui, false = CoreGui

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local GuiParent = Testing and Player:WaitForChild("PlayerGui") or CoreGui

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeathClient"
ScreenGui.Parent = GuiParent
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Tabs
local TabsFrame = Instance.new("Frame")
TabsFrame.Size = UDim2.new(0, 400, 0, 40)
TabsFrame.Position = UDim2.new(0, 0, 0, 0)
TabsFrame.BackgroundTransparency = 1
TabsFrame.Parent = MainFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -60)
ContentFrame.Position = UDim2.new(0, 10, 0, 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local tabs = {"Movement", "Combat", "Visuals", "Utility", "Script Hub", "Credits"}
local Buttons = {}
local ActiveTab

for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Size = UDim2.new(0, 65, 1, 0)
    btn.Position = UDim2.new(0, (i-1)*70, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60,0,0)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = TabsFrame
    Buttons[name] = btn

    btn.MouseButton1Click:Connect(function()
        for _, b in pairs(Buttons) do
            b.BackgroundColor3 = Color3.fromRGB(60,0,0)
        end
        btn.BackgroundColor3 = Color3.fromRGB(150,0,0)
        ActiveTab = name
        UpdateTab()
    end)
end

-- Modules storage
local Modules = {}
local ModuleToggles = {}

local function CreateToggle(parent, text, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Text = "OFF"
    button.Size = UDim2.new(0.3,0,1,0)
    button.Position = UDim2.new(0.7,0,0,0)
    button.BackgroundColor3 = Color3.fromRGB(100,0,0)
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Parent = frame

    local enabled = false
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        button.Text = enabled and "ON" or "OFF"
        button.BackgroundColor3 = enabled and Color3.fromRGB(0,150,0) or Color3.fromRGB(100,0,0)
        callback(enabled)
    end)
    return frame
end

-- Content update
function UpdateTab()
    for _,c in pairs(ContentFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local y = 0
    local tab = ActiveTab

    if tab == "Movement" then
        ModuleToggles.Fly = CreateToggle(ContentFrame, "Fly", function(enabled)
            if enabled then
                local bodyVel = Instance.new("BodyVelocity")
                bodyVel.Name = "DeathFly"
                bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
                bodyVel.Velocity = Vector3.new(0,0,0)
                bodyVel.Parent = Player.Character:FindFirstChild("HumanoidRootPart")
                RunService.Heartbeat:Connect(function()
                    if bodyVel.Parent then
                        local dir = Vector3.new()
                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Workspace.CurrentCamera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Workspace.CurrentCamera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Workspace.CurrentCamera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Workspace.CurrentCamera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
                        bodyVel.Velocity = dir.Unit * 50
                    end
                end)
            else
                local part = Player.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("DeathFly")
                if part then part:Destroy() end
            end
        end)
        ModuleToggles.HighJump = CreateToggle(ContentFrame, "High Jump", function(enabled)
            Player.Character.Humanoid.JumpPower = enabled and 200 or 50
        end)
        ModuleToggles.InfiniteJump = CreateToggle(ContentFrame, "Infinite Jump", function(enabled)
            local conn
            if enabled then
                conn = UserInputService.JumpRequest:Connect(function()
                    Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
                ModuleToggles.InfiniteJumpConn = conn
            else
                if ModuleToggles.InfiniteJumpConn then
                    ModuleToggles.InfiniteJumpConn:Disconnect()
                end
            end
        end)
    elseif tab == "Combat" then
        ModuleToggles.Triggerbot = CreateToggle(ContentFrame, "Triggerbot", function(enabled)
            local conn
            if enabled then
                conn = RunService.RenderStepped:Connect(function()
                    local mouse = Player:GetMouse()
                    local target = mouse.Target
                    if target and target.Parent:FindFirstChild("Humanoid") and target.Parent ~= Player.Character then
                        mouse1press()
                    end
                end)
                ModuleToggles.TriggerbotConn = conn
            else
                if ModuleToggles.TriggerbotConn then ModuleToggles.TriggerbotConn:Disconnect() end
            end
        end)
        ModuleToggles.AutoClicker = CreateToggle(ContentFrame, "Auto Clicker", function(enabled)
            local conn
            if enabled then
                conn = RunService.Heartbeat:Connect(function()
                    mouse1press()
                    mouse1release()
                end)
                ModuleToggles.AutoClickerConn = conn
            else
                if ModuleToggles.AutoClickerConn then ModuleToggles.AutoClickerConn:Disconnect() end
            end
        end)
    elseif tab == "Visuals" then
        ModuleToggles.ESP = CreateToggle(ContentFrame, "ESP", function(enabled)
            -- Example: highlight all players
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= Player then
                    local highlight = p.Character:FindFirstChildWhichIsA("Highlight") or Instance.new("Highlight")
                    highlight.Name = "DeathESP"
                    highlight.FillColor = Color3.fromRGB(255,0,0)
                    highlight.OutlineColor = Color3.fromRGB(0,0,0)
                    highlight.Parent = p.Character
                    highlight.Enabled = enabled
                end
            end
        end)
    elseif tab == "Utility" then
        ModuleToggles.NoClip = CreateToggle(ContentFrame, "NoClip", function(enabled)
            local conn
            if enabled then
                conn = RunService.Stepped:Connect(function()
                    for _, part in pairs(Player.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end)
                ModuleToggles.NoClipConn = conn
            else
                if ModuleToggles.NoClipConn then ModuleToggles.NoClipConn:Disconnect() end
            end
        end)
        ModuleToggles.FloatingPlatform = CreateToggle(ContentFrame, "Floating Platform", function(enabled)
            local platform = Player.Character:FindFirstChild("DeathPlatform")
            if enabled then
                if not platform then
                    platform = Instance.new("Part")
                    platform.Name = "DeathPlatform"
                    platform.Size = Vector3.new(6,1,6)
                    platform.Anchored = true
                    platform.CanCollide = true
                    platform.Position = Player.Character.HumanoidRootPart.Position - Vector3.new(0,3,0)
                    platform.Parent = Workspace
                end
                RunService.Heartbeat:Connect(function()
                    if platform then
                        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            platform.Position = Vector3.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
                        end
                    end
                end)
            else
                if platform then platform:Destroy() end
            end
        end)
    elseif tab == "Script Hub" then
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1,0,0,30)
        info.Text = "Click a game script to open menu"
        info.BackgroundTransparency = 1
        info.TextColor3 = Color3.fromRGB(255,255,255)
        info.Parent = ContentFrame
    elseif tab == "Credits" then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.Text = "Death Client V2.0\nVersion "..Version.."\nCreated by Hunter"
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.TextScaled = true
        label.Parent = ContentFrame
    end
end

-- Initialize
Buttons["Movement"].BackgroundColor3 = Color3.fromRGB(150,0,0)
ActiveTab = "Movement"
UpdateTab()
