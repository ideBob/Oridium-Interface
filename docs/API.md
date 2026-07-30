# Oridium Interface - API Documentation

**Version:** 1.0  
**Author:** @cuakieffer  
**Repository:** [ideBob/Oridium-Interface](https://github.com/ideBob/Oridium-Interface)

---

## Overview

Oridium Interface exposes a global table through `getgenv()` so other scripts or the user can interact with it at runtime.

```lua
getgenv().Oridium
```

---

## Global Table Structure

```lua
getgenv().Oridium = {
    SilentAim      = boolean,          -- Whether Silent Aim is currently enabled
    SilentTarget   = Instance | nil,   -- Current target BasePart (usually Head)
    AntiDetection  = boolean,          -- Whether Anti Detection is enabled
    GoodBoys       = { [number] = string },  -- UserId → PlayerName
    BadBoys        = { [number] = string },  -- UserId → PlayerName
}
```

---

## Properties

### `Oridium.SilentAim`
- **Type:** `boolean`
- **Description:** Controls whether Silent Aim is active.
- **Example:**
```lua
getgenv().Oridium.SilentAim = true
```

### `Oridium.SilentTarget`
- **Type:** `Instance?` (usually a `BasePart`, most commonly the Head)
- **Description:** The current part Silent Aim is redirecting shots toward. Automatically updated by the script.
- **Note:** Setting this manually may be overwritten by the internal target finder.

### `Oridium.AntiDetection`
- **Type:** `boolean`
- **Description:** When `true`, basic spoofing of JumpPower and WalkSpeed is active.

### `Oridium.GoodBoys`
- **Type:** `table`
- **Description:** Dictionary of players marked as Good Boys.
- **Format:** `[UserId] = PlayerName`
- **Example:**
```lua
for userId, name in pairs(getgenv().Oridium.GoodBoys) do
    print(name, "is a Good Boy")
end
```

### `Oridium.BadBoys`
- **Type:** `table`
- **Description:** Dictionary of players marked as Bad Boys.
- **Format:** `[UserId] = PlayerName`

---

## Usage Examples

### Enable Silent Aim from another script
```lua
getgenv().Oridium.SilentAim = true
```

### Check if a player is marked
```lua
local player = game.Players.SomePlayer
local oridium = getgenv().Oridium

if oridium.GoodBoys[player.UserId] then
    print(player.Name, "is a Good Boy")
elseif oridium.BadBoys[player.UserId] then
    print(player.Name, "is a Bad Boy")
else
    print(player.Name, "is Neutral")
end
```

### Manually mark a player as Bad Boy
```lua
local player = game.Players:FindFirstChild("TargetName")
if player then
    getgenv().Oridium.BadBoys[player.UserId] = player.Name
    getgenv().Oridium.GoodBoys[player.UserId] = nil
end
```

---

## Keybinds (Default)

| Feature       | Key   |
|---------------|-------|
| Aimbot        | Q     |
| ESP           | M     |
| Toggle UI     | End   |

---

## Notes

- All values in `getgenv().Oridium` are live and can be read/written at any time.
- Visual marks (crosses) are only created when using the UI buttons. Manually editing the tables will **not** automatically create the Drawing marks.
- This API is intentionally simple and designed for external scripts to integrate with Oridium.

---

*Oridium Interface - Made by @cuakieffer*
