# 05 - Full Example

Complete example using the Oridium API.

```lua
-- Load API
local OridiumAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ideBob/Oridium-Interface/main/api/OridiumAPI.lua"))()

-- Enable features
OridiumAPI:SetSilentAim(true)
OridiumAPI:SetHighJump(true, 140)
OridiumAPI:SetAntiDetection(true)
OridiumAPI:SetESP(true)

print("Oridium API features enabled!")

-- Example: Mark the closest player as Bad Boy
task.spawn(function()
    while true do
        local closest = OridiumAPI:GetClosestPlayer(300, 150)
        if closest and not OridiumAPI:IsBadBoy(closest) and not OridiumAPI:IsGoodBoy(closest) then
            OridiumAPI:MarkBadBoy(closest)
            print("Marked", closest.Name, "as Bad Boy")
        end
        task.wait(5)
    end
end)

-- Print state every 10 seconds
task.spawn(function()
    while true do
        OridiumAPI:PrintState()
        task.wait(10)
    end
end)
```

---

## What this does

1. Loads the Oridium API
2. Enables Silent Aim, High Jump, Anti Detection, and ESP
3. Automatically marks the closest player as Bad Boy every 5 seconds
4. Prints the current API state every 10 seconds
