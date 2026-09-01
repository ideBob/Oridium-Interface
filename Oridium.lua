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
local ViewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
bind("ViewportSizeChanged", Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    ViewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end))

-- ==================== HELPERS ====================
local function isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getClosestSilentTarget()
    local closest, closestDist = nil, math.huge
    local myPos = LocalHRP and LocalHRP.Position
    if not myPos then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isAlive(plr.Character) then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local head = plr.Character:FindFirstChild("Head")
            if hrp and head then
                local dist = (hrp.Position - myPos).Magnitude
                if dist < closestDist and dist <= State.AimbotRange then
                    local screen, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local fovDist = (Vector2.new(screen.X, screen.Y) - ViewportCenter).Magnitude
                        if fovDist <= State.AimbotFOV then
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

local function getTargetParts(char)
    if not char then return nil end
    return {
        Head = char:FindFirstChild("Head"),
        HRP = char:FindFirstChild("HumanoidRootPart"),
        Hum = char:FindFirstChildOfClass("Humanoid"),
    }
end

-- ==================== INTRO ANIMATION ====================
local function playIntro()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ServoIntro"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = CoreGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromScale(1, 0.2)
    title.Position = UDim2.fromScale(0, 0.35)
    title.BackgroundTransparency = 1
    title.Text = "SERVO"
    title.TextColor3 = ACCENT
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 72
    title.TextTransparency = 1
    title.Parent = bg

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.fromScale(1, 0.08)
    sub.Position = UDim2.fromScale(0, 0.55)
    sub.BackgroundTransparency = 1
    sub.Text = ".cc"
    sub.TextColor3 = Color3.fromRGB(180, 200, 255)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 28
    sub.TextTransparency = 1
    sub.Parent = bg

    -- Lightning / slice lines
    local lines = {}
    for i = 1, 6 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 2, 0, 0)
        line.Position = UDim2.fromScale(math.random() * 0.8 + 0.1, math.random() * 0.6 + 0.2)
        line.BackgroundColor3 = ACCENT
        line.BorderSizePixel = 0
        line.BackgroundTransparency = 0.3
        line.Parent = bg
        table.insert(lines, line)
    end

    task.spawn(function()
        for _, line in ipairs(lines) do
            local tween = game:GetService("TweenService"):Create(line, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 2, 0, math.random(80, 180)),
                BackgroundTransparency = 0.6
            })
            tween:Play()
        end
        task.wait(0.15)
        game:GetService("TweenService"):Create(title, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
        game:GetService("TweenService"):Create(sub, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
        task.wait(1.1)
        game:GetService("TweenService"):Create(bg, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
        game:GetService("TweenService"):Create(title, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
        game:GetService("TweenService"):Create(sub, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
        for _, line in ipairs(lines) do
            game:GetService("TweenService"):Create(line, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        end
        task.wait(0.5)
        gui:Destroy()
    end)
end

pcall(playIntro)

-- ==================== WINDOW ====================
local Window = Library:Window({
    Name = "Servo.cc",
    SubName = "by @cuakieffer",
})

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

-- ==================== NOTIFY ====================
local function notify(title, desc, duration)
    pcall(function()
        Library:Notify({
            Title = title or "Servo.cc",
            Description = desc or "",
            Duration = duration or 4,
        })
    end)
end

-- Welcome
task.delay(1.6, function()
    notify("Servo.cc", "Thank You For Executing Servo.cc", 5)
end)

-- ==================== DRAWING OBJECTS ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = 360
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = ACCENT
FOVCircle.Transparency = 0.7

local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 1.5
SnapLine.Visible = false
SnapLine.Color = ACCENT
SnapLine.Transparency = 0.85

local HeadDot = Drawing.new("Circle")
HeadDot.Thickness = 1
HeadDot.NumSides = 16
HeadDot.Radius = 4
HeadDot.Filled = true
HeadDot.Visible = false
HeadDot.Color = ACCENT

local TriggerFOVCircle = Drawing.new("Circle")
TriggerFOVCircle.Thickness = 1
TriggerFOVCircle.NumSides = 48
TriggerFOVCircle.Radius = 70
TriggerFOVCircle.Filled = false
TriggerFOVCircle.Visible = false
TriggerFOVCircle.Color = Color3.fromRGB(255, 80, 80)
TriggerFOVCircle.Transparency = 0.65

-- ==================== SILENT AIM (Da Hood only) ====================
local DA_HOOD_PLACE_IDS = {
    [2788229376] = true,
    [7213786345] = true,
    [9825515356] = true,
}

local function isDaHood()
    return DA_HOOD_PLACE_IDS[game.PlaceId] == true
end

local MainEvent = nil
pcall(function()
    MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" and self == MainEvent and getgenv().Servo.SilentAim and isDaHood() then
        local target = getgenv().Servo.SilentTarget
        if target and target.Parent then
            -- Redirect aim args when possible (Da Hood style)
            if typeof(args[1]) == "string" and (args[1] == "Cursor" or args[1] == "MousePos" or args[1]:find("Aim") or args[1]:find("Shoot")) then
                if args[2] and typeof(args[2]) == "Vector3" then
                    args[2] = target.Position
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end))

local function setSilentAim(enabled)
    if not isDaHood() then
        getgenv().Servo.SilentAim = false
        getgenv().Servo.SilentTarget = nil
        if enabled then notify("Silent Aim", "Only works on Da Hood", 3) end
        return
    end
    getgenv().Servo.SilentAim = enabled
    if not enabled then
        getgenv().Servo.SilentTarget = nil
    end
end

bind("SilentTargetUpdater", RunService.Heartbeat:Connect(function()
    if getgenv().Servo.SilentAim then
        getgenv().Servo.SilentTarget = getClosestSilentTarget()
    else
        getgenv().Servo.SilentTarget = nil
    end
end))

-- ==================== AIMBOT ====================
local function getClosestAimbotTarget()
    local closest, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isAlive(plr.Character) then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local screen, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screen.X, screen.Y) - ViewportCenter).Magnitude
                    if dist < closestDist and dist <= State.AimbotFOV then
                        closest = head
                        closestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- ==================== TRIGGERBOT ====================
local TRIGGER_WEAPONS = {
    ["[Revolver]"] = true,
    ["[Double-Barrel SG]"] = true,
    ["Revolver"] = true,
    ["Double-Barrel SG"] = true,
}

local function hasTriggerWeapon()
    local tool = LocalChar and LocalChar:FindFirstChildOfClass("Tool")
    if not tool then return false end
    return TRIGGER_WEAPONS[tool.Name] == true
end

local function triggerbotTick()
    if not State.Triggerbot or not hasTriggerWeapon() then return end
    if tick() - State.LastTrigger < State.TriggerCooldown then return end
    local target = getClosestAimbotTarget()
    if not target then return end
    local screen, onScreen = Camera:WorldToViewportPoint(target.Position)
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

-- ==================== HIGH JUMP ====================
local function applyJumpPower()
    if LocalHum then
        LocalHum.JumpPower = State.HighJump and State.JumpPower or 50
        LocalHum.UseJumpPower = true
    end
end

-- ==================== ANTI DETECTION ====================
local function setAntiDetection(v)
    State.AntiDetection = v
    getgenv().Servo.AntiDetection = v
    -- Basic anti-detection stubs (nil-safe)
    pcall(function()
        if v then
            -- Soften common checks if present
            if syn and syn.set_thread_identity then
                -- keep current identity
            end
        end
    end)
end

-- ==================== ESP ====================
local Cache = {}

local function createESP(player)
    if player == LocalPlayer or Cache[player] then return end
    local data = {}
    data.Box = Drawing.new("Square")
    data.Box.Thickness = 1.5
    data.Box.Filled = false
    data.Box.Visible = false
    data.Box.Color = ACCENT

    data.Name = Drawing.new("Text")
    data.Name.Size = 14
    data.Name.Center = true
    data.Name.Outline = true
    data.Name.Visible = false
    data.Name.Color = Color3.new(1, 1, 1)

    data.HealthBar = Drawing.new("Line")
    data.HealthBar.Thickness = 2
    data.HealthBar.Visible = false
    data.HealthBar.Color = Color3.fromRGB(0, 255, 80)

    data.Distance = Drawing.new("Text")
    data.Distance.Size = 12
    data.Distance.Center = true
    data.Distance.Outline = true
    data.Distance.Visible = false
    data.Distance.Color = Color3.fromRGB(200, 200, 200)

    Cache[player] = data
end

local function removeESP(player)
    local data = Cache[player]
    if not data then return end
    for _, obj in pairs(data) do
        pcall(function() obj:Remove() end)
    end
    Cache[player] = nil
end

local function updateESP(player)
    local data = Cache[player]
    if not data then return end
    local char = player.Character
    local parts = getTargetParts(char)
    if not parts or not parts.HRP or not parts.Hum or not isAlive(char) then
        data.Box.Visible = false
        data.Name.Visible = false
        data.HealthBar.Visible = false
        data.Distance.Visible = false
        return
    end

    local hrpPos, onScreen = Camera:WorldToViewportPoint(parts.HRP.Position)
    if not onScreen then
        data.Box.Visible = false
        data.Name.Visible = false
        data.HealthBar.Visible = false
        data.Distance.Visible = false
        return
    end

    local headPos = Camera:WorldToViewportPoint(parts.Head.Position + Vector3.new(0, 0.5, 0))
    local legPos = Camera:WorldToViewportPoint(parts.HRP.Position - Vector3.new(0, 3, 0))
    local height = math.abs(headPos.Y - legPos.Y)
    local width = height / 2

    data.Box.Size = Vector2.new(width, height)
    data.Box.Position = Vector2.new(hrpPos.X - width / 2, headPos.Y)
    data.Box.Visible = true
    data.Box.Color = ACCENT

    data.Name.Text = player.Name
    data.Name.Position = Vector2.new(hrpPos.X, headPos.Y - 16)
    data.Name.Visible = true

    local healthPct = math.clamp(parts.Hum.Health / parts.Hum.MaxHealth, 0, 1)
    data.HealthBar.From = Vector2.new(hrpPos.X - width / 2 - 5, legPos.Y)
    data.HealthBar.To = Vector2.new(hrpPos.X - width / 2 - 5, legPos.Y - height * healthPct)
    data.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 40)
    data.HealthBar.Visible = true

    local dist = LocalHRP and math.floor((parts.HRP.Position - LocalHRP.Position).Magnitude) or 0
    data.Distance.Text = dist .. "m"
    data.Distance.Position = Vector2.new(hrpPos.X, legPos.Y + 4)
    data.Distance.Visible = true
end

-- ==================== ESP PREVIEW PANEL ====================
local PreviewGui = Instance.new("ScreenGui")
PreviewGui.Name = "ServoESPPreview"
PreviewGui.IgnoreGuiInset = true
PreviewGui.DisplayOrder = 50
PreviewGui.Enabled = false
PreviewGui.Parent = CoreGui

local Outer = Instance.new("Frame")
Outer.Name = "Outer"
Outer.Size = UDim2.fromOffset(180, 260)
Outer.Position = UDim2.new(1, -200, 0.5, -130)
Outer.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
Outer.BorderSizePixel = 0
Outer.Visible = false
Outer.Parent = PreviewGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Outer

local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.BackgroundColor3 = ACCENT
AccentBar.BorderSizePixel = 0
AccentBar.Parent = Outer

local PreviewTitle = Instance.new("TextLabel")
PreviewTitle.Size = UDim2.new(1, -10, 0, 24)
PreviewTitle.Position = UDim2.fromOffset(5, 8)
PreviewTitle.BackgroundTransparency = 1
PreviewTitle.Text = "ESP Preview"
PreviewTitle.TextColor3 = Color3.new(1, 1, 1)
PreviewTitle.Font = Enum.Font.GothamBold
PreviewTitle.TextSize = 14
PreviewTitle.Parent = Outer

-- Hologram silhouette
local Silhouette = Instance.new("Frame")
Silhouette.Size = UDim2.fromOffset(50, 110)
Silhouette.Position = UDim2.new(0.5, -25, 0.5, -40)
Silhouette.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
Silhouette.BackgroundTransparency = 0.35
Silhouette.BorderSizePixel = 0
Silhouette.Parent = Outer

local SilCorner = Instance.new("UICorner")
SilCorner.CornerRadius = UDim.new(0, 6)
SilCorner.Parent = Silhouette

local HeadPreview = Instance.new("Frame")
HeadPreview.Size = UDim2.fromOffset(28, 28)
HeadPreview.Position = UDim2.new(0.5, -14, 0, -18)
HeadPreview.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
HeadPreview.BorderSizePixel = 0
HeadPreview.Parent = Silhouette

local HeadCorner = Instance.new("UICorner")
HeadCorner.CornerRadius = UDim.new(1, 0)
HeadCorner.Parent = HeadPreview

local HealthPreview = Instance.new("Frame")
HealthPreview.Size = UDim2.fromOffset(4, 110)
HealthPreview.Position = UDim2.fromOffset(-12, 0)
HealthPreview.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
HealthPreview.BorderSizePixel = 0
HealthPreview.Parent = Silhouette

local PREVIEW = {
    AccentColor = ACCENT,
}

-- ==================== SERVO LINES (TRACERS) ====================
local ServoLines = {}

local function createServoLine(player)
    if player == LocalPlayer or ServoLines[player] then return end
    local line = Drawing.new("Line")
    line.Thickness = 1.2
    line.Visible = false
    line.Color = ACCENT
    line.Transparency = 0.7
    ServoLines[player] = line
end

local function removeServoLine(player)
    local line = ServoLines[player]
    if not line then return end
    pcall(function() line:Remove() end)
    ServoLines[player] = nil
end

local function updateServoLine(player)
    local line = ServoLines[player]
    if not line then return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not isAlive(char) or not LocalHRP then
        line.Visible = false
        return
    end
    local fromPos = Camera:WorldToViewportPoint(LocalHRP.Position)
    local toPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        line.Visible = false
        return
    end
    line.From = Vector2.new(fromPos.X, fromPos.Y)
    line.To = Vector2.new(toPos.X, toPos.Y)
    line.Color = ACCENT
    line.Visible = true
end

-- ==================== AIMVIEWER ====================
local AimviewerCache = {}

local function createAimviewer(player)
    if player == LocalPlayer or AimviewerCache[player] then return end
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Visible = false
    line.Color = Color3.fromRGB(255, 120, 50)
    line.Transparency = 0.6
    AimviewerCache[player] = line
end

local function removeAimviewer(player)
    local line = AimviewerCache[player]
    if not line then return end
    pcall(function() line:Remove() end)
    AimviewerCache[player] = nil
end

local function updateAimviewer(player)
    local line = AimviewerCache[player]
    if not line then return end
    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    if not head or not isAlive(char) then
        line.Visible = false
        return
    end
    -- Approximate look direction from head CFrame
    local look = head.CFrame.LookVector * 80
    local endPos = head.Position + look
    local fromScreen = Camera:WorldToViewportPoint(head.Position)
    local toScreen, onScreen = Camera:WorldToViewportPoint(endPos)
    if not onScreen then
        line.Visible = false
        return
    end
    line.From = Vector2.new(fromScreen.X, fromScreen.Y)
    line.To = Vector2.new(toScreen.X, toScreen.Y)
    line.Visible = true
end

-- ==================== PLAYER LOOP ====================
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

for _, plr in ipairs(Players:GetPlayers()) do
    onPlayerAdded(plr)
end
bind("PlayerAdded", Players.PlayerAdded:Connect(onPlayerAdded))
bind("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))

-- ==================== MAIN RENDER LOOP ====================
bind("MainRender", RunService.RenderStepped:Connect(function()
    -- FOV circles
    FOVCircle.Position = ViewportCenter
    FOVCircle.Radius = State.AimbotFOV
    FOVCircle.Visible = State.Aimbot or getgenv().Servo.SilentAim
    FOVCircle.Color = ACCENT

    TriggerFOVCircle.Position = ViewportCenter
    TriggerFOVCircle.Radius = State.TriggerFOV
    TriggerFOVCircle.Visible = State.Triggerbot

    -- Aimbot
    if State.Aimbot then
        local target = getClosestAimbotTarget()
        State.CurrentTarget = target
        if target then
            local screen = Camera:WorldToViewportPoint(target.Position)
            SnapLine.From = ViewportCenter
            SnapLine.To = Vector2.new(screen.X, screen.Y)
            SnapLine.Visible = true
            SnapLine.Color = ACCENT
            HeadDot.Position = Vector2.new(screen.X, screen.Y)
            HeadDot.Visible = true
            HeadDot.Color = ACCENT

            -- Soft camera look
            local camCF = Camera.CFrame
            local targetCF = CFrame.new(camCF.Position, target.Position)
            Camera.CFrame = camCF:Lerp(targetCF, State.Smoothness)
        else
            SnapLine.Visible = false
            HeadDot.Visible = false
        end
    else
        SnapLine.Visible = false
        HeadDot.Visible = false
        State.CurrentTarget = nil
    end

    -- Triggerbot
    if State.Triggerbot then
        triggerbotTick()
    end

    -- ESP
    if State.ESP then
        for player in pairs(Cache) do
            updateESP(player)
        end
    else
        for _, data in pairs(Cache) do
            data.Box.Visible = false
            data.Name.Visible = false
            data.HealthBar.Visible = false
            data.Distance.Visible = false
        end
    end

    -- Servo Lines
    if State.ServoLines then
        for player in pairs(ServoLines) do
            updateServoLine(player)
        end
    else
        for _, line in pairs(ServoLines) do
            line.Visible = false
        end
    end

    -- Aimviewer
    if State.Aimviewer then
        for player in pairs(AimviewerCache) do
            updateAimviewer(player)
        end
    else
        for _, line in pairs(AimviewerCache) do
            line.Visible = false
        end
    end

    -- ESP Preview visibility
    Outer.Visible = State.ESPPreview
    PreviewGui.Enabled = State.ESPPreview
end))

-- ==================== UI CONTROLS ====================
CombatSection:Toggle({
    Name = "Silent Aim",
    Flag = "SilentAim",
    Default = false,
    Callback = function(v)
        setSilentAim(v)
    end
})

CombatSection:Toggle({
    Name = "Aimbot",
    Flag = "Aimbot",
    Default = false,
    Callback = function(v)
        State.Aimbot = v
    end
})

CombatSection:Slider({
    Name = "Aimbot FOV",
    Flag = "AimbotFOV",
    Default = 360,
    Min = 50,
    Max = 800,
    Callback = function(v)
        State.AimbotFOV = v
    end
})

CombatSection:Slider({
    Name = "Aimbot Range",
    Flag = "AimbotRange",
    Default = 1000,
    Min = 50,
    Max = 3000,
    Callback = function(v)
        State.AimbotRange = v
    end
})

CombatSection:Slider({
    Name = "Smoothness",
    Flag = "Smoothness",
    Default = 0.18,
    Min = 0.05,
    Max = 1,
    Decimal = 2,
    Callback = function(v)
        State.Smoothness = v
    end
})

TriggerSection:Toggle({
    Name = "Triggerbot",
    Flag = "Triggerbot",
    Default = false,
    Callback = function(v)
        State.Triggerbot = v
    end
})

TriggerSection:Slider({
    Name = "Trigger FOV",
    Flag = "TriggerFOV",
    Default = 70,
    Min = 20,
    Max = 200,
    Callback = function(v)
        State.TriggerFOV = v
    end
})

TriggerSection:Slider({
    Name = "Cooldown",
    Flag = "TriggerCooldown",
    Default = 0.28,
    Min = 0.1,
    Max = 1,
    Decimal = 2,
    Callback = function(v)
        State.TriggerCooldown = v
    end
})

ESPSection:Toggle({
    Name = "ESP",
    Flag = "ESP",
    Default = false,
    Callback = function(v)
        State.ESP = v
    end
})

ESPSection:Toggle({
    Name = "ESP Preview",
    Flag = "ESPPreview",
    Default = false,
    Callback = function(v)
        State.ESPPreview = v
        Outer.Visible = v
        PreviewGui.Enabled = v
    end
})

ESPSection:Toggle({
    Name = "Servo Lines",
    Flag = "ServoLines",
    Default = false,
    Callback = function(v)
        State.ServoLines = v
        if not v then
            for _, line in pairs(ServoLines or {}) do
                line.Visible = false
            end
        end
    end
})

AimviewerSection:Toggle({
    Name = "Aimviewer",
    Flag = "Aimviewer",
    Default = false,
    Callback = function(v)
        State.Aimviewer = v
    end
})

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
    Default = 100,
    Min = 50,
    Max = 250,
    Callback = function(v)
        State.JumpPower = v
        if State.HighJump then applyJumpPower() end
    end
})

AntiSection:Toggle({
    Name = "Anti Detection",
    Flag = "AntiDetection",
    Default = false,
    Callback = function(v)
        setAntiDetection(v)
    end
})

-- ==================== SETTINGS + RGB ====================
Window:Category("Settings")
local SettingsPage = PlayerPage -- fallback
pcall(function()
    SettingsPage = Library:CreateSettingsPage(Window, nil)
end)

-- Extra RGB toggle
local RGBSection = AntiSection
RGBSection:Toggle({
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

pcall(function()
    Window:Init()
end)

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
                FOVCircle:Remove()
                SnapLine:Remove()
                HeadDot:Remove()
                TriggerFOVCircle:Remove()
                for _, data in pairs(Cache) do
                    for _, obj in pairs(data) do obj:Remove() end
                end
                for _, line in pairs(AimviewerCache) do line:Remove() end
                for _, line in pairs(ServoLines) do line:Remove() end
                if PreviewGui then PreviewGui:Destroy() end
            end)
            return oldUnload(Library, ...)
        end
    end
end)
