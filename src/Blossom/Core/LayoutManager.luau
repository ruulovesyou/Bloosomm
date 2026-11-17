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
