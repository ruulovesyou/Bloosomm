--!strict
local Value = {}

function Value.finite(value: any): number
    assert(type(value) == 'number' and value == value and math.abs(value) < math.huge, 'Expected finite number')
    return value
end

function Value.id(value: any): string
    assert(type(value) == 'string' and #value > 0, 'Expected nonempty Id')
    return value
end

function Value.boolean(value: any): boolean
    assert(type(value) == 'boolean', 'Expected boolean')
    return value
end

function Value.slider(minimum: number, maximum: number, step: number): (any) -> number
    Value.finite(minimum)
    Value.finite(maximum)
    Value.finite(step)
    assert(maximum > minimum and step > 0, 'Slider requires Maximum > Minimum and Step > 0')
    Value.finite(maximum - minimum)
    Value.finite((maximum - minimum) / step)
    return function(value: any): number
        local bounded = math.clamp(Value.finite(value), minimum, maximum)
        if bounded == maximum then return maximum end
        local snapped = minimum + math.floor((bounded - minimum) / step + 0.5) * step
        return math.clamp(snapped, minimum, maximum)
    end
end

function Value.dropdown(options: {string}): (any) -> string
    assert(type(options) == 'table' and #options > 0, 'Dropdown requires options')
    local members: {[string]: boolean} = {}
    local count = 0
    for index in pairs(options) do
        assert(type(index) == 'number' and index % 1 == 0 and index >= 1 and index <= #options, 'Options must be a dense array')
        count += 1
    end
    assert(count == #options, 'Options must be a dense array')
    for _, option in ipairs(options) do
        Value.id(option)
        assert(not members[option], 'Duplicate dropdown option: ' .. option)
        members[option] = true
    end
    return function(value: any): string
        assert(type(value) == 'string' and members[value], 'Unknown dropdown option')
        return value
    end
end

function Value.multiselect(options: {string}): (any) -> {string}
    local single = Value.dropdown(options)
    local members = {}
    for _, option in ipairs(options) do members[option] = true end
    return function(value: any): {string}
        assert(type(value) == 'table', 'Expected a selection table')
        local result: {string} = {}
        local seen = {}
        for _, item in ipairs(value) do
            local itemName = item :: string
            single(itemName)
            assert(not seen[itemName], 'Duplicate selection option')
            seen[itemName] = true
            table.insert(result, itemName)
        end
        table.sort(result, function(a, b)
            local ia = table.find(options, a) :: number
            local ib = table.find(options, b) :: number
            return ia < ib
        end)
        return result
    end
end

function Value.text(maxLength: number): (any) -> string
    Value.finite(maxLength)
    assert(maxLength >= 0 and maxLength % 1 == 0, 'MaxLength must be a nonnegative integer')
    return function(value: any): string
        assert(type(value) == 'string', 'Expected string')
        local length = utf8.len(value)
        assert(length ~= nil, 'Expected valid UTF-8')
        if length <= maxLength then return value end
        local boundary = utf8.offset(value, maxLength + 1)
        return string.sub(value, 1, (boundary :: number) - 1)
    end
end

return Value
