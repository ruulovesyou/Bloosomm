--!nonstrict
local Blossom = require(script.Parent.Parent.Themes.Blossom)
local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager.new()
    return setmetatable({colors = table.clone(Blossom), listeners = {}}, ThemeManager)
end

function ThemeManager:Get(token)
    assert(self.colors[token], 'Unknown theme token: ' .. tostring(token))
    return self.colors[token]
end

function ThemeManager:Subscribe(scope, callback)
    self.listeners[callback] = true
    scope:Add(function() self.listeners[callback] = nil end)
    callback()
end

function ThemeManager:Bind(scope, instance, property, token)
    self:Subscribe(scope, function() instance[property] = self:Get(token) end)
end

function ThemeManager:Set(overrides)
    assert(type(overrides) == 'table', 'SetTheme expects a token table')
    for token, color in pairs(overrides) do
        assert(self.colors[token] and typeof(color) == 'Color3', 'Invalid theme token/color: ' .. tostring(token))
    end
    for token, color in pairs(overrides) do self.colors[token] = color end
    for callback in pairs(self.listeners) do callback() end
end

function ThemeManager:Destroy()
    table.clear(self.listeners)
end

return ThemeManager
