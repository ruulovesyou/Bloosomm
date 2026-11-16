--!nonstrict
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Dropdown = {}

function Dropdown.new(context, section, options)
    local normalize = Value.dropdown(options.Options)
    local choices = table.clone(options.Options)
    local self = Control.new(context, section, options, 'Dropdown', options.Default or choices[1], normalize, 42)
    local r = context.Renderer
    self.Label.Size = UDim2.new(1, 0, 0, 18)
    local field = r:Create('TextButton', {Name = 'Dropdown', Text = '', Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, Tokens.FieldHeight)}, self.Frame)
    r:Corner(field)
    r:Stroke(field, 'Inline')
    local selected = r:Create('TextLabel', {
        Name = 'Selected', Text = '', BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -23, 1, 0),
    }, field)
    local arrow = r:Create('Frame', {Name = 'Chevron', BackgroundTransparency = 1, Position = UDim2.new(1, -13, 0.5, -3), Size = UDim2.fromOffset(8, 6)}, field)
    for index, rotation in ipairs({45, -45}) do
        r:Create('Frame', {Name = 'Line' .. index, Rotation = rotation, Position = UDim2.fromOffset((index - 1) * 3, 2), Size = UDim2.fromOffset(5, 1)}, arrow, {BackgroundColor3 = 'InactiveText'})
    end
    self:Target(field)
    local refresh = r:Feedback(field, function() return self.Disabled end)
    local function paint()
        selected.Text = self:GetValue()
        selected.TextColor3 = context.Theme:Get(self.Disabled and 'InactiveText' or 'Text')
        refresh()
    end
    r:Connect(field.Activated, function()
        if self.Disabled then return end
        if context.Overlay:IsOpen(self.Id) then context.Overlay:Close(); return end
        local popup, pr = context.Overlay:Open(self.Id, field, math.min(Tokens.PopupMaxHeight, #choices * (Tokens.PopupRow + 1) + 6), function() arrow.Rotation = 0 end)
        arrow.Rotation = 180
        for index, choice in ipairs(choices) do
            local item = pr:Create('TextButton', {
                Name = 'Option' .. index, Text = '', Size = UDim2.new(1, -2, 0, Tokens.PopupRow), LayoutOrder = index, ZIndex = 31,
            }, popup)
            pr:Corner(item)
            pr:Label(item, choice, {Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -12, 1, 0), ZIndex = 32}, choice == self:GetValue() and 'Accent' or 'Text')
            pr:Feedback(item, nil, function() return choice == self:GetValue() and 'Tab' or 'Background' end)
            pr:Connect(item.Activated, function()
                context.Overlay:Close()
                self:SetValue(choice)
            end)
        end
    end)
    context.Cleanup:Add(context.Store:Subscribe(self.Id, function()
        if context.Overlay:IsOpen(self.Id) then context.Overlay:Close() end
    end))
    return self:Mount(paint, options.OnChanged)
end

return Dropdown
