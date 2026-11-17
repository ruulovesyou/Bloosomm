--!strict
local Records = {}

function Records.Copy(value: any): any
    if type(value) ~= 'table' then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = Records.Copy(child) end
    return copy
end

function Records.Equal(a: any, b: any): boolean
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    for key, value in pairs(a) do if not Records.Equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local function unit(value: any): number
    assert(type(value) == 'number' and value == value and value >= 0 and value <= 1, 'Color channels must be in [0,1]')
    return value
end

function Records.Color(value: any): any
    assert(type(value) == 'table', 'Color value must be a table')
    local animation = value.Animation or 'None'
    assert(table.find({'None', 'Rainbow', 'Fade', 'Fade Alpha'}, animation), 'Unknown color animation')
    return table.freeze({R = unit(value.R), G = unit(value.G), B = unit(value.B), Alpha = unit(value.Alpha == nil and 1 or value.Alpha), Animation = animation})
end

function Records.Keybind(value: any): any
    assert(type(value) == 'table' and type(value.Key) == 'string' and #value.Key <= 32, 'Invalid keybind')
    assert(value.Mode == 'toggle' or value.Mode == 'hold', 'Keybind mode must be toggle or hold')
    return table.freeze({Key = value.Key, Mode = value.Mode})
end

function Records.Search(metadata: {any}, query: string): {any}
    local words = {}
    for word in string.lower(query):gmatch('%S+') do table.insert(words, word) end
    if #words == 0 then return {} end
    local matches = {}
    for _, item in ipairs(metadata) do
        local haystack = string.lower(item.Label .. ' ' .. item.PageTitle .. ' ' .. item.SectionTitle .. ' ' .. item.Type)
        local matchesAll = true
        for _, word in ipairs(words) do
            if not string.find(haystack, word, 1, true) then matchesAll = false; break end
        end
        if matchesAll then table.insert(matches, item) end
    end
    table.sort(matches, function(a: any, b: any)
        if a.Label == b.Label then return a.Id < b.Id end
        return a.Label < b.Label
    end)
    return matches
end

return Records
