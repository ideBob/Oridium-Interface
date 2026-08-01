# 01 - Getting Started with Oridium API

This guide teaches you how to use the Oridium API system.

---

## Step 1: Load the API

```lua
local OridiumAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ideBob/Oridium-Interface/main/api/OridiumAPI.lua"))()
```

After this line runs, you can use all API functions.

---

## Step 2: Check if it loaded

```lua
print(OridiumAPI) -- Should not be nil
OridiumAPI:PrintState()
```

---

## Step 3: Enable basic features

```lua
-- Enable Silent Aim
OridiumAPI:SetSilentAim(true)

-- Enable High Jump with 130 power
OridiumAPI:SetHighJump(true, 130)

-- Enable Anti Detection
OridiumAPI:SetAntiDetection(true)
```

---

## Step 4: Verify

```lua
OridiumAPI:PrintState()
```

You should see the features you enabled set to `true`.

---

## Next

Go to **02-Aimbot-And-SilentAim.md** to learn combat features.
