local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local GreenBlackTheme = {
    TextColor = Color3.fromRGB(0, 255, 100),
    Background = Color3.fromRGB(10, 10, 10),
    Topbar = Color3.fromRGB(0, 20, 0),
    Shadow = Color3.fromRGB(0, 0, 0),
    NotificationBackground = Color3.fromRGB(0, 10, 0),
    NotificationActionsBackground = Color3.fromRGB(0, 50, 0),
    TabBackground = Color3.fromRGB(15, 15, 15),
    TabStroke = Color3.fromRGB(0, 100, 0),
    TabBackgroundSelected = Color3.fromRGB(0, 80, 0),
    TabTextColor = Color3.fromRGB(0, 200, 80),
    SelectedTabTextColor = Color3.fromRGB(0, 255, 100),
    ElementBackground = Color3.fromRGB(20, 20, 20),
    ElementBackgroundHover = Color3.fromRGB(30, 30, 30),
    SecondaryElementBackground = Color3.fromRGB(15, 15, 15),
    ElementStroke = Color3.fromRGB(0, 80, 0),
    SecondaryElementStroke = Color3.fromRGB(0, 60, 0),
    SliderBackground = Color3.fromRGB(0, 100, 0),
    SliderProgress = Color3.fromRGB(0, 200, 80),
    SliderStroke = Color3.fromRGB(0, 255, 100),
    ToggleBackground = Color3.fromRGB(20, 20, 20),
    ToggleEnabled = Color3.fromRGB(0, 200, 80),
    ToggleDisabled = Color3.fromRGB(40, 40, 40),
    ToggleEnabledStroke = Color3.fromRGB(0, 255, 100),
    ToggleDisabledStroke = Color3.fromRGB(60, 60, 60),
    ToggleEnabledOuterStroke = Color3.fromRGB(0, 150, 60),
    ToggleDisabledOuterStroke = Color3.fromRGB(80, 80, 80),
    DropdownSelected = Color3.fromRGB(0, 60, 0),
    DropdownUnselected = Color3.fromRGB(20, 20, 20),
    InputBackground = Color3.fromRGB(20, 20, 20),
    InputStroke = Color3.fromRGB(0, 100, 0),
    PlaceholderColor = Color3.fromRGB(0, 150, 60)
}

local Window = Rayfield:CreateWindow({
    Name = "NuvrHub",
    Icon = 0,
    LoadingTitle = "NuvrHub loading",
    LoadingSubtitle = "by Nuvr",
    Theme = GreenBlackTheme,
    ToggleUIKeybind = "K",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "myhub"
    },
    Discord = {
        Enabled = false,
        Invite = "https://discord.gg/nTaWsya6RV",
        RememberJoins = true
    },
    KeySystem = false
})

local UniversalTab = Window:CreateTab("Universal", 4483362458)

local InfYieldSection = UniversalTab:CreateSection("Universal")

local InfYieldButton = UniversalTab:CreateButton({
    Name = "Load Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end
})
