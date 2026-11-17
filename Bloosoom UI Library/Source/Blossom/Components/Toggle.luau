--!nonstrict
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Toggle = {}

function Toggle.new(context, section, options)
    local default = if options.Default == nil then false else options.Default
    local self = Control.new(context, section, options, 'Toggle', default, Value.boolean, Tokens.RowHeight)
    local r = context.Renderer
    self.Label.Size = UDim2.new(1, -30, 1, 0)
    local hit = r:Create('TextButton', {Name = 'Toggle', Text = '', BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, self.Frame)
    local pill = r:Create('Frame', {Name = 'Pill', AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(22, 12)}, hit)
    r:Corner(pill, 12)
    local knob = r:Create('Frame', {Name = 'Knob', AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(8, 8)}, pill)
    r:Corner(knob, 8)
    self:Target(hit)
    local hovered = false
    local function paint()
        local value = self:GetValue()
        local token = value and 'Accent' or (hovered and 'HoveredElement' or 'Element')
        if self.Disabled then token = 'Element' end
        r:Tween(pill, {BackgroundColor3 = context.Theme:Get(token)}, Tokens.ToggleTime)
        r:Tween(knob, {Position = UDim2.new(0, value and 12 or 2, 0.5, 0), BackgroundColor3 = context.Theme:Get(self.Disabled and 'InactiveText' or 'Text')}, Tokens.ToggleTime)
    end
    r:Connect(hit.MouseEnter, function() hovered = true; paint() end)
    r:Connect(hit.MouseLeave, function() hovered = false; paint() end)
    r:Connect(hit.SelectionGained, function() hovered = true; paint() end)
    r:Connect(hit.SelectionLost, function() hovered = false; paint() end)
    r:Connect(hit.Activated, function() if not self.Disabled then self:SetValue(not self:GetValue()) end end)
    return self:Mount(paint, options.OnChanged)
end

return Toggle
