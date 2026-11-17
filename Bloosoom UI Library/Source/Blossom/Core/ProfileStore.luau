--!strict
local ProfileStore = {}
ProfileStore.__index = ProfileStore

local function copy(value: any): any
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function nameCheck(name: any)
    assert(type(name) == 'string', 'Profile name must be a string')
    assert(#name > 0 and #name <= 64 and string.find(name, '%S') and not string.find(name, '%c'), 'Profile name must contain 1–64 printable bytes')
end

function ProfileStore.new(save: ((any) -> ())?)
    return setmetatable({data = {Version = 1, Profiles = {} :: {[string]: any}, Autoload = ''}, save = save}, ProfileStore)
end

function ProfileStore:Commit(candidate)
    if self.save then self.save(copy(candidate)) end
    self.data = candidate
end

function ProfileStore:Put(name: string, snapshot: any, overwrite: boolean?)
    nameCheck(name)
    assert(type(snapshot) == 'table', 'Expected configuration snapshot')
    if overwrite then assert(self.data.Profiles[name], 'Profile does not exist')
    else assert(not self.data.Profiles[name], 'Profile already exists') end
    local candidate = copy(self.data)
    candidate.Profiles[name] = copy(snapshot)
    self:Commit(candidate)
end

function ProfileStore:Get(name: string): any
    assert(self.data.Profiles[name], 'Profile does not exist')
    return copy(self.data.Profiles[name])
end

function ProfileStore:Delete(name: string)
    assert(self.data.Profiles[name], 'Profile does not exist')
    local candidate = copy(self.data)
    candidate.Profiles[name] = nil
    if candidate.Autoload == name then candidate.Autoload = '' end
    self:Commit(candidate)
end

function ProfileStore:SetAutoload(name: string)
    assert(name == '' or self.data.Profiles[name], 'Unknown autoload profile')
    local candidate = copy(self.data)
    candidate.Autoload = name
    self:Commit(candidate)
end

function ProfileStore:Names(): {string}
    local names = {}
    for name in pairs(self.data.Profiles) do table.insert(names, tostring(name)) end
    table.sort(names)
    return names
end

function ProfileStore:Replace(data: any, validate: (any) -> ())
    assert(type(data) == 'table' and data.Version == 1 and type(data.Profiles) == 'table', 'Unsupported profile document')
    local count = 0
    for name, snapshot in pairs(data.Profiles) do
        nameCheck(name)
        validate(snapshot)
        count += 1
        assert(count <= 100, 'At most 100 profiles are supported')
    end
    assert(type(data.Autoload) == 'string' and (data.Autoload == '' or data.Profiles[data.Autoload]), 'Invalid autoload profile')
    self:Commit({Version = 1, Profiles = copy(data.Profiles), Autoload = data.Autoload})
end

return ProfileStore
