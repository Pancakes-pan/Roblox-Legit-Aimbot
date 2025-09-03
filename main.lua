local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local AimbotEnabled = true
local WallCheck = true
local TeamCheck = true
local FieldOfView = 90 

local ToggleKey = Enum.KeyCode.L

local AimSmoothness = 0.5
local AimJitterAmount = 0.02

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == ToggleKey then
        AimbotEnabled = not AimbotEnabled
        print("Aimbot Toggled:", AimbotEnabled)
    end
end)

local function hasLineOfSight(target)
    if not WallCheck then return true end
    local head = target:FindFirstChild("Head")
    if not head then return false end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {localPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position), params)
    return (result and result.Instance:IsDescendantOf(target)) or (not result)
end

local function isValidTarget(target)
    local humanoid = target:FindFirstChild("Humanoid")
    local head = target:FindFirstChild("Head")
    if not humanoid or not head then return false end
    if humanoid.Health <= 0 then return false end 

    if TeamCheck and Players:GetPlayerFromCharacter(target) then
        local player = Players:GetPlayerFromCharacter(target)
        if player and player.Team == localPlayer.Team then
            return false
        end
    end
    return true
end

local function getBestTarget()
    local bestTarget = nil
    local lowestScore = math.huge

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") then
            if obj ~= localPlayer.Character and isValidTarget(obj) and hasLineOfSight(obj) then
                local pos = obj.Head.Position
                local dir = (pos - camera.CFrame.Position).Unit
                local angle = math.deg(math.acos(camera.CFrame.LookVector:Dot(dir)))

                if angle <= FieldOfView then
                    local screenPos = camera:WorldToViewportPoint(pos)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                    if dist < lowestScore then
                        lowestScore = dist
                        bestTarget = obj
                    end
                end
            end
        end
    end

    return bestTarget
end

RunService.RenderStepped:Connect(function()
    local target = getBestTarget()
    if target and AimbotEnabled then
        local currentCFrame = camera.CFrame
        local targetCFrame = CFrame.new(camera.CFrame.Position, target.Head.Position)
        
        local jitter = Vector3.new(
            (math.random() - 0.5) * AimJitterAmount,
            (math.random() - 0.5) * AimJitterAmount,
            0
        )
        
        camera.CFrame = currentCFrame:Lerp(targetCFrame * CFrame.new(jitter), AimSmoothness)
    end
end)
