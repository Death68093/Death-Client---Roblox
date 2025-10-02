local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()

-- Config the client here:
local config = {
    version = "1.0.1",
    testing = false,
    saveKey = "LocalModMenuConfig",
    guiEnabled = true,
    keybinds = {
        toggleGui = Enum.KeyCode.Z,
        toggleFly = Enum.KeyCode.F,
        toggleNoclip = Enum.KeyCode.N,
        toggleInfiniteJump = Enum.KeyCode.X,
        toggleSpeed = Enum.KeyCode.C,
        toggleAirWalk = Enum.KeyCode.H,
        toggleSpider = Enum.KeyCode.G,
        toggleTrails = Enum.KeyCode.T,
        toggleESP = Enum.KeyCode.Y,
        toggleAimbot = Enum.KeyCode.U,
        saveConfig = Enum.KeyCode.P,
        activatePrompt = Enum.KeyCode.E
    },
    modules = {
        Movement = {
            Fly = {
                enabled = false,
                speed = 60,
                smooth = true
            },
            Noclip = {
                enabled = false
            },
            HighJump = {
                enabled = false,
                multiplier = 2
            },
            Speed = {
                enabled = false,
                walkspeed = 32
            },
            InfiniteJump = {
                enabled = false
            },
            Spider = {
                enabled = false,
                climbSpeed = 16
            },
            AirWalk = {
                enabled = false,
                holdHeight = 0
            }
        },
        Visual = {
            CameraZoom = {
                enabled = false,
                fov = 70,
                min = 20,
                max = 120
            },
            RainbowTrails = {
                enabled = false,
                hueSpeed = 60
            }
        },
        Utility = {
            Teleport = {
                enabled = false
            },
            AntiAFK = {
                enabled = true
            },
            SaveSystem = {
                enabled = true
            }
        },
        ESP = {
            Enabled = true,
            Box = true,
            Tracer = true,
            HealthBar = true
        },
        Aimbot = {
            Enabled = false,
            FOV = 60,
            Smoothness = 10
        },
        Invis = {
            Enabled = false,
            FakeTransparency = 0.5,
            SeatPosition = Vector3.new(0, 0, 0)
        },
        FakeMovement = {
            MaxSpeed = 20,
            Acceleration = 40,
            Gravity = 196,
            JumpPower = 60
        }
    }
}

local function saveConfig()
    local sv = player:FindFirstChild(config.saveKey)
    if not sv then
        sv = Instance.new("StringValue")
        sv.Name = config.saveKey
        sv.Parent = player
    end
    sv.Value = HttpService:JSONEncode(config)
end
local function loadConfig()
    local sv = player:FindFirstChild(config.saveKey)
    if sv and sv.Value ~= "" then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(sv.Value)
        end)
        if ok and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                config[k] = v
            end
        end
    end
end
local function rebindCharacter(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
end
player.CharacterAdded:Connect(rebindCharacter)
local bindingsEnabled = true
if config.modules.Utility.AntiAFK then
    spawn(function()
        while true do
            wait(60)
            if player and player:IsDescendantOf(game) then
                mouse.Icon = mouse.Icon
            end
        end
    end)
end
local input = {
    forward = false,
    back = false,
    left = false,
    right = false,
    up = false,
    down = false,
    jump = false,
    click = false
}
UserInputService.InputBegan:Connect(function(i, gp)
    if gp or not bindingsEnabled then
        return
    end
    if i.KeyCode == Enum.KeyCode.W then
        input.forward = true
    end
    if i.KeyCode == Enum.KeyCode.S then
        input.back = true
    end
    if i.KeyCode == Enum.KeyCode.A then
        input.left = true
    end
    if i.KeyCode == Enum.KeyCode.D then
        input.right = true
    end
    if i.KeyCode == Enum.KeyCode.E then
        input.up = true
    end
    if i.KeyCode == Enum.KeyCode.Q then
        input.down = true
    end
    if i.KeyCode == Enum.KeyCode.Space then
        input.jump = true
    end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        input.click = true
    end
    if config.keybinds.toggleFly and i.KeyCode == config.keybinds.toggleFly then
        config.modules.Movement.Fly.enabled = not config.modules.Movement.Fly.enabled
    elseif config.keybinds.toggleNoclip and i.KeyCode == config.keybinds.toggleNoclip then
        config.modules.Movement.Noclip.enabled = not config.modules.Movement.Noclip.enabled
    elseif config.keybinds.toggleSpeed and i.KeyCode == config.keybinds.toggleSpeed then
        config.modules.Movement.Speed.enabled = not config.modules.Movement.Speed.enabled
        if config.modules.Movement.Speed.enabled then
            humanoid.WalkSpeed = config.modules.Movement.bvg.walkspeed
        else
            humanoid.WalkSpeed = 16
        end
    elseif config.keybinds.toggleInfiniteJump and i.KeyCode == config.keybinds.toggleInfiniteJump then
        config.modules.Movement.InfiniteJump.enabled = not config.modules.Movement.InfiniteJump.enabled
    elseif config.keybinds.toggleAirWalk and i.KeyCode == config.keybinds.toggleAirWalk then
        config.modules.Movement.AirWalk.enabled = not config.modules.Movement.AirWalk.enabled
        if config.modules.Movement.AirWalk.enabled then
            config.modules.Movement.AirWalk.holdHeight = hrp.Position.Y
        end
    elseif config.keybinds.toggleSpider and i.KeyCode == config.keybinds.toggleSpider then
        config.modules.Movement.Spider.enabled = not config.modules.Movement.Spider.enabled
    elseif config.keybinds.toggleTrails and i.KeyCode == config.keybinds.toggleTrails then
        config.modules.Visual.RainbowTrails.enabled = not config.modules.Visual.RainbowTrails.enabled
        if config.modules.Visual.RainbowTrails.enabled then
            enableRainbowTrails()
        else
            disableRainbowTrails()
        end
    elseif config.keybinds.toggleESP and i.KeyCode == config.keybinds.toggleESP then
        config.modules.ESP.Enabled = not config.modules.ESP.Enabled
    elseif config.keybinds.toggleAimbot and i.KeyCode == config.keybinds.toggleAimbot then
        config.modules.Aimbot.Enabled = not config.modules.Aimbot.Enabled
    elseif config.keybinds.saveConfig and i.KeyCode == config.keybinds.saveConfig then
        saveConfig()
    elseif config.keybinds.activatePrompt and i.KeyCode == config.keybinds.activatePrompt then
        local function tryActivateNearestPrompt()
            local radius = 7
            local cam = workspace.CurrentCamera
            local pos = hrp.Position
            local closestPrompt = nil
            local closestDist = radius + 1
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local parentPart = prompt.Parent
                    local promptPos
                    if parentPart and parentPart:IsA("BasePart") then
                        promptPos = parentPart.Position
                    elseif prompt.Parent and prompt.Parent:IsA("Model") and prompt.Parent.PrimaryPart then
                        promptPos = prompt.Parent.PrimaryPart.Position
                    else
                        promptPos = prompt.Parent.Position or nil
                    end
                    if promptPos then
                        local d = (promptPos - pos).Magnitude
                        if d < closestDist then
                            closestDist = d
                            closestPrompt = prompt
                        end
                    end
                end
            end
            if not closestPrompt then
                return
            end
            local promptParent = closestPrompt.Parent
            pcall(function()
                if closestPrompt.Trigger then
                    closestPrompt:Trigger()
                end
            end)
            pcall(function()
                if closestPrompt.InputHoldBegin then
                    closestPrompt:InputHoldBegin()
                end
            end)
            local be = promptParent:FindFirstChild("PromptActivated")
            if be and be:IsA("BindableEvent") then
                pcall(function()
                    be:Fire(player)
                end)
            end
            local re = promptParent:FindFirstChild("PromptActivated")
            if re and re:IsA("RemoteEvent") then
                pcall(function()
                    re:FireServer()
                end)
            end
        end
        tryActivateNearestPrompt()
    end
end)
UserInputService.InputEnded:Connect(function(i, gp)
    if gp then
        return
    end
    if i.KeyCode == Enum.KeyCode.W then
        input.forward = false
    end
    if i.KeyCode == Enum.KeyCode.S then
        input.back = false
    end
    if i.KeyCode == Enum.KeyCode.A then
        input.left = false
    end
    if i.KeyCode == Enum.KeyCode.D then
        input.right = false
    end
    if i.KeyCode == Enum.KeyCode.E then
        input.up = false
    end
    if i.KeyCode == Enum.KeyCode.Q then
        input.down = false
    end
    if i.KeyCode == Enum.KeyCode.Space then
        input.jump = false
    end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        input.click = false
    end
end)
UserInputService.JumpRequest:Connect(function()
    if config.modules.Movement.InfiniteJump.enabled then
        if not isInvisActive then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        else
            fakeVerticalVel = math.max(fakeVerticalVel, config.modules.FakeMovement.JumpPower or 50)
        end
    end
end)
local flyVelocity = Vector3.new(0, 0, 0)
local function updateFly(dt, root)
    if not config.modules.Movement.Fly.enabled then
        return
    end
    local speed = config.modules.Movement.Fly.speed or 50
    local dir = Vector3.new(0, 0, 0)
    local cam = workspace.CurrentCamera
    local look = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    if input.forward then
        dir = dir + Vector3.new(look.X, 0, look.Z)
    end
    if input.back then
        dir = dir - Vector3.new(look.X, 0, look.Z)
    end
    if input.right then
        dir = dir + Vector3.new(right.X, 0, right.Z)
    end
    if input.left then
        dir = dir - Vector3.new(right.X, 0, right.Z)
    end
    if input.up then
        dir = dir + Vector3.new(0, 1, 0)
    end
    if input.down then
        dir = dir - Vector3.new(0, 1, 0)
    end
    if dir.Magnitude > 0 then
        dir = dir.Unit
    end
    local targetVel = dir * speed
    if config.modules.Movement.Fly.smooth then
        flyVelocity = flyVelocity:Lerp(targetVel, math.min(1, dt * 8))
    else
        flyVelocity = targetVel
    end
    local newCFrame = root.CFrame + flyVelocity * dt
    if root:IsA("BasePart") then
        root.Velocity = Vector3.new(0, 0, 0)
        root.CFrame = CFrame.new(newCFrame.Position, newCFrame.Position + cam.CFrame.LookVector)
    else
        root.CFrame = CFrame.new(newCFrame.Position, newCFrame.Position + cam.CFrame.LookVector)
    end
end
local function setModelCanCollide(model, value)
    if not model then
        return
    end
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = value
        end
    end
end
local airBody
local function enableAirWalk(root)
    if airBody then
        airBody:Destroy()
    end
    airBody = Instance.new("BodyPosition")
    airBody.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    airBody.P = 1e4
    airBody.Position = Vector3.new(root.Position.X, config.modules.Movement.AirWalk.holdHeight or root.Position.Y,
        root.Position.Z)
    airBody.Parent = root
end
local function disableAirWalk()
    if airBody then
        airBody:Destroy()
        airBody = nil
    end
end
local lastTouched = nil
hrp.Touched:Connect(function(part)
    if part and part:IsA("BasePart") then
        lastTouched = part
        delay(0.2, function()
            lastTouched = nil
        end)
    end
end)
local function handleSpider(dt, root)
    if not config.modules.Movement.Spider.enabled then
        return
    end
    if lastTouched then
        local climb = Vector3.new(0, config.modules.Movement.Spider.climbSpeed or 12, 0)
        root.Velocity = Vector3.new(root.Velocity.X, climb.Y, root.Velocity.Z)
    end
end
local function handleSpeed(activeHumanoid)
    if config.modules.Movement.Speed.enabled then
        if activeHumanoid then
            activeHumanoid.WalkSpeed = config.modules.Movement.Speed.walkspeed
        end
    else
        if activeHumanoid then
            activeHumanoid.WalkSpeed = 16
        end
    end
end
local function applyCameraZoom()
    if config.modules.Visual.CameraZoom.enabled then
        workspace.CurrentCamera.FieldOfView = config.modules.Visual.CameraZoom.fov or 70
    end
end
local function setHighJump(enabled)
    if enabled then
        humanoid.JumpPower = (humanoid.JumpPower or 50) * config.modules.Movement.HighJump.multiplier
    else
        humanoid.JumpPower = 50
    end
end
local trailParts = {}
local hue = 0
function enableRainbowTrails()
    for _, t in pairs(trailParts) do
        if t and t.Parent then
            t:Destroy()
        end
    end
    trailParts = {}
    for _, limb in ipairs({"LeftArm", "RightArm", "LeftLeg", "RightLeg", "Head", "HumanoidRootPart"}) do
        local part = character:FindFirstChild(limb, true)
        if part and part:IsA("BasePart") then
            local a0 = Instance.new("Attachment", part)
            local a1 = Instance.new("Attachment", part)
            a1.Position = Vector3.new(0, -0.5, 0)
            local tr = Instance.new("Trail")
            tr.Attachment0 = a0
            tr.Attachment1 = a1
            tr.Parent = part
            tr.Lifetime = 0.4
            tr.Transparency = NumberSequence.new(0)
            tr.MinLength = 0.1
            table.insert(trailParts, tr)
        end
    end
end
function disableRainbowTrails()
    for _, t in pairs(trailParts) do
        if t then
            t:Destroy()
        end
    end
    trailParts = {}
end
local function updateRainbow(dt)
    if not config.modules.Visual.RainbowTrails.enabled then
        return
    end
    hue = (hue + (config.modules.Visual.RainbowTrails.hueSpeed or 60) * dt) % 360
    for _, tr in pairs(trailParts) do
        if tr and tr:IsA("Trail") then
            tr.Color =
                ColorSequence.new(Color3.fromHSV(hue / 360, 1, 1), Color3.fromHSV(((hue + 60) % 360) / 360, 1, 1))
        end
    end
end
local espBoxes = {}
local function clearESP()
    for _, gui in pairs(espBoxes) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    espBoxes = {}
end
local function updateESP()
    if not config.modules.ESP.Enabled then
        clearESP()
        return
    end
    local cam = workspace.CurrentCamera
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hr = plr.Character.HumanoidRootPart
            local onScreen, x, y = cam:WorldToViewportPoint(hr.Position)
            if onScreen then
                local gui = espBoxes[plr]
                if not gui or not gui.Parent then
                    local sg = player:WaitForChild("PlayerGui")
                    local frame = Instance.new("Frame", sg)
                    frame.Size = UDim2.new(0, 80, 0, 20)
                    frame.BackgroundTransparency = 0.5
                    frame.BorderSizePixel = 0
                    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    local txt = Instance.new("TextLabel", frame)
                    txt.Size = UDim2.new(1, 1, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.Text = plr.Name
                    txt.TextColor3 = Color3.fromRGB(255, 200, 200)
                    txt.TextScaled = true
                    espBoxes[plr] = frame
                end
                local frame = espBoxes[plr]
                frame.Position = UDim2.new(0, x - 40, 0, y - 10)
            else
                if espBoxes[plr] and espBoxes[plr].Parent then
                    espBoxes[plr]:Destroy()
                    espBoxes[plr] = nil
                end
            end
        end
    end
end
local function findClosestPlayer()
    local closest = nil
    local minAng = config.modules.Aimbot.FOV
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hr = plr.Character.HumanoidRootPart
            local onScreen, x, y = cam:WorldToViewportPoint(hr.Position)
            if onScreen then
                local angle = (Vector2.new(x, y) - center).Magnitude
                if angle < minAng then
                    minAng = angle
                    closest = hr
                end
            end
        end
    end
    return closest
end
local function updateAimbot(dt)
    if not config.modules.Aimbot.Enabled then
        return
    end
    local target = findClosestPlayer()
    if target then
        local cam = workspace.CurrentCamera
        local dir = (target.Position - cam.CFrame.Position).Unit
        local targetCFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + dir)
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, math.clamp(dt * config.modules.Aimbot.Smoothness, 0, 1))
    end
end
local fakeModel = nil
local fakeHumanoid = nil
local fakeHRP = nil
local fakeVelocity = Vector3.new(0, 0, 0)
local fakeVerticalVel = 0
local prevCameraSubject = nil
local realAnchoredParts = {}
local isInvisActive = false
local function anchorRealParts(val)
    if not character then
        return
    end
    for _, p in pairs(character:GetDescendants()) do
        if p:IsA("BasePart") then
            if val then
                realAnchoredParts[p] = {
                    Anchored = p.Anchored,
                    CanCollide = p.CanCollide
                }
                p.Anchored = true
                p.CanCollide = false
            else
                if realAnchoredParts[p] then
                    p.Anchored = realAnchoredParts[p].Anchored
                    p.CanCollide = realAnchoredParts[p].CanCollide
                else
                    p.Anchored = false
                    p.CanCollide = true
                end
                realAnchoredParts[p] = nil
            end
        end
    end
end
local function cloneToolsToFake()
    if not fakeModel then
        return
    end
    for _, child in pairs(fakeModel:GetChildren()) do
        if child.Name == "__ToolClone" then
            child:Destroy()
        end
    end
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        return
    end
    local cloneTool = tool:Clone()
    cloneTool.Name = "__ToolClone"
    cloneTool.Parent = fakeModel
    local handle = cloneTool:FindFirstChild("Handle", true)
    if handle and fakeHRP then
        handle.CFrame = fakeHRP.CFrame * CFrame.new(0, 0, -1)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = fakeHRP
        weld.Part1 = handle
        weld.Parent = handle
    end
end
local function tryActivateTool()
    local realTool = character:FindFirstChildOfClass("Tool")
    if realTool then
        pcall(function()
            realTool:Activate()
        end)
    end
    local cloneTool = fakeModel and fakeModel:FindFirstChild("__ToolClone")
    if cloneTool then
        pcall(function()
            cloneTool:Activate()
        end)
    end
end
local function enableInvis()
    if fakeModel then
        return
    end
    isInvisActive = true
    fakeModel = Instance.new("Model")
    fakeModel.Name = player.Name .. "_Fake"
    fakeModel.Parent = workspace
    local partMap = {}
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local cp = Instance.new(part.ClassName)
            cp.Size = part.Size
            cp.CFrame = part.CFrame
            cp.Anchored = false
            cp.CanCollide = not config.modules.Movement.Noclip.enabled
            cp.Transparency = config.modules.Invis.FakeTransparency
            cp.Name = part.Name
            cp.Parent = fakeModel
            partMap[part.Name] = cp
        end
    end
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.CFrame = hrp.CFrame
    root.Anchored = false
    root.Transparency = config.modules.Invis.FakeTransparency
    root.CanCollide = not config.modules.Movement.Noclip.enabled
    root.Parent = fakeModel
    fakeModel.PrimaryPart = root
    local hum = Instance.new("Humanoid")
    hum.Parent = fakeModel
    fakeHumanoid = hum
    fakeHRP = fakeModel.PrimaryPart
    prevCameraSubject = workspace.CurrentCamera.CameraSubject
    workspace.CurrentCamera.CameraSubject = fakeHumanoid
    anchorRealParts(true)
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.PlatformStand = true
    fakeVelocity = Vector3.new(0, 0, 0)
    fakeVerticalVel = 0
    cloneToolsToFake()
end
local function disableInvis()
    if not fakeModel then
        return
    end
    isInvisActive = false
    if fakeModel.PrimaryPart then
        pcall(function()
            hrp.CFrame = CFrame.new(fakeModel.PrimaryPart.Position + Vector3.new(0, 3, 0))
        end)
    end
    if prevCameraSubject then
        workspace.CurrentCamera.CameraSubject = prevCameraSubject
        prevCameraSubject = nil
    end
    if fakeModel and fakeModel.Parent then
        fakeModel:Destroy()
        fakeModel = nil
    end
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    humanoid.PlatformStand = false
    anchorRealParts(false)
end
local function teleportTo(targetPos)
    if not targetPos then
        return
    end
    pcall(function()
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    end)
end
local function disableAll()
    for _, m in pairs(config.modules.Movement) do
        if type(m) == "table" and m.enabled ~= nil then
            m.enabled = false
        end
    end
    config.modules.Visual.RainbowTrails.enabled = false
    disableRainbowTrails()
    config.modules.ESP.Enabled = false
    config.modules.Aimbot.Enabled = false
    config.modules.Invis.Enabled = false
    disableInvis()
    for k, _ in pairs(config.keybinds) do
        config.keybinds[k] = nil
    end
    bindingsEnabled = false
end
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.IgnoreGuiInset = true
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 480)
frame.Position = UDim2.new(0.5, -150, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderColor3 = Color3.fromRGB(200, 0, 0)
frame.Active = true
frame.Draggable = true
local header = Instance.new("TextButton", frame)
header.Size = UDim2.new(1, 0, 0, 28)
header.Position = UDim2.new(0, 0, 0, 0)
header.Text = "Mod Menu"
header.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.SourceSansBold
header.TextSize = 18
header.AutoButtonColor = false
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 60, 0, 22)
minimizeBtn.Position = UDim2.new(1, -190, 0, 3)
minimizeBtn.Text = "Minimize"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 60, 0, 22)
closeBtn.Position = UDim2.new(1, -120, 0, 3)
closeBtn.Text = "Close"
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
local saveBtn = Instance.new("TextButton", frame)
saveBtn.Size = UDim2.new(0, 80, 0, 22)
saveBtn.Position = UDim2.new(1, -60, 0, 3)
saveBtn.Text = "Save"
saveBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
saveBtn.TextColor3 = Color3.new(1, 1, 1)
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, c in pairs(frame:GetChildren()) do
        if (c:IsA("TextButton") or c:IsA("TextLabel")) and c ~= header and c ~= minimizeBtn and c ~= closeBtn and c ~=
            saveBtn then
            c.Visible = not minimized
        end
    end
end)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    disableAll()
end)
saveBtn.MouseButton1Click:Connect(function()
    saveConfig()
end)
local y = 34
local function addToggleLabel(text, getter, setter)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.48, 0, 0, 26)
    btn.Position = UDim2.new(0, 6, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.AutoButtonColor = false
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.48, 0, 0, 26)
    lbl.Position = UDim2.new(0.52, -6, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Text = tostring(getter())
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        lbl.Text = tostring(getter())
        if text == "Air Walk" and getter() then
            config.modules.Movement.AirWalk.holdHeight = hrp.Position.Y
        end
        if text == "High Jump" then
            setHighJump(getter())
        end
        if text == "Rainbow Trails" then
            if getter() then
                enableRainbowTrails()
            else
                disableRainbowTrails()
            end
        end
        if text == "Invisibility" and getter() then
            enableInvis()
        else
            disableInvis()
        end
    end)
    y = y + 30
end
addToggleLabel("Fly", function()
    return config.modules.Movement.Fly.enabled
end, function(v)
    config.modules.Movement.Fly.enabled = v
end)
addToggleLabel("Noclip", function()
    return config.modules.Movement.Noclip.enabled
end, function(v)
    config.modules.Movement.Noclip.enabled = v
end)
addToggleLabel("Infinite Jump", function()
    return config.modules.Movement.InfiniteJump.enabled
end, function(v)
    config.modules.Movement.InfiniteJump.enabled = v
end)
addToggleLabel("Air Walk", function()
    return config.modules.Movement.AirWalk.enabled
end, function(v)
    config.modules.Movement.AirWalk.enabled = v
end)
addToggleLabel("Speed", function()
    return config.modules.Movement.Speed.enabled
end, function(v)
    config.modules.Movement.Speed.enabled = v
end)
addToggleLabel("Spider", function()
    return config.modules.Movement.Spider.enabled
end, function(v)
    config.modules.Movement.Spider.enabled = v
end)
addToggleLabel("High Jump", function()
    return config.modules.Movement.HighJump.enabled
end, function(v)
    config.modules.Movement.HighJump.enabled = v
end)
addToggleLabel("Rainbow Trails", function()
    return config.modules.Visual.RainbowTrails.enabled
end, function(v)
    config.modules.Visual.RainbowTrails.enabled = v
end)
addToggleLabel("ESP", function()
    return config.modules.ESP.Enabled
end, function(v)
    config.modules.ESP.Enabled = v
end)
addToggleLabel("Aim Assist", function()
    return config.modules.Aimbot.Enabled
end, function(v)
    config.modules.Aimbot.Enabled = v
end)
addToggleLabel("Invisibility", function()
    return config.modules.Invis.Enabled
end, function(v)
    config.modules.Invis.Enabled = v
end)
local tpLabel = Instance.new("TextLabel", frame)
tpLabel.Size = UDim2.new(1, -12, 0, 20)
tpLabel.Position = UDim2.new(0, 6, 0, y)
tpLabel.BackgroundTransparency = 1
tpLabel.Text = "Teleport To Player"
tpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
y = y + 24
local function refreshTeleportList()
    for _, c in pairs(frame:GetChildren()) do
        if c.Name == "TPBtn" then
            c:Destroy()
        end
    end
    local yy = y
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local b = Instance.new("TextButton", frame)
            b.Name = "TPBtn"
            b.Size = UDim2.new(1, -12, 0, 20)
            b.Position = UDim2.new(0, 6, 0, yy)
            b.Text = plr.Name
            b.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
            b.TextColor3 = Color3.new(1, 1, 1)
            b.AutoButtonColor = false
            b.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    teleportTo(plr.Character.HumanoidRootPart.Position)
                end
            end)
            yy = yy + 22
        end
    end
end

Players.PlayerAdded:Connect(function()
    refreshTeleportList()
end)
Players.PlayerRemoving:Connect(function()
    refreshTeleportList()
end)
refreshTeleportList()
local function tryToggleGUI()
    if not bindingsEnabled then
        return
    end
    if config.keybinds.toggleGui then
        frame.Visible = not frame.Visible
    end
end
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then
        return
    end
    if inp.KeyCode == config.keybinds.toggleGui then
        tryToggleGUI()
    end
end)

local function updateFakeMovement(dt)
    if not fakeHRP then
        return
    end
    local cam = workspace.CurrentCamera
    local look = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    local dir = Vector3.new(0, 0, 0)
    if input.forward then
        dir = dir + Vector3.new(look.X, 0, look.Z)
    end
    if input.back then
        dir = dir - Vector3.new(look.X, 0, look.Z)
    end
    if input.right then
        dir = dir + Vector3.new(right.X, 0, right.Z)
    end
    if input.left then
        dir = dir - Vector3.new(right.X, 0, right.Z)
    end
    local cfgM = config.modules.FakeMovement
    local maxSpeed = cfgM.MaxSpeed or 20
    local accel = cfgM.Acceleration or 40
    local gravity = cfgM.Gravity or 196
    local jumpPower = cfgM.JumpPower or 60
    if config.modules.Movement.Fly.enabled then
        if input.up then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if input.down then
            dir = dir - Vector3.new(0, 1, 0)
        end
        if dir.Magnitude > 0 then
            dir = dir.Unit
        end
        local targetVel = dir * ((config.modules.Movement.Fly.speed) or maxSpeed)
        fakeVelocity = fakeVelocity:Lerp(targetVel, math.clamp(accel * dt / maxSpeed, 0, 1))
        local newPos = fakeHRP.Position + fakeVelocity * dt
        fakeHRP.CFrame = CFrame.new(newPos, newPos + cam.CFrame.LookVector)
    else
        local targetVel = Vector3.new(0, 0, 0)
        if dir.Magnitude > 0 then
            dir = dir.Unit
            targetVel = Vector3.new(dir.X * maxSpeed, 0, dir.Z * maxSpeed)
        end
        fakeVelocity = fakeVelocity:Lerp(Vector3.new(targetVel.X, 0, targetVel.Z),
            math.clamp(accel * dt / maxSpeed, 0, 1))
        if input.jump then
            fakeVerticalVel = math.max(fakeVerticalVel, jumpPower)
        end
        fakeVerticalVel = fakeVerticalVel - (gravity * dt)
        local proposed = fakeHRP.Position + Vector3.new(fakeVelocity.X, fakeVerticalVel * dt, fakeVelocity.Z)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {fakeModel}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        local ray = Workspace:Raycast(proposed, Vector3.new(0, -5, 0), rayParams)
        local finalPos = proposed
        if ray then
            finalPos = Vector3.new(proposed.X, ray.Position.Y + 2, proposed.Z)
            fakeVerticalVel = 0
        end
        fakeHRP.CFrame = CFrame.new(finalPos, finalPos + cam.CFrame.LookVector)
    end
    cloneToolsToFake()
    if input.click then
        tryActivateTool()
    end
end

RunService.RenderStepped:Connect(function(dt)
    if not character or not humanoid or not hrp then
        return
    end
    if not isInvisActive then
        if config.modules.Movement.Fly.enabled then
            humanoid.PlatformStand = true
            updateFly(dt, hrp)
        else
            humanoid.PlatformStand = false
        end
        if config.modules.Movement.Noclip.enabled then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        if config.modules.Movement.AirWalk.enabled then
            if not airBody then
                enableAirWalk(hrp)
            end
            airBody.Position = Vector3.new(hrp.Position.X, config.modules.Movement.AirWalk.holdHeight or hrp.Position.Y,
                hrp.Position.Z)
        else
            disableAirWalk()
        end
        handleSpider(dt, hrp)
        handleSpeed(humanoid)
        applyCameraZoom()
        if config.modules.Movement.HighJump.enabled then
            setHighJump(true)
        end
    else
        if config.modules.Movement.Noclip.enabled then
            setModelCanCollide(fakeModel, false)
        else
            setModelCanCollide(fakeModel, true)
        end
        if config.modules.Movement.AirWalk.enabled then
            if not airBody then
                enableAirWalk(fakeHRP)
            end
            airBody.Position = Vector3.new(fakeHRP.Position.X,
                config.modules.Movement.AirWalk.holdHeight or fakeHRP.Position.Y, fakeHRP.Position.Z)
        else
            disableAirWalk()
        end
        updateFakeMovement(dt)
        handleSpider(dt, fakeHRP)
        handleSpeed(fakeHumanoid)
        applyCameraZoom()
    end
    updateRainbow(dt)
    updateESP()
    updateAimbot(dt)
end)
loadConfig()
