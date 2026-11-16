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
local Tokens = require(script.Themes.Tokens)
local Window = require(script.Components.Window)
local Sidebar = require(script.Components.Sidebar)
local Page = require(script.Components.Page)

local Blossom = {}
Blossom.__index = Blossom

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
    assert(options.Theme == nil or options.Theme == 'Blossom' or type(options.Theme) == 'table', 'Only Blossom preset or token overrides are available')
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
    context.Sidebar = Sidebar.new(context, options.Title)
    return self
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
    context.CurrentPage = id
    for pageId, page in pairs(context.Pages) do page.Frame.Visible = pageId == id end
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

function Blossom:SetTheme(overrides)
    local context = self._context
    assert(not context.Destroyed, 'Library destroyed')
    context.Overlay:Close()
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
