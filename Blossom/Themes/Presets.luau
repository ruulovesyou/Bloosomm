--!nonstrict
-- Approximate recreations. Only preset names and broad appearances are observed.
local Blossom = require(script.Parent.Blossom)
local Presets = {Names = {'Blossom', 'Afterglow', 'Frostbite', 'Volt', 'Obsidian', 'Sakura Drift', 'Neon Mirage', 'Copper Dust', 'Abyss', 'Porcelain'}}
local accents = {
    ['Blossom'] = '74A9E3', ['Afterglow'] = 'E79B80', ['Frostbite'] = '8DD8E8', ['Volt'] = '97E650',
    ['Obsidian'] = 'ADADBB', ['Sakura Drift'] = 'E6A2BF', ['Neon Mirage'] = 'BE8CFF', ['Copper Dust'] = 'D99A69',
    ['Abyss'] = '579CE2', ['Porcelain'] = '397ABF',
}
local surfaces = {['Afterglow'] = '282125', ['Frostbite'] = '1C252C', ['Volt'] = '151D17', ['Obsidian'] = '171719', ['Sakura Drift'] = '29222C', ['Neon Mirage'] = '201D2D', ['Copper Dust'] = '29231F', ['Abyss'] = '151E2B'}
function Presets.Get(name)
    assert(accents[name], 'Unknown theme preset: ' .. tostring(name))
    local colors = table.clone(Blossom)
    colors.Accent = Color3.fromHex(accents[name])
    if surfaces[name] then
        local base = Color3.fromHex(surfaces[name])
        colors.Background = base
        colors.Sidebar = base:Lerp(Color3.new(), 0.1)
        colors.Tab = base:Lerp(Color3.new(1, 1, 1), 0.035)
        colors.Section = base:Lerp(Color3.new(1, 1, 1), 0.055)
        colors.Input = colors.Tab
        colors.Element = base:Lerp(Color3.new(1, 1, 1), 0.09)
        colors.HoveredElement = base:Lerp(Color3.new(1, 1, 1), 0.14)
    elseif name == 'Porcelain' then
        colors.Background = Color3.fromHex('F3F4F6'); colors.Sidebar = Color3.fromHex('E9ECF0')
        colors.Tab = Color3.fromHex('FAFBFC'); colors.Section = Color3.fromHex('FFFFFF'); colors.Input = Color3.fromHex('E8EBEF')
        colors.Outline = Color3.fromHex('BCC3CD'); colors.Inline = Color3.fromHex('D5DAE1')
        colors.Text = Color3.fromHex('202733'); colors.InactiveText = Color3.fromHex('586270')
        colors.Element = Color3.fromHex('CAD2DD'); colors.HoveredElement = Color3.fromHex('DDE5EE')
        colors.Gradient = Color3.fromHex('FFFFFF')
    end
    return colors
end
return Presets
