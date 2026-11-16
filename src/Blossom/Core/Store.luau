--!strict
type Listener = {callback: (any) -> (), active: boolean}
type Entry = {value: any, normalize: (any) -> any, metadata: {[string]: any}, listeners: {Listener}}
type StoreData = {entries: {[string]: Entry}, destroyed: boolean}
local Store = {}
Store.__index = Store

function Store.new()
    return setmetatable({entries = {} :: {[string]: Entry}, destroyed = false}, Store)
end

function Store.Register(self: StoreData, id: string, default: any, normalize: (any) -> any, metadata: {[string]: any})
    assert(not self.destroyed, 'Store destroyed')
    assert(type(id) == 'string' and #id > 0 and not self.entries[id], 'Invalid or duplicate control Id: ' .. tostring(id))
    self.entries[id] = {value = normalize(default), normalize = normalize, metadata = table.freeze(table.clone(metadata)), listeners = {}}
end

function Store.Get(self: StoreData, id: string): any
    local entry = self.entries[id]
    assert(entry, 'Unknown control: ' .. id)
    return entry.value
end

function Store.Set(self: StoreData, id: string, value: any): boolean
    assert(not self.destroyed, 'Store destroyed')
    local entry = self.entries[id]
    assert(entry, 'Unknown control: ' .. id)
    local normalized = entry.normalize(value)
    if entry.value == normalized then return false end
    entry.value = normalized
    -- A snapshot lets callbacks unsubscribe safely without skipping other listeners.
    for _, listener in ipairs(table.clone(entry.listeners)) do
        if entry.value ~= normalized then break end
        if listener.active then
            local ok, problem = pcall(listener.callback, normalized)
            if not ok then print('[Blossom callback] ' .. tostring(problem)) end
        end
    end
    return true
end

function Store.Subscribe(self: StoreData, id: string, callback: (any) -> ()): () -> ()
    assert(not self.destroyed, 'Store destroyed')
    local entry = self.entries[id]
    assert(entry, 'Unknown control: ' .. id)
    local listener = {callback = callback, active = true}
    table.insert(entry.listeners, listener)
    return function()
        listener.active = false
        local index = table.find(entry.listeners, listener)
        if index then table.remove(entry.listeners, index) end
    end
end

function Store.Snapshot(self: StoreData): {[string]: any}
    local values = {}
    for id, entry in pairs(self.entries) do values[id] = entry.value end
    return values
end

function Store.Destroy(self: StoreData)
    if self.destroyed then return end
    self.destroyed = true
    for _, entry in pairs(self.entries) do
        for _, listener in ipairs(entry.listeners) do listener.active = false end
    end
    table.clear(self.entries)
end

return Store
