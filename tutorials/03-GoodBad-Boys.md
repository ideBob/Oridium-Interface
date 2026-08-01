# 03 - Good Boy / Bad Boy System

## Mark a player as Good Boy

```lua
local OridiumAPI = getgenv().OridiumAPI or loadstring(game:HttpGet("https://raw.githubusercontent.com/ideBob/Oridium-Interface/main/api/OridiumAPI.lua"))()

local player = game.Players:FindFirstChild("PlayerName")
if player then
    OridiumAPI:MarkGoodBoy(player)
    print(player.Name, "is now a Good Boy")
end
```

## Mark a player as Bad Boy

```lua
local player = game.Players:FindFirstChild("PlayerName")
if player then
    OridiumAPI:MarkBadBoy(player)
    print(player.Name, "is now a Bad Boy")
end
```

## Check status

```lua
local player = game.Players:FindFirstChild("PlayerName")

if OridiumAPI:IsGoodBoy(player) then
    print("Good Boy")
elseif OridiumAPI:IsBadBoy(player) then
    print("Bad Boy")
else
    print("Neutral")
end
```

## Get all marked players

```lua
print("Good Boys:")
for userId, name in pairs(OridiumAPI:GetGoodBoys()) do
    print("-", name)
end

print("Bad Boys:")
for userId, name in pairs(OridiumAPI:GetBadBoys()) do
    print("-", name)
end
```

## Unmark / Clear

```lua
OridiumAPI:UnmarkPlayer(player)
OridiumAPI:ClearGoodBoys()
OridiumAPI:ClearBadBoys()
```
