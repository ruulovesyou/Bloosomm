--!nonstrict
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local RangeSlider = {}

function RangeSlider.new(context, section, options)
    local minimum = options.Minimum or 0
    local maximum = options.Maximum or 100
    local step = options.Step or 1
    local normalize = function(value)
        assert(type(value) == 'table' and #value == 2, 'Range slider requires two values')
        local snap = Value.slider(minimum, maximum, step)
        local left, right = snap(value[1]), snap(value[2])
        if left > right then left, right = right, left end
        return {left, right}
    end
    local self = Control.new(context, section, options, 'RangeSlider', options.Default or {minimum, maximum}, normalize, Tokens.SliderHeight)
    local r = context.Renderer
    self.Label.Size = UDim2.new(1, -74, 0, 18)
    local values = r:Label(self.Frame, '', {Position = UDim2.new(1, -72, 0, 0), Size = UDim2.fromOffset(72, 18), TextXAlignment = Enum.TextXAlignment.Right, TextSize = Tokens.SmallText}, 'InactiveText')
    local hit = r:Create('TextButton', {Name = 'RangeSlider', Text = '', BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 17), Size = UDim2.new(1, 0, 0, 13)}, self.Frame)
    local track = r:Create('Frame', {Position = UDim2.new(0, 3, 0.5, -2), Size = UDim2.new(1, -6, 0, 4)}, hit, {BackgroundColor3 = 'Element'})
    r:Corner(track, 4)
    local fill = r:Create('Frame', {Name = 'Fill'}, track, {BackgroundColor3 = 'Accent'})
    r:Corner(fill, 4)
    local thumbs = {}
    for index = 1, 2 do
        local thumb = r:Create('Frame', {Name = 'Thumb' .. index, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6)}, track, {BackgroundColor3 = 'Accent'})
        r:Corner(thumb, 6)
        thumbs[index] = thumb
    end
    self:Target(hit)
    local function paint()
        local value = self:GetValue()
        local a = (value[1] - minimum) / (maximum - minimum)
        local b = (value[2] - minimum) / (maximum - minimum)
        fill.Position = UDim2.fromScale(a, 0)
        fill.Size = UDim2.fromScale(b - a, 1)
        thumbs[1].Position = UDim2.fromScale(a, 0.5)
        thumbs[2].Position = UDim2.fromScale(b, 0.5)
        values.Text = tostring(value[1]) .. (options.Unit or '') .. '  ' .. tostring(value[2]) .. (options.Unit or '')
    end
    r:Connect(hit.InputBegan, function(input)
        if self.Disabled then return end
        context.Input:Begin(input, function(point)
            local alpha = math.clamp((point.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            local current = self:GetValue()
            local target = minimum + alpha * (maximum - minimum)
            local index = math.abs(target - current[1]) <= math.abs(target - current[2]) and 1 or 2
            current[index] = target
            self:SetValue(current)
        end)
    end)
    return self:Mount(paint, options.OnChanged)
end

return RangeSlider
