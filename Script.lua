--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║             UNIVERSAL GAME EXPLORER v2.0                      ║
    ║         Works for ANY Roblox Game - Full Scanner              ║
    ║                                                               ║
    ║  Features:                                                    ║
    ║  • Scan ALL remotes, buttons, scripts, values                 ║
    ║  • Find & click ANY button automatically                      ║
    ║  • Auto-detect quest/arise/collect buttons                    ║
    ║  • Dump scripts with decompiler                               ║
    ║  • Copy everything to clipboard                               ║
    ║  • Save to files                                              ║
    ║  • Entity scanner (enemies, NPCs, players)                    ║
    ║  • GUI explorer                                               ║
    ║  • Universal auto-farm tools                                  ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- Anti-reload
if getgenv().__UNIVERSAL_EXPLORER then
    print("⚠️ Explorer already running!")
    return
end
getgenv().__UNIVERSAL_EXPLORER = true

print("🔄 Loading Universal Game Explorer...")

-- ═══════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local Teams = game:GetService("Teams")
local LocalizationService = game:GetService("LocalizationService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Update character on respawn
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- ═══════════════════════════════════════════════════════════════
--  LOAD ORIONLIB
-- ═══════════════════════════════════════════════════════════════

local OrionLib = nil

local OrionURLs = {
    "https://raw.githubusercontent.com/jensonhirst/Orion/main/source",
    "https://raw.githubusercontent.com/shlexware/Orion/main/source",
    "https://raw.githubusercontent.com/ionlyusegithubformcmods/1-Line-Scripts/main/Orion%20Library"
}

for i, url in pairs(OrionURLs) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success and result then
        OrionLib = result
        print("✅ OrionLib loaded from URL #" .. i)
        break
    end
end

if not OrionLib then
    print("❌ Failed to load OrionLib!")
    getgenv().__UNIVERSAL_EXPLORER = nil
    return
end

-- ═══════════════════════════════════════════════════════════════
--  SETTINGS & STORAGE
-- ═══════════════════════════════════════════════════════════════

local Settings = {
    MaxObjects = 1000,
    ScanDelay = 0.01,
    YieldEvery = 100,
    ShowHiddenButtons = true,
    AutoClickDelay = 0.1,
    IncludeInvisible = true,
    DeepScan = true
}

-- Storage for found objects
local FoundData = {
    Remotes = {},
    Buttons = {},
    QuestButtons = {},
    AriseButtons = {},
    CollectButtons = {},
    InteractButtons = {},
    Scripts = {},
    Values = {},
    Entities = {},
    Prompts = {},
    ClickDetectors = {},
    Folders = {},
    GUIs = {},
    Modules = {},
    Animations = {},
    Sounds = {}
}

-- Output text
local FullOutput = ""
local IsScanning = false

-- ═══════════════════════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function Log(text)
    text = text or ""
    print(text)
    FullOutput = FullOutput .. text .. "\n"
end

local function LogLine()
    Log("════════════════════════════════════════════════════════════════")
end

local function LogHeader(title)
    Log("")
    LogLine()
    Log("  " .. title)
    LogLine()
end

local function ClearOutput()
    FullOutput = ""
end

local function CopyOutput()
    if setclipboard then
        setclipboard(FullOutput)
        return true, "Copied to clipboard!"
    elseif toclipboard then
        toclipboard(FullOutput)
        return true, "Copied to clipboard!"
    end
    return false, "Clipboard not available"
end

local function SaveOutput(filename)
    if writefile then
        filename = filename or ("GameExplorer_" .. game.PlaceId .. "_" .. os.time() .. ".txt")
        writefile(filename, FullOutput)
        return true, filename
    end
    return false, "writefile not available"
end

local function Notify(title, content, duration)
    OrionLib:MakeNotification({
        Name = title,
        Content = content,
        Time = duration or 3
    })
end

-- Anti-AFK
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ═══════════════════════════════════════════════════════════════
--  KEYWORD DETECTION
-- ═══════════════════════════════════════════════════════════════

local Keywords = {
    Quest = {"quest", "mission", "task", "accept", "complete", "claim", "reward", "submit", "redeem", "dialog", "talk", "npc", "objective", "goal", "bounty", "contract", "assignment"},
    
    Arise = {"arise", "summon", "extract", "shadow", "capture", "absorb", "soul", "spirit", "resurrect", "revive", "awaken", "召唤"},
    
    Collect = {"collect", "loot", "pickup", "grab", "take", "get", "open", "chest", "drop", "item", "reward", "treasure", "crate", "box"},
    
    Interact = {"interact", "use", "activate", "trigger", "press", "click", "touch", "enter", "exit", "portal", "door", "shop", "store", "buy", "sell", "trade", "upgrade", "craft"},
    
    Combat = {"attack", "skill", "ability", "spell", "damage", "hit", "combo", "special", "ultimate", "dash", "dodge", "block", "parry", "heal", "buff", "debuff"},
    
    UI = {"close", "cancel", "confirm", "yes", "no", "ok", "back", "next", "previous", "continue", "skip", "menu", "settings", "inventory", "character", "stats"}
}

local function DetectKeywords(text, name, path)
    text = (text or ""):lower()
    name = (name or ""):lower()
    path = (path or ""):lower()
    
    local combined = text .. " " .. name .. " " .. path
    
    local detected = {
        Quest = false,
        Arise = false,
        Collect = false,
        Interact = false,
        Combat = false,
        UI = false
    }
    
    for category, keywords in pairs(Keywords) do
        for _, keyword in pairs(keywords) do
            if combined:find(keyword) then
                detected[category] = true
                break
            end
        end
    end
    
    return detected
end

-- ═══════════════════════════════════════════════════════════════
--  GAME INFO SCANNER
-- ═══════════════════════════════════════════════════════════════

local function ScanGameInfo()
    LogHeader("📱 GAME INFORMATION")
    
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        Log("  Game Name: " .. (info.Name or "Unknown"))
        Log("  Description: " .. (info.Description or "None"):sub(1, 100))
        Log("  Creator: " .. (info.Creator.Name or "Unknown"))
        Log("  Creator Type: " .. (info.Creator.CreatorType or "Unknown"))
    end)
    
    Log("  Place ID: " .. game.PlaceId)
    Log("  Game ID: " .. game.GameId)
    Log("  Job ID: " .. game.JobId)
    Log("  Player Count: " .. #Players:GetPlayers())
    Log("  Max Players: " .. Players.MaxPlayers)
    Log("  Your Name: " .. Player.Name)
    Log("  Your UserID: " .. Player.UserId)
    Log("  Your DisplayName: " .. Player.DisplayName)
    Log("  Account Age: " .. Player.AccountAge .. " days")
    
    -- Teams
    if #Teams:GetTeams() > 0 then
        Log("")
        Log("  Teams:")
        for _, team in pairs(Teams:GetTeams()) do
            Log("    - " .. team.Name .. " (" .. #team:GetPlayers() .. " players)")
        end
    end
    
    return 1
end

-- ═══════════════════════════════════════════════════════════════
--  REMOTE SCANNER
-- ═══════════════════════════════════════════════════════════════

local function ScanRemotes()
    LogHeader("📡 ALL REMOTES (Events & Functions)")
    
    FoundData.Remotes = {}
    local count = 0
    
    local services = {
        {Service = ReplicatedStorage, Name = "ReplicatedStorage"},
        {Service = ReplicatedFirst, Name = "ReplicatedFirst"},
        {Service = Workspace, Name = "Workspace"},
        {Service = Player, Name = "Player"},
        {Service = Lighting, Name = "Lighting"},
        {Service = StarterGui, Name = "StarterGui"},
        {Service = StarterPlayer, Name = "StarterPlayer"},
        {Service = StarterPack, Name = "StarterPack"}
    }
    
    for _, data in pairs(services) do
        pcall(function()
            for _, obj in pairs(data.Service:GetDescendants()) do
                if count % Settings.YieldEvery == 0 then
                    task.wait(Settings.ScanDelay)
                end
                
                pcall(function()
                    local isRemote = obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or 
                                     obj:IsA("BindableEvent") or obj:IsA("BindableFunction") or
                                     obj:IsA("UnreliableRemoteEvent")
                    
                    if isRemote then
                        count = count + 1
                        
                        local remoteInfo = {
                            Name = obj.Name,
                            ClassName = obj.ClassName,
                            Path = obj:GetFullName(),
                            Parent = obj.Parent and obj.Parent.Name or "None",
                            Object = obj
                        }
                        
                        table.insert(FoundData.Remotes, remoteInfo)
                        
                        Log("  " .. count .. ". [" .. obj.ClassName .. "] " .. obj.Name)
                        Log("    Parent: " .. remoteInfo.Parent)
                        Log("    Path: " .. remoteInfo.Path)
                        
                        -- Detect keywords
                        local detected = DetectKeywords("", obj.Name, remoteInfo.Path)
                        local tags = {}
                        for cat, found in pairs(detected) do
                            if found then table.insert(tags, cat) end
                        end
                        if #tags > 0 then
                            Log("    Tags: " .. table.concat(tags, ", "))
                        end
                        
                        Log("")
                    end
                end)
            end
        end)
    end
    
    Log("  TOTAL REMOTES: " .. count)
    return count
end

-- ═══════════════════════════════════════════════════════════════
--  BUTTON SCANNER
-- ═══════════════════════════════════════════════════════════════

local function GetButtonText(button)
    local text = ""
    
    pcall(function()
        if button:IsA("TextButton") then
            text = button.Text or ""
        end
    end)
    
    -- Check for TextLabel children
    pcall(function()
        for _, child in pairs(button:GetDescendants()) do
            if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                if text ~= "" then
                    text = text .. " | " .. child.Text
                else
                    text = child.Text
                end
            end
        end
    end)
    
    return text
end

local function ScanButtons()
    LogHeader("🖱️ ALL BUTTONS IN GUI")
    
    FoundData.Buttons = {}
    FoundData.QuestButtons = {}
    FoundData.AriseButtons = {}
    FoundData.CollectButtons = {}
    FoundData.InteractButtons = {}
    
    local count = 0
    
    local function ScanGUI(gui)
        pcall(function()
            for _, obj in pairs(gui:GetDescendants()) do
                if count % Settings.YieldEvery == 0 then
                    task.wait(Settings.ScanDelay)
                end
                
                pcall(function()
                    if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("GuiButton") then
                        local text = GetButtonText(obj)
                        local path = obj:GetFullName()
                        
                        -- Skip if not including invisible and button is not visible
                        if not Settings.IncludeInvisible and not obj.Visible then
                            return
                        end
                        
                        count = count + 1
                        
                        local buttonInfo = {
                            Index = count,
                            Name = obj.Name,
                            ClassName = obj.ClassName,
                            Text = text,
                            Path = path,
                            Visible = obj.Visible,
                            Active = obj.Active,
                            Parent = obj.Parent and obj.Parent.Name or "Unknown",
                            Position = obj.AbsolutePosition,
                            Size = obj.AbsoluteSize,
                            Object = obj
                        }
                        
                        table.insert(FoundData.Buttons, buttonInfo)
                        
                        -- Categorize button
                        local detected = DetectKeywords(text, obj.Name, path)
                        
                        if detected.Quest then
                            table.insert(FoundData.QuestButtons, buttonInfo)
                        end
                        if detected.Arise then
                            table.insert(FoundData.AriseButtons, buttonInfo)
                        end
                        if detected.Collect then
                            table.insert(FoundData.CollectButtons, buttonInfo)
                        end
                        if detected.Interact then
                            table.insert(FoundData.InteractButtons, buttonInfo)
                        end
                        
                        -- Log
                        Log("  " .. count .. ". [" .. obj.ClassName .. "] " .. obj.Name)
                        if text ~= "" then
                            Log("    Text: \"" .. text .. "\"")
                        end
                        Log("    Parent: " .. buttonInfo.Parent)
                        Log("    Visible: " .. tostring(obj.Visible) .. " | Active: " .. tostring(obj.Active))
                        Log("    Path: " .. path)
                        
                        local tags = {}
                        for cat, found in pairs(detected) do
                            if found then table.insert(tags, "⭐" .. cat) end
                        end
                        if #tags > 0 then
                            Log("    Tags: " .. table.concat(tags, ", "))
                        end
                        
                        Log("")
                    end
                end)
            end
        end)
    end
    
    -- Scan PlayerGui
    ScanGUI(PlayerGui)
    
    -- Try to scan CoreGui
    pcall(function()
        ScanGUI(CoreGui)
    end)
    
    Log("  TOTAL BUTTONS: " .. count)
    Log("")
    Log("  📊 CATEGORIZED:")
    Log("    Quest Buttons: " .. #FoundData.QuestButtons)
    Log("    Arise Buttons: " .. #FoundData.AriseButtons)
    Log("    Collect Buttons: " .. #FoundData.CollectButtons)
    Log("    Interact Buttons: " .. #FoundData.InteractButtons)
    
    return count
end

-- ═══════════════════════════════════════════════════════════════
--  BUTTON CLICKER
-- ═══════════════════════════════════════════════════════════════

local function ClickButton(buttonInfo)
    if not buttonInfo or not buttonInfo.Object then return false end
    
    local button = buttonInfo.Object
    local success = false
    
    -- Method 1: Fire connections
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(button.MouseButton1Click)) do
                conn:Fire()
                success = true
            end
        end
    end)
    
    -- Method 2: Direct fire
    pcall(function()
        button.MouseButton1Click:Fire()
        success = true
    end)
    
    -- Method 3: Activated
    pcall(function()
        button.Activated:Fire()
        success = true
    end)
    
    -- Method 4: firesignal
    pcall(function()
        if firesignal then
            firesignal(button.MouseButton1Click)
            success = true
        end
    end)
    
    -- Method 5: fireclick
    pcall(function()
        if fireclick then
            fireclick(button)
            success = true
        end
    end)
    
    return success
end

local function ClickButtonsByCategory(category)
    local buttons = {}
    
    if category == "Quest" then
        buttons = FoundData.QuestButtons
    elseif category == "Arise" then
        buttons = FoundData.AriseButtons
    elseif category == "Collect" then
        buttons = FoundData.CollectButtons
    elseif category == "Interact" then
        buttons = FoundData.InteractButtons
    elseif category == "All" then
        buttons = FoundData.Buttons
    end
    
    local clicked = 0
    
    for _, btn in pairs(buttons) do
        if btn.Object and btn.Object.Visible then
            if ClickButton(btn) then
                clicked = clicked + 1
                print("✅ Clicked: " .. btn.Name)
            end
            task.wait(Settings.AutoClickDelay)
        end
    end
    
    return clicked
end

local function FindAndClickButton(searchText)
    searchText = searchText:lower()
    
    -- Rescan first
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        pcall(function()
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local text = (gui:IsA("TextButton") and gui.Text or ""):lower()
                local name = gui.Name:lower()
                local path = gui:GetFullName():lower()
                
                if text:find(searchText) or name:find(searchText) or path:find(searchText) then
                    if gui.Visible then
                        ClickButton({Object = gui})
                        print("✅ Found and clicked: " .. gui.Name)
                        return gui
                    end
                end
            end
        end)
    end
    
    print("❌ Button not found: " .. searchText)
    return nil
end

-- ═══════════════════════════════════════════════════════════════
--  PROXIMITY PROMPT & CLICK DETECTOR SCANNER
-- ═══════════════════════════════════════════════════════════════

local function ScanPrompts()
    LogHeader("🎯 PROXIMITY PROMPTS")
    
    FoundData.Prompts = {}
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if count % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        pcall(function()
            if obj:IsA("ProximityPrompt") then
                count = count + 1
                
                local promptInfo = {
                    Name = obj.Parent and obj.Parent.Name or "Unknown",
                    ActionText = obj.ActionText,
                    ObjectText = obj.ObjectText,
                    KeyboardKeyCode = obj.KeyboardKeyCode.Name,
                    HoldDuration = obj.HoldDuration,
                    MaxDistance = obj.MaxActivationDistance,
                    Enabled = obj.Enabled,
                    Path = obj:GetFullName(),
                    Object = obj
                }
                
                table.insert(FoundData.Prompts, promptInfo)
                
                Log("  " .. count .. ". " .. promptInfo.Name)
                Log("    ActionText: " .. (obj.ActionText ~= "" and obj.ActionText or "Interact"))
                Log("    ObjectText: " .. (obj.ObjectText ~= "" and obj.ObjectText or "None"))
                Log("    Key: " .. promptInfo.KeyboardKeyCode)
                Log("    HoldDuration: " .. obj.HoldDuration .. "s")
                Log("    MaxDistance: " .. obj.MaxActivationDistance)
                Log("    Enabled: " .. tostring(obj.Enabled))
                Log("    Path: " .. promptInfo.Path)
                Log("")
            end
        end)
    end
    
    Log("  TOTAL PROMPTS: " .. count)
    return count
end

local function ScanClickDetectors()
    LogHeader("👆 CLICK DETECTORS")
    
    FoundData.ClickDetectors = {}
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if count % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        pcall(function()
            if obj:IsA("ClickDetector") then
                count = count + 1
                
                local clickInfo = {
                    Name = obj.Parent and obj.Parent.Name or "Unknown",
                    MaxDistance = obj.MaxActivationDistance,
                    CursorIcon = obj.CursorIcon,
                    Path = obj:GetFullName(),
                    Object = obj
                }
                
                table.insert(FoundData.ClickDetectors, clickInfo)
                
                Log("  " .. count .. ". " .. clickInfo.Name)
                Log("    MaxDistance: " .. obj.MaxActivationDistance)
                Log("    Path: " .. clickInfo.Path)
                Log("")
            end
        end)
    end
    
    Log("  TOTAL CLICK DETECTORS: " .. count)
    return count
end

-- ═══════════════════════════════════════════════════════════════
--  ENTITY SCANNER
-- ═══════════════════════════════════════════════════════════════

local function ScanEntities()
    LogHeader("👾 ENTITIES (NPCs, Enemies, Players)")
    
    FoundData.Entities = {}
    local count = 0
    
    -- Common entity folder names
    local entityFolderNames = {
        "EntityFolder", "Entities", "Enemies", "NPCs", "Mobs", 
        "Monsters", "Characters", "Units", "Creatures", "Bots",
        "Zombies", "Bosses", "Minions", "Spawns"
    }
    
    local scannedFolders = {}
    
    -- Find entity folders
    for _, folderName in pairs(entityFolderNames) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder and not scannedFolders[folder] then
            scannedFolders[folder] = true
            Log("  📁 Found: " .. folderName)
            
            for _, entity in pairs(folder:GetChildren()) do
                task.wait(Settings.ScanDelay)
                pcall(function()
                    local humanoid = entity:FindFirstChildOfClass("Humanoid")
                    local hrp = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("Torso") or entity:FindFirstChild("UpperTorso")
                    local isPlayer = Players:GetPlayerFromCharacter(entity) ~= nil
                    
                    count = count + 1
                    
                    local entityInfo = {
                        Name = entity.Name,
                        IsPlayer = isPlayer,
                        Health = humanoid and humanoid.Health or 0,
                        MaxHealth = humanoid and humanoid.MaxHealth or 0,
                        IsDead = humanoid and humanoid.Health <= 0,
                        Position = hrp and hrp.Position or Vector3.new(0, 0, 0),
                        Path = entity:GetFullName(),
                        Object = entity,
                        Humanoid = humanoid,
                        HRP = hrp
                    }
                    
                    table.insert(FoundData.Entities, entityInfo)
                    
                    Log("")
                    Log("  " .. count .. ". " .. entity.Name)
                    Log("    Type: " .. (isPlayer and "👤 Player" or "👾 NPC/Enemy"))
                    Log("    Health: " .. tostring(entityInfo.Health) .. "/" .. tostring(entityInfo.MaxHealth))
                    Log("    Status: " .. (entityInfo.IsDead and "💀 DEAD" or "💚 ALIVE"))
                    
                    if hrp then
                        Log("    Position: " .. tostring(math.floor(hrp.Position.X)) .. ", " .. tostring(math.floor(hrp.Position.Y)) .. ", " .. tostring(math.floor(hrp.Position.Z)))
                    end
                    
                    -- List special children
                    local specialChildren = {}
                    for _, child in pairs(entity:GetChildren()) do
                        if child:IsA("ValueBase") or child.Name:lower():find("arise") or child.Name:lower():find("shadow") then
                            table.insert(specialChildren, child.Name .. "[" .. child.ClassName .. "]")
                        end
                    end
                    if #specialChildren > 0 then
                        Log("    Special: " .. table.concat(specialChildren, ", "))
                    end
                    
                    Log("    Path: " .. entityInfo.Path)
                end)
            end
            
            Log("")
        end
    end
    
    -- Also scan direct Workspace children that look like characters
    for _, obj in pairs(Workspace:GetChildren()) do
        if not scannedFolders[obj] and obj:FindFirstChildOfClass("Humanoid") then
            local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
            if not isPlayer then
                count = count + 1
                Log("  " .. count .. ". [Workspace] " .. obj.Name)
                
                table.insert(FoundData.Entities, {
                    Name = obj.Name,
                    IsPlayer = false,
                    Object = obj,
                    Path = obj:GetFullName()
                })
            end
        end
    end
    
    Log("")
    Log("  TOTAL ENTITIES: " .. count)
    
    -- Count alive/dead
    local alive, dead = 0, 0
    for _, e in pairs(FoundData.Entities) do
        if e.IsDead then dead = dead + 1 else alive = alive + 1 end
    end
    Log("  Alive: " .. alive .. " | Dead: " .. dead)
    
    return count
end

-- ═══════════════════════════════════════════════════════════════
--  VALUE SCANNER
-- ═══════════════════════════════════════════════════════════════

local function ScanValues()
    LogHeader("📊 PLAYER VALUES & DATA")
    
    FoundData.Values = {}
    local count = 0
    
    -- Leaderstats
    local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        Log("  📁 leaderstats:")
        for _, val in pairs(leaderstats:GetChildren()) do
            count = count + 1
            
            local valueInfo = {
                Name = val.Name,
                Value = val.Value,
                ClassName = val.ClassName,
                Path = val:GetFullName(),
                Object = val
            }
            
            table.insert(FoundData.Values, valueInfo)
            Log("    " .. val.Name .. " = " .. tostring(val.Value) .. " [" .. val.ClassName .. "]")
        end
        Log("")
    end
    
    -- All other values
    Log("  📊 Other Values:")
    for _, obj in pairs(Player:GetDescendants()) do
        if count % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        pcall(function()
            if (obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or 
                obj:IsA("NumberValue") or obj:IsA("ObjectValue") or obj:IsA("Color3Value") or
                obj:IsA("Vector3Value") or obj:IsA("CFrameValue")) and obj.Parent ~= leaderstats then
                
                count = count + 1
                
                local valueInfo = {
                    Name = obj.Name,
                    Value = obj.Value,
                    ClassName = obj.ClassName,
                    Path = obj:GetFullName(),
                    Object = obj
                }
                
                table.insert(FoundData.Values, valueInfo)
                
                Log("    " .. obj.Name .. " = " .. tostring(obj.Value))
                Log("      Path: " .. valueInfo.Path)
            end
        end)
    end
    
    Log("")
    Log("  TOTAL VALUES: " .. count)
    return count
end

-- ═══════════════════════════════════════════════════════════════
--  FOLDER SCANNER
-- ═══════════════════════════════════════════════════════════════

local function ScanFolders()
    LogHeader("📁 ALL FOLDERS")
    
    FoundData.Folders = {}
    local count = 0
    
    local services = {
        {Service = Workspace, Name = "Workspace"},
        {Service = ReplicatedStorage, Name = "ReplicatedStorage"},
        {Service = ReplicatedFirst, Name = "ReplicatedFirst"},
        {Service = Lighting, Name = "Lighting"},
        {Service = StarterGui, Name = "StarterGui"},
        {Service = StarterPlayer, Name = "StarterPlayer"},
        {Service = StarterPack, Name = "StarterPack"},
        {Service = SoundService, Name = "SoundService"}
    }
    
    for _, data in pairs(services) do
        pcall(function()
            for _, obj in pairs(data.Service:GetChildren()) do
                if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Configuration") then
                    count = count + 1
                    
                    local folderInfo = {
                        Name = obj.Name,
                        ClassName = obj.ClassName,
                        ChildCount = #obj:GetChildren(),
                        DescendantCount = #obj:GetDescendants(),
                        Service = data.Name,
                        Path = obj:GetFullName(),
                        Object = obj
                    }
                    
                    table.insert(FoundData.Folders, folderInfo)
                    
                    Log("  " .. count .. ". [" .. data.Name .. "] " .. obj.Name .. " (" .. folderInfo.ChildCount .. " children)")
                    
                    -- List first few children
                    local childNames = {}
                    for i, child in pairs(obj:GetChildren()) do
                        if i <= 5 then
                            table.insert(childNames, child.Name)
                        elseif i == 6 then
                            table.insert(childNames, "... +" .. (folderInfo.ChildCount - 5) .. " more")
                            break
                        end
                    end
                    if #childNames > 0 then
                        Log("    Children: " .. table.concat(childNames, ", "))
                    end
                end
            end
        end)
    end
    
    Log("")
    Log("  TOTAL FOLDERS: " .. count)
    return count
end

-- ═══════════════════════════════════════════════════════════════
--  GUI SCANNER
-- ═══════════════════════════════════════════════════════════════

local function ScanGUIs()
    LogHeader("🖥️ ALL GUI SCREENS")
    
    FoundData.GUIs = {}
    local count = 0
    
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            count = count + 1
            
            local buttonCount = 0
            local frameCount = 0
            local textCount = 0
            
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    buttonCount = buttonCount + 1
                elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
                    frameCount = frameCount + 1
                elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then
                    textCount = textCount + 1
                end
            end
            
            local guiInfo = {
                Name = gui.Name,
                ClassName = gui.ClassName,
                Enabled = gui:IsA("ScreenGui") and gui.Enabled or true,
                ButtonCount = buttonCount,
                FrameCount = frameCount,
                TextCount = textCount,
                Path = gui:GetFullName(),
                Object = gui
            }
            
            table.insert(FoundData.GUIs, guiInfo)
            
            Log("  " .. count .. ". [" .. gui.ClassName .. "] " .. gui.Name)
            if gui:IsA("ScreenGui") then
                Log("    Enabled: " .. tostring(gui.Enabled))
                Log("    ResetOnSpawn: " .. tostring(gui.ResetOnSpawn))
                Log("    ZIndexBehavior: " .. tostring(gui.ZIndexBehavior))
            end
            Log("    Buttons: " .. buttonCount .. " | Frames: " .. frameCount .. " | Text: " .. textCount)
            Log("    Total Descendants: " .. #gui:GetDescendants())
            Log("")
        end
    end
    
    Log("  TOTAL SCREEN GUIS: " .. count)
    return count
end

-- ═══════════════════════════════════════════════════════════════
--  SCRIPT SCANNER
-- ═══════════════════════════════════════════════════════════════

local HasDecompiler = decompile ~= nil or getscriptbytecode ~= nil

local function ScanScripts()
    LogHeader("📜 ALL SCRIPTS")
    
    FoundData.Scripts = {}
    local localCount, moduleCount, serverCount = 0, 0, 0
    
    local services = {
        {Service = ReplicatedStorage, Name = "ReplicatedStorage"},
        {Service = ReplicatedFirst, Name = "ReplicatedFirst"},
        {Service = StarterPlayer, Name = "StarterPlayer"},
        {Service = StarterGui, Name = "StarterGui"},
        {Service = StarterPack, Name = "StarterPack"},
        {Service = Workspace, Name = "Workspace"},
        {Service = Lighting, Name = "Lighting"},
        {Service = PlayerGui, Name = "PlayerGui"}
    }
    
    for _, data in pairs(services) do
        pcall(function()
            for _, obj in pairs(data.Service:GetDescendants()) do
                if (localCount + moduleCount + serverCount) % Settings.YieldEvery == 0 then
                    task.wait(Settings.ScanDelay)
                end
                
                pcall(function()
                    local scriptType = nil
                    
                    if obj:IsA("LocalScript") then
                        scriptType = "LocalScript"
                        localCount = localCount + 1
                    elseif obj:IsA("ModuleScript") then
                        scriptType = "ModuleScript"
                        moduleCount = moduleCount + 1
                    elseif obj:IsA("Script") then
                        scriptType = "Script"
                        serverCount = serverCount + 1
                    end
                    
                    if scriptType then
                        local scriptInfo = {
                            Name = obj.Name,
                            Type = scriptType,
                            Path = obj:GetFullName(),
                            Service = data.Name,
                            Object = obj
                        }
                        
                        table.insert(FoundData.Scripts, scriptInfo)
                        
                        Log("  [" .. scriptType .. "] " .. obj.Name)
                        Log("    Path: " .. scriptInfo.Path)
                    end
                end)
            end
        end)
    end
    
    Log("")
    Log("  TOTAL SCRIPTS:")
    Log("    LocalScripts: " .. localCount)
    Log("    ModuleScripts: " .. moduleCount)
    Log("    Scripts (Server): " .. serverCount)
    Log("    TOTAL: " .. (localCount + moduleCount + serverCount))
    Log("")
    Log("  Decompiler: " .. (HasDecompiler and "✅ Available" or "❌ Not Available"))
    
    return localCount + moduleCount + serverCount
end

-- ═══════════════════════════════════════════════════════════════
--  FULL SCAN
-- ═══════════════════════════════════════════════════════════════

local function FullScan()
    if IsScanning then
        Notify("⚠️ Busy", "Scan already in progress!")
        return
    end
    
    IsScanning = true
    ClearOutput()
    
    Log("╔═══════════════════════════════════════════════════════════════╗")
    Log("║             UNIVERSAL GAME EXPLORER - FULL SCAN              ║")
    Log("║             " .. os.date("%Y-%m-%d %H:%M:%S") .. "                                  ║")
    Log("╚═══════════════════════════════════════════════════════════════╝")
    
    local totalFound = 0
    
    -- Game Info
    ScanGameInfo()
    task.wait(0.1)
    
    -- Remotes
    totalFound = totalFound + ScanRemotes()
    task.wait(0.1)
    
    -- Buttons
    totalFound = totalFound + ScanButtons()
    task.wait(0.1)
    
    -- Prompts & Click Detectors
    totalFound = totalFound + ScanPrompts()
    task.wait(0.1)
    totalFound = totalFound + ScanClickDetectors()
    task.wait(0.1)
    
    -- Entities
    totalFound = totalFound + ScanEntities()
    task.wait(0.1)
    
    -- Values
    totalFound = totalFound + ScanValues()
    task.wait(0.1)
    
    -- Folders
    totalFound = totalFound + ScanFolders()
    task.wait(0.1)
    
    -- GUIs
    totalFound = totalFound + ScanGUIs()
    task.wait(0.1)
    
    -- Scripts
    totalFound = totalFound + ScanScripts()
    
    -- Summary
    LogHeader("📊 SCAN SUMMARY")
    Log("  Remotes: " .. #FoundData.Remotes)
    Log("  Buttons: " .. #FoundData.Buttons)
    Log("    Quest Buttons: " .. #FoundData.QuestButtons)
    Log("    Arise Buttons: " .. #FoundData.AriseButtons)
    Log("    Collect Buttons: " .. #FoundData.CollectButtons)
    Log("    Interact Buttons: " .. #FoundData.InteractButtons)
    Log("  Prompts: " .. #FoundData.Prompts)
    Log("  Click Detectors: " .. #FoundData.ClickDetectors)
    Log("  Entities: " .. #FoundData.Entities)
    Log("  Values: " .. #FoundData.Values)
    Log("  Folders: " .. #FoundData.Folders)
    Log("  GUIs: " .. #FoundData.GUIs)
    Log("  Scripts: " .. #FoundData.Scripts)
    Log("")
    Log("  TOTAL OBJECTS FOUND: " .. totalFound)
    
    Log("")
    Log("╔═══════════════════════════════════════════════════════════════╗")
    Log("║             ✅ FULL SCAN COMPLETE!                           ║")
    Log("╚═══════════════════════════════════════════════════════════════╝")
    
    IsScanning = false
    
    return totalFound
end

-- ═══════════════════════════════════════════════════════════════
--  AUTO TOOLS
-- ═══════════════════════════════════════════════════════════════

local AutoTools = {
    AutoClickQuest = false,
    AutoClickArise = false,
    AutoClickCollect = false,
    AutoTriggerPrompts = false
}

-- Auto click loops
spawn(function()
    while task.wait(0.5) do
        if AutoTools.AutoClickQuest then
            pcall(function()
                for _, btn in pairs(FoundData.QuestButtons) do
                    if btn.Object and btn.Object.Visible then
                        ClickButton(btn)
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while task.wait(0.5) do
        if AutoTools.AutoClickArise then
            pcall(function()
                for _, btn in pairs(FoundData.AriseButtons) do
                    if btn.Object and btn.Object.Visible then
                        ClickButton(btn)
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while task.wait(0.5) do
        if AutoTools.AutoClickCollect then
            pcall(function()
                for _, btn in pairs(FoundData.CollectButtons) do
                    if btn.Object and btn.Object.Visible then
                        ClickButton(btn)
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while task.wait(1) do
        if AutoTools.AutoTriggerPrompts then
            pcall(function()
                for _, prompt in pairs(FoundData.Prompts) do
                    if prompt.Object and prompt.Object.Enabled then
                        fireproximityprompt(prompt.Object)
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  TELEPORT FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function TeleportToEntity(entityInfo)
    if not entityInfo or not entityInfo.HRP then return false end
    
    pcall(function()
        HumanoidRootPart.CFrame = entityInfo.HRP.CFrame * CFrame.new(0, 0, 5)
    end)
    
    return true
end

local function TeleportToNearestEnemy()
    local nearest = nil
    local nearestDist = math.huge
    
    for _, entity in pairs(FoundData.Entities) do
        if not entity.IsPlayer and not entity.IsDead and entity.HRP then
            local dist = (HumanoidRootPart.Position - entity.HRP.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = entity
            end
        end
    end
    
    if nearest then
        TeleportToEntity(nearest)
        return nearest.Name
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════════
--  CREATE UI
-- ═══════════════════════════════════════════════════════════════

local Window = OrionLib:MakeWindow({
    Name = "🔍 Universal Game Explorer v2.0",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "UniversalExplorer",
    IntroEnabled = true,
    IntroText = "🔍 Universal Game Explorer"
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 1: SCAN
-- ═══════════════════════════════════════════════════════════════

local ScanTab = Window:MakeTab({
    Name = "🔍 Scan",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ScanTab:AddSection({Name = "⚡ Quick Actions"})

ScanTab:AddButton({
    Name = "🔍 FULL SCAN (Everything)",
    Callback = function()
        Notify("⏳ Scanning...", "This may take a moment...")
        task.spawn(function()
            local count = FullScan()
            Notify("✅ Done!", "Found " .. count .. " objects")
        end)
    end
})

ScanTab:AddSection({Name = "📋 Individual Scans"})

ScanTab:AddButton({
    Name = "📱 Game Info",
    Callback = function()
        ClearOutput()
        ScanGameInfo()
        Notify("✅ Done", "Game info scanned")
    end
})

ScanTab:AddButton({
    Name = "📡 Remotes Only",
    Callback = function()
        ClearOutput()
        task.spawn(function()
            local c = ScanRemotes()
            Notify("✅ Done", "Found " .. c .. " remotes")
        end)
    end
})

ScanTab:AddButton({
    Name = "🖱️ Buttons Only",
    Callback = function()
        ClearOutput()
        task.spawn(function()
            local c = ScanButtons()
            Notify("✅ Done", "Found " .. c .. " buttons")
        end)
    end
})

ScanTab:AddButton({
    Name = "👾 Entities Only",
    Callback = function()
        ClearOutput()
        task.spawn(function()
            local c = ScanEntities()
            Notify("✅ Done", "Found " .. c .. " entities")
        end)
    end
})

ScanTab:AddButton({
    Name = "📜 Scripts Only",
    Callback = function()
        ClearOutput()
        task.spawn(function()
            local c = ScanScripts()
            Notify("✅ Done", "Found " .. c .. " scripts")
        end)
    end
})

ScanTab:AddSection({Name = "💾 Export"})

ScanTab:AddButton({
    Name = "📋 Copy to Clipboard",
    Callback = function()
        local success, msg = CopyOutput()
        Notify(success and "✅ Copied!" or "❌ Error", msg)
    end
})

ScanTab:AddButton({
    Name = "💾 Save to File",
    Callback = function()
        local success, msg = SaveOutput()
        Notify(success and "✅ Saved!" or "❌ Error", msg, 5)
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 2: BUTTONS
-- ═══════════════════════════════════════════════════════════════

local ButtonTab = Window:MakeTab({
    Name = "🖱️ Buttons",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ButtonTab:AddSection({Name = "🔍 Scan Buttons"})

ButtonTab:AddButton({
    Name = "🔄 Rescan All Buttons",
    Callback = function()
        task.spawn(function()
            ScanButtons()
            Notify("✅ Done", "Found " .. #FoundData.Buttons .. " buttons")
        end)
    end
})

ButtonTab:AddSection({Name = "🎯 Click by Category"})

ButtonTab:AddButton({
    Name = "📋 Click Quest Buttons (" .. #FoundData.QuestButtons .. ")",
    Callback = function()
        local c = ClickButtonsByCategory("Quest")
        Notify("✅ Done", "Clicked " .. c .. " buttons")
    end
})

ButtonTab:AddButton({
    Name = "👻 Click Arise Buttons (" .. #FoundData.AriseButtons .. ")",
    Callback = function()
        local c = ClickButtonsByCategory("Arise")
        Notify("✅ Done", "Clicked " .. c .. " buttons")
    end
})

ButtonTab:AddButton({
    Name = "📦 Click Collect Buttons (" .. #FoundData.CollectButtons .. ")",
    Callback = function()
        local c = ClickButtonsByCategory("Collect")
        Notify("✅ Done", "Clicked " .. c .. " buttons")
    end
})

ButtonTab:AddButton({
    Name = "🔄 Click Interact Buttons (" .. #FoundData.InteractButtons .. ")",
    Callback = function()
        local c = ClickButtonsByCategory("Interact")
        Notify("✅ Done", "Clicked " .. c .. " buttons")
    end
})

ButtonTab:AddSection({Name = "🔎 Find & Click"})

ButtonTab:AddTextbox({
    Name = "Button Text/Name",
    Default = "",
    TextDisappear = false,
    Callback = function(text)
        if text and text ~= "" then
            FindAndClickButton(text)
        end
    end
})

ButtonTab:AddSection({Name = "⚡ Auto Click"})

ButtonTab:AddToggle({
    Name = "Auto Click Quest",
    Default = false,
    Callback = function(val)
        AutoTools.AutoClickQuest = val
    end
})

ButtonTab:AddToggle({
    Name = "Auto Click Arise",
    Default = false,
    Callback = function(val)
        AutoTools.AutoClickArise = val
    end
})

ButtonTab:AddToggle({
    Name = "Auto Click Collect",
    Default = false,
    Callback = function(val)
        AutoTools.AutoClickCollect = val
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 3: ENTITIES
-- ═══════════════════════════════════════════════════════════════

local EntityTab = Window:MakeTab({
    Name = "👾 Entities",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

EntityTab:AddSection({Name = "🔍 Scan"})

EntityTab:AddButton({
    Name = "🔄 Rescan Entities",
    Callback = function()
        task.spawn(function()
            local c = ScanEntities()
            Notify("✅ Done", "Found " .. c .. " entities")
        end)
    end
})

EntityTab:AddSection({Name = "📍 Teleport"})

EntityTab:AddButton({
    Name = "📍 TP to Nearest Enemy",
    Callback = function()
        local name = TeleportToNearestEnemy()
        if name then
            Notify("✅ Teleported", "To: " .. name)
        else
            Notify("❌ Error", "No enemies found")
        end
    end
})

EntityTab:AddSection({Name = "🎯 Prompts"})

EntityTab:AddButton({
    Name = "🔄 Rescan Prompts",
    Callback = function()
        task.spawn(function()
            local c = ScanPrompts()
            Notify("✅ Done", "Found " .. c .. " prompts")
        end)
    end
})

EntityTab:AddToggle({
    Name = "Auto Trigger Prompts",
    Default = false,
    Callback = function(val)
        AutoTools.AutoTriggerPrompts = val
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 4: REMOTES
-- ═══════════════════════════════════════════════════════════════

local RemoteTab = Window:MakeTab({
    Name = "📡 Remotes",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

RemoteTab:AddSection({Name = "🔍 Scan"})

RemoteTab:AddButton({
    Name = "🔄 Rescan Remotes",
    Callback = function()
        task.spawn(function()
            ClearOutput()
            local c = ScanRemotes()
            Notify("✅ Done", "Found " .. c .. " remotes")
        end)
    end
})

RemoteTab:AddSection({Name = "📋 Export"})

RemoteTab:AddButton({
    Name = "📋 Copy Remote List",
    Callback = function()
        local output = "═══ REMOTES ═══\n\n"
        for i, r in pairs(FoundData.Remotes) do
            output = output .. i .. ". [" .. r.ClassName .. "] " .. r.Name .. "\n"
            output = output .. "   Path: " .. r.Path .. "\n\n"
        end
        if setclipboard then
            setclipboard(output)
            Notify("✅ Copied", #FoundData.Remotes .. " remotes")
        end
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 5: TOOLS
-- ═══════════════════════════════════════════════════════════════

local ToolsTab = Window:MakeTab({
    Name = "🛠️ Tools",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ToolsTab:AddSection({Name = "🏃 Player"})

ToolsTab:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 500,
    Default = 16,
    Increment = 1,
    Callback = function(val)
        pcall(function()
            Humanoid.WalkSpeed = val
        end)
    end
})

ToolsTab:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 500,
    Default = 50,
    Increment = 1,
    Callback = function(val)
        pcall(function()
            Humanoid.JumpPower = val
        end)
    end
})

ToolsTab:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(val)
        getgenv().InfiniteJump = val
    end
})

-- Infinite Jump handler
UserInputService.JumpRequest:Connect(function()
    if getgenv().InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

ToolsTab:AddToggle({
    Name = "No Clip",
    Default = false,
    Callback = function(val)
        getgenv().NoClip = val
    end
})

-- No clip handler
spawn(function()
    while task.wait() do
        if getgenv().NoClip and Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

ToolsTab:AddSection({Name = "📖 Utilities"})

ToolsTab:AddButton({
    Name = "📖 Open Console (F9)",
    Callback = function()
        StarterGui:SetCore("DevConsoleVisible", true)
    end
})

ToolsTab:AddButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end
})

ToolsTab:AddButton({
    Name = "🔄 Server Hop",
    Callback = function()
        TeleportService:Teleport(game.PlaceId)
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 6: SETTINGS
-- ═══════════════════════════════════════════════════════════════

local SettingsTab = Window:MakeTab({
    Name = "⚙️ Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSection({Name = "⚙️ Scan Settings"})

SettingsTab:AddSlider({
    Name = "Max Objects",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Increment = 100,
    Callback = function(val)
        Settings.MaxObjects = val
    end
})

SettingsTab:AddToggle({
    Name = "Include Invisible Buttons",
    Default = true,
    Callback = function(val)
        Settings.IncludeInvisible = val
    end
})

SettingsTab:AddSlider({
    Name = "Auto Click Delay",
    Min = 0.1,
    Max = 2,
    Default = 0.1,
    Increment = 0.1,
    ValueName = "sec",
    Callback = function(val)
        Settings.AutoClickDelay = val
    end
})

SettingsTab:AddSection({Name = "🎨 UI"})

SettingsTab:AddBind({
    Name = "Toggle UI",
    Default = Enum.KeyCode.RightShift,
    Hold = false,
    Callback = function()
        OrionLib:ToggleUI()
    end
})

SettingsTab:AddButton({
    Name = "🗑️ Destroy UI",
    Callback = function()
        OrionLib:Destroy()
        getgenv().__UNIVERSAL_EXPLORER = nil
    end
})

SettingsTab:AddSection({Name = "📖 Info"})

SettingsTab:AddParagraph("Version", "Universal Game Explorer v2.0")
SettingsTab:AddParagraph("Game", game.PlaceId .. " (" .. (MarketplaceService:GetProductInfo(game.PlaceId).Name or "Unknown") .. ")")

-- ═══════════════════════════════════════════════════════════════
--  GLOBAL COMMANDS
-- ═══════════════════════════════════════════════════════════════

getgenv().Explorer = {
    Scan = FullScan,
    ScanButtons = ScanButtons,
    ScanRemotes = ScanRemotes,
    ScanEntities = ScanEntities,
    ScanScripts = ScanScripts,
    
    ClickQuest = function() return ClickButtonsByCategory("Quest") end,
    ClickArise = function() return ClickButtonsByCategory("Arise") end,
    ClickCollect = function() return ClickButtonsByCategory("Collect") end,
    ClickInteract = function() return ClickButtonsByCategory("Interact") end,
    
    FindButton = FindAndClickButton,
    
    CopyOutput = CopyOutput,
    SaveOutput = SaveOutput,
    
    Data = FoundData,
    Settings = Settings
}

getgenv().Scan = FullScan
getgenv().ClickQuest = function() return ClickButtonsByCategory("Quest") end
getgenv().ClickArise = function() return ClickButtonsByCategory("Arise") end
getgenv().ClickCollect = function() return ClickButtonsByCategory("Collect") end
getgenv().FindButton = FindAndClickButton
getgenv().Rescan = function()
    ScanButtons()
    ScanEntities()
    print("✅ Rescanned!")
end

-- ═══════════════════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════════════════

OrionLib:Init()

print("")
print("╔═══════════════════════════════════════════════════════════════╗")
print("║     ✅ UNIVERSAL GAME EXPLORER LOADED!                       ║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  📋 CONSOLE COMMANDS:                                        ║")
print("║                                                               ║")
print("║  Scan()         - Full game scan                              ║")
print("║  ClickQuest()   - Click all quest buttons                     ║")
print("║  ClickArise()   - Click all arise/shadow buttons              ║")
print("║  ClickCollect() - Click all collect/loot buttons              ║")
print("║  FindButton('text') - Find and click button                   ║")
print("║  Rescan()       - Rescan buttons and entities                 ║")
print("║                                                               ║")
print("║  Explorer.Data  - Access all found data                       ║")
print("║  Explorer.CopyOutput() - Copy to clipboard                    ║")
print("╚═══════════════════════════════════════════════════════════════╝")
print("")

Notify("✅ Loaded!", "Universal Game Explorer ready! Press RightShift to toggle.", 5)
