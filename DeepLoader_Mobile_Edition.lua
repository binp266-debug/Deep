-- DeepLoader Mobile Edition - dành cho điện thoại, sờ là chạy
-- F8: UI (nếu có bàn phím) | Chạm nút trên UI để điều khiển

local DeepLoader = {}
local _queue = {}
local _ui = nil
local _connections = {}

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
        CoreGui = game:GetService("CoreGui")
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

function DeepLoader:copyScript(name)
    local src = _queue[name]
    if not src then
        self:log("Script not found: " .. name, "ERROR")
        return
    end
    local success = pcall(function()
        setclipboard(src)
    end)
    if success then
        self:log("✅ Script copied to clipboard: " .. name)
        if _ui and _ui.Parent then
            local notif = Instance.new("TextLabel")
            notif.Size = UDim2.new(1, 0, 0, 40)
            notif.Position = UDim2.new(0, 0, 1, -40)
            notif.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
            notif.BackgroundTransparency = 0.2
            notif.Text = "✅ Copied: " .. name
            notif.TextColor3 = Color3.fromRGB(255, 255, 255)
            notif.TextSize = 16
            notif.Font = Enum.Font.GothamBold
            notif.Parent = _ui
            game:GetService("Debris"):AddItem(notif, 2)
        end
    else
        self:log("Copy failed - clipboard not available", "ERROR")
    end
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

        local btnCopy = Instance.new("TextButton")
        btnCopy.Size = UDim2.new(0, 55, 0, 36)
        btnCopy.Position = UDim2.new(0.52, 0, 0.5, -18)
        btnCopy.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
        btnCopy.Text = "📋"
        btnCopy.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnCopy.TextSize = 20
        btnCopy.Font = Enum.Font.GothamBold
        btnCopy.Parent = item
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = btnCopy
        btnCopy.MouseButton1Click:Connect(function()
            DeepLoader:copyScript(name)
        end)

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

function DeepLoader:createUI()
    if _ui then _ui:Destroy() _ui = nil end
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeepLoaderUI"
    gui.Parent = game:GetService("CoreGui")

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
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔧 DeepLoader Mobile"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = titleBar

    local btnClose = Instance.new("TextButton")
    btnClose.Size = UDim2.new(0, 45, 0, 45)
    btnClose.Position = UDim2.new(1, -55, 0, 3)
    btnClose.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    btnClose.Text = "✕"
    btnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnClose.TextSize = 22
    btnClose.Font = Enum.Font.GothamBold
    btnClose.Parent = titleBar
    local cc2 = Instance.new("UICorner")
    cc2.CornerRadius = UDim.new(0, 10)
    cc2.Parent = btnClose
    btnClose.MouseButton1Click:Connect(function()
        if _ui then
            _ui:Destroy()
            _ui = nil
            DeepLoader:log("UI closed")
        end
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
    self:refreshUI()
    self:log("UI created (Mobile optimized)")
    return gui
end

function DeepLoader:setupHotkeys()
    -- Vẫn giữ hotkey cho ai có bàn phím
    local uis = game:GetService("UserInputService")
    local conn = uis.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F8 then
            if _ui and _ui.Parent then
                _ui:Destroy()
                _ui = nil
            else
                self:createUI()
            end
        elseif input.KeyCode == Enum.KeyCode.F9 then
            self:loadAll()
            self:refreshUI()
        elseif input.KeyCode == Enum.KeyCode.F10 then
            self:toggleAll()
            self:refreshUI()
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
    self:setupHotkeys()
    self:autoReload()
    self:createUI()
    task.wait(0.5)
    self:loadAll()
    self:log("✅ Ready. Mở UI bằng F8 (nếu có phím) hoặc chạm nút trên màn hình. Tự động restore khi respawn.")
end

-- === PASTE YOUR FORSAKEN AI SCRIPT HERE ===
DeepLoader:add("Forsaken AI", [[
    -- Paste YOUR Forsaken AI script here
    print("🔥 Forsaken AI loaded on mobile")
]])

DeepLoader:start()
return DeepLoader