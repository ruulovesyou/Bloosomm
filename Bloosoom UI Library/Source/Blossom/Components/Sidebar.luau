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
