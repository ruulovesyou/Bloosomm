--!nonstrict
local GuiService = game:GetService('GuiService')
local UserInputService = game:GetService('UserInputService')
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Slider = {}

function Slider.new(context, section, options)
    local minimum, maximum, step = options.Minimum or 0, options.Maximum or 100, options.Step or 1
    local normalize = Value.slider(minimum, maximum, step)
    assert(options.Unit == nil or type(options.Unit) == 'string', 'Unit must be a string')
    local self = Control.new(context, section, options, 'Slider', options.Default or minimum, normalize, Tokens.SliderHeight)
    local r = context.Renderer
    self.Label.Size = UDim2.new(1, -42, 0, 18)
    local valueLabel = r:Label(self.Frame, '', {Position = UDim2.new(1, -44, 0, 0), Size = UDim2.fromOffset(44, 18), TextXAlignment = Enum.TextXAlignment.Right, TextSize = Tokens.SmallText}, 'InactiveText')
    local hit = r:Create('TextButton', {Name = 'Slider', Text = '', BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 17), Size = UDim2.new(1, 0, 0, 17)}, self.Frame)
    local track = r:Create('Frame', {Name = 'Track', Position = UDim2.new(0, 3, 0.5, -2), Size = UDim2.new(1, -6, 0, 4)}, hit, {BackgroundColor3 = 'Element'})
    r:Corner(track, 4)
    local fill = r:Create('Frame', {Name = 'Fill', Size = UDim2.fromScale(0, 1)}, track)
    r:Corner(fill, 4)
    local thumb = r:Create('Frame', {Name = 'Thumb', AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(6, 6)}, track)
    r:Corner(thumb, 6)
    self:Target(hit)
    local function paint()
        local value = self:GetValue()
        local alpha = (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.fromScale(alpha, 1)
        thumb.Position = UDim2.fromScale(alpha, 0.5)
        fill.BackgroundColor3 = context.Theme:Get(self.Disabled and 'InactiveText' or 'Accent')
        thumb.BackgroundColor3 = context.Theme:Get(self.Disabled and 'InactiveText' or 'Accent')
        valueLabel.Text = string.format('%.6f', value):gsub('0+$', ''):gsub('%.$', '') .. (options.Unit or '')
    end
    r:Connect(hit.InputBegan, function(input)
        if self.Disabled then return end
        local column = section.Frame.Parent
        local wasScrolling = column.ScrollingEnabled
        local began = context.Input:Begin(input, function(point)
            local alpha = math.clamp((point.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            self:SetValue(minimum + alpha * (maximum - minimum))
        end, function()
            column.ScrollingEnabled = wasScrolling
        end)
        if began and not context.Destroyed then column.ScrollingEnabled = false end
    end)
    -- Native GUI selection supplies focus; arrows/D-pad adjust a selected slider.
    r:Connect(UserInputService.InputBegan, function(input, processed)
        if processed or self.Disabled or GuiService.SelectedObject ~= hit or not self.Frame:IsDescendantOf(context.Root) or not context.Root.Visible then return end
        if not section.Page.Frame.Visible or context.Overlay.current then return end
        local key = input.KeyCode
        if key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft then self:SetValue(self:GetValue() - step) end
        if key == Enum.KeyCode.Right or key == Enum.KeyCode.DPadRight then self:SetValue(self:GetValue() + step) end
    end)
    r:Connect(hit.SelectionGained, function() thumb.Size = UDim2.fromOffset(8, 8) end)
    r:Connect(hit.SelectionLost, function() thumb.Size = UDim2.fromOffset(6, 6) end)
    return self:Mount(paint, options.OnChanged)
end

return Slider
