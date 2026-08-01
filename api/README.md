# Oridium API System

Official API for Oridium Interface.

## Load the API

```lua
local OridiumAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ideBob/Oridium-Interface/main/api/OridiumAPI.lua"))()
```

Or if you already have the main script loaded, use:

```lua
local API = getgenv().OridiumAPI
```

---

## Available Methods

### Aimbot
```lua
OridiumAPI:SetAimbot(true)
OridiumAPI:IsAimbotEnabled()
```

### Silent Aim
```lua
OridiumAPI:SetSilentAim(true)
OridiumAPI:IsSilentAimEnabled()
OridiumAPI:GetSilentTarget()
OridiumAPI:SetSilentTarget(part)
```

### High Jump
```lua
OridiumAPI:SetHighJump(true, 120)
OridiumAPI:SetJumpPower(150)
OridiumAPI:GetJumpPower()
```

### Good / Bad Boys
```lua
OridiumAPI:MarkGoodBoy(player)
OridiumAPI:MarkBadBoy(player)
OridiumAPI:UnmarkPlayer(player)
OridiumAPI:IsGoodBoy(player)
OridiumAPI:IsBadBoy(player)
OridiumAPI:GetGoodBoys()
OridiumAPI:GetBadBoys()
OridiumAPI:ClearGoodBoys()
OridiumAPI:ClearBadBoys()
```

### Anti Detection
```lua
OridiumAPI:SetAntiDetection(true)
OridiumAPI:IsAntiDetectionEnabled()
```

### ESP
```lua
OridiumAPI:SetESP(true)
OridiumAPI:IsESPEnabled()
```

### Utils
```lua
OridiumAPI:IsValidTarget(player)
OridiumAPI:GetClosestPlayer(maxDistance, fov)
OridiumAPI:GetState()
OridiumAPI:PrintState()
```

---

## Example

```lua
local API = loadstring(game:HttpGet("https://raw.githubusercontent.com/ideBob/Oridium-Interface/main/api/OridiumAPI.lua"))()

-- Enable features
API:SetSilentAim(true)
API:SetHighJump(true, 130)
API:SetAntiDetection(true)

-- Mark a player
local target = game.Players:FindFirstChild("SomePlayer")
if target then
    API:MarkBadBoy(target)
end

-- Check state
API:PrintState()
```
