-- ============================================================
-- Oridium Interface - API System
-- Made by @cuakieffer
-- ============================================================

local OridiumAPI = {}
OridiumAPI.__index = OridiumAPI

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Shared State
getgenv().Oridium = getgenv().Oridium or {
    SilentAim = false,
    SilentTarget = nil,
    AntiDetection = false,
    GoodBoys = {},
    BadBoys = {},
    Aimbot = false,
    ESP = false,
    HighJump = false,
    JumpPower = 100,
}

local State = getgenv().Oridium

-- ==================== UTILS ====================
function OridiumAPI:IsValidTarget(player)
    return player
        and player.Character
        and player.Character:FindFirstChild("Head")
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

function OridiumAPI:GetClosestPlayer(maxDistance, fov)
    maxDistance = maxDistance or 1000
    fov = fov or 360

    local closest, shortest = nil, math.huge
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and self:IsValidTarget(player) then
            local head = player.Character.Head
            local dist = (head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

            if dist <= maxDistance then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distFromCenter <= (fov / 2) and dist < shortest then
                        shortest = dist
                        closest = player
                    end
                end
            end
        end
    end

    return closest
end

-- ==================== AIMBOT ====================
function OridiumAPI:SetAimbot(enabled)
    State.Aimbot = enabled
    return true
end

function OridiumAPI:IsAimbotEnabled()
    return State.Aimbot
end

-- ==================== SILENT AIM ====================
function OridiumAPI:SetSilentAim(enabled)
    State.SilentAim = enabled
    if not enabled then
        State.SilentTarget = nil
    end
    return true
end

function OridiumAPI:IsSilentAimEnabled()
    return State.SilentAim
end

function OridiumAPI:GetSilentTarget()
    return State.SilentTarget
end

function OridiumAPI:SetSilentTarget(part)
    State.SilentTarget = part
end

-- ==================== HIGH JUMP ====================
function OridiumAPI:SetHighJump(enabled, power)
    State.HighJump = enabled
    if power then
        State.JumpPower = power
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if enabled then
                hum.UseJumpPower = true
                hum.JumpPower = State.JumpPower
            else
                hum.JumpPower = 50
            end
        end
    end
    return true
end

function OridiumAPI:SetJumpPower(power)
    State.JumpPower = power
    if State.HighJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = power
            end
        end
    end
    return true
end

function OridiumAPI:GetJumpPower()
    return State.JumpPower
end

-- ==================== GOOD / BAD BOYS ====================
function OridiumAPI:MarkGoodBoy(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        State.GoodBoys[player.UserId] = player.Name
        State.BadBoys[player.UserId] = nil
        return true
    end
    return false
end

function OridiumAPI:MarkBadBoy(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        State.BadBoys[player.UserId] = player.Name
        State.GoodBoys[player.UserId] = nil
        return true
    end
    return false
end

function OridiumAPI:UnmarkPlayer(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        State.GoodBoys[player.UserId] = nil
        State.BadBoys[player.UserId] = nil
        return true
    end
    return false
end

function OridiumAPI:IsGoodBoy(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return State.GoodBoys[player.UserId] ~= nil
    end
    return false
end

function OridiumAPI:IsBadBoy(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return State.BadBoys[player.UserId] ~= nil
    end
    return false
end

function OridiumAPI:GetGoodBoys()
    return State.GoodBoys
end

function OridiumAPI:GetBadBoys()
    return State.BadBoys
end

function OridiumAPI:ClearGoodBoys()
    table.clear(State.GoodBoys)
    return true
end

function OridiumAPI:ClearBadBoys()
    table.clear(State.BadBoys)
    return true
end

-- ==================== ANTI DETECTION ====================
function OridiumAPI:SetAntiDetection(enabled)
    State.AntiDetection = enabled
    return true
end

function OridiumAPI:IsAntiDetectionEnabled()
    return State.AntiDetection
end

-- ==================== ESP ====================
function OridiumAPI:SetESP(enabled)
    State.ESP = enabled
    return true
end

function OridiumAPI:IsESPEnabled()
    return State.ESP
end

-- ==================== STATE ====================
function OridiumAPI:GetState()
    return State
end

function OridiumAPI:PrintState()
    print("========== Oridium API State ==========")
    print("Aimbot:", State.Aimbot)
    print("Silent Aim:", State.SilentAim)
    print("ESP:", State.ESP)
    print("High Jump:", State.HighJump, "| Power:", State.JumpPower)
    print("Anti Detection:", State.AntiDetection)
    print("Good Boys:", #State.GoodBoys)
    print("Bad Boys:", #State.BadBoys)
    print("======================================")
end

-- ==================== INIT ====================
function OridiumAPI.new()
    local self = setmetatable({}, OridiumAPI)
    return self
end

-- Global access
getgenv().OridiumAPI = OridiumAPI.new()

return getgenv().OridiumAPI
