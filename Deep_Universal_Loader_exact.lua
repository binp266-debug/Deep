-- Deep Universal Loader (Lightweight)
-- F8: Toggle UI | F9: Reload all scripts

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
        UserInputService = game:GetService("UserInputService")
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
end

function DeepLoader:unloadAll()
    local count = 0
    for name in pairs(_loaded) do
        if self:unload(name) then count = count + 1 end
    end
    self:log("Unloaded " .. count .. " scripts")
end

function DeepLoader:createUI()
    if _ui then _ui:Destroy() _ui = nil end
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeepLoaderUI"
    gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 400)
    frame.Position = UDim2.new(0.5, -160, 0.5, -200)
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
    title.Text = "DeepLoader"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -80)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 4
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local btnAll = Instance.new("TextButton")
    btnAll.Size = UDim2.new(0.4, 0, 0, 30)
    btnAll.Position = UDim2.new(0.05, 0, 1, -40)
    btnAll.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btnAll.Text = "Load All"
    btnAll.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAll.Font = Enum.Font.GothamBold
    btnAll.TextSize = 14
    btnAll.Parent = frame

    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 6)
    cornerBtn.Parent = btnAll

    local btnUnload = Instance.new("TextButton")
    btnUnload.Size = UDim2.new(0.4, 0, 0, 30)
    btnUnload.Position = UDim2.new(0.55, 0, 1, -40)
    btnUnload.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btnUnload.Text = "Unload All"
    btnUnload.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnUnload.Font = Enum.Font.GothamBold
    btnUnload.TextSize = 14
    btnUnload.Parent = frame

    local cornerBtn2 = Instance.new("UICorner")
    cornerBtn2.CornerRadius = UDim.new(0, 6)
    cornerBtn2.Parent = btnUnload

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

    btnAll.MouseButton1Click:Connect(function()
        DeepLoader:loadAll()
        refreshUI()
    end)

    btnUnload.MouseButton1Click:Connect(function()
        DeepLoader:unloadAll()
        refreshUI()
    end)

    refreshUI()
    _ui = gui
    DeepLoader:log("UI created")
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
        end
    end)
    table.insert(_connections, conn)
end

function DeepLoader:start()
    self:log("Starting...")
    self:setupHotkeys()
    self:createUI()
    self:log("✅ Ready. Press F8 for UI, F9 to load all.")
end

-- === ADD YOUR SCRIPTS HERE ===
DeepLoader:add("Forsaken AI", [[
    -- Paste your whole Forsaken AI script here (the one named "Deep")
    -- Or any script you want to load
]])

DeepLoader:start()
return DeepLoader