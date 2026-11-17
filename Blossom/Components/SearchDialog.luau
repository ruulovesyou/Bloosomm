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
