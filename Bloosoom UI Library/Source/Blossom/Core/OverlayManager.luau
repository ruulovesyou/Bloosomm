--!nonstrict
local UserInputService = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')
local Cleanup = require(script.Parent.Cleanup)
local Renderer = require(script.Parent.Renderer)
local OverlayManager = {}
OverlayManager.__index = OverlayManager

local function contains(object, point)
    local position, size = object.AbsolutePosition, object.AbsoluteSize
    return point.X >= position.X and point.Y >= position.Y and point.X <= position.X + size.X and point.Y <= position.Y + size.Y
end

function OverlayManager.new(context, layer)
    local self = setmetatable({context = context, layer = layer, current = nil}, OverlayManager)
    context.Renderer:Connect(UserInputService.InputBegan, function(input)
        local current = self.current
        if not current then return end
        if input.KeyCode == Enum.KeyCode.Escape then self:Close(); return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local point = Vector2.new(input.Position.X, input.Position.Y)
            if not contains(current.frame, point) and not contains(current.anchor, point) then self:Close() end
        end
    end)
    context.Cleanup:Add(function() self:Close() end)
    return self
end

function OverlayManager:Close()
    local current = self.current
    if not current then return end
    self.current = nil
    self.context.Input:Cancel()
    local selected = GuiService.SelectedObject
    if selected and selected:IsDescendantOf(current.frame) then GuiService.SelectedObject = nil end
    current.scope:Destroy()
    current.frame:Destroy()
    if current.closed then current.closed() end
end

function OverlayManager:Open(owner, anchor, requestedHeight, closed, settings)
    self:Close()
    settings = settings or {}
    local context = self.context
    local scope = Cleanup.new()
    local renderer = Renderer.new(context.Theme, scope, context.Renderer.ReducedMotion)
    local scale = context.Scale.Scale
    local viewport = context.Viewport
    local edge = 4 * scale
    local height = math.min(requestedHeight * scale, math.max(1, viewport.AbsoluteSize.Y - edge * 2))
    local width = math.min(settings.Width and settings.Width * scale or anchor.AbsoluteSize.X, math.max(1, viewport.AbsoluteSize.X - edge * 2))
    local minX, minY = viewport.AbsolutePosition.X + edge, viewport.AbsolutePosition.Y + edge
    local maxX = math.max(minX, viewport.AbsolutePosition.X + viewport.AbsoluteSize.X - width - edge)
    local maxY = math.max(minY, viewport.AbsolutePosition.Y + viewport.AbsoluteSize.Y - height - edge)
    local x = math.clamp(anchor.AbsolutePosition.X, minX, maxX)
    local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + edge
    if y > maxY then y = anchor.AbsolutePosition.Y - height - edge end
    y = math.clamp(y, minY, maxY)
    local origin = self.layer.AbsolutePosition
    local properties = {
        Name = 'DropdownPopup', Position = UDim2.fromOffset((x - origin.X) / scale, (y - origin.Y) / scale),
        Size = UDim2.fromOffset(width / scale, height / scale), ZIndex = settings.ZIndex or 30,
        Active = true, ClipsDescendants = true,
    }
    if not settings.Freeform then
        properties.CanvasSize = UDim2.new()
        properties.AutomaticCanvasSize = Enum.AutomaticSize.Y
        properties.ScrollBarThickness = 2
        properties.ScrollingDirection = Enum.ScrollingDirection.Y
    end
    local frame = renderer:Create(settings.Freeform and 'Frame' or 'ScrollingFrame', properties, self.layer, {BackgroundColor3 = 'Background'})
    if not settings.Freeform then renderer.Theme:Bind(scope, frame, 'ScrollBarImageColor3', 'Accent') end
    renderer:Corner(frame, 4)
    renderer:Stroke(frame)
    if not settings.Freeform then renderer:Padding(frame, 3); renderer:List(frame, 1) end
    self.current = {owner = owner, anchor = anchor, frame = frame, scope = scope, closed = closed}
    renderer:Connect(anchor:GetPropertyChangedSignal('AbsolutePosition'), function() self:Close() end)
    renderer:Connect(anchor:GetPropertyChangedSignal('AbsoluteSize'), function() self:Close() end)
    return frame, renderer
end

function OverlayManager:IsOpen(owner)
    return self.current ~= nil and self.current.owner == owner
end

return OverlayManager
