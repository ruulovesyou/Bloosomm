--!nonstrict
local TweenService = game:GetService('TweenService')
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(theme, cleanup, reducedMotion)
    local self = setmetatable({Theme = theme, Scope = cleanup, ReducedMotion = reducedMotion, tweens = {}}, Renderer)
    cleanup:Add(function() self:CancelTweens() end)
    return self
end

function Renderer:Connect(signal, callback)
    local connection = signal:Connect(callback)
    self.Scope:Add(function() connection:Disconnect() end)
    return connection
end

function Renderer:Create(className, properties, parent, colors)
    local instance = Instance.new(className)
    if instance:IsA('GuiObject') then
        instance.BorderSizePixel = 0
        instance.ZIndex = parent and parent:IsA('GuiObject') and parent.ZIndex or 10
    end
    if instance:IsA('TextLabel') or instance:IsA('TextButton') or instance:IsA('TextBox') then
        instance.Font = Enum.Font.Gotham
        instance.TextSize = Tokens.TextSize
        instance.TextTruncate = Enum.TextTruncate.AtEnd
    end
    if instance:IsA('GuiButton') then instance.AutoButtonColor = false end
    for property, value in pairs(properties) do instance[property] = value end
    for property, token in pairs(colors or {}) do self.Theme:Bind(self.Scope, instance, property, token) end
    instance.Parent = parent
    return instance
end

function Renderer:Corner(parent, radius)
    return self:Create('UICorner', {CornerRadius = UDim.new(0, radius or Tokens.ControlRadius)}, parent)
end

function Renderer:Stroke(parent, token)
    return self:Create('UIStroke', {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, parent, {Color = token or 'Outline'})
end

function Renderer:Label(parent, text, properties, token)
    local props = {
        Name = 'Label', Text = text, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, Tokens.RowHeight), TextXAlignment = Enum.TextXAlignment.Left,
    }
    for key, value in pairs(properties or {}) do props[key] = value end
    return self:Create('TextLabel', props, parent, {TextColor3 = token or 'Text'})
end

function Renderer:List(parent, gap)
    return self:Create('UIListLayout', {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, gap or Tokens.ControlGap),
    }, parent)
end

function Renderer:Padding(parent, padding)
    return self:Create('UIPadding', {
        PaddingLeft = UDim.new(0, padding), PaddingRight = UDim.new(0, padding),
        PaddingTop = UDim.new(0, padding), PaddingBottom = UDim.new(0, padding),
    }, parent)
end

function Renderer:CancelTweens()
    for instance, active in pairs(self.tweens) do
        active.connection:Disconnect()
        active.tween:Cancel()
        self.tweens[instance] = nil
    end
end

function Renderer:Tween(instance, properties, duration)
    local previous = self.tweens[instance]
    if previous then
        previous.connection:Disconnect()
        previous.tween:Cancel()
        self.tweens[instance] = nil
    end
    if self.ReducedMotion or duration == 0 then
        for property, value in pairs(properties) do instance[property] = value end
        return
    end
    local tween = TweenService:Create(instance, TweenInfo.new(duration or Tokens.HoverTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    local active = {tween = tween}
    active.connection = tween.Completed:Connect(function()
        if self.tweens[instance] == active then self.tweens[instance] = nil end
        active.connection:Disconnect()
    end)
    self.tweens[instance] = active
    tween:Play()
end

-- State resolution is shared by buttons, fields and navigation, without owning values.
function Renderer:Feedback(button, isDisabled, baseToken)
    local hovered, selected, pressed = false, false, false
    local function paint()
        local disabled = isDisabled and isDisabled()
        local token = baseToken and baseToken() or 'Input'
        if not disabled and (hovered or selected or pressed) then
            token = pressed and 'Element' or 'HoveredElement'
        end
        self:Tween(button, {BackgroundColor3 = self.Theme:Get(token)})
    end
    self:Connect(button.MouseEnter, function() hovered = true; paint() end)
    self:Connect(button.MouseLeave, function() hovered = false; pressed = false; paint() end)
    self:Connect(button.SelectionGained, function() selected = true; paint() end)
    self:Connect(button.SelectionLost, function() selected = false; paint() end)
    self:Connect(button.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then pressed = true; paint() end
    end)
    self:Connect(button.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then pressed = false; paint() end
    end)
    self.Theme:Subscribe(self.Scope, paint)
    return paint
end

return Renderer
