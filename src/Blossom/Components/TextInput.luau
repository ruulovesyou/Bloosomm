--!nonstrict
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local TextInput = {}

function TextInput.new(context, section, options)
    assert(options.OnSubmitted == nil or type(options.OnSubmitted) == 'function', 'OnSubmitted must be a function')
    assert(options.Placeholder == nil or type(options.Placeholder) == 'string', 'Placeholder must be a string')
    local self = Control.new(context, section, options, 'TextInput', options.Default or '', Value.text(options.MaxLength or 200), 42)
    local r = context.Renderer
    self.Label.Size = UDim2.new(1, 0, 0, 18)
    local field = r:Create('TextBox', {
        Name = 'TextInput', Text = self:GetValue(), PlaceholderText = options.Placeholder or '',
        Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, Tokens.FieldHeight),
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        MultiLine = false, TextTruncate = Enum.TextTruncate.None,
    }, self.Frame, {BackgroundColor3 = 'Input', PlaceholderColor3 = 'InactiveText'})
    r:Corner(field)
    r:Create('UIPadding', {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, field)
    local stroke = r:Create('UIStroke', {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, field)
    self:Target(field)
    local focused = false
    local function paint()
        if not focused then field.Text = self:GetValue() end
        field.TextColor3 = context.Theme:Get(self.Disabled and 'InactiveText' or 'Text')
        stroke.Color = context.Theme:Get(focused and not self.Disabled and 'Accent' or 'Inline')
    end
    -- Draft text stays local until focus loss, avoiding partial IME commits.
    r:Connect(field.Focused, function() focused = true; paint() end)
    r:Connect(field.FocusLost, function(enterPressed)
        focused = false
        if not self.Disabled and not context.Destroyed then
            self:SetValue(field.Text)
            if context.Destroyed then return end
            field.Text = self:GetValue()
            if enterPressed then Control.Call(options.OnSubmitted, self:GetValue()) end
        end
        if not context.Destroyed then paint() end
    end)
    -- External SetValue wins over an in-flight draft.
    context.Cleanup:Add(context.Store:Subscribe(self.Id, function(value) field.Text = value end))
    return self:Mount(paint, options.OnChanged)
end

return TextInput
