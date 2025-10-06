-- Place ID: 205224386 Name: Hide and Seek Extreme

local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- ====== Tag All ====== --
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        hrp.CFrame = player.Character.HumanoidRootPart.CFrame
        task.wait(0.5)
    end
end
