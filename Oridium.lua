-- ============================================================
-- Servo.cc
-- Made by @cuakieffer
-- UI: Neverlose-style library (migrated from Linoria)
-- ============================================================

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ImInsane-1337/neverlose-ui/refs/heads/main/source/library.lua"))()

Library.Folders = {
    Directory = "ServoCC",
    Configs = "ServoCC/Configs",
    Assets = "ServoCC/Assets",
}

local ACCENT = Color3.fromRGB(100, 180, 255)
local ACCENT_GRAD = Color3.fromRGB(40, 100, 180)
Library.Theme.Accent = ACCENT
Library.Theme.AccentGradient = ACCENT_GRAD
pcall(function()
    Library:ChangeTheme("Accent", ACCENT)
    Library:ChangeTheme("AccentGradient", ACCENT_GRAD)
end)

Library.MenuKeybind = tostring(Enum.KeyCode.End)
Library.LogsEnabled = true

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== STATE ====================
getgenv().Servo = getgenv().Servo or {
    SilentAim = false,
    SilentTarget = nil,
    AntiDetection = false,
}

local State = {
    Aimbot = false,
    Triggerbot = false,
    ESP = false,
    ESPPreview = false,
    ServoLines = false,
    Aimviewer = false,
    HighJump = false,
    AntiDetection = false,
    RGB = false,
    JumpPower = 100,
    AimbotFOV = 360,
    AimbotRange = 1000,
    Smoothness = 0.18,
    TriggerFOV = 70,
    TriggerCooldown = 0.28,
    LastTrigger = 0,
    CurrentTarget = nil,
}

local Connections = {}
local function bind(name, conn)
    if Connections[name] then Connections[name]:Disconnect() end
    Connections[name] = conn
    return conn
end
local function unbind(name)
    if Connections[name] then Connections[name]:Disconnect() Connections[name] = nil end
end
local function unbindAll()
    for n, c in pairs(Connections) do pcall(function() c:Disconnect() end) Connections[n] = nil end
end

-- Local character cache
local LocalChar, LocalHum, LocalHRP
local function refreshLocalCharacter(char)
    LocalChar = char
    LocalHum = char and char:FindFirstChildOfClass("Humanoid") or nil
    LocalHRP = char and char:FindFirstChild("HumanoidRootPart") or nil
end
if LocalPlayer.Character then refreshLocalCharacter(LocalPlayer.Character) end

local applyJumpPower -- forward declare

bind("LocalCharacterAdded", LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.35)
    refreshLocalCharacter(char)
    task.defer(function()
        if State.HighJump and applyJumpPower then applyJumpPower() end
    end)
end))
bind("LocalCharacterRemoving", LocalPlayer.CharacterRemoving:Connect(function()
    LocalChar, LocalHum, LocalHRP = nil, nil, nil
end))

-- Camera / viewport cache
local ViewportCenter = Vector2.new(0, 0)
local function refreshCamera()
    Camera = workspace.CurrentCamera
    if not Camera then return end
    local size = Camera.ViewportSize
    ViewportCenter = Vector2.new(size.X * 0.5, size.Y * 0.5)
end
refreshCamera()
bind("CameraChanged", workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshCamera))
if Camera then
    bind("ViewportChanged", Camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshCamera))
end

-- ==================== WINDOW ====================
local Window = Library:Window({
    Name = "Servo.cc",
    SubName = "by @cuakieffer",
    Logo = "0",
})

local KeybindList = nil
pcall(function() KeybindList = Library:KeybindList("Keybinds") end)
pcall(function() Library:Watermark({ "Servo.cc", "by @cuakieffer" }) end)

Window:Category("Combat")
local BlatantPage = Window:Page({ Name = "Blatant", Icon = "0" })
local CombatSection = BlatantPage:Section({ Name = "Combat", Side = 1 })
local TriggerSection = BlatantPage:Section({ Name = "Triggerbot", Side = 2 })

Window:Category("Visuals")
local VisualsPage = Window:Page({ Name = "Visuals", Icon = "0" })
local ESPSection = VisualsPage:Section({ Name = "ESP", Side = 1 })
local AimviewerSection = VisualsPage:Section({ Name = "Aimviewer", Side = 2 })

Window:Category("Player")
local PlayerPage = Window:Page({ Name = "Player", Icon = "0" })
local MovementSection = PlayerPage:Section({ Name = "Movement", Side = 1 })
local AntiSection = PlayerPage:Section({ Name = "Anti Detection", Side = 2 })

local function notify(title, desc, duration)
    pcall(function()
        Library:Notification({
            Title = title or "Servo.cc",
            Description = desc or "",
            Duration = duration or 4,
        })
    end)
end

task.defer(function()
    notify("Servo.cc", "Thank You For Executing Servo.cc", 5)
end)

-- ==================== HELPERS ====================
local lightBlue = ACCENT

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return head and hum and hrp and hum.Health > 0
end

local function getTargetParts(player)
    local char = player and player.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if head and hum and hrp and hum.Health > 0 then
        return char, head, hum, hrp
    end
    return nil
end

-- ==================== DRAWING ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = lightBlue
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Radius = 180
FOVCircle.Filled = false
FOVCircle.Visible = false

local SnapLine = Drawing.new("Line")
SnapLine.Color = lightBlue
SnapLine.Thickness = 1.8
SnapLine.Visible = false

local HeadDot = Drawing.new("Circle")
HeadDot.Color = lightBlue
HeadDot.Thickness = 1
HeadDot.NumSides = 16
HeadDot.Radius = 3
HeadDot.Filled = true
HeadDot.Visible = false

local TriggerFOVCircle = Drawing.new("Circle")
TriggerFOVCircle.Color = Color3.fromRGB(255, 80, 80)
TriggerFOVCircle.Thickness = 1.5
TriggerFOVCircle.NumSides = 48
TriggerFOVCircle.Radius = 70
TriggerFOVCircle.Filled = false
TriggerFOVCircle.Visible = false

local function hideAimbotVisuals()
    SnapLine.Visible = false
    HeadDot.Visible = false
end

-- ==================== SILENT AIM (Da Hood) ====================
local DA_HOOD = {
    [2788229376] = true,
    [7213786345] = true,
    [9825515356] = true,
}

local function isDaHood()
    return DA_HOOD[game.PlaceId] == true
end

pcall(function()
    if not hookmetamethod or not newcclosure or not getnamecallmethod then return end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if getgenv().Servo.SilentAim and isDaHood() and method == "FireServer" then
            local target = getgenv().Servo.SilentTarget
            if target and target.Parent then
                if typeof(self) == "Instance" and (self.Name == "MainEvent" or self.Name == "MainEvent") then
                    local action = args[1]
                    if action == "Shoot" or action == "ShootGun" or action == "MousePos" or action == "Cursor" then
                        for i = 2, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = target.Position
                            end
                        end
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end))
end)

local function getClosestSilentTarget()
    if not LocalHRP or not Camera then return nil end
    local closest, closestDist = nil, math.huge
    local origin = LocalHRP.Position
    local fovR = State.AimbotFOV * 0.5
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValidTarget(plr) then
            local _, head, _, hrp = getTargetParts(plr)
            if head and hrp then
                local dist = (hrp.Position - origin).Magnitude
                if dist <= State.AimbotRange then
                    local screen, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local fovDist = (Vector2.new(screen.X, screen.Y) - ViewportCenter).Magnitude
                        if fovDist <= fovR and dist < closestDist then
                            closest = head
                            closestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

bind("SilentTargetUpdater", RunService.Heartbeat:Connect(function()
    if getgenv().Servo.SilentAim then
        getgenv().Servo.SilentTarget = getClosestSilentTarget()
    else
        getgenv().Servo.SilentTarget = nil
    end
end))

CombatSection:Toggle({
    Name = "Silent Aim",
    Flag = "SilentAim",
    Default = false,
    Callback = function(v)
        if v and not isDaHood() then
            notify("Silent Aim", "Only works on Da Hood", 3)
            getgenv().Servo.SilentAim = false
            return
        end
        getgenv().Servo.SilentAim = v
        if not v then getgenv().Servo.SilentTarget = nil end
    end
})

-- ==================== AIMBOT ====================
local function getClosestPlayer()
    if not Camera or not LocalHRP then return nil end
    local closest, shortest = nil, State.AimbotRange
    local fovRadius = State.AimbotFOV * 0.5
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local _, head = getTargetParts(player)
            if head then
                local screen, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screen.X, screen.Y) - ViewportCenter).Magnitude
                    local worldDist = (head.Position - LocalHRP.Position).Magnitude
                    if dist <= fovRadius and worldDist < shortest then
                        shortest = worldDist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

CombatSection:Toggle({
    Name = "Aimbot",
    Flag = "Aimbot",
    Default = false,
    Callback = function(v)
        State.Aimbot = v
        FOVCircle.Visible = v or getgenv().Servo.SilentAim
        if not v then hideAimbotVisuals() end
    end
})

CombatSection:Slider({
    Name = "Aimbot FOV",
    Flag = "AimbotFOV",
    Min = 50, Max = 800, Default = 360, Decimals = 0,
    Callback = function(v)
        State.AimbotFOV = v
        FOVCircle.Radius = v * 0.5
    end
})

CombatSection:Slider({
    Name = "Aimbot Range",
    Flag = "AimbotRange",
    Min = 50, Max = 3000, Default = 1000, Decimals = 0,
    Callback = function(v) State.AimbotRange = v end
})

CombatSection:Slider({
    Name = "Smoothness",
    Flag = "Smoothness",
    Min = 0.05, Max = 1, Default = 0.18, Decimals = 2,
    Callback = function(v) State.Smoothness = v end
})

-- ==================== TRIGGERBOT ====================
local TRIGGER_WEAPONS = {
    ["[Revolver]"] = true, ["[Double-Barrel SG]"] = true,
    ["Revolver"] = true, ["Double-Barrel SG"] = true,
}

local function hasTriggerWeapon()
    local tool = LocalChar and LocalChar:FindFirstChildOfClass("Tool")
    return tool and TRIGGER_WEAPONS[tool.Name] == true
end

local function triggerbotTick()
    if not State.Triggerbot or not hasTriggerWeapon() then return end
    if tick() - State.LastTrigger < State.TriggerCooldown then return end
    local target = getClosestPlayer()
    if not target then return end
    local _, head = getTargetParts(target)
    if not head then return end
    local screen, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return end
    local dist = (Vector2.new(screen.X, screen.Y) - ViewportCenter).Magnitude
    if dist <= State.TriggerFOV then
        State.LastTrigger = tick()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

TriggerSection:Toggle({
    Name = "Triggerbot",
    Flag = "Triggerbot",
    Default = false,
    Callback = function(v)
        State.Triggerbot = v
        TriggerFOVCircle.Visible = v
    end
})

TriggerSection:Slider({
    Name = "Trigger FOV",
    Flag = "TriggerFOV",
    Min = 20, Max = 150, Default = 70, Decimals = 0,
    Callback = function(v)
        State.TriggerFOV = v
        TriggerFOVCircle.Radius = v
    end
})

TriggerSection:Slider({
    Name = "Cooldown",
    Flag = "TriggerCooldown",
    Min = 0.1, Max = 1, Default = 0.28, Decimals = 2,
    Callback = function(v) State.TriggerCooldown = v end
})

-- ==================== HIGH JUMP ====================
applyJumpPower = function()
    if not LocalChar then refreshLocalCharacter(LocalPlayer.Character) end
    local hum = LocalHum or (LocalChar and LocalChar:FindFirstChildOfClass("Humanoid"))
    if not hum then return end
    if State.HighJump then
        hum.UseJumpPower = true
        hum.JumpPower = State.JumpPower
        pcall(function() hum.JumpHeight = State.JumpPower / 3.5 end)
    else
        hum.JumpPower = 50
        pcall(function() hum.JumpHeight = 7.2 end)
    end
end

MovementSection:Toggle({
    Name = "High Jump",
    Flag = "HighJump",
    Default = false,
    Callback = function(v)
        State.HighJump = v
        applyJumpPower()
    end
})

MovementSection:Slider({
    Name = "Jump Power",
    Flag = "JumpPower",
    Min = 50, Max = 300, Default = 100, Decimals = 0, Suffix = " JP",
    Callback = function(v)
        State.JumpPower = v
        if State.HighJump then applyJumpPower() end
    end
})

-- ==================== ANTI DETECTION ====================
AntiSection:Toggle({
    Name = "Anti Detection",
    Flag = "AntiDetection",
    Default = false,
    Callback = function(v)
        State.AntiDetection = v
        getgenv().Servo.AntiDetection = v
    end
})

pcall(function()
    if not hookmetamethod or not newcclosure then return end
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if State.AntiDetection and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local char = LocalChar or LocalPlayer.Character
            if char and self:IsDescendantOf(char) then
                if key == "JumpPower" then return 50 end
                if key == "WalkSpeed" then return 16 end
            end
        end
        return oldIndex(self, key)
    end))
end)

-- ==================== ESP ====================
local Cache = {}

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function createESP(player)
    if player == LocalPlayer or Cache[player] then return end
    Cache[player] = {
        Box = newDrawing("Square", { Thickness = 1, Filled = false, Color = Color3.new(1,1,1), Visible = false }),
        HealthBG = newDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.fromRGB(20,20,20), Visible = false }),
        HealthBar = newDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.fromRGB(0,255,0), Visible = false }),
        Distance = newDrawing("Text", { Size = 13, Center = true, Outline = true, Color = Color3.new(1,1,1), Font = 2, Visible = false }),
        Name = newDrawing("Text", { Size = 14, Center = true, Outline = true, Color = Color3.new(1,1,1), Font = 2, Visible = false }),
    }
end

local function removeESP(player)
    local data = Cache[player]
    if not data then return end
    for _, obj in pairs(data) do pcall(function() obj:Remove() end) end
    Cache[player] = nil
end

local function hideESP(player)
    local data = Cache[player]
    if not data then return end
    for _, obj in pairs(data) do obj.Visible = false end
end

local function updateESP(player)
    local data = Cache[player]
    if not data or not Camera then return end
    local char, head, hum, hrp = getTargetParts(player)
    if not char then hideESP(player) return end
    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    if dist > 2000 then hideESP(player) return end

    local top = head.Position + Vector3.new(0, 0.5, 0)
    local bottom = hrp.Position - Vector3.new(0, 3, 0)
    local topScreen, onTop = Camera:WorldToViewportPoint(top)
    local botScreen = Camera:WorldToViewportPoint(bottom)
    if not onTop then hideESP(player) return end

    local height = math.abs(topScreen.Y - botScreen.Y)
    local width = height * 0.55
    local x = topScreen.X - width / 2
    local y = topScreen.Y

    data.Box.Size = Vector2.new(width, height)
    data.Box.Position = Vector2.new(x, y)
    data.Box.Color = ACCENT
    data.Box.Visible = true

    local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    data.HealthBG.Size = Vector2.new(3, height)
    data.HealthBG.Position = Vector2.new(x - 6, y)
    data.HealthBG.Visible = true
    data.HealthBar.Size = Vector2.new(3, height * hp)
    data.HealthBar.Position = Vector2.new(x - 6, y + height * (1 - hp))
    data.HealthBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 40)
    data.HealthBar.Visible = true

    data.Name.Text = player.Name
    data.Name.Position = Vector2.new(topScreen.X, y - 16)
    data.Name.Visible = true

    data.Distance.Text = math.floor(dist) .. "m"
    data.Distance.Position = Vector2.new(topScreen.X, y + height + 2)
    data.Distance.Visible = true
end

ESPSection:Toggle({
    Name = "ESP",
    Flag = "ESP",
    Default = false,
    Callback = function(v)
        State.ESP = v
        if not v then
            for player in pairs(Cache) do hideESP(player) end
        end
    end
})

-- ==================== SERVO LINES ====================
local ServoLines = {}

local function createServoLine(player)
    if player == LocalPlayer or ServoLines[player] then return end
    local line = Drawing.new("Line")
    line.Thickness = 1.2
    line.Color = ACCENT
    line.Transparency = 0.7
    line.Visible = false
    ServoLines[player] = line
end

local function removeServoLine(player)
    local line = ServoLines[player]
    if line then pcall(function() line:Remove() end) ServoLines[player] = nil end
end

local function updateServoLine(player)
    local line = ServoLines[player]
    if not line or not LocalHRP then return end
    local _, _, _, hrp = getTargetParts(player)
    if not hrp then line.Visible = false return end
    local fromP = Camera:WorldToViewportPoint(LocalHRP.Position)
    local toP, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then line.Visible = false return end
    line.From = Vector2.new(fromP.X, fromP.Y)
    line.To = Vector2.new(toP.X, toP.Y)
    line.Color = ACCENT
    line.Visible = true
end

ESPSection:Toggle({
    Name = "Servo Lines",
    Flag = "ServoLines",
    Default = false,
    Callback = function(v)
        State.ServoLines = v
        if not v then for _, line in pairs(ServoLines) do line.Visible = false end end
    end
})

-- ==================== AIMVIEWER ====================
local AimviewerCache = {}

local function createAimviewer(player)
    if player == LocalPlayer or AimviewerCache[player] then return end
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = Color3.fromRGB(255, 120, 50)
    line.Transparency = 0.6
    line.Visible = false
    AimviewerCache[player] = line
end

local function removeAimviewer(player)
    local line = AimviewerCache[player]
    if line then pcall(function() line:Remove() end) AimviewerCache[player] = nil end
end

local function updateAimviewer(player)
    local line = AimviewerCache[player]
    if not line then return end
    local _, head = getTargetParts(player)
    if not head then line.Visible = false return end
    local look = head.CFrame.LookVector * 80
    local endPos = head.Position + look
    local fromS = Camera:WorldToViewportPoint(head.Position)
    local toS, onScreen = Camera:WorldToViewportPoint(endPos)
    if not onScreen then line.Visible = false return end
    line.From = Vector2.new(fromS.X, fromS.Y)
    line.To = Vector2.new(toS.X, toS.Y)
    line.Visible = true
end

AimviewerSection:Toggle({
    Name = "Aimviewer",
    Flag = "Aimviewer",
    Default = false,
    Callback = function(v)
        State.Aimviewer = v
        if not v then for _, line in pairs(AimviewerCache) do line.Visible = false end end
    end
})

-- ==================== PLAYER TRACKING ====================
local function onPlayerAdded(player)
    createESP(player)
    createServoLine(player)
    createAimviewer(player)
end
local function onPlayerRemoving(player)
    removeESP(player)
    removeServoLine(player)
    removeAimviewer(player)
end
for _, plr in ipairs(Players:GetPlayers()) do onPlayerAdded(plr) end
bind("PlayerAdded", Players.PlayerAdded:Connect(onPlayerAdded))
bind("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))

-- ==================== MAIN LOOP ====================
bind("MainRender", RunService.RenderStepped:Connect(function()
    refreshCamera()

    FOVCircle.Position = ViewportCenter
    FOVCircle.Radius = State.AimbotFOV * 0.5
    FOVCircle.Visible = State.Aimbot or getgenv().Servo.SilentAim
    FOVCircle.Color = ACCENT

    TriggerFOVCircle.Position = ViewportCenter
    TriggerFOVCircle.Radius = State.TriggerFOV
    TriggerFOVCircle.Visible = State.Triggerbot

    if State.Aimbot then
        local target = getClosestPlayer()
        State.CurrentTarget = target
        if target then
            local _, head = getTargetParts(target)
            if head then
                local sp = Camera:WorldToViewportPoint(head.Position)
                SnapLine.From = ViewportCenter
                SnapLine.To = Vector2.new(sp.X, sp.Y)
                SnapLine.Visible = true
                SnapLine.Color = ACCENT
                HeadDot.Position = Vector2.new(sp.X, sp.Y)
                HeadDot.Visible = true
                HeadDot.Color = ACCENT
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), State.Smoothness)
            else
                hideAimbotVisuals()
            end
        else
            hideAimbotVisuals()
        end
    else
        hideAimbotVisuals()
        State.CurrentTarget = nil
    end

    if State.Triggerbot then triggerbotTick() end

    if State.ESP then
        for player in pairs(Cache) do updateESP(player) end
    else
        for player in pairs(Cache) do hideESP(player) end
    end

    if State.ServoLines then
        for player in pairs(ServoLines) do updateServoLine(player) end
    else
        for _, line in pairs(ServoLines) do line.Visible = false end
    end

    if State.Aimviewer then
        for player in pairs(AimviewerCache) do updateAimviewer(player) end
    else
        for _, line in pairs(AimviewerCache) do line.Visible = false end
    end
end))

-- ==================== RGB ====================
AntiSection:Toggle({
    Name = "RGB Accent",
    Flag = "RGBMode",
    Default = false,
    Callback = function(v)
        State.RGB = v
        if not v then
            unbind("RGBLoop")
            pcall(function()
                Library:ChangeTheme("Accent", ACCENT)
                Library:ChangeTheme("AccentGradient", ACCENT_GRAD)
            end)
            return
        end
        if Connections.RGBLoop then return end
        bind("RGBLoop", RunService.Heartbeat:Connect(function()
            if not State.RGB then return end
            local color = Color3.fromHSV((tick() * 0.25) % 1, 1, 1)
            pcall(function()
                Library:ChangeTheme("Accent", color)
                Library:ChangeTheme("AccentGradient", color:Lerp(Color3.new(0, 0, 0), 0.35))
            end)
        end))
    end
})

-- Settings page
pcall(function()
    if Library.CreateSettingsPage then
        Library:CreateSettingsPage(Window, KeybindList)
    end
end)

pcall(function()
    if Window.Init then Window:Init() end
end)

-- Unload
pcall(function()
    if Library.Unload then
        local oldUnload = Library.Unload
        Library.Unload = function(...)
            State.Aimbot = false
            State.Triggerbot = false
            State.ESP = false
            State.ServoLines = false
            State.Aimviewer = false
            State.RGB = false
            getgenv().Servo.SilentAim = false
            getgenv().Servo.SilentTarget = nil
            unbindAll()
            pcall(function()
                if FOVCircle then FOVCircle:Remove() end
                if SnapLine then SnapLine:Remove() end
                if HeadDot then HeadDot:Remove() end
                if TriggerFOVCircle then TriggerFOVCircle:Remove() end
                for _, data in pairs(Cache or {}) do
                    for _, obj in pairs(data) do pcall(function() obj:Remove() end) end
                end
                for _, line in pairs(AimviewerCache or {}) do pcall(function() line:Remove() end) end
                for _, line in pairs(ServoLines or {}) do pcall(function() line:Remove() end) end
            end)
            return oldUnload(Library, ...)
        end
    end
end)

print("[Servo.cc] Loaded successfully")
