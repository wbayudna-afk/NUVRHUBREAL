local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Window = Rayfield:CreateWindow({
    Name = "NuvrHub",
    Icon = 0,
    LoadingTitle = "NuvrHub loading",
    LoadingSubtitle = "by Nuvr",
    Theme = "Default",
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
