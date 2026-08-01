# 04 - High Jump & Utilities

## Enable High Jump

```lua
local OridiumAPI = getgenv().OridiumAPI or loadstring(game:HttpGet("https://raw.githubusercontent.com/ideBob/Oridium-Interface/main/api/OridiumAPI.lua"))()

-- Enable with custom power
OridiumAPI:SetHighJump(true, 150)
```

## Change Jump Power later

```lua
OridiumAPI:SetJumpPower(200)
print("Current JumpPower:", OridiumAPI:GetJumpPower())
```

## Disable High Jump

```lua
OridiumAPI:SetHighJump(false)
```

## Useful Utilities

### Check if a player is valid
```lua
local player = game.Players:FindFirstChild("Someone")
if OridiumAPI:IsValidTarget(player) then
    print("Valid target")
end
```

### Get closest player
```lua
local closest = OridiumAPI:GetClosestPlayer(800, 250)
if closest then
    print("Closest:", closest.Name)
end
```

### Print full state
```lua
OridiumAPI:PrintState()
```

### Get raw state table
```lua
local state = OridiumAPI:GetState()
print(state.SilentAim)
print(state.JumpPower)
```
