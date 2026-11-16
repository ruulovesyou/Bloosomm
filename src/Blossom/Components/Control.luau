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
        Disabled = options.Disabled or false, context = context, hasValue = normalize ~= nil,
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
