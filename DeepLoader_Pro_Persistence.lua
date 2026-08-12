-- DeepLoader Pro - Persistence Mode with Toggle All
-- F8: Toggle UI | F9: Load All | F10: Toggle All

local DeepLoader = {}
local _loaded = {}
local _queue = {}
local _ui = nil
local _connections = {}

function DeepLoader:log(msg)
    print("[DeepLoader] " .. msg)
end

function DeepLoader:add(name, src)
    _queue[name] = src
    self:log("Added: " .. name)
end

function DeepLoader:load(name)
    local src = _queue[name]
    if not src then
        self:log("Script not found: " .. name, "ERROR")
        return false
    end
    if _loaded[name] then
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
        CoreGui = game:GetService("CoreGui")
    }
    setfenv(fn, env)
    local ok, res = pcall(fn)
    if not ok then
        self:log("Runtime error: " .. res, "ERROR")
        return false
    end
    _loaded[name] = { func = res, env = env }
    self:log("Loaded: " .. name, "SUCCESS")
    return true
end

function DeepLoader:unload(name)
    local data = _loaded[name]
    if not data then return false end
    if type(data.func) == "table" and data.func.Stop then
        pcall(data.func.Stop)
    elseif type(data.func) == "function" then
        pcall(data.func)
    end
    _loaded[name] = nil
    self:log("Unloaded: " .. name)
    return true
end

function DeepLoader:reload(name)
    if _loaded[name] then self:unload(name) end
    return self:load(name)
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
    for name in pairs(_loaded) do
        if self:unload(name) then count = count + 1 end
    end
    self:log("Unloaded " .. count .. " scripts")
    return count
end

function DeepLoader:toggleAll()
    local loadedCount = 0
    for name in pairs(_loaded) do
        loadedCount = loadedCount + 1
        break
    end
    if loadedCount > 0 then
        self:unloadAll()
    else
        self:loadAll()
    end
    -- Refresh UI if exists
    if _ui and _ui.Parent then
        for _, child in ipairs(_ui:GetDescendants()) do
            if child.Name == "ScrollingFrame" then
                child:Destroy()
            end
        end
        DeepLoader:createUI()
    end
end

function DeepLoader:createUI()
    if _ui then _ui:Destroy() _ui = nil end
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeepLoaderUI"
    gui.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 430)
    frame.Position = UDim2.new(0.5, -170, 0.5, -215)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BackgroundTransparency = 0.95
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "DeepLoader Pro"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -110)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 4
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local btnLoad = Instance.new("TextButton")
    btnLoad.Size = UDim2.new(0.28, 0, 0, 30)
    btnLoad.Position = UDim2.new(0.02, 0, 1, -45)
    btnLoad.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btnLoad.Text = "Load All"
    btnLoad.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnLoad.Font = Enum.Font.GothamBold
    btnLoad.TextSize = 13
    btnLoad.Parent = frame

    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 6)
    cornerBtn.Parent = btnLoad

    local btnUnload = Instance.new("TextButton")
    btnUnload.Size = UDim2.new(0.28, 0, 0, 30)
    btnUnload.Position = UDim2.new(0.33, 0, 1, -45)
    btnUnload.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btnUnload.Text = "Unload All"
    btnUnload.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnUnload.Font = Enum.Font.GothamBold
    btnUnload.TextSize = 13
    btnUnload.Parent = frame

    local cornerBtn2 = Instance.new("UICorner")
    cornerBtn2.CornerRadius = UDim.new(0, 6)
    cornerBtn2.Parent = btnUnload

    local btnToggle = Instance.new("TextButton")
    btnToggle.Size = UDim2.new(0.28, 0, 0, 30)
    btnToggle.Position = UDim2.new(0.64, 0, 1, -45)
    btnToggle.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
    btnToggle.Text = "Toggle All"
    btnToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnToggle.Font = Enum.Font.GothamBold
    btnToggle.TextSize = 13
    btnToggle.Parent = frame

    local cornerBtn3 = Instance.new("UICorner")
    cornerBtn3.CornerRadius = UDim.new(0, 6)
    cornerBtn3.Parent = btnToggle

    local function refreshUI()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local y = 0
        for name in pairs(_queue) do
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, 0, 0, 30)
            item.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            item.BackgroundTransparency = 0.5
            item.Parent = scroll

            local ic = Instance.new("UICorner")
            ic.CornerRadius = UDim.new(0, 4)
            ic.Parent = item

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 1, 0)
            label.Position = UDim2.new(0, 8, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = name
            label.TextColor3 = _loaded[name] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.Parent = item

            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(0, 60, 0, 22)
            toggle.Position = UDim2.new(0.7, 0, 0.5, -11)
            toggle.BackgroundColor3 = _loaded[name] and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
            toggle.Text = _loaded[name] and "Unload" or "Load"
            toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggle.TextSize = 11
            toggle.Font = Enum.Font.GothamBold
            toggle.Parent = item

            local tc = Instance.new("UICorner")
            tc.CornerRadius = UDim.new(0, 4)
            tc.Parent = toggle

            toggle.MouseButton1Click:Connect(function()
                if _loaded[name] then
                    DeepLoader:unload(name)
                else
                    DeepLoader:load(name)
                end
                refreshUI()
            end)

            y = y + 36
        end
        scroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
    end

    btnLoad.MouseButton1Click:Connect(function()
        DeepLoader:loadAll()
        refreshUI()
    end)

    btnUnload.MouseButton1Click:Connect(function()
        DeepLoader:unloadAll()
        refreshUI()
    end)

    btnToggle.MouseButton1Click:Connect(function()
        DeepLoader:toggleAll()
        refreshUI()
    end)

    refreshUI()
    _ui = gui
    DeepLoader:log("UI created in CoreGui")
    return gui
end

function DeepLoader:setupHotkeys()
    local uis = game:GetService("UserInputService")
    local conn = uis.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F8 then
            if _ui and _ui.Parent then
                _ui:Destroy()
                _ui = nil
                DeepLoader:log("UI closed")
            else
                DeepLoader:createUI()
            end
        elseif input.KeyCode == Enum.KeyCode.F9 then
            DeepLoader:loadAll()
            if _ui and _ui.Parent then
                for _, child in ipairs(_ui:GetDescendants()) do
                    if child.Name == "ScrollingFrame" then
                        child:Destroy()
                    end
                end
                DeepLoader:createUI()
            end
        elseif input.KeyCode == Enum.KeyCode.F10 then
            DeepLoader:toggleAll()
        end
    end)
    table.insert(_connections, conn)
end

function DeepLoader:setupAutoReload()
    local player = game:GetService("Players").LocalPlayer
    if not player then return end
    local conn = player.CharacterAdded:Connect(function(char)
        DeepLoader:log("Character added - reloading scripts...")
        for name in pairs(_loaded) do
            DeepLoader:reload(name)
        end
        if _ui and _ui.Parent then
            for _, child in ipairs(_ui:GetDescendants()) do
                if child.Name == "ScrollingFrame" then
                    child:Destroy()
                end
            end
            DeepLoader:createUI()
        end
    end)
    table.insert(_connections, conn)
    self:log("Auto-reload configured for match entry")
end

function DeepLoader:start()
    self:log("Starting DeepLoader Pro...")
    self:setupHotkeys()
    self:setupAutoReload()
    self:createUI()
    task.wait(0.5)
    self:loadAll()
    self:log("✅ Ready. F8=UI, F9=Load All, F10=Toggle All. Auto-reload on match entry.")
end

-- === ADD YOUR SCRIPTS HERE ===
DeepLoader:add("Forsaken AI", [[
    -- PASTE YOUR COMPLETE FORSAKEN AI SCRIPT HERE
    print("Forsaken AI script loaded")
]])

DeepLoader:start()
return DeepLoader