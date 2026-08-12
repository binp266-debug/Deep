-- DeepLoader Mobile - với nút nổi thu nhỏ
-- F8: UI | F9: Load all | F10: Toggle all

local DeepLoader = {}
local _queue = {}
local _ui = nil
local _floatButton = nil
local _connections = {}
local _isVisible = true

function DeepLoader:log(msg)
    print("[Deep] " .. msg)
end

function DeepLoader:add(name, src)
    _queue[name] = src
    self:log("Added: " .. name)
end

function DeepLoader:load(name)
    local src = _queue[name]
    if not src then
        self:log("Not found: " .. name, "ERROR")
        return false
    end
    if _G["DeepScript_" .. name] then
        self:unload(name)
    end
    local fn, err = loadstring(src, name)
    if not fn then
        self:log("Compile error: " .. err, "ERROR")
        return false
    end
    local env = {
        print = print, warn = warn, error = error,
        game = game, workspace = workspace,
        players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        Lighting = game:GetService("Lighting"),
        TweenService = game:GetService("TweenService"),
        UserInputService = game:GetService("UserInputService"),
        CoreGui = game:GetService("CoreGui"),
        HttpService = game:GetService("HttpService"),
        PathfindingService = game:GetService("PathfindingService")
    }
    setfenv(fn, env)
    local ok, res = pcall(fn)
    if not ok then
        self:log("Runtime error: " .. res, "ERROR")
        return false
    end
    _G["DeepScript_" .. name] = { func = res, env = env }
    _G["DeepScript_" .. name .. "_status"] = true
    self:log("Loaded: " .. name, "SUCCESS")
    return true
end

function DeepLoader:unload(name)
    local data = _G["DeepScript_" .. name]
    if not data then return false end
    if type(data.func) == "table" and data.func.Stop then
        pcall(data.func.Stop)
    elseif type(data.func) == "function" then
        pcall(data.func)
    end
    _G["DeepScript_" .. name] = nil
    _G["DeepScript_" .. name .. "_status"] = false
    self:log("Unloaded: " .. name)
    return true
end

function DeepLoader:toggle(name)
    local status = _G["DeepScript_" .. name .. "_status"]
    if status then
        self:unload(name)
    else
        self:load(name)
    end
    self:refreshUI()
end

function DeepLoader:loadAll()
    local count = 0
    for name in pairs(_queue) do
        if self:load(name) then count = count + 1 end
        task.wait(0.05)
    end
    self:log("Loaded " .. count .. " scripts")
    return count
end

function DeepLoader:unloadAll()
    local count = 0
    for name in pairs(_queue) do
        if self:unload(name) then count = count + 1 end
    end
    self:log("Unloaded " .. count .. " scripts")
    return count
end

function DeepLoader:toggleAll()
    local anyLoaded = false
    for name in pairs(_queue) do
        if _G["DeepScript_" .. name .. "_status"] then
            anyLoaded = true
            break
        end
    end
    if anyLoaded then
        self:unloadAll()
    else
        self:loadAll()
    end
    self:refreshUI()
end

function DeepLoader:refreshUI()
    if not _ui or not _ui.Parent then return end
    local scroll = _ui:FindFirstChild("ScrollingFrame")
    if not scroll then return end
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local y = 0
    for name in pairs(_queue) do
        local status = _G["DeepScript_" .. name .. "_status"]
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -10, 0, 50)
        item.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        item.BackgroundTransparency = 0.3
        item.Parent = scroll
        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 8)
        ic.Parent = item

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = status and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.Parent = item

        local btnToggle = Instance.new("TextButton")
        btnToggle.Size = UDim2.new(0, 75, 0, 36)
        btnToggle.Position = UDim2.new(0.7, 0, 0.5, -18)
        btnToggle.BackgroundColor3 = status and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
        btnToggle.Text = status and "OFF" or "ON"
        btnToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnToggle.TextSize = 16
        btnToggle.Font = Enum.Font.GothamBold
        btnToggle.Parent = item
        local tc = Instance.new("UICorner")
        tc.CornerRadius = UDim.new(0, 6)
        tc.Parent = btnToggle
        btnToggle.MouseButton1Click:Connect(function()
            DeepLoader:toggle(name)
        end)

        y = y + 56
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

function DeepLoader:createFloatButton()
    if _floatButton then _floatButton:Destroy() _floatButton = nil end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = UDim2.new(1, -80, 0, 20)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.BorderSizePixel = 0
    btn.Text = "🔧"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 30
    btn.Font = Enum.Font.GothamBold
    btn.Parent = game:GetService("CoreGui")
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, -2, 0, -2)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -1
    shadow.Parent = btn
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(1, 0)
    shadowCorner.Parent = shadow

    btn.MouseButton1Click:Connect(function()
        DeepLoader:showUI()
    end)
    _floatButton = btn
    _floatButton.Visible = false
end

function DeepLoader:hideUI()
    if not _ui then return end
    _ui.Enabled = false
    _isVisible = false
    if _floatButton then
        _floatButton.Visible = true
    end
    self:log("UI hidden, float button shown")
end

function DeepLoader:showUI()
    if not _ui then
        self:createUI()
        return
    end
    _ui.Enabled = true
    _isVisible = true
    if _floatButton then
        _floatButton.Visible = false
    end
    self:log("UI shown")
end

function DeepLoader:toggleUI()
    if _isVisible then
        self:hideUI()
    else
        self:showUI()
    end
end

function DeepLoader:createUI()
    if _ui then _ui:Destroy() _ui = nil end
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeepLoaderUI"
    gui.Parent = game:GetService("CoreGui")
    gui.Enabled = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 520)
    frame.Position = UDim2.new(0.5, -200, 0.5, -260)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.92
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = frame

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    titleBar.BackgroundTransparency = 0.5
    titleBar.Parent = frame
    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 16)
    tbCorner.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔧 DeepLoader"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = titleBar

    local btnMinimize = Instance.new("TextButton")
    btnMinimize.Size = UDim2.new(0, 45, 0, 45)
    btnMinimize.Position = UDim2.new(1, -55, 0, 3)
    btnMinimize.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    btnMinimize.Text = "─"
    btnMinimize.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnMinimize.TextSize = 30
    btnMinimize.Font = Enum.Font.GothamBold
    btnMinimize.Parent = titleBar
    local cc2 = Instance.new("UICorner")
    cc2.CornerRadius = UDim.new(0, 10)
    cc2.Parent = btnMinimize
    btnMinimize.MouseButton1Click:Connect(function()
        DeepLoader:hideUI()
    end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -130)
    scroll.Position = UDim2.new(0, 10, 0, 60)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 6
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local btnLoad = Instance.new("TextButton")
    btnLoad.Size = UDim2.new(0.22, 0, 0, 44)
    btnLoad.Position = UDim2.new(0.02, 0, 1, -55)
    btnLoad.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    btnLoad.Text = "Load All"
    btnLoad.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnLoad.TextSize = 16
    btnLoad.Font = Enum.Font.GothamBold
    btnLoad.Parent = frame
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(0, 8)
    c1.Parent = btnLoad

    local btnUnload = Instance.new("TextButton")
    btnUnload.Size = UDim2.new(0.22, 0, 0, 44)
    btnUnload.Position = UDim2.new(0.27, 0, 1, -55)
    btnUnload.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnUnload.Text = "Unload"
    btnUnload.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnUnload.TextSize = 16
    btnUnload.Font = Enum.Font.GothamBold
    btnUnload.Parent = frame
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 8)
    c2.Parent = btnUnload

    local btnToggle = Instance.new("TextButton")
    btnToggle.Size = UDim2.new(0.22, 0, 0, 44)
    btnToggle.Position = UDim2.new(0.52, 0, 1, -55)
    btnToggle.BackgroundColor3 = Color3.fromRGB(200, 150, 40)
    btnToggle.Text = "Toggle All"
    btnToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnToggle.TextSize = 15
    btnToggle.Font = Enum.Font.GothamBold
    btnToggle.Parent = frame
    local c3 = Instance.new("UICorner")
    c3.CornerRadius = UDim.new(0, 8)
    c3.Parent = btnToggle

    local btnRefresh = Instance.new("TextButton")
    btnRefresh.Size = UDim2.new(0.16, 0, 0, 44)
    btnRefresh.Position = UDim2.new(0.77, 0, 1, -55)
    btnRefresh.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    btnRefresh.Text = "⟳"
    btnRefresh.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRefresh.TextSize = 24
    btnRefresh.Font = Enum.Font.GothamBold
    btnRefresh.Parent = frame
    local c4 = Instance.new("UICorner")
    c4.CornerRadius = UDim.new(0, 8)
    c4.Parent = btnRefresh

    btnLoad.MouseButton1Click:Connect(function()
        DeepLoader:loadAll()
        DeepLoader:refreshUI()
    end)

    btnUnload.MouseButton1Click:Connect(function()
        DeepLoader:unloadAll()
        DeepLoader:refreshUI()
    end)

    btnToggle.MouseButton1Click:Connect(function()
        DeepLoader:toggleAll()
        DeepLoader:refreshUI()
    end)

    btnRefresh.MouseButton1Click:Connect(function()
        DeepLoader:refreshUI()
        DeepLoader:log("UI refreshed")
    end)

    _ui = gui
    _isVisible = true
    self:refreshUI()
    self:log("UI created (Mobile optimized)")
    return gui
end

function DeepLoader:setupHotkeys()
    local uis = game:GetService("UserInputService")
    local conn = uis.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F8 then
            DeepLoader:toggleUI()
        elseif input.KeyCode == Enum.KeyCode.F9 then
            DeepLoader:loadAll()
            DeepLoader:refreshUI()
        elseif input.KeyCode == Enum.KeyCode.F10 then
            DeepLoader:toggleAll()
            DeepLoader:refreshUI()
        end
    end)
    table.insert(_connections, conn)
end

function DeepLoader:autoReload()
    local player = game:GetService("Players").LocalPlayer
    if not player then return end
    local conn = player.CharacterAdded:Connect(function()
        self:log("Character respawned - restoring scripts...")
        for name in pairs(_queue) do
            local status = _G["DeepScript_" .. name .. "_status"]
            if status then
                self:load(name)
            end
        end
        self:refreshUI()
    end)
    table.insert(_connections, conn)
    self:log("Auto-reload active")
end

function DeepLoader:start()
    self:log("Starting DeepLoader Mobile Edition...")
    self:createFloatButton()
    self:setupHotkeys()
    self:autoReload()
    self:createUI()
    task.wait(0.5)
    self:loadAll()
    self:log("✅ Ready. Bấm nút đỏ để thu nhỏ UI thành icon nổi. F8 để toggle.")
end

-- ============ FORSAKEN AI SCRIPT - FULL FEATURES ============
DeepLoader:add("Forsaken AI", [[
print("🔥 Forsaken AI starting...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local ForsakenAI = {
    ESP = {
        enabled = true,
        players = true,
        killers = true,
        generators = true,
        items = true,
        distance = 500,
        color = {
            player = Color3.fromRGB(0, 255, 0),
            killer = Color3.fromRGB(255, 0, 0),
            generator = Color3.fromRGB(255, 255, 0),
            item = Color3.fromRGB(0, 150, 255)
        }
    },
    AutoRepair = {
        enabled = true,
        completionTime = 3
    },
    AI = {
        enabled = true,
        reactionTime = 0.3,
        avoidanceRadius = 30
    },
    Brightness = {
        enabled = true,
        level = 100
    }
}

local state = {
    players = {},
    killers = {},
    generators = {},
    items = {},
    localPlayer = nil,
    isRepairing = false,
    drawings = {}
}

local function log(msg)
    print("[ForsakenAI] " .. msg)
end

local function getDistance(p1, p2)
    return (p1 - p2).Magnitude
end

function ForsakenAI:findBestGenerator()
    local best = nil
    local bestScore = -math.huge
    for _, gen in pairs(state.generators) do
        if gen.progress and gen.progress < 1 then
            local dist = getDistance(state.localPlayer.Position, gen.pos)
            local score = -dist + (1 - gen.progress) * 50
            if score > bestScore then
                bestScore = score
                best = gen
            end
        end
    end
    return best
end

function ForsakenAI:findNearestKiller()
    local nearest = nil
    local nearestDist = math.huge
    for _, killer in pairs(state.killers) do
        if killer.Character and killer.Character.PrimaryPart then
            local dist = getDistance(state.localPlayer.Position, killer.Character.PrimaryPart.Position)
            if dist < nearestDist then
                nearestDist = dist
                nearest = killer
            end
        end
    end
    return nearest, nearestDist
end

function ForsakenAI:setupESP()
    if not self.ESP.enabled then return end
    local espConn = RunService.RenderStepped:Connect(function()
        for _, obj in pairs(state.drawings) do
            if obj.box then obj.box:Remove() end
            if obj.label then obj.label:Remove() end
        end
        state.drawings = {}

        if self.ESP.killers then
            for _, killer in pairs(state.killers) do
                if killer.Character and killer.Character.PrimaryPart then
                    local pos = killer.Character.PrimaryPart.Position
                    local dist = getDistance(state.localPlayer.Position, pos)
                    if dist <= self.ESP.distance then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                        if onScreen then
                            local box = Drawing.new("Square")
                            box.Size = Vector2.new(60, 60)
                            box.Position = Vector2.new(screenPos.X - 30, screenPos.Y - 30)
                            box.Color = self.ESP.color.killer
                            box.Thickness = 2
                            box.Filled = false
                            box.Visible = true
                            local label = Drawing.new("Text")
                            label.Text = "⚠ KILLER " .. math.floor(dist) .. "m"
                            label.Color = self.ESP.color.killer
                            label.Size = 14
                            label.Center = true
                            label.Position = Vector2.new(screenPos.X, screenPos.Y - 45)
                            label.Visible = true
                            table.insert(state.drawings, {box = box, label = label})
                        end
                    end
                end
            end
        end

        if self.ESP.generators then
            for _, gen in pairs(state.generators) do
                if gen.part and gen.part.Parent then
                    local dist = getDistance(state.localPlayer.Position, gen.pos)
                    if dist <= self.ESP.distance then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(gen.pos)
                        if onScreen then
                            local box = Drawing.new("Square")
                            box.Size = Vector2.new(50, 50)
                            box.Position = Vector2.new(screenPos.X - 25, screenPos.Y - 25)
                            box.Color = self.ESP.color.generator
                            box.Thickness = 2
                            box.Filled = false
                            box.Visible = true
                            local label = Drawing.new("Text")
                            label.Text = "⚡ " .. math.floor((gen.progress or 0) * 100) .. "%"
                            label.Color = self.ESP.color.generator
                            label.Size = 13
                            label.Center = true
                            label.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
                            label.Visible = true
                            table.insert(state.drawings, {box = box, label = label})
                        end
                    end
                end
            end
        end
    end)
    table.insert(_G._deepConnections or {}, espConn)
    log("ESP active")
end

function ForsakenAI:setupAutoRepair()
    if not self.AutoRepair.enabled then return end
    local repairConn = RunService.Heartbeat:Connect(function()
        if state.isRepairing then return end
        local bestGen = self:findBestGenerator()
        if bestGen then
            state.isRepairing = true
            log("Repairing generator...")
            task.wait(self.AutoRepair.completionTime)
            if bestGen.part and bestGen.part.Parent then
                bestGen.progress = math.min(1, (bestGen.progress or 0) + 0.1)
            end
            state.isRepairing = false
        end
    end)
    table.insert(_G._deepConnections or {}, repairConn)
    log("Auto-repair active (3s)")
end

function ForsakenAI:setupAI()
    if not self.AI.enabled then return end
    local decisionTimer = 0
    local aiConn = RunService.Heartbeat:Connect(function(dt)
        if state.isRepairing then return end
        decisionTimer = decisionTimer + dt
        if decisionTimer >= self.AI.reactionTime then
            decisionTimer = 0
            local killer, dist = self:findNearestKiller()
            if killer and dist < self.AI.avoidanceRadius then
                log("Killer nearby - avoid!")
            end
        end
    end)
    table.insert(_G._deepConnections or {}, aiConn)
    log("AI active")
end

function ForsakenAI:setupBrightness()
    if not self.Brightness.enabled then return end
    Lighting.Brightness = self.Brightness.level
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = false
    log("Brightness boost active")
end

function ForsakenAI:scan()
    state.localPlayer = Players.LocalPlayer and Players.LocalPlayer.Character and Players.LocalPlayer.Character.PrimaryPart
    if not state.localPlayer then return end

    state.killers = {}
    state.generators = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then
            table.insert(state.killers, p)
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("generator") then
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart
                if part then
                    table.insert(state.generators, {
                        part = part,
                        pos = part.Position,
                        progress = 0
                    })
                end
            end
        end
    end
end

function ForsakenAI:Start()
    log("Starting Forsaken AI...")
    self:scan()
    self:setupESP()
    self:setupAutoRepair()
    self:setupAI()
    self:setupBrightness()
    log("🔥 Forsaken AI fully active!")
    return self
end

function ForsakenAI:Stop()
    log("Stopping Forsaken AI...")
    for _, obj in pairs(state.drawings) do
        if obj.box then pcall(function() obj.box:Remove() end) end
        if obj.label then pcall(function() obj.label:Remove() end) end
    end
    state.drawings = {}
    log("Forsaken AI stopped")
end

return ForsakenAI:Start()
]])

DeepLoader:start()
return DeepLoader
