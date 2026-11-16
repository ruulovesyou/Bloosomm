--!nonstrict
local UserInputService = game:GetService('UserInputService')
local InputManager = {}
InputManager.__index = InputManager

function InputManager.new(renderer)
    local self = setmetatable({active = nil}, InputManager)
    renderer:Connect(UserInputService.InputChanged, function(input)
        local active = self.active
        if active and (input == active.input or (active.mouse and input.UserInputType == Enum.UserInputType.MouseMovement)) then
            active.move(Vector2.new(input.Position.X, input.Position.Y))
        end
    end)
    renderer:Connect(UserInputService.InputEnded, function(input)
        local active = self.active
        if active and (input == active.input or (active.mouse and input.UserInputType == Enum.UserInputType.MouseButton1)) then self:Cancel() end
    end)
    renderer:Connect(UserInputService.WindowFocusReleased, function() self:Cancel() end)
    renderer.Scope:Add(function() self:Cancel() end)
    return self
end

function InputManager:Begin(input, move, finish)
    local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
    if not mouse and input.UserInputType ~= Enum.UserInputType.Touch then return false end
    self:Cancel()
    self.active = {input = input, mouse = mouse, move = move, finish = finish}
    move(Vector2.new(input.Position.X, input.Position.Y))
    return true
end

function InputManager:Cancel()
    local active = self.active
    self.active = nil
    if active and active.finish then active.finish() end
end

return InputManager
