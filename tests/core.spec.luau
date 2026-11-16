-- Run with the official Luau CLI from the repository root.
local Value = require('../src/Blossom/Core/Value')
local Store = require('../src/Blossom/Core/Store')
local Cleanup = require('../src/Blossom/Core/Cleanup')
local count = 0
local function test(name, callback)
    callback()
    count += 1
    print('PASS ' .. name)
end
local function rejects(callback)
    assert(not pcall(callback), 'Expected invalid input to be rejected')
end

test('slider snaps relative to minimum and reaches both bounds', function()
    local normalize = Value.slider(-1, 1, 0.3)
    assert(normalize(-100) == -1)
    assert(normalize(100) == 1)
    assert(math.abs(normalize(0) - (-0.1)) < 1e-9)
    rejects(function() normalize(0 / 0) end)
    rejects(function() normalize(math.huge) end)
    rejects(function() Value.slider(2, 1, 1) end)
    rejects(function() Value.slider(0, 1, 0) end)
    rejects(function() Value.slider(-1e308, 1e308, 1) end)
    rejects(function() Value.slider(0, 1, 1e-320) end)
end)

test('dropdown validates unique options and membership', function()
    local options = {'Near', 'Far'}
    local normalize = Value.dropdown(options)
    options[1] = 'Mutated'
    assert(normalize('Near') == 'Near')
    rejects(function() normalize('Unknown') end)
    rejects(function() Value.dropdown({}) end)
    rejects(function() Value.dropdown({'A', 'A'}) end)
    rejects(function() Value.dropdown({[1] = 'A', Extra = 'B'}) end)
    rejects(function() Value.dropdown({[1] = 'A', [3] = 'C'}) end)
end)

test('text limit preserves complete UTF-8 characters', function()
    local normalize = Value.text(3)
    assert(normalize('abcde') == 'abc')
    assert(normalize('a🌸bc') == 'a🌸b')
    rejects(function() normalize(5) end)
    rejects(function() Value.text(-1) end)
end)

test('store retains canonical values and suppresses duplicate callbacks', function()
    local store = Store.new()
    store:Register('enabled', false, Value.boolean, {Label = 'Enabled', Type = 'Toggle'})
    local changes = 0
    local disconnect = store:Subscribe('enabled', function(value)
        changes += 1
        assert(value == true)
    end)
    store:Set('enabled', true)
    store:Set('enabled', true)
    assert(changes == 1 and store:Get('enabled') == true)
    local snapshot = store:Snapshot()
    snapshot.enabled = false
    assert(store:Get('enabled') == true)
    disconnect()
    store:Set('enabled', false)
    assert(changes == 1)
    rejects(function() store:Set('enabled', 'yes') end)
    rejects(function() store:Register('enabled', false, Value.boolean, {}) end)
    rejects(function() store:Get('missing') end)
    store:Destroy()
    rejects(function() store:Set('enabled', true) end)
end)

test('store supports safe unsubscribe during delivery', function()
    local store = Store.new()
    store:Register('value', 0, Value.slider(0, 10, 1), {})
    local unsubscribe
    local calls = 0
    unsubscribe = store:Subscribe('value', function()
        calls += 1
        unsubscribe()
    end)
    store:Set('value', 1)
    store:Set('value', 2)
    assert(calls == 1)
    store:Destroy()
end)

test('reentrant updates do not deliver stale values to remaining listeners', function()
    local store = Store.new()
    store:Register('value', 0, Value.slider(0, 10, 1), {})
    store:Subscribe('value', function(value)
        if value == 1 then store:Set('value', 2) end
    end)
    local delivered = {}
    store:Subscribe('value', function(value) table.insert(delivered, value) end)
    store:Set('value', 1)
    assert(store:Get('value') == 2)
    assert(#delivered == 1 and delivered[1] == 2)
    store:Destroy()
end)

test('callback errors do not block remaining subscribers', function()
    local store = Store.new()
    store:Register('value', false, Value.boolean, {})
    store:Subscribe('value', function() error('intentional test error') end)
    local delivered = false
    store:Subscribe('value', function() delivered = true end)
    store:Set('value', true)
    assert(delivered)
    store:Destroy()
end)

test('cleanup runs in reverse once and immediately disposes late resources', function()
    local cleanup = Cleanup.new()
    local order = {}
    cleanup:Add(function() table.insert(order, 1) end)
    cleanup:Add(function() table.insert(order, 2) end)
    cleanup:Destroy()
    cleanup:Destroy()
    cleanup:Add(function() table.insert(order, 3) end)
    assert(table.concat(order, ',') == '2,1,3')
end)

print(string.format('%d core tests passed', count))
