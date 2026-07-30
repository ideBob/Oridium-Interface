# Installation Guide

## Requirements

- A working Roblox executor (Synapse, Wave, Solara, etc.)
- Da Hood (or any game that supports the features)

---

## Method 1: Loadstring (Recommended)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ideBob/Oridium-Interface/main/Oridium.lua"))()
```

Just paste this into your executor and run it.

---

## Method 2: Manual

1. Go to the [Oridium.lua](https://github.com/ideBob/Oridium-Interface/blob/main/Oridium.lua) file
2. Click the **Raw** button
3. Copy everything
4. Paste into your executor and execute

---

## After Loading

- The UI will appear after the intro animation
- Press **End** to toggle the menu
- Your settings are automatically saved

---

## Troubleshooting

| Problem | Solution |
|--------|----------|
| Script doesn't load | Make sure your executor supports `Drawing` and `getrawmetatable` |
| UI not showing | Press the **End** key |
| Config not saving | Check if the executor allows writing files |
| Silent Aim not working | Some games require different hooks. Try toggling it on/off |

---

Need help? Open an issue on the repository.
