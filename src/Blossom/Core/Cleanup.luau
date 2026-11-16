--!strict
local Cleanup = {}
Cleanup.__index = Cleanup

function Cleanup.new()
    return setmetatable({tasks = {} :: {() -> ()}, destroyed = false}, Cleanup)
end

function Cleanup:Add(dispose: () -> ())
    if self.destroyed then
        dispose()
    else
        table.insert(self.tasks, dispose)
    end
    return dispose
end

function Cleanup:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    for index = #self.tasks, 1, -1 do
        local ok, problem = pcall(self.tasks[index])
        if not ok then print('[Blossom cleanup] ' .. tostring(problem)) end
    end
    table.clear(self.tasks)
end

return Cleanup
