repeat task.wait() until game:IsLoaded()

-- =======================================================
-- PINATHUB | SWING OBBY FOR BRAINROTS
-- =======================================================

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- EXECUTOR COMPATIBILITY
-- ============================================
local function noop() end
local get_hui = gethui or (syn and syn.gethui) or noop
local set_clipboard = setclipboard or (syn and syn.setclipboard) or noop

-- ============================================
-- PLAYER VARIABLES
-- ============================================
local player = LocalPlayer
local UIS = UserInputService
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ============================================
-- CREATE HIDE PART
-- ============================================
local hidePart = nil

local function createHidePart()
    if hidePart and hidePart.Parent then
        hidePart:Destroy()
        hidePart = nil
    end
    
    local part = Instance.new("Part")
    part.Name = "PinatHubHideZone"
    part.Size = Vector3.new(10, 10, 10)
    part.Position = Vector3.new(23.050, -9.820, -46.845)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = workspace
    
    hidePart = part
    return part
end

local function teleportToHidePart()
    if not hidePart then
        createHidePart()
        task.wait(0.1)
    end
    
    if hidePart then
        humanoidRootPart.CFrame = hidePart.CFrame + Vector3.new(0, 3, 0)
        if window then
            window:Notify("Hide Zone", "Teleported to safe zone!", 2)
        end
        return true
    end
    return false
end

-- ============================================
-- LOGO LAUNCHER PINATHUB
-- ============================================
local logoGui = Instance.new("ScreenGui")
logoGui.Name = "PinatHubLogo"
logoGui.ResetOnSpawn = false
logoGui.Parent = player:WaitForChild("PlayerGui", 5)

local logoButton = Instance.new("ImageButton")
logoButton.Name = "LogoButton"
logoButton.Size = UDim2.new(0, 50, 0, 50)
logoButton.Position = UDim2.new(0.5, -25, 0.5, -25)
logoButton.BackgroundTransparency = 1
logoButton.Image = "rbxassetid://118264723961739"
logoButton.ImageColor3 = Color3.fromRGB(180, 0, 255)
logoButton.ScaleType = Enum.ScaleType.Fit
logoButton.Parent = logoGui

local uiCornerLogo = Instance.new("UICorner")
uiCornerLogo.CornerRadius = UDim.new(1, 0)
uiCornerLogo.Parent = logoButton

local hoverTween = TweenService:Create(logoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)})
local unhoverTween = TweenService:Create(logoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 50, 0, 50)})

logoButton.MouseEnter:Connect(function() hoverTween:Play() end)
logoButton.MouseLeave:Connect(function() unhoverTween:Play() end)

local dragging = false
local dragStart = nil
local startPos = nil

logoButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = logoButton.Position
    end
end)

logoButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        dragStart = nil
        startPos = nil
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and dragStart and startPos then
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
            logoButton.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end
end)

-- ============================================
-- LOAD WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet('https://github.com/Footagesus/WindUI/releases/latest/download/main.lua'))()

local window = WindUI:CreateWindow({
    Title = "PinatHub",
    Author = "@viunze on tiktok",
    Folder = "pinathub",
    Size = UDim2.fromOffset(600, 600),
    Transparent = false,
    Theme = "Dark",
    IsOpenButtonEnabled = false,
    User = {Enabled = true, Anonymous = true},
    SideBarWidth = 150,
})

local guiVisible = true
logoButton.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    if window then
        pcall(function()
            if guiVisible then
                window:Open()
            else
                window:Minimize()
            end
        end)
    end
end)

-- Create Tabs
local tabs = {
    farm = window:Tab({Title = "Farm", Icon = "bot"}),
    upgrades = window:Tab({Title = "Upgrades", Icon = "dollar-sign"}),
    automation = window:Tab({Title = "Automation", Icon = "folder-cog"}),
    random = window:Tab({Title = "Random", Icon = "box"}),
    settings = window:Tab({Title = "Settings", Icon = "cog"}),
    community = window:Tab({Title = "Community", Icon = "users"}),
}

-- ============================================
-- STATE VARIABLES
-- ============================================
local autoFarmRunning = false
local autoUpgradeRunning = false
local autoPodUpgradeRunning = false
local busy = false
local upgradeInterval = 1
local selectedUpgrades = {}
local powerAmount = 5
local reachAmount = 5
local maxLevel = 100
local autoClaimRunning = false
local autoRebirthRunning = false
local autoCollectRunning = false
local collectionMode = "Teleport"
local customPowerEnabled = false
local customPowerValue = 10
local infReachEnabled = false
local excludedRarities = {}
local excludedRanks = {}
local levelLimit = 0

-- Remote references
local upgradeRemote = nil
local rebirthRemote = nil
local plotUpgradeRemote = nil

pcall(function()
    upgradeRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("StatUpgradeService"):WaitForChild("RF"):WaitForChild("Upgrade")
    rebirthRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("StatUpgradeService"):WaitForChild("RF"):WaitForChild("Rebirth")
    plotUpgradeRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("PlotService"):WaitForChild("RF"):WaitForChild("Upgrade")
end)

-- Suffixes for money parsing
local suffixes = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12,
    qa = 1e15, qi = 1e18, sx = 1e21,
    sp = 1e24, oc = 1e27, no = 1e30, dc = 1e33
}

local function parseMoney(text)
    if not text then return 0 end
    text = text:lower():gsub("%$", ""):gsub(",", "")
    local num, suf = text:match("([%d%.]+)(%a*)")
    num = tonumber(num)
    if not num then return 0 end
    return num * (suffixes[suf] or 1)
end

-- ============================================
-- FARM BRAINROTS FUNCTIONS
-- ============================================

local function getBestBrainrot()
    local bestPart = nil
    local bestModel = nil
    local bestValue = 0
    
    local activeBrainrots = workspace:FindFirstChild("ActiveBrainrots")
    if not activeBrainrots then return nil, nil end
    
    for _, part in pairs(activeBrainrots:GetChildren()) do
        if part:IsA("BasePart") then
            local model = part:FindFirstChildOfClass("Model")
            if not model then
                -- skip this iteration
            else
                local success, data = pcall(function()
                    local frame = model.LevelBoard.Frame
                    return {
                        earnings = frame.CurrencyFrame.Earnings.Text,
                        rarity = frame.Rarity.Text,
                        rank = frame.Rank.Text,
                        level = frame.Level.Text
                    }
                end)
                
                if success and data then
                    local shouldSkip = false
                    
                    if excludedRarities[data.rarity] then
                        shouldSkip = true
                    end
                    
                    if excludedRanks[data.rank] then
                        shouldSkip = true
                    end
                    
                    if not shouldSkip then
                        local levelNumber = tonumber(string.match(data.level, "%d+")) or 0
                        if levelNumber > levelLimit then
                            local value = parseMoney(data.earnings)
                            if value > bestValue then
                                bestValue = value
                                bestPart = part
                                bestModel = model
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestPart, bestModel
end

local function teleportToPosition(cf)
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    root.CFrame = cf
end

local function processBrainrot()
    local part, model = getBestBrainrot()
    if not part or not model then return end
    
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    teleportToPosition(hrp.CFrame + Vector3.new(0, 3, 0))
    task.wait(0.3)
    
    local attachment = part:FindFirstChild("Attachment")
    if attachment then
        local prompt = attachment:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
    end
    
    task.wait(0.3)
    teleportToHidePart()
end

-- ============================================
-- UPGRADE FUNCTIONS
-- ============================================

local function doUpgrade()
    if busy then return end
    busy = true
    
    if upgradeRemote then
        if selectedUpgrades["Power"] then
            pcall(function()
                upgradeRemote:InvokeServer("Power", powerAmount)
            end)
        end
        if selectedUpgrades["Reach"] then
            pcall(function()
                upgradeRemote:InvokeServer("Reach_Distance", reachAmount)
            end)
        end
        if selectedUpgrades["Carry"] then
            pcall(function()
                upgradeRemote:InvokeServer("GrabAmount", 1)
            end)
        end
    end
    
    busy = false
end

-- ============================================
-- BRAINROT UPGRADE FUNCTIONS
-- ============================================

local function getMyPlot()
    local myName = string.upper(player.Name)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    for i = 1, 5 do
        local plot = plots:FindFirstChild("Plot"..i)
        if plot then
            local success, ownerText = pcall(function()
                return plot.MainSign.ScreenFrame.SurfaceGui.Frame.Owner.PlayerName.Text
            end)
            if success and ownerText == myName then
                return plot
            end
        end
    end
    return nil
end

local function getPodLevel(pod)
    local success, levelText = pcall(function()
        local model = pod:FindFirstChild("BrainrotModel")
        if not model then return nil end
        local visual = model:FindFirstChild("VisualAnchor")
        if not visual then return nil end
        local brainrot = visual:GetChildren()[1]
        if not brainrot then return nil end
        return brainrot.LevelBoard.Frame.Level.Text
    end)
    if success and levelText then
        return tonumber(string.match(levelText, "%d+")) or 0
    end
    return nil
end

local function processPodUpgrade()
    if busy then return end
    busy = true
    
    local plot = getMyPlot()
    if plot then
        local pods = plot:FindFirstChild("Pods")
        if pods then
            for _, pod in pairs(pods:GetChildren()) do
                if not autoPodUpgradeRunning then break end
                local level = getPodLevel(pod)
                if level and level < maxLevel then
                    pcall(function()
                        if plotUpgradeRemote then
                            plotUpgradeRemote:InvokeServer(pod)
                        end
                    end)
                    task.wait(0.1)
                end
            end
        end
    end
    
    busy = false
end

-- ============================================
-- AUTO CLAIM INDEX REWARDS
-- ============================================

local TIERS = {"Normal", "Golden", "Diamond", "Emerald", "Ruby", "Rainbow", "Void", "Ethereal", "Celestial"}

local function getClaimButtons()
    local buttons = {}
    local path = player:FindFirstChild("PlayerGui")
    if path then
        local screenGui = path:FindFirstChild("ScreenGui")
        if screenGui then
            local frameIndex = screenGui:FindFirstChild("FrameIndex")
            if frameIndex then
                local main = frameIndex:FindFirstChild("Main")
                if main then
                    local scrollingFrame = main:FindFirstChild("ScrollingFrame")
                    if scrollingFrame then
                        for _, v in pairs(scrollingFrame:GetChildren()) do
                            if v:IsA("ImageButton") then
                                table.insert(buttons, v)
                            end
                        end
                    end
                end
            end
        end
    end
    return buttons
end

local function processClaimIndex()
    while autoClaimRunning do
        local buttons = getClaimButtons()
        for _, button in ipairs(buttons) do
            if not autoClaimRunning then break end
            local brainrotName = button.Name
            for _, tier in ipairs(TIERS) do
                if not autoClaimRunning then break end
                pcall(function()
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if remotes then
                        local newBrainrotIndex = remotes:FindFirstChild("NewBrainrotIndex")
                        if newBrainrotIndex then
                            local claimRemoteFunc = newBrainrotIndex:FindFirstChild("ClaimBrainrotIndex")
                            if claimRemoteFunc then
                                claimRemoteFunc:FireServer(brainrotName, tier)
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- AUTO COLLECT MONEY
-- ============================================

local function getMyPlotForCollect()
    for i = 1, 5 do
        local plots = workspace:FindFirstChild("Plots")
        if plots then
            local plot = plots:FindFirstChild("Plot"..i)
            if plot then
                local label = plot.MainSign.ScreenFrame.SurfaceGui.Frame.Owner.PlayerName
                if label and label.Text == string.upper(player.Name) then
                    return plot
                end
            end
        end
    end
    return nil
end

local function teleportCollect(cf)
    humanoidRootPart.CFrame = cf
end

local function tweenCollect(cf)
    local tween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(0.15, Enum.EasingStyle.Linear),
        {CFrame = cf}
    )
    tween:Play()
    tween.Completed:Wait()
end

local function moveToCollect(cf)
    if collectionMode == "Tween" then
        tweenCollect(cf)
    else
        teleportCollect(cf)
    end
end

local function processCollect()
    while autoCollectRunning do
        local plot = getMyPlotForCollect()
        if plot then
            local startPart = plot.MainSign.ScreenFrame
            moveToCollect(startPart.CFrame + Vector3.new(0, 3, 0))
            task.wait(0.5)
            
            local pods = plot:FindFirstChild("Pods")
            if pods then
                for i = 1, 40 do
                    if not autoCollectRunning then break end
                    local pod = pods:FindFirstChild(tostring(i))
                    if pod and pod:FindFirstChild("TouchPart") then
                        local touch = pod.TouchPart
                        moveToCollect(touch.CFrame + Vector3.new(0, 3, 0))
                        task.wait(0.2)
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- STAT MODIFIERS
-- ============================================

local stat = player:WaitForChild("updateStatsFolder"):WaitForChild("Reach_Distance")
local powerStat = player:WaitForChild("updateStatsFolder"):WaitForChild("Power")
local originalReachValue = stat.Value
local originalPowerValue = powerStat.Value

local function enforceReach()
    while infReachEnabled do
        if stat.Value ~= 1e9 then
            stat.Value = 1e9
        end
        task.wait(0.1)
    end
end

local function enforcePower()
    while customPowerEnabled do
        if powerStat.Value ~= customPowerValue then
            powerStat.Value = customPowerValue
        end
        task.wait(0.1)
    end
end

-- ============================================
-- AUTO REBIRTH
-- ============================================

local function autoRebirthLoop()
    while autoRebirthRunning do
        pcall(function()
            if rebirthRemote then
                rebirthRemote:InvokeServer()
            end
        end)
        task.wait(1)
    end
end

-- ============================================
-- UI SECTIONS
-- ============================================

-- FARM TAB
local farmSection = tabs.farm:Section({Title = "Brainrot Filter"})

farmSection:Dropdown({
    Title = "Exclude Rarities",
    Values = {"COMMON","UNCOMMON","RARE","EPIC","LEGENDARY","MYTHIC","SECRET","ANCIENT","DIVINE"},
    Multi = true,
    Callback = function(value)
        local t = {}
        for _, v in pairs(value) do
            t[v] = true
        end
        excludedRarities = t
    end
})

farmSection:Dropdown({
    Title = "Exclude Ranks",
    Values = {"NORMAL","GOLDEN","DIAMOND","EMERALD","RUBY","RAINBOW","VOID","ETHEREAL","CELESTIAL"},
    Multi = true,
    Callback = function(value)
        local t = {}
        for _, v in pairs(value) do
            t[v] = true
        end
        excludedRanks = t
    end
})

farmSection:Input({
    Title = "Minimum Brainrot Level",
    Placeholder = "Enter number",
    Numeric = true,
    Callback = function(value)
        levelLimit = tonumber(value) or 0
    end
})

farmSection:Divider()

local farmToggle = farmSection:Toggle({
    Title = "Farm Brainrots",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        autoFarmRunning = state
        if state then
            task.spawn(function()
                while autoFarmRunning do
                    pcall(processBrainrot)
                    task.wait(1.5)
                end
            end)
        end
    end
})

-- UPGRADES TAB
local upgradeSection = tabs.upgrades:Section({Title = "Stat Upgrades"})

upgradeSection:Dropdown({
    Title = "Select Upgrades",
    Values = {"Power", "Reach", "Carry"},
    Multi = true,
    Callback = function(value)
        local t = {}
        for _, v in pairs(value) do
            t[v] = true
        end
        selectedUpgrades = t
    end
})

upgradeSection:Dropdown({
    Title = "Power Amount",
    Values = {"5", "25", "50"},
    Callback = function(value)
        powerAmount = tonumber(value) or 5
    end
})

upgradeSection:Dropdown({
    Title = "Reach Amount",
    Values = {"5", "25", "50"},
    Callback = function(value)
        reachAmount = tonumber(value) or 5
    end
})

upgradeSection:Slider({
    Title = "Upgrade Interval (seconds)",
    Value = {Min = 0, Max = 5, Default = 1, Decimals = 1},
    Callback = function(value)
        upgradeInterval = value
    end
})

local upgradeToggle = upgradeSection:Toggle({
    Title = "Auto Upgrade Selected",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        autoUpgradeRunning = state
        if state then
            task.spawn(function()
                while autoUpgradeRunning do
                    doUpgrade()
                    task.wait(upgradeInterval)
                end
            end)
        end
    end
})

upgradeSection:Divider()
upgradeSection:Paragraph({Title = "Brainrot Upgrades", Desc = ""})

upgradeSection:Input({
    Title = "Max Brainrot Level",
    Placeholder = "100",
    Numeric = true,
    Callback = function(value)
        maxLevel = tonumber(value) or 100
    end
})

local podUpgradeToggle = upgradeSection:Toggle({
    Title = "Auto Upgrade Brainrots",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        autoPodUpgradeRunning = state
        if state then
            task.spawn(function()
                while autoPodUpgradeRunning do
                    processPodUpgrade()
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- AUTOMATION TAB
local automationSection = tabs.automation:Section({Title = "Automation"})

local claimToggle = automationSection:Toggle({
    Title = "Auto Claim Index Rewards",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        autoClaimRunning = state
        if state then
            task.spawn(processClaimIndex)
        end
    end
})

local rebirthToggle = automationSection:Toggle({
    Title = "Auto Rebirth",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        autoRebirthRunning = state
        if state then
            task.spawn(autoRebirthLoop)
        end
    end
})

automationSection:Divider()
automationSection:Paragraph({Title = "Collecting", Desc = ""})

automationSection:Dropdown({
    Title = "Collection Method",
    Values = {"Teleport", "Tween"},
    Default = "Teleport",
    Callback = function(value)
        collectionMode = value
    end
})

local collectToggle = automationSection:Toggle({
    Title = "Auto Collect Money",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        autoCollectRunning = state
        if state then
            task.spawn(processCollect)
        end
    end
})

-- RANDOM TAB
local randomSection = tabs.random:Section({Title = "Stat Modifiers"})

local reachToggle = randomSection:Toggle({
    Title = "Inf Rope Reach",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        infReachEnabled = state
        if state then
            stat.Value = 1e9
            task.spawn(enforceReach)
        else
            stat.Value = originalReachValue
        end
    end
})

randomSection:Slider({
    Title = "Custom Power Value",
    Value = {Min = 5, Max = 15000, Default = 10, Decimals = 1},
    Callback = function(value)
        customPowerValue = value
        if customPowerEnabled then
            powerStat.Value = value
        end
    end
})

local powerToggle = randomSection:Toggle({
    Title = "Enable Custom Power",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        customPowerEnabled = state
        if state then
            powerStat.Value = customPowerValue
            task.spawn(enforcePower)
        else
            powerStat.Value = originalPowerValue
        end
    end
})

randomSection:Divider()

randomSection:Button({
    Title = "Teleport to End",
    Callback = function()
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        root.CFrame = CFrame.new(21, -10, -34044)
        window:Notify("Teleport", "Teleported to end!", 2)
    end
})

-- SETTINGS TAB
local moveSection = tabs.settings:Section({Title = "Movement"})

local walkSpeedValue = 16
moveSection:Slider({
    Title = "Walk Speed (16-250)",
    Value = {Min = 16, Max = 250, Default = 16, Decimals = 0},
    Callback = function(value)
        walkSpeedValue = value
        if humanoid then humanoid.WalkSpeed = value end
    end
})

local jumpPowerValue = 50
moveSection:Slider({
    Title = "Jump Power (0-500)",
    Value = {Min = 0, Max = 500, Default = 50, Decimals = 0},
    Callback = function(value)
        jumpPowerValue = value
        if humanoid then
            humanoid.JumpPower = value
            humanoid.UseJumpPower = true
        end
    end
})

local infiniteJumpEnabled = false
moveSection:Toggle({
    Title = "Infinite Jump",
    Type = "Checkbox",
    Value = false,
    Callback = function(value)
        infiniteJumpEnabled = value
    end
})

UIS.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState("Jumping") end
        end
    end
end)

moveSection:Button({
    Title = "Reset Character",
    Callback = function()
        if player.Character then
            player.Character:BreakJoints()
            window:Notify("Reset", "Character reset!", 2)
        end
    end
})

moveSection:Divider()

local serverSection = tabs.settings:Section({Title = "Server"})

local antiAFKActive = false
serverSection:Toggle({
    Title = "Anti-AFK",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        antiAFKActive = state
        if state then
            task.spawn(function()
                while antiAFKActive do
                    task.wait(60)
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                    end)
                end
            end)
        end
    end
})

serverSection:Button({
    Title = "Server Hop",
    Callback = function()
        local req = syn and syn.request or http_request or request or httprequest
        local servers = {}
        local placeId = game.PlaceId
        
        if req then
            local cursor = ""
            for _ = 1, 3 do
                local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
                if cursor ~= "" then url = url .. "&cursor=" .. cursor end
                local ok, response = pcall(req, { Url = url, Method = "GET" })
                if not ok or not response or not response.Body then break end
                local ok2, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
                if not ok2 or not data or not data.data then break end
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        table.insert(servers, server.id)
                    end
                end
                local nextCursor = data.nextPageCursor
                if not nextCursor or nextCursor == "" or nextCursor == "null" then break end
                cursor = tostring(nextCursor)
            end
        end
        
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], player)
        else
            TeleportService:Teleport(placeId, player)
        end
        window:Notify("Server Hop", "Joining new server...", 2)
    end
})

serverSection:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, player)
        window:Notify("Rejoin", "Rejoining server...", 2)
    end
})

-- COMMUNITY TAB
local communitySection = tabs.community:Section({Title = "Join Community"})

communitySection:Button({
    Title = "WhatsApp Group",
    Callback = function()
        if set_clipboard then
            set_clipboard("https://chat.whatsapp.com/I8hG44FLgrRAwQcS3lvEft")
            window:Notify("Copied!", "WhatsApp link copied!", 2)
        end
    end
})

communitySection:Button({
    Title = "Discord Server",
    Callback = function()
        if set_clipboard then
            set_clipboard("https://discord.gg/eDbaHKEf7G")
            window:Notify("Copied!", "Discord link copied!", 2)
        end
    end
})

communitySection:Button({
    Title = "TikTok @viunze",
    Callback = function()
        if set_clipboard then
            set_clipboard("https://tiktok.com/@viunze")
            window:Notify("Copied!", "TikTok profile copied!", 2)
        end
    end
})

-- Create initial hide part
createHidePart()

-- ============================================
-- CHARACTER RESPAWN HANDLER
-- ============================================
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    
    task.wait(0.5)
    pcall(function()
        humanoid.WalkSpeed = walkSpeedValue
        humanoid.JumpPower = jumpPowerValue
        humanoid.UseJumpPower = true
    end)
end)

-- ============================================
-- INITIAL NOTIFICATION
-- ============================================
task.wait(1)
window:Notify("PinatHub", "Loaded!", 3)
window:Open()
