-- Blossom UI Library - single-file bundle (generated)
-- Recreates the script.Core / script.Components / script.Themes tree so the
-- original require(script.Parent...) paths work under loadstring.

local function __node(name, parent)
    local node = {Name = name, Parent = parent, _children = {}}
    return setmetatable(node, {__index = function(_, key) return node._children[key] end})
end

local __root = __node("Blossom", nil)

local function __register(folder, name, factory)
    local parent = __root
    if folder then
        parent = __root._children[folder]
        if not parent then
            parent = __node(folder, __root)
            __root._children[folder] = parent
        end
    end
    local leaf = __node(name, parent)
    leaf._factory = factory
    parent._children[name] = leaf
end

local function __require(node)
    if type(node) ~= "table" or not node._factory then
        error("Blossom bundle: require target is not a module", 2)
    end
    if not node._loaded then
        node._result = node._factory(node, __require)
        node._loaded = true
    end
    return node._result
end

__register("Core", "Cleanup", function(script, require)
--!strict
local Cleanup = {}
Cleanup.__index = Cleanup

function Cleanup.new()
    return setmetatable({tasks = {} :: {() -> ()}, destroyed = false}, Cleanup)
end

function Cleanup:Add(dispose: () -> ())
    if self.destroyed then
        dispose()
    else
        table.insert(self.tasks, dispose)
    end
    return dispose
end

function Cleanup:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    for index = #self.tasks, 1, -1 do
        local ok, problem = pcall(self.tasks[index])
        if not ok then print('[Blossom cleanup] ' .. tostring(problem)) end
    end
    table.clear(self.tasks)
end

return Cleanup

end)

__register("Core", "ColorAnimator", function(script, require)
--!nonstrict
local RunService = game:GetService('RunService')
local ColorAnimator = {}
ColorAnimator.__index = ColorAnimator

function ColorAnimator.new(context)
    local self = setmetatable({context = context, controls = {}, connection = nil, elapsed = 0}, ColorAnimator)
    context.Cleanup:Add(function() if self.connection then self.connection:Disconnect(); self.connection = nil end; table.clear(self.controls) end)
    return self
end

function ColorAnimator:Sync()
    local needed = false
    for _, control in pairs(self.controls) do
        if not control.Disabled and control:GetValue().Animation ~= 'None' then needed = true; break end
    end
    needed = needed and self.context.Root.Visible
    if not needed and self.connection then self.connection:Disconnect(); self.connection = nil end
    if not needed or self.connection then return end
    self.connection = RunService.Heartbeat:Connect(function(delta)
        self.elapsed += delta
        if self.elapsed < 1 / 30 then return end
        self.elapsed = 0
        local now = os.clock()
        for _, control in pairs(self.controls) do
            if self.context.Destroyed then break end
            if not control.Disabled then control:Preview(now) end
        end
    end)
end

return ColorAnimator

end)

__register("Core", "InputManager", function(script, require)
--!nonstrict
local UserInputService = game:GetService('UserInputService')
local InputManager = {}
InputManager.__index = InputManager

function InputManager.new(renderer)
    local self = setmetatable({active = nil}, InputManager)
    renderer:Connect(UserInputService.InputChanged, function(input)
        local active = self.active
        if active and (input == active.input or (active.mouse and input.UserInputType == Enum.UserInputType.MouseMovement)) then
            active.move(Vector2.new(input.Position.X, input.Position.Y))
        end
    end)
    renderer:Connect(UserInputService.InputEnded, function(input)
        local active = self.active
        if active and (input == active.input or (active.mouse and input.UserInputType == Enum.UserInputType.MouseButton1)) then self:Cancel() end
    end)
    renderer:Connect(UserInputService.WindowFocusReleased, function() self:Cancel() end)
    renderer.Scope:Add(function() self:Cancel() end)
    return self
end

function InputManager:Begin(input, move, finish)
    local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
    if not mouse and input.UserInputType ~= Enum.UserInputType.Touch then return false end
    if self.active then return false end
    local active = {input = input, mouse = mouse, move = move, finish = finish}
    self.active = active
    move(Vector2.new(input.Position.X, input.Position.Y))
    return self.active == active
end

function InputManager:Cancel()
    local active = self.active
    self.active = nil
    if active and active.finish then active.finish() end
end

return InputManager

end)

__register("Core", "KeybindManager", function(script, require)
--!nonstrict
local UserInputService = game:GetService('UserInputService')
local KeybindManager = {}
KeybindManager.__index = KeybindManager

function KeybindManager.new(context)
    local self = setmetatable({context = context, bindings = {}, capture = nil}, KeybindManager)
    context.Renderer:Connect(UserInputService.InputBegan, function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local key = input.KeyCode.Name
        if self.capture then
            local control = self.capture
            self.capture = nil
            if key ~= 'Escape' and key ~= 'Unknown' then
                control:SetValue({Key = key == 'Backspace' and 'None' or key, Mode = control:GetValue().Mode})
            end
            control:Refresh()
            return
        end
        if processed or UserInputService:GetFocusedTextBox() or context.Modal.current or context.Overlay.current then return end
        for _, control in pairs(self.bindings) do
            local value = control:GetValue()
            if not control.Disabled and value.Key == key and (context.Root.Visible or control.Global) then
                control:SetActive(value.Mode == 'hold' or not control.Active)
            end
        end
    end)
    context.Renderer:Connect(UserInputService.InputEnded, function(input)
        for _, control in pairs(self.bindings) do
            local value = control:GetValue()
            if value.Mode == 'hold' and value.Key == input.KeyCode.Name then control:SetActive(false) end
        end
    end)
    context.Renderer:Connect(UserInputService.WindowFocusReleased, function() self:Release() end)
    context.Cleanup:Add(function() self.capture = nil; table.clear(self.bindings) end)
    return self
end

function KeybindManager:Release()
    local captured = self.capture
    self.capture = nil
    if captured and not self.context.Destroyed then captured:Refresh() end
    for _, control in pairs(self.bindings) do
        if not control.Global then control:SetActive(false) end
    end
end

function KeybindManager:Capture(control)
    self.context.Overlay:Close()
    self.capture = control
    control:Refresh()
end

return KeybindManager

end)

__register("Core", "LayoutManager", function(script, require)
--!nonstrict
local LayoutManager = {}
LayoutManager.__index = LayoutManager
local function inside(frame, point)
    local p, s = frame.AbsolutePosition, frame.AbsoluteSize
    return point.X >= p.X and point.Y >= p.Y and point.X <= p.X + s.X and point.Y <= p.Y + s.Y
end
local function layer(frame, z)
    frame.ZIndex = z
    for _, object in ipairs(frame:GetDescendants()) do if object:IsA('GuiObject') then object.ZIndex = z end end
end

function LayoutManager.new(context)
    return setmetatable({context = context, drag = nil}, LayoutManager)
end

function LayoutManager:Ordered(page, column, except)
    local result = {}
    for _, section in pairs(page.Sections) do
        if section ~= except and not section.Detached and section.Column == column then table.insert(result, section) end
    end
    table.sort(result, function(a, b) if a.Order == b.Order then return a.Id < b.Id end; return a.Order < b.Order end)
    return result
end

function LayoutManager:Move(section, column, index)
    assert(column == 1 or column == 2, 'Column must be 1 or 2')
    local ordered = self:Ordered(section.Page, column, section)
    index = math.clamp(math.floor(index or #ordered + 1), 1, #ordered + 1)
    table.insert(ordered, index, section)
    section.Detached = false
    section.Page.Floating.Visible = section.Page.Frame.Visible
    section.Column = column
    section.Frame.Parent = section.Page.Columns[column]
    section.Frame.Size = UDim2.new(1, 0, 0, 0)
    section.Frame.Position = UDim2.new()
    layer(section.Frame, 10)
    for order, item in ipairs(ordered) do item.Order = order; item.Frame.LayoutOrder = order end
end

function LayoutManager:Detach(section, x, y, width)
    local context = self.context
    local scale = context.Scale.Scale
    local origin = section.Page.Floating.AbsolutePosition
    local viewport = context.Viewport
    local minX = (viewport.AbsolutePosition.X - origin.X) / scale
    local minY = (viewport.AbsolutePosition.Y - origin.Y) / scale
    local maxX = math.max(minX, minX + viewport.AbsoluteSize.X / scale - width)
    local maxY = math.max(minY, minY + viewport.AbsoluteSize.Y / scale - 24)
    section.Detached = true
    section.Page.Floating.Visible = section.Page.Frame.Visible
    section.Frame.Parent = section.Page.Floating
    section.Frame.Size = UDim2.fromOffset(width, 0)
    section.Frame.Position = UDim2.fromOffset(math.clamp(x, minX, maxX), math.clamp(y, minY, maxY))
    layer(section.Frame, 20)
end

function LayoutManager:Begin(section, input)
    local context = self.context
    if context.Modal.current or context.Input.active then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    context.Overlay:Close()
    local start = Vector2.new(input.Position.X, input.Position.Y)
    local initialPosition = section.Frame.AbsolutePosition
    local width = section.Frame.AbsoluteSize.X / context.Scale.Scale
    local original = {Column = section.Column, Order = section.Order, Detached = section.Detached, Position = section.Frame.Position}
    local moved, targetColumn, targetIndex = false, nil, nil
    local marker
    local function restore()
        if original.Detached then self:Detach(section, original.Position.X.Offset, original.Position.Y.Offset, width)
        else self:Move(section, original.Column, original.Order) end
    end
    self.drag = {Cancel = restore}
    context.Input:Begin(input, function(point)
        if not moved and (point - start).Magnitude < 4 then return end
        if not moved then
            moved = true
            section.Frame.Parent = section.Page.Floating
            section.Frame.Size = UDim2.fromOffset(width, 0)
            layer(section.Frame, 50)
            marker = Instance.new('Frame')
            marker.Name = 'DropMarker'; marker.BorderSizePixel = 0; marker.Size = UDim2.new(1, 0, 0, 3)
            marker.BackgroundColor3 = context.Theme:Get('Accent'); marker.ZIndex = 51
        end
        local localPosition = (initialPosition + point - start - section.Page.Floating.AbsolutePosition) / context.Scale.Scale
        section.Frame.Position = UDim2.fromOffset(localPosition.X, localPosition.Y)
        targetColumn, targetIndex = nil, nil
        marker.Parent = nil
        for column, frame in ipairs(section.Page.Columns) do
            if inside(frame, point) then
                targetColumn = column
                local ordered = self:Ordered(section.Page, column, section)
                targetIndex = #ordered + 1
                for index, item in ipairs(ordered) do
                    if point.Y < item.Frame.AbsolutePosition.Y + item.Frame.AbsoluteSize.Y / 2 then targetIndex = index; break end
                end
                for index, item in ipairs(ordered) do item.Frame.LayoutOrder = index * 2 end
                marker.LayoutOrder = targetIndex * 2 - 1
                marker.Parent = frame
            end
        end
    end, function()
        if marker then marker:Destroy() end
        self.drag = nil
        if not moved then return end
        if self.cancelling then restore()
        elseif targetColumn then self:Move(section, targetColumn, targetIndex)
        else self:Detach(section, section.Frame.Position.X.Offset, section.Frame.Position.Y.Offset, width) end
        for column = 1, 2 do
            for index, item in ipairs(self:Ordered(section.Page, column)) do item.Order = index; item.Frame.LayoutOrder = index end
        end
    end)
end

function LayoutManager:Cancel()
    self.cancelling = true
    self.context.Input:Cancel()
    self.cancelling = false
end

function LayoutManager:Snapshot()
    local result = {}
    for pageId, page in pairs(self.context.Pages) do
        result[pageId] = {}
        for id, section in pairs(page.Sections) do
            result[pageId][id] = {Column = section.Column, Order = section.Order, Detached = section.Detached == true, X = section.Frame.Position.X.Offset, Y = section.Frame.Position.Y.Offset}
        end
    end
    return result
end

function LayoutManager:Validate(layout)
    assert(type(layout) == 'table', 'Missing section layout')
    for pageId, sections in pairs(layout) do
        local page = self.context.Pages[pageId]
        assert(page and type(sections) == 'table', 'Unknown layout page')
        for id, record in pairs(sections) do
            assert(page.Sections[id] and type(record) == 'table', 'Unknown layout section')
            assert(record.Column == 1 or record.Column == 2, 'Invalid layout column')
            assert(type(record.Order) == 'number' and record.Order >= 1 and record.Order <= 10000 and record.Order % 1 == 0, 'Invalid layout order')
            assert(type(record.Detached) == 'boolean', 'Invalid detached state')
            for _, key in ipairs({'X', 'Y'}) do assert(type(record[key]) == 'number' and math.abs(record[key]) <= 100000, 'Invalid layout position') end
        end
    end
end

function LayoutManager:Apply(layout)
    self:Validate(layout)
    self:Cancel()
    for pageId, records in pairs(layout) do
        local page = self.context.Pages[pageId]
        -- First dock all supplied cards, then insert in ascending order.
        local ordered = {}
        for id, record in pairs(records) do table.insert(ordered, {section = page.Sections[id], record = record}) end
        table.sort(ordered, function(a, b) if a.record.Order == b.record.Order then return a.section.Id < b.section.Id end; return a.record.Order < b.record.Order end)
        for _, item in ipairs(ordered) do self:Move(item.section, item.record.Column) end
        for _, item in ipairs(ordered) do
            local section, record = item.section, item.record
            self:Move(section, record.Column, record.Order)
            if record.Detached then self:Detach(section, record.X, record.Y, page.Columns[record.Column].AbsoluteSize.X / self.context.Scale.Scale - 3) end
        end
    end
end

return LayoutManager

end)

__register("Core", "ModalManager", function(script, require)
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

end)

__register("Core", "OverlayManager", function(script, require)
--!nonstrict
local UserInputService = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')
local Cleanup = require(script.Parent.Cleanup)
local Renderer = require(script.Parent.Renderer)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
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
    if current.frame.Parent then
        self.context.Renderer:Tween(current.frame, {BackgroundTransparency = 1}, Tokens.PopupTime)
        task.delay(Tokens.PopupTime, function()
            if current.frame.Parent then current.frame:Destroy() end
        end)
    end
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
    local finalPosition = UDim2.fromOffset((x - origin.X) / scale, (y - origin.Y) / scale)
    local properties = {
        Name = 'DropdownPopup', Position = UDim2.new(finalPosition.X.Scale, finalPosition.X.Offset, finalPosition.Y.Scale, finalPosition.Y.Offset + 4),
        Size = UDim2.fromOffset(width / scale, height / scale), ZIndex = settings.ZIndex or 30,
        Active = true, ClipsDescendants = true,
    }
    if not settings.Freeform then
        properties.CanvasSize = UDim2.new()
        properties.AutomaticCanvasSize = Enum.AutomaticSize.Y
        properties.ScrollBarThickness = 2
        properties.ScrollingDirection = Enum.ScrollingDirection.Y
    end
    properties.BackgroundTransparency = context.Renderer.ReducedMotion and 0 or 1
    local frame = renderer:Create(settings.Freeform and 'Frame' or 'ScrollingFrame', properties, self.layer, {BackgroundColor3 = 'Background'})
    if not settings.Freeform then renderer.Theme:Bind(scope, frame, 'ScrollBarImageColor3', 'Accent') end
    renderer:Corner(frame, 4)
    renderer:Stroke(frame)
    if not settings.Freeform then renderer:Padding(frame, 3); renderer:List(frame, 1) end
    self.current = {owner = owner, anchor = anchor, frame = frame, scope = scope, closed = closed}
    renderer:Tween(frame, {BackgroundTransparency = 0, Position = finalPosition}, Tokens.PopupTime)
    renderer:Connect(anchor:GetPropertyChangedSignal('AbsolutePosition'), function() self:Close() end)
    renderer:Connect(anchor:GetPropertyChangedSignal('AbsoluteSize'), function() self:Close() end)
    return frame, renderer
end

function OverlayManager:IsOpen(owner)
    return self.current ~= nil and self.current.owner == owner
end

return OverlayManager

end)

__register("Core", "ProfileStore", function(script, require)
--!strict
local ProfileStore = {}
ProfileStore.__index = ProfileStore

local function copy(value: any): any
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function nameCheck(name: any)
    assert(type(name) == 'string', 'Profile name must be a string')
    assert(#name > 0 and #name <= 64 and string.find(name, '%S') and not string.find(name, '%c'), 'Profile name must contain 1–64 printable bytes')
end

function ProfileStore.new(save: ((any) -> ())?)
    return setmetatable({data = {Version = 1, Profiles = {} :: {[string]: any}, Autoload = ''}, save = save}, ProfileStore)
end

function ProfileStore:Commit(candidate)
    if self.save then self.save(copy(candidate)) end
    self.data = candidate
end

function ProfileStore:Put(name: string, snapshot: any, overwrite: boolean?)
    nameCheck(name)
    assert(type(snapshot) == 'table', 'Expected configuration snapshot')
    if overwrite then assert(self.data.Profiles[name], 'Profile does not exist')
    else assert(not self.data.Profiles[name], 'Profile already exists') end
    local candidate = copy(self.data)
    candidate.Profiles[name] = copy(snapshot)
    self:Commit(candidate)
end

function ProfileStore:Get(name: string): any
    assert(self.data.Profiles[name], 'Profile does not exist')
    return copy(self.data.Profiles[name])
end

function ProfileStore:Delete(name: string)
    assert(self.data.Profiles[name], 'Profile does not exist')
    local candidate = copy(self.data)
    candidate.Profiles[name] = nil
    if candidate.Autoload == name then candidate.Autoload = '' end
    self:Commit(candidate)
end

function ProfileStore:SetAutoload(name: string)
    assert(name == '' or self.data.Profiles[name], 'Unknown autoload profile')
    local candidate = copy(self.data)
    candidate.Autoload = name
    self:Commit(candidate)
end

function ProfileStore:Names(): {string}
    local names = {}
    for name in pairs(self.data.Profiles) do table.insert(names, tostring(name)) end
    table.sort(names)
    return names
end

function ProfileStore:Replace(data: any, validate: (any) -> ())
    assert(type(data) == 'table' and data.Version == 1 and type(data.Profiles) == 'table', 'Unsupported profile document')
    local count = 0
    for name, snapshot in pairs(data.Profiles) do
        nameCheck(name)
        validate(snapshot)
        count += 1
        assert(count <= 100, 'At most 100 profiles are supported')
    end
    assert(type(data.Autoload) == 'string' and (data.Autoload == '' or data.Profiles[data.Autoload]), 'Invalid autoload profile')
    self:Commit({Version = 1, Profiles = copy(data.Profiles), Autoload = data.Autoload})
end

return ProfileStore

end)

__register("Core", "Records", function(script, require)
--!strict
local Records = {}

function Records.Copy(value: any): any
    if type(value) ~= 'table' then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = Records.Copy(child) end
    return copy
end

function Records.Equal(a: any, b: any): boolean
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    for key, value in pairs(a) do if not Records.Equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local function unit(value: any): number
    assert(type(value) == 'number' and value == value and value >= 0 and value <= 1, 'Color channels must be in [0,1]')
    return value
end

function Records.Color(value: any): any
    assert(type(value) == 'table', 'Color value must be a table')
    local animation = value.Animation or 'None'
    assert(table.find({'None', 'Rainbow', 'Fade', 'Fade Alpha'}, animation), 'Unknown color animation')
    return table.freeze({R = unit(value.R), G = unit(value.G), B = unit(value.B), Alpha = unit(value.Alpha == nil and 1 or value.Alpha), Animation = animation})
end

function Records.Keybind(value: any): any
    assert(type(value) == 'table' and type(value.Key) == 'string' and #value.Key <= 32, 'Invalid keybind')
    assert(value.Mode == 'toggle' or value.Mode == 'hold', 'Keybind mode must be toggle or hold')
    return table.freeze({Key = value.Key, Mode = value.Mode})
end

function Records.Search(metadata: {any}, query: string): {any}
    local words = {}
    for word in string.lower(query):gmatch('%S+') do table.insert(words, word) end
    if #words == 0 then return {} end
    local matches = {}
    for _, item in ipairs(metadata) do
        local haystack = string.lower(item.Label .. ' ' .. item.PageTitle .. ' ' .. item.SectionTitle .. ' ' .. item.Type)
        local matchesAll = true
        for _, word in ipairs(words) do
            if not string.find(haystack, word, 1, true) then matchesAll = false; break end
        end
        if matchesAll then table.insert(matches, item) end
    end
    table.sort(matches, function(a: any, b: any)
        if a.Label == b.Label then return a.Id < b.Id end
        return a.Label < b.Label
    end)
    return matches
end

return Records

end)

__register("Core", "Renderer", function(script, require)
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

end)

__register("Core", "Store", function(script, require)
--!strict
type Listener = {callback: (any) -> (), active: boolean}
type Entry = {value: any, normalize: (any) -> any, metadata: {[string]: any}, listeners: {Listener}}
type StoreData = {entries: {[string]: Entry}, destroyed: boolean}
local Store = {}
Store.__index = Store

local function equal(a: any, b: any): boolean
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    for key, value in pairs(a) do if b[key] ~= value then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

function Store.new()
    return setmetatable({entries = {} :: {[string]: Entry}, destroyed = false}, Store)
end

function Store.Register(self: StoreData, id: string, default: any, normalize: (any) -> any, metadata: {[string]: any})
    assert(not self.destroyed, 'Store destroyed')
    assert(type(id) == 'string' and #id > 0 and not self.entries[id], 'Invalid or duplicate control Id: ' .. tostring(id))
    self.entries[id] = {value = normalize(default), normalize = normalize, metadata = table.freeze(table.clone(metadata)), listeners = {}}
end

function Store.Get(self: StoreData, id: string): any
    local entry = self.entries[id]
    assert(entry, 'Unknown control: ' .. id)
    return entry.value
end

function Store.Set(self: StoreData, id: string, value: any): boolean
    assert(not self.destroyed, 'Store destroyed')
    local entry = self.entries[id]
    assert(entry, 'Unknown control: ' .. id)
    local normalized = entry.normalize(value)
    if equal(entry.value, normalized) then return false end
    entry.value = normalized
    -- A snapshot lets callbacks unsubscribe safely without skipping other listeners.
    for _, listener in ipairs(table.clone(entry.listeners)) do
        if entry.value ~= normalized then break end
        if listener.active then
            local ok, problem = pcall(listener.callback, normalized)
            if not ok then print('[Blossom callback] ' .. tostring(problem)) end
        end
    end
    return true
end

function Store.Subscribe(self: StoreData, id: string, callback: (any) -> ()): () -> ()
    assert(not self.destroyed, 'Store destroyed')
    local entry = self.entries[id]
    assert(entry, 'Unknown control: ' .. id)
    local listener = {callback = callback, active = true}
    table.insert(entry.listeners, listener)
    return function()
        listener.active = false
        local index = table.find(entry.listeners, listener)
        if index then table.remove(entry.listeners, index) end
    end
end

function Store.Snapshot(self: StoreData): {[string]: any}
    local values = {}
    for id, entry in pairs(self.entries) do values[id] = entry.value end
    return values
end

function Store.Destroy(self: StoreData)
    if self.destroyed then return end
    self.destroyed = true
    for _, entry in pairs(self.entries) do
        for _, listener in ipairs(entry.listeners) do listener.active = false end
    end
    table.clear(self.entries)
end

return Store

end)

__register("Core", "ThemeManager", function(script, require)
--!nonstrict
local Blossom = require(script.Parent.Parent.Themes.Blossom)
local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager.new()
    return setmetatable({colors = table.clone(Blossom), listeners = {}}, ThemeManager)
end

function ThemeManager:Get(token)
    assert(self.colors[token], 'Unknown theme token: ' .. tostring(token))
    return self.colors[token]
end

function ThemeManager:Subscribe(scope, callback)
    self.listeners[callback] = true
    scope:Add(function() self.listeners[callback] = nil end)
    callback()
end

function ThemeManager:Bind(scope, instance, property, token)
    self:Subscribe(scope, function() instance[property] = self:Get(token) end)
end

function ThemeManager:Set(overrides)
    assert(type(overrides) == 'table', 'SetTheme expects a token table')
    for token, color in pairs(overrides) do
        assert(self.colors[token] and typeof(color) == 'Color3', 'Invalid theme token/color: ' .. tostring(token))
    end
    for token, color in pairs(overrides) do self.colors[token] = color end
    for callback in pairs(table.clone(self.listeners)) do if self.listeners[callback] then callback() end end
end

function ThemeManager:Destroy()
    table.clear(self.listeners)
end

return ThemeManager

end)

__register("Core", "Value", function(script, require)
--!strict
local Value = {}

function Value.finite(value: any): number
    assert(type(value) == 'number' and value == value and math.abs(value) < math.huge, 'Expected finite number')
    return value
end

function Value.id(value: any): string
    assert(type(value) == 'string' and #value > 0, 'Expected nonempty Id')
    return value
end

function Value.boolean(value: any): boolean
    assert(type(value) == 'boolean', 'Expected boolean')
    return value
end

function Value.slider(minimum: number, maximum: number, step: number): (any) -> number
    Value.finite(minimum)
    Value.finite(maximum)
    Value.finite(step)
    assert(maximum > minimum and step > 0, 'Slider requires Maximum > Minimum and Step > 0')
    Value.finite(maximum - minimum)
    Value.finite((maximum - minimum) / step)
    return function(value: any): number
        local bounded = math.clamp(Value.finite(value), minimum, maximum)
        if bounded == maximum then return maximum end
        local snapped = minimum + math.floor((bounded - minimum) / step + 0.5) * step
        return math.clamp(snapped, minimum, maximum)
    end
end

function Value.dropdown(options: {string}): (any) -> string
    assert(type(options) == 'table' and #options > 0, 'Dropdown requires options')
    local members: {[string]: boolean} = {}
    local count = 0
    for index in pairs(options) do
        assert(type(index) == 'number' and index % 1 == 0 and index >= 1 and index <= #options, 'Options must be a dense array')
        count += 1
    end
    assert(count == #options, 'Options must be a dense array')
    for _, option in ipairs(options) do
        Value.id(option)
        assert(not members[option], 'Duplicate dropdown option: ' .. option)
        members[option] = true
    end
    return function(value: any): string
        assert(type(value) == 'string' and members[value], 'Unknown dropdown option')
        return value
    end
end

function Value.multiselect(options: {string}): (any) -> {string}
    local single = Value.dropdown(options)
    local members = {}
    for _, option in ipairs(options) do members[option] = true end
    return function(value: any): {string}
        assert(type(value) == 'table', 'Expected a selection table')
        local result: {string} = {}
        local seen = {}
        for _, item in ipairs(value) do
            local itemName = item :: string
            single(itemName)
            assert(not seen[itemName], 'Duplicate selection option')
            seen[itemName] = true
            table.insert(result, itemName)
        end
        table.sort(result, function(a, b)
            local ia = table.find(options, a) :: number
            local ib = table.find(options, b) :: number
            return ia < ib
        end)
        return result
    end
end

function Value.text(maxLength: number): (any) -> string
    Value.finite(maxLength)
    assert(maxLength >= 0 and maxLength % 1 == 0, 'MaxLength must be a nonnegative integer')
    return function(value: any): string
        assert(type(value) == 'string', 'Expected string')
        local length = utf8.len(value)
        assert(length ~= nil, 'Expected valid UTF-8')
        if length <= maxLength then return value end
        local boundary = utf8.offset(value, maxLength + 1)
        return string.sub(value, 1, (boundary :: number) - 1)
    end
end

return Value

end)

__register("Themes", "Blossom", function(script, require)
--!strict
return table.freeze({
    Background = Color3.fromRGB(29, 31, 34),
    Sidebar = Color3.fromRGB(27, 29, 32),
    Tab = Color3.fromRGB(37, 39, 43),
    Section = Color3.fromRGB(41, 43, 47),
    Input = Color3.fromRGB(37, 39, 42),
    Outline = Color3.fromRGB(56, 59, 64),
    Inline = Color3.fromRGB(48, 51, 56),
    Text = Color3.fromRGB(227, 230, 234),
    InactiveText = Color3.fromRGB(141, 146, 155),
    Accent = Color3.fromRGB(116, 169, 227),
    Element = Color3.fromRGB(51, 54, 60),
    HoveredElement = Color3.fromRGB(58, 61, 67),
    Gradient = Color3.fromRGB(200, 212, 227),
    Shadow = Color3.fromRGB(0, 0, 0),
})

end)

__register("Themes", "Presets", function(script, require)
--!nonstrict
-- Approximate recreations. Only preset names and broad appearances are observed.
local Blossom = require(script.Parent.Blossom)
local Presets = {Names = {'Blossom', 'Afterglow', 'Frostbite', 'Volt', 'Obsidian', 'Sakura Drift', 'Neon Mirage', 'Copper Dust', 'Abyss', 'Porcelain'}}
local accents = {
    ['Blossom'] = '74A9E3', ['Afterglow'] = 'E79B80', ['Frostbite'] = '8DD8E8', ['Volt'] = '97E650',
    ['Obsidian'] = 'ADADBB', ['Sakura Drift'] = 'E6A2BF', ['Neon Mirage'] = 'BE8CFF', ['Copper Dust'] = 'D99A69',
    ['Abyss'] = '579CE2', ['Porcelain'] = '397ABF',
}
local surfaces = {['Afterglow'] = '282125', ['Frostbite'] = '1C252C', ['Volt'] = '151D17', ['Obsidian'] = '171719', ['Sakura Drift'] = '29222C', ['Neon Mirage'] = '201D2D', ['Copper Dust'] = '29231F', ['Abyss'] = '151E2B'}
function Presets.Get(name)
    assert(accents[name], 'Unknown theme preset: ' .. tostring(name))
    local colors = table.clone(Blossom)
    colors.Accent = Color3.fromHex(accents[name])
    if surfaces[name] then
        local base = Color3.fromHex(surfaces[name])
        colors.Background = base
        colors.Sidebar = base:Lerp(Color3.new(), 0.1)
        colors.Tab = base:Lerp(Color3.new(1, 1, 1), 0.035)
        colors.Section = base:Lerp(Color3.new(1, 1, 1), 0.055)
        colors.Input = colors.Tab
        colors.Element = base:Lerp(Color3.new(1, 1, 1), 0.09)
        colors.HoveredElement = base:Lerp(Color3.new(1, 1, 1), 0.14)
    elseif name == 'Porcelain' then
        colors.Background = Color3.fromHex('F3F4F6'); colors.Sidebar = Color3.fromHex('E9ECF0')
        colors.Tab = Color3.fromHex('FAFBFC'); colors.Section = Color3.fromHex('FFFFFF'); colors.Input = Color3.fromHex('E8EBEF')
        colors.Outline = Color3.fromHex('BCC3CD'); colors.Inline = Color3.fromHex('D5DAE1')
        colors.Text = Color3.fromHex('202733'); colors.InactiveText = Color3.fromHex('586270')
        colors.Element = Color3.fromHex('CAD2DD'); colors.HoveredElement = Color3.fromHex('DDE5EE')
        colors.Gradient = Color3.fromHex('FFFFFF')
    end
    return colors
end
return Presets

end)

__register("Themes", "Tokens", function(script, require)
--!strict
-- Estimated from the supplied blueprint; tune against Studio screenshots.
return table.freeze({
    Width = 422, Height = 336, Sidebar = 103, Gutter = 8,
    Radius = 7, CardRadius = 4, ControlRadius = 3,
    TextSize = 10, SmallText = 9, TitleSize = 13,
    RowHeight = 18, FieldHeight = 18, SliderHeight = 30,
    NavHeight = 21, SectionHeader = 21, ControlGap = 2,
    HoverTime = 0.09, ToggleTime = 0.12, PageFadeOut = 0.10, PageFadeIn = 0.15,
    SidebarMove = 0.30, PopupTime = 0.12, SectionCollapse = 0.18,
    PopupRow = 20, PopupMaxHeight = 144,
})

end)

__register("Components", "Button", function(script, require)
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

end)

__register("Components", "ColorPicker", function(script, require)
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

end)

__register("Components", "Control", function(script, require)
--!nonstrict
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Control = {}
Control.__index = Control

function Control.Call(callback, ...)
    if not callback then return end
    local ok, problem = pcall(callback, ...)
    if not ok then warn('[Blossom callback] ' .. tostring(problem)) end
end

function Control.new(context, section, options, kind, default, normalize, height)
    assert(not context.Destroyed, 'Library destroyed')
    Value.id(options.Id)
    Value.id(options.Label)
    assert(not context.Registry[options.Id], 'Duplicate control Id: ' .. options.Id)
    assert(options.OnChanged == nil or type(options.OnChanged) == 'function', 'OnChanged must be a function')
    assert(options.Disabled == nil or type(options.Disabled) == 'boolean', 'Disabled must be boolean')
    if normalize then default = normalize(default) end
    local metadata = table.freeze({
        Id = options.Id, Label = options.Label, Type = kind,
        PageId = section.Page.Id, PageTitle = section.Page.Title,
        SectionId = section.Id, SectionTitle = section.Title,
        Persist = options.Persist ~= false,
    })
    if normalize then context.Store:Register(options.Id, default, normalize, metadata) end
    section.count += 1
    local r = context.Renderer
    local row = r:Create('Frame', {
        Name = options.Id, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = section.count,
    }, section.Body)
    local label = r:Create('TextLabel', {
        Name = 'Label', Text = options.Label, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, Tokens.RowHeight),
    }, row)
    local self = setmetatable({
        Id = options.Id, Frame = row, Label = label, Metadata = metadata,
        Disabled = options.Disabled or false, context = context, hasValue = normalize ~= nil, Section = section,
        refreshers = {}, targets = {},
    }, Control)
    context.Registry[options.Id] = self
    context.Theme:Subscribe(context.Cleanup, function() self:Refresh() end)
    return self
end

function Control:Refresh()
    self.Label.TextColor3 = self.context.Theme:Get(self.Disabled and 'InactiveText' or 'Text')
    for _, target in ipairs(self.targets) do
        target.Active = not self.Disabled
        target.Selectable = not self.Disabled
        target.Interactable = not self.Disabled
        if target:IsA('TextBox') then target.TextEditable = not self.Disabled end
    end
    for _, refresh in ipairs(self.refreshers) do refresh() end
end

function Control:Target(target)
    table.insert(self.targets, target)
end

function Control:Mount(paint, callback)
    table.insert(self.refreshers, paint)
    if self.hasValue then
        self.context.Cleanup:Add(self.context.Store:Subscribe(self.Id, function() paint() end))
        if callback then self.context.Cleanup:Add(self.context.Store:Subscribe(self.Id, callback)) end
    end
    self:Refresh()
    return self
end

function Control:GetValue()
    assert(not self.context.Destroyed and self.hasValue, 'Control has no readable value')
    return self.context.Store:Get(self.Id)
end

function Control:SetValue(value)
    assert(not self.context.Destroyed and self.hasValue, 'Control has no writable value')
    return self.context.Store:Set(self.Id, value)
end

function Control:SetDisabled(disabled)
    assert(not self.context.Destroyed, 'Library destroyed')
    Value.boolean(disabled)
    self.Disabled = disabled
    if disabled then
        self.context.Input:Cancel()
        if self.context.Overlay:IsOpen(self.Id) then self.context.Overlay:Close() end
        for _, target in ipairs(self.targets) do
            if target:IsA('TextBox') and target:IsFocused() then target:ReleaseFocus(false) end
        end
    end
    self:Refresh()
end

return Control

end)

__register("Components", "Dropdown", function(script, require)
--!nonstrict
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Dropdown = {}

function Dropdown.new(context, section, options)
    local multi = options.Multi == true
    local normalize = if multi then Value.multiselect(options.Options) else Value.dropdown(options.Options)
    local choices = table.clone(options.Options)
    local default = if options.Default ~= nil then options.Default else if multi then {} else choices[1]
    local self = Control.new(context, section, options, 'Dropdown', default, normalize, 42)
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
        local current = self:GetValue()
        selected.Text = if multi then table.concat(current, ', ') else current
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
            local selectedChoice = if multi then table.find(self:GetValue(), choice) ~= nil else choice == self:GetValue()
            pr:Label(item, (selectedChoice and '▌ ' or '  ') .. choice, {Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -12, 1, 0), ZIndex = 32}, selectedChoice and 'Accent' or 'Text')
            pr:Feedback(item, nil, function() return selectedChoice and 'Tab' or 'Background' end)
            pr:Connect(item.Activated, function()
                if multi then
                    local nextValue = table.clone(self:GetValue())
                    local index = table.find(nextValue, choice)
                    if index then table.remove(nextValue, index) else table.insert(nextValue, choice) end
                    self:SetValue(nextValue)
                    context.Overlay:Close()
                else
                    context.Overlay:Close()
                    self:SetValue(choice)
                end
            end)
        end
    end)
    context.Cleanup:Add(context.Store:Subscribe(self.Id, function()
        if context.Overlay:IsOpen(self.Id) then context.Overlay:Close() end
    end))
    return self:Mount(paint, options.OnChanged)
end

return Dropdown

end)

__register("Components", "Keybind", function(script, require)
--!nonstrict
local Control = require(script.Parent.Control)
local Records = require(script.Parent.Parent.Core.Records)
local Keybind = {}

function Keybind.new(context, section, options)
    assert(options.OnTriggered == nil or type(options.OnTriggered) == 'function', 'OnTriggered must be function')
    local function normalize(value)
        local record = Records.Keybind(value)
        if record.Key ~= 'None' then
            local ok, key = pcall(function() return Enum.KeyCode[record.Key] end)
            assert(ok and key and key ~= Enum.KeyCode.Unknown, 'Unknown keyboard key')
        end
        return record
    end
    local self = Control.new(context, section, options, 'Keybind', options.Default or {Key = 'None', Mode = 'toggle'}, normalize, 22)
    self.Active = false
    self.Global = options.Global == true
    self.Label.Size = UDim2.new(1, -64, 1, 0)
    local r = context.Renderer
    local chip = r:Create('TextButton', {Name = 'Keybind', Text = '', Position = UDim2.new(1, -62, 0, 1), Size = UDim2.fromOffset(62, 20), TextSize = 9}, self.Frame)
    r:Corner(chip); r:Stroke(chip, 'Inline')
    r:Feedback(chip, function() return self.Disabled end)
    self:Target(chip)
    function self:SetActive(active)
        if self.Active == active then return end
        self.Active = active
        if not context.Destroyed then
            self:Refresh()
            Control.Call(options.OnTriggered, active)
        end
    end
    local function paint()
        chip.Text = context.Keys.capture == self and 'Press key...' or self:GetValue().Key
        chip.TextColor3 = context.Theme:Get(self.Disabled and 'InactiveText' or self.Active and 'Accent' or 'Text')
        if self.Disabled then self:SetActive(false) end
    end
    r:Connect(chip.Activated, function()
        if self.Disabled then return end
        if context.Overlay:IsOpen(self.Id) then context.Overlay:Close(); return end
        local popup, pr = context.Overlay:Open(self.Id, chip, 102, nil, {Width = 142})
        for index, label in ipairs({'Capture key', 'On Toggle', 'On Hold', 'Reset'}) do
            local button = pr:Create('TextButton', {Text = label, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = index, ZIndex = 31}, popup, {TextColor3 = ((index == 2 and self:GetValue().Mode == 'toggle') or (index == 3 and self:GetValue().Mode == 'hold')) and 'Accent' or 'Text'})
            pr:Corner(button); pr:Feedback(button)
            pr:Connect(button.Activated, function()
                if index == 1 then context.Keys:Capture(self); return end
                local value = self:GetValue()
                self:SetValue({Key = index == 4 and 'None' or value.Key, Mode = index == 3 and 'hold' or index == 2 and 'toggle' or value.Mode})
                context.Overlay:Close()
            end)
        end
    end)
    context.Keys.bindings[self.Id] = self
    context.Cleanup:Add(context.Store:Subscribe(self.Id, function() self:SetActive(false) end))
    return self:Mount(paint, options.OnChanged)
end

return Keybind

end)

__register("Components", "ListBox", function(script, require)
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

end)

__register("Components", "Page", function(script, require)
--!nonstrict
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Value = require(script.Parent.Parent.Core.Value)
local Section = require(script.Parent.Section)
local Page = {}
Page.__index = Page

function Page.new(context, options)
    local r = context.Renderer
    local frame = r:Create('CanvasGroup', {
        Name = 'Page_' .. options.Id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false,
        GroupTransparency = 1,
    }, context.Content)
    local columns = {}
    for index = 1, 2 do
        local column = r:Create('ScrollingFrame', {
            Name = 'Column' .. index, BackgroundTransparency = 1,
            Position = UDim2.new((index - 1) * 0.5, (index - 1) * Tokens.Gutter / 2, 0, 0),
            Size = UDim2.new(0.5, -Tokens.Gutter / 2, 1, 0), CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2,
            ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true,
        }, frame, {ScrollBarImageColor3 = 'Element'})
        r:List(column, Tokens.Gutter)
        r:Create('UIPadding', {PaddingBottom = UDim.new(0, 2), PaddingRight = UDim.new(0, 3)}, column)
        columns[index] = column
    end
    local floating = r:Create('Frame', {Name = 'Floating_' .. options.Id, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 20}, context.Root)
    return setmetatable({Id = options.Id, Title = options.Title, Frame = frame, Floating = floating, Columns = columns, Sections = {}, context = context, count = 0}, Page)
end

function Page:AddSection(options)
    assert(not self.context.Destroyed, 'Library destroyed')
    Value.id(options.Id)
    Value.id(options.Title)
    assert(not self.Sections[options.Id], 'Duplicate section Id: ' .. options.Id)
    local column = options.Column or 1
    assert(column == 1 or column == 2, 'Column must be 1 or 2')
    local order = options.Order or self.count + 1
    Value.finite(order)
    local section = Section.new(self.context, self, options, self.Columns[column], order)
    self.count += 1
    self.Sections[options.Id] = section
    return section
end

return Page

end)

__register("Components", "RangeSlider", function(script, require)
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

end)

__register("Components", "SearchDialog", function(script, require)
--!nonstrict
local Records = require(script.Parent.Parent.Core.Records)
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Renderer = require(script.Parent.Parent.Core.Renderer)
local SearchDialog = {}

function SearchDialog.Open(context)
    local panel, r = context.Modal:Open('Search', 330, 250)
    local input = r:Create('TextBox', {Name = 'SearchQuery', PlaceholderText = 'Search controls...', Text = '', ClearTextOnFocus = false, Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 0, 26), TextXAlignment = Enum.TextXAlignment.Left}, panel, {BackgroundColor3 = 'Input', TextColor3 = 'Text', PlaceholderColor3 = 'InactiveText'})
    r:Padding(input, 6); r:Corner(input); r:Stroke(input, 'Accent')
    local results = r:Create('ScrollingFrame', {Name = 'Results', Position = UDim2.fromOffset(12, 72), Size = UDim2.new(1, -24, 1, -84), BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y}, panel, {ScrollBarImageColor3 = 'Accent'})
    r:List(results, 4)
    local resultScope = Cleanup.new()
    r.Scope:Add(function() resultScope:Destroy() end)
    local firstMatch
    local function refresh()
        resultScope:Destroy()
        for _, child in ipairs(results:GetChildren()) do if child:IsA('GuiObject') then child:Destroy() end end
        resultScope = Cleanup.new()
        local rr = Renderer.new(context.Theme, resultScope, context.Renderer.ReducedMotion)
        local matches = Records.Search(context.Library:GetControls(), input.Text)
        firstMatch = matches[1]
        if #matches == 0 then
            rr:Label(results, input.Text:match('%S') and 'No matching controls' or 'Type to find a control', {Size = UDim2.new(1, 0, 0, 32)}, 'InactiveText')
        end
        for index, match in ipairs(matches) do
            local row = rr:Create('TextButton', {Name = match.Id, Text = '', Size = UDim2.new(1, -4, 0, 38), LayoutOrder = index}, results)
            rr:Corner(row); rr:Feedback(row)
            rr:Create('Frame', {Position = UDim2.fromOffset(0, 4), Size = UDim2.new(0, 2, 1, -8)}, row, {BackgroundColor3 = 'Accent'})
            rr:Label(row, match.Label, {Position = UDim2.fromOffset(8, 2), Size = UDim2.new(1, -12, 0, 18)})
            rr:Label(row, match.PageTitle .. ' / ' .. match.SectionTitle .. ' · ' .. match.Type, {Position = UDim2.fromOffset(8, 19), Size = UDim2.new(1, -12, 0, 16), TextSize = 9}, 'InactiveText')
            rr:Connect(row.Activated, function() context.Modal:Close(); context.Library:RevealControl(match.Id) end)
        end
        results.CanvasPosition = Vector2.zero
    end
    r:Connect(input:GetPropertyChangedSignal('Text'), refresh)
    r:Connect(input.FocusLost, function(enter)
        if enter and firstMatch then context.Modal:Close(); context.Library:RevealControl(firstMatch.Id) end
    end)
    refresh()
    input:CaptureFocus()
end

return SearchDialog

end)

__register("Components", "Section", function(script, require)
--!nonstrict
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Toggle = require(script.Parent.Toggle)
local Slider = require(script.Parent.Slider)
local RangeSlider = require(script.Parent.RangeSlider)
local Dropdown = require(script.Parent.Dropdown)
local Button = require(script.Parent.Button)
local TextInput = require(script.Parent.TextInput)
local Keybind = require(script.Parent.Keybind)
local ColorPicker = require(script.Parent.ColorPicker)
local ListBox = require(script.Parent.ListBox)
local Section = {}
Section.__index = Section

function Section.new(context, page, options, parent, order)
    local r = context.Renderer
    local frame = r:Create('Frame', {
        Name = 'Section_' .. options.Id, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order,
    }, parent, {BackgroundColor3 = 'Tab'})
    r:Corner(frame, Tokens.CardRadius)
    local gradient = r:Create('UIGradient', {Name = 'SurfaceGradient', Rotation = 90}, frame)
    context.Theme:Subscribe(context.Cleanup, function()
        gradient.Color = ColorSequence.new(context.Theme:Get('Tab'), context.Theme:Get('Section'))
    end)
    r:List(frame, 0)
    local header = r:Create('TextButton', {Name = 'Header', Text = '', Size = UDim2.new(1, 0, 0, Tokens.SectionHeader), BackgroundTransparency = 1, LayoutOrder = 0}, frame)
    local icon = r:Create('Frame', {Name = 'Icon', Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(5, 5)}, header, {BackgroundColor3 = 'Accent'})
    r:Corner(icon, 5)
    r:Label(header, options.Title, {Position = UDim2.fromOffset(19, 0), Size = UDim2.new(1, -26, 1, 0), Font = Enum.Font.GothamMedium})
    local collapsible = options.Collapsible == true
    local chevron
    if collapsible then
        chevron = r:Label(header, '⌄', {Name = 'Chevron', Position = UDim2.new(1, -22, 0, 0), Size = UDim2.fromOffset(16, Tokens.SectionHeader), TextXAlignment = Enum.TextXAlignment.Center, TextSize = Tokens.SmallText}, 'InactiveText')
    end
    r:Create('Frame', {Name = 'Rule', Position = UDim2.new(0, 7, 1, -1), Size = UDim2.new(1, -14, 0, 1)}, header, {BackgroundColor3 = 'Inline'})
    if options.Description and options.Description ~= '' then
        r:Label(frame, options.Description, {Name = 'Description', Position = UDim2.fromOffset(19, Tokens.SectionHeader), Size = UDim2.new(1, -26, 0, 14), TextSize = Tokens.SmallText, LayoutOrder = 1}, 'InactiveText')
    end
    local body = r:Create('Frame', {Name = 'Body', Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, frame)
    r:Padding(body, 6)
    r:List(body, Tokens.ControlGap)
    local self = setmetatable({Id = options.Id, Title = options.Title, Page = page, Frame = frame, Body = body, Column = options.Column or 1, Order = order, context = context, count = 0, Collapsible = collapsible, Collapsed = false, Chevron = chevron, Transition = 0}, Section)
    function self:SetCollapsed(collapsed)
        if not self.Collapsible or self.Collapsed == collapsed then return end
        self.Collapsed = collapsed
        self.Transition += 1
        local transition = self.Transition
        local expandedHeight = self.Body.AbsoluteSize.Y
        self.Body.AutomaticSize = Enum.AutomaticSize.None
        if collapsed then
            self.context.Renderer:Tween(self.Body, {Size = UDim2.new(1, 0, 0, 0)}, Tokens.SectionCollapse)
        else
            self.Body.Size = UDim2.new(1, 0, 0, 0)
            self.Body.AutomaticSize = Enum.AutomaticSize.Y
            task.defer(function()
                if self.context.Destroyed or transition ~= self.Transition then return end
                expandedHeight = self.Body.AbsoluteSize.Y
                self.Body.AutomaticSize = Enum.AutomaticSize.None
                self.context.Renderer:Tween(self.Body, {Size = UDim2.new(1, 0, 0, expandedHeight)}, Tokens.SectionCollapse)
            end)
        end
        if self.Chevron then self.context.Renderer:Tween(self.Chevron, {Rotation = collapsed and -90 or 0}, Tokens.SectionCollapse) end
        if collapsed then self.context.Input:Cancel(); self.context.Overlay:Close() end
        task.delay(Tokens.SectionCollapse, function()
            if not self.context.Destroyed and transition == self.Transition and not self.Collapsed then self.Body.AutomaticSize = Enum.AutomaticSize.Y end
        end)
    end
    function self:IsCollapsed() return self.Collapsed end
    if collapsible and options.Collapsed == true then task.defer(function() self:SetCollapsed(true) end) end
    r:Connect(header.InputBegan, function(input) context.Layout:Begin(self, input) end)
    r:Connect(header.Activated, function(input)
        if input and input.UserInputType == Enum.UserInputType.Gamepad1 then
            self:MoveTo(self.Column == 1 and 2 or 1)
        elseif self.Collapsible and not context.Layout.drag then
            self:SetCollapsed(not self.Collapsed)
        end
    end)
    r:Connect(header.MouseButton2Click, function() self:MoveTo(self.Column == 1 and 2 or 1) end)
    return self
end

function Section:AddToggle(options) return Toggle.new(self.context, self, options) end
function Section:AddSlider(options) return Slider.new(self.context, self, options) end
function Section:AddRangeSlider(options) return RangeSlider.new(self.context, self, options) end
function Section:AddDropdown(options) return Dropdown.new(self.context, self, options) end
function Section:AddButton(options) return Button.new(self.context, self, options) end
function Section:AddTextInput(options) return TextInput.new(self.context, self, options) end
function Section:AddKeybind(options) return Keybind.new(self.context, self, options) end
function Section:AddColorPicker(options) return ColorPicker.new(self.context, self, options) end
function Section:AddListBox(options) return ListBox.new(self.context, self, options) end
function Section:MoveTo(column, order) self.context.Layout:Cancel(); self.context.Layout:Move(self, column, order) end
function Section:Detach(x, y) self.context.Layout:Cancel(); self.context.Layout:Detach(self, x, y, self.Frame.AbsoluteSize.X / self.context.Scale.Scale) end

return Section

end)

__register("Components", "Sidebar", function(script, require)
--!nonstrict
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Sidebar = {}
Sidebar.__index = Sidebar

function Sidebar.new(context, title)
    local r = context.Renderer
    local frame = r:Create('Frame', {Name = 'Sidebar', Size = UDim2.new(0, Tokens.Sidebar, 1, 0)}, context.Root, {BackgroundColor3 = 'Sidebar'})
    r:Corner(frame, Tokens.Radius)
    r:Create('Frame', {Name = 'Divider', Position = UDim2.new(1, -1, 0, 8), Size = UDim2.new(0, 1, 1, -16)}, frame, {BackgroundColor3 = 'Inline'})
    local brand = r:Create('TextButton', {
        Name = 'DragHandle', Text = '', BackgroundTransparency = 1, Size = UDim2.new(1, -2, 0, 38), Selectable = false,
    }, frame)
    local logo = r:Create('Frame', {Name = 'Logo', Position = UDim2.fromOffset(10, 13), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1}, brand)
    r:Corner(logo, 12)
    r:Stroke(logo, 'Accent')
    r:Label(brand, title, {Position = UDim2.fromOffset(29, 0), Size = UDim2.new(1, -33, 1, 0), TextSize = Tokens.TitleSize, Font = Enum.Font.GothamMedium})
    r:Connect(brand.InputBegan, context.BeginWindowDrag)
    local nav = r:Create('ScrollingFrame', {
        Name = 'Navigation', Position = UDim2.fromOffset(7, 40), Size = UDim2.new(1, -14, 1, -76),
        BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y,
    }, frame)
    r:List(nav, 3)
    local search = r:Create('TextButton', {
        Name = 'Search', Text = 'Search...', TextSize = Tokens.SmallText,
        Position = UDim2.new(0, 8, 1, -28), Size = UDim2.new(1, -16, 0, 20),
        Active = true, Selectable = true, Interactable = true,
    }, frame, {BackgroundColor3 = 'Input', TextColor3 = 'InactiveText'})
    r:Corner(search)
    r:Stroke(search, 'Inline')
    r:Feedback(search)
    r:Connect(search.Activated, function() context.Search:Open() end)
    return setmetatable({context = context, nav = nav, groups = {}, items = {}, order = 0, search = search}, Sidebar)
end

function Sidebar:AddPage(page, groupName)
    local r = self.context.Renderer
    local group = self.groups[groupName]
    if not group then
        self.order += 1
        group = r:Create('Frame', {Name = 'Group_' .. groupName, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = self.order}, self.nav)
        r:List(group, 1)
        if groupName ~= '' then
            r:Label(group, groupName, {Size = UDim2.new(1, -4, 0, 17), Position = UDim2.fromOffset(4, 0), TextSize = Tokens.SmallText, LayoutOrder = 0}, 'InactiveText')
        end
        self.groups[groupName] = group
    end
    local button = r:Create('TextButton', {
        Name = 'Page_' .. page.Id, Text = '', Size = UDim2.new(1, 0, 0, Tokens.NavHeight), LayoutOrder = #self.items + 1,
    }, group)
    r:Corner(button, 4)
    local selection = r:Create('Frame', {Name = 'Selection', Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = button.ZIndex}, button, {BackgroundColor3 = 'Tab'})
    r:Corner(selection, 4)
    local marker = r:Create('Frame', {Name = 'Marker', Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(5, 5)}, button)
    r:Corner(marker, 4)
    local label = r:Create('TextLabel', {Name = 'Label', Text = page.Title, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -23, 1, 0)}, button)
    local refresh = r:Feedback(button, nil, function() return 'Sidebar' end)
    local function paint()
        local active = self.context.CurrentPage == page.Id
        r:Tween(selection, {BackgroundTransparency = active and 0 or 1}, Tokens.SidebarMove)
        marker.BackgroundColor3 = self.context.Theme:Get(active and 'Accent' or 'InactiveText')
        label.TextColor3 = self.context.Theme:Get(active and 'Text' or 'InactiveText')
        refresh()
    end
    self.context.Theme:Subscribe(self.context.Cleanup, paint)
    table.insert(self.items, paint)
    r:Connect(button.Activated, function() self.context.Library:SelectPage(page.Id) end)
end

function Sidebar:Refresh()
    for _, paint in ipairs(self.items) do paint() end
end

return Sidebar

end)

__register("Components", "Slider", function(script, require)
--!nonstrict
local GuiService = game:GetService('GuiService')
local UserInputService = game:GetService('UserInputService')
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Slider = {}

function Slider.new(context, section, options)
    local minimum = if options.Minimum == nil then 0 else options.Minimum
    local maximum = if options.Maximum == nil then 100 else options.Maximum
    local step = if options.Step == nil then 1 else options.Step
    local normalize = Value.slider(minimum, maximum, step)
    assert(options.Unit == nil or type(options.Unit) == 'string', 'Unit must be a string')
    local self = Control.new(context, section, options, 'Slider', if options.Default == nil then minimum else options.Default, normalize, Tokens.SliderHeight)
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

end)

__register("Components", "TextInput", function(script, require)
--!nonstrict
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local TextInput = {}

function TextInput.new(context, section, options)
    assert(options.OnSubmitted == nil or type(options.OnSubmitted) == 'function', 'OnSubmitted must be a function')
    assert(options.Placeholder == nil or type(options.Placeholder) == 'string', 'Placeholder must be a string')
    local maxLength = if options.MaxLength == nil then 200 else options.MaxLength
    local self = Control.new(context, section, options, 'TextInput', if options.Default == nil then '' else options.Default, Value.text(maxLength), 42)
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

end)

__register("Components", "Toggle", function(script, require)
--!nonstrict
local Control = require(script.Parent.Control)
local Value = require(script.Parent.Parent.Core.Value)
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Toggle = {}

function Toggle.new(context, section, options)
    local default = if options.Default == nil then false else options.Default
    local self = Control.new(context, section, options, 'Toggle', default, Value.boolean, Tokens.RowHeight)
    local r = context.Renderer
    local accessoryWidth = (options.Keybind and 27 or 0) + (options.Color and 16 or 0)
    self.Label.Size = UDim2.new(1, -27 - accessoryWidth, 1, 0)
    if options.Keybind then
        local chip = r:Create('TextLabel', {Name = 'KeybindChip', Text = tostring(options.Keybind), Position = UDim2.new(1, -49 - (options.Color and 16 or 0), 0, 2), Size = UDim2.fromOffset(24, 14), TextSize = 8, TextXAlignment = Enum.TextXAlignment.Center}, self.Frame, {BackgroundColor3 = 'Input', TextColor3 = 'InactiveText'})
        r:Corner(chip, 2)
        r:Stroke(chip, 'Inline')
    end
    if options.Color then
        local swatch = r:Create('Frame', {Name = 'ColorSwatch', Position = UDim2.new(1, -43, 0, 5), Size = UDim2.fromOffset(8, 8)}, self.Frame, {BackgroundColor3 = 'Accent'})
        r:Corner(swatch, 2)
    end
    local hit = r:Create('TextButton', {Name = 'Toggle', Text = '', BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, self.Frame)
    local pill = r:Create('Frame', {Name = 'Pill', AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(20, 10)}, hit)
    r:Corner(pill, 12)
    local knob = r:Create('Frame', {Name = 'Knob', AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(6, 6)}, pill)
    r:Corner(knob, 8)
    self:Target(hit)
    local hovered = false
    local function paint()
        local value = self:GetValue()
        local token = value and 'Accent' or (hovered and 'HoveredElement' or 'Element')
        if self.Disabled then token = 'Element' end
        r:Tween(pill, {BackgroundColor3 = context.Theme:Get(token)}, Tokens.ToggleTime)
        r:Tween(knob, {Position = UDim2.new(0, value and 12 or 2, 0.5, 0), BackgroundColor3 = context.Theme:Get(self.Disabled and 'InactiveText' or 'Text')}, Tokens.ToggleTime)
    end
    r:Connect(hit.MouseEnter, function() hovered = true; paint() end)
    r:Connect(hit.MouseLeave, function() hovered = false; paint() end)
    r:Connect(hit.SelectionGained, function() hovered = true; paint() end)
    r:Connect(hit.SelectionLost, function() hovered = false; paint() end)
    r:Connect(hit.Activated, function() if not self.Disabled then self:SetValue(not self:GetValue()) end end)
    return self:Mount(paint, options.OnChanged)
end

return Toggle

end)

__register("Components", "Window", function(script, require)
--!nonstrict
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Window = {}

function Window.new(context, options)
    local r = context.Renderer
    local gui = r:Create('ScreenGui', {
        Name = 'Blossom', ResetOnSpawn = false, DisplayOrder = options.DisplayOrder or 10,
        ZIndexBehavior = Enum.ZIndexBehavior.Global, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
    }, options.Parent)
    context.Gui = gui
    context.Cleanup:Add(function() gui:Destroy() end)
    local viewport = r:Create('Frame', {Name = 'Viewport', Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, gui)
    context.Viewport = viewport
    local root = r:Create('Frame', {
        Name = 'Window', Size = UDim2.fromOffset(options.Width, options.Height),
        Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        Active = true, ClipsDescendants = false,
    }, viewport, {BackgroundColor3 = 'Background'})
    context.Root = root
    context.Scale = r:Create('UIScale', {Scale = options.Scale}, root)
    r:Corner(root, Tokens.Radius)
    r:Stroke(root)
    local gradient = r:Create('UIGradient', {Name = 'WindowGradient', Rotation = 90}, root)
    context.Theme:Subscribe(context.Cleanup, function()
        gradient.Color = ColorSequence.new(context.Theme:Get('Background'), context.Theme:Get('Tab'))
    end)
    local shadow = r:Create('Frame', {
        Name = 'Shadow', Position = UDim2.fromOffset(-3, 3), Size = UDim2.new(1, 6, 1, 3),
        ZIndex = 9, BackgroundTransparency = 0.65,
    }, root, {BackgroundColor3 = 'Shadow'})
    r:Corner(shadow, Tokens.Radius + 2)
    local content = r:Create('Frame', {
        Name = 'Content', BackgroundTransparency = 1,
        Position = UDim2.fromOffset(Tokens.Sidebar + Tokens.Gutter, Tokens.Gutter),
        Size = UDim2.new(1, -Tokens.Sidebar - Tokens.Gutter * 2, 1, -Tokens.Gutter * 2),
    }, root)
    context.Content = content
    context.OverlayLayer = r:Create('Frame', {
        Name = 'OverlayLayer', BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 30,
    }, root)

    -- Keep the entire window on large viewports, and its drag handle reachable on small ones.
    local function clampCenter(center)
        local viewSize, size = viewport.AbsoluteSize, root.AbsoluteSize
        local x = if size.X <= viewSize.X then math.clamp(center.X, size.X / 2, viewSize.X - size.X / 2) else size.X / 2
        local y = if size.Y <= viewSize.Y then math.clamp(center.Y, size.Y / 2, viewSize.Y - size.Y / 2) else size.Y / 2
        root.Position = UDim2.fromOffset(x, y)
    end
    context.ClampWindow = function()
        if viewport.AbsoluteSize.X <= 0 then return end
        clampCenter(root.AbsolutePosition - viewport.AbsolutePosition + root.AbsoluteSize / 2)
    end
    r:Connect(viewport:GetPropertyChangedSignal('AbsoluteSize'), function()
        context.Input:Cancel()
        if context.Overlay then context.Overlay:Close() end
        context.ClampWindow()
    end)
    context.BeginWindowDrag = function(input)
        local start = Vector2.new(input.Position.X, input.Position.Y)
        local center = root.AbsolutePosition - viewport.AbsolutePosition + root.AbsoluteSize / 2
        context.Input:Begin(input, function(point)
            if context.Overlay then context.Overlay:Close() end
            clampCenter(center + point - start)
        end)
    end
    return root
end

return Window

end)

local function __init(script, require)
--!nonstrict
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')
local Cleanup = require(script.Core.Cleanup)
local Store = require(script.Core.Store)
local Value = require(script.Core.Value)
local Renderer = require(script.Core.Renderer)
local ThemeManager = require(script.Core.ThemeManager)
local InputManager = require(script.Core.InputManager)
local OverlayManager = require(script.Core.OverlayManager)
local ModalManager = require(script.Core.ModalManager)
local LayoutManager = require(script.Core.LayoutManager)
local KeybindManager = require(script.Core.KeybindManager)
local ColorAnimator = require(script.Core.ColorAnimator)
local ProfileStore = require(script.Core.ProfileStore)
local Presets = require(script.Themes.Presets)
local SearchDialog = require(script.Components.SearchDialog)
local Tokens = require(script.Themes.Tokens)
local Window = require(script.Components.Window)
local Sidebar = require(script.Components.Sidebar)
local Page = require(script.Components.Page)

local Blossom = {}
Blossom.__index = Blossom

local function slug(value)
    local id = string.lower(tostring(value or 'control')):gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return id ~= '' and id or 'control'
end

local function option(options, lower, upper, fallback)
    if options[lower] ~= nil then return options[lower] end
    if options[upper] ~= nil then return options[upper] end
    return fallback
end

local function safeCallback(callback, ...)
    local ok, problem = pcall(callback, ...)
    if not ok then warn('[Blossom callback] ' .. tostring(problem)) end
end

local function elementOptions(options, kind)
    local name = option(options, 'name', 'Name', kind)
    local result = table.clone(options)
    result.Id = option(options, 'flag', 'Flag', slug(name))
    result.Label = name
    result.Default = option(options, 'value', 'Value', option(options, 'default', 'Default', nil))
    result.OnChanged = option(options, 'callback', 'Callback', option(options, 'onChanged', 'OnChanged', nil))
    return result
end

local function pageAdapter(page)
    local adapter = {Raw = page}
    local function scoped(options, kind)
        local result = elementOptions(options, kind)
        if options.flag == nil and options.Flag == nil then result.Id = page.Id .. '_' .. result.Id end
        return result
    end
    function adapter:CreateSection(options)
        options = options or {}
        local section = page:AddSection({
            Id = slug(option(options, 'name', 'Name', 'section')),
            Title = option(options, 'name', 'Name', 'Section'),
            Column = option(options, 'column', 'Column', 1),
            Description = option(options, 'description', 'Description', nil),
            Collapsible = option(options, 'collapsible', 'Collapsible', false),
            Collapsed = option(options, 'collapsed', 'Collapsed', false),
        })
        self._section = section
        return section
    end
    function adapter:CreateToggle(options) return self._section:AddToggle(scoped(options, 'Toggle')) end
    function adapter:CreateSlider(options)
        local result = scoped(options, 'Slider')
        local range = option(options, 'range', 'Range', {0, 100})
        result.Minimum, result.Maximum = range[1], range[2]
        result.Step = option(options, 'increment', 'Increment', 1)
        result.Unit = option(options, 'suffix', 'Suffix', '')
        return self._section:AddSlider(result)
    end
    function adapter:CreateDropdown(options)
        local result = scoped(options, 'Dropdown')
        result.Options = option(options, 'options', 'Options', {})
        result.Multi = option(options, 'multiSelect', 'MultiSelect', false) or option(options, 'multi', 'Multi', false)
        result.Default = option(options, 'value', 'Value', if result.Multi then {} else result.Options[1])
        return self._section:AddDropdown(result)
    end
    function adapter:CreateButton(options)
        local result = scoped(options, 'Button')
        return self._section:AddButton({
            Id = result.Id,
            Label = option(options, 'name', 'Name', 'Button'),
            OnClick = option(options, 'callback', 'Callback', nil),
        })
    end
    function adapter:CreateInput(options) return self._section:AddTextInput(scoped(options, 'Input')) end
    function adapter:CreateKeybind(options)
        local result = scoped(options, 'Keybind')
        local value = option(options, 'value', 'Value', 'None')
        local key = if typeof(value) == 'EnumItem' then value.Name else tostring(value)
        if key == 'Unknown' then key = 'None' end
        result.Default = {
            Key = key,
            Mode = option(options, 'hold', 'Hold', false) and 'hold' or 'toggle',
        }
        result.OnTriggered = option(options, 'callback', 'Callback', nil)
        return self._section:AddKeybind(result)
    end
    function adapter:CreateColorPicker(options)
        local color = option(options, 'color', 'Color', Color3.fromRGB(116, 169, 227))
        local result = scoped(options, 'ColorPicker')
        result.Default = {R = color.R, G = color.G, B = color.B, Alpha = 1, Animation = 'None'}
        local callback = result.OnChanged
        if callback then
            result.OnChanged = function(value)
                if type(value) == 'table' and value.R and value.G and value.B then
                    safeCallback(callback, Color3.new(value.R, value.G, value.B))
                else
                    safeCallback(callback, value)
                end
            end
        end
        return self._section:AddColorPicker(result)
    end
    function adapter:CreateList(options)
        local result = scoped(options, 'ListBox')
        result.Options = option(options, 'options', 'Options', {})
        return self._section:AddListBox(result)
    end
    return adapter
end

function Blossom.new(options)
    options = table.clone(options or {})
    options.Title = options.Title or 'Blossom'
    Value.id(options.Title)
    options.Scale = options.Scale or 1
    Value.finite(options.Scale)
    assert(options.Scale >= 0.5 and options.Scale <= 3, 'Scale must be between 0.5 and 3')
    local size = options.Size or UDim2.fromOffset(Tokens.Width, Tokens.Height)
    assert(typeof(size) == 'UDim2' and size.X.Scale == 0 and size.Y.Scale == 0, 'Size must use pixel offsets')
    options.Width, options.Height = Value.finite(size.X.Offset), Value.finite(size.Y.Offset)
    assert(options.Width >= 360 and options.Height >= 260, 'Minimum window size is 360 x 260')
    local theme = options.Theme
    if type(theme) == 'string' and theme ~= 'Blossom' and table.find(Presets.Names, theme) then
        options.Theme = Presets.Get(theme)
    end
    assert(options.Theme == nil or options.Theme == 'Blossom' or type(options.Theme) == 'table', 'Only Blossom preset, known presets, or token overrides are available')
    assert(options.ReducedMotion == nil or type(options.ReducedMotion) == 'boolean', 'ReducedMotion must be boolean')
    if options.DisplayOrder ~= nil then Value.finite(options.DisplayOrder) end
    if options.Parent == nil then
        assert(Players.LocalPlayer, 'Blossom.new must run on a client')
        options.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')
    end
    assert(typeof(options.Parent) == 'Instance' and options.Parent:IsA('PlayerGui'), 'Parent must be PlayerGui')
    local cleanup = Cleanup.new()
    local context = {Cleanup = cleanup, Store = Store.new(), Theme = ThemeManager.new(), Registry = {}, Pages = {}, Destroyed = false}
    if type(options.Theme) == 'table' then context.Theme:Set(options.Theme) end
    cleanup:Add(function() context.Theme:Destroy(); context.Store:Destroy() end)
    context.Renderer = Renderer.new(context.Theme, cleanup, options.ReducedMotion or false)
    context.Input = InputManager.new(context.Renderer)
    local self = setmetatable({_context = context}, Blossom)
    context.Library = self
    Window.new(context, options)
    context.Overlay = OverlayManager.new(context, context.OverlayLayer)
    context.Modal = ModalManager.new(context)
    context.Layout = LayoutManager.new(context)
    context.Keys = KeybindManager.new(context)
    context.Animations = ColorAnimator.new(context)
    context.Profiles = ProfileStore.new(options.SaveProfile)
    context.Search = {Open = function() SearchDialog.Open(context) end}
    context.Sidebar = Sidebar.new(context, options.Title)
    return self
end

-- Rayfield-style public facade. The explicit AddPage/AddSection API remains available.
function Blossom:CreateWindow(options)
    options = options or {}
    local theme = option(options, 'theme', 'Theme', 'Blossom')
    local window = Blossom.new({
        Title = option(options, 'name', 'Name', 'Blossom'),
        Size = options.Size,
        Scale = options.Scale or 1,
        Theme = if theme == 'default' then 'Blossom' else theme,
        ReducedMotion = options.ReducedMotion,
        Parent = options.Parent,
        SaveProfile = options.SaveProfile,
    })
    window.Subtitle = option(options, 'subtitle', 'Subtitle', '')
    window.Configuration = option(options, 'configuration', 'Configuration', nil)
    function window:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        local page = self:AddPage({Id = option(tabOptions, 'flag', 'Flag', slug(option(tabOptions, 'name', 'Name', 'tab'))), Title = option(tabOptions, 'name', 'Name', 'Tab'), Group = option(tabOptions, 'group', 'Group', '')})
        local adapter = pageAdapter(page)
        function adapter:CreateSection(sectionOptions)
            sectionOptions = sectionOptions or {}
            local section = page:AddSection({Id = slug(option(sectionOptions, 'name', 'Name', 'section')), Title = option(sectionOptions, 'name', 'Name', 'Section'), Column = option(sectionOptions, 'column', 'Column', 1), Description = option(sectionOptions, 'description', 'Description', nil), Collapsible = option(sectionOptions, 'collapsible', 'Collapsible', false), Collapsed = option(sectionOptions, 'collapsed', 'Collapsed', false)})
            self._section = section
            return section
        end
        function adapter:UseSection(section) self._section = section; return self end
        function adapter:CreateGroup() return self end
        return adapter
    end
    function window:CreateSection(options)
        return {Name = option(options or {}, 'name', 'Name', 'Section')}
    end
    function window:ChangeTheme(value) if value == 'default' then value = 'Blossom' end; self:SetThemePreset(value) end
    function window:Save(name)
        name = name or 'Default'
        if table.find(self:ListProfiles(), name) then self:OverwriteProfile(name) else self:CreateProfile(name) end
    end
    function window:Load(name) self:LoadProfile(name or 'Default') end
    function window:ListConfigs() return self:ListProfiles() end
    function window:DeleteConfig(name) self:DeleteProfile(name) end
    function window:Navigate(id) self:SelectPage(id) end
    function window:Notify(data) warn('[Blossom notification] ' .. tostring(data and (data.title or data.Title) or 'Notification') .. ': ' .. tostring(data and (data.content or data.Content) or '')) end
    return window
end

function Blossom:AddPage(options)
    local context = self._context
    assert(not context.Destroyed, 'Library destroyed')
    Value.id(options.Id)
    Value.id(options.Title)
    assert(options.Group == nil or type(options.Group) == 'string', 'Group must be string')
    assert(not context.Pages[options.Id], 'Duplicate page Id: ' .. options.Id)
    local page = Page.new(context, options)
    context.Pages[page.Id] = page
    context.Sidebar:AddPage(page, options.Group or '')
    if not context.CurrentPage then self:SelectPage(page.Id) end
    return page
end

function Blossom:_ReleaseFocus()
    local context = self._context
    local focused = UserInputService:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(context.Root) then focused:ReleaseFocus(false) end
    local selected = GuiService.SelectedObject
    if selected and selected:IsDescendantOf(context.Root) then GuiService.SelectedObject = nil end
end

function Blossom:SelectPage(id)
    local context = self._context
    assert(not context.Destroyed and context.Pages[id], 'Unknown page or destroyed library')
    if context.CurrentPage == id then return end
    self:_ReleaseFocus()
    context.Input:Cancel()
    context.Overlay:Close()
    local previous = context.CurrentPage and context.Pages[context.CurrentPage]
    context.CurrentPage = id
    local nextPage = context.Pages[id]
    local function show(page, visible, transparency)
        if not page then return end
        page.Frame.Visible = visible
        page.Floating.Visible = visible
        context.Renderer:Tween(page.Frame, {GroupTransparency = transparency}, visible and Tokens.PageFadeIn or Tokens.PageFadeOut)
    end
    if previous and previous ~= nextPage then
        show(previous, true, 1)
        task.delay(context.Renderer.ReducedMotion and 0 or Tokens.PageFadeOut, function()
            if not context.Destroyed and context.CurrentPage == id then show(previous, false, 1) end
        end)
    end
    for pageId, page in pairs(context.Pages) do
        if page ~= previous and page ~= nextPage then show(page, false, 1) end
    end
    show(nextPage, true, 1)
    task.delay(context.Renderer.ReducedMotion and 0 or Tokens.PageFadeIn, function()
        if not context.Destroyed and context.CurrentPage == id then show(nextPage, true, 0) end
    end)
    context.Sidebar:Refresh()
end

function Blossom:GetValue(id) return self._context.Store:Get(id) end
function Blossom:SetValue(id, value) return self._context.Store:Set(id, value) end
function Blossom:GetValues() return self._context.Store:Snapshot() end

function Blossom:GetControls()
    local controls = {}
    for _, control in pairs(self._context.Registry) do table.insert(controls, control.Metadata) end
    table.sort(controls, function(a, b) return a.Id < b.Id end)
    return controls
end

function Blossom:GetControl(id)
    assert(self._context.Registry[id], 'Unknown control: ' .. tostring(id))
    return self._context.Registry[id]
end

function Blossom:RevealControl(id)
    local control = self:GetControl(id)
    local page = control.Section.Page
    self:SelectPage(page.Id)
    if not control.Section.Detached then
        local column = page.Columns[control.Section.Column]
        column.CanvasPosition = Vector2.new(0, math.max(0, control.Frame.AbsolutePosition.Y - column.AbsolutePosition.Y - 28))
    end
    local frame = control.Frame
    local original = frame.BackgroundTransparency
    frame.BackgroundTransparency = 0.05
    frame.BackgroundColor3 = self._context.Theme:Get('Accent')
    task.delay(0.35, function()
        if not self._context.Destroyed and frame.Parent then
            frame.BackgroundTransparency = original
            frame.BackgroundColor3 = self._context.Theme:Get('Tab')
        end
    end)
end

function Blossom:SetThemePreset(name)
    assert(table.find(Presets.Names, name), 'Unknown theme preset: ' .. tostring(name))
    self._context.ActiveTheme = name
    self:SetTheme(Presets.Get(name))
end
function Blossom:GetThemePresets() return table.clone(Presets.Names) end
function Blossom:_SnapshotProfile()
    return {Version = 1, Controls = self:GetValues(), Layout = self._context.Layout:Snapshot(), Page = self._context.CurrentPage, Theme = self._context.ActiveTheme or 'Blossom'}
end
function Blossom:CreateProfile(name) self._context.Profiles:Put(name, self:_SnapshotProfile()) end
function Blossom:OverwriteProfile(name) self._context.Profiles:Put(name, self:_SnapshotProfile(), true) end
function Blossom:DeleteProfile(name) self._context.Profiles:Delete(name) end
function Blossom:ListProfiles() return self._context.Profiles:Names() end
function Blossom:LoadProfile(name)
    local profile = self._context.Profiles:Get(name)
    for id, value in pairs(profile.Controls or {}) do if self._context.Registry[id] and self._context.Registry[id].hasValue then self:SetValue(id, value) end end
    if profile.Layout then self._context.Layout:Apply(profile.Layout) end
    if profile.Page and self._context.Pages[profile.Page] then self:SelectPage(profile.Page) end
    if profile.Theme and table.find(Presets.Names, profile.Theme) then self:SetThemePreset(profile.Theme) end
end
function Blossom:SetAutoloadProfile(name) self._context.Profiles:SetAutoload(name) end
function Blossom:ExportProfiles() return game:GetService('HttpService'):JSONEncode(self._context.Profiles.data) end
function Blossom:ImportProfiles(json)
    local document = game:GetService('HttpService'):JSONDecode(json)
    self._context.Profiles:Replace(document, function(snapshot) assert(type(snapshot) == 'table' and snapshot.Version == 1, 'Invalid profile snapshot') end)
end

function Blossom:SetTheme(overrides)
    local context = self._context
    assert(not context.Destroyed, 'Library destroyed')
    context.Overlay:Close()
    context.Modal:Close()
    context.Renderer:CancelTweens()
    context.Theme:Set(overrides)
end

function Blossom:SetScale(scale)
    local context = self._context
    assert(not context.Destroyed, 'Library destroyed')
    Value.finite(scale)
    assert(scale >= 0.5 and scale <= 3, 'Scale must be between 0.5 and 3')
    context.Input:Cancel()
    context.Overlay:Close()
    context.Scale.Scale = scale
    context.ClampWindow()
end

function Blossom:SetVisible(visible)
    local context = self._context
    assert(not context.Destroyed, 'Library destroyed')
    Value.boolean(visible)
    if not visible then
        self:_ReleaseFocus()
        context.Input:Cancel()
        context.Overlay:Close()
    end
    context.Root.Visible = visible
end

function Blossom:Destroy()
    local context = self._context
    if context.Destroyed then return end
    context.Destroyed = true
    self:_ReleaseFocus()
    context.Input:Cancel()
    context.Overlay:Close()
    context.Renderer:CancelTweens()
    context.Cleanup:Destroy()
    table.clear(context.Registry)
    table.clear(context.Pages)
end

return Blossom
end

return __init(__root, __require)
