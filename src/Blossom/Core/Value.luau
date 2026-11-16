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
