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
local MarketplaceService = game:GetService("MarketplaceService")
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

-- Forward declare so CharacterAdded can call it safely before the real definition
local applyJumpPower

bind("LocalCharacterAdded", LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.35)
    refreshLocalCharacter(char)
    task.defer(function()
        if State.HighJump and applyJumpPower then
            applyJumpPower()
        end
    end)
end))
bind("LocalCharacterRemoving", LocalPlayer.CharacterRemoving:Connect(function()
    LocalChar, LocalHum, LocalHRP = nil, nil, nil
end))

-- Camera / viewport cache
local ViewportCenter = Vector2.new(0, 0)
local ViewportBottom = Vector2.new(0, 0)
local function refreshCamera()
    Camera = workspace.CurrentCamera
    if not Camera then return end
    local size = Camera.ViewportSize
    ViewportCenter = Vector2.new(size.X * 0.5, size.Y * 0.5)
    ViewportBottom = Vector2.new(size.X * 0.5, size.Y)
end
refreshCamera()
bind("CameraChanged", workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshCamera))
if Camera then
    bind("ViewportChanged", Camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshCamera))
end

-- ==================== INTRO ====================
do
    local sw = Camera and Camera.ViewportSize.X or 1920
    local sh = Camera and Camera.ViewportSize.Y or 1080
    local cx, cy = sw / 2, sh / 2

    local COL_CORE = Color3.fromRGB(100, 180, 255)
    local COL_GLOW = Color3.fromRGB(140, 200, 255)
    local COL_DIM = Color3.fromRGB(80, 120, 180)
    local COL_WHITE = Color3.fromRGB(255, 255, 255)

    local core = Drawing.new("Circle")
    core.Radius = 2
    core.Filled = true
    core.NumSides = 32
    core.Color = COL_CORE
    core.Visible = true
    core.Transparency = 1
    core.Position = Vector2.new(cx, cy)

    local rings = {}
    for i = 1, 3 do
        local r = Drawing.new("Circle")
        r.Radius = 10 + i * 12
        r.Filled = false
        r.Thickness = 1.5
        r.NumSides = 48
        r.Color = COL_GLOW
        r.Visible = true
        r.Transparency = 1
        r.Position = Vector2.new(cx, cy)
        rings[i] = r
    end

    local orbiters = {}
    for i = 1, 8 do
        local d = Drawing.new("Circle")
        d.Radius = 2.2
        d.Filled = true
        d.NumSides = 12
        d.Color = COL_GLOW
        d.Visible = true
        d.Transparency = 1
        d.Position = Vector2.new(cx, cy)
        orbiters[i] = { draw = d, angle = (i / 8) * math.pi * 2 }
    end

    local beamL = Drawing.new("Line")
    beamL.Thickness = 2
    beamL.Color = COL_CORE
    beamL.Visible = true
    beamL.Transparency = 1
    beamL.From = Vector2.new(cx, cy)
    beamL.To = Vector2.new(cx, cy)

    local beamR = Drawing.new("Line")
    beamR.Thickness = 2
    beamR.Color = COL_CORE
    beamR.Visible = true
    beamR.Transparency = 1
    beamR.From = Vector2.new(cx, cy)
    beamR.To = Vector2.new(cx, cy)

    local title = Drawing.new("Text")
    title.Text = "SERVO"
    title.Size = 44
    title.Center = true
    title.Outline = true
    title.OutlineColor = Color3.fromRGB(0, 0, 0)
    title.Color = COL_CORE
    title.Position = Vector2.new(cx, cy - 10)
    title.Visible = true
    title.Transparency = 1

    local sub = Drawing.new("Text")
    sub.Text = ".CC"
    sub.Size = 15
    sub.Center = true
    sub.Outline = true
    sub.Color = COL_GLOW
    sub.Position = Vector2.new(cx, cy + 26)
    sub.Visible = true
    sub.Transparency = 1

    local credit = Drawing.new("Text")
    credit.Text = "by @cuakieffer"
    credit.Size = 13
    credit.Center = true
    credit.Outline = true
    credit.Color = COL_DIM
    credit.Position = Vector2.new(cx, cy + 48)
    credit.Visible = true
    credit.Transparency = 1

    local underline = Drawing.new("Line")
    underline.Thickness = 1.5
    underline.Color = COL_CORE
    underline.Visible = true
    underline.Transparency = 1
    underline.From = Vector2.new(cx, cy + 12)
    underline.To = Vector2.new(cx, cy + 12)

    local sparks = {}
    for i = 1, 24 do
        local s = Drawing.new("Circle")
        s.Radius = math.random(1, 2)
        s.Filled = true
        s.NumSides = 8
        s.Color = (i % 2 == 0) and COL_GLOW or COL_WHITE
        s.Visible = false
        s.Transparency = 0
        s.Position = Vector2.new(cx, cy)
        local a = math.rad(math.random(0, 360))
        local sp = math.random(25, 90) / 10
        sparks[i] = { draw = s, vx = math.cos(a) * sp, vy = math.sin(a) * sp }
    end

    task.spawn(function()
        for i = 1, 12 do
            local t = i / 12
            core.Transparency = 1 - t
            core.Radius = 2 + t * 6
            task.wait(0.02)
        end
        for i = 1, 18 do
            local t = i / 18
            for ri, ring in ipairs(rings) do
                ring.Transparency = 1 - t * (1 - ri * 0.15)
                ring.Radius = 10 + ri * 12 + t * 8
            end
            for _, o in ipairs(orbiters) do
                o.angle = o.angle + 0.18
                local rad = 28 + t * 10
                o.draw.Position = Vector2.new(cx + math.cos(o.angle) * rad, cy + math.sin(o.angle) * rad)
                o.draw.Transparency = 1 - t
            end
            beamL.Transparency = 1 - t
            beamR.Transparency = 1 - t
            beamL.From = Vector2.new(cx - 80 * t, cy)
            beamL.To = Vector2.new(cx - 20, cy)
            beamR.From = Vector2.new(cx + 20, cy)
            beamR.To = Vector2.new(cx + 80 * t, cy)
            task.wait(0.025)
        end
        for i = 1, 15 do
            local t = i / 15
            title.Transparency = 1 - t
            sub.Transparency = 1 - t
            credit.Transparency = 1 - t
            underline.Transparency = 1 - t
            underline.From = Vector2.new(cx - 40 * t, cy + 12)
            underline.To = Vector2.new(cx + 40 * t, cy + 12)
            for _, o in ipairs(orbiters) do
                o.angle = o.angle + 0.12
                o.draw.Position = Vector2.new(cx + math.cos(o.angle) * 38, cy + math.sin(o.angle) * 38)
            end
            task.wait(0.018)
        end
        for i = 1, 8 do
            title.Color = (i % 2 == 0) and COL_WHITE or COL_CORE
            core.Radius = 8 + (i % 2) * 5
            core.Transparency = (i % 2) * 0.25
            task.wait(0.045)
        end
        title.Color = COL_CORE
        core.Transparency = 0.15
        task.wait(0.35)
        for _, s in ipairs(sparks) do
            s.draw.Visible = true
            s.draw.Position = Vector2.new(cx, cy)
            s.draw.Transparency = 0
        end
        for frame = 1, 26 do
            local t = frame / 26
            title.Transparency = t
            sub.Transparency = t
            credit.Transparency = t
            underline.Transparency = t
            core.Transparency = 0.15 + t * 0.85
            core.Radius = 8 + t * 30
            for _, ring in ipairs(rings) do ring.Transparency = 1 end
            for _, o in ipairs(orbiters) do o.draw.Transparency = 1 end
            beamL.Transparency = 1
            beamR.Transparency = 1
            for _, s in ipairs(sparks) do
                local p = s.draw.Position
                s.draw.Position = Vector2.new(p.X + s.vx, p.Y + s.vy)
                s.draw.Transparency = t
                s.vx *= 0.96
                s.vy *= 0.96
            end
            task.wait(0.016)
        end
        core:Remove()
        title:Remove()
        sub:Remove()
        credit:Remove()
        underline:Remove()
        beamL:Remove()
        beamR:Remove()
        for _, ring in ipairs(rings) do ring:Remove() end
        for _, o in ipairs(orbiters) do o.draw:Remove() end
        for _, s in ipairs(sparks) do s.draw:Remove() end
    end)
    task.wait(3.2)
end

-- ==================== WINDOW (Neverlose) ====================
local Window = Library:Window({
    Name = "Servo.cc",
    SubName = "by @cuakieffer",
    Logo = "0",
})

local KeybindList = Library:KeybindList("Keybinds")
pcall(function()
    Library:Watermark({ "Servo.cc", "by @cuakieffer" })
end)

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

-- ==================== WELCOME ====================
local function notify(title, desc, duration)
    pcall(function()
        Library:Notification({
            Title = title or "Servo.cc",
            Description = desc or "",
            Duration = duration or 4,
        })
    end)
    pcall(function()
        if Library.Log then Library:Log(desc or title, duration or 4, ACCENT) end
    end)
end

task.defer(function()
    notify("Servo.cc", "Thank You For Executing Servo.cc", 5)
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://4590657391"
        sound.Volume = 0.7
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Once(function() sound:Destroy() end)
        task.delay(6, function() pcall(function() sound:Destroy() end) end)
    end)
end)

-- ==================== UTILITIES ====================
local lightBlue = Color3.fromRGB(100, 180, 255)

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return head ~= nil and hum ~= nil and hrp ~= nil and hum.Health > 0
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

-- ==================== SILENT AIM ====================
local DA_HOOD = {
    [2788229376] = true,
    [7213786345] = true,
    [9825515356] = true,
}
local function isDaHood() return DA_HOOD[game.PlaceId] == true end

pcall(function()
    if not (hookmetamethod and newcclosure and getnamecallmethod) then return end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if getgenv().Servo.SilentAim and isDaHood() and method == "FireServer" then
            local target = getgenv().Servo.SilentTarget
            if target and target.Parent and typeof(self) == "Instance" and self.Name == "MainEvent" then
                local action = args[1]
                if action == "Shoot" or action == "ShootGun" or action == "MousePos" or action == "Cursor" then
                    for i = 2, #args do
                        if typeof(args[i]) == "Vector3" then args[i] = target.Position end
                    end
                    return oldNamecall(self, unpack(args))
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
                            closest, closestDist = head, dist
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
    Name = "Silent Aim", Flag = "SilentAim", Default = false,
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
    Name = "High Jump", Flag = "HighJump", Default = false,
    Callback = function(v) State.HighJump = v; applyJumpPower() end
})
MovementSection:Slider({
    Name = "Jump Power", Flag = "JumpPower", Min = 50, Max = 300, Default = 100, Decimals = 0, Suffix = " JP",
    Callback = function(v) State.JumpPower = v; if State.HighJump then applyJumpPower() end end
})

-- ==================== ANTI DETECTION ====================
AntiSection:Toggle({
    Name = "Anti Detection", Flag = "AntiDetection", Default = false,
    Callback = function(v) State.AntiDetection = v; getgenv().Servo.AntiDetection = v end
})

pcall(function()
    if not (hookmetamethod and newcclosure) then return end
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

-- ==================== AIMBOT VISUALS ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = lightBlue
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Radius = State.AimbotFOV * 0.5
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
                        shortest, closest = worldDist, player
                    end
                end
            end
        end
    end
    return closest
end

CombatSection:Toggle({
    Name = "Aimbot", Flag = "Aimbot", Default = false,
    Callback = function(v)
        State.Aimbot = v
        FOVCircle.Visible = v or getgenv().Servo.SilentAim
        if not v then hideAimbotVisuals() end
    end
})
CombatSection:Slider({ Name = "Aimbot FOV", Flag = "AimbotFOV", Min = 50, Max = 800, Default = 360, Decimals = 0,
    Callback = function(v) State.AimbotFOV = v; FOVCircle.Radius = v * 0.5 end })
CombatSection:Slider({ Name = "Aimbot Range", Flag = "AimbotRange", Min = 50, Max = 3000, Default = 1000, Decimals = 0,
    Callback = function(v) State.AimbotRange = v end })
CombatSection:Slider({ Name = "Smoothness", Flag = "Smoothness", Min = 0.05, Max = 1, Default = 0.18, Decimals = 2,
    Callback = function(v) State.Smoothness = v end })

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
    if (Vector2.new(screen.X, screen.Y) - ViewportCenter).Magnitude <= State.TriggerFOV then
        State.LastTrigger = tick()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

TriggerSection:Toggle({ Name = "Triggerbot", Flag = "Triggerbot", Default = false,
    Callback = function(v) State.Triggerbot = v; TriggerFOVCircle.Visible = v end })
TriggerSection:Slider({ Name = "Trigger FOV", Flag = "TriggerFOV", Min = 20, Max = 150, Default = 70, Decimals = 0,
    Callback = function(v) State.TriggerFOV = v; TriggerFOVCircle.Radius = v end })
TriggerSection:Slider({ Name = "Cooldown", Flag = "TriggerCooldown", Min = 0.1, Max = 1, Default = 0.28, Decimals = 2,
    Callback = function(v) State.TriggerCooldown = v end })

-- ==================== ESP ====================
local ESP_SETTINGS = { BoxColor = Color3.fromRGB(255,255,255), TextColor = Color3.fromRGB(255,255,255), MaxDistance = 2000 }
local Cache = {}

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function createESP(player)
    if player == LocalPlayer or Cache[player] then return end
    Cache[player] = {
        Box = newDrawing("Square", { Thickness = 1, Filled = false, Color = ESP_SETTINGS.BoxColor, Visible = false }),
        HealthBG = newDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.fromRGB(20,20,20), Visible = false }),
        HealthBar = newDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.fromRGB(0,255,0), Visible = false }),
        Distance = newDrawing("Text", { Size = 13, Center = true, Outline = true, Color = ESP_SETTINGS.TextColor, Font = 2, Visible = false }),
        Name = newDrawing("Text", { Size = 14, Center = true, Outline = true, Color = ESP_SETTINGS.TextColor, Font = 2, Visible = false }),
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
    if dist > ESP_SETTINGS.MaxDistance then hideESP(player) return end

    local top = head.Position + Vector3.new(0, 0.5, 0)
    local bottom = hrp.Position - Vector3.new(0, 3, 0)
    local topScreen, onTop = Camera:WorldToViewportPoint(top)
    local botScreen = Camera:WorldToViewportPoint(bottom)
    if not onTop then hideESP(player) return end

    local height = math.abs(topScreen.Y - botScreen.Y)
    local width = height * 0.55
    local x, y = topScreen.X - width / 2, topScreen.Y

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

ESPSection:Toggle({ Name = "ESP", Flag = "ESP", Default = false,
    Callback = function(v) State.ESP = v; if not v then for p in pairs(Cache) do hideESP(p) end end end })

pcall(function()
    ESPSection:Label("ESP Color"):Colorpicker({
        Name = "Color", Flag = "ESPColor", Default = Color3.fromRGB(255,255,255),
        Callback = function(v) ESP_SETTINGS.BoxColor = v; ESP_SETTINGS.TextColor = v end
    })
end)

-- ==================== ESP PREVIEW PANEL ====================
local PREVIEW = {
    MainColor = Color3.fromRGB(28, 28, 28),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    AccentColor = ACCENT,
    OutlineColor = Color3.fromRGB(50, 50, 50),
    FontColor = Color3.fromRGB(255, 255, 255),
    DimColor = Color3.fromRGB(160, 160, 160),
}

local PreviewGui = Instance.new("ScreenGui")
PreviewGui.Name = "ServoESPPreview"
PreviewGui.ResetOnSpawn = false
PreviewGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() PreviewGui.Parent = (gethui and gethui()) or CoreGui end)
if not PreviewGui.Parent then PreviewGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Outer = Instance.new("Frame")
Outer.BackgroundColor3 = Color3.new(0, 0, 0)
Outer.BorderSizePixel = 0
Outer.Position = UDim2.new(0.5, 290, 0.5, -200)
Outer.Size = UDim2.new(0, 220, 0, 400)
Outer.Visible = false
Outer.Parent = PreviewGui
Instance.new("UICorner", Outer).CornerRadius = UDim.new(0, 2)

local Inner = Instance.new("Frame")
Inner.BackgroundColor3 = PREVIEW.MainColor
Inner.BorderColor3 = PREVIEW.OutlineColor
Inner.BorderMode = Enum.BorderMode.Inset
Inner.BorderSizePixel = 1
Inner.Size = UDim2.new(1, 0, 1, 0)
Inner.Parent = Outer

local AccentBar = Instance.new("Frame")
AccentBar.BackgroundColor3 = PREVIEW.AccentColor
AccentBar.BorderSizePixel = 0
AccentBar.Size = UDim2.new(1, 0, 0, 2)
AccentBar.Parent = Inner

local TitleLabel = Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 8, 0, 6)
TitleLabel.Size = UDim2.new(1, -16, 0, 20)
TitleLabel.Font = Enum.Font.Code
TitleLabel.Text = "ESP Preview"
TitleLabel.TextColor3 = PREVIEW.FontColor
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Inner

local Divider = Instance.new("Frame")
Divider.BackgroundColor3 = PREVIEW.OutlineColor
Divider.BorderSizePixel = 0
Divider.Position = UDim2.new(0, 6, 0, 28)
Divider.Size = UDim2.new(1, -12, 0, 1)
Divider.Parent = Inner

local List = Instance.new("ScrollingFrame")
List.BackgroundColor3 = PREVIEW.BackgroundColor
List.BorderColor3 = PREVIEW.OutlineColor
List.BorderSizePixel = 1
List.Position = UDim2.new(0, 6, 0, 36)
List.Size = UDim2.new(1, -12, 1, -44)
List.ScrollBarThickness = 3
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.Parent = Inner

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = List

local PreviewCards = {}

local function createPreviewCard(player)
    if player == LocalPlayer or PreviewCards[player] then return end
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, -4, 0, 36)
    card.Parent = List
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 2)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Position = UDim2.new(0, 8, 0, 2)
    nameLbl.Size = UDim2.new(1, -16, 0, 16)
    nameLbl.Font = Enum.Font.Code
    nameLbl.Text = player.Name
    nameLbl.TextColor3 = PREVIEW.FontColor
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = card

    local hpLbl = Instance.new("TextLabel")
    hpLbl.BackgroundTransparency = 1
    hpLbl.Position = UDim2.new(0, 8, 0, 18)
    hpLbl.Size = UDim2.new(1, -16, 0, 14)
    hpLbl.Font = Enum.Font.Code
    hpLbl.Text = "100 HP"
    hpLbl.TextColor3 = PREVIEW.DimColor
    hpLbl.TextSize = 11
    hpLbl.TextXAlignment = Enum.TextXAlignment.Left
    hpLbl.Parent = card

    PreviewCards[player] = { card = card, name = nameLbl, hp = hpLbl }
end

local function removePreviewCard(player)
    local c = PreviewCards[player]
    if c then pcall(function() c.card:Destroy() end) PreviewCards[player] = nil end
end

local function updatePreviewCard(player)
    local c = PreviewCards[player]
    if not c then return end
    local char, head, hum = getTargetParts(player)
    if not char then
        c.hp.Text = "Dead"
        c.hp.TextColor3 = Color3.fromRGB(200, 60, 60)
        return
    end
    local hp = math.floor(hum.Health)
    c.hp.Text = hp .. " HP"
    c.hp.TextColor3 = hp > 50 and Color3.fromRGB(80, 220, 80) or Color3.fromRGB(220, 160, 40)
end

ESPSection:Toggle({
    Name = "ESP Preview", Flag = "ESPPreview", Default = false,
    Callback = function(v)
        State.ESPPreview = v
        Outer.Visible = v
        PreviewGui.Enabled = v
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

ESPSection:Toggle({ Name = "Servo Lines", Flag = "ServoLines", Default = false,
    Callback = function(v) State.ServoLines = v; if not v then for _, l in pairs(ServoLines) do l.Visible = false end end end })

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
    local endPos = head.Position + head.CFrame.LookVector * 80
    local fromS = Camera:WorldToViewportPoint(head.Position)
    local toS, onScreen = Camera:WorldToViewportPoint(endPos)
    if not onScreen then line.Visible = false return end
    line.From = Vector2.new(fromS.X, fromS.Y)
    line.To = Vector2.new(toS.X, toS.Y)
    line.Visible = true
end

AimviewerSection:Toggle({ Name = "Aimviewer", Flag = "Aimviewer", Default = false,
    Callback = function(v) State.Aimviewer = v; if not v then for _, l in pairs(AimviewerCache) do l.Visible = false end end end })

-- ==================== PLAYER TRACKING ====================
local function onPlayerAdded(player)
    createESP(player)
    createServoLine(player)
    createAimviewer(player)
    createPreviewCard(player)
end
local function onPlayerRemoving(player)
    removeESP(player)
    removeServoLine(player)
    removeAimviewer(player)
    removePreviewCard(player)
end
for _, plr in ipairs(Players:GetPlayers()) do onPlayerAdded(plr) end
bind("PlayerAdded", Players.PlayerAdded:Connect(onPlayerAdded))
bind("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))

-- ==================== MAIN RENDER LOOP ====================
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

    if State.ESPPreview then
        for player in pairs(PreviewCards) do updatePreviewCard(player) end
        List.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 4)
    end
end))

-- ==================== SETTINGS + RGB ====================
Window:Category("Settings")
pcall(function()
    if Library.CreateSettingsPage then
        Library:CreateSettingsPage(Window, KeybindList)
    end
end)

AntiSection:Toggle({
    Name = "RGB Accent", Flag = "RGBMode", Default = false,
    Callback = function(v)
        State.RGB = v
        if not v then
            unbind("RGBLoop")
            pcall(function()
                Library:ChangeTheme("Accent", ACCENT)
                Library:ChangeTheme("AccentGradient", ACCENT_GRAD)
            end)
            PREVIEW.AccentColor = ACCENT
            AccentBar.BackgroundColor3 = ACCENT
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
            PREVIEW.AccentColor = color
            if Outer.Visible then AccentBar.BackgroundColor3 = color end
        end))
    end
})

pcall(function() if Window.Init then Window:Init() end end)

-- Unload hook
pcall(function()
    if Library.Unload then
        local oldUnload = Library.Unload
        Library.Unload = function(...)
            State.Aimbot = false
            State.Triggerbot = false
            State.ESP = false
            State.ESPPreview = false
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
                if PreviewGui then PreviewGui:Destroy() end
            end)
            return oldUnload(Library, ...)
        end
    end
end)

print("[Servo.cc] Loaded successfully - full version")
