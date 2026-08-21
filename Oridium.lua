-- ============================================================
-- Oridium Interface
-- Made by @cuakieffer
-- Optimized: state, connections, nil-safety, hot-path caching
-- ============================================================

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

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

-- ==================== SHARED STATE ====================
getgenv().Oridium = getgenv().Oridium or {
    SilentAim = false,
    SilentTarget = nil,
    AntiDetection = false,
}

local State = {
    Aimbot = false,
    Triggerbot = false,
    ESP = false,
    ESPPreview = false,
    OridiumLines = false,
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
    if Connections[name] then
        Connections[name]:Disconnect()
    end
    Connections[name] = conn
    return conn
end

local function unbind(name)
    local c = Connections[name]
    if c then
        c:Disconnect()
        Connections[name] = nil
    end
end

local function unbindAll()
    for name, c in pairs(Connections) do
        pcall(function() c:Disconnect() end)
        Connections[name] = nil
    end
end

-- Local character cache (refreshed on respawn)
local LocalChar, LocalHum, LocalHRP

local function refreshLocalCharacter(char)
    LocalChar = char
    LocalHum = nil
    LocalHRP = nil
    if not char then return end
    LocalHum = char:FindFirstChildOfClass("Humanoid")
    LocalHRP = char:FindFirstChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    refreshLocalCharacter(LocalPlayer.Character)
end

bind("LocalCharacterAdded", LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.35)
    refreshLocalCharacter(char)
    if State.HighJump then
        -- applied later via applyJumpPower once defined; deferred call below
        task.defer(function()
            if State.HighJump and applyJumpPower then
                applyJumpPower()
            end
        end)
    end
end))

bind("LocalCharacterRemoving", LocalPlayer.CharacterRemoving:Connect(function()
    LocalChar, LocalHum, LocalHRP = nil, nil, nil
end))

-- Camera + viewport cache
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

-- ==================== INTRO (unchanged visual behavior) ====================
do
    local sw, sh = Camera and Camera.ViewportSize.X or 1920, Camera and Camera.ViewportSize.Y or 1080
    local cx, cy = sw / 2, sh / 2

    local COL_CORE = Color3.fromRGB(90, 170, 255)
    local COL_GLOW = Color3.fromRGB(170, 220, 255)
    local COL_WHITE = Color3.fromRGB(255, 255, 255)
    local COL_DIM = Color3.fromRGB(60, 110, 180)

    local core = Drawing.new("Circle")
    core.Position = Vector2.new(cx, cy)
    core.Radius = 2
    core.Filled = true
    core.NumSides = 32
    core.Color = COL_GLOW
    core.Visible = true
    core.Transparency = 1

    local rings = {}
    for i = 1, 3 do
        local r = Drawing.new("Circle")
        r.Position = Vector2.new(cx, cy)
        r.Radius = 4
        r.Filled = false
        r.NumSides = 64
        r.Thickness = 1.5
        r.Color = COL_CORE
        r.Visible = true
        r.Transparency = 1
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
    title.Text = "ORIDIUM"
    title.Size = 44
    title.Center = true
    title.Outline = true
    title.OutlineColor = Color3.fromRGB(0, 0, 0)
    title.Color = COL_CORE
    title.Position = Vector2.new(cx, cy - 10)
    title.Visible = true
    title.Transparency = 1

    local sub = Drawing.new("Text")
    sub.Text = "INTERFACE"
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
            task.wait(0.018)
        end

        for frame = 1, 36 do
            local t = frame / 36
            for ri, ring in ipairs(rings) do
                local delay = (ri - 1) * 0.18
                local localT = math.clamp((t - delay) / math.max(1 - delay, 0.001), 0, 1)
                ring.Radius = 8 + localT * (50 + ri * 22)
                ring.Transparency = 1 - localT * 0.75 + localT * localT * 0.6
            end
            for _, o in ipairs(orbiters) do
                o.angle = o.angle + 0.12
                local radius = 18 + t * 28
                o.draw.Position = Vector2.new(cx + math.cos(o.angle) * radius, cy + math.sin(o.angle) * radius)
                o.draw.Transparency = 1 - t
            end
            core.Radius = 8 + math.sin(t * math.pi * 3) * 2
            task.wait(0.016)
        end

        for i = 1, 14 do
            local t = i / 14
            beamL.Transparency = 1 - t
            beamR.Transparency = 1 - t
            beamL.From = Vector2.new(cx, cy)
            beamL.To = Vector2.new(cx - t * (sw * 0.42), cy)
            beamR.From = Vector2.new(cx, cy)
            beamR.To = Vector2.new(cx + t * (sw * 0.42), cy)
            task.wait(0.014)
        end

        for i = 1, 18 do
            local t = i / 18
            title.Transparency = 1 - t
            sub.Transparency = 1 - t
            credit.Transparency = 1 - t * 0.8
            underline.Transparency = 1 - t
            underline.From = Vector2.new(cx - t * 56, cy + 12)
            underline.To = Vector2.new(cx + t * 56, cy + 12)
            for _, ring in ipairs(rings) do ring.Transparency = math.clamp(ring.Transparency + 0.03, 0, 1) end
            for _, o in ipairs(orbiters) do o.draw.Transparency = math.clamp(o.draw.Transparency + 0.04, 0, 1) end
            beamL.Transparency = math.clamp(beamL.Transparency + 0.05, 0, 1)
            beamR.Transparency = math.clamp(beamR.Transparency + 0.05, 0, 1)
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

-- ==================== WINDOW ====================
local Window = Library:CreateWindow({
    Title = 'Oridium Interface | by @cuakieffer',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Blatant         = Window:AddTab('Blatant'),
    Visuals         = Window:AddTab('Visuals'),
    Player          = Window:AddTab('Player'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local CombatBox    = Tabs.Blatant:AddLeftGroupbox('Combat')
local TriggerBox   = Tabs.Blatant:AddRightGroupbox('Triggerbot')
local VisualsBox   = Tabs.Visuals:AddLeftGroupbox('ESP')
local AimviewerBox = Tabs.Visuals:AddRightGroupbox('Aimviewer')
local MovementBox  = Tabs.Player:AddLeftGroupbox('Movement')
local AntiBox      = Tabs.Player:AddRightGroupbox('Anti Detection')

-- ==================== WELCOME ====================
task.defer(function()
    Library:Notify("Thank You For Executing Oridium Interface", 5)
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
    if not head or not hum or not hrp or hum.Health <= 0 then return nil end
    return char, head, hum, hrp
end

-- ==================== DA HOOD / SILENT AIM ====================
local DA_HOOD_PLACE_IDS = {
    [2788229376] = true, [7213786345] = true, [9825515356] = true,
    [1008451066] = true, [5602055394] = true, [9183933413] = true,
}

local function isDaHood()
    if DA_HOOD_PLACE_IDS[game.PlaceId] then return true end
    local ok, name = pcall(function()
        return string.lower(tostring(MarketplaceService:GetProductInfo(game.PlaceId).Name or ""))
    end)
    if ok and name and (string.find(name, "da hood", 1, true) or string.find(name, "dahood", 1, true)) then
        return true
    end
    local mainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
    return mainEvent ~= nil
end

local ON_DA_HOOD = isDaHood()

local function getClosestSilentTarget()
    if not Camera then return nil end
    local closest, shortest = nil, 200
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        local _, head = getTargetParts(player)
        if head then
            local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

local function setSilentAim(enabled)
    if not ON_DA_HOOD then
        getgenv().Oridium.SilentAim = false
        getgenv().Oridium.SilentTarget = nil
        unbind("SilentAimHeartbeat")
        if enabled then
            Library:Notify("Silent Aim only works on Da Hood", 3)
        end
        return
    end

    getgenv().Oridium.SilentAim = enabled
    if not enabled then
        getgenv().Oridium.SilentTarget = nil
        unbind("SilentAimHeartbeat")
        return
    end

    if Connections.SilentAimHeartbeat then return end

    bind("SilentAimHeartbeat", RunService.Heartbeat:Connect(function()
        if getgenv().Oridium.SilentAim then
            getgenv().Oridium.SilentTarget = getClosestSilentTarget()
        else
            getgenv().Oridium.SilentTarget = nil
        end
    end))
end

if ON_DA_HOOD then
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = { ... }

            if getgenv().Oridium.SilentAim then
                local target = getgenv().Oridium.SilentTarget
                if target and target.Parent then
                    if method == "FireServer" and self.Name == "MainEvent" then
                        local action = args[1]
                        if action == "Shoot" or action == "ShootGun" or action == "MousePos" then
                            for i = 2, #args do
                                if typeof(args[i]) == "Vector3" then
                                    args[i] = target.Position
                                end
                            end
                            return oldNamecall(self, unpack(args))
                        end
                    elseif method == "Raycast" and self == workspace then
                        local origin = args[1]
                        if typeof(origin) == "Vector3" then
                            local mag = (typeof(args[2]) == "Vector3" and args[2].Magnitude) or 1000
                            args[2] = (target.Position - origin).Unit * mag
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end
            end

            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

-- ==================== HIGH JUMP ====================
function applyJumpPower()
    if not LocalChar then
        refreshLocalCharacter(LocalPlayer.Character)
    end
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

MovementBox:AddToggle('HighJump', {
    Text = 'High Jump',
    Default = false,
    Callback = function(v)
        State.HighJump = v
        applyJumpPower()
    end
})

MovementBox:AddSlider('JumpPower', {
    Text = 'Jump Power',
    Default = 100, Min = 50, Max = 300, Rounding = 0, Suffix = ' JP',
    Callback = function(v)
        State.JumpPower = v
        if State.HighJump then applyJumpPower() end
    end
})

-- ==================== ANTI DETECTION ====================
AntiBox:AddToggle('AntiDetection', {
    Text = 'Anti Detection',
    Default = false,
    Tooltip = 'Spoofs JumpPower & WalkSpeed',
    Callback = function(v)
        State.AntiDetection = v
        getgenv().Oridium.AntiDetection = v
    end
})

pcall(function()
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

-- ==================== AIMBOT DRAWINGS ====================
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
HeadDot.Radius = 1.6
HeadDot.Filled = true
HeadDot.Visible = false

local function hideAimbotVisuals()
    SnapLine.Visible = false
    HeadDot.Visible = false
end

local function getClosestPlayer()
    if not Camera or not LocalHRP then return nil end

    local closest, shortest = nil, State.AimbotRange
    local fovRadius = State.AimbotFOV * 0.5
    local origin = LocalHRP.Position

    for _, player in ipairs(Players:GetPlayers()) do
        local _, head, _, hrp = getTargetParts(player)
        if head then
            local worldDist = (hrp.Position - origin).Magnitude
            if worldDist <= shortest then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local centerDist = (Vector2.new(sp.X, sp.Y) - ViewportCenter).Magnitude
                    if centerDist <= fovRadius then
                        shortest = worldDist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

CombatBox:AddToggle('Aimbot', {
    Text = 'Aimbot',
    Default = false,
    Callback = function(v)
        State.Aimbot = v
        FOVCircle.Visible = v
        if not v then
            hideAimbotVisuals()
            State.CurrentTarget = nil
        end
    end
}):AddKeyPicker('AimbotKey', { Default = 'Q', SyncToggleState = true, Mode = 'Toggle', Text = 'Aimbot' })

CombatBox:AddToggle('SilentAim', {
    Text = 'Silent Aim (Da Hood Only)',
    Default = false,
    Tooltip = ON_DA_HOOD and 'Works on this Da Hood place' or 'Not Da Hood — silent aim disabled',
    Callback = function(v)
        setSilentAim(v)
    end
})

-- ==================== TRIGGERBOT ====================
local TriggerFOVCircle = Drawing.new("Circle")
TriggerFOVCircle.Color = Color3.fromRGB(0, 255, 150)
TriggerFOVCircle.Thickness = 2
TriggerFOVCircle.NumSides = 64
TriggerFOVCircle.Radius = State.TriggerFOV
TriggerFOVCircle.Filled = false
TriggerFOVCircle.Visible = false

local weaponNames = { "Revolver", "Double Barrel SG", "DoubleBarrel", "Shotgun", "Double Barrel" }

local function equipWeapon()
    local char = LocalChar or LocalPlayer.Character
    if not char then return end
    local hum = LocalHum or char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for i = 1, #weaponNames do
        local name = weaponNames[i]
        local tool = char:FindFirstChild(name) or LocalPlayer.Backpack:FindFirstChild(name)
        if tool and tool:IsA("Tool") then
            hum:EquipTool(tool)
            return
        end
    end
end

local function simulateClick()
    -- Yield outside the render callback
    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.04)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end)
end

local function getPlayerInMouseFOV()
    if not Camera then return nil end
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestDist = nil, State.TriggerFOV

    for _, player in ipairs(Players:GetPlayers()) do
        local _, head = getTargetParts(player)
        if head then
            local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if dist <= closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

TriggerBox:AddToggle('Triggerbot', {
    Text = 'Triggerbot',
    Default = false,
    Callback = function(v)
        State.Triggerbot = v
        TriggerFOVCircle.Visible = v
    end
})

TriggerBox:AddSlider('TriggerFOV', {
    Text = 'Trigger FOV',
    Default = 70, Min = 20, Max = 150, Rounding = 0,
    Callback = function(v)
        State.TriggerFOV = v
        TriggerFOVCircle.Radius = v
    end
})

-- ==================== ESP ====================
local ESP_SETTINGS = {
    BoxColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    BoxWidth = 10,
    MaxDistance = 2000
}
local Cache = {}

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do
        d[k] = v
    end
    return d
end

local function createESP(player)
    if player == LocalPlayer or Cache[player] then return end
    Cache[player] = {
        Box = newDrawing("Square", { Thickness = 1, Filled = false, Color = ESP_SETTINGS.BoxColor, Visible = false }),
        HealthBG = newDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.fromRGB(20, 20, 20), Visible = false }),
        HealthBar = newDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.fromRGB(0, 255, 0), Visible = false }),
        Distance = newDrawing("Text", { Size = 13, Center = true, Outline = true, Color = ESP_SETTINGS.TextColor, Font = 2, Visible = false }),
    }
end

local function removeESP(player)
    local data = Cache[player]
    if not data then return end
    for _, obj in pairs(data) do
        pcall(function() obj:Remove() end)
    end
    Cache[player] = nil
end

local function hideESP(player)
    local data = Cache[player]
    if not data then return end
    data.Box.Visible = false
    data.HealthBG.Visible = false
    data.HealthBar.Visible = false
    data.Distance.Visible = false
end

local function updateESP(player)
    local data = Cache[player]
    if not data or not Camera then return end

    local char, head, hum, hrp = getTargetParts(player)
    if not char then
        hideESP(player)
        return
    end

    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    if dist > ESP_SETTINGS.MaxDistance then
        hideESP(player)
        return
    end

    local top = head.Position + Vector3.new(0, 0.5, 0)
    local bottom = hrp.Position - Vector3.new(0, 3, 0)
    local topS, topV = Camera:WorldToViewportPoint(top)
    local botS, botV = Camera:WorldToViewportPoint(bottom)
    if not (topV and botV) then
        hideESP(player)
        return
    end

    local height = math.abs(botS.Y - topS.Y)
    local centerX = (topS.X + botS.X) * 0.5
    local width = ESP_SETTINGS.BoxWidth

    data.Box.Size = Vector2.new(width, height)
    data.Box.Position = Vector2.new(centerX - width * 0.5, topS.Y)
    data.Box.Color = ESP_SETTINGS.BoxColor
    data.Box.Visible = true

    local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local barX = centerX - width * 0.5 - 5
    data.HealthBG.Size = Vector2.new(2, height)
    data.HealthBG.Position = Vector2.new(barX, topS.Y)
    data.HealthBG.Visible = true
    data.HealthBar.Size = Vector2.new(2, height * hp)
    data.HealthBar.Position = Vector2.new(barX, topS.Y + height * (1 - hp))
    data.HealthBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
    data.HealthBar.Visible = true

    data.Distance.Text = math.floor(dist) .. " studs"
    data.Distance.Position = Vector2.new(centerX, botS.Y + 2)
    data.Distance.Color = ESP_SETTINGS.TextColor
    data.Distance.Visible = true
end

VisualsBox:AddToggle('ESP', {
    Text = 'ESP',
    Default = false,
    Callback = function(v)
        State.ESP = v
        if not v then
            for p in pairs(Cache) do hideESP(p) end
        end
    end
}):AddKeyPicker('ESPKey', { Default = 'M', SyncToggleState = true, Mode = 'Toggle', Text = 'ESP' })

VisualsBox:AddLabel('ESP Color'):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        ESP_SETTINGS.BoxColor = v
        ESP_SETTINGS.TextColor = v
    end
})

-- ==================== ESP PREVIEW ====================
local PREVIEW = {
    MainColor = Color3.fromRGB(28, 28, 28),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    AccentColor = Color3.fromRGB(100, 180, 255),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    FontColor = Color3.fromRGB(255, 255, 255),
    DimColor = Color3.fromRGB(160, 160, 160),
}

local PreviewGui = Instance.new("ScreenGui")
PreviewGui.Name = "OridiumESPPreview"
PreviewGui.ResetOnSpawn = false
PreviewGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    PreviewGui.Parent = (gethui and gethui()) or CoreGui
end)
if not PreviewGui.Parent then
    PreviewGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Outer = Instance.new("Frame")
Outer.Name = "Outer"
Outer.BackgroundColor3 = Color3.new(0, 0, 0)
Outer.BorderSizePixel = 0
Outer.Position = UDim2.new(0.5, 290, 0.5, -200)
Outer.Size = UDim2.new(0, 220, 0, 400)
Outer.Visible = false
Outer.Parent = PreviewGui

local OuterCorner = Instance.new("UICorner")
OuterCorner.CornerRadius = UDim.new(0, 2)
OuterCorner.Parent = Outer

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
List.Position = UDim2.new(0, 6, 0, 34)
List.Size = UDim2.new(1, -12, 1, -42)
List.ScrollBarThickness = 3
List.ScrollBarImageColor3 = PREVIEW.AccentColor
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = Inner

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = List

local ListPad = Instance.new("UIPadding")
ListPad.PaddingTop = UDim.new(0, 4)
ListPad.PaddingBottom = UDim.new(0, 4)
ListPad.PaddingLeft = UDim.new(0, 4)
ListPad.PaddingRight = UDim.new(0, 4)
ListPad.Parent = List

local PreviewCards = {}

local function makeHologram(parent)
    local holo = Instance.new("Frame")
    holo.BackgroundTransparency = 1
    holo.Size = UDim2.new(0, 28, 0, 48)
    holo.Parent = parent

    local function part(props)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = PREVIEW.AccentColor
        f.BackgroundTransparency = props.t or 0.45
        f.BorderSizePixel = 0
        f.Position = props.p
        f.Size = props.s
        f.Parent = holo
        if props.circle then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = f
        end
        return f
    end

    part({ p = UDim2.new(0.5, -6, 0, 2), s = UDim2.new(0, 12, 0, 12), t = 0.35, circle = true })
    part({ p = UDim2.new(0.5, -7, 0, 15), s = UDim2.new(0, 14, 0, 18), t = 0.45 })
    part({ p = UDim2.new(0.5, -7, 0, 34), s = UDim2.new(0, 5, 0, 12), t = 0.5 })
    part({ p = UDim2.new(0.5, 2, 0, 34), s = UDim2.new(0, 5, 0, 12), t = 0.5 })
    part({ p = UDim2.new(0.5, -12, 0, 16), s = UDim2.new(0, 4, 0, 12), t = 0.5 })
    part({ p = UDim2.new(0.5, 8, 0, 16), s = UDim2.new(0, 4, 0, 12), t = 0.5 })
    return holo
end

local function createPreviewCard(player)
    if player == LocalPlayer or PreviewCards[player] then return end

    local card = Instance.new("Frame")
    card.Name = player.Name
    card.BackgroundColor3 = PREVIEW.MainColor
    card.BorderColor3 = PREVIEW.OutlineColor
    card.BorderSizePixel = 1
    card.Size = UDim2.new(1, -4, 0, 56)
    card.Parent = List

    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = PREVIEW.AccentColor
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(0, 2, 1, 0)
    accent.Parent = card

    local holo = makeHologram(card)
    holo.Position = UDim2.new(0, 8, 0.5, -24)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Position = UDim2.new(0, 42, 0, 6)
    nameLbl.Size = UDim2.new(1, -50, 0, 16)
    nameLbl.Font = Enum.Font.Code
    nameLbl.Text = player.Name
    nameLbl.TextColor3 = PREVIEW.FontColor
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = card

    local distLbl = Instance.new("TextLabel")
    distLbl.BackgroundTransparency = 1
    distLbl.Position = UDim2.new(0, 42, 0, 22)
    distLbl.Size = UDim2.new(1, -50, 0, 14)
    distLbl.Font = Enum.Font.Code
    distLbl.Text = "-- studs"
    distLbl.TextColor3 = PREVIEW.DimColor
    distLbl.TextSize = 11
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.Parent = card

    local hpBG = Instance.new("Frame")
    hpBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    hpBG.BorderSizePixel = 0
    hpBG.Position = UDim2.new(0, 42, 0, 40)
    hpBG.Size = UDim2.new(1, -54, 0, 6)
    hpBG.Parent = card

    local hpBar = Instance.new("Frame")
    hpBar.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
    hpBar.BorderSizePixel = 0
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.Parent = hpBG

    PreviewCards[player] = {
        Card = card,
        Name = nameLbl,
        Dist = distLbl,
        HpBar = hpBar,
        Accent = accent,
    }
end

local function removePreviewCard(player)
    local data = PreviewCards[player]
    if not data then return end
    pcall(function() data.Card:Destroy() end)
    PreviewCards[player] = nil
end

local function updatePreviewCard(player)
    local data = PreviewCards[player]
    if not data then return end

    local _, _, hum, hrp = getTargetParts(player)
    if not hrp then
        data.Card.Visible = false
        return
    end

    data.Card.Visible = true
    if player.DisplayName ~= player.Name then
        data.Name.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    else
        data.Name.Text = player.Name
    end

    local dist = 0
    if LocalHRP then
        dist = (hrp.Position - LocalHRP.Position).Magnitude
    end
    data.Dist.Text = math.floor(dist) .. " studs"

    if hum then
        local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        data.HpBar.Size = UDim2.new(hp, 0, 1, 0)
        data.HpBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - hp), 220 * hp, 40)
        data.Accent.BackgroundColor3 = hp > 0.3 and PREVIEW.AccentColor or Color3.fromRGB(220, 60, 60)
    end
end

local function refreshPreviewList()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            createPreviewCard(p)
        end
    end
end

VisualsBox:AddToggle('ESPPreview', {
    Text = 'ESP Preview',
    Default = false,
    Tooltip = 'Linoria-styled panel showing player holograms',
    Callback = function(v)
        State.ESPPreview = v
        Outer.Visible = v
        if v then refreshPreviewList() end
    end
})

-- ==================== ORIDIUM LINES ====================
local OridiumLines = {}

local function createOridiumLine(player)
    if player == LocalPlayer or OridiumLines[player] then return end
    local line = Drawing.new("Line")
    line.Color = lightBlue
    line.Thickness = 1.4
    line.Visible = false
    OridiumLines[player] = line
end

local function removeOridiumLine(player)
    local line = OridiumLines[player]
    if not line then return end
    pcall(function() line:Remove() end)
    OridiumLines[player] = nil
end

local function updateOridiumLine(player)
    local line = OridiumLines[player]
    if not line or not Camera then return end

    local _, head = getTargetParts(player)
    if not head then
        line.Visible = false
        return
    end

    local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        line.Visible = false
        return
    end

    line.From = ViewportBottom
    line.To = Vector2.new(sp.X, sp.Y)
    line.Color = lightBlue
    line.Visible = true
end

VisualsBox:AddToggle('OridiumLines', {
    Text = 'Oridium Lines',
    Default = false,
    Tooltip = 'Tracers from bottom of screen to players',
    Callback = function(v)
        State.OridiumLines = v
        if not v then
            for _, line in pairs(OridiumLines) do line.Visible = false end
        end
    end
})

-- ==================== AIMVIEWER ====================
local AimviewerCache = {}

local function createAimviewer(player)
    if player == LocalPlayer or AimviewerCache[player] then return end
    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(255, 80, 80)
    line.Thickness = 1.5
    line.Visible = false
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
    if not line or not Camera then return end

    local _, head = getTargetParts(player)
    if not head then
        line.Visible = false
        return
    end

    local endPos = head.Position + head.CFrame.LookVector * 80
    local s1, v1 = Camera:WorldToViewportPoint(head.Position)
    local s2, v2 = Camera:WorldToViewportPoint(endPos)
    if v1 and v2 then
        line.From = Vector2.new(s1.X, s1.Y)
        line.To = Vector2.new(s2.X, s2.Y)
        line.Visible = true
    else
        line.Visible = false
    end
end

AimviewerBox:AddToggle('Aimviewer', {
    Text = 'Aimviewer',
    Default = false,
    Callback = function(v)
        State.Aimviewer = v
        if not v then
            for _, line in pairs(AimviewerCache) do line.Visible = false end
        end
    end
})

-- ==================== PLAYER LIFECYCLE ====================
local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    createESP(player)
    createAimviewer(player)
    createOridiumLine(player)
    if State.ESPPreview then
        createPreviewCard(player)
    end
end

local function onPlayerRemoving(player)
    removeESP(player)
    removeAimviewer(player)
    removeOridiumLine(player)
    removePreviewCard(player)
    if State.CurrentTarget == player then
        State.CurrentTarget = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end
bind("PlayerAdded", Players.PlayerAdded:Connect(onPlayerAdded))
bind("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))

-- ==================== MAIN LOOP ====================
bind("MainLoop", RunService.RenderStepped:Connect(function()
    if not Camera then
        refreshCamera()
        if not Camera then return end
    end

    -- Keep local character cache warm
    if not LocalHRP and LocalPlayer.Character then
        refreshLocalCharacter(LocalPlayer.Character)
    end

    local now = tick()

    if State.Triggerbot then
        TriggerFOVCircle.Position = UserInputService:GetMouseLocation()
        if (now - State.LastTrigger) >= State.TriggerCooldown then
            local target = getPlayerInMouseFOV()
            if target then
                equipWeapon()
                simulateClick()
                State.LastTrigger = now
            end
        end
    end

    if State.Aimbot then
        FOVCircle.Position = ViewportCenter
        FOVCircle.Radius = State.AimbotFOV * 0.5

        if not State.CurrentTarget or not isValidTarget(State.CurrentTarget) then
            State.CurrentTarget = getClosestPlayer()
        end

        local target = State.CurrentTarget
        if target then
            local _, head = getTargetParts(target)
            if head then
                local sp = Camera:WorldToViewportPoint(head.Position)
                SnapLine.From = ViewportCenter
                SnapLine.To = Vector2.new(sp.X, sp.Y)
                SnapLine.Visible = true
                HeadDot.Position = Vector2.new(sp.X, sp.Y)
                HeadDot.Visible = true
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), State.Smoothness)
            else
                hideAimbotVisuals()
            end
        else
            hideAimbotVisuals()
        end
    end

    if State.ESP then
        for player in pairs(Cache) do
            updateESP(player)
        end
    end

    if State.Aimviewer then
        for player in pairs(AimviewerCache) do
            updateAimviewer(player)
        end
    end

    if State.OridiumLines then
        for player in pairs(OridiumLines) do
            updateOridiumLine(player)
        end
    end

    if State.ESPPreview then
        for player in pairs(PreviewCards) do
            updatePreviewCard(player)
        end
    end
end))

-- ==================== UI SETTINGS + RGB ====================
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    Text = 'Menu keybind',
    Mode = 'Toggle',
})
Library.ToggleKeybind = Options.MenuKeybind

local DEFAULT_ACCENT = Color3.fromRGB(100, 180, 255)
local DEFAULT_ACCENT_DARK = Color3.fromRGB(60, 120, 180)

local function setRGB(enabled)
    State.RGB = enabled
    if not enabled then
        unbind("RGBLoop")
        Library.AccentColor = DEFAULT_ACCENT
        Library.AccentColorDark = DEFAULT_ACCENT_DARK
        PREVIEW.AccentColor = DEFAULT_ACCENT
        AccentBar.BackgroundColor3 = DEFAULT_ACCENT
        if Library.UpdateColorsUsingRegistry then
            pcall(function() Library:UpdateColorsUsingRegistry() end)
        end
        return
    end

    if Connections.RGBLoop then return end

    bind("RGBLoop", RunService.Heartbeat:Connect(function()
        if not State.RGB then return end
        local color = Color3.fromHSV((tick() * 0.25) % 1, 1, 1)
        Library.AccentColor = color
        Library.AccentColorDark = color:Lerp(Color3.new(0, 0, 0), 0.35)
        PREVIEW.AccentColor = color
        if Outer.Visible then
            AccentBar.BackgroundColor3 = color
        end
        if Library.UpdateColorsUsingRegistry then
            pcall(function() Library:UpdateColorsUsingRegistry() end)
        end
    end))
end

MenuGroup:AddToggle('RGBMode', {
    Text = 'RGB',
    Default = false,
    Tooltip = 'Makes the UI outline cycle through RGB colors',
    Callback = function(v)
        setRGB(v)
    end
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder('OridiumInterface')
SaveManager:SetFolder('OridiumInterface/Configs')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

Library:OnUnload(function()
    State.Aimbot = false
    State.Triggerbot = false
    State.ESP = false
    State.ESPPreview = false
    State.OridiumLines = false
    State.Aimviewer = false
    State.RGB = false
    getgenv().Oridium.SilentAim = false
    getgenv().Oridium.SilentTarget = nil

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
        for _, line in pairs(OridiumLines) do line:Remove() end
        if PreviewGui then PreviewGui:Destroy() end
    end)
end)

SaveManager:LoadAutoloadConfig()
