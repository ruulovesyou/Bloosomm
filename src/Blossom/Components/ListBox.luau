--!nonstrict
local Control = require(script.Parent.Control)
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Renderer = require(script.Parent.Parent.Core.Renderer)
local ListBox = {}

function ListBox.new(context, section, options)
    local choices = {}
    local function validateOptions(values)
        assert(type(values) == 'table', 'List options must be an array')
        local seen = {}
        for _, value in ipairs(values) do
            assert(type(value) == 'string' and value ~= '' and not seen[value], 'Invalid/duplicate list option')
            seen[value] = true
        end
        return table.clone(values)
    end
    choices = validateOptions(options.Options or {})
    local function normalize(value)
        assert(type(value) == 'string' and (value == '' or table.find(choices, value)), 'Unknown list selection')
        return value
    end
    local self = Control.new(context, section, options, 'ListBox', options.Default or '', normalize, 114)
    self.Label.Size = UDim2.new(1, 0, 0, 18)
    local r = context.Renderer
    local list = r:Create('ScrollingFrame', {Name = 'List', Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 92), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y}, self.Frame, {BackgroundColor3 = 'Input', ScrollBarImageColor3 = 'Accent'})
    r:Stroke(list, 'Inline'); r:Corner(list); r:Padding(list, 3); r:List(list, 1)
    local scope = Cleanup.new()
    context.Cleanup:Add(function() scope:Destroy() end)
    local function render()
        scope:Destroy()
        for _, child in ipairs(list:GetChildren()) do if child:IsA('GuiObject') then child:Destroy() end end
        scope = Cleanup.new()
        local rr = Renderer.new(context.Theme, scope, context.Renderer.ReducedMotion)
        if #choices == 0 then rr:Label(list, 'No items', {Size = UDim2.new(1, 0, 0, 22)}, 'InactiveText') end
        for index, value in ipairs(choices) do
            local button = rr:Create('TextButton', {Text = value, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = index, Interactable = not self.Disabled, Selectable = not self.Disabled}, list, {TextColor3 = value == self:GetValue() and 'Accent' or 'Text'})
            rr:Feedback(button, function() return self.Disabled end, function() return value == self:GetValue() and 'Tab' or 'Input' end)
            rr:Connect(button.Activated, function() if not self.Disabled then self:SetValue(value) end end)
        end
    end
    function self:SetOptions(values)
        choices = validateOptions(values)
        if self:GetValue() ~= '' and not table.find(choices, self:GetValue()) then self:SetValue('') else render() end
    end
    return self:Mount(render, options.OnChanged)
end

return ListBox
