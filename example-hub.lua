-- example-hub.lua
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LP = Players.LocalPlayer

local Blossom = loadstring(game:HttpGet("https://raw.githubusercontent.com/ruulovesyou/Bloosomm/main/Blossom/Blossom.lua"))()

local win = Blossom:CreateWindow({
    Name = "Blossom Hub",
    Subtitle = "example",
    Theme = "Blossom",
    Size = UDim2.fromOffset(420, 340),
})

local function log(msg)
    win:Notify({title = "Hub", content = msg})
end

-- shared state
local State = {
    master = false,
    loops = {},
    rates = {collect = 1, buy = 3, merge = 5, hire = 0.5},
}

local function spawnLoop(name, fn)
    if not State.master or State.loops[name] then return end
    State.loops[name] = true
    task.spawn(function()
        while State.master and State.loops[name] do
            local ok, err = pcall(fn)
            if not ok then log(name .. " error: " .. tostring(err)) end
            task.wait(State.rates[name])
        end
        State.loops[name] = nil
    end)
end

local function stopLoop(name) State.loops[name] = nil end
local function stopAll() table.clear(State.loops) end

-- MAIN tab
local mainTab = win:CreateTab({Name = "Main"})

mainTab:CreateSection({Name = "Master", Column = 1})
mainTab:CreateToggle({
    Name = "Enable Hub", Flag = "master", Default = false,
    Callback = function(on)
        State.master = on
        log(on and "hub enabled" or "hub disabled")
        if not on then stopAll() end
    end,
})
mainTab:CreateKeybind({
    Name = "Toggle Hub", Flag = "hub_key", Value = Enum.KeyCode.RightControl,
    Callback = function(key) log("keybind: " .. tostring(key)) end,
})

mainTab:CreateSection({Name = "Status", Column = 2})
mainTab:CreateButton({
    Name = "Check connection", Flag = "check_connection",
    Callback = function()
        log(string.format("player: %s | game: %d", LP.Name, game.PlaceId))
    end,
})

-- FARM tab
local farmTab = win:CreateTab({Name = "Farm"})

farmTab:CreateSection({Name = "Actions", Column = 1})
farmTab:CreateToggle({
    Name = "Auto Collect", Flag = "auto_collect", Default = false,
    Callback = function(on)
        if on then
            spawnLoop("collect", function()
                -- press({"Sell", "CollectButton", "Button"})
            end)
        else
            stopLoop("collect")
        end
    end,
})
farmTab:CreateToggle({
    Name = "Auto Buy", Flag = "auto_buy", Default = false,
    Callback = function(on)
        if on then
            spawnLoop("buy", function()
                -- press({"Buttons", "ButtonBuy1", "Button"})
            end)
        else
            stopLoop("buy")
        end
    end,
})
farmTab:CreateToggle({
    Name = "Auto Merge", Flag = "auto_merge", Default = false,
    Callback = function(on)
        if on then
            spawnLoop("merge", function()
                -- press({"Buttons", "ButtonMerge", "Button"})
            end)
        else
            stopLoop("merge")
        end
    end,
})
farmTab:CreateSlider({
    Name = "Collect Rate", Flag = "collect_rate",
    Range = {0.1, 10}, Increment = 0.1, Default = 1, Suffix = "s",
    Callback = function(v) State.rates.collect = v end,
})
farmTab:CreateSlider({
    Name = "Buy Rate", Flag = "buy_rate",
    Range = {1, 30}, Increment = 1, Default = 3, Suffix = "s",
    Callback = function(v) State.rates.buy = v end,
})

farmTab:CreateSection({Name = "Target", Column = 2})
farmTab:CreateDropdown({
    Name = "Plot", Flag = "plot",
    Options = {"auto", "Plot_1", "Plot_2", "Plot_3"}, Value = "auto",
    Callback = function(v) log("target plot: " .. v) end,
})
farmTab:CreateDropdown({
    Name = "Hire Amount", Flag = "hire_amount",
    Options = {"hire 1", "hire 5", "hire 25"}, Value = "hire 1",
    Callback = function(v) log("hire: " .. v) end,
})
farmTab:CreateToggle({
    Name = "Auto Hire", Flag = "auto_hire", Default = false,
    Callback = function(on)
        if on then
            spawnLoop("hire", function()
                -- press({"Buttons", "ButtonBuy1", "Button"})
            end)
        else
            stopLoop("hire")
        end
    end,
})
farmTab:CreateButton({
    Name = "Stop All Loops", Flag = "stop_loops",
    Callback = function()
        stopAll()
        log("loops stopped")
    end,
})

-- VISUAL tab
local visualTab = win:CreateTab({Name = "Visual"})

visualTab:CreateSection({Name = "ESP", Column = 1})

local ESP_FOLDER = Instance.new("Folder")
ESP_FOLDER.Name = "HubESP"
ESP_FOLDER.Parent = game:GetService("CoreGui")

local tracked = {}
local espOn, espRunning = false, false
local espColor = Color3.fromRGB(255, 80, 80)

local function makeHighlight(model)
    local h = Instance.new("Highlight")
    h.Adornee = model
    h.FillColor = espColor
    h.OutlineColor = espColor
    h.FillTransparency = 0.7
    h.OutlineTransparency = 0.1
    h.Parent = ESP_FOLDER
    return h
end

local function clearESP()
    for model, h in pairs(tracked) do
        h:Destroy()
        tracked[model] = nil
    end
end

visualTab:CreateToggle({
    Name = "Player ESP", Flag = "player_esp", Default = false,
    Callback = function(on)
        espOn = on
        if not on then
            clearESP()
            return
        end
        if espRunning then return end
        espRunning = true
        task.spawn(function()
            while espOn do
                for _, player in ipairs(Players:GetPlayers()) do
                    local char = player ~= LP and player.Character
                    if char and not tracked[char] then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            tracked[char] = makeHighlight(char)
                        end
                    end
                end
                task.wait(0.5)
            end
            espRunning = false
        end)
    end,
})
visualTab:CreateSlider({
    Name = "Max Distance", Flag = "esp_range",
    Range = {50, 2000}, Increment = 50, Default = 500,
    Callback = function(v) log("esp range: " .. v) end,
})
visualTab:CreateColorPicker({
    Name = "Enemy Color", Flag = "enemy_color", Color = espColor,
    Callback = function(c)
        if typeof(c) == "Color3" then espColor = c end
    end,
})

visualTab:CreateSection({Name = "World", Column = 2})
visualTab:CreateToggle({
    Name = "Fullbright", Flag = "fullbright", Default = false,
    Callback = function(on)
        local l = game:GetService("Lighting")
        l.Brightness = on and 2 or 1
        l.ClockTime = on and 12 or 14
        l.GlobalShadows = not on
    end,
})
visualTab:CreateSlider({
    Name = "FOV", Flag = "fov",
    Range = {70, 120}, Increment = 1, Default = 70,
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end,
})

-- MISC tab
local miscTab = win:CreateTab({Name = "Misc"})

miscTab:CreateSection({Name = "Player", Column = 1})
miscTab:CreateSlider({
    Name = "Walk Speed", Flag = "walk_speed",
    Range = {16, 200}, Increment = 2, Default = 16,
    Callback = function(v)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})
miscTab:CreateSlider({
    Name = "Jump Power", Flag = "jump_power",
    Range = {50, 300}, Increment = 5, Default = 50,
    Callback = function(v)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

local infiniteJump = false
UIS.JumpRequest:Connect(function()
    if not infiniteJump then return end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
miscTab:CreateToggle({
    Name = "Infinite Jump", Flag = "infinite_jump", Default = false,
    Callback = function(on) infiniteJump = on end,
})

miscTab:CreateSection({Name = "Utility", Column = 2})
miscTab:CreateInput({
    Name = "Custom Name", Flag = "custom_name", Default = "",
    Callback = function(v) log("saved: " .. v) end,
})
miscTab:CreateButton({
    Name = "Rejoin Server", Flag = "rejoin",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end,
})
miscTab:CreateButton({
    Name = "Unload Hub", Flag = "unload",
    Callback = function()
        clearESP()
        ESP_FOLDER:Destroy()
        win:Destroy()
    end,
})

-- CONFIG tab
local cfgTab = win:CreateTab({Name = "Config"})

cfgTab:CreateSection({Name = "Theme", Column = 1})
cfgTab:CreateDropdown({
    Name = "Preset", Flag = "preset",
    Options = win:GetThemePresets(), Value = "Blossom",
    Callback = function(name) win:ChangeTheme(name) end,
})

cfgTab:CreateSection({Name = "Profiles", Column = 2})
cfgTab:CreateButton({
    Name = "Save", Flag = "save_profile",
    Callback = function()
        win:Save("default")
        log("saved")
    end,
})
cfgTab:CreateButton({
    Name = "Load", Flag = "load_profile",
    Callback = function()
        win:Load("default")
        log("loaded")
    end,
})
cfgTab:CreateButton({
    Name = "Delete", Flag = "delete_profile",
    Callback = function()
        win:DeleteConfig("default")
        log("deleted")
    end,
})

log("hub loaded")
return win
