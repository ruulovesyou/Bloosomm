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
