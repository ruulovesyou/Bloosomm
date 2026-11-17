--!nonstrict
local Control = require(script.Parent.Control)
local Records = require(script.Parent.Parent.Core.Records)
local ColorPicker = {}

function ColorPicker.new(context, section, options)
    assert(options.OnPreview == nil or type(options.OnPreview) == 'function', 'OnPreview must be function')
    local self = Control.new(context, section, options, 'ColorPicker', options.Default or {R = 0.45, G = 0.66, B = 0.89, Alpha = 1, Animation = 'None'}, Records.Color, 22)
    self.Label.Size = UDim2.new(1, -32, 1, 0)
    local r = context.Renderer
    local chip = r:Create('TextButton', {Name = 'Color', Text = '', Position = UDim2.new(1, -26, 0, 3), Size = UDim2.fromOffset(26, 16)}, self.Frame)
    r:Corner(chip); r:Stroke(chip)
    self:Target(chip)
    local lastColor, lastAlpha
    function self:Preview(now)
        local value = self:GetValue()
        local color, alpha = Color3.new(value.R, value.G, value.B), value.Alpha
        if value.Animation == 'Rainbow' then color = Color3.fromHSV((now / 6) % 1, 0.75, 1)
        elseif value.Animation == 'Fade' then color = color:Lerp(Color3.new(), (math.sin(now * 2) + 1) * 0.35)
        elseif value.Animation == 'Fade Alpha' then alpha *= (math.sin(now * 2) + 1) / 2 end
        chip.BackgroundColor3 = color
        chip.BackgroundTransparency = 1 - alpha
        if color ~= lastColor or alpha ~= lastAlpha then
            lastColor, lastAlpha = color, alpha
            Control.Call(options.OnPreview, color, alpha)
        end
    end
    local function paint()
        local value = self:GetValue()
        chip.BackgroundColor3 = lastColor or Color3.new(value.R, value.G, value.B)
        chip.BackgroundTransparency = 1 - (lastAlpha or value.Alpha)
    end
    r:Connect(chip.Activated, function()
        if self.Disabled then return end
        if context.Overlay:IsOpen(self.Id) then context.Overlay:Close(); return end
        local popup, pr = context.Overlay:Open(self.Id, chip, 238, nil, {Width = 196, Freeform = true, ZIndex = 40})
        local value = self:GetValue()
        local hue, saturation, brightness = Color3.new(value.R, value.G, value.B):ToHSV()
        local alpha = value.Alpha
        local sv = pr:Create('TextButton', {Name = 'SaturationValue', Text = '', Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(148, 120), BackgroundColor3 = Color3.fromHSV(hue, 1, 1)}, popup)
        local white = pr:Create('Frame', {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1)}, sv)
        pr:Create('UIGradient', {Transparency = NumberSequence.new(0, 1)}, white)
        local black = pr:Create('Frame', {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new()}, sv)
        pr:Create('UIGradient', {Rotation = 90, Transparency = NumberSequence.new(1, 0)}, black)
        local cursor = pr:Create('Frame', {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 1, ZIndex = 43}, sv)
        pr:Corner(cursor, 6); pr:Stroke(cursor, 'Text')
        local hueBar = pr:Create('TextButton', {Name = 'Hue', Text = '', Position = UDim2.fromOffset(168, 10), Size = UDim2.fromOffset(16, 120), BackgroundColor3 = Color3.new(1, 1, 1)}, popup)
        local rainbow = {}
        for index = 0, 6 do table.insert(rainbow, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1))) end
        pr:Create('UIGradient', {Rotation = 90, Color = ColorSequence.new(rainbow)}, hueBar)
        local hueMarker = pr:Create('Frame', {Size = UDim2.new(1, 2, 0, 2), Position = UDim2.fromOffset(-1, 0), ZIndex = 43}, hueBar, {BackgroundColor3 = 'Text'})
        pr:Label(popup, 'Opacity', {Position = UDim2.fromOffset(10, 136), Size = UDim2.fromOffset(80, 18)}, 'InactiveText')
        local alphaBar = pr:Create('TextButton', {Name = 'Alpha', Text = '', Position = UDim2.fromOffset(10, 156), Size = UDim2.fromOffset(174, 10), BackgroundColor3 = Color3.new(1, 1, 1)}, popup)
        pr:Create('UIGradient', {Transparency = NumberSequence.new(1, 0)}, alphaBar)
        local alphaMarker = pr:Create('Frame', {Size = UDim2.fromOffset(2, 14), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 43}, alphaBar, {BackgroundColor3 = 'Text'})
        local number = pr:Label(popup, '', {Position = UDim2.fromOffset(92, 136), Size = UDim2.fromOffset(92, 18), TextXAlignment = Enum.TextXAlignment.Right}, 'InactiveText')
        pr:Label(popup, 'Animations', {Position = UDim2.fromOffset(10, 176), Size = UDim2.fromOffset(174, 18)}, 'InactiveText')
        local mode = pr:Create('TextButton', {Text = value.Animation, Position = UDim2.fromOffset(10, 198), Size = UDim2.fromOffset(174, 24)}, popup, {TextColor3 = 'Text'})
        pr:Corner(mode); pr:Feedback(mode)
        local function render()
            sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            cursor.Position = UDim2.fromScale(saturation, 1 - brightness)
            hueMarker.Position = UDim2.new(0, -1, hue, -1)
            alphaMarker.Position = UDim2.fromScale(alpha, 0.5)
            alphaBar.BackgroundColor3 = Color3.fromHSV(hue, saturation, brightness)
            number.Text = string.format('%d%%', math.floor(alpha * 100 + 0.5))
            mode.Text = self:GetValue().Animation
        end
        local function commit()
            local color = Color3.fromHSV(hue, saturation, brightness)
            self:SetValue({R = color.R, G = color.G, B = color.B, Alpha = alpha, Animation = self:GetValue().Animation})
            if not context.Destroyed and popup.Parent then render() end
        end
        for _, pair in ipairs({{sv, 'sv'}, {hueBar, 'hue'}, {alphaBar, 'alpha'}}) do
            pr:Connect(pair[1].InputBegan, function(input)
                context.Input:Begin(input, function(point)
                    local pos, size = pair[1].AbsolutePosition, pair[1].AbsoluteSize
                    local x = math.clamp((point.X - pos.X) / math.max(1, size.X), 0, 1)
                    local y = math.clamp((point.Y - pos.Y) / math.max(1, size.Y), 0, 1)
                    if pair[2] == 'sv' then saturation = x; brightness = 1 - y
                    elseif pair[2] == 'hue' then hue = y else alpha = x end
                    commit()
                end)
            end)
        end
        pr:Connect(mode.Activated, function()
            local modes = {'None', 'Rainbow', 'Fade', 'Fade Alpha'}
            local nextMode = modes[(table.find(modes, self:GetValue().Animation) % #modes) + 1]
            local nextValue = table.clone(self:GetValue()); nextValue.Animation = nextMode
            self:SetValue(nextValue)
            if popup.Parent then render() end
        end)
        pr.Scope:Add(context.Store:Subscribe(self.Id, function(newValue)
            hue, saturation, brightness = Color3.new(newValue.R, newValue.G, newValue.B):ToHSV()
            alpha = newValue.Alpha
            render()
        end))
        render()
    end)
    context.Animations.controls[self.Id] = self
    context.Cleanup:Add(context.Store:Subscribe(self.Id, function()
        self:Preview(os.clock()); if not context.Destroyed then context.Animations:Sync() end
    end))
    table.insert(self.refreshers, function() context.Animations:Sync() end)
    self:Mount(paint, options.OnChanged)
    self:Preview(os.clock())
    return self
end

return ColorPicker
