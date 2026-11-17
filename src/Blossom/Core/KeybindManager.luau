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
