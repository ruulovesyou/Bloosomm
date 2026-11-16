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
