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
    Blatant              = Window:AddTab('Blatant'),
    Visuals              = Window:AddTab('Visuals'),
    Player               = Window:AddTab('Player'),
    ['Customization']    = Window:AddTab('Player Customization'),
    ['Good/Bad']         = Window:AddTab('Good/Bad Boys'),
    ['UI Customization'] = Window:AddTab('UI Customization'),
    ['UI Settings']      = Window:AddTab('UI Settings'),
}

local CombatBox     = Tabs.Blatant:AddLeftGroupbox('Combat')
local TriggerBox    = Tabs.Blatant:AddRightGroupbox('Triggerbot')
local VisualsBox    = Tabs.Visuals:AddLeftGroupbox('ESP')
local AimviewerBox  = Tabs.Visuals:AddRightGroupbox('Aimviewer')
local MovementBox   = Tabs.Player:AddLeftGroupbox('Movement')
local AntiBox       = Tabs.Player:AddRightGroupbox('Anti Detection')
local CustomBox     = Tabs['Customization']:AddLeftGroupbox('Accessories')
local CustomInfoBox = Tabs['Customization']:AddRightGroupbox('Info')
local BoysBox       = Tabs['Good/Bad']:AddLeftGroupbox('Oridium Boys')
local ActionsBox    = Tabs['Good/Bad']:AddRightGroupbox('Actions')
local UIThemeBox    = Tabs['UI Customization']:AddLeftGroupbox('Themes')
local UITransBox    = Tabs['UI Customization']:AddRightGroupbox('Transparency')

-- ==================== SERVICES & SHARED ====================
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

getgenv().Oridium = getgenv().Oridium or {
    SilentAim = false,
    SilentTarget = nil,
    AntiDetection = false,
    GoodBoys = {},
    BadBoys = {}
}

local GoodBoys = getgenv().Oridium.GoodBoys
local BadBoys = getgenv().Oridium.BadBoys
local Marks = {}

local function isValidTarget(player)
    return player and player.Character
        and player.Character:FindFirstChild("Head")
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

-- ==================== UI CUSTOMIZATION ====================
local Themes = {
    ["Oridium Blue"] = { Accent = Color3.fromRGB(100, 180, 255), Dark = Color3.fromRGB(60, 120, 180) },
    ["Bright Blue"]  = { Accent = Color3.fromRGB(0, 150, 255),   Dark = Color3.fromRGB(0, 90, 180) },
    ["Cyan"]         = { Accent = Color3.fromRGB(0, 220, 255),   Dark = Color3.fromRGB(0, 140, 180) },
    ["Purple"]       = { Accent = Color3.fromRGB(160, 80, 255),  Dark = Color3.fromRGB(100, 40, 180) },
    ["Pink"]         = { Accent = Color3.fromRGB(255, 80, 160),  Dark = Color3.fromRGB(180, 40, 100) },
    ["Red"]          = { Accent = Color3.fromRGB(255, 60, 60),   Dark = Color3.fromRGB(180, 30, 30) },
    ["Orange"]       = { Accent = Color3.fromRGB(255, 140, 40),  Dark = Color3.fromRGB(180, 90, 20) },
    ["Green"]        = { Accent = Color3.fromRGB(60, 220, 100),  Dark = Color3.fromRGB(30, 140, 60) },
    ["Mint"]         = { Accent = Color3.fromRGB(80, 255, 200),  Dark = Color3.fromRGB(40, 170, 130) },
    ["Gold"]         = { Accent = Color3.fromRGB(255, 200, 50),  Dark = Color3.fromRGB(180, 140, 20) },
    ["White"]        = { Accent = Color3.fromRGB(240, 240, 240), Dark = Color3.fromRGB(160, 160, 160) },
    ["Crimson"]      = { Accent = Color3.fromRGB(220, 20, 60),   Dark = Color3.fromRGB(140, 10, 35) },
}

local function applyTheme(themeName)
    local theme = Themes[themeName]
    if not theme then return end

    Library.AccentColor = theme.Accent
    Library.AccentColorDark = theme.Dark

    if Library.UpdateColorsUsingRegistry then
        pcall(function()
            Library:UpdateColorsUsingRegistry()
        end)
    end

    Library:Notify("Theme: " .. themeName, 2)
end

UIThemeBox:AddDropdown('UITheme', {
    Values = { "Oridium Blue", "Bright Blue", "Cyan", "Purple", "Pink", "Red", "Orange", "Green", "Mint", "Gold", "White", "Crimson" },
    Default = 1,
    Multi = false,
    Text = 'Theme',
    Tooltip = 'Change the UI accent color',
    Callback = function(Value)
        applyTheme(Value)
    end
})

UIThemeBox:AddLabel('Pick a theme from the dropdown')
UIThemeBox:AddLabel('Changes accent color instantly')

-- Transparency
local transparencyEnabled = false
local transparencyValue = 0 -- 0 = solid, 1 = fully transparent (we'll map 1-100% to this)

local function applyTransparency(percent)
    -- percent: 1 to 100
    local alpha = math.clamp(percent / 100, 0.01, 1)
    -- Linoria uses BackgroundColor etc; try setting main window transparency
    pcall(function()
        if Library.InnerVideoBackground then
            -- skip
        end
        -- Walk common Linoria UI holders
        for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if gui:IsA("Frame") and (gui.Name == "Main" or gui.Name == "Holder" or gui.Name == "Window") then
                if transparencyEnabled then
                    gui.BackgroundTransparency = alpha
                end
            end
        end
        if typeof(gethui) == "function" then
            for _, gui in ipairs(gethui():GetDescendants()) do
                if gui:IsA("Frame") and (gui.Name:find("Main") or gui.Name:find("Window") or gui.Name:find("Holder")) then
                    if transparencyEnabled then
                        gui.BackgroundTransparency = alpha
                    end
                end
            end
        end
    end)
end

UITransBox:AddToggle('ToggleTransparency', {
    Text = 'Toggle Transparency',
    Default = false,
    Tooltip = 'Enable UI transparency',
    Callback = function(Value)
        transparencyEnabled = Value
        if Value then
            applyTransparency(transparencyValue > 0 and transparencyValue or 30)
            Library:Notify("Transparency ON", 2)
        else
            -- Reset transparency
            pcall(function()
                if typeof(gethui) == "function" then
                    for _, gui in ipairs(gethui():GetDescendants()) do
                        if gui:IsA("Frame") and (gui.Name:find("Main") or gui.Name:find("Window") or gui.Name:find("Holder")) then
                            gui.BackgroundTransparency = 0
                        end
                    end
                end
            end)
            Library:Notify("Transparency OFF", 2)
        end
    end
})

UITransBox:AddSlider('TransparencySlider', {
    Text = 'Transparency',
    Default = 30,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Suffix = '%',
    Tooltip = '1% = almost solid, 100% = very transparent',
    Callback = function(Value)
        transparencyValue = Value
        if transparencyEnabled then
            applyTransparency(Value)
        end
    end
})

UITransBox:AddLabel('Slider only works when')
UITransBox:AddLabel('Toggle Transparency is ON')

-- ==================== PLAYER CUSTOMIZATION ====================
local CustomAssets = {
    {Name = "Yabujin Shirt",       Id = 1350415618,      Type = "Shirt"},
    {Name = "Tragedy",             Id = 13702160,         Type = "Face"},
    {Name = "Hair",                Id = 105694273623487,  Type = "Accessory"},
    {Name = "Black Eye Patch",     Id = 4528880486,       Type = "Accessory"},
    {Name = "Black Horns",         Id = 140127383196216,  Type = "Accessory"},
    {Name = "Glowing Beast Eyes",  Id = 1594010,          Type = "Face"},
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

local function loadAllCustom()
    if not isR15() then
        Library:Notify("Only works on R15 characters!", 3)
        return
    end

    Library:Notify("Loading all accessories...", 2)

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
end

for _, asset in ipairs(CustomAssets) do
    CustomBox:AddLabel(asset.Name .. "  |  " .. tostring(asset.Id))
end

CustomBox:AddDivider()

CustomBox:AddButton({
    Text = 'Load All',
    Func = function()
        task.spawn(loadAllCustom)
    end
})

CustomInfoBox:AddLabel('Only works on R15')
CustomInfoBox:AddLabel('Loads all items then waits 15s')
CustomInfoBox:AddLabel('and resets your character')
CustomInfoBox:AddDivider()
CustomInfoBox:AddLabel('Items included:')
CustomInfoBox:AddLabel('- Yabujin Shirt')
CustomInfoBox:AddLabel('- Tragedy')
CustomInfoBox:AddLabel('- Hair')
CustomInfoBox:AddLabel('- Black Eye Patch')
CustomInfoBox:AddLabel('- Black Horns')
CustomInfoBox:AddLabel('- Glowing Beast Eyes')

-- ==================== GOOD / BAD BOYS MARKS ====================
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

local function updateMarks()
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
end

-- ==================== GOOD / BAD BOYS UI ====================
local SelectedPlayer = nil

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    table.sort(list)
    return list
end

local function refreshPlayerDropdown()
    local list = getPlayerList()
    if Options.PlayerList then
        Options.PlayerList:SetValues(list)
        if #list > 0 then
            Options.PlayerList:SetValue(list[1])
        end
    end
end

BoysBox:AddDropdown('PlayerList', {
    Values = getPlayerList(),
    Default = 1,
    Multi = false,
    Text = 'Oridium Boys',
    Callback = function(Value)
        SelectedPlayer = Players:FindFirstChild(Value)
    end
})

BoysBox:AddButton({
    Text = 'Refresh List',
    Func = function()
        refreshPlayerDropdown()
        Library:Notify('Player list refreshed', 2)
    end
})

local StatusLabel = BoysBox:AddLabel('No player selected')

Options.PlayerList:OnChanged(function()
    local name = Options.PlayerList.Value
    SelectedPlayer = Players:FindFirstChild(name)

    if SelectedPlayer then
        local status = "Neutral"
        if GoodBoys[SelectedPlayer.UserId] then
            status = "✅ Good Boy"
        elseif BadBoys[SelectedPlayer.UserId] then
            status = "❌ Bad Boy"
        end
        StatusLabel:SetText(SelectedPlayer.Name .. " | " .. status .. "\nID: " .. SelectedPlayer.UserId)
    else
        StatusLabel:SetText('No player selected')
    end
end)

ActionsBox:AddButton({
    Text = 'Sign Good Boys',
    Func = function()
        if SelectedPlayer then
            GoodBoys[SelectedPlayer.UserId] = SelectedPlayer.Name
            BadBoys[SelectedPlayer.UserId] = nil
            createMark(SelectedPlayer, true)
            Library:Notify(SelectedPlayer.Name .. " → Good Boy ✝", 3)
            Options.PlayerList:SetValue(SelectedPlayer.Name)
        else
            Library:Notify("Select a player first", 2)
        end
    end
})

ActionsBox:AddButton({
    Text = 'Sign Bad Boys',
    Func = function()
        if SelectedPlayer then
            BadBoys[SelectedPlayer.UserId] = SelectedPlayer.Name
            GoodBoys[SelectedPlayer.UserId] = nil
            createMark(SelectedPlayer, false)
            Library:Notify(SelectedPlayer.Name .. " → Bad Boy †", 3)
            Options.PlayerList:SetValue(SelectedPlayer.Name)
        else
            Library:Notify("Select a player first", 2)
        end
    end
})

ActionsBox:AddDivider()

ActionsBox:AddButton({
    Text = 'Clear Good Boys',
    Func = function()
        for uid, name in pairs(GoodBoys) do
            local p = Players:FindFirstChild(name)
            if p then removeMark(p) end
        end
        table.clear(GoodBoys)
        Library:Notify("Good Boys cleared", 2)
    end
})

ActionsBox:AddButton({
    Text = 'Clear Bad Boys',
    Func = function()
        for uid, name in pairs(BadBoys) do
            local p = Players:FindFirstChild(name)
            if p then removeMark(p) end
        end
        table.clear(BadBoys)
        Library:Notify("Bad Boys cleared", 2)
    end
})

Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    refreshPlayerDropdown()
    if GoodBoys[player.UserId] then
        createMark(player, true)
    elseif BadBoys[player.UserId] then
        createMark(player, false)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeMark(player)
    task.wait(0.3)
    refreshPlayerDropdown()
end)

-- ==================== SILENT AIM ====================
local function getClosestSilentTarget()
    local closest, shortest = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isValidTarget(player) then
            local head = player.Character.Head
            local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if dist < 180 and dist < shortest then
                    shortest = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

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

RunService.Heartbeat:Connect(function()
    if getgenv().Oridium.SilentAim then
        getgenv().Oridium.SilentTarget = getClosestSilentTarget()
    else
        getgenv().Oridium.SilentTarget = nil
    end
end)

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

local SnapLine = Drawing.new("Line")
SnapLine.Color = lightBlue
SnapLine.Thickness = 2
SnapLine.Visible = false

local HeadDot = Drawing.new("Circle")
HeadDot.Color = lightBlue
HeadDot.Thickness = 1.5
HeadDot.NumSides = 24
HeadDot.Radius = 3
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
    Text = 'Silent Aim',
    Default = false,
    Callback = function(v)
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
end

local function onPlayerRemoving(player)
    removeESP(player)
    removeAimviewer(player)
    removeMark(player)
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    local now = tick()

    updateFOVCircle()
    updateMarks()

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
        for _, mark in pairs(Marks) do mark:Remove() end
    end)
end)

SaveManager:LoadAutoloadConfig()
