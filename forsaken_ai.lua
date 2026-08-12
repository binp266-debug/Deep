local ForsakenAI = {
    Config = {
        ESP = {
            Enabled = true,
            Players = true,
            Killers = true,
            Generators = true,
            Items = true,
            Distance = 500,
            BoxSize = 2,
            Color = {
                Player = Color3.fromRGB(0, 255, 0),
                Killer = Color3.fromRGB(255, 0, 0),
                Generator = Color3.fromRGB(255, 255, 0),
                Item = Color3.fromRGB(0, 150, 255)
            }
        },
        AutoRepair = {
            Enabled = true,
            CompletionTime = 3,
            Priority = {"Nearby", "LowestProgress"}
        },
        AI = {
            Enabled = true,
            ReactionTime = 0.3,
            AvoidanceRadius = 30,
            TargetPriority = "NearestGenerator"
        },
        Brightness = {
            Enabled = true,
            Level = 100
        }
    },
    State = {
        Players = {},
        Killers = {},
        Generators = {},
        Items = {},
        LocalPlayer = nil,
        CurrentTarget = nil,
        IsRepairing = false,
        DecisionTimer = 0
    },
    _cache = {},
    _connections = {},
    _running = false
}

function ForsakenAI:Log(message, level)
    level = level or "INFO"
    if level == "ERROR" then
        warn("[ForsakenAI] " .. message)
    elseif level == "WARN" then
        print("[ForsakenAI] ⚠ " .. message)
    else
        print("[ForsakenAI] ✓ " .. message)
    end
end

function ForsakenAI:GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function ForsakenAI:Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function ForsakenAI:FindClosest(list, position, filter)
    local closest = nil
    local closestDist = math.huge
    for _, item in ipairs(list) do
        if not filter or filter(item) then
            local dist = self:GetDistance(position, item.Position)
            if dist < closestDist then
                closestDist = dist
                closest = item
            end
        end
    end
    return closest, closestDist
end

function ForsakenAI:SetupESP()
    if not self.Config.ESP.Enabled then return end
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local drawings = {}
    function self:CreateESPBox(object, color, text)
        local pos, onScreen = Camera:WorldToViewportPoint(object.Position)
        if not onScreen then return nil end
        local box = Drawing.new("Square")
        box.Size = Vector2.new(self.Config.ESP.BoxSize * 50, self.Config.ESP.BoxSize * 50)
        box.Position = Vector2.new(pos.X - box.Size.X/2, pos.Y - box.Size.Y/2)
        box.Color = color
        box.Thickness = 2
        box.Filled = false
        box.Visible = true
        if text then
            local label = Drawing.new("Text")
            label.Text = text
            label.Color = color
            label.Size = 14
            label.Center = true
            label.Position = Vector2.new(pos.X, pos.Y - box.Size.Y/2 - 20)
            label.Visible = true
            return {box = box, label = label}
        end
        return {box = box}
    end
    local espConnection = RunService.RenderStepped:Connect(function()
        for _, obj in pairs(drawings) do
            if obj.box then obj.box:Remove() end
            if obj.label then obj.label:Remove() end
        end
        drawings = {}
        if self.Config.ESP.Players then
            for _, player in pairs(self.State.Players) do
                if player.Character and player.Character.PrimaryPart then
                    local pos = player.Character.PrimaryPart.Position
                    if self:GetDistance(self.State.LocalPlayer.Position, pos) <= self.Config.ESP.Distance then
                        local obj = self:CreateESPBox({Position = pos}, self.Config.ESP.Color.Player,
                            player.Name .. " | " .. math.floor(self:GetDistance(self.State.LocalPlayer.Position, pos)) .. "m")
                        if obj then table.insert(drawings, obj) end
                    end
                end
            end
        end
        if self.Config.ESP.Killers then
            for _, killer in pairs(self.State.Killers) do
                if killer.Character and killer.Character.PrimaryPart then
                    local pos = killer.Character.PrimaryPart.Position
                    if self:GetDistance(self.State.LocalPlayer.Position, pos) <= self.Config.ESP.Distance then
                        local obj = self:CreateESPBox({Position = pos}, self.Config.ESP.Color.Killer,
                            "⚠ KILLER | " .. math.floor(self:GetDistance(self.State.LocalPlayer.Position, pos)) .. "m")
                        if obj then table.insert(drawings, obj) end
                    end
                end
            end
        end
        if self.Config.ESP.Generators then
            for _, gen in pairs(self.State.Generators) do
                if gen.Part and gen.Part.Parent then
                    local pos = gen.Part.Position
                    if self:GetDistance(self.State.LocalPlayer.Position, pos) <= self.Config.ESP.Distance then
                        local progress = gen.Progress or 0
                        local obj = self:CreateESPBox({Position = pos}, self.Config.ESP.Color.Generator,
                            "⚡ Gen " .. math.floor(progress * 100) .. "%")
                        if obj then table.insert(drawings, obj) end
                    end
                end
            end
        end
        if self.Config.ESP.Items then
            for _, item in pairs(self.State.Items) do
                if item.Part and item.Part.Parent then
                    local pos = item.Part.Position
                    if self:GetDistance(self.State.LocalPlayer.Position, pos) <= self.Config.ESP.Distance then
                        local obj = self:CreateESPBox({Position = pos}, self.Config.ESP.Color.Item, item.Name or "Item")
                        if obj then table.insert(drawings, obj) end
                    end
                end
            end
        end
    end)
    table.insert(self._connections, espConnection)
    self:Log("ESP System initialized")
end

function ForsakenAI:SetupAutoRepair()
    if not self.Config.AutoRepair.Enabled then return end
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local repairStartTime = 0
    local currentGen = nil
    function self:FindBestGenerator()
        local best = nil
        local bestScore = -math.huge
        for _, gen in pairs(self.State.Generators) do
            if gen.Progress and gen.Progress < 1 then
                local distance = self:GetDistance(self.State.LocalPlayer.Position, gen.Part.Position)
                local score = 0
                if self.Config.AutoRepair.Priority[1] == "Nearby" then
                    score = -distance + (1 - gen.Progress) * 50
                elseif self.Config.AutoRepair.Priority[1] == "LowestProgress" then
                    score = (1 - gen.Progress) * 100 - distance * 0.5
                end
                if score > bestScore then
                    bestScore = score
                    best = gen
                end
            end
        end
        return best
    end
    function self:RepairGenerator(gen)
        if not gen or not gen.Part or not gen.Part.Parent then return false end
        local mouse = UserInputService:GetMouseLocation()
        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(gen.Part.Position)
        if not onScreen then
            local tweenService = game:GetService("TweenService")
            local newCFrame = CFrame.new(self.State.LocalPlayer.Position, gen.Part.Position)
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(newCFrame, 0.3)
        end
        local repairButton = self:FindRepairButton()
        if repairButton then
            repairButton:Fire()
            repairStartTime = tick()
            currentGen = gen
            self.State.IsRepairing = true
            task.wait(self.Config.AutoRepair.CompletionTime)
            if gen.Progress then
                gen.Progress = math.min(1, gen.Progress + 0.1)
            end
            self.State.IsRepairing = false
            return true
        end
        return false
    end
    local repairConnection = RunService.Heartbeat:Connect(function()
        if not self.Config.AutoRepair.Enabled then return end
        if self.State.IsRepairing then return end
        local bestGen = self:FindBestGenerator()
        if bestGen then self:RepairGenerator(bestGen) end
    end)
    table.insert(self._connections, repairConnection)
    self:Log("Auto-Repair System initialized (3s per repair)")
end

function ForsakenAI:FindRepairButton()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local possiblePaths = {"ScreenGui.RepairButton", "MainGUI.InteractButton", "GameUI.ActionButton", "HUD.Repair"}
    for _, path in ipairs(possiblePaths) do
        local parts = {}
        for part in path:gmatch("[^%.]+") do table.insert(parts, part) end
        local current = playerGui
        local found = true
        for _, part in ipairs(parts) do
            current = current:FindFirstChild(part)
            if not current then found = false break end
        end
        if found and current then
            if current:IsA("ImageButton") or current:IsA("TextButton") then return current
            elseif current:IsA("Frame") then
                for _, child in ipairs(current:GetChildren()) do
                    if child:IsA("ImageButton") or child:IsA("TextButton") then return child end
                end
            end
        end
    end
    return nil
end

function ForsakenAI:SetupAI()
    if not self.Config.AI.Enabled then return end
    local RunService = game:GetService("RunService")
    local decisionInterval = self.Config.AI.ReactionTime
    local lastDecision = 0
    function self:MakeDecision()
        local localPos = self.State.LocalPlayer.Position
        local nearestKiller, killerDist = self:FindClosest(self.State.Killers, localPos,
            function(k) return k.Character and k.Character.PrimaryPart end)
        if nearestKiller and killerDist < self.Config.AI.AvoidanceRadius then
            self:Log("AI: Threat detected! Evading killer")
            self:EvadeThreat(nearestKiller)
            return
        end
        local targetGen = self:FindBestGenerator()
        if targetGen then
            self.State.CurrentTarget = targetGen
            self:NavigateTo(targetGen.Part.Position)
            self:Log("AI: Moving to generator at " .. math.floor(self:GetDistance(localPos, targetGen.Part.Position)) .. "m")
        else self:Wander() end
    end
    function self:EvadeThreat(killer)
        local localPos = self.State.LocalPlayer.Position
        local killerPos = killer.Character.PrimaryPart.Position
        local dir = (localPos - killerPos).Unit
        local evadePos = localPos + dir * 50 + Vector3.new(math.random(-10,10),0,math.random(-10,10))
        self:NavigateTo(evadePos)
    end
    function self:NavigateTo(targetPos)
        local humanoid = self.State.LocalPlayer.Character:FindFirstChild("Humanoid")
        if not humanoid then return end
        humanoid:MoveTo(targetPos)
    end
    function self:Wander()
        local localPos = self.State.LocalPlayer.Position
        local wanderPos = localPos + Vector3.new(math.random(-30,30),0,math.random(-30,30))
        self:NavigateTo(wanderPos)
    end
    local aiConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not self.Config.AI.Enabled or self.State.IsRepairing then return end
        lastDecision = lastDecision + deltaTime
        if lastDecision >= decisionInterval then
            lastDecision = 0
            self:MakeDecision()
        end
    end)
    table.insert(self._connections, aiConnection)
    self:Log("AI System initialized (reaction time: " .. decisionInterval .. "s)")
end

function ForsakenAI:SetupBrightness()
    if not self.Config.Brightness.Enabled then return end
    local Lighting = game:GetService("Lighting")
    local level = self.Config.Brightness.Level / 100
    Lighting.Brightness = level * 2
    Lighting.Ambient = Color3.fromRGB(255 * level, 255 * level, 255 * level)
    Lighting.EnvironmentDiffuseScale = level
    Lighting.EnvironmentSpecularScale = level
    if level > 0.5 then
        Lighting.FogEnd = 1000
        Lighting.FogStart = 100
    else
        Lighting.FogEnd = 500
        Lighting.FogStart = 50
    end
    self:Log("Brightness set to " .. self.Config.Brightness.Level .. "%")
end

function ForsakenAI:TrackGameState()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = workspace
    self.State.LocalPlayer = Players.LocalPlayer
    if self.State.LocalPlayer.Character and self.State.LocalPlayer.Character.PrimaryPart then
        self.State.LocalPlayer.Position = self.State.LocalPlayer.Character.PrimaryPart.Position
    end
    local function updatePlayers()
        self.State.Players = {}
        self.State.Killers = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= self.State.LocalPlayer then
                local isKiller = player.Character and player.Character:FindFirstChild("KillerTag") ~= nil
                if isKiller then table.insert(self.State.Killers, player)
                else table.insert(self.State.Players, player) end
            end
        end
    end
    local function updateGenerators()
        self.State.Generators = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("generator") then
                local gen = {
                    Part = obj,
                    Position = obj.Position,
                    Progress = obj:FindFirstChild("Progress") and obj.Progress.Value or 0
                }
                table.insert(self.State.Generators, gen)
            end
        end
    end
    local function updateItems()
        self.State.Items = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj:FindFirstChild("ItemTag") then
                table.insert(self.State.Items, {Part=obj, Position=obj.Position, Name=obj.Name})
            end
        end
    end
    local trackConnection = RunService.Heartbeat:Connect(function()
        updatePlayers()
        updateGenerators()
        updateItems()
        if self.State.LocalPlayer.Character and self.State.LocalPlayer.Character.PrimaryPart then
            self.State.LocalPlayer.Position = self.State.LocalPlayer.Character.PrimaryPart.Position
        end
    end)
    table.insert(self._connections, trackConnection)
    self:Log("Game state tracking initialized")
end

function ForsakenAI:Start()
    if self._running then self:Log("Already running!", "WARN") return end
    self:Log("Initializing Forsaken AI Assistant...")
    self:TrackGameState()
    self:SetupESP()
    self:SetupAutoRepair()
    self:SetupAI()
    self:SetupBrightness()
    self._running = true
    self:Log("All systems operational! AI Assistant is ready.")
end

function ForsakenAI:Stop()
    if not self._running then self:Log("Already stopped!", "WARN") return end
    self:Log("Shutting down all systems...")
    for _, conn in ipairs(self._connections) do conn:Disconnect() end
    self._connections = {}
    self.State.IsRepairing = false
    self.State.CurrentTarget = nil
    self._running = false
    local Lighting = game:GetService("Lighting")
    Lighting.Brightness = 1
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    self:Log("Forsaken AI Assistant stopped.")
end

function ForsakenAI:ToggleESP()
    self.Config.ESP.Enabled = not self.Config.ESP.Enabled
    self:Log("ESP " .. (self.Config.ESP.Enabled and "enabled" or "disabled"))
end

function ForsakenAI:ToggleAutoRepair()
    self.Config.AutoRepair.Enabled = not self.Config.AutoRepair.Enabled
    self:Log("Auto-Repair " .. (self.Config.AutoRepair.Enabled and "enabled" or "disabled"))
end

function ForsakenAI:ToggleAI()
    self.Config.AI.Enabled = not self.Config.AI.Enabled
    self:Log("AI Auto-Play " .. (self.Config.AI.Enabled and "enabled" or "disabled"))
end

function ForsakenAI:SetBrightness(level)
    level = self:Clamp(level, 0, 100)
    self.Config.Brightness.Level = level
    self:SetupBrightness()
    self:Log("Brightness set to " .. level .. "%")
end

function ForsakenAI:SetupHotkeys()
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F1 then self:ToggleESP()
        elseif input.KeyCode == Enum.KeyCode.F2 then self:ToggleAutoRepair()
        elseif input.KeyCode == Enum.KeyCode.F3 then self:ToggleAI()
        elseif input.KeyCode == Enum.KeyCode.F4 then
            if self._running then self:Stop() else self:Start() end
        elseif input.KeyCode == Enum.KeyCode.F5 then self:SetBrightness(self.Config.Brightness.Level + 10)
        elseif input.KeyCode == Enum.KeyCode.F6 then self:SetBrightness(self.Config.Brightness.Level - 10) end
    end)
    self:Log("Hotkeys configured: F1=ESP, F2=Repair, F3=AI, F4=Start/Stop, F5/F6=Brightness")
end

local instance = ForsakenAI
instance:SetupHotkeys()
instance:Start()
return ForsakenAI
