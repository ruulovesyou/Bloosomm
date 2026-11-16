--!nonstrict
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Value = require(script.Parent.Parent.Core.Value)
local Section = require(script.Parent.Section)
local Page = {}
Page.__index = Page

function Page.new(context, options)
    local r = context.Renderer
    local frame = r:Create('Frame', {
        Name = 'Page_' .. options.Id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false,
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
    return setmetatable({Id = options.Id, Title = options.Title, Frame = frame, Columns = columns, Sections = {}, context = context, count = 0}, Page)
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
