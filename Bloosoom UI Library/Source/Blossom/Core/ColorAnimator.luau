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
