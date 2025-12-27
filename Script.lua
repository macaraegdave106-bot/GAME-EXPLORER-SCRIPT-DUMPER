--[[
    GAME EXPLORER + SCRIPT DUMPER
    Finds and saves all Luau scripts from the game
]]

-- Anti-reload
if getgenv().__EXPLORER then return end
getgenv().__EXPLORER = true

print("🔄 Loading Game Explorer + Script Dumper...")

-- ============================================
-- LOAD ORIONLIB
-- ============================================
local OrionLib = nil

local OrionURLs = {
    "https://raw.githubusercontent.com/shlexware/Orion/main/source",
    "https://raw.githubusercontent.com/jensonhirst/Orion/main/source",
    "https://raw.githubusercontent.com/ionlyusegithubformcmods/1-Line-Scripts/main/Orion%20Library"
}

for i, url in pairs(OrionURLs) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success and result then
        OrionLib = result
        print("✅ OrionLib loaded from URL " .. i)
        break
    end
end

if not OrionLib then
    print("❌ OrionLib failed!")
    getgenv().__EXPLORER = nil
    return
end

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

-- ============================================
-- SETTINGS
-- ============================================
local Settings = {
    MaxObjects = 500,
    YieldEvery = 50,
    ScanDelay = 0.01
}

-- ============================================
-- OUTPUT STORAGE
-- ============================================
local OutputText = ""
local ScriptOutput = ""
local IsScanning = false

local function Log(text)
    text = text or ""
    print(text)
    OutputText = OutputText .. text .. "\n"
end

local function LogScript(text)
    text = text or ""
    print(text)
    ScriptOutput = ScriptOutput .. text .. "\n"
end

local function LogLine()
    Log("════════════════════════════════════════════════════════")
end

local function LogHeader(title)
    Log("")
    LogLine()
    Log("  " .. title)
    LogLine()
end

-- ============================================
-- SCRIPT SCANNER FUNCTIONS
-- ============================================

-- Check if decompiler is available
local HasDecompiler = false
local DecompileFunc = nil

if decompile then
    HasDecompiler = true
    DecompileFunc = decompile
    print("✅ Decompiler available!")
elseif getscriptbytecode then
    HasDecompiler = true
    print("✅ getscriptbytecode available!")
else
    print("⚠️ No decompiler - will save script info only")
end

-- Get script source safely
local function GetScriptSource(script)
    if not HasDecompiler then
        return nil, "No decompiler"
    end
    
    local success, source = pcall(function()
        if decompile then
            return decompile(script)
        elseif getscriptbytecode then
            return getscriptbytecode(script)
        end
    end)
    
    if success and source then
        return source, nil
    else
        return nil, tostring(source)
    end
end

-- Scan all scripts in a service
local function ScanScriptsInService(service, serviceName)
    local scripts = {
        LocalScripts = {},
        ModuleScripts = {},
        Scripts = {}
    }
    
    local count = 0
    
    pcall(function()
        for _, obj in pairs(service:GetDescendants()) do
            count = count + 1
            
            if count % Settings.YieldEvery == 0 then
                task.wait(Settings.ScanDelay)
            end
            
            pcall(function()
                if obj:IsA("LocalScript") then
                    table.insert(scripts.LocalScripts, {
                        Name = obj.Name,
                        Path = obj:GetFullName(),
                        Object = obj
                    })
                elseif obj:IsA("ModuleScript") then
                    table.insert(scripts.ModuleScripts, {
                        Name = obj.Name,
                        Path = obj:GetFullName(),
                        Object = obj
                    })
                elseif obj:IsA("Script") then
                    table.insert(scripts.Scripts, {
                        Name = obj.Name,
                        Path = obj:GetFullName(),
                        Object = obj
                    })
                end
            end)
        end
    end)
    
    return scripts
end

-- Scan all scripts in game
local function ScanAllScripts()
    LogHeader("📜 SCANNING ALL SCRIPTS")
    
    local allScripts = {
        LocalScripts = {},
        ModuleScripts = {},
        Scripts = {}
    }
    
    local services = {
        {Name = "Workspace", Service = Workspace},
        {Name = "ReplicatedStorage", Service = ReplicatedStorage},
        {Name = "ReplicatedFirst", Service = ReplicatedFirst},
        {Name = "StarterPlayer", Service = StarterPlayer},
        {Name = "StarterGui", Service = StarterGui},
        {Name = "StarterPack", Service = StarterPack},
        {Name = "Lighting", Service = Lighting},
        {Name = "PlayerGui", Service = Player.PlayerGui}
    }
    
    for _, data in pairs(services) do
        Log("  Scanning " .. data.Name .. "...")
        task.wait(0.1)
        
        local scripts = ScanScriptsInService(data.Service, data.Name)
        
        for _, script in pairs(scripts.LocalScripts) do
            table.insert(allScripts.LocalScripts, script)
        end
        for _, script in pairs(scripts.ModuleScripts) do
            table.insert(allScripts.ModuleScripts, script)
        end
        for _, script in pairs(scripts.Scripts) do
            table.insert(allScripts.Scripts, script)
        end
    end
    
    Log("")
    Log("  📊 RESULTS:")
    Log("    LocalScripts: " .. #allScripts.LocalScripts)
    Log("    ModuleScripts: " .. #allScripts.ModuleScripts)
    Log("    Scripts: " .. #allScripts.Scripts)
    Log("    TOTAL: " .. (#allScripts.LocalScripts + #allScripts.ModuleScripts + #allScripts.Scripts))
    
    return allScripts
end

-- List all scripts (without source)
local function ListAllScripts()
    ScriptOutput = ""
    
    LogScript("╔═══════════════════════════════════════════════════════╗")
    LogScript("║           ALL SCRIPTS IN GAME                         ║")
    LogScript("║           Game: " .. game.PlaceId .. "                              ║")
    LogScript("╚═══════════════════════════════════════════════════════╝")
    LogScript("")
    
    local allScripts = ScanAllScripts()
    
    -- LocalScripts
    LogScript("")
    LogScript("════════════════════════════════════════════════════════")
    LogScript("  📜 LOCAL SCRIPTS (" .. #allScripts.LocalScripts .. ")")
    LogScript("════════════════════════════════════════════════════════")
    
    for i, script in pairs(allScripts.LocalScripts) do
        task.wait()
        LogScript("")
        LogScript("  " .. i .. ". " .. script.Name)
        LogScript("    Path: " .. script.Path)
    end
    
    -- ModuleScripts
    LogScript("")
    LogScript("════════════════════════════════════════════════════════")
    LogScript("  📦 MODULE SCRIPTS (" .. #allScripts.ModuleScripts .. ")")
    LogScript("════════════════════════════════════════════════════════")
    
    for i, script in pairs(allScripts.ModuleScripts) do
        task.wait()
        LogScript("")
        LogScript("  " .. i .. ". " .. script.Name)
        LogScript("    Path: " .. script.Path)
    end
    
    -- Scripts
    LogScript("")
    LogScript("════════════════════════════════════════════════════════")
    LogScript("  ⚙️ SERVER SCRIPTS (" .. #allScripts.Scripts .. ")")
    LogScript("════════════════════════════════════════════════════════")
    
    for i, script in pairs(allScripts.Scripts) do
        task.wait()
        LogScript("")
        LogScript("  " .. i .. ". " .. script.Name)
        LogScript("    Path: " .. script.Path)
    end
    
    LogScript("")
    LogScript("════════════════════════════════════════════════════════")
    LogScript("  ✅ SCRIPT LIST COMPLETE!")
    LogScript("════════════════════════════════════════════════════════")
    
    return #allScripts.LocalScripts + #allScripts.ModuleScripts + #allScripts.Scripts
end

-- Dump all scripts with source code
local function DumpAllScripts()
    if not HasDecompiler then
        return false, "No decompiler available. Use 'List Scripts' instead."
    end
    
    ScriptOutput = ""
    
    LogScript("╔═══════════════════════════════════════════════════════╗")
    LogScript("║           SCRIPT DUMP - ALL SOURCE CODE               ║")
    LogScript("║           Game: " .. game.PlaceId .. "                              ║")
    LogScript("║           Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "                 ║")
    LogScript("╚═══════════════════════════════════════════════════════╝")
    LogScript("")
    
    local allScripts = ScanAllScripts()
    local successCount = 0
    local failCount = 0
    
    -- Dump LocalScripts
    LogScript("")
    LogScript("════════════════════════════════════════════════════════")
    LogScript("  📜 LOCAL SCRIPTS SOURCE CODE")
    LogScript("════════════════════════════════════════════════════════")
    
    for i, scriptData in pairs(allScripts.LocalScripts) do
        task.wait(0.1)
        
        LogScript("")
        LogScript("--[[ ═══════════════════════════════════════════════════")
        LogScript("  Script #" .. i)
        LogScript("  Name: " .. scriptData.Name)
        LogScript("  Type: LocalScript")
        LogScript("  Path: " .. scriptData.Path)
        LogScript("═══════════════════════════════════════════════════ ]]--")
        LogScript("")
        
        local source, err = GetScriptSource(scriptData.Object)
        if source then
            LogScript(source)
            successCount = successCount + 1
        else
            LogScript("-- ❌ Failed to decompile: " .. (err or "Unknown error"))
            failCount = failCount + 1
        end
        
        LogScript("")
    end
    
    -- Dump ModuleScripts
    LogScript("")
    LogScript("════════════════════════════════════════════════════════")
    LogScript("  📦 MODULE SCRIPTS SOURCE CODE")
    LogScript("════════════════════════════════════════════════════════")
    
    for i, scriptData in pairs(allScripts.ModuleScripts) do
        task.wait(0.1)
        
        LogScript("")
        LogScript("--[[ ═══════════════════════════════════════════════════")
        LogScript("  Module #" .. i)
        LogScript("  Name: " .. scriptData.Name)
        LogScript("  Type: ModuleScript")
        LogScript("  Path: " .. scriptData.Path)
        LogScript("═══════════════════════════════════════════════════ ]]--")
        LogScript("")
        
        local source, err = GetScriptSource(scriptData.Object)
        if source then
            LogScript(source)
            successCount = successCount + 1
        else
            LogScript("-- ❌ Failed to decompile: " .. (err or "Unknown error"))
            failCount = failCount + 1
        end
        
        LogScript("")
    end
    
    LogScript("")
    LogScript("════════════════════════════════════════════════════════")
    LogScript("  ✅ DUMP COMPLETE!")
    LogScript("  Success: " .. successCount)
    LogScript("  Failed: " .. failCount)
    LogScript("════════════════════════════════════════════════════════")
    
    return true, "Dumped " .. successCount .. " scripts"
end

-- Save scripts to individual files
local function SaveScriptsToFiles()
    if not writefile or not makefolder then
        return false, "File functions not available"
    end
    
    -- Create folder
    local folderName = "GameScripts_" .. game.PlaceId
    pcall(function()
        makefolder(folderName)
    end)
    
    local allScripts = ScanAllScripts()
    local savedCount = 0
    
    -- Save LocalScripts
    for _, scriptData in pairs(allScripts.LocalScripts) do
        task.wait(0.1)
        
        local fileName = folderName .. "/LocalScript_" .. scriptData.Name:gsub("[^%w]", "_") .. ".lua"
        local content = "-- Name: " .. scriptData.Name .. "\n"
        content = content .. "-- Type: LocalScript\n"
        content = content .. "-- Path: " .. scriptData.Path .. "\n\n"
        
        if HasDecompiler then
            local source = GetScriptSource(scriptData.Object)
            if source then
                content = content .. source
            else
                content = content .. "-- Failed to decompile"
            end
        else
            content = content .. "-- No decompiler available"
        end
        
        pcall(function()
            writefile(fileName, content)
            savedCount = savedCount + 1
        end)
    end
    
    -- Save ModuleScripts
    for _, scriptData in pairs(allScripts.ModuleScripts) do
        task.wait(0.1)
        
        local fileName = folderName .. "/ModuleScript_" .. scriptData.Name:gsub("[^%w]", "_") .. ".lua"
        local content = "-- Name: " .. scriptData.Name .. "\n"
        content = content .. "-- Type: ModuleScript\n"
        content = content .. "-- Path: " .. scriptData.Path .. "\n\n"
        
        if HasDecompiler then
            local source = GetScriptSource(scriptData.Object)
            if source then
                content = content .. source
            else
                content = content .. "-- Failed to decompile"
            end
        else
            content = content .. "-- No decompiler available"
        end
        
        pcall(function()
            writefile(fileName, content)
            savedCount = savedCount + 1
        end)
    end
    
    return true, "Saved " .. savedCount .. " scripts to " .. folderName
end

-- ============================================
-- REGULAR SCAN FUNCTIONS
-- ============================================

local function ScanGameInfo()
    LogHeader("📱 GAME INFORMATION")
    
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        Log("  Game Name: " .. (info.Name or "Unknown"))
        Log("  Creator: " .. (info.Creator.Name or "Unknown"))
    end)
    
    Log("  Place ID: " .. game.PlaceId)
    Log("  Game ID: " .. game.GameId)
    Log("  Player Count: " .. #Players:GetPlayers())
    Log("  Your Name: " .. Player.Name)
    
    return 1
end

local function ScanRemotes()
    LogHeader("📡 ALL REMOTES")
    
    local count = 0
    local scanned = 0
    
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        scanned = scanned + 1
        
        if scanned % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        if count >= Settings.MaxObjects then
            Log("  ⚠️ Limit reached")
            break
        end
        
        pcall(function()
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                count = count + 1
                Log("  [" .. obj.ClassName .. "] " .. obj.Name)
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL REMOTES: " .. count)
    return count
end

local function ScanPrompts()
    LogHeader("🎯 PROXIMITY PROMPTS")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if count % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        if count >= Settings.MaxObjects then break end
        
        pcall(function()
            if obj:IsA("ProximityPrompt") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Parent.Name)
                Log("    Action: " .. (obj.ActionText ~= "" and obj.ActionText or "Interact"))
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL PROMPTS: " .. count)
    return count
end

local function ScanFolders()
    LogHeader("📁 FOLDERS")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetChildren()) do
        task.wait()
        if obj:IsA("Folder") then
            count = count + 1
            Log("  " .. count .. ". [Workspace] " .. obj.Name .. " (" .. #obj:GetChildren() .. " children)")
        end
    end
    
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        task.wait()
        if obj:IsA("Folder") then
            count = count + 1
            Log("  " .. count .. ". [ReplicatedStorage] " .. obj.Name .. " (" .. #obj:GetChildren() .. " children)")
        end
    end
    
    Log("  TOTAL FOLDERS: " .. count)
    return count
end

local function ScanValues()
    LogHeader("📊 YOUR VALUES")
    
    local count = 0
    
    for _, obj in pairs(Player:GetDescendants()) do
        task.wait()
        pcall(function()
            if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name .. " = " .. tostring(obj.Value))
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL VALUES: " .. count)
    return count
end

local function QuickScan()
    if IsScanning then return end
    
    IsScanning = true
    OutputText = ""
    
    Log("╔═══════════════════════════════════════════════════════╗")
    Log("║           QUICK SCAN                                  ║")
    Log("╚═══════════════════════════════════════════════════════╝")
    
    ScanGameInfo()
    task.wait(0.1)
    ScanRemotes()
    task.wait(0.1)
    ScanFolders()
    task.wait(0.1)
    ScanValues()
    
    Log("")
    Log("✅ QUICK SCAN COMPLETE!")
    
    IsScanning = false
    return OutputText
end

-- ============================================
-- SAVE FUNCTIONS
-- ============================================

local function SaveToFile()
    if not writefile then
        return false, "writefile not available"
    end
    
    if OutputText == "" then
        QuickScan()
    end
    
    local filename = "Scan_" .. game.PlaceId .. ".txt"
    writefile(filename, OutputText)
    return true, filename
end

local function SaveScriptListToFile()
    if not writefile then
        return false, "writefile not available"
    end
    
    local filename = "Scripts_" .. game.PlaceId .. ".txt"
    writefile(filename, ScriptOutput)
    return true, filename
end

local function CopyToClipboard()
    if not setclipboard then
        return false, "setclipboard not available"
    end
    
    if OutputText == "" then
        QuickScan()
    end
    
    setclipboard(OutputText)
    return true, "Copied!"
end

local function CopyScriptsToClipboard()
    if not setclipboard then
        return false, "setclipboard not available"
    end
    
    setclipboard(ScriptOutput)
    return true, "Copied!"
end

-- ============================================
-- ORIONLIB UI
-- ============================================

local Window = OrionLib:MakeWindow({
    Name = "🔍 Explorer + Script Dumper",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = false
})

-- ============================================
-- TAB 1: GAME SCAN
-- ============================================
local ScanTab = Window:MakeTab({
    Name = "Scan",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ScanTab:AddSection({Name = "⚡ Quick Scans"})

ScanTab:AddButton({
    Name = "⚡ Quick Scan",
    Callback = function()
        task.spawn(function()
            QuickScan()
            OrionLib:MakeNotification({
                Name = "✅ Done!",
                Content = "Check console (F9)",
                Time = 3
            })
        end)
    end
})

ScanTab:AddButton({
    Name = "📡 Scan Remotes",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanRemotes()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " remotes",
                Time = 3
            })
        end)
    end
})

ScanTab:AddButton({
    Name = "🎯 Scan Prompts",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanPrompts()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " prompts",
                Time = 3
            })
        end)
    end
})

ScanTab:AddButton({
    Name = "📁 Scan Folders",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanFolders()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " folders",
                Time = 3
            })
        end)
    end
})

ScanTab:AddButton({
    Name = "📊 Scan Values",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanValues()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " values",
                Time = 3
            })
        end)
    end
})

ScanTab:AddSection({Name = "💾 Save Results"})

ScanTab:AddButton({
    Name = "💾 Save to File",
    Callback = function()
        local s, r = SaveToFile()
        OrionLib:MakeNotification({
            Name = s and "✅ Saved!" or "❌ Error",
            Content = r,
            Time = 5
        })
    end
})

ScanTab:AddButton({
    Name = "📋 Copy to Clipboard",
    Callback = function()
        local s, r = CopyToClipboard()
        OrionLib:MakeNotification({
            Name = s and "✅ Copied!" or "❌ Error",
            Content = r,
            Time = 3
        })
    end
})

-- ============================================
-- TAB 2: SCRIPT DUMPER
-- ============================================
local ScriptTab = Window:MakeTab({
    Name = "Scripts",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ScriptTab:AddSection({Name = "📜 Script Scanner"})

ScriptTab:AddParagraph("Info", "Find and dump all Luau scripts from the game!")

ScriptTab:AddLabel("Decompiler: " .. (HasDecompiler and "✅ Available" or "❌ Not Available"))

ScriptTab:AddButton({
    Name = "📜 List All Scripts",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "⏳ Scanning...",
            Content = "Finding all scripts...",
            Time = 3
        })
        
        task.spawn(function()
            local count = ListAllScripts()
            OrionLib:MakeNotification({
                Name = "✅ Done!",
                Content = "Found " .. count .. " scripts",
                Time = 5
            })
        end)
    end
})

ScriptTab:AddButton({
    Name = "📦 Dump All Scripts (Source Code)",
    Callback = function()
        if not HasDecompiler then
            OrionLib:MakeNotification({
                Name = "❌ Error",
                Content = "No decompiler available",
                Time = 5
            })
            return
        end
        
        OrionLib:MakeNotification({
            Name = "⏳ Dumping...",
            Content = "This may take a while...",
            Time = 5
        })
        
        task.spawn(function()
            local s, r = DumpAllScripts()
            OrionLib:MakeNotification({
                Name = s and "✅ Done!" or "❌ Error",
                Content = r,
                Time = 5
            })
        end)
    end
})

ScriptTab:AddSection({Name = "💾 Save Scripts"})

ScriptTab:AddButton({
    Name = "💾 Save Script List to File",
    Callback = function()
        if ScriptOutput == "" then
            ListAllScripts()
        end
        local s, r = SaveScriptListToFile()
        OrionLib:MakeNotification({
            Name = s and "✅ Saved!" or "❌ Error",
            Content = r,
            Time = 5
        })
    end
})

ScriptTab:AddButton({
    Name = "📁 Save Each Script to Folder",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "⏳ Saving...",
            Content = "Saving scripts to folder...",
            Time = 3
        })
        
        task.spawn(function()
            local s, r = SaveScriptsToFiles()
            OrionLib:MakeNotification({
                Name = s and "✅ Saved!" or "❌ Error",
                Content = r,
                Time = 5
            })
        end)
    end
})

ScriptTab:AddButton({
    Name = "📋 Copy Scripts to Clipboard",
    Callback = function()
        if ScriptOutput == "" then
            ListAllScripts()
        end
        local s, r = CopyScriptsToClipboard()
        OrionLib:MakeNotification({
            Name = s and "✅ Copied!" or "❌ Error",
            Content = r,
            Time = 3
        })
    end
})

-- ============================================
-- TAB 3: SETTINGS
-- ============================================
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSection({Name = "⚙️ Scan Settings"})

SettingsTab:AddSlider({
    Name = "Max Objects",
    Min = 100,
    Max = 1000,
    Default = 500,
    Increment = 100,
    Callback = function(val)
        Settings.MaxObjects = val
    end
})

SettingsTab:AddSection({Name = "📖 Help"})

SettingsTab:AddParagraph("Scripts Tab", "List Scripts = Shows all script names and paths")
SettingsTab:AddParagraph("", "Dump Scripts = Gets actual source code (needs decompiler)")
SettingsTab:AddParagraph("", "Save to Folder = Creates separate file for each script")

SettingsTab:AddButton({
    Name = "📖 Open Console (F9)",
    Callback = function()
        game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
    end
})

SettingsTab:AddButton({
    Name = "🗑️ Close UI",
    Callback = function()
        OrionLib:Destroy()
        getgenv().__EXPLORER = nil
    end
})

-- ============================================
-- INIT
-- ============================================
OrionLib:Init()

print("")
print("╔════════════════════════════════════════╗")
print("║  ✅ EXPLORER + SCRIPT DUMPER LOADED!   ║")
print("╠════════════════════════════════════════╣")
print("║  Tab 1: Scan - Game info, remotes      ║")
print("║  Tab 2: Scripts - Find & dump scripts  ║")
print("║  Tab 3: Settings - Configure           ║")
print("╚════════════════════════════════════════╝")
print("")

OrionLib:MakeNotification({
    Name = "✅ Loaded!",
    Content = "Use Scripts tab to dump Luau scripts",
    Time = 5
})
