local UILibrary = {}
UILibrary.__index = UILibrary

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local COLORS = {
    Background = Color3.fromRGB(20, 20, 20),
    Sidebar = Color3.fromRGB(15, 15, 15),
    Panel = Color3.fromRGB(25, 25, 25),
    PanelDark = Color3.fromRGB(18, 18, 18),
    Border = Color3.fromRGB(40, 40, 40),
    Text = Color3.fromRGB(200, 200, 200),
    TextDim = Color3.fromRGB(120, 120, 120),
    Accent = Color3.fromRGB(150, 255, 100),
    AccentDim = Color3.fromRGB(100, 200, 70),
    Red = Color3.fromRGB(255, 100, 100),
    Blue = Color3.fromRGB(100, 150, 255),
    Purple = Color3.fromRGB(200, 100, 255),
    Orange = Color3.fromRGB(255, 180, 100),
    Yellow = Color3.fromRGB(255, 255, 100),
    White = Color3.fromRGB(255, 255, 255),
}

function UILibrary.new(title)
    local self = setmetatable({}, UILibrary)
    
    self.Title = title or "Menu"
    self.Tabs = {}
    self.CurrentTab = nil
    self.Visible = true
    self.AccentColor = COLORS.Accent
    
    self:CreateUI()
    
    return self
end

function UILibrary:CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CheatMenu"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")
    
    self.ScreenGui = ScreenGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 800, 0, 700)
    MainFrame.Position = UDim2.new(0.5, -400, 0.5, -350)
    MainFrame.BackgroundColor3 = COLORS.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    self.MainFrame = MainFrame
    
    local TopBorder = Instance.new("Frame")
    TopBorder.Name = "TopBorder"
    TopBorder.Size = UDim2.new(1, 0, 0, 2)
    TopBorder.BackgroundColor3 = self.AccentColor
    TopBorder.BorderSizePixel = 0
    TopBorder.Parent = MainFrame
    
    self.TopBorder = TopBorder
    
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 100, 1, -2)
    Sidebar.Position = UDim2.new(0, 0, 0, 2)
    Sidebar.BackgroundColor3 = COLORS.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    
    self.Sidebar = Sidebar
    
    local SidebarList = Instance.new("UIListLayout")
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Padding = UDim.new(0, 0)
    SidebarList.Parent = Sidebar
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -100, 1, -2)
    ContentFrame.Position = UDim2.new(0, 100, 0, 2)
    ContentFrame.BackgroundColor3 = COLORS.Background
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame
    
    self.ContentFrame = ContentFrame
    
    self:MakeDraggable(MainFrame)
    self:SetupToggleKey()
end

function UILibrary:MakeDraggable(frame)
    local dragging = false
    local dragInput, mousePos, framePos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
end

function UILibrary:SetupToggleKey()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
            self:Toggle()
        end
    end)
end

function UILibrary:Toggle()
    self.Visible = not self.Visible
    self.MainFrame.Visible = self.Visible
end

function UILibrary:SetAccentColor(color)
    self.AccentColor = color
    self.TopBorder.BackgroundColor3 = color
    
    for _, tab in pairs(self.Tabs) do
        if tab.Selected then
            tab.Button.BackgroundColor3 = color
        end
    end
end

function UILibrary:CreateTab(name, icon)
    local tab = {
        Name = name,
        Icon = icon,
        Sections = {},
        Selected = false,
        Library = self
    }
    
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 100)
    Button.BackgroundColor3 = COLORS.Sidebar
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = self.Sidebar
    
    tab.Button = Button
    
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Name = "Icon"
    IconLabel.Size = UDim2.new(0, 50, 0, 50)
    IconLabel.Position = UDim2.new(0.5, -25, 0.5, -25)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = icon or "?"
    IconLabel.TextColor3 = COLORS.TextDim
    IconLabel.TextSize = 32
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.Parent = Button
    
    tab.IconLabel = IconLabel
    
    local ContentContainer = Instance.new("ScrollingFrame")
    ContentContainer.Name = name .. "Content"
    ContentContainer.Size = UDim2.new(1, 0, 1, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.BorderSizePixel = 0
    ContentContainer.ScrollBarThickness = 4
    ContentContainer.ScrollBarImageColor3 = COLORS.Border
    ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentContainer.Visible = false
    ContentContainer.Parent = self.ContentFrame
    
    tab.ContentContainer = ContentContainer
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 10)
    ContentLayout.Parent = ContentContainer
    
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    ContentPadding.Parent = ContentContainer
    
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentContainer.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    Button.MouseEnter:Connect(function()
        if not tab.Selected then
            IconLabel.TextColor3 = COLORS.Text
        end
    end)
    
    Button.MouseLeave:Connect(function()
        if not tab.Selected then
            IconLabel.TextColor3 = COLORS.TextDim
        end
    end)
    
    table.insert(self.Tabs, tab)
    
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    return setmetatable(tab, {__index = self:GetTabMethods()})
end

function UILibrary:SelectTab(tab)
    for _, t in pairs(self.Tabs) do
        t.Selected = false
        t.Button.BackgroundColor3 = COLORS.Sidebar
        t.IconLabel.TextColor3 = COLORS.TextDim
        t.ContentContainer.Visible = false
    end
    
    tab.Selected = true
    tab.Button.BackgroundColor3 = self.AccentColor
    tab.IconLabel.TextColor3 = COLORS.Text
    tab.ContentContainer.Visible = true
    
    self.CurrentTab = tab
end

function UILibrary:GetTabMethods()
    local methods = {}
    
    function methods:CreateSection(name)
        local section = {
            Name = name,
            Elements = {},
            Tab = self
        }
        
        local SectionFrame = Instance.new("Frame")
        SectionFrame.Name = name
        SectionFrame.Size = UDim2.new(1, -10, 0, 0)
        SectionFrame.BackgroundColor3 = COLORS.Panel
        SectionFrame.BorderSizePixel = 0
        SectionFrame.Parent = self.ContentContainer
        
        section.Frame = SectionFrame
        
        local SectionTitle = Instance.new("TextLabel")
        SectionTitle.Name = "Title"
        SectionTitle.Size = UDim2.new(1, -20, 0, 30)
        SectionTitle.Position = UDim2.new(0, 10, 0, 10)
        SectionTitle.BackgroundTransparency = 1
        SectionTitle.Text = name
        SectionTitle.TextColor3 = COLORS.Text
        SectionTitle.TextSize = 14
        SectionTitle.Font = Enum.Font.GothamBold
        SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        SectionTitle.Parent = SectionFrame
        
        local ElementContainer = Instance.new("Frame")
        ElementContainer.Name = "Elements"
        ElementContainer.Size = UDim2.new(1, -20, 1, -50)
        ElementContainer.Position = UDim2.new(0, 10, 0, 40)
        ElementContainer.BackgroundTransparency = 1
        ElementContainer.Parent = SectionFrame
        
        section.ElementContainer = ElementContainer
        
        local ElementLayout = Instance.new("UIListLayout")
        ElementLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ElementLayout.Padding = UDim.new(0, 5)
        ElementLayout.Parent = ElementContainer
        
        ElementLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            SectionFrame.Size = UDim2.new(1, -10, 0, ElementLayout.AbsoluteContentSize.Y + 60)
        end)
        
        table.insert(self.Sections, section)
        
        return setmetatable(section, {__index = self.Tab.Library:GetSectionMethods()})
    end
    
    return methods
end

function UILibrary:GetSectionMethods()
    local methods = {}
    
    function methods:CreateCheckbox(name, default, callback)
        local checkbox = {
            Name = name,
            Value = default or false,
            Callback = callback or function() end
        }
        
        local CheckboxFrame = Instance.new("Frame")
        CheckboxFrame.Name = name
        CheckboxFrame.Size = UDim2.new(1, 0, 0, 20)
        CheckboxFrame.BackgroundTransparency = 1
        CheckboxFrame.Parent = self.ElementContainer
        
        local CheckboxButton = Instance.new("TextButton")
        CheckboxButton.Name = "Checkbox"
        CheckboxButton.Size = UDim2.new(0, 14, 0, 14)
        CheckboxButton.Position = UDim2.new(0, 0, 0, 3)
        CheckboxButton.BackgroundColor3 = COLORS.PanelDark
        CheckboxButton.BorderColor3 = COLORS.Border
        CheckboxButton.BorderSizePixel = 1
        CheckboxButton.Text = ""
        CheckboxButton.AutoButtonColor = false
        CheckboxButton.Parent = CheckboxFrame
        
        local CheckboxInner = Instance.new("Frame")
        CheckboxInner.Name = "Inner"
        CheckboxInner.Size = UDim2.new(1, -4, 1, -4)
        CheckboxInner.Position = UDim2.new(0, 2, 0, 2)
        CheckboxInner.BackgroundColor3 = self.Tab.Library.AccentColor
        CheckboxInner.BorderSizePixel = 0
        CheckboxInner.Visible = checkbox.Value
        CheckboxInner.Parent = CheckboxButton
        
        local CheckboxLabel = Instance.new("TextLabel")
        CheckboxLabel.Name = "Label"
        CheckboxLabel.Size = UDim2.new(1, -20, 1, 0)
        CheckboxLabel.Position = UDim2.new(0, 20, 0, 0)
        CheckboxLabel.BackgroundTransparency = 1
        CheckboxLabel.Text = name
        CheckboxLabel.TextColor3 = COLORS.Text
        CheckboxLabel.TextSize = 12
        CheckboxLabel.Font = Enum.Font.Gotham
        CheckboxLabel.TextXAlignment = Enum.TextXAlignment.Left
        CheckboxLabel.Parent = CheckboxFrame
        
        CheckboxButton.MouseButton1Click:Connect(function()
            checkbox.Value = not checkbox.Value
            CheckboxInner.Visible = checkbox.Value
            checkbox.Callback(checkbox.Value)
        end)
        
        checkbox.Frame = CheckboxFrame
        checkbox.Button = CheckboxButton
        checkbox.Inner = CheckboxInner
        
        function checkbox:SetValue(value)
            self.Value = value
            CheckboxInner.Visible = value
            self.Callback(value)
        end
        
        table.insert(self.Elements, checkbox)
        return checkbox
    end
    
    function methods:CreateSlider(name, min, max, default, increment, callback)
        local slider = {
            Name = name,
            Min = min or 0,
            Max = max or 100,
            Value = default or min or 0,
            Increment = increment or 1,
            Callback = callback or function() end
        }
        
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Name = name
        SliderFrame.Size = UDim2.new(1, 0, 0, 35)
        SliderFrame.BackgroundTransparency = 1
        SliderFrame.Parent = self.ElementContainer
        
        local SliderLabel = Instance.new("TextLabel")
        SliderLabel.Name = "Label"
        SliderLabel.Size = UDim2.new(1, -50, 0, 15)
        SliderLabel.BackgroundTransparency = 1
        SliderLabel.Text = name
        SliderLabel.TextColor3 = COLORS.Text
        SliderLabel.TextSize = 12
        SliderLabel.Font = Enum.Font.Gotham
        SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
        SliderLabel.Parent = SliderFrame
        
        local SliderValue = Instance.new("TextLabel")
        SliderValue.Name = "Value"
        SliderValue.Size = UDim2.new(0, 50, 0, 15)
        SliderValue.Position = UDim2.new(1, -50, 0, 0)
        SliderValue.BackgroundTransparency = 1
        SliderValue.Text = tostring(slider.Value)
        SliderValue.TextColor3 = self.Tab.Library.AccentColor
        SliderValue.TextSize = 12
        SliderValue.Font = Enum.Font.GothamBold
        SliderValue.TextXAlignment = Enum.TextXAlignment.Right
        SliderValue.Parent = SliderFrame
        
        local SliderBar = Instance.new("Frame")
        SliderBar.Name = "Bar"
        SliderBar.Size = UDim2.new(1, 0, 0, 4)
        SliderBar.Position = UDim2.new(0, 0, 0, 20)
        SliderBar.BackgroundColor3 = COLORS.PanelDark
        SliderBar.BorderSizePixel = 0
        SliderBar.Parent = SliderFrame
        
        local SliderFill = Instance.new("Frame")
        SliderFill.Name = "Fill"
        SliderFill.Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
        SliderFill.BackgroundColor3 = self.Tab.Library.AccentColor
        SliderFill.BorderSizePixel = 0
        SliderFill.Parent = SliderBar
        
        local SliderButton = Instance.new("TextButton")
        SliderButton.Name = "Button"
        SliderButton.Size = UDim2.new(1, 0, 0, 10)
        SliderButton.Position = UDim2.new(0, 0, 0, 17)
        SliderButton.BackgroundTransparency = 1
        SliderButton.Text = ""
        SliderButton.Parent = SliderFrame
        
        local dragging = false
        
        local function updateSlider(input)
            local pos = (input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X
            pos = math.clamp(pos, 0, 1)
            
            local value = slider.Min + (slider.Max - slider.Min) * pos
            value = math.floor(value / slider.Increment + 0.5) * slider.Increment
            value = math.clamp(value, slider.Min, slider.Max)
            
            slider.Value = value
            SliderValue.Text = tostring(value)
            SliderFill.Size = UDim2.new((value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
            
            slider.Callback(value)
        end
        
        SliderButton.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
        
        SliderButton.MouseButton1Click:Connect(function(input)
            updateSlider(input)
        end)
        
        slider.Frame = SliderFrame
        slider.Fill = SliderFill
        slider.ValueLabel = SliderValue
        
        function slider:SetValue(value)
            value = math.clamp(value, self.Min, self.Max)
            value = math.floor(value / self.Increment + 0.5) * self.Increment
            
            self.Value = value
            SliderValue.Text = tostring(value)
            SliderFill.Size = UDim2.new((value - self.Min) / (self.Max - self.Min), 0, 1, 0)
            self.Callback(value)
        end
        
        table.insert(self.Elements, slider)
        return slider
    end
    
    function methods:CreateDropdown(name, options, default, callback)
        local dropdown = {
            Name = name,
            Options = options or {},
            Value = default or (options and options[1]) or "",
            Callback = callback or function() end,
            Open = false
        }
        
        local DropdownFrame = Instance.new("Frame")
        DropdownFrame.Name = name
        DropdownFrame.Size = UDim2.new(1, 0, 0, 25)
        DropdownFrame.BackgroundTransparency = 1
        DropdownFrame.ClipsDescendants = false
        DropdownFrame.ZIndex = 2
        DropdownFrame.Parent = self.ElementContainer
        
        local DropdownButton = Instance.new("TextButton")
        DropdownButton.Name = "Button"
        DropdownButton.Size = UDim2.new(1, 0, 0, 25)
        DropdownButton.BackgroundColor3 = COLORS.PanelDark
        DropdownButton.BorderSizePixel = 0
        DropdownButton.Text = ""
        DropdownButton.AutoButtonColor = false
        DropdownButton.ZIndex = 2
        DropdownButton.Parent = DropdownFrame
        
        local DropdownLabel = Instance.new("TextLabel")
        DropdownLabel.Name = "Label"
        DropdownLabel.Size = UDim2.new(1, -30, 1, 0)
        DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
        DropdownLabel.BackgroundTransparency = 1
        DropdownLabel.Text = dropdown.Value
        DropdownLabel.TextColor3 = COLORS.Text
        DropdownLabel.TextSize = 12
        DropdownLabel.Font = Enum.Font.Gotham
        DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
        DropdownLabel.ZIndex = 2
        DropdownLabel.Parent = DropdownButton
        
        local DropdownArrow = Instance.new("TextLabel")
        DropdownArrow.Name = "Arrow"
        DropdownArrow.Size = UDim2.new(0, 20, 1, 0)
        DropdownArrow.Position = UDim2.new(1, -25, 0, 0)
        DropdownArrow.BackgroundTransparency = 1
        DropdownArrow.Text = "▼"
        DropdownArrow.TextColor3 = COLORS.TextDim
        DropdownArrow.TextSize = 10
        DropdownArrow.Font = Enum.Font.Gotham
        DropdownArrow.ZIndex = 2
        DropdownArrow.Parent = DropdownButton
        
        local DropdownList = Instance.new("Frame")
        DropdownList.Name = "List"
        DropdownList.Size = UDim2.new(1, 0, 0, 0)
        DropdownList.Position = UDim2.new(0, 0, 0, 25)
        DropdownList.BackgroundColor3 = COLORS.PanelDark
        DropdownList.BorderSizePixel = 0
        DropdownList.Visible = false
        DropdownList.ZIndex = 3
        DropdownList.Parent = DropdownFrame
        
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = DropdownList
        
        for _, option in ipairs(dropdown.Options) do
            local OptionButton = Instance.new("TextButton")
            OptionButton.Name = option
            OptionButton.Size = UDim2.new(1, 0, 0, 25)
            OptionButton.BackgroundColor3 = COLORS.PanelDark
            OptionButton.BorderSizePixel = 0
            OptionButton.Text = option
            OptionButton.TextColor3 = COLORS.Text
            OptionButton.TextSize = 12
            OptionButton.Font = Enum.Font.Gotham
            OptionButton.AutoButtonColor = false
            OptionButton.ZIndex = 3
            OptionButton.Parent = DropdownList
            
            OptionButton.MouseEnter:Connect(function()
                OptionButton.BackgroundColor3 = COLORS.Panel
            end)
            
            OptionButton.MouseLeave:Connect(function()
                OptionButton.BackgroundColor3 = COLORS.PanelDark
            end)
            
            OptionButton.MouseButton1Click:Connect(function()
                dropdown.Value = option
                DropdownLabel.Text = option
                dropdown.Open = false
                DropdownList.Visible = false
                DropdownArrow.Text = "▼"
                DropdownFrame.Size = UDim2.new(1, 0, 0, 25)
                dropdown.Callback(option)
            end)
        end
        
        DropdownButton.MouseButton1Click:Connect(function()
            dropdown.Open = not dropdown.Open
            DropdownList.Visible = dropdown.Open
            DropdownArrow.Text = dropdown.Open and "▲" or "▼"
            
            if dropdown.Open then
                DropdownList.Size = UDim2.new(1, 0, 0, #dropdown.Options * 25)
                DropdownFrame.Size = UDim2.new(1, 0, 0, 25 + #dropdown.Options * 25)
            else
                DropdownFrame.Size = UDim2.new(1, 0, 0, 25)
            end
        end)
        
        dropdown.Frame = DropdownFrame
        dropdown.Label = DropdownLabel
        
        function dropdown:SetValue(value)
            self.Value = value
            DropdownLabel.Text = value
            self.Callback(value)
        end
        
        table.insert(self.Elements, dropdown)
        return dropdown
    end
    
    function methods:CreateButton(name, callback)
        local button = {
            Name = name,
            Callback = callback or function() end
        }
        
        local ButtonFrame = Instance.new("TextButton")
        ButtonFrame.Name = name
        ButtonFrame.Size = UDim2.new(1, 0, 0, 30)
        ButtonFrame.BackgroundColor3 = COLORS.PanelDark
        ButtonFrame.BorderSizePixel = 0
        ButtonFrame.Text = name
        ButtonFrame.TextColor3 = COLORS.Text
        ButtonFrame.TextSize = 12
        ButtonFrame.Font = Enum.Font.GothamBold
        ButtonFrame.AutoButtonColor = false
        ButtonFrame.Parent = self.ElementContainer
        
        ButtonFrame.MouseEnter:Connect(function()
            ButtonFrame.BackgroundColor3 = COLORS.Panel
        end)
        
        ButtonFrame.MouseLeave:Connect(function()
            ButtonFrame.BackgroundColor3 = COLORS.PanelDark
        end)
        
        ButtonFrame.MouseButton1Click:Connect(function()
            button.Callback()
        end)
        
        button.Frame = ButtonFrame
        
        table.insert(self.Elements, button)
        return button
    end
    
    function methods:CreateTextbox(name, placeholder, callback)
        local textbox = {
            Name = name,
            Value = "",
            Callback = callback or function() end
        }
        
        local TextboxFrame = Instance.new("Frame")
        TextboxFrame.Name = name
        TextboxFrame.Size = UDim2.new(1, 0, 0, 25)
        TextboxFrame.BackgroundTransparency = 1
        TextboxFrame.Parent = self.ElementContainer
        
        local TextboxInput = Instance.new("TextBox")
        TextboxInput.Name = "Input"
        TextboxInput.Size = UDim2.new(1, 0, 1, 0)
        TextboxInput.BackgroundColor3 = COLORS.PanelDark
        TextboxInput.BorderSizePixel = 0
        TextboxInput.Text = ""
        TextboxInput.PlaceholderText = placeholder or name
        TextboxInput.TextColor3 = COLORS.Text
        TextboxInput.PlaceholderColor3 = COLORS.TextDim
        TextboxInput.TextSize = 12
        TextboxInput.Font = Enum.Font.Gotham
        TextboxInput.ClearTextOnFocus = false
        TextboxInput.Parent = TextboxFrame
        
        local TextboxPadding = Instance.new("UIPadding")
        TextboxPadding.PaddingLeft = UDim.new(0, 10)
        TextboxPadding.PaddingRight = UDim.new(0, 10)
        TextboxPadding.Parent = TextboxInput
        
        TextboxInput.FocusLost:Connect(function()
            textbox.Value = TextboxInput.Text
            textbox.Callback(TextboxInput.Text)
        end)
        
        textbox.Frame = TextboxFrame
        textbox.Input = TextboxInput
        
        function textbox:SetValue(value)
            self.Value = value
            TextboxInput.Text = value
            self.Callback(value)
        end
        
        table.insert(self.Elements, textbox)
        return textbox
    end
    
    function methods:CreateColorPicker(name, default, callback)
        local colorpicker = {
            Name = name,
            Color = default or Color3.fromRGB(255, 255, 255),
            Callback = callback or function() end
        }
        
        local PickerFrame = Instance.new("Frame")
        PickerFrame.Name = name
        PickerFrame.Size = UDim2.new(1, 0, 0, 20)
        PickerFrame.BackgroundTransparency = 1
        PickerFrame.Parent = self.ElementContainer
        
        local PickerLabel = Instance.new("TextLabel")
        PickerLabel.Name = "Label"
        PickerLabel.Size = UDim2.new(1, -30, 1, 0)
        PickerLabel.BackgroundTransparency = 1
        PickerLabel.Text = name
        PickerLabel.TextColor3 = COLORS.Text
        PickerLabel.TextSize = 12
        PickerLabel.Font = Enum.Font.Gotham
        PickerLabel.TextXAlignment = Enum.TextXAlignment.Left
        PickerLabel.Parent = PickerFrame
        
        local ColorDisplay = Instance.new("TextButton")
        ColorDisplay.Name = "Display"
        ColorDisplay.Size = UDim2.new(0, 20, 0, 20)
        ColorDisplay.Position = UDim2.new(1, -20, 0, 0)
        ColorDisplay.BackgroundColor3 = colorpicker.Color
        ColorDisplay.BorderColor3 = COLORS.Border
        ColorDisplay.BorderSizePixel = 1
        ColorDisplay.Text = ""
        ColorDisplay.Parent = PickerFrame
        
        ColorDisplay.MouseButton1Click:Connect(function()
        end)
        
        colorpicker.Frame = PickerFrame
        colorpicker.Display = ColorDisplay
        
        function colorpicker:SetColor(color)
            self.Color = color
            ColorDisplay.BackgroundColor3 = color
            self.Callback(color)
        end
        
        table.insert(self.Elements, colorpicker)
        return colorpicker
    end
    
    function methods:CreateLabel(text)
        local label = {
            Text = text
        }
        
        local LabelFrame = Instance.new("TextLabel")
        LabelFrame.Name = "Label"
        LabelFrame.Size = UDim2.new(1, 0, 0, 20)
        LabelFrame.BackgroundTransparency = 1
        LabelFrame.Text = text
        LabelFrame.TextColor3 = COLORS.TextDim
        LabelFrame.TextSize = 12
        LabelFrame.Font = Enum.Font.Gotham
        LabelFrame.TextXAlignment = Enum.TextXAlignment.Left
        LabelFrame.Parent = self.ElementContainer
        
        label.Frame = LabelFrame
        
        function label:SetText(text)
            self.Text = text
            LabelFrame.Text = text
        end
        
        table.insert(self.Elements, label)
        return label
    end
    
    return methods
end

return UILibrary
