--!nonstrict
local Control = require(script.Parent.Control)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Button = {}

function Button.new(context, section, options)
    assert(options.OnClick == nil or type(options.OnClick) == 'function', 'OnClick must be a function')
    local self = Control.new(context, section, options, 'Button', nil, nil, Tokens.RowHeight)
    self.Label.Visible = false
    local r = context.Renderer
    local button = r:Create('TextButton', {
        Name = 'Button', Text = options.Label, Size = UDim2.new(1, 0, 0, Tokens.FieldHeight),
        Position = UDim2.fromOffset(0, 1),
    }, self.Frame)
    r:Corner(button)
    r:Stroke(button, 'Inline')
    self:Target(button)
    local refresh = r:Feedback(button, function() return self.Disabled end)
    r:Connect(button.Activated, function()
        if not self.Disabled then Control.Call(options.OnClick) end
    end)
    return self:Mount(function()
        button.TextColor3 = context.Theme:Get(self.Disabled and 'InactiveText' or 'Text')
        refresh()
    end)
end

return Button
