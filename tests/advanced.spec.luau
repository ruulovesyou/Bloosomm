local Records = require('../src/Blossom/Core/Records')
local ProfileStore = require('../src/Blossom/Core/ProfileStore')
local Value = require('../src/Blossom/Core/Value')
local count = 0
local function test(name, callback) callback(); count += 1; print('PASS ' .. name) end
local function rejects(callback) assert(not pcall(callback)) end

test('search is literal, contextual, multiword and deterministic', function()
    local items = {
        {Id = 'b', Label = 'Speed Amount', PageTitle = 'Movement', SectionTitle = 'Movement', Type = 'Slider'},
        {Id = 'a', Label = 'Speed', PageTitle = 'Movement', SectionTitle = 'Movement', Type = 'Toggle'},
    }
    assert(#Records.Search(items, '   ') == 0)
    assert(Records.Search(items, 'SPEED')[1].Id == 'a')
    assert(#Records.Search(items, 'movement slider') == 1)
    assert(#Records.Search(items, '.*') == 0)
end)
test('structured values validate and compare without aliasing', function()
    local color = Records.Color({R = 1, G = 0, B = 0, Alpha = 0.5})
    local copy = Records.Copy(color)
    assert(Records.Equal(copy, color))
    copy.R = 0
    assert(color.R == 1 and not Records.Equal(copy, color))
    rejects(function() Records.Color({R = 0/0, G = 0, B = 0}) end)
    rejects(function() Records.Color({R = 1, G = 0, B = 0, Animation = 'Bad'}) end)
    assert(Records.Keybind({Key = 'F', Mode = 'hold'}).Mode == 'hold')
    rejects(function() Records.Keybind({Key = 'F', Mode = 'bad'}) end)
end)
test('multi-select and range values normalize deterministically', function()
    local select = Value.multiselect({'Head', 'Torso', 'Arms'})
    local selected = select({'Arms', 'Head'})
    assert(selected[1] == 'Head' and selected[2] == 'Arms')
    rejects(function() select({'Head', 'Head'}) end)
    local range = Value.slider(20, 80, 5)
    assert(range(22) == 20 and range(78) == 80)
end)
test('profiles create/load/overwrite/delete and isolate snapshots', function()
    local profiles = ProfileStore.new()
    local snapshot = {Version = 1, Controls = {a = true}}
    profiles:Put('A', snapshot)
    snapshot.Controls.a = false
    assert(profiles:Get('A').Controls.a)
    rejects(function() profiles:Put('A', snapshot) end)
    profiles:Put('A', snapshot, true)
    assert(not profiles:Get('A').Controls.a)
    profiles:SetAutoload('A')
    profiles:Delete('A')
    assert(profiles.data.Autoload == '' and #profiles:Names() == 0)
end)
test('failed storage writes and invalid imports preserve profiles', function()
    local profiles = ProfileStore.new(function() error('disk unavailable') end)
    rejects(function() profiles:Put('A', {Version = 1}) end)
    assert(#profiles:Names() == 0)
    profiles = ProfileStore.new()
    profiles:Put('Keep', {Version = 1})
    rejects(function() profiles:Replace({Version = 1, Profiles = {Bad = {Version = 2}}, Autoload = ''}, function(value) assert(value.Version == 1) end) end)
    assert(profiles:Get('Keep').Version == 1)
end)
print(count .. ' advanced tests passed')
