--!nonstrict
local Tokens = require(script.Parent.Parent.Themes.Tokens)
local Toggle = require(script.Parent.Toggle)
local Slider = require(script.Parent.Slider)
local RangeSlider = require(script.Parent.RangeSlider)
local Dropdown = require(script.Parent.Dropdown)
local Button = require(script.Parent.Button)
local TextInput = require(script.Parent.TextInput)
local Keybind = require(script.Parent.Keybind)
local ColorPicker = require(script.Parent.ColorPicker)
local ListBox = require(script.Parent.ListBox)
local Section = {}
Section.__index = Section

function Section.new(context, page, options, parent, order)
    local r = context.Renderer
    local frame = r:Create('Frame', {
        Name = 'Section_' .. options.Id, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order,
    }, parent, {BackgroundColor3 = 'Tab'})
    r:Corner(frame, Tokens.CardRadius)
    local gradient = r:Create('UIGradient', {Name = 'SurfaceGradient', Rotation = 90}, frame)
    context.Theme:Subscribe(context.Cleanup, function()
        gradient.Color = ColorSequence.new(context.Theme:Get('Tab'), context.Theme:Get('Section'))
    end)
    r:List(frame, 0)
    local header = r:Create('TextButton', {Name = 'Header', Text = '', Size = UDim2.new(1, 0, 0, Tokens.SectionHeader), BackgroundTransparency = 1, LayoutOrder = 0}, frame)
    local icon = r:Create('Frame', {Name = 'Icon', Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(5, 5)}, header, {BackgroundColor3 = 'Accent'})
    r:Corner(icon, 5)
    r:Label(header, options.Title, {Position = UDim2.fromOffset(19, 0), Size = UDim2.new(1, -26, 1, 0), Font = Enum.Font.GothamMedium})
    r:Create('Frame', {Name = 'Rule', Position = UDim2.new(0, 7, 1, -1), Size = UDim2.new(1, -14, 0, 1)}, header, {BackgroundColor3 = 'Inline'})
    if options.Description and options.Description ~= '' then
        r:Label(frame, options.Description, {Name = 'Description', Position = UDim2.fromOffset(19, Tokens.SectionHeader), Size = UDim2.new(1, -26, 0, 14), TextSize = Tokens.SmallText}, 'InactiveText')
    end
    local body = r:Create('Frame', {Name = 'Body', Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1}, frame)
    r:Padding(body, 6)
    r:List(body, Tokens.ControlGap)
    local self = setmetatable({Id = options.Id, Title = options.Title, Page = page, Frame = frame, Body = body, Column = options.Column or 1, Order = order, context = context, count = 0}, Section)
    r:Connect(header.InputBegan, function(input) context.Layout:Begin(self, input) end)
    r:Connect(header.Activated, function(input)
        if input and input.UserInputType == Enum.UserInputType.Gamepad1 then self:MoveTo(self.Column == 1 and 2 or 1) end
    end)
    r:Connect(header.MouseButton2Click, function() self:MoveTo(self.Column == 1 and 2 or 1) end)
    return self
end

function Section:AddToggle(options) return Toggle.new(self.context, self, options) end
function Section:AddSlider(options) return Slider.new(self.context, self, options) end
function Section:AddRangeSlider(options) return RangeSlider.new(self.context, self, options) end
function Section:AddDropdown(options) return Dropdown.new(self.context, self, options) end
function Section:AddButton(options) return Button.new(self.context, self, options) end
function Section:AddTextInput(options) return TextInput.new(self.context, self, options) end
function Section:AddKeybind(options) return Keybind.new(self.context, self, options) end
function Section:AddColorPicker(options) return ColorPicker.new(self.context, self, options) end
function Section:AddListBox(options) return ListBox.new(self.context, self, options) end
function Section:MoveTo(column, order) self.context.Layout:Cancel(); self.context.Layout:Move(self, column, order) end
function Section:Detach(x, y) self.context.Layout:Cancel(); self.context.Layout:Detach(self, x, y, self.Frame.AbsoluteSize.X / self.context.Scale.Scale) end

return Section
