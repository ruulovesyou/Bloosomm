--!nonstrict
-- Appended to the standalone bundle. The local Blossom variable is supplied by the bundle.
local win = Blossom:CreateWindow({
    Name = 'Blossom',
    Theme = 'Blossom',
    Size = UDim2.fromOffset(422, 336),
    Scale = 1.5,
})

local function createSettingsTab()
local demoTab = win:CreateTab({Name = 'Settings', Flag = 'settings'})
local demoSection = demoTab:CreateSection({Name = 'UI Demo', Column = 1})
local demoName = demoTab:CreateInput({Name = 'Demo name', Flag = 'demo_name', Placeholder = 'Type a name', Default = '', Callback = function() end})
local demoStatus = demoTab:CreateInput({Name = 'Last action', Flag = 'demo_status', Default = 'Ready', Callback = function() end})
demoTab:CreateButton({Name = 'Test callback', Flag = 'test_callback', Callback = function()
    demoStatus:SetValue('Callback fired')
end})
demoTab:CreateButton({Name = 'Reset demo', Flag = 'reset_demo', Callback = function()
    demoName:SetValue('')
    demoStatus:SetValue('Ready')
end})

demoTab:CreateSection({Name = 'Profiles', Column = 1, Collapsible = true})
local profileName = demoTab:CreateInput({Name = 'Config name', Flag = 'profile_name', Placeholder = 'profile name', Default = '', Callback = function() end})
local profileStatus = demoTab:CreateInput({Name = 'Profile status', Flag = 'profile_status', Default = 'No profile selected', Callback = function() end})
local profilesList
local function refreshProfiles()
    if profilesList then profilesList:SetOptions(win:ListProfiles()) end
end
local function selectedProfile()
    local value = profileName:GetValue()
    if value == '' then
        profileStatus:SetValue('Enter a profile name')
        return nil
    end
    return value
end
demoTab:CreateButton({Name = 'Create', Flag = 'profile_create', Callback = function()
    local name = selectedProfile()
    if not name then return end
    local ok, problem = pcall(function() win:CreateProfile(name) end)
    profileStatus:SetValue(ok and ('Created ' .. name) or tostring(problem))
    if ok then refreshProfiles() end
end})
demoTab:CreateButton({Name = 'Load', Flag = 'profile_load', Callback = function()
    local name = selectedProfile()
    if not name then return end
    local ok, problem = pcall(function() win:LoadProfile(name) end)
    profileStatus:SetValue(ok and ('Loaded ' .. name) or tostring(problem))
end})
demoTab:CreateButton({Name = 'Overwrite', Flag = 'profile_overwrite', Callback = function()
    local name = selectedProfile()
    if not name then return end
    local ok, problem = pcall(function() win:OverwriteProfile(name) end)
    profileStatus:SetValue(ok and ('Overwritten ' .. name) or tostring(problem))
    if ok then refreshProfiles() end
end})
demoTab:CreateButton({Name = 'Delete', Flag = 'profile_delete', Callback = function()
    local name = selectedProfile()
    if not name then return end
    local ok, problem = pcall(function() win:DeleteProfile(name) end)
    profileStatus:SetValue(ok and ('Deleted ' .. name) or tostring(problem))
    if ok then refreshProfiles() end
end})

demoTab:CreateSection({Name = 'Menu', Column = 2})
demoTab:CreateDropdown({Name = 'UI scale', Flag = 'ui_scale', Options = {'100%', '125%', '150%'}, Value = '150%', Callback = function(value)
    win:SetScale((tonumber(value:sub(1, -2)) or 150) / 100)
end})
demoTab:CreateDropdown({Name = 'Theme', Flag = 'theme', Options = win:GetThemePresets(), Value = 'Blossom', Callback = function(value)
    win:ChangeTheme(value)
end})
demoTab:CreateToggle({Name = 'Disable input', Flag = 'disable_input', Default = false, Callback = function(value)
    demoName:SetDisabled(value)
end})
demoTab:CreateKeybind({Name = 'Menu Keybind', Flag = 'menu_keybind', Value = Enum.KeyCode.RightShift, Callback = function(active)
    win:SetVisible(active)
end})
demoTab:CreateColorPicker({Name = 'Accent color', Flag = 'accent_color', Color = Color3.fromRGB(116, 169, 227), Callback = function(value)
    if typeof(value) == 'Color3' then win:SetTheme({Accent = value}) end
end})
profilesList = demoTab:CreateList({Name = 'Saved configs', Flag = 'saved_configs', Options = {}, Value = ''})

end

local combat = win:CreateTab({Name = 'Combat', Flag = 'combat', Group = 'Combat'})
combat:CreateSection({Name = 'Rage', Description = 'Targeting controls', Column = 1})
combat:CreateToggle({Name = 'Enabled', Flag = 'rage_enabled', Default = false, Callback = function() end})
combat:CreateSlider({Name = 'Hitchance', Flag = 'hitchance', Range = {0, 100}, Increment = 1, Default = 85, Suffix = '%', Callback = function() end})
combat:CreateDropdown({Name = 'Target selection', Flag = 'target_selection', Options = {'Closest to Crosshair', 'Closest Distance', 'Lowest Health'}, Value = 'Closest to Crosshair', Callback = function() end})
local legit = win:CreateTab({Name = 'Legit', Flag = 'legit', Group = 'Combat'})
legit:CreateSection({Name = 'Aim Assist', Column = 1})
legit:CreateToggle({Name = 'Enabled', Flag = 'assist_enabled', Default = false, Callback = function() end})

local visuals = win:CreateTab({Name = 'Players', Flag = 'players', Group = 'Visuals'})
visuals:CreateSection({Name = 'Players', Column = 1})
visuals:CreateToggle({Name = 'Player ESP', Flag = 'player_esp', Default = false, Callback = function() end})
visuals:CreateColorPicker({Name = 'ESP color', Flag = 'esp_color', Color = Color3.fromRGB(116, 169, 227), Callback = function() end})
win:CreateTab({Name = 'Effects', Flag = 'effects', Group = 'Visuals'})

local movement = win:CreateTab({Name = 'Movement', Flag = 'movement', Group = 'Player'})
movement:CreateSection({Name = 'Movement', Column = 1})
movement:CreateToggle({Name = 'Speed', Flag = 'speed', Default = false, Callback = function() end})
movement:CreateSlider({Name = 'Speed amount', Flag = 'speed_amount', Range = {0, 100}, Increment = 1, Default = 16, Callback = function() end})
win:CreateTab({Name = 'Exploits', Flag = 'exploits', Group = 'Player'})

createSettingsTab()
win:Navigate('settings')
return win
