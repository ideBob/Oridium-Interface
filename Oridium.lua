-- ============================================================
-- Oridium Interface
-- Made by @cuakieffer
-- ============================================================

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- ==================== INTRO ANIMATION ====================
do
    local Camera = workspace.CurrentCamera
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local title = Drawing.new("Text")
    title.Text = "Oridium..."
    title.Size = 48
    title.Center = true
    title.Outline = true
    title.OutlineColor = Color3.fromRGB(0, 0, 0)
    title.Color = Color3.fromRGB(100, 180, 255)
    title.Position = center
    title.Visible = true
    title.Transparency = 1

    local sub = Drawing.new("Text")
    sub.Text = "by @cuakieffer"
    sub.Size = 18
    sub.Center = true
    sub.Outline = true
    sub.Color = Color3.fromRGB(180, 220, 255)
    sub.Position = center + Vector2.new(0, 40)
    sub.Visible = true
    sub.Transparency = 1

    local boltSegments = {}
    local boltPoints = {
        Vector2.new(center.X - 10, center.Y - 220),
        Vector2.new(center.X + 25, center.Y - 160),
        Vector2.new(center.X - 15, center.Y - 100),
        Vector2.new(center.X + 30, center.Y - 50),
        Vector2.new(center.X - 5, center.Y - 10),
        Vector2.new(center.X + 5, center.Y + 5),
    }

    for i = 1, #boltPoints - 1 do
        local line = Drawing.new("Line")
        line.From = boltPoints[i]
        line.To = boltPoints[i]
        line.Color = Color3.fromRGB(180, 220, 255)
        line.Thickness = 3
        line.Visible = true
        line.Transparency = 1
        table.insert(boltSegments, line)
    end

    local flash = Drawing.new("Circle")
    flash.Position = center
    flash.Radius = 5
    flash.Color = Color3.fromRGB(255, 255, 255)
    flash.Filled = true
    flash.NumSides = 32
    flash.Visible = false
    flash.Transparency = 1

    task.spawn(function()
        for i = 1, 20 do
            title.Transparency = 1 - (i / 20)
            sub.Transparency = 1 - (i / 20)
            task.wait(0.02)
        end
        task.wait(0.35)

        for i, line in ipairs(boltSegments) do
            line.Transparency = 0
            line.To = boltPoints[i + 1]
            task.wait(0.035)
        end

        flash.Visible = true
        flash.Transparency = 0
        for i = 1, 12 do
            flash.Radius = 5 + i * 8
            flash.Transparency = i / 12
            task.wait(0.015)
        end
        flash.Visible = false

        local originalPos = title.Position
        for i = 1, 14 do
            title.Position = originalPos + Vector2.new(math.random(-8, 8), math.random(-5, 5))
            title.Color = (i % 2 == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 180, 255)
            task.wait(0.025)
        end
        title.Position = originalPos
        title.Color = Color3.fromRGB(100, 180, 255)

        task.wait(0.55)

        for i = 1, 25 do
            local t = i / 25
            title.Transparency = t
            sub.Transparency = t
            for _, line in ipairs(boltSegments) do
                line.Transparency = t
            end
            task.wait(0.018)
        end

        title:Remove()
        sub:Remove()
        flash:Remove()
        for _, line in ipairs(boltSegments) do
            line:Remove()
        end
    end)

    task.wait(2.8)
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

-- ==================== SERVICES & SHARED ====================
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

getgenv().Oridium = getgenv().Oridium or {
    SilentAim = false,
    SilentTarget = nil,
    AntiDetection = false,
}

local function isValidTarget(player)
    return player and player.Character
        and player.Character:FindFirstChild("Head")
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

-- ==================== DA HOOD CHECK ====================
-- Only enable silent aim logic on real Da Hood places
local DA_HOOD_PLACE_IDS = {
    [2788229376] = true,  -- Da Hood
    [7213786345] = true,  -- Da Hood related
    [9825515356] = true,  -- Da Hood variants
    [1008451066] = true,
    [5602055394] = true,
    [9183933413] = true,
}

local function isDaHood()
    if DA_HOOD_PLACE_IDS[game.PlaceId] then
        return true
    end
    local name = string.lower(tostring(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or ""))
    if string.find(name, "da hood") or string.find(name, "dahood") then
        return true
    end
    -- Fallback: MainEvent exists (classic Da Hood gun system)
    local ok = pcall(function()
        return game:GetService("ReplicatedStorage"):FindFirstChild("MainEvent") ~= nil
    end)
    return ok and game:GetService("ReplicatedStorage"):FindFirstChild("MainEvent") ~= nil
end

local ON_DA_HOOD = isDaHood()

-- ==================== SILENT AIM (DA HOOD ONLY) ====================
local function getClosestSilentTarget()
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
    return closest
end

if ON_DA_HOOD then
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if getgenv().Oridium.SilentAim and getgenv().Oridium.SilentTarget then
                local target = getgenv().Oridium.SilentTarget

                -- Da Hood MainEvent Shoot
                if method == "FireServer" and tostring(self.Name) == "MainEvent" then
                    if args[1] == "Shoot" or args[1] == "ShootGun" or args[1] == "MousePos" then
                        -- redirect mouse position style args when present
                        for i = 2, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = target.Position
                            end
                        end
                        return oldNamecall(self, unpack(args))
                    end
                end

                -- Raycasts used by some DH gun scripts
                if method == "Raycast" and self == workspace then
                    local origin = args[1]
                    if typeof(origin) == "Vector3" then
                        args[2] = (target.Position - origin).Unit * ((typeof(args[2]) == "Vector3" and args[2].Magnitude) or 1000)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end

            return oldNamecall(self, ...)
        end)

        setreadonly(mt, true)
    end)

    RunService.Heartbeat:Connect(function()
        if getgenv().Oridium.SilentAim then
            getgenv().Oridium.SilentTarget = getClosestSilentTarget()
        else
            getgenv().Oridium.SilentTarget = nil
        end
    end)
end

-- ==================== HIGH JUMP ====================
local highJumpEnabled = false
local jumpPowerValue = 100

local function applyJumpPower()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if highJumpEnabled then
        hum.UseJumpPower = true
        hum.JumpPower = jumpPowerValue
        pcall(function() hum.JumpHeight = jumpPowerValue / 3.5 end)
    else
        hum.JumpPower = 50
        pcall(function() hum.JumpHeight = 7.2 end)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.4)
    if highJumpEnabled then applyJumpPower() end
end)

MovementBox:AddToggle('HighJump', {
    Text = 'High Jump',
    Default = false,
    Callback = function(v)
        highJumpEnabled = v
        applyJumpPower()
    end
})

MovementBox:AddSlider('JumpPower', {
    Text = 'Jump Power',
    Default = 100,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Suffix = ' JP',
    Callback = function(v)
        jumpPowerValue = v
        if highJumpEnabled then applyJumpPower() end
    end
})

-- ==================== ANTI DETECTION ====================
local antiDetectionEnabled = false

AntiBox:AddToggle('AntiDetection', {
    Text = 'Anti Detection',
    Default = false,
    Tooltip = 'Spoofs JumpPower & WalkSpeed',
    Callback = function(v)
        antiDetectionEnabled = v
        getgenv().Oridium.AntiDetection = v
    end
})

pcall(function()
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if antiDetectionEnabled and self:IsA("Humanoid") and self:IsDescendantOf(LocalPlayer.Character) then
            if key == "JumpPower" then return 50 end
            if key == "WalkSpeed" then return 16 end
        end
        return oldIndex(self, key)
    end)
end)

-- ==================== AIMBOT ====================
local aimbotEnabled = false
local aimbotFOV = 360
local aimbotMaxRange = 1000
local smoothness = 0.18
local currentTarget = nil
local lightBlue = Color3.fromRGB(100, 180, 255)

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = lightBlue
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Radius = aimbotFOV / 2
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Snap line: not too skinny
local SnapLine = Drawing.new("Line")
SnapLine.Color = lightBlue
SnapLine.Thickness = 1.8
SnapLine.Visible = false

-- Head dot: skinny / small
local HeadDot = Drawing.new("Circle")
HeadDot.Color = lightBlue
HeadDot.Thickness = 1
HeadDot.NumSides = 16
HeadDot.Radius = 1.6
HeadDot.Filled = true
HeadDot.Visible = false

local function updateFOVCircle()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function updateSnapLine(pos)
    SnapLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local sp = Camera:WorldToViewportPoint(pos)
    SnapLine.To = Vector2.new(sp.X, sp.Y)
    SnapLine.Visible = true
end

local function updateHeadDot(pos)
    local sp = Camera:WorldToViewportPoint(pos)
    HeadDot.Position = Vector2.new(sp.X, sp.Y)
    HeadDot.Visible = true
end

local function getClosestPlayer()
    local closest, shortest = nil, math.huge
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isValidTarget(player) then
            local head = player.Character.Head
            local dist = (head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if dist <= aimbotMaxRange then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local centerDist = (Vector2.new(sp.X, sp.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if centerDist <= aimbotFOV/2 and dist < shortest then
                        shortest = dist
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
        aimbotEnabled = v
        FOVCircle.Visible = v
        if not v then
            SnapLine.Visible = false
            HeadDot.Visible = false
            currentTarget = nil
        end
    end
}):AddKeyPicker('AimbotKey', {
    Default = 'Q',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Aimbot',
})

CombatBox:AddToggle('SilentAim', {
    Text = 'Silent Aim (Da Hood Only)',
    Default = false,
    Tooltip = ON_DA_HOOD and 'Works on this Da Hood place' or 'Not Da Hood — silent aim disabled',
    Callback = function(v)
        if not ON_DA_HOOD then
            getgenv().Oridium.SilentAim = false
            Library:Notify('Silent Aim only works on Da Hood', 3)
            return
        end
        getgenv().Oridium.SilentAim = v
    end
})

-- ==================== TRIGGERBOT ====================
local triggerbotEnabled = false
local triggerFOV = 70
local triggerCooldown = 0.28
local lastTriggerTime = 0

local TriggerFOVCircle = Drawing.new("Circle")
TriggerFOVCircle.Color = Color3.fromRGB(0, 255, 150)
TriggerFOVCircle.Thickness = 2
TriggerFOVCircle.NumSides = 64
TriggerFOVCircle.Radius = triggerFOV
TriggerFOVCircle.Filled = false
TriggerFOVCircle.Visible = false

local weaponNames = {"Revolver", "Double Barrel SG", "DoubleBarrel", "Shotgun", "Double Barrel"}

local function equipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, name in ipairs(weaponNames) do
        local tool = char:FindFirstChild(name) or LocalPlayer.Backpack:FindFirstChild(name)
        if tool and tool:IsA("Tool") then
            hum:EquipTool(tool)
            return
        end
    end
end

local function simulateClick()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.04)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

local function getPlayerInMouseFOV()
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isValidTarget(player) then
            local head = player.Character.Head
            local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if dist <= triggerFOV and dist < closestDist then
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
        triggerbotEnabled = v
        TriggerFOVCircle.Visible = v
    end
})

TriggerBox:AddSlider('TriggerFOV', {
    Text = 'Trigger FOV',
    Default = 70,
    Min = 20,
    Max = 150,
    Rounding = 0,
    Callback = function(v)
        triggerFOV = v
        TriggerFOVCircle.Radius = v
    end
})

-- ==================== ESP ====================
local espEnabled = false
local ESP_SETTINGS = {
    BoxColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    BoxWidth = 10,
    MaxDistance = 2000
}
local Cache = {}

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function createESP(player)
    if Cache[player] then return end
    Cache[player] = {
        Box = newDrawing("Square", {Thickness = 1, Filled = false, Color = ESP_SETTINGS.BoxColor, Visible = false}),
        HealthBG = newDrawing("Square", {Thickness = 1, Filled = true, Color = Color3.fromRGB(20,20,20), Visible = false}),
        HealthBar = newDrawing("Square", {Thickness = 1, Filled = true, Color = Color3.fromRGB(0,255,0), Visible = false}),
        Distance = newDrawing("Text", {Size = 13, Center = true, Outline = true, Color = ESP_SETTINGS.TextColor, Font = 2, Visible = false}),
    }
end

local function removeESP(player)
    if not Cache[player] then return end
    for _, obj in pairs(Cache[player]) do pcall(function() obj:Remove() end) end
    Cache[player] = nil
end

local function hideESP(player)
    if not Cache[player] then return end
    for _, obj in pairs(Cache[player]) do obj.Visible = false end
end

local function updateESP(player)
    local data = Cache[player]
    if not data then return end
    if not isValidTarget(player) then return hideESP(player) end

    local hrp = player.Character.HumanoidRootPart
    local head = player.Character.Head
    local hum = player.Character.Humanoid
    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    if dist > ESP_SETTINGS.MaxDistance then return hideESP(player) end

    local top = head.Position + Vector3.new(0, 0.5, 0)
    local bottom = hrp.Position - Vector3.new(0, 3, 0)
    local topS, topV = Camera:WorldToViewportPoint(top)
    local botS, botV = Camera:WorldToViewportPoint(bottom)
    if not (topV and botV) then return hideESP(player) end

    local height = math.abs(botS.Y - topS.Y)
    local centerX = (topS.X + botS.X) / 2
    local width = ESP_SETTINGS.BoxWidth

    data.Box.Size = Vector2.new(width, height)
    data.Box.Position = Vector2.new(centerX - width/2, topS.Y)
    data.Box.Color = ESP_SETTINGS.BoxColor
    data.Box.Visible = true

    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    local barX = centerX - width/2 - 5
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
        espEnabled = v
        if not v then
            for p in pairs(Cache) do hideESP(p) end
        end
    end
}):AddKeyPicker('ESPKey', {
    Default = 'M',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'ESP',
})

VisualsBox:AddLabel('ESP Color'):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        ESP_SETTINGS.BoxColor = v
        ESP_SETTINGS.TextColor = v
    end
})

-- ==================== ORIDIUM LINES (TRACERS) ====================
local oridiumLinesEnabled = false
local OridiumLines = {}

local function createOridiumLine(player)
    if OridiumLines[player] then return end
    local line = Drawing.new("Line")
    line.Color = lightBlue
    line.Thickness = 1.4
    line.Visible = false
    OridiumLines[player] = line
end

local function removeOridiumLine(player)
    if OridiumLines[player] then
        pcall(function() OridiumLines[player]:Remove() end)
        OridiumLines[player] = nil
    end
end

local function updateOridiumLine(player)
    local line = OridiumLines[player]
    if not line then return end
    if not isValidTarget(player) then
        line.Visible = false
        return
    end

    local head = player.Character.Head
    local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        line.Visible = false
        return
    end

    -- From bottom center of screen to head
    local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    line.From = from
    line.To = Vector2.new(sp.X, sp.Y)
    line.Color = lightBlue
    line.Visible = true
end

VisualsBox:AddToggle('OridiumLines', {
    Text = 'Oridium Lines',
    Default = false,
    Tooltip = 'Tracers from bottom of screen to players',
    Callback = function(v)
        oridiumLinesEnabled = v
        if not v then
            for _, line in pairs(OridiumLines) do
                line.Visible = false
            end
        end
    end
})

-- ==================== AIMVIEWER ====================
local aimviewerEnabled = false
local AimviewerCache = {}

local function createAimviewer(player)
    if AimviewerCache[player] then return end
    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(255, 80, 80)
    line.Thickness = 1.5
    line.Visible = false
    AimviewerCache[player] = line
end

local function removeAimviewer(player)
    if AimviewerCache[player] then
        pcall(function() AimviewerCache[player]:Remove() end)
        AimviewerCache[player] = nil
    end
end

local function updateAimviewer(player)
    local line = AimviewerCache[player]
    if not line or not isValidTarget(player) then
        if line then line.Visible = false end
        return
    end
    local head = player.Character.Head
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
    Callback = function(v) aimviewerEnabled = v end
})

-- ==================== PLAYER EVENTS ====================
local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    createESP(player)
    createAimviewer(player)
    createOridiumLine(player)
end

local function onPlayerRemoving(player)
    removeESP(player)
    removeAimviewer(player)
    removeOridiumLine(player)
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    local now = tick()

    updateFOVCircle()

    if triggerbotEnabled then
        TriggerFOVCircle.Position = UserInputService:GetMouseLocation()
        local target = getPlayerInMouseFOV()
        if target and (now - lastTriggerTime) >= triggerCooldown then
            equipWeapon()
            simulateClick()
            lastTriggerTime = now
        end
    end

    if aimbotEnabled then
        if not currentTarget or not isValidTarget(currentTarget) then
            currentTarget = getClosestPlayer()
        end
        if currentTarget and isValidTarget(currentTarget) then
            local head = currentTarget.Character.Head
            updateSnapLine(head.Position)
            updateHeadDot(head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), smoothness)
        else
            SnapLine.Visible = false
            HeadDot.Visible = false
        end
    else
        SnapLine.Visible = false
        HeadDot.Visible = false
    end

    if espEnabled then
        for player in pairs(Cache) do
            pcall(updateESP, player)
        end
    end

    if aimviewerEnabled then
        for player in pairs(AimviewerCache) do
            pcall(updateAimviewer, player)
        end
    end

    if oridiumLinesEnabled then
        for player in pairs(OridiumLines) do
            pcall(updateOridiumLine, player)
        end
    end
end)

-- ==================== UI SETTINGS + RGB ====================
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    Text = 'Menu keybind',
    Mode = 'Toggle',
})

Library.ToggleKeybind = Options.MenuKeybind

local rgbEnabled = false

MenuGroup:AddToggle('RGBMode', {
    Text = 'RGB',
    Default = false,
    Tooltip = 'Makes the UI outline cycle through RGB colors',
    Callback = function(Value)
        rgbEnabled = Value
        if not Value then
            Library.AccentColor = Color3.fromRGB(100, 180, 255)
            Library.AccentColorDark = Color3.fromRGB(60, 120, 180)
            if Library.UpdateColorsUsingRegistry then
                pcall(function() Library:UpdateColorsUsingRegistry() end)
            end
        end
    end
})

task.spawn(function()
    while true do
        if rgbEnabled and Library then
            local hue = (tick() * 0.25) % 1
            local color = Color3.fromHSV(hue, 1, 1)
            Library.AccentColor = color
            Library.AccentColorDark = color:Lerp(Color3.new(0, 0, 0), 0.35)
            if Library.UpdateColorsUsingRegistry then
                pcall(function() Library:UpdateColorsUsingRegistry() end)
            end
        end
        task.wait(0.03)
    end
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder('OridiumInterface')
SaveManager:SetFolder('OridiumInterface/Configs')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

Library:OnUnload(function()
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
    end)
end)

SaveManager:LoadAutoloadConfig()
