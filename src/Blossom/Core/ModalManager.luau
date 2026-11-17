--!nonstrict
local UserInputService = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')
local Cleanup = require(script.Parent.Cleanup)
local Renderer = require(script.Parent.Renderer)
local ModalManager = {}
ModalManager.__index = ModalManager

function ModalManager.new(context)
    local self = setmetatable({context = context}, ModalManager)
    context.Renderer:Connect(UserInputService.InputBegan, function(input)
        if self.current and input.KeyCode == Enum.KeyCode.Escape then self:Close() end
    end)
    context.Cleanup:Add(function() self:Close() end)
    return self
end

function ModalManager:Close()
    local current = self.current
    if not current then return end
    self.current = nil
    local focused = UserInputService:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(current.backdrop) then focused:ReleaseFocus(false) end
    current.scope:Destroy()
    current.backdrop:Destroy()
    for object, selectable in pairs(current.selectable) do
        if object.Parent then object.Selectable = selectable end
    end
    if not self.context.Destroyed then
        for _, control in pairs(self.context.Registry) do control:Refresh() end
    end
    GuiService.SelectedObject = nil
end

function ModalManager:Open(title, width, height)
    self:Close()
    local context = self.context
    context.Overlay:Close()
    context.Input:Cancel()
    context.Library:_ReleaseFocus()
    local scope = Cleanup.new()
    local r = Renderer.new(context.Theme, scope, context.Renderer.ReducedMotion)
    local selectable = {}
    for _, object in ipairs(context.Root:GetDescendants()) do
        if object:IsA('GuiObject') then selectable[object] = object.Selectable; object.Selectable = false end
    end
    local backdrop = r:Create('TextButton', {Name = 'ModalBackdrop', Text = '', Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.4, ZIndex = 80, Selectable = false, Modal = true}, context.Viewport, {BackgroundColor3 = 'Shadow'})
    local panel = r:Create('TextButton', {Name = 'Modal', Text = '', Size = UDim2.fromOffset(width, height), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 81, Selectable = false, Active = true}, backdrop, {BackgroundColor3 = 'Background'})
    local scale = math.min(context.Scale.Scale, math.max(0.1, (context.Viewport.AbsoluteSize.X - 16) / width), math.max(0.1, (context.Viewport.AbsoluteSize.Y - 16) / height))
    r:Create('UIScale', {Scale = scale}, panel)
    r:Corner(panel, 6)
    r:Stroke(panel)
    r:Label(panel, title, {Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -48, 0, 26), TextSize = 13, Font = Enum.Font.GothamMedium})
    local close = r:Create('TextButton', {Name = 'Close', Text = '×', Position = UDim2.new(1, -30, 0, 6), Size = UDim2.fromOffset(24, 24), ZIndex = 82}, panel, {TextColor3 = 'Text'})
    r:Corner(close)
    r:Feedback(close)
    r:Connect(close.Activated, function() self:Close() end)
    r:Connect(backdrop.Activated, function() self:Close() end)
    self.current = {scope = scope, backdrop = backdrop, panel = panel, selectable = selectable}
    return panel, r
end

function ModalManager:Confirm(title, message, action)
    local panel, r = self:Open(title, 300, 128)
    r:Label(panel, message, {Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 46), TextWrapped = true, TextTruncate = Enum.TextTruncate.None})
    for index, label in ipairs({'Cancel', 'Confirm'}) do
        local button = r:Create('TextButton', {Text = label, Position = UDim2.fromOffset(12 + (index - 1) * 144, 92), Size = UDim2.fromOffset(132, 24)}, panel, {TextColor3 = 'Text'})
        r:Corner(button); r:Feedback(button)
        r:Connect(button.Activated, function() self:Close(); if index == 2 then action() end end)
    end
end

return ModalManager
