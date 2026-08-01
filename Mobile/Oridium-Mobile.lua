-- ============================================================
-- Oridium Interface - Mobile Version
-- Made by @cuakieffer
-- Optimized for Mobile Executors (Kavo UI)
-- ============================================================

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Oridium Mobile | @cuakieffer", "Ocean")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local InsertService = game:GetService("InsertService")
local VirtualInputManager = game:GetService("VirtualInputManager")

getgenv().Oridium = getgenv().Oridium or {
    SilentAim = false,
    SilentTarget = nil,
    AntiDetection = false,
    GoodBoys = {},
    BadBoys = {}
}

local function isValidTarget(player)
    return player and player.Character
        and player.Character:FindFirstChild("Head")
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

-- ==================== COMBAT TAB ====================
local CombatTab = Window:NewTab("Combat")
local CombatSection = CombatTab:NewSection("Combat")

local aimbotEnabled = false
local triggerbotEnabled = false
local smoothness = 0.2

CombatSection:NewToggle("Aimbot", "Smooth Aimbot", function(state)
    aimbotEnabled = state
end)

CombatSection:NewToggle("Silent Aim", "Redirect bullets", function(state)
    getgenv().Oridium.SilentAim = state
end)

CombatSection:NewToggle("Triggerbot", "Auto shoot", function(state)
    triggerbotEnabled = state
end)

-- ==================== VISUALS TAB ====================
local VisualsTab = Window:NewTab("Visuals")
local VisualsSection = VisualsTab:NewSection("ESP")

local espEnabled = false
local aimviewerEnabled = false

VisualsSection:NewToggle("ESP", "Box + Health + Distance", function(state)
    espEnabled = state
end)

VisualsSection:NewToggle("Aimviewer", "Show look direction", function(state)
    aimviewerEnabled = state
end)

-- ==================== PLAYER TAB ====================
local PlayerTab = Window:NewTab("Player")
local PlayerSection = PlayerTab:NewSection("Movement")

local highJumpEnabled = false
local jumpPowerValue = 100

PlayerSection:NewToggle("High Jump", "Increase JumpPower", function(state)
    highJumpEnabled = state
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if state then
                hum.UseJumpPower = true
                hum.JumpPower = jumpPowerValue
            else
                hum.JumpPower = 50
            end
        end
    end
end)

PlayerSection:NewSlider("Jump Power", "JP Value", 50, 300, function(val)
    jumpPowerValue = val
    if highJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = val end
        end
    end
end)

-- ==================== CUSTOMIZATION TAB ====================
local CustomTab = Window:NewTab("Customization")
local CustomSection = CustomTab:NewSection("Accessories (R15 Only)")

local CustomAssets = {
    {Name = "Yabujin Shirt", Id = 1350415618, Type = "Shirt"},
    {Name = "Tragedy", Id = 13702160, Type = "Face"},
    {Name = "Hair", Id = 105694273623487, Type = "Accessory"},
    {Name = "Black Eye Patch", Id = 4528880486, Type = "Accessory"},
    {Name = "Black Horns", Id = 140127383196216, Type = "Accessory"},
    {Name = "Glowing Beast Eyes", Id = 1594010, Type = "Face"},
}

local function isR15()
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.RigType == Enum.HumanoidRigType.R15
end

local function applyAsset(assetData)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local id = assetData.Id
    local assetType = assetData.Type

    if assetType == "Shirt" then
        local old = char:FindFirstChildOfClass("Shirt")
        if old then old:Destroy() end
        local shirt = Instance.new("Shirt")
        shirt.ShirtTemplate = "rbxassetid://" .. id
        shirt.Parent = char
    elseif assetType == "Face" then
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
            if face then
                face.Texture = "rbxassetid://" .. id
            end
        end
    else
        local success, model = pcall(function()
            return InsertService:LoadAsset(id)
        end)
        if success and model then
            local accessory = model:FindFirstChildOfClass("Accessory")
            if not accessory then
                for _, child in ipairs(model:GetChildren()) do
                    if child:IsA("Accessory") or child:IsA("Hat") or child:IsA("Accoutrement") then
                        accessory = child
                        break
                    end
                end
            end
            if accessory then
                humanoid:AddAccessory(accessory:Clone())
            end
            model:Destroy()
        end
    end
end

CustomSection:NewButton("Load All (R15 Only)", "Loads all items, waits 15s, then resets", function()
    if not isR15() then
        Library:Notify("Only works on R15!", 3)
        return
    end

    Library:Notify("Loading all accessories...", 3)

    for _, asset in ipairs(CustomAssets) do
        pcall(applyAsset, asset)
        task.wait(0.15)
    end

    Library:Notify("All loaded! Resetting in 15 seconds...", 3)
    task.wait(15)

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = 0
    end
end)

-- ==================== GOOD / BAD TAB ====================
local GoodBadTab = Window:NewTab("Good/Bad")
local GoodBadSection = GoodBadTab:NewSection("Mark Players")

local GoodBoys = getgenv().Oridium.GoodBoys
local BadBoys = getgenv().Oridium.BadBoys
local Marks = {}

local function createMark(player, isGood)
    if Marks[player] then
        pcall(function() Marks[player]:Remove() end)
        Marks[player] = nil
    end

    local mark = Drawing.new("Text")
    mark.Center = true
    mark.Outline = true
    mark.OutlineColor = Color3.fromRGB(0, 0, 0)
    mark.Visible = false

    if isGood then
        mark.Text = "✝"
        mark.Size = 28
        mark.Color = Color3.fromRGB(80, 255, 120)
    else
        mark.Text = "†"
        mark.Size = 32
        mark.Color = Color3.fromRGB(255, 50, 50)
    end

    Marks[player] = mark
end

local function removeMark(player)
    if Marks[player] then
        pcall(function() Marks[player]:Remove() end)
        Marks[player] = nil
    end
end

local SelectedPlayerName = nil

GoodBadSection:NewTextBox("Player Name", "Enter player name", function(txt)
    SelectedPlayerName = txt
end)

GoodBadSection:NewButton("Sign Good Boy", "Mark as Good Boy", function()
    if SelectedPlayerName then
        local player = Players:FindFirstChild(SelectedPlayerName)
        if player then
            GoodBoys[player.UserId] = player.Name
            BadBoys[player.UserId] = nil
            createMark(player, true)
            Library:Notify(player.Name .. " → Good Boy ✝", 3)
        else
            Library:Notify("Player not found", 2)
        end
    end
end)

GoodBadSection:NewButton("Sign Bad Boy", "Mark as Bad Boy", function()
    if SelectedPlayerName then
        local player = Players:FindFirstChild(SelectedPlayerName)
        if player then
            BadBoys[player.UserId] = player.Name
            GoodBoys[player.UserId] = nil
            createMark(player, false)
            Library:Notify(player.Name .. " → Bad Boy †", 3)
        else
            Library:Notify("Player not found", 2)
        end
    end
end)

-- ==================== SETTINGS TAB ====================
local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Settings")

SettingsSection:NewButton("Reset Character", "Force reset", function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)

SettingsSection:NewButton("Unload Script", "Destroy UI", function()
    Library:Destroy()
end)

-- ==================== SILENT AIM HOOK ====================
pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if getgenv().Oridium.SilentAim and getgenv().Oridium.SilentTarget then
            local target = getgenv().Oridium.SilentTarget
            if method == "Raycast" and self == workspace then
                local origin = args[1]
                args[2] = (target.Position - origin).Unit * (args[2].Magnitude or 1000)
                return old(self, unpack(args))
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                local ray = args[1]
                if typeof(ray) == "Ray" then
                    args[1] = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * 999)
                    return old(self, unpack(args))
                end
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

-- Silent Aim target finder
RunService.Heartbeat:Connect(function()
    if getgenv().Oridium.SilentAim then
        local closest, shortest = nil, math.huge
        local mousePos = UserInputService:GetMouseLocation()

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isValidTarget(player) then
                local head = player.Character.Head
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                    if dist < 200 and dist < shortest then
                        shortest = dist
                        closest = head
                    end
                end
            end
        end
        getgenv().Oridium.SilentTarget = closest
    else
        getgenv().Oridium.SilentTarget = nil
    end
end)

-- Marks update
RunService.RenderStepped:Connect(function()
    for player, mark in pairs(Marks) do
        if isValidTarget(player) then
            local headPos = player.Character.Head.Position + Vector3.new(0, 3.3, 0)
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            if onScreen then
                mark.Position = Vector2.new(screenPos.X, screenPos.Y)
                mark.Visible = true
            else
                mark.Visible = false
            end
        else
            mark.Visible = false
        end
    end
end)

print("Oridium Mobile Version Loaded successfully!")
