# 02 - Aimbot & Silent Aim

## Enable Aimbot

```lua
local OridiumAPI = getgenv().OridiumAPI or loadstring(game:HttpGet("https://raw.githubusercontent.com/ideBob/Oridium-Interface/main/api/OridiumAPI.lua"))()

OridiumAPI:SetAimbot(true)
print("Aimbot enabled:", OridiumAPI:IsAimbotEnabled())
```

## Enable Silent Aim

```lua
OridiumAPI:SetSilentAim(true)
print("Silent Aim enabled:", OridiumAPI:IsSilentAimEnabled())
```

## Get current Silent Aim target

```lua
local target = OridiumAPI:GetSilentTarget()
if target then
    print("Current target:", target.Parent.Name)
else
    print("No target")
end
```

## Manually set a Silent Aim target

```lua
local player = game.Players:FindFirstChild("SomePlayer")
if player and player.Character and player.Character:FindFirstChild("Head") then
    OridiumAPI:SetSilentTarget(player.Character.Head)
end
```

## Find closest player

```lua
local closest = OridiumAPI:GetClosestPlayer(500, 200) -- maxDistance, FOV
if closest then
    print("Closest player:", closest.Name)
end
```

## Disable them

```lua
OridiumAPI:SetAimbot(false)
OridiumAPI:SetSilentAim(false)
```
