--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
--[[
    nuvr — Chams + Drone Chams + Theme + Fullbright + Trees Transparency
    Insert = menu | Home = unload
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local BRAND    = "nuvr"
local Unloaded = false

-- ============================================================
-- ПАЛИТРА
-- ============================================================
local Palette = {
    ACCENT      = Color3.fromRGB(247, 224, 92),
    BG          = Color3.fromRGB(12, 12, 14),
    BG_ITEM     = Color3.fromRGB(24, 24, 28),
    TEXT        = Color3.fromRGB(240, 240, 245),
    TEXT_DIM    = Color3.fromRGB(150, 150, 160),
    TRACK       = Color3.fromRGB(28, 28, 32),
    STROKE      = Color3.fromRGB(40, 40, 46),
    Enemy       = Color3.fromRGB(255, 80, 80),
    Team        = Color3.fromRGB(100, 180, 255),
    DroneEnemy  = Color3.fromRGB(255, 100, 255),
    DroneTeam   = Color3.fromRGB(180, 140, 255),
}

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    FULLBRIGHT_Enabled        = false,

    CHAMS_Enabled             = true,
    CHAMS_TeamCheck           = true,
    CHAMS_FillTransparency    = 0.5,
    CHAMS_OutlineTransparency = 0.3,

    DRONE_Enabled             = true,
    DRONE_TeamCheck           = false,
    DRONE_FillTransparency    = 0.5,
    DRONE_OutlineTransparency = 0.3,

    ATMOS_MAX     = 0.4,
    ATMOS_Density = 0,

    TREES_Enabled      = false,
    TREES_Transparency = 0.5,
}

-- ============================================================
-- АТМОСФЕРА + FULLBRIGHT
-- ============================================================
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Parent = Lighting
end

local Fullbright = { enabled = false, saved = nil }

local function setAtmos(d)
    d = math.clamp(d, 0, Config.ATMOS_MAX)
    Config.ATMOS_Density = d
    if not Fullbright.enabled then
        atmosphere.Density = d
    end
end

local function applyFullbright()
    if Fullbright.enabled then return end
    Fullbright.saved = {
        Ambient                 = Lighting.Ambient,
        OutdoorAmbient          = Lighting.OutdoorAmbient,
        Brightness              = Lighting.Brightness,
        ClockTime               = Lighting.ClockTime,
        FogEnd                  = Lighting.FogEnd,
        FogStart                = Lighting.FogStart,
        GlobalShadows           = Lighting.GlobalShadows,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale= Lighting.EnvironmentSpecularScale,
        atmosHaze               = atmosphere.Haze,
    }
    Lighting.Ambient                 = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient          = Color3.fromRGB(178, 178, 178)
    Lighting.Brightness              = 2
    Lighting.ClockTime               = 12
    Lighting.FogEnd                  = 100000
    Lighting.FogStart                = 0
    Lighting.GlobalShadows           = false
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale= 1
    atmosphere.Density = 0
    atmosphere.Haze    = 0
    Fullbright.enabled = true
end

local function disableFullbright()
    if not Fullbright.enabled then return end
    if Fullbright.saved then
        Lighting.Ambient                 = Fullbright.saved.Ambient
        Lighting.OutdoorAmbient          = Fullbright.saved.OutdoorAmbient
        Lighting.Brightness              = Fullbright.saved.Brightness
        Lighting.ClockTime               = Fullbright.saved.ClockTime
        Lighting.FogEnd                  = Fullbright.saved.FogEnd
        Lighting.FogStart                = Fullbright.saved.FogStart
        Lighting.GlobalShadows           = Fullbright.saved.GlobalShadows
        Lighting.EnvironmentDiffuseScale = Fullbright.saved.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale= Fullbright.saved.EnvironmentSpecularScale
        atmosphere.Haze = Fullbright.saved.atmosHaze
    end
    atmosphere.Density = Config.ATMOS_Density
    Fullbright.saved   = nil
    Fullbright.enabled = false
end

Config.ATMOS_Density = math.clamp(atmosphere.Density or 0, 0, Config.ATMOS_MAX)

-- ============================================================
-- TREES TRANSPARENCY
-- ============================================================
local Trees = { saved = {}, lastUpdate = 0 }

local function getTreesFolder()
    local ignore = workspace:FindFirstChild("ignore")
    if not ignore then return nil end
    return ignore:FindFirstChild("trees")
end

local function applyTrees()
    local trees = getTreesFolder()
    if not trees then return end
    for _, desc in ipairs(trees:GetDescendants()) do
        if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
            if Trees.saved[desc] == nil then
                Trees.saved[desc] = desc.Transparency
            end
            desc.Transparency = Config.TREES_Transparency
        end
    end
end

local function restoreTrees()
    for inst, orig in pairs(Trees.saved) do
        if inst and inst.Parent then
            pcall(function()
                if inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture") then
                    inst.Transparency = orig
                end
            end)
        end
    end
    Trees.saved = {}
end

-- ============================================================
-- КОМАНДЫ / ПЕРСОНАЖИ / ДРОНЫ
-- ============================================================
local function isSameTeam(char)
    if not char then return false end
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local plr = Players:GetPlayerFromCharacter(char)
    if plr and LocalPlayer.Team and plr.Team then
        return plr.Team == LocalPlayer.Team
    end
    if myChar.Parent and char.Parent then
        return myChar.Parent == char.Parent
    end
    return false
end

local function findAllCharacters()
    local found, seen = {}, {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                found[#found+1] = { char = char, plr = plr }
                seen[char] = true
            end
        end
    end
    local myChar = LocalPlayer.Character
    if myChar and myChar.Parent and myChar.Parent.Parent then
        local root = myChar.Parent.Parent
        for _, container in ipairs(root:GetChildren()) do
            if container:IsA("Model") then
                for _, model in ipairs(container:GetChildren()) do
                    if model:IsA("Model") and not seen[model] then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local plr = Players:FindFirstChild(model.Name)
                            if plr and plr ~= LocalPlayer then
                                found[#found+1] = { char = model, plr = plr }
                                seen[model] = true
                            end
                        end
                    end
                end
            end
        end
    end
    return found
end

local function isDroneModel(model)
    if not model or not model:IsA("Model") then return false end
    if model:FindFirstChildOfClass("Humanoid") then return false end
    return model:FindFirstChild("Rotators") ~= nil
        or model:FindFirstChild("explosive") ~= nil
        or model:FindFirstChild("Base") ~= nil
end

local function findAllDrones()
    local drones = {}
    local myChar = LocalPlayer.Character
    if not (myChar and myChar.Parent and myChar.Parent.Parent) then return drones end
    local myContainer = myChar.Parent
    local root = myContainer.Parent
    for _, container in ipairs(root:GetChildren()) do
        if container:IsA("Model") then
            local isMyTeam = (container == myContainer)
            for _, model in ipairs(container:GetChildren()) do
                if isDroneModel(model) then
                    drones[#drones+1] = { model = model, isMyTeam = isMyTeam }
                end
            end
        end
    end
    return drones
end

local CharacterCache = { list = {}, lastUpdate = 0 }
local DroneCache     = { list = {}, lastUpdate = 0 }

-- ============================================================
-- CHAMS (player)
-- ============================================================
local Chams = { cache = {} }
local function destroyChams(char)
    local hl = Chams.cache[char]
    if hl then pcall(function() hl:Destroy() end); Chams.cache[char] = nil end
end
local function createChams(char)
    local hl = Instance.new("Highlight")
    hl.Name                = "NuvrChams"
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency    = Config.CHAMS_FillTransparency
    hl.OutlineTransparency = Config.CHAMS_OutlineTransparency
    hl.Adornee             = char
    hl.Parent              = char
    return hl
end
local function chamsStep()
    for char in pairs(Chams.cache) do
        if not char.Parent then destroyChams(char) end
    end
    if not Config.CHAMS_Enabled then
        for char in pairs(Chams.cache) do destroyChams(char) end
        return
    end
    local active = {}
    for _, entry in ipairs(CharacterCache.list) do
        local char   = entry.char
        local isTeam = isSameTeam(char)
        active[char] = true
        local show = not (Config.CHAMS_TeamCheck and isTeam)
        if show then
            if not Chams.cache[char] or not Chams.cache[char].Parent then
                Chams.cache[char] = createChams(char)
            end
            local hl  = Chams.cache[char]
            local col = isTeam and Palette.Team or Palette.Enemy
            hl.FillColor           = col
            hl.OutlineColor        = col
            hl.FillTransparency    = Config.CHAMS_FillTransparency
            hl.OutlineTransparency = Config.CHAMS_OutlineTransparency
            hl.Adornee             = char
        else
            destroyChams(char)
        end
    end
    for char in pairs(Chams.cache) do
        if not active[char] then destroyChams(char) end
    end
end

-- ============================================================
-- DRONE CHAMS
-- ============================================================
local DroneChams = { cache = {} }
local function destroyDroneChams(model)
    local hl = DroneChams.cache[model]
    if hl then pcall(function() hl:Destroy() end); DroneChams.cache[model] = nil end
end
local function createDroneChams(model)
    local hl = Instance.new("Highlight")
    hl.Name                = "NuvrDroneChams"
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency    = Config.DRONE_FillTransparency
    hl.OutlineTransparency = Config.DRONE_OutlineTransparency
    hl.Adornee             = model
    hl.Parent              = model
    return hl
end
local function droneChamsStep()
    for model in pairs(DroneChams.cache) do
        if not model.Parent then destroyDroneChams(model) end
    end
    if not Config.DRONE_Enabled then
        for model in pairs(DroneChams.cache) do destroyDroneChams(model) end
        return
    end
    local active = {}
    for _, entry in ipairs(DroneCache.list) do
        local model  = entry.model
        local isTeam = entry.isMyTeam
        active[model] = true
        local show = not (Config.DRONE_TeamCheck and isTeam)
        if show then
            if not DroneChams.cache[model] or not DroneChams.cache[model].Parent then
                DroneChams.cache[model] = createDroneChams(model)
            end
            local hl  = DroneChams.cache[model]
            local col = isTeam and Palette.DroneTeam or Palette.DroneEnemy
            hl.FillColor           = col
            hl.OutlineColor        = col
            hl.FillTransparency    = Config.DRONE_FillTransparency
            hl.OutlineTransparency = Config.DRONE_OutlineTransparency
            hl.Adornee             = model
        else
            destroyDroneChams(model)
        end
    end
    for model in pairs(DroneChams.cache) do
        if not active[model] then destroyDroneChams(model) end
    end
end

-- ============================================================
-- GUI CORE
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "Nuvr_" .. math.random(100000, 999999)
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = PlayerGui end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 620)
Main.Position = UDim2.new(0.5, -160, 0.5, -310)
Main.BackgroundColor3 = Palette.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 5
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mStroke = Instance.new("UIStroke", Main)
mStroke.Color = Palette.ACCENT
mStroke.Thickness = 1
mStroke.Transparency = 0.5

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundTransparency = 1
header.Parent = Main

local title = Instance.new("TextLabel")
title.Position = UDim2.new(0, 14, 0, 0)
title.Size = UDim2.new(0, 100, 1, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Palette.ACCENT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = BRAND
title.Parent = header

local TabsFrame = Instance.new("Frame")
TabsFrame.Position = UDim2.new(0, 100, 0, 0)
TabsFrame.Size = UDim2.new(1, -114, 1, 0)
TabsFrame.BackgroundTransparency = 1
TabsFrame.Parent = header
local tabsLayout = Instance.new("UIListLayout", TabsFrame)
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 6)
tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local TabButtons = {}
local function makeTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 56, 0, 26)
    btn.BackgroundColor3 = Palette.BG_ITEM
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Palette.TEXT_DIM
    btn.Text = name
    btn.AutoButtonColor = false
    btn.Parent = TabsFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    TabButtons[name] = btn
    return btn
end
makeTabButton("Main")
makeTabButton("Theme")

local div = Instance.new("Frame")
div.Position = UDim2.new(0, 0, 0, 44)
div.Size = UDim2.new(1, 0, 0, 1)
div.BackgroundColor3 = Palette.STROKE
div.BorderSizePixel = 0
div.Parent = Main

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.new(0, 12, 0, 56)
content.Size = UDim2.new(1, -24, 1, -84)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = Palette.ACCENT
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.Parent = Main
local listLayout = Instance.new("UIListLayout", content)
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    content.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

local footer = Instance.new("TextLabel")
footer.Position = UDim2.new(0, 0, 1, -22)
footer.Size = UDim2.new(1, 0, 0, 20)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.GothamMedium
footer.TextSize = 10
footer.TextColor3 = Palette.TEXT_DIM
footer.Text = "Insert = menu | Home = unload"
footer.Parent = Main

-- ============================================================
-- THEME REGISTRY
-- ============================================================
local Registry = {}
local function regTheme(scope, refreshFn)
    table.insert(Registry, { scope = scope, refresh = refreshFn })
end
local function clearRegistry(scope)
    local newR = {}
    for _, entry in ipairs(Registry) do
        if entry.scope ~= scope then table.insert(newR, entry) end
    end
    Registry = newR
end
local function applyThemeAll()
    for _, entry in ipairs(Registry) do pcall(entry.refresh) end
    mStroke.Color                = Palette.ACCENT
    title.TextColor3             = Palette.ACCENT
    div.BackgroundColor3         = Palette.STROKE
    footer.TextColor3            = Palette.TEXT_DIM
    Main.BackgroundColor3        = Palette.BG
    content.ScrollBarImageColor3 = Palette.ACCENT
    for name, b in pairs(TabButtons) do
        local active = (name == CurrentTab)
        b.BackgroundColor3 = active and Palette.ACCENT or Palette.BG_ITEM
        b.TextColor3       = active and Color3.new(0, 0, 0) or Palette.TEXT_DIM
    end
end

-- ============================================================
-- UI HELPERS
-- ============================================================
local currentOrder = 0
local function nextOrder()
    currentOrder = currentOrder + 1
    return currentOrder
end

local function section(text, scope)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextColor3 = Palette.TEXT_DIM
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.LayoutOrder = nextOrder()
    l.Parent = content
    regTheme(scope, function() l.TextColor3 = Palette.TEXT_DIM end)
    return l
end

local function toggle(label, key, scope, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = content

    local box = Instance.new("Frame")
    box.Position = UDim2.new(0, 0, 0.5, -9)
    box.Size = UDim2.new(0, 18, 0, 18)
    box.BorderSizePixel = 0
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    local bs = Instance.new("UIStroke", box)
    bs.Thickness = 1

    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Font = Enum.Font.GothamBold
    check.TextSize = 12
    check.TextColor3 = Color3.new(0, 0, 0)
    check.Text = "v"
    check.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.new(0, 28, 0, 0)
    lbl.Size = UDim2.new(1, -28, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextColor3 = Palette.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local function refresh()
        local on = Config[key]
        box.BackgroundColor3 = on and Palette.ACCENT or Palette.BG_ITEM
        bs.Color             = on and Palette.ACCENT or Palette.STROKE
        check.Visible        = on
        lbl.TextColor3       = Palette.TEXT
    end
    refresh()
    regTheme(scope, refresh)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Parent = row
    hit.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        refresh()
        if onChange then onChange(Config[key]) end
    end)
end

local function slider(label, key, minV, maxV, step, scope, fmt)
    fmt = fmt or function(v)
        if step < 1 then return string.format("%.2f", v) end
        return tostring(math.floor(v + 0.5))
    end
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = content

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.Size = UDim2.new(0.7, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextColor3 = Palette.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Position = UDim2.new(0.7, 0, 0, 0)
    valLbl.Size = UDim2.new(0.3, 0, 0, 18)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamMedium
    valLbl.TextSize = 13
    valLbl.TextColor3 = Palette.ACCENT
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local track = Instance.new("TextButton")
    track.Position = UDim2.new(0, 0, 0, 26)
    track.Size = UDim2.new(1, 0, 0, 18)
    track.BackgroundTransparency = 1
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row

    local bar = Instance.new("Frame")
    bar.Position = UDim2.new(0, 0, 0.5, -2)
    bar.Size = UDim2.new(1, 0, 0, 4)
    bar.BackgroundColor3 = Palette.TRACK
    bar.BorderSizePixel = 0
    bar.Parent = track
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Palette.ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function apply(v)
        v = math.clamp(v, minV, maxV)
        Config[key] = v
        local p = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        valLbl.Text = fmt(v)
        if key == "ATMOS_Density" then setAtmos(v) end
        if key == "TREES_Transparency" and Config.TREES_Enabled then applyTrees() end
    end
    apply(Config[key] or minV)

    local function refresh()
        lbl.TextColor3 = Palette.TEXT
        valLbl.TextColor3 = Palette.ACCENT
        bar.BackgroundColor3 = Palette.TRACK
        fill.BackgroundColor3 = Palette.ACCENT
    end
    regTheme(scope, refresh)

    local dragging = false
    local function fromMouse()
        local mx = UserInputService:GetMouseLocation().X
        local ax = bar.AbsolutePosition.X
        local aw = bar.AbsoluteSize.X
        if aw <= 0 then return end
        local p = math.clamp((mx - ax) / aw, 0, 1)
        local v = minV + p * (maxV - minV)
        v = math.floor(v / step + 0.5) * step
        apply(v)
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            fromMouse()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and not Unloaded and bar.Parent then fromMouse() end
    end)
end

-- ============================================================
-- COLOR PICKER
-- ============================================================
local pickerFrame = nil
local function closeColorPicker()
    if pickerFrame then pcall(function() pickerFrame:Destroy() end); pickerFrame = nil end
end

local function openColorPicker(key, callback)
    closeColorPicker()
    local startCol = Palette[key]
    local h, s, v = Color3.toHSV(startCol)

    local W, H = 340, 340
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, W, 0, H)
    f.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    f.BackgroundColor3 = Palette.BG
    f.BorderSizePixel = 0
    f.ZIndex = 1500
    f.Active = true
    f.Parent = ScreenGui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local fS = Instance.new("UIStroke", f)
    fS.Color = Palette.ACCENT
    fS.Thickness = 1
    pickerFrame = f

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Position = UDim2.new(0, 12, 0, 8)
    titleLbl.Size = UDim2.new(1, -24, 0, 20)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = Palette.ACCENT
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "COLOR: " .. key
    titleLbl.ZIndex = 1501
    titleLbl.Parent = f

    local preview = Instance.new("Frame")
    preview.Position = UDim2.new(0, 12, 0, 34)
    preview.Size = UDim2.new(0, 40, 0, 24)
    preview.BackgroundColor3 = startCol
    preview.BorderSizePixel = 0
    preview.ZIndex = 1501
    preview.Parent = f
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)

    local hexLbl = Instance.new("TextLabel")
    hexLbl.Position = UDim2.new(0, 60, 0, 34)
    hexLbl.Size = UDim2.new(1, -72, 0, 24)
    hexLbl.BackgroundTransparency = 1
    hexLbl.Font = Enum.Font.GothamMedium
    hexLbl.TextSize = 12
    hexLbl.TextColor3 = Palette.TEXT
    hexLbl.TextXAlignment = Enum.TextXAlignment.Left
    hexLbl.ZIndex = 1501
    hexLbl.Parent = f

    local svArea = Instance.new("Frame")
    svArea.Position = UDim2.new(0, 12, 0, 66)
    svArea.Size = UDim2.new(1, -24, 0, 150)
    svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    svArea.BorderSizePixel = 0
    svArea.ClipsDescendants = true
    svArea.ZIndex = 1501
    svArea.Parent = f
    Instance.new("UICorner", svArea).CornerRadius = UDim.new(0, 5)

    local white = Instance.new("Frame")
    white.Size = UDim2.new(1, 0, 1, 0)
    white.BackgroundColor3 = Color3.new(1, 1, 1)
    white.BorderSizePixel = 0
    white.ZIndex = 1502
    white.Parent = svArea
    local wg = Instance.new("UIGradient", white)
    wg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })

    local black = Instance.new("Frame")
    black.Size = UDim2.new(1, 0, 1, 0)
    black.BackgroundColor3 = Color3.new(0, 0, 0)
    black.BorderSizePixel = 0
    black.ZIndex = 1503
    black.Parent = svArea
    local bg = Instance.new("UIGradient", black)
    bg.Rotation = 90
    bg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })

    local svCursor = Instance.new("Frame")
    svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    svCursor.Size = UDim2.new(0, 12, 0, 12)
    svCursor.BackgroundTransparency = 1
    svCursor.ZIndex = 1510
    svCursor.Parent = svArea
    local svcStroke = Instance.new("UIStroke", svCursor)
    svcStroke.Color = Color3.new(1, 1, 1)
    svcStroke.Thickness = 2
    Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1, 0)

    local hueBar = Instance.new("Frame")
    hueBar.Position = UDim2.new(0, 12, 0, 226)
    hueBar.Size = UDim2.new(1, -24, 0, 20)
    hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
    hueBar.BorderSizePixel = 0
    hueBar.ClipsDescendants = true
    hueBar.ZIndex = 1501
    hueBar.Parent = f
    Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 4)
    local hg = Instance.new("UIGradient", hueBar)
    hg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
    })

    local hCursor = Instance.new("Frame")
    hCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    hCursor.Position = UDim2.new(h, 0, 0.5, 0)
    hCursor.Size = UDim2.new(0, 4, 1, 0)
    hCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    hCursor.BorderSizePixel = 0
    hCursor.ZIndex = 1510
    hCursor.Parent = hueBar

    local function sync()
        preview.BackgroundColor3 = Color3.fromHSV(h, s, v)
        svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hCursor.Position = UDim2.new(h, 0, 0.5, 0)
        local c = Color3.fromHSV(h, s, v)
        hexLbl.Text = string.format("#%02X%02X%02X",
            math.floor(c.R * 255 + 0.5),
            math.floor(c.G * 255 + 0.5),
            math.floor(c.B * 255 + 0.5))
    end
    sync()

    local okBtn = Instance.new("TextButton")
    okBtn.Position = UDim2.new(0, 12, 1, -42)
    okBtn.Size = UDim2.new(0.5, -15, 0, 30)
    okBtn.BackgroundColor3 = Palette.ACCENT
    okBtn.BorderSizePixel = 0
    okBtn.Font = Enum.Font.GothamBold
    okBtn.TextSize = 12
    okBtn.TextColor3 = Color3.new(0, 0, 0)
    okBtn.Text = "OK"
    okBtn.AutoButtonColor = false
    okBtn.ZIndex = 1501
    okBtn.Parent = f
    Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 5)

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Position = UDim2.new(0.5, 3, 1, -42)
    cancelBtn.Size = UDim2.new(0.5, -15, 0, 30)
    cancelBtn.BackgroundColor3 = Palette.BG_ITEM
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.TextSize = 12
    cancelBtn.TextColor3 = Palette.TEXT
    cancelBtn.Text = "CANCEL"
    cancelBtn.AutoButtonColor = false
    cancelBtn.ZIndex = 1501
    cancelBtn.Parent = f
    Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 5)

    local svDrag = false
    svArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
    end)
    local hDrag = false
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then hDrag = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = false
            hDrag = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if not f.Parent then return end
        if svDrag then
            local mp = UserInputService:GetMouseLocation()
            local ap, asz = svArea.AbsolutePosition, svArea.AbsoluteSize
            if asz.X > 0 and asz.Y > 0 then
                s = math.clamp((mp.X - ap.X) / asz.X, 0, 1)
                v = 1 - math.clamp((mp.Y - ap.Y) / asz.Y, 0, 1)
                sync()
            end
        end
        if hDrag then
            local mp = UserInputService:GetMouseLocation()
            local ap, asz = hueBar.AbsolutePosition, hueBar.AbsoluteSize
            if asz.X > 0 then
                h = math.clamp((mp.X - ap.X) / asz.X, 0, 1)
                sync()
            end
        end
    end)

    okBtn.MouseButton1Click:Connect(function()
        local col = Color3.fromHSV(h, s, v)
        closeColorPicker()
        if callback then callback(col) end
    end)
    cancelBtn.MouseButton1Click:Connect(function() closeColorPicker() end)
end

-- ============================================================
-- COLOR ROW
-- ============================================================
local function colorRow(label, key, scope)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = content

    local swatch = Instance.new("Frame")
    swatch.Position = UDim2.new(0, 0, 0.5, -8)
    swatch.Size = UDim2.new(0, 16, 0, 16)
    swatch.BackgroundColor3 = Palette[key]
    swatch.BorderSizePixel = 0
    swatch.Parent = row
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 3)
    local swS = Instance.new("UIStroke", swatch)
    swS.Color = Palette.STROKE
    swS.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextColor3 = Palette.TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Position = UDim2.new(1, -70, 0.5, -11)
    btn.Size = UDim2.new(0, 70, 0, 22)
    btn.BackgroundColor3 = Palette.ACCENT
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.new(0, 0, 0)
    btn.Text = "PICK"
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local function refresh()
        lbl.TextColor3 = Palette.TEXT
        btn.BackgroundColor3 = Palette.ACCENT
        swS.Color = Palette.STROKE
    end
    regTheme(scope, refresh)

    btn.MouseButton1Click:Connect(function()
        openColorPicker(key, function(newColor)
            Palette[key] = newColor
            swatch.BackgroundColor3 = newColor
            applyThemeAll()
        end)
    end)
end

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local CurrentTab = "Main"

local function buildMainTab()
    section("LIGHTING", "Main")
    toggle("Fullbright", "FULLBRIGHT_Enabled", "Main", function(on)
        if on then applyFullbright() else disableFullbright() end
    end)

    section("CHAMS — PLAYERS", "Main")
    toggle("Enable Chams", "CHAMS_Enabled", "Main")
    toggle("Team Check",   "CHAMS_TeamCheck", "Main")
    slider("Fill Transparency",    "CHAMS_FillTransparency",    0, 1, 0.05, "Main")
    slider("Outline Transparency", "CHAMS_OutlineTransparency", 0, 1, 0.05, "Main")

    section("CHAMS — DRONES", "Main")
    toggle("Enable Drone Chams", "DRONE_Enabled", "Main")
    toggle("Drone Team Check",   "DRONE_TeamCheck", "Main")
    slider("Drone Fill Transparency",    "DRONE_FillTransparency",    0, 1, 0.05, "Main")
    slider("Drone Outline Transparency", "DRONE_OutlineTransparency", 0, 1, 0.05, "Main")

    section("ATMOSPHERE", "Main")
    slider("Density", "ATMOS_Density", 0, Config.ATMOS_MAX, 0.01, "Main", function(v)
        return string.format("%.2f", v)
    end)

    section("TREES (workspace.ignore.trees)", "Main")
    toggle("Enable Trees Transparency", "TREES_Enabled", "Main", function(on)
        if on then
            applyTrees()
        else
            restoreTrees()
        end
    end)
    slider("Trees Transparency", "TREES_Transparency", 0, 1, 0.05, "Main", function(v)
        return string.format("%.2f", v)
    end)
end

local function buildThemeTab()
    section("UI COLORS", "Theme")
    colorRow("Accent",    "ACCENT",   "Theme")
    colorRow("Background","BG",       "Theme")
    colorRow("Item BG",   "BG_ITEM",  "Theme")
    colorRow("Text",      "TEXT",     "Theme")
    colorRow("Text Dim",  "TEXT_DIM", "Theme")
    colorRow("Track",     "TRACK",    "Theme")
    colorRow("Stroke",    "STROKE",   "Theme")

    section("CHAMS — PLAYERS", "Theme")
    colorRow("Enemy",     "Enemy",    "Theme")
    colorRow("Team",      "Team",     "Theme")

    section("CHAMS — DRONES", "Theme")
    colorRow("Drone Enemy", "DroneEnemy", "Theme")
    colorRow("Drone Team",  "DroneTeam",  "Theme")
end

local function switchTab(tab)
    CurrentTab = tab
    currentOrder = 0
    for _, c in ipairs(content:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    clearRegistry("Main")
    clearRegistry("Theme")
    closeColorPicker()
    if tab == "Main" then buildMainTab()
    elseif tab == "Theme" then buildThemeTab() end
    for name, b in pairs(TabButtons) do
        local active = (name == tab)
        b.BackgroundColor3 = active and Palette.ACCENT or Palette.BG_ITEM
        b.TextColor3 = active and Color3.new(0, 0, 0) or Palette.TEXT_DIM
    end
end

TabButtons["Main"].MouseButton1Click:Connect(function() switchTab("Main") end)
TabButtons["Theme"].MouseButton1Click:Connect(function() switchTab("Theme") end)

-- ============================================================
-- DRAG
-- ============================================================
local dragging = false
local dragOffset = Vector2.zero
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        local m = UserInputService:GetMouseLocation()
        dragOffset = m - Vector2.new(Main.AbsolutePosition.X, Main.AbsolutePosition.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
RunService.RenderStepped:Connect(function()
    if dragging and Main.Parent then
        local m = UserInputService:GetMouseLocation()
        local p = m - dragOffset
        Main.Position = UDim2.new(0, p.X, 0, p.Y)
    end
end)

-- ============================================================
-- MAIN LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    if Unloaded then return end
    local now = tick()
    if now - CharacterCache.lastUpdate > 0.1 then
        CharacterCache.list = findAllCharacters()
        CharacterCache.lastUpdate = now
    end
    if now - DroneCache.lastUpdate > 0.2 then
        DroneCache.list = findAllDrones()
        DroneCache.lastUpdate = now
    end
    if Config.TREES_Enabled and now - Trees.lastUpdate > 0.5 then
        Trees.lastUpdate = now
        pcall(applyTrees)
    end
    pcall(chamsStep)
    pcall(droneChamsStep)
end)

-- ============================================================
-- INIT & HOTKEYS
-- ============================================================
switchTab("Main")
applyThemeAll()

UserInputService.InputBegan:Connect(function(input, gp)
    if Unloaded then return end
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
        if not Main.Visible then closeColorPicker() end
    elseif input.KeyCode == Enum.KeyCode.Home then
        Unloaded = true
        if Fullbright.enabled then disableFullbright() end
        for char in pairs(Chams.cache) do destroyChams(char) end
        for model in pairs(DroneChams.cache) do destroyDroneChams(model) end
        if Config.TREES_Enabled then restoreTrees() end
        closeColorPicker()
        pcall(function() ScreenGui:Destroy() end)
        print("[nuvr] Unloaded")
    end
end)

print("[nuvr] Chams + Drone Chams + Theme + Fullbright + Trees loaded | Insert = menu | Home = unload")
