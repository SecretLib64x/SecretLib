

local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return game:GetService("CoreGui") end
local protectgui = protectgui or function() end

local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
pcall(protectgui, ScreenGui)

local success = pcall(function()
    ScreenGui.Parent = gethui()
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local SecretLib = {
    Version = "1.0.0",
    Flags = {},
    Connections = {},
    Windows = {},
    Notifications = {},
    Elements = {},
    Dependencies = {},
    ScreenGui = ScreenGui,
    DebounceTimers = {},
    ObjectPool = {},
    Events = {},
    
    Theme = {
        Background = Color3.fromRGB(15, 15, 15),
        Surface = Color3.fromRGB(20, 20, 20),
        SurfaceHover = Color3.fromRGB(25, 25, 25),
        Border = Color3.fromRGB(40, 40, 40),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentHover = Color3.fromRGB(108, 121, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 180, 180),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(237, 66, 69),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
    
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    
    SpringConfig = {
        Default = {Tension = 180, Friction = 20},
        Snappy = {Tension = 300, Friction = 25},
        Smooth = {Tension = 120, Friction = 18},
        Bouncy = {Tension = 200, Friction = 12},
    }
}

return SecretLib

do
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Spring = {}
Spring.__index = Spring

function Spring.new(initialValue, config)
    local self = setmetatable({}, Spring)
    self.Value = initialValue
    self.Target = initialValue
    self.Velocity = 0
    self.Tension = config.Tension or 180
    self.Friction = config.Friction or 20
    return self
end

function Spring:Update(dt)
    local displacement = self.Value - self.Target
    local springForce = -self.Tension * displacement
    local dampingForce = -self.Friction * self.Velocity
    
    local acceleration = springForce + dampingForce
    self.Velocity = self.Velocity + acceleration * dt
    self.Value = self.Value + self.Velocity * dt
    
    if math.abs(self.Velocity) < 0.01 and math.abs(displacement) < 0.01 then
        self.Value = self.Target
        self.Velocity = 0
        return true
    end
    
    return false
end

function Spring:SetTarget(target)
    self.Target = target
end

local AnimationController = {
    Springs = {},
    Active = false
}

function AnimationController:AddSpring(id, spring)
    self.Springs[id] = spring
    if not self.Active then
        self:Start()
    end
end

function AnimationController:RemoveSpring(id)
    self.Springs[id] = nil
    if next(self.Springs) == nil then
        self:Stop()
    end
end

function AnimationController:Start()
    if self.Active then return end
    self.Active = true
    
    local lastTime = tick()
    self.Connection = RunService.RenderStepped:Connect(function()
        local currentTime = tick()
        local dt = math.min(currentTime - lastTime, 0.1)
        lastTime = currentTime
        
        for id, spring in pairs(self.Springs) do
            if spring:Update(dt) then
                self:RemoveSpring(id)
            end
        end
    end)
end

function AnimationController:Stop()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    self.Active = false
end

local Utility = {}

function Utility:Create(class, properties)
    local instance = Instance.new(class)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility:Tween(instance, property, target, config)
    config = config or SecretLib.SpringConfig.Default
    
    local springId = tostring(instance) .. property
    local currentValue = instance[property]
    
    if typeof(currentValue) == "number" then
        local spring = Spring.new(currentValue, config)
        spring:SetTarget(target)
        
        AnimationController:AddSpring(springId, spring)
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if AnimationController.Springs[springId] then
                instance[property] = spring.Value
            else
                conn:Disconnect()
            end
        end)
    elseif typeof(currentValue) == "UDim2" then
        local xSpring = Spring.new(currentValue.X.Scale, config)
        local xOffsetSpring = Spring.new(currentValue.X.Offset, config)
        local ySpring = Spring.new(currentValue.Y.Scale, config)
        local yOffsetSpring = Spring.new(currentValue.Y.Offset, config)
        
        xSpring:SetTarget(target.X.Scale)
        xOffsetSpring:SetTarget(target.X.Offset)
        ySpring:SetTarget(target.Y.Scale)
        yOffsetSpring:SetTarget(target.Y.Offset)
        
        AnimationController:AddSpring(springId .. "X", xSpring)
        AnimationController:AddSpring(springId .. "XOffset", xOffsetSpring)
        AnimationController:AddSpring(springId .. "Y", ySpring)
        AnimationController:AddSpring(springId .. "YOffset", yOffsetSpring)
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if AnimationController.Springs[springId .. "X"] then
                instance[property] = UDim2.new(
                    xSpring.Value, xOffsetSpring.Value,
                    ySpring.Value, yOffsetSpring.Value
                )
            else
                conn:Disconnect()
            end
        end)
    elseif typeof(currentValue) == "Color3" then
        local hStart, sStart, vStart = currentValue:ToHSV()
        local hTarget, sTarget, vTarget = target:ToHSV()
        
        local hSpring = Spring.new(hStart, config)
        local sSpring = Spring.new(sStart, config)
        local vSpring = Spring.new(vStart, config)
        
        hSpring:SetTarget(hTarget)
        sSpring:SetTarget(sTarget)
        vSpring:SetTarget(vTarget)
        
        AnimationController:AddSpring(springId .. "H", hSpring)
        AnimationController:AddSpring(springId .. "S", sSpring)
        AnimationController:AddSpring(springId .. "V", vSpring)
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if AnimationController.Springs[springId .. "H"] then
                instance[property] = Color3.fromHSV(hSpring.Value, sSpring.Value, vSpring.Value)
            else
                conn:Disconnect()
            end
        end)
    end
end

function Utility:GetTextSize(text, fontSize, font, maxWidth)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.Font = font
    params.Size = fontSize
    params.Width = maxWidth or math.huge
    
    return TextService:GetTextBoundsAsync(params)
end

function Utility:MakeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Utility:AddRipple(button)
    button.ClipsDescendants = true
    
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local ripple = Utility:Create("Frame", {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0, input.Position.X - button.AbsolutePosition.X, 0, input.Position.Y - button.AbsolutePosition.Y),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.7,
                BorderSizePixel = 0,
                ZIndex = button.ZIndex + 1,
                Parent = button
            })
            
            Utility:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = ripple
            })
            
            local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
            
            Utility:Tween(ripple, "Size", UDim2.new(0, maxSize, 0, maxSize), SecretLib.SpringConfig.Smooth)
            Utility:Tween(ripple, "BackgroundTransparency", 1, SecretLib.SpringConfig.Smooth)
            
            task.delay(0.6, function()
                ripple:Destroy()
            end)
        end
    end)
end

return Utility

end

do

local Utility = 

local DependencyManager = {}

function DependencyManager:RegisterElement(element, config)
    if not element or not element.Container then return end
    
    local elementId = tostring(element.Container)
    SecretLib.Elements[elementId] = {
        Element = element,
        Visible = true,
        Enabled = true,
        Dependencies = {},
        Dependents = {}
    }
    
    if config.DependsOn then
        self:AddDependency(element, config.DependsOn)
    end
    
    return elementId
end

function DependencyManager:AddDependency(element, dependency)
    local elementId = tostring(element.Container)
    local elementData = SecretLib.Elements[elementId]
    
    if not elementData then return end
    
    if type(dependency) == "table" then
        if dependency.Flag then
            local depConfig = {
                Flag = dependency.Flag,
                Value = dependency.Value,
                Invert = dependency.Invert or false
            }
            table.insert(elementData.Dependencies, depConfig)
            
            if not SecretLib.Dependencies[dependency.Flag] then
                SecretLib.Dependencies[dependency.Flag] = {}
            end
            table.insert(SecretLib.Dependencies[dependency.Flag], elementId)
            
            self:UpdateElementState(elementId)
        end
    elseif type(dependency) == "string" then
        local depConfig = {
            Flag = dependency,
            Value = true,
            Invert = false
        }
        table.insert(elementData.Dependencies, depConfig)
        
        if not SecretLib.Dependencies[dependency] then
            SecretLib.Dependencies[dependency] = {}
        end
        table.insert(SecretLib.Dependencies[dependency], elementId)
        
        self:UpdateElementState(elementId)
    end
end

function DependencyManager:CheckDependencies(elementId)
    local elementData = SecretLib.Elements[elementId]
    if not elementData or #elementData.Dependencies == 0 then
        return true
    end
    
    for _, dep in ipairs(elementData.Dependencies) do
        local flagValue = SecretLib.Flags[dep.Flag]
        local expectedValue = dep.Value
        local invert = dep.Invert
        
        local matches = false
        
        if type(expectedValue) == "boolean" then
            matches = (flagValue == expectedValue)
        elseif type(expectedValue) == "table" then
            if type(flagValue) == "table" then
                for _, val in ipairs(expectedValue) do
                    if flagValue[val] then
                        matches = true
                        break
                    end
                end
            end
        else
            matches = (flagValue == expectedValue)
        end
        
        if invert then
            matches = not matches
        end
        
        if not matches then
            return false
        end
    end
    
    return true
end

function DependencyManager:UpdateElementState(elementId)
    local elementData = SecretLib.Elements[elementId]
    if not elementData then return end
    
    local shouldBeVisible = self:CheckDependencies(elementId)
    
    if shouldBeVisible ~= elementData.Visible then
        elementData.Visible = shouldBeVisible
        
        if shouldBeVisible then
            self:ShowElement(elementData.Element)
        else
            self:HideElement(elementData.Element)
        end
    end
end

function DependencyManager:ShowElement(element)
    if not element or not element.Container then return end
    
    element.Container.Visible = true
    Utility:Tween(element.Container, "BackgroundTransparency", 0, SecretLib.SpringConfig.Snappy)
    
    for _, child in ipairs(element.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            local originalTransparency = 0
            if child:IsA("TextLabel") and child.Name ~= "Label" then
                originalTransparency = 1
            end
            Utility:Tween(child, "TextTransparency", originalTransparency, SecretLib.SpringConfig.Snappy)
        elseif child:IsA("Frame") or child:IsA("ImageLabel") then
            if child.BackgroundTransparency < 1 then
                Utility:Tween(child, "BackgroundTransparency", 0, SecretLib.SpringConfig.Snappy)
            end
        end
    end
end

function DependencyManager:HideElement(element)
    if not element or not element.Container then return end
    
    Utility:Tween(element.Container, "BackgroundTransparency", 0.5, SecretLib.SpringConfig.Snappy)
    
    for _, child in ipairs(element.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            Utility:Tween(child, "TextTransparency", 0.7, SecretLib.SpringConfig.Snappy)
        elseif child:IsA("Frame") or child:IsA("ImageLabel") then
            if child.BackgroundTransparency < 1 then
                Utility:Tween(child, "BackgroundTransparency", 0.7, SecretLib.SpringConfig.Snappy)
            end
        end
    end
    
    if element.Container:FindFirstChildOfClass("TextButton") then
        element.Container:FindFirstChildOfClass("TextButton").Active = false
    end
end

function DependencyManager:OnFlagChanged(flag)
    local dependents = SecretLib.Dependencies[flag]
    if not dependents then return end
    
    for _, elementId in ipairs(dependents) do
        self:UpdateElementState(elementId)
    end
end

function DependencyManager:SetElementVisible(element, visible)
    if not element or not element.Container then return end
    
    local elementId = tostring(element.Container)
    local elementData = SecretLib.Elements[elementId]
    
    if elementData then
        elementData.Visible = visible
        
        if visible then
            self:ShowElement(element)
        else
            self:HideElement(element)
        end
    end
end

return DependencyManager

end

do

local EventSystem = {}

function EventSystem:CreateEvent(eventName)
    if not SecretLib.Events[eventName] then
        SecretLib.Events[eventName] = {
            Listeners = {}
        }
    end
    return SecretLib.Events[eventName]
end

function EventSystem:Connect(eventName, callback)
    local event = self:CreateEvent(eventName)
    local id = tostring(callback)
    event.Listeners[id] = callback
    
    return {
        Disconnect = function()
            event.Listeners[id] = nil
        end
    }
end

function EventSystem:Fire(eventName, ...)
    local event = SecretLib.Events[eventName]
    if not event then return end
    
    for _, callback in pairs(event.Listeners) do
        task.spawn(callback, ...)
    end
end

function EventSystem:Once(eventName, callback)
    local connection
    connection = self:Connect(eventName, function(...)
        callback(...)
        connection:Disconnect()
    end)
    return connection
end

function EventSystem:Wait(eventName)
    local thread = coroutine.running()
    local connection
    
    connection = self:Connect(eventName, function(...)
        connection:Disconnect()
        task.spawn(thread, ...)
    end)
    
    return coroutine.yield()
end

function EventSystem:DisconnectAll(eventName)
    if SecretLib.Events[eventName] then
        SecretLib.Events[eventName].Listeners = {}
    end
end

return EventSystem

end

do

local Performance = {}

function Performance:Debounce(func, delay, key)
    return function(...)
        local args = {...}
        
        if SecretLib.DebounceTimers[key] then
            SecretLib.DebounceTimers[key]:Cancel()
        end
        
        SecretLib.DebounceTimers[key] = task.delay(delay, function()
            func(unpack(args))
            SecretLib.DebounceTimers[key] = nil
        end)
    end
end

function Performance:CreateObjectPool(template, initialSize)
    local pool = {
        Available = {},
        InUse = {},
        Template = template,
        CreateFunc = nil
    }
    
    function pool:Initialize(createFunc)
        self.CreateFunc = createFunc
        for i = 1, initialSize or 5 do
            local obj = createFunc()
            obj.Parent = nil
            table.insert(self.Available, obj)
        end
    end
    
    function pool:Acquire()
        local obj
        if #self.Available > 0 then
            obj = table.remove(self.Available)
        else
            obj = self.CreateFunc()
        end
        table.insert(self.InUse, obj)
        return obj
    end
    
    function pool:Release(obj)
        for i, inUse in ipairs(self.InUse) do
            if inUse == obj then
                table.remove(self.InUse, i)
                obj.Parent = nil
                table.insert(self.Available, obj)
                return
            end
        end
    end
    
    function pool:Clear()
        for _, obj in ipairs(self.Available) do
            obj:Destroy()
        end
        for _, obj in ipairs(self.InUse) do
            obj:Destroy()
        end
        self.Available = {}
        self.InUse = {}
    end
    
    return pool
end

function Performance:OptimizeSpringBatch(springs)
    local RunService = game:GetService("RunService")
    local batchConnection
    
    batchConnection = RunService.RenderStepped:Connect(function(deltaTime)
        local allComplete = true
        
        for id, spring in pairs(springs) do
            if spring and not spring:IsComplete() then
                allComplete = false
                spring:Update(deltaTime)
            end
        end
        
        if allComplete then
            batchConnection:Disconnect()
        end
    end)
    
    return batchConnection
end

return Performance

end

do

local Utility = 
local RunService = game:GetService("RunService")

local VirtualScroll = {}
VirtualScroll.__index = VirtualScroll

function VirtualScroll.new(scrollFrame, config)
    local self = setmetatable({}, VirtualScroll)
    
    self.ScrollFrame = scrollFrame
    self.ItemHeight = config.ItemHeight or 40
    self.ItemSpacing = config.ItemSpacing or 8
    self.Items = config.Items or {}
    self.RenderFunc = config.RenderFunc
    self.BufferSize = config.BufferSize or 3
    
    self.VisibleItems = {}
    self.ItemPool = {}
    self.FirstVisibleIndex = 1
    self.LastVisibleIndex = 1
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = scrollFrame
    })
    
    self:UpdateCanvasSize()
    
    self.ScrollConnection = scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self:UpdateVisibleItems()
    end)
    
    self.ResizeConnection = scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:UpdateVisibleItems()
    end)
    
    self:UpdateVisibleItems()
    
    return self
end

function VirtualScroll:UpdateCanvasSize()
    local totalHeight = (#self.Items * self.ItemHeight) + ((#self.Items - 1) * self.ItemSpacing)
    self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

function VirtualScroll:UpdateVisibleItems()
    local scrollPos = self.ScrollFrame.CanvasPosition.Y
    local viewportHeight = self.ScrollFrame.AbsoluteSize.Y
    
    local startIndex = math.max(1, math.floor(scrollPos / (self.ItemHeight + self.ItemSpacing)) - self.BufferSize + 1)
    local endIndex = math.min(#self.Items, math.ceil((scrollPos + viewportHeight) / (self.ItemHeight + self.ItemSpacing)) + self.BufferSize)
    
    if startIndex == self.FirstVisibleIndex and endIndex == self.LastVisibleIndex then
        return
    end
    
    for i = self.FirstVisibleIndex, self.LastVisibleIndex do
        if i < startIndex or i > endIndex then
            local item = self.VisibleItems[i]
            if item then
                item.Visible = false
                table.insert(self.ItemPool, item)
                self.VisibleItems[i] = nil
            end
        end
    end
    
    for i = startIndex, endIndex do
        if not self.VisibleItems[i] then
            local item = self:GetOrCreateItem(i)
            if item then
                local yPos = (i - 1) * (self.ItemHeight + self.ItemSpacing)
                item.Position = UDim2.new(0, 0, 0, yPos)
                item.Size = UDim2.new(1, 0, 0, self.ItemHeight)
                item.Visible = true
                self.VisibleItems[i] = item
            end
        end
    end
    
    self.FirstVisibleIndex = startIndex
    self.LastVisibleIndex = endIndex
end

function VirtualScroll:GetOrCreateItem(index)
    local data = self.Items[index]
    if not data then return nil end
    
    local item
    if #self.ItemPool > 0 then
        item = table.remove(self.ItemPool)
    else
        item = Utility:Create("Frame", {
            Size = UDim2.new(1, 0, 0, self.ItemHeight),
            BackgroundTransparency = 1,
            Parent = self.Container
        })
    end
    
    if self.RenderFunc then
        self.RenderFunc(item, data, index)
    end
    
    return item
end

function VirtualScroll:SetItems(items)
    self.Items = items
    
    for _, item in pairs(self.VisibleItems) do
        item.Visible = false
        table.insert(self.ItemPool, item)
    end
    self.VisibleItems = {}
    
    self:UpdateCanvasSize()
    self:UpdateVisibleItems()
end

function VirtualScroll:AddItem(data)
    table.insert(self.Items, data)
    self:UpdateCanvasSize()
    self:UpdateVisibleItems()
end

function VirtualScroll:RemoveItem(index)
    table.remove(self.Items, index)
    
    if self.VisibleItems[index] then
        local item = self.VisibleItems[index]
        item.Visible = false
        table.insert(self.ItemPool, item)
        self.VisibleItems[index] = nil
    end
    
    self:UpdateCanvasSize()
    self:UpdateVisibleItems()
end

function VirtualScroll:Clear()
    self.Items = {}
    
    for _, item in pairs(self.VisibleItems) do
        item.Visible = false
        table.insert(self.ItemPool, item)
    end
    self.VisibleItems = {}
    
    self:UpdateCanvasSize()
end

function VirtualScroll:Destroy()
    if self.ScrollConnection then
        self.ScrollConnection:Disconnect()
    end
    
    if self.ResizeConnection then
        self.ResizeConnection:Disconnect()
    end
    
    for _, item in pairs(self.VisibleItems) do
        item:Destroy()
    end
    
    for _, item in ipairs(self.ItemPool) do
        item:Destroy()
    end
    
    if self.Container then
        self.Container:Destroy()
    end
end

return VirtualScroll

end

do

local Utility = 
local HttpService = game:GetService("HttpService")

local NotificationManager = {
    Queue = {},
    Active = {},
    MaxActive = 3,
    Processing = false,
    Position = "BottomRight"
}

function NotificationManager:Show(config)
    config.Priority = config.Priority or 0
    config.Id = HttpService:GenerateGUID(false)
    config.Position = config.Position or self.Position
    
    table.insert(self.Queue, config)
    table.sort(self.Queue, function(a, b)
        return (a.Priority or 0) > (b.Priority or 0)
    end)
    
    if not self.Processing then
        self:ProcessQueue()
    end
end

function NotificationManager:ProcessQueue()
    self.Processing = true
    
    while #self.Queue > 0 do
        while #self.Active >= self.MaxActive do
            task.wait(0.1)
        end
        
        local config = table.remove(self.Queue, 1)
        if config then
            self:CreateNotification(config)
        end
    end
    
    self.Processing = false
end

function NotificationManager:CreateNotification(config)
    local notifId = config.Id
    local position = config.Position or "BottomRight"
    
    local anchorPoint, startPos, targetPos
    
    if position == "TopLeft" then
        anchorPoint = Vector2.new(0, 0)
        startPos = UDim2.new(0, -340, 0, 20)
        targetPos = UDim2.new(0, 20, 0, 20)
    elseif position == "TopRight" then
        anchorPoint = Vector2.new(1, 0)
        startPos = UDim2.new(1, 340, 0, 20)
        targetPos = UDim2.new(1, -20, 0, 20)
    elseif position == "BottomLeft" then
        anchorPoint = Vector2.new(0, 1)
        startPos = UDim2.new(0, -340, 1, -20)
        targetPos = UDim2.new(0, 20, 1, -20)
    else
        anchorPoint = Vector2.new(1, 1)
        startPos = UDim2.new(1, 340, 1, -20)
        targetPos = UDim2.new(1, -20, 1, -20)
    end
    
    local container = Utility:Create("Frame", {
        Size = UDim2.new(0, 320, 0, 0),
        Position = startPos,
        AnchorPoint = anchorPoint,
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1000,
        Parent = SecretLib.ScreenGui
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Parent = container
    })
    
    local accentBar = Utility:Create("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = config.Type == "success" and SecretLib.Theme.Success or
                          config.Type == "warning" and SecretLib.Theme.Warning or
                          config.Type == "error" and SecretLib.Theme.Error or
                          SecretLib.Theme.Accent,
        BorderSizePixel = 0,
        Parent = container
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        Parent = container
    })
    
    local title = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = config.Title or "Notification",
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 14,
        Font = SecretLib.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = container
    })
    
    local message = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = config.Message or "",
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 12,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = container
    })
    
    local textSize = Utility:GetTextSize(config.Message or "", 12, SecretLib.Font, 284)
    message.Size = UDim2.new(1, -20, 0, textSize.Y)
    
    local totalHeight = 12 + 18 + 4 + textSize.Y + 12
    container.Size = UDim2.new(0, 320, 0, totalHeight)
    
    local offset = 20
    for _, notif in pairs(self.Active) do
        if notif and notif.Parent and notif:GetAttribute("Position") == position then
            if position == "TopLeft" or position == "TopRight" then
                offset = offset + notif.AbsoluteSize.Y + 12
            else
                offset = offset + notif.AbsoluteSize.Y + 12
            end
        end
    end
    
    container:SetAttribute("Position", position)
    
    local finalPos
    if position == "TopLeft" then
        container.Position = UDim2.new(0, -340, 0, offset)
        finalPos = UDim2.new(0, 20, 0, offset)
        startPos = UDim2.new(0, -340, 0, offset)
    elseif position == "TopRight" then
        container.Position = UDim2.new(1, 340, 0, offset)
        finalPos = UDim2.new(1, -20, 0, offset)
        startPos = UDim2.new(1, 340, 0, offset)
    elseif position == "BottomLeft" then
        container.Position = UDim2.new(0, -340, 1, -offset)
        finalPos = UDim2.new(0, 20, 1, -offset)
        startPos = UDim2.new(0, -340, 1, -offset)
    else
        container.Position = UDim2.new(1, 340, 1, -offset)
        finalPos = UDim2.new(1, -20, 1, -offset)
        startPos = UDim2.new(1, 340, 1, -offset)
    end
    
    self.Active[notifId] = container
    SecretLib.Notifications[notifId] = container
    
    Utility:Tween(container, "Position", finalPos, SecretLib.SpringConfig.Bouncy)
    
    task.delay(config.Duration or 5, function()
        Utility:Tween(container, "Position", startPos, SecretLib.SpringConfig.Snappy)
        task.wait(0.4)
        container:Destroy()
        self.Active[notifId] = nil
        SecretLib.Notifications[notifId] = nil
    end)
end

return NotificationManager

end

do

local Utility = 

local Modal = {}

function Modal:ShowConfirmation(config)
    local result = nil
    local responded = false
    
    local overlay = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 2000,
        Parent = SecretLib.ScreenGui
    })
    
    local modalContainer = Utility:Create("Frame", {
        Size = UDim2.new(0, 400, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2001,
        Parent = overlay
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = modalContainer
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 2,
        Parent = modalContainer
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 20),
        PaddingTop = UDim.new(0, 20),
        PaddingBottom = UDim.new(0, 20),
        Parent = modalContainer
    })
    
    local title = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = config.Title or "Confirmation",
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 16,
        Font = SecretLib.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 2002,
        Parent = modalContainer
    })
    
    local message = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = config.Message or "Are you sure?",
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 13,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 2002,
        Parent = modalContainer
    })
    
    local textSize = Utility:GetTextSize(config.Message or "Are you sure?", 13, SecretLib.Font, 360)
    message.Size = UDim2.new(1, 0, 0, textSize.Y)
    
    local buttonContainer = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 40 + textSize.Y),
        BackgroundTransparency = 1,
        ZIndex = 2002,
        Parent = modalContainer
    })
    
    local confirmButton = Utility:Create("TextButton", {
        Size = UDim2.new(0.48, 0, 1, 0),
        Position = UDim2.new(0.52, 0, 0, 0),
        BackgroundColor3 = config.ConfirmColor or SecretLib.Theme.Success,
        BorderSizePixel = 0,
        Text = config.ConfirmText or "Confirm",
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.FontBold,
        ZIndex = 2003,
        Parent = buttonContainer
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = confirmButton
    })
    
    Utility:AddRipple(confirmButton)
    
    local cancelButton = Utility:Create("TextButton", {
        Size = UDim2.new(0.48, 0, 1, 0),
        BackgroundColor3 = SecretLib.Theme.Error,
        BorderSizePixel = 0,
        Text = config.CancelText or "Cancel",
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.FontBold,
        ZIndex = 2003,
        Parent = buttonContainer
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = cancelButton
    })
    
    Utility:AddRipple(cancelButton)
    
    local totalHeight = 20 + 24 + 8 + textSize.Y + 8 + 36 + 20
    
    overlay.BackgroundTransparency = 1
    Utility:Tween(overlay, "BackgroundTransparency", 0.5, SecretLib.SpringConfig.Snappy)
    
    Utility:Tween(modalContainer, "Size", UDim2.new(0, 400, 0, totalHeight), SecretLib.SpringConfig.Bouncy)
    
    local function closeModal(response)
        result = response
        responded = true
        
        Utility:Tween(overlay, "BackgroundTransparency", 1, SecretLib.SpringConfig.Snappy)
        Utility:Tween(modalContainer, "Size", UDim2.new(0, 400, 0, 0), SecretLib.SpringConfig.Snappy)
        
        task.delay(0.3, function()
            overlay:Destroy()
        end)
    end
    
    confirmButton.MouseButton1Click:Connect(function()
        if not responded then
            closeModal(true)
            if config.Callback then
                task.spawn(config.Callback, true)
            end
        end
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        if not responded then
            closeModal(false)
            if config.Callback then
                task.spawn(config.Callback, false)
            end
        end
    end)
    
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local containerPos = modalContainer.AbsolutePosition
            local containerSize = modalContainer.AbsoluteSize
            
            if mousePos.X < containerPos.X or mousePos.X > containerPos.X + containerSize.X or
               mousePos.Y < containerPos.Y or mousePos.Y > containerPos.Y + containerSize.Y then
                if not responded then
                    closeModal(false)
                    if config.Callback then
                        task.spawn(config.Callback, false)
                    end
                end
            end
        end
    end)
    
    return result
end

function Modal:ShowLoading(config)
    local overlay = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 2000,
        Parent = SecretLib.ScreenGui
    })
    
    local spinnerContainer = Utility:Create("Frame", {
        Size = UDim2.new(0, 120, 0, 120),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 2001,
        Parent = overlay
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = spinnerContainer
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 2,
        Parent = spinnerContainer
    })
    
    local spinner = Utility:Create("Frame", {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, 0, 0.5, -15),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 2002,
        Parent = spinnerContainer
    })
    
    for i = 1, 8 do
        local dot = Utility:Create("Frame", {
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = SecretLib.Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 2003,
            Parent = spinner
        })
        
        Utility:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = dot
        })
        
        local angle = (i - 1) * (360 / 8)
        local radians = math.rad(angle)
        local x = math.cos(radians) * 15
        local y = math.sin(radians) * 15
        
        dot.Position = UDim2.new(0.5, x, 0.5, y)
        
        task.spawn(function()
            while dot.Parent do
                local delay = (i - 1) * 0.1
                task.wait(delay)
                
                while dot.Parent do
                    Utility:Tween(dot, "BackgroundTransparency", 0.8, SecretLib.SpringConfig.Smooth)
                    task.wait(0.8)
                    if not dot.Parent then break end
                    Utility:Tween(dot, "BackgroundTransparency", 0, SecretLib.SpringConfig.Smooth)
                    task.wait(0.8)
                end
            end
        end)
    end
    
    local label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 1, -30),
        BackgroundTransparency = 1,
        Text = config.Text or "Loading...",
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 12,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 2002,
        Parent = spinnerContainer
    })
    
    overlay.BackgroundTransparency = 1
    Utility:Tween(overlay, "BackgroundTransparency", 0.5, SecretLib.SpringConfig.Snappy)
    
    local loadingModal = {
        Overlay = overlay,
        Label = label
    }
    
    function loadingModal:SetText(text)
        self.Label.Text = text
    end
    
    function loadingModal:Close()
        Utility:Tween(self.Overlay, "BackgroundTransparency", 1, SecretLib.SpringConfig.Snappy)
        task.delay(0.3, function()
            self.Overlay:Destroy()
        end)
    end
    
    return loadingModal
end

return Modal

end

do

local Utility = 
local UserInputService = game:GetService("UserInputService")

local Tooltip = {
    Active = nil,
    Container = nil,
    Label = nil,
    HoverDelay = 0.5,
    CurrentHover = nil,
    HoverStart = 0
}

function Tooltip:Initialize()
    if self.Container then return end
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(0, 200, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 3000,
        Parent = SecretLib.ScreenGui
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Parent = self.Container
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        Parent = self.Container
    })
    
    self.Label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 12,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = self.Container
    })
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if self.Active and self.Container.Visible then
                self:UpdatePosition(input.Position)
            end
        end
    end)
end

function Tooltip:AddToElement(element, text)
    if not element or not element.Container then return end
    
    self:Initialize()
    
    local hoverConnection
    local leaveConnection
    
    hoverConnection = element.Container.MouseEnter:Connect(function()
        self.CurrentHover = text
        self.HoverStart = tick()
        
        task.spawn(function()
            task.wait(self.HoverDelay)
            if self.CurrentHover == text and tick() - self.HoverStart >= self.HoverDelay then
                self:Show(text)
            end
        end)
    end)
    
    leaveConnection = element.Container.MouseLeave:Connect(function()
        if self.CurrentHover == text then
            self.CurrentHover = nil
            self:Hide()
        end
    end)
    
    table.insert(SecretLib.Connections, hoverConnection)
    table.insert(SecretLib.Connections, leaveConnection)
end

function Tooltip:Show(text)
    if not self.Container then return end
    
    self.Active = text
    self.Label.Text = text
    
    local textSize = Utility:GetTextSize(text, 12, SecretLib.Font, 250)
    local width = math.min(math.max(textSize.X + 16, 100), 300)
    local height = textSize.Y + 12
    
    self.Container.Size = UDim2.new(0, width, 0, height)
    
    local mousePos = UserInputService:GetMouseLocation()
    self:UpdatePosition(mousePos)
    
    self.Container.Visible = true
    self.Container.BackgroundTransparency = 1
    self.Label.TextTransparency = 1
    
    Utility:Tween(self.Container, "BackgroundTransparency", 0, SecretLib.SpringConfig.Snappy)
    Utility:Tween(self.Label, "TextTransparency", 0, SecretLib.SpringConfig.Snappy)
end

function Tooltip:Hide()
    if not self.Container then return end
    
    self.Active = nil
    
    Utility:Tween(self.Container, "BackgroundTransparency", 1, SecretLib.SpringConfig.Snappy)
    Utility:Tween(self.Label, "TextTransparency", 1, SecretLib.SpringConfig.Snappy)
    
    task.delay(0.2, function()
        if not self.Active then
            self.Container.Visible = false
        end
    end)
end

function Tooltip:UpdatePosition(mousePos)
    if not self.Container then return end
    
    local screenSize = self.Container.Parent.AbsoluteSize
    local tooltipSize = self.Container.AbsoluteSize
    
    local offsetX = 15
    local offsetY = 15
    
    local x = mousePos.X + offsetX
    local y = mousePos.Y + offsetY
    
    if x + tooltipSize.X > screenSize.X then
        x = mousePos.X - tooltipSize.X - offsetX
    end
    
    if y + tooltipSize.Y > screenSize.Y then
        y = mousePos.Y - tooltipSize.Y - offsetY
    end
    
    x = math.clamp(x, 0, screenSize.X - tooltipSize.X)
    y = math.clamp(y, 0, screenSize.Y - tooltipSize.Y)
    
    self.Container.Position = UDim2.new(0, x, 0, y)
end

return Tooltip

end

do

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager.new(config)
    local self = setmetatable({}, SaveManager)
    
    self.Folder = config.Folder or "SecretLib"
    self.ConfigFolder = config.ConfigFolder or self.Folder
    self.ThemeFolder = config.ThemeFolder or self.Folder
    self.FileName = config.FileName or "config"
    self.IgnoreIndexes = config.IgnoreIndexes or {}
    
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
    
    if not isfolder(self.ConfigFolder) then
        makefolder(self.ConfigFolder)
    end
    
    if not isfolder(self.ThemeFolder) then
        makefolder(self.ThemeFolder)
    end
    
    return self
end

function SaveManager:SetIgnoreIndexes(indexes)
    self.IgnoreIndexes = indexes or {}
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    self.ConfigFolder = folder
end

function SaveManager:ValidateConfigName(name)
    if not name or name == "" then
        return false, "Config name cannot be empty"
    end
    
    if name:match("[^%w%s%-_]") then
        return false, "Config name contains invalid characters"
    end
    
    if #name > 50 then
        return false, "Config name too long (max 50 characters)"
    end
    
    return true, name:gsub("%s+", "_")
end

function SaveManager:ExportToJSON()
    local data = {}
    
    for flag, value in pairs(SecretLib.Flags) do
        local shouldIgnore = false
        for _, ignoreIndex in ipairs(self.IgnoreIndexes) do
            if flag == ignoreIndex then
                shouldIgnore = true
                break
            end
        end
        
        if not shouldIgnore then
            data[flag] = value
        end
    end
    
    return HttpService:JSONEncode(data)
end

function SaveManager:ImportFromJSON(jsonString)
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if not success then
        return false, "Invalid JSON format"
    end
    
    for flag, value in pairs(data) do
        SecretLib.Flags[flag] = value
        
        if getgenv().Toggles[flag] then
            getgenv().Toggles[flag]:SetValue(value)
        elseif getgenv().Options[flag] then
            getgenv().Options[flag]:SetValue(value)
        end
    end
    
    return true
end

function SaveManager:BuildConfigSection(tab)
    local section = tab:CreateSection("Configuration")
    
    local configName = ""
    
    section:CreateInput({
        Name = "Config Name",
        Placeholder = "Enter config name...",
        Callback = function(value)
            configName = value
        end
    })
    
    section:CreateButton({
        Name = "Save Config",
        Callback = function()
            if configName == "" then
                SecretLib:Notify({
                    Title = "Save Failed",
                    Message = "Please enter a config name",
                    Type = "error"
                })
                return
            end
            
            local valid, sanitized = self:ValidateConfigName(configName)
            if not valid then
                SecretLib:Notify({
                    Title = "Invalid Name",
                    Message = sanitized,
                    Type = "error"
                })
                return
            end
            
            self.FileName = sanitized
            local success = self:Save()
            
            if success then
                SecretLib:Notify({
                    Title = "Config Saved",
                    Message = "Config '" .. sanitized .. "' saved successfully",
                    Type = "success"
                })
            end
        end
    })
    
    section:CreateButton({
        Name = "Load Config",
        Callback = function()
            if configName == "" then
                SecretLib:Notify({
                    Title = "Load Failed",
                    Message = "Please enter a config name",
                    Type = "error"
                })
                return
            end
            
            local valid, sanitized = self:ValidateConfigName(configName)
            if not valid then
                return
            end
            
            self.FileName = sanitized
            local success = self:Load()
            
            if success then
                SecretLib:Notify({
                    Title = "Config Loaded",
                    Message = "Config '" .. sanitized .. "' loaded successfully",
                    Type = "success"
                })
            else
                SecretLib:Notify({
                    Title = "Load Failed",
                    Message = "Config not found",
                    Type = "error"
                })
            end
        end
    })
    
    section:CreateButton({
        Name = "Delete Config",
        Callback = function()
            if configName == "" then
                SecretLib:Notify({
                    Title = "Delete Failed",
                    Message = "Please enter a config name",
                    Type = "error"
                })
                return
            end
            
            local valid, sanitized = self:ValidateConfigName(configName)
            if not valid then
                return
            end
            
            self.FileName = sanitized
            local success = self:Delete()
            
            if success then
                SecretLib:Notify({
                    Title = "Config Deleted",
                    Message = "Config '" .. sanitized .. "' deleted successfully",
                    Type = "success"
                })
            end
        end
    })
    
    local configs = self:GetConfigs()
    if #configs > 0 then
        section:CreateDropdown({
            Name = "Available Configs",
            Options = configs,
            Callback = function(value)
                configName = value
            end
        })
    end
    
    return section
end

function SaveManager:Save()
    local data = {}
    
    for flag, value in pairs(SecretLib.Flags) do
        local shouldIgnore = false
        for _, ignoreIndex in ipairs(self.IgnoreIndexes) do
            if flag == ignoreIndex then
                shouldIgnore = true
                break
            end
        end
        
        if not shouldIgnore then
            data[flag] = value
        end
    end
    
    local success, err = pcall(function()
        writefile(self.ConfigFolder .. "/" .. self.FileName .. ".json", HttpService:JSONEncode(data))
    end)
    
    if success then
        return true
    else
        warn("SecretLib SaveManager: Failed to save - " .. tostring(err))
        return false
    end
end

function SaveManager:Load()
    local filePath = self.ConfigFolder .. "/" .. self.FileName .. ".json"
    
    if not isfile(filePath) then
        return false
    end
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(filePath))
    end)
    
    if success and type(result) == "table" then
        for flag, value in pairs(result) do
            if SecretLib.Flags[flag] ~= nil then
                SecretLib.Flags[flag] = value
            end
        end
        return true
    else
        warn("SecretLib SaveManager: Failed to load - " .. tostring(result))
        return false
    end
end

function SaveManager:Delete()
    local filePath = self.ConfigFolder .. "/" .. self.FileName .. ".json"
    
    if isfile(filePath) then
        delfile(filePath)
        return true
    end
    
    return false
end

function SaveManager:AutoSave(interval)
    interval = interval or 60
    
    task.spawn(function()
        while true do
            task.wait(interval)
            self:Save()
        end
    end)
end

return SaveManager

end

do

local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.__index = ThemeManager

ThemeManager.Themes = {
    Dark = {
        Background = Color3.fromRGB(15, 15, 15),
        Surface = Color3.fromRGB(20, 20, 20),
        SurfaceHover = Color3.fromRGB(25, 25, 25),
        Border = Color3.fromRGB(40, 40, 40),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentHover = Color3.fromRGB(108, 121, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 180, 180),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(237, 66, 69),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceHover = Color3.fromRGB(245, 245, 245),
        Border = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentHover = Color3.fromRGB(108, 121, 255),
        Text = Color3.fromRGB(0, 0, 0),
        TextDim = Color3.fromRGB(100, 100, 100),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(237, 66, 69),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
    Nord = {
        Background = Color3.fromRGB(46, 52, 64),
        Surface = Color3.fromRGB(59, 66, 82),
        SurfaceHover = Color3.fromRGB(67, 76, 94),
        Border = Color3.fromRGB(76, 86, 106),
        Accent = Color3.fromRGB(136, 192, 208),
        AccentHover = Color3.fromRGB(143, 188, 187),
        Text = Color3.fromRGB(236, 239, 244),
        TextDim = Color3.fromRGB(216, 222, 233),
        Success = Color3.fromRGB(163, 190, 140),
        Warning = Color3.fromRGB(235, 203, 139),
        Error = Color3.fromRGB(191, 97, 106),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
    Dracula = {
        Background = Color3.fromRGB(40, 42, 54),
        Surface = Color3.fromRGB(68, 71, 90),
        SurfaceHover = Color3.fromRGB(98, 114, 164),
        Border = Color3.fromRGB(68, 71, 90),
        Accent = Color3.fromRGB(189, 147, 249),
        AccentHover = Color3.fromRGB(255, 121, 198),
        Text = Color3.fromRGB(248, 248, 242),
        TextDim = Color3.fromRGB(98, 114, 164),
        Success = Color3.fromRGB(80, 250, 123),
        Warning = Color3.fromRGB(241, 250, 140),
        Error = Color3.fromRGB(255, 85, 85),
        Shadow = Color3.fromRGB(0, 0, 0),
    }
}

function ThemeManager.new(config)
    local self = setmetatable({}, ThemeManager)
    
    self.Folder = config.Folder or "SecretLib/Themes"
    self.CurrentTheme = "Dark"
    
    return self
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
end

function ThemeManager:ApplyTheme(themeName)
    local theme = self.Themes[themeName]
    if not theme then
        return false
    end
    
    for key, value in pairs(theme) do
        if SecretLib.Theme[key] then
            SecretLib.Theme[key] = value
        end
    end
    
    self.CurrentTheme = themeName
    return true
end

function ThemeManager:SaveTheme(themeName)
    local theme = {}
    for key, value in pairs(SecretLib.Theme) do
        theme[key] = {
            R = value.R,
            G = value.G,
            B = value.B
        }
    end
    
    local encoded = HttpService:JSONEncode(theme)
    local filePath = self.Folder .. "/" .. themeName .. ".json"
    
    local success, err = pcall(function()
        if not isfolder(self.Folder) then
            makefolder(self.Folder)
        end
        writefile(filePath, encoded)
    end)
    
    return success
end

function ThemeManager:LoadTheme(themeName)
    local filePath = self.Folder .. "/" .. themeName .. ".json"
    
    if not isfile(filePath) then
        return false
    end
    
    local success, result = pcall(function()
        local content = readfile(filePath)
        local data = HttpService:JSONDecode(content)
        
        for key, rgb in pairs(data) do
            if SecretLib.Theme[key] then
                SecretLib.Theme[key] = Color3.new(rgb.R, rgb.G, rgb.B)
            end
        end
        
        return true
    end)
    
    return success and result
end

function ThemeManager:GetThemes()
    local themes = {}
    
    for name, _ in pairs(self.Themes) do
        table.insert(themes, name)
    end
    
    if isfolder(self.Folder) then
        local files = listfiles(self.Folder)
        for _, file in ipairs(files) do
            if file:match("%.json$") then
                local name = file:match("([^/]+)%.json$")
                if name and not self.Themes[name] then
                    table.insert(themes, name)
                end
            end
        end
    end
    
    return themes
end

function ThemeManager:CreateThemeManager(groupbox)
    groupbox:CreateLabel({Text = "Theme Settings"})
    
    groupbox:CreateLabel({Text = "Background"}):AddColorPicker({
        Default = SecretLib.Theme.Background,
        Title = "Background Color",
        Callback = function(color)
            SecretLib.Theme.Background = color
        end
    })
    
    groupbox:CreateLabel({Text = "Surface"}):AddColorPicker({
        Default = SecretLib.Theme.Surface,
        Title = "Surface Color",
        Callback = function(color)
            SecretLib.Theme.Surface = color
        end
    })
    
    groupbox:CreateLabel({Text = "Accent"}):AddColorPicker({
        Default = SecretLib.Theme.Accent,
        Title = "Accent Color",
        Callback = function(color)
            SecretLib.Theme.Accent = color
        end
    })
    
    groupbox:CreateLabel({Text = "Text"}):AddColorPicker({
        Default = SecretLib.Theme.Text,
        Title = "Text Color",
        Callback = function(color)
            SecretLib.Theme.Text = color
        end
    })
    
    groupbox:CreateDropdown({
        Name = "Theme Preset",
        Options = self:GetThemes(),
        Callback = function(theme)
            if self.Themes[theme] then
                self:ApplyTheme(theme)
            else
                self:LoadTheme(theme)
            end
        end
    })
    
    local themeName = ""
    
    groupbox:CreateInput({
        Name = "Theme Name",
        Placeholder = "Enter theme name...",
        Callback = function(value)
            themeName = value
        end
    })
    
    groupbox:CreateButton({
        Name = "Save Theme",
        Callback = function()
            if themeName ~= "" then
                local success = self:SaveTheme(themeName)
                if success then
                    SecretLib:Notify({
                        Title = "Theme Saved",
                        Message = "Theme '" .. themeName .. "' saved successfully",
                        Type = "success"
                    })
                end
            end
        end
    })
end

return ThemeManager

end

do

local Utility = 
local EventSystem = 

local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)
    
    self.Title = config.Title or "SecretLib"
    self.Size = config.Size or UDim2.new(0, 580, 0, 460)
    self.Center = config.Center
    self.Position = config.Center and UDim2.new(0.5, 0, 0.5, 0) or (config.Position or UDim2.new(0.5, 0, 0.5, 0))
    self.ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    self.TabPadding = config.TabPadding or 8
    self.MenuFadeTime = config.MenuFadeTime or 0.2
    self.AutoShow = config.AutoShow ~= false
    self.Tabs = {}
    self.ActiveTab = nil
    self.Visible = self.AutoShow
    self.Minimized = false
    
    self.Container = Utility:Create("Frame", {
        Size = self.AutoShow and self.Size or UDim2.new(0, 0, 0, 0),
        Position = self.Position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = SecretLib.Theme.Background,
        BorderSizePixel = 0,
        BackgroundTransparency = self.AutoShow and 0 or 1,
        Visible = self.AutoShow,
        Parent = SecretLib.ScreenGui
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Parent = self.Container
    })
    
    local shadow = Utility:Create("ImageLabel", {
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        ImageColor3 = SecretLib.Theme.Shadow,
        ImageTransparency = 0.7,
        ZIndex = -1,
        Parent = self.Container
    })
    
    local titleBar = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = titleBar
    })
    
    local titleBarBottom = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = titleBar
    })
    
    local titleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 16,
        Font = SecretLib.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    local minimizeButton = Utility:Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -80, 0, 8),
        BackgroundColor3 = SecretLib.Theme.Warning,
        BorderSizePixel = 0,
        Text = "_",
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 14,
        Font = SecretLib.FontBold,
        Parent = titleBar
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = minimizeButton
    })
    
    Utility:AddRipple(minimizeButton)
    
    minimizeButton.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)
    
    local closeButton = Utility:Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -40, 0, 8),
        BackgroundColor3 = SecretLib.Theme.Error,
        BorderSizePixel = 0,
        Text = "X",
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 14,
        Font = SecretLib.FontBold,
        Parent = titleBar
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = closeButton
    })
    
    Utility:AddRipple(closeButton)
    
    closeButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    self.MinimizeButton = minimizeButton
    
    Utility:MakeDraggable(self.Container, titleBar)
    
    self.SidebarContainer = sidebarContainer
    self.TitleBar = titleBar
    
    local sidebarContainer = Utility:Create("Frame", {
        Size = UDim2.new(0, 160, 1, -60),
        Position = UDim2.new(0, 12, 0, 56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    
    self.TabList = Utility:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = SecretLib.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = sidebarContainer
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, self.TabPadding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.TabList
    })
    
    self.ContentArea = Utility:Create("Frame", {
        Size = UDim2.new(1, -188, 1, -60),
        Position = UDim2.new(0, 176, 0, 56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    
    table.insert(SecretLib.Windows, self)
    
    EventSystem:Fire("WindowCreated", self)
    EventSystem:Fire("WindowOpened", self)
    
    if self.ToggleKey and self.ToggleKey ~= Enum.KeyCode.Unknown then
        local UserInputService = game:GetService("UserInputService")
        self.ToggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == self.ToggleKey then
                self:Toggle()
            end
        end)
    end
    
    return self
end

function Window:SelectTab(tab)
    local previousTab = self.ActiveTab
    
    for _, t in ipairs(self.Tabs) do
        if t == tab then
            t.Active = true
            t.Container.Visible = true
            Utility:Tween(t.Button, "BackgroundColor3", SecretLib.Theme.Accent, SecretLib.SpringConfig.Snappy)
            Utility:Tween(t.Button, "TextColor3", SecretLib.Theme.Text, SecretLib.SpringConfig.Snappy)
        else
            t.Active = false
            t.Container.Visible = false
            Utility:Tween(t.Button, "BackgroundColor3", SecretLib.Theme.Surface, SecretLib.SpringConfig.Snappy)
            Utility:Tween(t.Button, "TextColor3", SecretLib.Theme.TextDim, SecretLib.SpringConfig.Snappy)
        end
    end
    self.ActiveTab = tab
    
    EventSystem:Fire("TabChanged", self, tab, previousTab)
    
    return self
end

function Window:CreateTab(name)
    local Tab = 
    local tab = Tab.new(self, name)
    EventSystem:Fire("TabCreated", self, tab)
    return tab
end

function Window:Toggle()
    self.Visible = not self.Visible
    
    if self.Visible then
        self.Container.Visible = true
        if self.Minimized then
            Utility:Tween(self.Container, "Size", UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 48), SecretLib.SpringConfig.Bouncy)
        else
            Utility:Tween(self.Container, "Size", self.Size, SecretLib.SpringConfig.Bouncy)
        end
        EventSystem:Fire("WindowOpened", self)
    else
        Utility:Tween(self.Container, "Size", UDim2.new(0, 0, 0, 0), SecretLib.SpringConfig.Snappy)
        task.delay(0.2, function()
            if not self.Visible then
                self.Container.Visible = false
            end
        end)
        EventSystem:Fire("WindowClosed", self)
    end
    
    return self
end

function Window:ToggleMinimize()
    self.Minimized = not self.Minimized
    
    if self.Minimized then
        self.SidebarContainer.Visible = false
        self.ContentArea.Visible = false
        Utility:Tween(self.Container, "Size", UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 48), SecretLib.SpringConfig.Bouncy)
        self.MinimizeButton.Text = "+"
        EventSystem:Fire("WindowMinimized", self)
    else
        Utility:Tween(self.Container, "Size", self.Size, SecretLib.SpringConfig.Bouncy)
        task.delay(0.2, function()
            if not self.Minimized then
                self.SidebarContainer.Visible = true
                self.ContentArea.Visible = true
            end
        end)
        self.MinimizeButton.Text = "_"
        EventSystem:Fire("WindowMaximized", self)
    end
    
    return self
end

function Window:SetToggleKey(keyCode)
    self.ToggleKey = keyCode
    
    if self.ToggleConnection then
        self.ToggleConnection:Disconnect()
    end
    
    if keyCode and keyCode ~= Enum.KeyCode.Unknown then
        local UserInputService = game:GetService("UserInputService")
        self.ToggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == self.ToggleKey then
                self:Toggle()
            end
        end)
    end
end

function Window:Destroy()
    if self.ToggleConnection then
        self.ToggleConnection:Disconnect()
    end
    
    EventSystem:Fire("WindowDestroyed", self)
    
    Utility:Tween(self.Container, "Size", UDim2.new(0, 0, 0, 0), SecretLib.SpringConfig.Bouncy)
    task.wait(0.3)
    self.Container:Destroy()
end

return Window

end

do

local Utility = 

local Tab = {}
Tab.__index = Tab

function Tab.new(window, name)
    local self = setmetatable({}, Tab)
    
    self.Window = window
    self.Name = name
    self.Active = false
    self.Loaded = false
    
    self.Button = Utility:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 13,
        Font = SecretLib.Font,
        Parent = window.TabList
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Button
    })
    
    Utility:AddRipple(self.Button)
    
    self.Container = Utility:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = SecretLib.Theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
        Parent = window.ContentArea
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.Container
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 0),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 0),
        PaddingBottom = UDim.new(0, 16),
        Parent = self.Container
    })
    
    self.Button.MouseButton1Click:Connect(function()
        if not self.Loaded then
            self.Loaded = true
            if self.OnLoad then
                self.OnLoad()
            end
        end
        window:SelectTab(self)
    end)
    
    self.Button.MouseEnter:Connect(function()
        if not self.Active then
            Utility:Tween(self.Button, "BackgroundColor3", SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
        end
    end)
    
    self.Button.MouseLeave:Connect(function()
        if not self.Active then
            Utility:Tween(self.Button, "BackgroundColor3", SecretLib.Theme.Surface, SecretLib.SpringConfig.Snappy)
        end
    end)
    
    table.insert(window.Tabs, self)
    
    if #window.Tabs == 1 then
        window:SelectTab(self)
    end
    
    window.TabList.CanvasSize = UDim2.new(0, 0, 0, window.TabList.UIListLayout.AbsoluteContentSize.Y + 8)
    
    return self
end

function Tab:UpdateCanvasSize()
    self.Container.CanvasSize = UDim2.new(0, 0, 0, self.Container.UIListLayout.AbsoluteContentSize.Y + 16)
end

function Tab:CreateSection(name)
    local Section = 
    local section = Section.new(self, name)
    return section
end

function Tab:AddLeftGroupbox(name)
    local Section = 
    local section = Section.new(self, name)
    section.Container.LayoutOrder = -1000
    return section
end

function Tab:AddRightGroupbox(name)
    local Section = 
    local section = Section.new(self, name)
    section.Container.LayoutOrder = 1000
    return section
end

function Tab:CreateToggle(config)
    local Toggle = 
    local toggle = Toggle.new(self, config)
    return toggle
end

function Tab:CreateButton(config)
    local Button = 
    local button = Button.new(self, config)
    return button
end

function Tab:CreateSlider(config)
    local Slider = 
    local slider = Slider.new(self, config)
    return slider
end

function Tab:CreateDropdown(config)
    local Dropdown = 
    local dropdown = Dropdown.new(self, config)
    return dropdown
end

function Tab:CreateInput(config)
    local Input = 
    local input = Input.new(self, config)
    return input
end

function Tab:CreateLabel(config)
    local Label = 
    local label = Label.new(self, config)
    return label
end

function Tab:CreateKeybind(config)
    local Keybind = 
    local keybind = Keybind.new(self, config)
    return keybind
end

function Tab:CreateColorPicker(config)
    local ColorPicker = 
    local colorpicker = ColorPicker.new(self, config)
    return colorpicker
end

function Tab:CreateParagraph(config)
    local Paragraph = 
    return Paragraph.new(self, config)
end

function Tab:CreateDivider(config)
    local Divider = 
    return Divider.new(self, config or {})
end

function Tab:CreateImage(config)
    local Image = 
    return Image.new(self, config)
end

function Tab:CreateMultiSlider(config)
    local MultiSlider = 
    return MultiSlider.new(self, config)
end

function Tab:AddLeftTabbox()
    local TabBox = 
    return TabBox.new(self, "Left")
end

function Tab:AddRightTabbox()
    local TabBox = 
    return TabBox.new(self, "Right")
end

return Tab

end

do

local Utility = 

local TabBox = {}
TabBox.__index = TabBox

function TabBox.new(parentTab, side)
    local self = setmetatable({}, TabBox)
    
    self.ParentTab = parentTab
    self.Side = side
    self.Tabs = {}
    self.ActiveTab = nil
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = side == "Left" and -500 or 500,
        Parent = parentTab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 12),
        Parent = self.Container
    })
    
    self.TabList = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = self.Container
    })
    
    Utility:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.TabList
    })
    
    self.ContentArea = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Container
    })
    
    parentTab:UpdateCanvasSize()
    
    return self
end

function TabBox:AddTab(name)
    local tab = {
        Name = name,
        TabBox = self,
        Active = false
    }
    
    local button = Utility:Create("TextButton", {
        Size = UDim2.new(0, 80, 1, 0),
        BackgroundColor3 = SecretLib.Theme.Background,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 12,
        Font = SecretLib.Font,
        Parent = self.TabList
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = button
    })
    
    Utility:AddRipple(button)
    
    local container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.ContentArea
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = container
    })
    
    tab.Button = button
    tab.Container = container
    
    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    button.MouseEnter:Connect(function()
        if not tab.Active then
            Utility:Tween(button, "BackgroundColor3", SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not tab.Active then
            Utility:Tween(button, "BackgroundColor3", SecretLib.Theme.Background, SecretLib.SpringConfig.Snappy)
        end
    end)
    
    table.insert(self.Tabs, tab)
    
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    function tab:CreateToggle(config)
        local Toggle = 
        local toggle = Toggle.new(self.TabBox.ParentTab, config)
        toggle.Container.Parent = self.Container
        self.TabBox.ParentTab:UpdateCanvasSize()
        return toggle
    end
    
    function tab:CreateButton(config)
        local Button = 
        local button = Button.new(self.TabBox.ParentTab, config)
        button.Container.Parent = self.Container
        self.TabBox.ParentTab:UpdateCanvasSize()
        return button
    end
    
    function tab:CreateSlider(config)
        local Slider = 
        local slider = Slider.new(self.TabBox.ParentTab, config)
        slider.Container.Parent = self.Container
        self.TabBox.ParentTab:UpdateCanvasSize()
        return slider
    end
    
    function tab:CreateDropdown(config)
        local Dropdown = 
        local dropdown = Dropdown.new(self.TabBox.ParentTab, config)
        dropdown.Container.Parent = self.Container
        self.TabBox.ParentTab:UpdateCanvasSize()
        return dropdown
    end
    
    function tab:CreateInput(config)
        local Input = 
        local input = Input.new(self.TabBox.ParentTab, config)
        input.Container.Parent = self.Container
        self.TabBox.ParentTab:UpdateCanvasSize()
        return input
    end
    
    function tab:CreateLabel(config)
        local Label = 
        local label = Label.new(self.TabBox.ParentTab, config)
        label.Container.Parent = self.Container
        self.TabBox.ParentTab:UpdateCanvasSize()
        return label
    end
    
    function tab:CreateKeybind(config)
        local Keybind = 
        local keybind = Keybind.new(self.TabBox.ParentTab, config)
        keybind.Container.Parent = self.Container
        self.TabBox.ParentTab:UpdateCanvasSize()
        return keybind
    end
    
    function tab:CreateColorPicker(config)
        local ColorPicker = 
        local colorpicker = ColorPicker.new(self.TabBox.ParentTab, config)
        colorpicker.Container.Parent = self.Container
        self.TabBox.ParentTab:UpdateCanvasSize()
        return colorpicker
    end
    
    return tab
end

function TabBox:SelectTab(tab)
    for _, t in ipairs(self.Tabs) do
        if t == tab then
            t.Active = true
            t.Container.Visible = true
            Utility:Tween(t.Button, "BackgroundColor3", SecretLib.Theme.Accent, SecretLib.SpringConfig.Snappy)
            Utility:Tween(t.Button, "TextColor3", SecretLib.Theme.Text, SecretLib.SpringConfig.Snappy)
        else
            t.Active = false
            t.Container.Visible = false
            Utility:Tween(t.Button, "BackgroundColor3", SecretLib.Theme.Background, SecretLib.SpringConfig.Snappy)
            Utility:Tween(t.Button, "TextColor3", SecretLib.Theme.TextDim, SecretLib.SpringConfig.Snappy)
        end
    end
    self.ActiveTab = tab
end

return TabBox

end

do

local Utility = 

local Section = {}
Section.__index = Section

function Section.new(tab, name)
    local self = setmetatable({}, Section)
    
    self.Tab = tab
    self.Name = name
    self.Collapsed = false
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    local headerButton = Utility:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        Parent = self.Container
    })
    
    local headerLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 14,
        Font = SecretLib.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = headerButton
    })
    
    self.CollapseIcon = Utility:Create("TextLabel", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 10,
        Font = SecretLib.Font,
        Parent = headerButton
    })
    
    Utility:AddRipple(headerButton)
    
    headerButton.MouseButton1Click:Connect(function()
        self:ToggleCollapse()
    end)
    
    self.Content = Utility:Create("Frame", {
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 12, 0, 36),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Container
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.Content
    })
    
    Utility:Create("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        Parent = self.Container
    })
    
    tab:UpdateCanvasSize()
    
    return self
end

function Section:ToggleCollapse()
    self.Collapsed = not self.Collapsed
    
    if self.Collapsed then
        self.Content.Visible = false
        Utility:Tween(self.CollapseIcon, "Rotation", -90, SecretLib.SpringConfig.Bouncy)
    else
        self.Content.Visible = true
        Utility:Tween(self.CollapseIcon, "Rotation", 0, SecretLib.SpringConfig.Bouncy)
    end
    
    self.Tab:UpdateCanvasSize()
end

function Section:CreateToggle(config)
    local Toggle = 
    local toggle = Toggle.new(self.Tab, config)
    toggle.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return toggle
end

function Section:CreateButton(config)
    local Button = 
    local button = Button.new(self.Tab, config)
    button.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return button
end

function Section:CreateSlider(config)
    local Slider = 
    local slider = Slider.new(self.Tab, config)
    slider.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return slider
end

function Section:CreateDropdown(config)
    local Dropdown = 
    local dropdown = Dropdown.new(self.Tab, config)
    dropdown.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return dropdown
end

function Section:CreateInput(config)
    local Input = 
    local input = Input.new(self.Tab, config)
    input.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return input
end

function Section:CreateLabel(config)
    local Label = 
    local label = Label.new(self.Tab, config)
    label.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return label
end

function Section:CreateKeybind(config)
    local Keybind = 
    local keybind = Keybind.new(self.Tab, config)
    keybind.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return keybind
end

function Section:CreateColorPicker(config)
    local ColorPicker = 
    local colorpicker = ColorPicker.new(self.Tab, config)
    colorpicker.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return colorpicker
end

function Section:CreateParagraph(config)
    local Paragraph = 
    local paragraph = Paragraph.new(self.Tab, config)
    paragraph.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return paragraph
end

function Section:CreateDivider(config)
    local Divider = 
    local divider = Divider.new(self.Tab, config or {})
    divider.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return divider
end

function Section:CreateImage(config)
    local Image = 
    local image = Image.new(self.Tab, config)
    image.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return image
end

function Section:CreateMultiSlider(config)
    local MultiSlider = 
    local multislider = MultiSlider.new(self.Tab, config)
    multislider.Container.Parent = self.Content
    self.Tab:UpdateCanvasSize()
    return multislider
end

function Section:AddDependencyBox()
    local DependencyBox = 
    local depBox = DependencyBox.new(self)
    return depBox
end

return Section

end

do

local Utility = 
local DependencyManager = 

local DependencyBox = {}
DependencyBox.__index = DependencyBox

function DependencyBox.new(parent)
    local self = setmetatable({}, DependencyBox)
    
    self.Parent = parent
    self.Dependencies = {}
    self.Elements = {}
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = SecretLib.Theme.Background,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = true,
        Parent = parent.Content or parent.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        Parent = self.Container
    })
    
    self.Content = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Container
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.Content
    })
    
    if parent.Tab then
        parent.Tab:UpdateCanvasSize()
    end
    
    return self
end

function DependencyBox:SetupDependencies(dependencies)
    self.Dependencies = dependencies
    self:UpdateVisibility()
    
    for _, dep in ipairs(dependencies) do
        local element = dep[1]
        local expectedValue = dep[2]
        
        if element and element.Flag then
            local originalCallback = element.Callback
            element.Callback = function(...)
                if originalCallback then
                    originalCallback(...)
                end
                self:UpdateVisibility()
            end
        end
    end
end

function DependencyBox:UpdateVisibility()
    local shouldShow = true
    
    for _, dep in ipairs(self.Dependencies) do
        local element = dep[1]
        local expectedValue = dep[2]
        
        if element then
            local currentValue = element.Value
            if currentValue ~= expectedValue then
                shouldShow = false
                break
            end
        end
    end
    
    if self.Parent.Dependencies and #self.Parent.Dependencies > 0 then
        local parentVisible = true
        for _, dep in ipairs(self.Parent.Dependencies) do
            local element = dep[1]
            local expectedValue = dep[2]
            if element and element.Value ~= expectedValue then
                parentVisible = false
                break
            end
        end
        shouldShow = shouldShow and parentVisible
    end
    
    if shouldShow then
        self.Container.Visible = true
        Utility:Tween(self.Container, "BackgroundTransparency", 0, SecretLib.SpringConfig.Snappy)
    else
        Utility:Tween(self.Container, "BackgroundTransparency", 1, SecretLib.SpringConfig.Snappy)
        task.delay(0.2, function()
            if not shouldShow then
                self.Container.Visible = false
            end
        end)
    end
end

function DependencyBox:AddToggle(config)
    local Toggle = 
    local tab = self.Parent.Tab or self.Parent.TabBox.ParentTab
    local toggle = Toggle.new(tab, config)
    toggle.Container.Parent = self.Content
    table.insert(self.Elements, toggle)
    if tab then tab:UpdateCanvasSize() end
    return toggle
end

function DependencyBox:AddButton(config)
    local Button = 
    local tab = self.Parent.Tab or self.Parent.TabBox.ParentTab
    local button = Button.new(tab, config)
    button.Container.Parent = self.Content
    table.insert(self.Elements, button)
    if tab then tab:UpdateCanvasSize() end
    return button
end

function DependencyBox:AddSlider(config)
    local Slider = 
    local tab = self.Parent.Tab or self.Parent.TabBox.ParentTab
    local slider = Slider.new(tab, config)
    slider.Container.Parent = self.Content
    table.insert(self.Elements, slider)
    if tab then tab:UpdateCanvasSize() end
    return slider
end

function DependencyBox:AddDropdown(config)
    local Dropdown = 
    local tab = self.Parent.Tab or self.Parent.TabBox.ParentTab
    local dropdown = Dropdown.new(tab, config)
    dropdown.Container.Parent = self.Content
    table.insert(self.Elements, dropdown)
    if tab then tab:UpdateCanvasSize() end
    return dropdown
end

function DependencyBox:AddInput(config)
    local Input = 
    local tab = self.Parent.Tab or self.Parent.TabBox.ParentTab
    local input = Input.new(tab, config)
    input.Container.Parent = self.Content
    table.insert(self.Elements, input)
    if tab then tab:UpdateCanvasSize() end
    return input
end

function DependencyBox:AddLabel(config)
    local Label = 
    local tab = self.Parent.Tab or self.Parent.TabBox.ParentTab
    local label = Label.new(tab, config)
    label.Container.Parent = self.Content
    table.insert(self.Elements, label)
    if tab then tab:UpdateCanvasSize() end
    return label
end

function DependencyBox:AddDependencyBox()
    local depBox = DependencyBox.new(self)
    depBox.Parent = self
    table.insert(self.Elements, depBox)
    return depBox
end

return DependencyBox

end

do

local Utility = 
local DependencyManager = 

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(tab, config)
    local self = setmetatable({}, Toggle)
    
    self.Name = config.Name or "Toggle"
    self.Value = config.Default or false
    self.Flag = config.Flag
    self.Index = config.Index or config.Flag
    self.Callback = config.Callback
    self.Debounce = config.Debounce or 0
    self.DependsOn = config.DependsOn
    self.Tooltip = config.Tooltip
    self.LastCall = 0
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    local label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -56, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    local switchBg = Utility:Create("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = self.Value and SecretLib.Theme.Accent or SecretLib.Theme.Border,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = switchBg
    })
    
    local switchKnob = Utility:Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = SecretLib.Theme.Text,
        BorderSizePixel = 0,
        Parent = switchBg
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = switchKnob
    })
    
    local button = Utility:Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = self.Container
    })
    
    Utility:AddRipple(button)
    
    button.MouseButton1Click:Connect(function()
        self:SetValue(not self.Value)
    end)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = self.Value
    end
    
    DependencyManager:RegisterElement(self, config)
    
    if self.Tooltip then
        local Tooltip = 
        Tooltip:AddToElement(self, self.Tooltip)
    end
    
    if self.Index then
        getgenv().Toggles[self.Index] = self
    end
    
    tab:UpdateCanvasSize()
    
    return self
end

function Toggle:OnChanged(callback)
    local oldCallback = self.Callback
    self.Callback = function(...)
        if oldCallback then
            oldCallback(...)
        end
        callback(...)
    end
    return self
end

function Toggle:SetValue(value)
    self.Value = value
    
    local switchBg = self.Container:FindFirstChild("Frame")
    local switchKnob = switchBg:FindFirstChild("Frame")
    
    Utility:Tween(switchBg, "BackgroundColor3", value and SecretLib.Theme.Accent or SecretLib.Theme.Border, SecretLib.SpringConfig.Snappy)
    Utility:Tween(switchKnob, "Position", value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), SecretLib.SpringConfig.Bouncy)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = value
        DependencyManager:OnFlagChanged(self.Flag)
    end
    
    if self.Callback then
        local now = tick()
        if now - self.LastCall >= self.Debounce then
            self.LastCall = now
            task.spawn(self.Callback, value)
        end
    end
end

function Toggle:AddKeyPicker(config)
    local Keybind = 
    config = config or {}
    config.SyncToggleState = config.SyncToggleState ~= false
    
    local keybind = Keybind.new(self.Tab or self.TabBox.ParentTab, config)
    keybind.ParentToggle = self
    keybind.Container.Parent = self.Container.Parent
    keybind.Container.LayoutOrder = self.Container.LayoutOrder + 0.1
    
    if config.SyncToggleState then
        local oldCallback = keybind.Callback
        keybind.Callback = function(state)
            self:SetValue(state)
            if oldCallback then
                oldCallback(state)
            end
        end
    end
    
    return keybind
end

function Toggle:AddColorPicker(config)
    local ColorPicker = 
    config = config or {}
    
    local colorpicker = ColorPicker.new(self.Tab or self.TabBox.ParentTab, config)
    colorpicker.Container.Parent = self.Container.Parent
    colorpicker.Container.LayoutOrder = self.Container.LayoutOrder + 0.2
    
    return colorpicker
end

return Toggle

end

do

local Utility = 

local Button = {}
Button.__index = Button

function Button.new(tab, config)
    local self = setmetatable({}, Button)
    
    self.Name = config.Name or config.Text or "Button"
    self.Callback = config.Callback or config.Func
    self.DoubleClick = config.DoubleClick or false
    self.Tooltip = config.Tooltip
    self.SubButtons = {}
    self.LastClick = 0
    self.ClickCount = 0
    
    self.Container = Utility:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = SecretLib.Theme.Accent,
        BorderSizePixel = 0,
        Text = self.Name,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.FontBold,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:AddRipple(self.Container)
    
    self.Container.MouseEnter:Connect(function()
        Utility:Tween(self.Container, "BackgroundColor3", SecretLib.Theme.AccentHover, SecretLib.SpringConfig.Snappy)
    end)
    
    self.Container.MouseLeave:Connect(function()
        Utility:Tween(self.Container, "BackgroundColor3", SecretLib.Theme.Accent, SecretLib.SpringConfig.Snappy)
    end)
    
    self.Container.MouseButton1Click:Connect(function()
        if self.DoubleClick then
            local now = tick()
            if now - self.LastClick < 0.5 then
                self.ClickCount = self.ClickCount + 1
                if self.ClickCount >= 2 then
                    if self.Callback then
                        task.spawn(self.Callback)
                    end
                    self.ClickCount = 0
                end
            else
                self.ClickCount = 1
            end
            self.LastClick = now
        else
            if self.Callback then
                task.spawn(self.Callback)
            end
        end
    end)
    
    if self.Tooltip then
        local Tooltip = 
        Tooltip:AddToElement(self, self.Tooltip)
    end
    
    tab:UpdateCanvasSize()
    
    return self
end

function Button:AddButton(config)
    local subButton = Button.new(self.Tab or self.TabBox.ParentTab, config)
    
    subButton.Container.Size = UDim2.new(1, -20, 0, 32)
    subButton.Container.BackgroundColor3 = SecretLib.Theme.Surface
    subButton.Container.Parent = self.Container.Parent
    subButton.Container.LayoutOrder = self.Container.LayoutOrder + (#self.SubButtons * 0.01) + 0.001
    
    local indent = Utility:Create("Frame", {
        Size = UDim2.new(0, 12, 1, 0),
        BackgroundColor3 = SecretLib.Theme.Border,
        BorderSizePixel = 0,
        Parent = subButton.Container
    })
    
    subButton.Container.TextXAlignment = Enum.TextXAlignment.Left
    subButton.Container.TextTransparency = 0
    subButton.Container.Text = "  " .. subButton.Name
    
    subButton.Container.MouseEnter:Connect(function()
        Utility:Tween(subButton.Container, "BackgroundColor3", SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
    end)
    
    subButton.Container.MouseLeave:Connect(function()
        Utility:Tween(subButton.Container, "BackgroundColor3", SecretLib.Theme.Surface, SecretLib.SpringConfig.Snappy)
    end)
    
    table.insert(self.SubButtons, subButton)
    
    if self.Tab then
        self.Tab:UpdateCanvasSize()
    elseif self.TabBox and self.TabBox.ParentTab then
        self.TabBox.ParentTab:UpdateCanvasSize()
    end
    
    return subButton
end

return Button

end

do

local Utility = 
local DependencyManager = 
local UserInputService = game:GetService("UserInputService")

local Slider = {}
Slider.__index = Slider

function Slider.new(tab, config)
    local self = setmetatable({}, Slider)
    
    self.Name = config.Name or "Slider"
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.Default = config.Default or 50
    self.Increment = config.Increment or 1
    self.Flag = config.Flag
    self.Index = config.Index or config.Flag
    self.Callback = config.Callback
    self.Value = config.Default or 50
    self.Suffix = config.Suffix or ""
    self.Debounce = config.Debounce or 0.05
    self.Compact = config.Compact or false
    self.HideMax = config.HideMax or false
    self.DependsOn = config.DependsOn
    self.Tooltip = config.Tooltip
    self.LastCall = 0
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    local label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -120, 0, 20),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = self.Compact and "" or self.Name,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = not self.Compact,
        Parent = self.Container
    })
    
    self.ValueLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0, 100, 0, 20),
        Position = self.Compact and UDim2.new(0, 12, 0, 8) or UDim2.new(1, -112, 0, 8),
        BackgroundTransparency = 1,
        Text = self:GetDisplayText(),
        TextColor3 = SecretLib.Theme.Accent,
        TextSize = 13,
        Font = SecretLib.FontBold,
        TextXAlignment = self.Compact and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
        Parent = self.Container
    })
    
    self.SliderBg = Utility:Create("Frame", {
        Size = UDim2.new(1, -24, 0, 4),
        Position = self.Compact and UDim2.new(0, 12, 1, -12) or UDim2.new(0, 12, 1, -16),
        BackgroundColor3 = SecretLib.Theme.Border,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.SliderBg
    })
    
    self.SliderFill = Utility:Create("Frame", {
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BackgroundColor3 = SecretLib.Theme.Accent,
        BorderSizePixel = 0,
        Parent = self.SliderBg
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.SliderFill
    })
    
    self.SliderKnob = Utility:Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = SecretLib.Theme.Text,
        BorderSizePixel = 0,
        Parent = self.SliderBg
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.SliderKnob
    })
    
    self.Dragging = false
    
    self.SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = true
            self:UpdateSlider(input)
            
            Utility:Tween(self.SliderKnob, "Size", UDim2.new(0, 16, 0, 16), SecretLib.SpringConfig.Bouncy)
        end
    end)
    
    self.SliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = false
            Utility:Tween(self.SliderKnob, "Size", UDim2.new(0, 12, 0, 12), SecretLib.SpringConfig.Bouncy)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            self:UpdateSlider(input)
        end
    end)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = self.Value
    end
    
    DependencyManager:RegisterElement(self, config)
    
    if self.Tooltip then
        local Tooltip = 
        Tooltip:AddToElement(self, self.Tooltip)
    end
    
    if self.Index then
        getgenv().Options[self.Index] = self
    end
    
    tab:UpdateCanvasSize()
    
    return self
end

function Slider:UpdateSlider(input)
    local relativeX = math.clamp((input.Position.X - self.SliderBg.AbsolutePosition.X) / self.SliderBg.AbsoluteSize.X, 0, 1)
    local value = self.Min + (self.Max - self.Min) * relativeX
    value = math.floor(value / self.Increment + 0.5) * self.Increment
    value = math.clamp(value, self.Min, self.Max)
    
    self:SetValue(value)
end

function Slider:GetDisplayText()
    if self.HideMax or self.Compact then
        return tostring(self.Value) .. self.Suffix
    else
        return tostring(self.Value) .. " / " .. tostring(self.Max) .. self.Suffix
    end
end

function Slider:OnChanged(callback)
    local oldCallback = self.Callback
    self.Callback = function(...)
        if oldCallback then
            oldCallback(...)
        end
        callback(...)
    end
    return self
end

function Slider:SetValue(value)
    self.Value = value
    self.ValueLabel.Text = self:GetDisplayText()
    
    local relativeX = (value - self.Min) / (self.Max - self.Min)
    
    Utility:Tween(self.SliderFill, "Size", UDim2.new(relativeX, 0, 1, 0), SecretLib.SpringConfig.Snappy)
    Utility:Tween(self.SliderKnob, "Position", UDim2.new(relativeX, 0, 0.5, 0), SecretLib.SpringConfig.Snappy)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = value
        DependencyManager:OnFlagChanged(self.Flag)
    end
    
    if self.Callback then
        local now = tick()
        if now - self.LastCall >= self.Debounce then
            self.LastCall = now
            task.spawn(self.Callback, value)
        end
    end
end

return Slider

end

do

local Utility = 
local DependencyManager = 

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(tab, config)
    local self = setmetatable({}, Dropdown)
    
    self.Name = config.Name or config.Text or "Dropdown"
    self.Options = config.Options or config.Values or {}
    self.Default = config.Default
    self.Multi = config.Multi or false
    self.Flag = config.Flag
    self.Index = config.Index or config.Flag
    self.Callback = config.Callback
    self.Value = self.Multi and {} or self.Default
    self.Open = false
    self.DependsOn = config.DependsOn
    self.Tooltip = config.Tooltip
    self.SpecialType = config.SpecialType
    self.PlayerConnections = {}
    
    if self.Multi and self.Default then
        for _, v in ipairs(self.Default) do
            self.Value[v] = true
        end
    end
    
    if self.SpecialType == "Player" then
        self:SetupPlayerDropdown()
    end
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    local label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -32, 0, 18),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 11,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    self.ValueLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -32, 0, 16),
        Position = UDim2.new(0, 12, 0, 20),
        BackgroundTransparency = 1,
        Text = self:GetDisplayText(),
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.Container
    })
    
    local arrow = Utility:Create("TextLabel", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 10,
        Font = SecretLib.Font,
        Parent = self.Container
    })
    
    local button = Utility:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "",
        Parent = self.Container
    })
    
    Utility:AddRipple(button)
    
    self.DropdownList = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 100,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.DropdownList
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Parent = self.DropdownList
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.DropdownList
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = self.DropdownList
    })
    
    for _, option in ipairs(self.Options) do
        self:CreateOption(option)
    end
    
    button.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = self.Value
    end
    
    DependencyManager:RegisterElement(self, config)
    
    if self.Tooltip then
        local Tooltip = 
        Tooltip:AddToElement(self, self.Tooltip)
    end
    
    if self.Index then
        getgenv().Options[self.Index] = self
    end
    
    tab:UpdateCanvasSize()
    
    return self
end

function Dropdown:SetupPlayerDropdown()
    local Players = game:GetService("Players")
    
    local function updatePlayers()
        local playerNames = {}
        for _, player in ipairs(Players:GetPlayers()) do
            table.insert(playerNames, player.Name)
        end
        self:SetOptions(playerNames)
    end
    
    updatePlayers()
    
    local addedConnection = Players.PlayerAdded:Connect(function()
        updatePlayers()
    end)
    
    local removingConnection = Players.PlayerRemoving:Connect(function()
        task.wait(0.1)
        updatePlayers()
    end)
    
    table.insert(self.PlayerConnections, addedConnection)
    table.insert(self.PlayerConnections, removingConnection)
    table.insert(SecretLib.Connections, addedConnection)
    table.insert(SecretLib.Connections, removingConnection)
end

function Dropdown:OnChanged(callback)
    local oldCallback = self.Callback
    self.Callback = function(...)
        if oldCallback then
            oldCallback(...)
        end
        callback(...)
    end
    return self
end

function Dropdown:SetOptions(options)
    self.Options = options
    
    if self.OptionsContainer then
        self.OptionsContainer:ClearAllChildren()
        
        Utility:Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.OptionsContainer
        })
        
        for _, option in ipairs(options) do
            self:CreateOption(option)
        end
    end
    
    if not self.Multi then
        if not table.find(options, self.Value) then
            self.Value = options[1] or nil
            self:UpdateDisplay()
        end
    end
end

function Dropdown:CreateOption(option)
    local isSelected = self.Multi and self.Value[option] or self.Value == option
    
    local optionButton = Utility:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = isSelected and SecretLib.Theme.Accent or SecretLib.Theme.SurfaceHover,
        BorderSizePixel = 0,
        Text = option,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 12,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.DropdownList
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = optionButton
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        Parent = optionButton
    })
    
    Utility:AddRipple(optionButton)
    
    optionButton.MouseEnter:Connect(function()
        if not (self.Multi and self.Value[option] or self.Value == option) then
            Utility:Tween(optionButton, "BackgroundColor3", SecretLib.Theme.Border, SecretLib.SpringConfig.Snappy)
        end
    end)
    
    optionButton.MouseLeave:Connect(function()
        local isNowSelected = self.Multi and self.Value[option] or self.Value == option
        Utility:Tween(optionButton, "BackgroundColor3", isNowSelected and SecretLib.Theme.Accent or SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
    end)
    
    optionButton.MouseButton1Click:Connect(function()
        if self.Multi then
            self.Value[option] = not self.Value[option]
            
            Utility:Tween(optionButton, "BackgroundColor3", self.Value[option] and SecretLib.Theme.Accent or SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
        else
            for _, btn in ipairs(self.DropdownList:GetChildren()) do
                if btn:IsA("TextButton") then
                    Utility:Tween(btn, "BackgroundColor3", SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
                end
            end
            
            self.Value = option
            Utility:Tween(optionButton, "BackgroundColor3", SecretLib.Theme.Accent, SecretLib.SpringConfig.Snappy)
            
            task.delay(0.15, function()
                self:Toggle()
            end)
        end
        
        self.ValueLabel.Text = self:GetDisplayText()
        
        if self.Flag then
            SecretLib.Flags[self.Flag] = self.Value
        end
        
        if self.Callback then
            task.spawn(self.Callback, self.Value)
        end
    end)
end

function Dropdown:GetDisplayText()
    if self.Multi then
        local selected = {}
        for option, enabled in pairs(self.Value) do
            if enabled then
                table.insert(selected, option)
            end
        end
        return #selected > 0 and table.concat(selected, ", ") or "None"
    else
        return self.Value or "None"
    end
end

function Dropdown:Toggle()
    self.Open = not self.Open
    
    if self.Open then
        local contentHeight = self.DropdownList.UIListLayout.AbsoluteContentSize.Y + 8
        self.DropdownList.Visible = true
        Utility:Tween(self.DropdownList, "Size", UDim2.new(1, 0, 0, math.min(contentHeight, 200)), SecretLib.SpringConfig.Bouncy)
        Utility:Tween(self.Container, "Size", UDim2.new(1, 0, 0, 44 + math.min(contentHeight, 200)), SecretLib.SpringConfig.Bouncy)
    else
        Utility:Tween(self.DropdownList, "Size", UDim2.new(1, 0, 0, 0), SecretLib.SpringConfig.Snappy)
        Utility:Tween(self.Container, "Size", UDim2.new(1, 0, 0, 40), SecretLib.SpringConfig.Snappy)
        
        task.delay(0.2, function()
            if not self.Open then
                self.DropdownList.Visible = false
            end
        end)
    end
end

function Dropdown:SetValue(value)
    self.Value = value
    self.ValueLabel.Text = self:GetDisplayText()
    
    for _, btn in ipairs(self.DropdownList:GetChildren()) do
        if btn:IsA("TextButton") then
            local isSelected = self.Multi and self.Value[btn.Text] or self.Value == btn.Text
            Utility:Tween(btn, "BackgroundColor3", isSelected and SecretLib.Theme.Accent or SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
        end
    end
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = value
        DependencyManager:OnFlagChanged(self.Flag)
    end
    
    if self.Callback then
        task.spawn(self.Callback, value)
    end
end

return Dropdown

end

do

local Utility = 
local DependencyManager = 

local Input = {}
Input.__index = Input

function Input.new(tab, config)
    local self = setmetatable({}, Input)
    
    self.Name = config.Name or config.Text or "Input"
    self.Default = config.Default or ""
    self.Placeholder = config.Placeholder or "Enter text..."
    self.Numeric = config.Numeric or false
    self.Finished = config.Finished or false
    self.MaxLength = config.MaxLength
    self.Flag = config.Flag
    self.Index = config.Index or config.Flag
    self.Callback = config.Callback
    self.Value = self.Default
    self.Debounce = config.Debounce or 0.3
    self.DependsOn = config.DependsOn
    self.Tooltip = config.Tooltip
    self.LastCall = 0
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    local label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 11,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    local inputBg = Utility:Create("Frame", {
        Size = UDim2.new(1, -24, 0, 32),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundColor3 = SecretLib.Theme.Background,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = inputBg
    })
    
    self.TextBox = Utility:Create("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Value,
        PlaceholderText = self.Placeholder,
        TextColor3 = SecretLib.Theme.Text,
        PlaceholderColor3 = SecretLib.Theme.TextDim,
        TextSize = 12,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        MaxVisibleGraphemes = self.MaxLength,
        Parent = inputBg
    })
    
    self.TextBox.Focused:Connect(function()
        Utility:Tween(inputBg, "BackgroundColor3", SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
    end)
    
    self.TextBox.FocusLost:Connect(function(enterPressed)
        Utility:Tween(inputBg, "BackgroundColor3", SecretLib.Theme.Background, SecretLib.SpringConfig.Snappy)
        
        if enterPressed then
            local value = self.TextBox.Text
            
            if self.Numeric then
                value = tonumber(value) or 0
                self.TextBox.Text = tostring(value)
            end
            
            self.Value = value
            
            if self.Flag then
                SecretLib.Flags[self.Flag] = value
            end
            
            if self.Callback then
                task.spawn(self.Callback, value)
            end
        end
    end)
    
    if self.Finished then
        self.TextBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local text = self.TextBox.Text
                if self.MaxLength then
                    text = text:sub(1, self.MaxLength)
                    self.TextBox.Text = text
                end
                
                if self.Numeric then
                    local filtered = text:gsub("[^%d%.%-]", "")
                    self.TextBox.Text = filtered
                    local value = tonumber(filtered) or 0
                    self:SetValue(value)
                else
                    self:SetValue(text)
                end
            end
        end)
    else
        if self.Numeric then
            self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                local text = self.TextBox.Text
                if self.MaxLength then
                    text = text:sub(1, self.MaxLength)
                    self.TextBox.Text = text
                end
                
                local filtered = text:gsub("[^%d%.%-]", "")
                
                if filtered ~= text then
                    self.TextBox.Text = filtered
                end
                
                local value = tonumber(filtered) or 0
                self:SetValue(value)
            end)
        else
            self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                local text = self.TextBox.Text
                if self.MaxLength then
                    text = text:sub(1, self.MaxLength)
                    self.TextBox.Text = text
                end
                self:SetValue(text)
            end)
        end
    end
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = self.Value
    end
    
    DependencyManager:RegisterElement(self, config)
    
    if self.Tooltip then
        local Tooltip = 
        Tooltip:AddToElement(self, self.Tooltip)
    end
    
    if self.Index then
        getgenv().Options[self.Index] = self
    end
    
    tab:UpdateCanvasSize()
    
    return self
end

function Input:OnChanged(callback)
    local oldCallback = self.Callback
    self.Callback = function(...)
        if oldCallback then
            oldCallback(...)
        end
        callback(...)
    end
    return self
end

function Input:SetValue(value)
    self.Value = value
    self.TextBox.Text = tostring(value)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = value
        DependencyManager:OnFlagChanged(self.Flag)
    end
    
    if self.Callback then
        local now = tick()
        if now - self.LastCall >= self.Debounce then
            self.LastCall = now
            task.spawn(self.Callback, value)
        end
    end
end

return Input

end

do

local Utility = 

local Label = {}
Label.__index = Label

function Label.new(tab, config)
    local self = setmetatable({}, Label)
    
    self.Text = config.Text or "Label"
    self.Center = config.Center or false
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tab.Container
    })
    
    self.Label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Text,
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 12,
        Font = SecretLib.Font,
        TextXAlignment = self.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Container
    })
    
    tab:UpdateCanvasSize()
    
    return self
end

function Label:SetText(text)
    self.Text = text
    self.Label.Text = text
end

function Label:AddColorPicker(config)
    local ColorPicker = 
    config = config or {}
    
    local colorpicker = ColorPicker.new(self.Tab or self.TabBox.ParentTab, config)
    colorpicker.Container.Parent = self.Container.Parent
    colorpicker.Container.LayoutOrder = self.Container.LayoutOrder + 0.001
    
    return colorpicker
end

function Label:AddKeyPicker(config)
    local Keybind = 
    config = config or {}
    
    local keybind = Keybind.new(self.Tab or self.TabBox.ParentTab, config)
    keybind.Container.Parent = self.Container.Parent
    keybind.Container.LayoutOrder = self.Container.LayoutOrder + 0.001
    
    return keybind
end

return Label

end

do

local Utility = 
local DependencyManager = 
local UserInputService = game:GetService("UserInputService")

local Keybind = {}
Keybind.__index = Keybind

local KeybindRegistry = {}

local KeyCodeNames = {
    [Enum.KeyCode.Unknown] = "None",
    [Enum.KeyCode.Backspace] = "Backspace",
    [Enum.KeyCode.Tab] = "Tab",
    [Enum.KeyCode.Clear] = "Clear",
    [Enum.KeyCode.Return] = "Enter",
    [Enum.KeyCode.Pause] = "Pause",
    [Enum.KeyCode.Escape] = "Esc",
    [Enum.KeyCode.Space] = "Space",
    [Enum.KeyCode.QuotedDouble] = '"',
    [Enum.KeyCode.Hash] = "#",
    [Enum.KeyCode.Dollar] = "$",
    [Enum.KeyCode.Percent] = "%",
    [Enum.KeyCode.Ampersand] = "&",
    [Enum.KeyCode.Quote] = "'",
    [Enum.KeyCode.LeftParenthesis] = "(",
    [Enum.KeyCode.RightParenthesis] = ")",
    [Enum.KeyCode.Asterisk] = "*",
    [Enum.KeyCode.Plus] = "+",
    [Enum.KeyCode.Comma] = ",",
    [Enum.KeyCode.Minus] = "-",
    [Enum.KeyCode.Period] = ".",
    [Enum.KeyCode.Slash] = "/",
    [Enum.KeyCode.Zero] = "0",
    [Enum.KeyCode.One] = "1",
    [Enum.KeyCode.Two] = "2",
    [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4",
    [Enum.KeyCode.Five] = "5",
    [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7",
    [Enum.KeyCode.Eight] = "8",
    [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.Colon] = ":",
    [Enum.KeyCode.Semicolon] = ";",
    [Enum.KeyCode.LessThan] = "<",
    [Enum.KeyCode.Equals] = "=",
    [Enum.KeyCode.GreaterThan] = ">",
    [Enum.KeyCode.Question] = "?",
    [Enum.KeyCode.At] = "@",
    [Enum.KeyCode.LeftBracket] = "[",
    [Enum.KeyCode.BackSlash] = "\\",
    [Enum.KeyCode.RightBracket] = "]",
    [Enum.KeyCode.Caret] = "^",
    [Enum.KeyCode.Underscore] = "_",
    [Enum.KeyCode.Backquote] = "`",
    [Enum.KeyCode.A] = "A",
    [Enum.KeyCode.B] = "B",
    [Enum.KeyCode.C] = "C",
    [Enum.KeyCode.D] = "D",
    [Enum.KeyCode.E] = "E",
    [Enum.KeyCode.F] = "F",
    [Enum.KeyCode.G] = "G",
    [Enum.KeyCode.H] = "H",
    [Enum.KeyCode.I] = "I",
    [Enum.KeyCode.J] = "J",
    [Enum.KeyCode.K] = "K",
    [Enum.KeyCode.L] = "L",
    [Enum.KeyCode.M] = "M",
    [Enum.KeyCode.N] = "N",
    [Enum.KeyCode.O] = "O",
    [Enum.KeyCode.P] = "P",
    [Enum.KeyCode.Q] = "Q",
    [Enum.KeyCode.R] = "R",
    [Enum.KeyCode.S] = "S",
    [Enum.KeyCode.T] = "T",
    [Enum.KeyCode.U] = "U",
    [Enum.KeyCode.V] = "V",
    [Enum.KeyCode.W] = "W",
    [Enum.KeyCode.X] = "X",
    [Enum.KeyCode.Y] = "Y",
    [Enum.KeyCode.Z] = "Z",
    [Enum.KeyCode.LeftCurly] = "{",
    [Enum.KeyCode.Pipe] = "|",
    [Enum.KeyCode.RightCurly] = "}",
    [Enum.KeyCode.Tilde] = "~",
    [Enum.KeyCode.Delete] = "Del",
    [Enum.KeyCode.KeypadZero] = "Num0",
    [Enum.KeyCode.KeypadOne] = "Num1",
    [Enum.KeyCode.KeypadTwo] = "Num2",
    [Enum.KeyCode.KeypadThree] = "Num3",
    [Enum.KeyCode.KeypadFour] = "Num4",
    [Enum.KeyCode.KeypadFive] = "Num5",
    [Enum.KeyCode.KeypadSix] = "Num6",
    [Enum.KeyCode.KeypadSeven] = "Num7",
    [Enum.KeyCode.KeypadEight] = "Num8",
    [Enum.KeyCode.KeypadNine] = "Num9",
    [Enum.KeyCode.KeypadPeriod] = "Num.",
    [Enum.KeyCode.KeypadDivide] = "Num/",
    [Enum.KeyCode.KeypadMultiply] = "Num*",
    [Enum.KeyCode.KeypadMinus] = "Num-",
    [Enum.KeyCode.KeypadPlus] = "Num+",
    [Enum.KeyCode.KeypadEnter] = "NumEnter",
    [Enum.KeyCode.KeypadEquals] = "Num=",
    [Enum.KeyCode.Up] = "Up",
    [Enum.KeyCode.Down] = "Down",
    [Enum.KeyCode.Right] = "Right",
    [Enum.KeyCode.Left] = "Left",
    [Enum.KeyCode.Insert] = "Ins",
    [Enum.KeyCode.Home] = "Home",
    [Enum.KeyCode.End] = "End",
    [Enum.KeyCode.PageUp] = "PgUp",
    [Enum.KeyCode.PageDown] = "PgDn",
    [Enum.KeyCode.F1] = "F1",
    [Enum.KeyCode.F2] = "F2",
    [Enum.KeyCode.F3] = "F3",
    [Enum.KeyCode.F4] = "F4",
    [Enum.KeyCode.F5] = "F5",
    [Enum.KeyCode.F6] = "F6",
    [Enum.KeyCode.F7] = "F7",
    [Enum.KeyCode.F8] = "F8",
    [Enum.KeyCode.F9] = "F9",
    [Enum.KeyCode.F10] = "F10",
    [Enum.KeyCode.F11] = "F11",
    [Enum.KeyCode.F12] = "F12",
    [Enum.KeyCode.LeftShift] = "LShift",
    [Enum.KeyCode.RightShift] = "RShift",
    [Enum.KeyCode.LeftControl] = "LCtrl",
    [Enum.KeyCode.RightControl] = "RCtrl",
    [Enum.KeyCode.LeftAlt] = "LAlt",
    [Enum.KeyCode.RightAlt] = "RAlt",
    [Enum.KeyCode.LeftMeta] = "LMeta",
    [Enum.KeyCode.RightMeta] = "RMeta",
    [Enum.KeyCode.CapsLock] = "Caps",
    [Enum.KeyCode.NumLock] = "NumLock",
    [Enum.KeyCode.ScrollLock] = "ScrollLock",
}

function Keybind.new(tab, config)
    local self = setmetatable({}, Keybind)
    
    self.Name = config.Name or "Keybind"
    self.Default = config.Default or Enum.KeyCode.Unknown
    self.Flag = config.Flag
    self.Index = config.Index or config.Flag
    self.Callback = config.Callback
    self.ChangedCallback = config.ChangedCallback
    self.Value = self.Default
    self.Mode = config.Mode or "Toggle"
    self.SyncToggleState = config.SyncToggleState
    self.NoUI = config.NoUI or false
    self.State = false
    self.Binding = false
    self.Id = tostring(self)
    self.DependsOn = config.DependsOn
    self.Tooltip = config.Tooltip
    self.ParentToggle = nil
    
    if typeof(self.Default) == "string" then
        self.Value = Enum.KeyCode[self.Default] or Enum.KeyCode.Unknown
    end
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    local label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    self.KeyDisplay = Utility:Create("TextButton", {
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -92, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = SecretLib.Theme.Background,
        BorderSizePixel = 0,
        Text = self:GetKeyName(self.Value),
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 12,
        Font = SecretLib.FontBold,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = self.KeyDisplay
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Parent = self.KeyDisplay
    })
    
    Utility:AddRipple(self.KeyDisplay)
    
    self.KeyDisplay.MouseButton1Click:Connect(function()
        self:StartBinding()
    end)
    
    self.ModeDisplay = Utility:Create("TextLabel", {
        Size = UDim2.new(0, 60, 0, 14),
        Position = UDim2.new(1, -92, 0, -2),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        Text = "[" .. self.Mode .. "]",
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 9,
        Font = SecretLib.Font,
        Parent = self.Container
    })
    
    self.KeyDisplay.MouseEnter:Connect(function()
        if not self.Binding then
            Utility:Tween(self.KeyDisplay, "BackgroundColor3", SecretLib.Theme.SurfaceHover, SecretLib.SpringConfig.Snappy)
        end
    end)
    
    self.KeyDisplay.MouseLeave:Connect(function()
        if not self.Binding then
            Utility:Tween(self.KeyDisplay, "BackgroundColor3", SecretLib.Theme.Background, SecretLib.SpringConfig.Snappy)
        end
    end)
    
    KeybindRegistry[self.Id] = self
    
    local inputConnection
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == self.Value then
            if self.Mode == "Always" then
                self.State = true
                if self.Callback then
                    task.spawn(self.Callback, true)
                end
            elseif self.Mode == "Toggle" then
                self.State = not self.State
                if self.SyncToggleState and self.ParentToggle then
                    self.ParentToggle:SetValue(self.State)
                end
                if self.Callback then
                    task.spawn(self.Callback, self.State)
                end
            elseif self.Mode == "Hold" then
                self.State = true
                if self.Callback then
                    task.spawn(self.Callback, true)
                end
            end
        end
    end)
    
    local inputEndConnection
    inputEndConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == self.Value and self.Mode == "Hold" then
            self.State = false
            if self.Callback then
                task.spawn(self.Callback, false)
            end
        end
    end)
    
    table.insert(SecretLib.Connections, inputEndConnection)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = self.Value
    end
    
    DependencyManager:RegisterElement(self, config)
    
    if self.Tooltip then
        local Tooltip = 
        Tooltip:AddToElement(self, self.Tooltip)
    end
    
    if self.Index then
        getgenv().Options[self.Index] = self
    end
    
    if self.NoUI then
        self.Container.Visible = false
    end
    
    tab:UpdateCanvasSize()
    
    return self
end

function Keybind:GetState()
    return self.State
end

function Keybind:SetMode(mode)
    if mode == "Always" or mode == "Toggle" or mode == "Hold" then
        self.Mode = mode
        self.ModeDisplay.Text = "[" .. mode .. "]"
        self.State = false
    end
end

function Keybind:OnClick(callback)
    local oldCallback = self.Callback
    self.Callback = function(...)
        if oldCallback then
            oldCallback(...)
        end
        callback(...)
    end
end

function Keybind:GetKeyName(keyCode)
    return KeyCodeNames[keyCode] or "None"
end

function Keybind:StartBinding()
    if self.Binding then return end
    
    self.Binding = true
    self.KeyDisplay.Text = "..."
    Utility:Tween(self.KeyDisplay, "BackgroundColor3", SecretLib.Theme.Accent, SecretLib.SpringConfig.Snappy)
    
    local bindConnection
    bindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            bindConnection:Disconnect()
            
            if input.KeyCode == Enum.KeyCode.Escape then
                self:SetKey(Enum.KeyCode.Unknown)
            else
                local conflict = self:CheckConflict(input.KeyCode)
                if conflict then
                    SecretLib:Notify({
                        Title = "Keybind Conflict",
                        Message = string.format("Key '%s' is already bound to '%s'", self:GetKeyName(input.KeyCode), conflict.Name),
                        Type = "warning",
                        Duration = 3
                    })
                end
                
                self:SetKey(input.KeyCode)
            end
            
            self.Binding = false
            Utility:Tween(self.KeyDisplay, "BackgroundColor3", SecretLib.Theme.Background, SecretLib.SpringConfig.Snappy)
        end
    end)
    
    task.delay(5, function()
        if self.Binding then
            bindConnection:Disconnect()
            self.Binding = false
            self.KeyDisplay.Text = self:GetKeyName(self.Value)
            Utility:Tween(self.KeyDisplay, "BackgroundColor3", SecretLib.Theme.Background, SecretLib.SpringConfig.Snappy)
        end
    end)
end

function Keybind:CheckConflict(keyCode)
    if keyCode == Enum.KeyCode.Unknown then return nil end
    
    for id, keybind in pairs(KeybindRegistry) do
        if id ~= self.Id and keybind.Value == keyCode then
            return keybind
        end
    end
    
    return nil
end

function Keybind:SetKey(keyCode)
    self.Value = keyCode
    self.KeyDisplay.Text = self:GetKeyName(keyCode)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = keyCode
        DependencyManager:OnFlagChanged(self.Flag)
    end
    
    if self.Callback then
        task.spawn(self.Callback, keyCode)
    end
end

function Keybind:Destroy()
    if self.InputConnection then
        self.InputConnection:Disconnect()
    end
    
    KeybindRegistry[self.Id] = nil
    
    if self.Container then
        self.Container:Destroy()
    end
end

return Keybind

end

do

local Utility = 
local DependencyManager = 
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker.new(tab, config)
    local self = setmetatable({}, ColorPicker)
    
    self.Name = config.Name or "ColorPicker"
    self.Default = config.Default or Color3.fromRGB(255, 255, 255)
    self.Flag = config.Flag
    self.Index = config.Index or config.Flag
    self.Callback = config.Callback
    self.Value = self.Default
    self.Alpha = config.Alpha or 1
    self.Open = false
    self.DependsOn = config.DependsOn
    self.Tooltip = config.Tooltip
    
    local h, s, v = self.Value:ToHSV()
    self.Hue = h
    self.Saturation = s
    self.Brightness = v
    
    self.RecentColors = {}
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    local label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -56, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    self.ColorDisplay = Utility:Create("TextButton", {
        Size = UDim2.new(0, 36, 0, 28),
        Position = UDim2.new(1, -48, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = self.Value,
        BorderSizePixel = 0,
        Text = "",
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = self.ColorDisplay
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 2,
        Parent = self.ColorDisplay
    })
    
    Utility:AddRipple(self.ColorDisplay)
    
    self.PickerFrame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 100,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.PickerFrame
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Parent = self.PickerFrame
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        Parent = self.PickerFrame
    })
    
    self.SaturationBrightness = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 150),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1),
        BorderSizePixel = 0,
        Parent = self.PickerFrame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = self.SaturationBrightness
    })
    
    local whiteness = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = self.SaturationBrightness
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = whiteness
    })
    
    Utility:Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Rotation = 0,
        Parent = whiteness
    })
    
    local blackness = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = self.SaturationBrightness
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = blackness
    })
    
    Utility:Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Rotation = 90,
        Parent = blackness
    })
    
    self.SBCursor = Utility:Create("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(self.Saturation, 0, 1 - self.Brightness, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = self.SaturationBrightness
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.SBCursor
    })
    
    Utility:Create("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 2,
        Parent = self.SBCursor
    })
    
    self.HueSlider = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 158),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = self.PickerFrame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = self.HueSlider
    })
    
    Utility:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        }),
        Rotation = 0,
        Parent = self.HueSlider
    })
    
    self.HueCursor = Utility:Create("Frame", {
        Size = UDim2.new(0, 4, 1, 4),
        Position = UDim2.new(self.Hue, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = self.HueSlider
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.HueCursor
    })
    
    Utility:Create("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 2,
        Parent = self.HueCursor
    })
    
    self.AlphaSlider = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 182),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = self.PickerFrame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = self.AlphaSlider
    })
    
    local alphaGradient = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Value,
        BorderSizePixel = 0,
        Parent = self.AlphaSlider
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = alphaGradient
    })
    
    self.AlphaGradient = Utility:Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Rotation = 0,
        Parent = alphaGradient
    })
    
    self.AlphaCursor = Utility:Create("Frame", {
        Size = UDim2.new(0, 4, 1, 4),
        Position = UDim2.new(self.Alpha, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = self.AlphaSlider
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.AlphaCursor
    })
    
    Utility:Create("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 2,
        Parent = self.AlphaCursor
    })
    
    local rgbFrame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 206),
        BackgroundTransparency = 1,
        Parent = self.PickerFrame
    })
    
    local rgb = {math.floor(self.Value.R * 255), math.floor(self.Value.G * 255), math.floor(self.Value.B * 255)}
    
    self.RGBInputs = {}
    local labels = {"R:", "G:", "B:"}
    for i = 1, 3 do
        local labelText = Utility:Create("TextLabel", {
            Size = UDim2.new(0, 15, 1, 0),
            Position = UDim2.new((i-1) * 0.33, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = labels[i],
            TextColor3 = SecretLib.Theme.TextDim,
            TextSize = 11,
            Font = SecretLib.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = rgbFrame
        })
        
        local inputBg = Utility:Create("Frame", {
            Size = UDim2.new(0.33, -20, 1, 0),
            Position = UDim2.new((i-1) * 0.33, 18, 0, 0),
            BackgroundColor3 = SecretLib.Theme.Background,
            BorderSizePixel = 0,
            Parent = rgbFrame
        })
        
        Utility:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = inputBg
        })
        
        local input = Utility:Create("TextBox", {
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(rgb[i]),
            TextColor3 = SecretLib.Theme.Text,
            TextSize = 11,
            Font = SecretLib.Font,
            TextXAlignment = Enum.TextXAlignment.Center,
            ClearTextOnFocus = false,
            Parent = inputBg
        })
        
        self.RGBInputs[i] = input
        
        input.FocusLost:Connect(function()
            local value = tonumber(input.Text) or 0
            value = math.clamp(value, 0, 255)
            input.Text = tostring(value)
            
            local r = tonumber(self.RGBInputs[1].Text) or 0
            local g = tonumber(self.RGBInputs[2].Text) or 0
            local b = tonumber(self.RGBInputs[3].Text) or 0
            
            self:SetColor(Color3.fromRGB(r, g, b))
        end)
        
        input:GetPropertyChangedSignal("Text"):Connect(function()
            local text = input.Text
            local filtered = text:gsub("[^%d]", "")
            if filtered ~= text then
                input.Text = filtered
            end
        end)
    end
    
    local hexFrame = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 242),
        BackgroundTransparency = 1,
        Parent = self.PickerFrame
    })
    
    local hexLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0, 30, 1, 0),
        BackgroundTransparency = 1,
        Text = "Hex:",
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 11,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hexFrame
    })
    
    local hexInputBg = Utility:Create("Frame", {
        Size = UDim2.new(1, -35, 1, 0),
        Position = UDim2.new(0, 33, 0, 0),
        BackgroundColor3 = SecretLib.Theme.Background,
        BorderSizePixel = 0,
        Parent = hexFrame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = hexInputBg
    })
    
    self.HexInput = Utility:Create("TextBox", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text = self:ColorToHex(self.Value),
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 11,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        Parent = hexInputBg
    })
    
    self.HexInput.FocusLost:Connect(function()
        local color = self:HexToColor(self.HexInput.Text)
        if color then
            self:SetColor(color)
        else
            self.HexInput.Text = self:ColorToHex(self.Value)
        end
    end)
    
    self:SetupInteraction()
    
    self.ColorDisplay.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = {Color = self.Value, Alpha = self.Alpha}
    end
    
    DependencyManager:RegisterElement(self, config)
    
    if self.Tooltip then
        local Tooltip = 
        Tooltip:AddToElement(self, self.Tooltip)
    end
    
    if self.Index then
        getgenv().Options[self.Index] = self
    end
    
    tab:UpdateCanvasSize()
    
    return self
end

function ColorPicker:SetupInteraction()
    local sbDragging = false
    local hueDragging = false
    local alphaDragging = false
    
    self.SaturationBrightness.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sbDragging = true
            self:UpdateSB(input)
        end
    end)
    
    self.SaturationBrightness.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sbDragging = false
        end
    end)
    
    self.HueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            self:UpdateHue(input)
        end
    end)
    
    self.HueSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)
    
    self.AlphaSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            alphaDragging = true
            self:UpdateAlpha(input)
        end
    end)
    
    self.AlphaSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            alphaDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if sbDragging then
                self:UpdateSB(input)
            elseif hueDragging then
                self:UpdateHue(input)
            elseif alphaDragging then
                self:UpdateAlpha(input)
            end
        end
    end)
end

function ColorPicker:UpdateSB(input)
    local relativeX = math.clamp((input.Position.X - self.SaturationBrightness.AbsolutePosition.X) / self.SaturationBrightness.AbsoluteSize.X, 0, 1)
    local relativeY = math.clamp((input.Position.Y - self.SaturationBrightness.AbsolutePosition.Y) / self.SaturationBrightness.AbsoluteSize.Y, 0, 1)
    
    self.Saturation = relativeX
    self.Brightness = 1 - relativeY
    
    self.SBCursor.Position = UDim2.new(relativeX, 0, relativeY, 0)
    
    local color = Color3.fromHSV(self.Hue, self.Saturation, self.Brightness)
    self:SetColor(color, true)
end

function ColorPicker:UpdateHue(input)
    local relativeX = math.clamp((input.Position.X - self.HueSlider.AbsolutePosition.X) / self.HueSlider.AbsoluteSize.X, 0, 1)
    
    self.Hue = relativeX
    self.HueCursor.Position = UDim2.new(relativeX, 0, 0.5, 0)
    
    self.SaturationBrightness.BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1)
    
    local color = Color3.fromHSV(self.Hue, self.Saturation, self.Brightness)
    self:SetColor(color, true)
end

function ColorPicker:UpdateAlpha(input)
    local relativeX = math.clamp((input.Position.X - self.AlphaSlider.AbsolutePosition.X) / self.AlphaSlider.AbsoluteSize.X, 0, 1)
    
    self.Alpha = relativeX
    self.AlphaCursor.Position = UDim2.new(relativeX, 0, 0.5, 0)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = {Color = self.Value, Alpha = self.Alpha}
    end
    
    if self.Callback then
        task.spawn(self.Callback, self.Value, self.Alpha)
    end
end

function ColorPicker:SetColor(color, fromPicker)
    self.Value = color
    self.ColorDisplay.BackgroundColor3 = color
    
    if not fromPicker then
        local h, s, v = color:ToHSV()
        self.Hue = h
        self.Saturation = s
        self.Brightness = v
        
        self.SBCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        self.HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        self.SaturationBrightness.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    end
    
    self.RGBInputs[1].Text = tostring(math.floor(color.R * 255))
    self.RGBInputs[2].Text = tostring(math.floor(color.G * 255))
    self.RGBInputs[3].Text = tostring(math.floor(color.B * 255))
    self.HexInput.Text = self:ColorToHex(color)
    
    self.AlphaSlider:FindFirstChildOfClass("Frame").BackgroundColor3 = color
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = {Color = color, Alpha = self.Alpha}
        DependencyManager:OnFlagChanged(self.Flag)
    end
    
    if self.Callback then
        task.spawn(self.Callback, color, self.Alpha)
    end
end

function ColorPicker:ColorToHex(color)
    return string.format("#%02X%02X%02X", 
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

function ColorPicker:HexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b)
        end
    end
    return nil
end

function ColorPicker:Toggle()
    self.Open = not self.Open
    
    if self.Open then
        self.PickerFrame.Visible = true
        Utility:Tween(self.PickerFrame, "Size", UDim2.new(1, 0, 0, 278), SecretLib.SpringConfig.Bouncy)
        Utility:Tween(self.Container, "Size", UDim2.new(1, 0, 0, 322), SecretLib.SpringConfig.Bouncy)
    else
        Utility:Tween(self.PickerFrame, "Size", UDim2.new(1, 0, 0, 0), SecretLib.SpringConfig.Snappy)
        Utility:Tween(self.Container, "Size", UDim2.new(1, 0, 0, 40), SecretLib.SpringConfig.Snappy)
        
        task.delay(0.2, function()
            if not self.Open then
                self.PickerFrame.Visible = false
            end
        end)
    end
    self:UpdateDisplay()
end

function ColorPicker:SetValueRGB(color)
    self:SetColor(color, false)
end

function ColorPicker:OnChanged(callback)
    local oldCallback = self.Callback
    self.Callback = function(...)
        if oldCallback then
            oldCallback(...)
        end
        callback(...)
    end
    return self
end

return ColorPicker

end

do

local Utility = 
local DependencyManager = 

local Paragraph = {}
Paragraph.__index = Paragraph

function Paragraph.new(tab, config)
    local self = setmetatable({}, Paragraph)
    
    self.Title = config.Title or "Paragraph"
    self.Content = config.Content or ""
    self.DependsOn = config.DependsOn
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        Parent = self.Container
    })
    
    self.TitleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 14,
        Font = SecretLib.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Container
    })
    
    self.ContentLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Content,
        TextColor3 = SecretLib.Theme.TextDim,
        TextSize = 12,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Container
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.Container
    })
    
    DependencyManager:RegisterElement(self, config)
    
    tab:UpdateCanvasSize()
    
    return self
end

function Paragraph:SetTitle(title)
    self.Title = title
    self.TitleLabel.Text = title
end

function Paragraph:SetContent(content)
    self.Content = content
    self.ContentLabel.Text = content
end

return Paragraph

end

do

local Utility = 
local DependencyManager = 

local Divider = {}
Divider.__index = Divider

function Divider.new(tab, config)
    local self = setmetatable({}, Divider)
    
    self.Text = config.Text
    self.DependsOn = config.DependsOn
    
    if self.Text then
        self.Container = Utility:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Parent = tab.Container
        })
        
        local leftLine = Utility:Create("Frame", {
            Size = UDim2.new(0.5, -40, 0, 1),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = SecretLib.Theme.Border,
            BorderSizePixel = 0,
            Parent = self.Container
        })
        
        local label = Utility:Create("TextLabel", {
            Size = UDim2.new(0, 70, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = self.Text,
            TextColor3 = SecretLib.Theme.TextDim,
            TextSize = 11,
            Font = SecretLib.Font,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = self.Container
        })
        
        local rightLine = Utility:Create("Frame", {
            Size = UDim2.new(0.5, -40, 0, 1),
            Position = UDim2.new(1, 0, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = SecretLib.Theme.Border,
            BorderSizePixel = 0,
            Parent = self.Container
        })
    else
        self.Container = Utility:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 12),
            BackgroundTransparency = 1,
            Parent = tab.Container
        })
        
        local line = Utility:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = SecretLib.Theme.Border,
            BorderSizePixel = 0,
            Parent = self.Container
        })
    end
    
    DependencyManager:RegisterElement(self, config)
    
    tab:UpdateCanvasSize()
    
    return self
end

return Divider

end

do

local Utility = 
local DependencyManager = 

local Image = {}
Image.__index = Image

function Image.new(tab, config)
    local self = setmetatable({}, Image)
    
    self.Name = config.Name or ""
    self.Image = config.Image or ""
    self.Size = config.Size or UDim2.new(1, 0, 0, 150)
    self.ScaleType = config.ScaleType or Enum.ScaleType.Fit
    self.DependsOn = config.DependsOn
    
    local height = self.Size.Y.Offset
    if self.Name ~= "" then
        height = height + 28
    end
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    if self.Name ~= "" then
        local label = Utility:Create("TextLabel", {
            Size = UDim2.new(1, -24, 0, 20),
            Position = UDim2.new(0, 12, 0, 8),
            BackgroundTransparency = 1,
            Text = self.Name,
            TextColor3 = SecretLib.Theme.Text,
            TextSize = 13,
            Font = SecretLib.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.Container
        })
    end
    
    local imageContainer = Utility:Create("Frame", {
        Size = UDim2.new(1, -24, 0, self.Size.Y.Offset),
        Position = UDim2.new(0, 12, 0, self.Name ~= "" and 32 or 12),
        BackgroundColor3 = SecretLib.Theme.Background,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = imageContainer
    })
    
    self.ImageLabel = Utility:Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = self.Image,
        ScaleType = self.ScaleType,
        Parent = imageContainer
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = self.ImageLabel
    })
    
    DependencyManager:RegisterElement(self, config)
    
    tab:UpdateCanvasSize()
    
    return self
end

function Image:SetImage(imageId)
    self.Image = imageId
    self.ImageLabel.Image = imageId
end

function Image:SetSize(size)
    self.Size = size
    local height = size.Y.Offset
    if self.Name ~= "" then
        height = height + 28
    end
    self.Container.Size = UDim2.new(1, 0, 0, height)
    self.ImageLabel.Parent.Size = UDim2.new(1, -24, 0, size.Y.Offset)
end

return Image

end

do

local Utility = 
local DependencyManager = 
local UserInputService = game:GetService("UserInputService")

local MultiSlider = {}
MultiSlider.__index = MultiSlider

function MultiSlider.new(tab, config)
    local self = setmetatable({}, MultiSlider)
    
    self.Name = config.Name or "Range Slider"
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.DefaultMin = config.DefaultMin or 25
    self.DefaultMax = config.DefaultMax or 75
    self.Increment = config.Increment or 1
    self.Flag = config.Flag
    self.Callback = config.Callback
    self.MinValue = self.DefaultMin
    self.MaxValue = self.DefaultMax
    self.Suffix = config.Suffix or ""
    self.DependsOn = config.DependsOn
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Container
    })
    
    local label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -120, 0, 20),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 13,
        Font = SecretLib.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    self.ValueLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(0, 100, 0, 20),
        Position = UDim2.new(1, -112, 0, 8),
        BackgroundTransparency = 1,
        Text = string.format("%s - %s%s", tostring(self.MinValue), tostring(self.MaxValue), self.Suffix),
        TextColor3 = SecretLib.Theme.Accent,
        TextSize = 13,
        Font = SecretLib.FontBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self.Container
    })
    
    self.SliderBg = Utility:Create("Frame", {
        Size = UDim2.new(1, -24, 0, 4),
        Position = UDim2.new(0, 12, 1, -16),
        BackgroundColor3 = SecretLib.Theme.Border,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.SliderBg
    })
    
    local minPos = (self.MinValue - self.Min) / (self.Max - self.Min)
    local maxPos = (self.MaxValue - self.Min) / (self.Max - self.Min)
    
    self.SliderFill = Utility:Create("Frame", {
        Size = UDim2.new(maxPos - minPos, 0, 1, 0),
        Position = UDim2.new(minPos, 0, 0, 0),
        BackgroundColor3 = SecretLib.Theme.Accent,
        BorderSizePixel = 0,
        Parent = self.SliderBg
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.SliderFill
    })
    
    self.MinKnob = Utility:Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(minPos, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = SecretLib.Theme.Text,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.SliderBg
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.MinKnob
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Accent,
        Thickness = 2,
        Parent = self.MinKnob
    })
    
    self.MaxKnob = Utility:Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(maxPos, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = SecretLib.Theme.Text,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.SliderBg
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.MaxKnob
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Accent,
        Thickness = 2,
        Parent = self.MaxKnob
    })
    
    self.DraggingMin = false
    self.DraggingMax = false
    
    self.MinKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.DraggingMin = true
            Utility:Tween(self.MinKnob, "Size", UDim2.new(0, 16, 0, 16), SecretLib.SpringConfig.Bouncy)
        end
    end)
    
    self.MinKnob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.DraggingMin = false
            Utility:Tween(self.MinKnob, "Size", UDim2.new(0, 12, 0, 12), SecretLib.SpringConfig.Bouncy)
        end
    end)
    
    self.MaxKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.DraggingMax = true
            Utility:Tween(self.MaxKnob, "Size", UDim2.new(0, 16, 0, 16), SecretLib.SpringConfig.Bouncy)
        end
    end)
    
    self.MaxKnob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.DraggingMax = false
            Utility:Tween(self.MaxKnob, "Size", UDim2.new(0, 12, 0, 12), SecretLib.SpringConfig.Bouncy)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if self.DraggingMin then
                self:UpdateMin(input)
            elseif self.DraggingMax then
                self:UpdateMax(input)
            end
        end
    end)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = {Min = self.MinValue, Max = self.MaxValue}
    end
    
    DependencyManager:RegisterElement(self, config)
    
    tab:UpdateCanvasSize()
    
    return self
end

function MultiSlider:UpdateMin(input)
    local relativeX = math.clamp((input.Position.X - self.SliderBg.AbsolutePosition.X) / self.SliderBg.AbsoluteSize.X, 0, 1)
    local value = self.Min + (self.Max - self.Min) * relativeX
    value = math.floor(value / self.Increment + 0.5) * self.Increment
    value = math.clamp(value, self.Min, self.MaxValue - self.Increment)
    
    self:SetMinValue(value)
end

function MultiSlider:UpdateMax(input)
    local relativeX = math.clamp((input.Position.X - self.SliderBg.AbsolutePosition.X) / self.SliderBg.AbsoluteSize.X, 0, 1)
    local value = self.Min + (self.Max - self.Min) * relativeX
    value = math.floor(value / self.Increment + 0.5) * self.Increment
    value = math.clamp(value, self.MinValue + self.Increment, self.Max)
    
    self:SetMaxValue(value)
end

function MultiSlider:SetMinValue(value)
    self.MinValue = value
    self:UpdateDisplay()
end

function MultiSlider:SetMaxValue(value)
    self.MaxValue = value
    self:UpdateDisplay()
end

function MultiSlider:UpdateDisplay()
    local minPos = (self.MinValue - self.Min) / (self.Max - self.Min)
    local maxPos = (self.MaxValue - self.Min) / (self.Max - self.Min)
    
    self.ValueLabel.Text = string.format("%s - %s%s", tostring(self.MinValue), tostring(self.MaxValue), self.Suffix)
    
    Utility:Tween(self.SliderFill, "Size", UDim2.new(maxPos - minPos, 0, 1, 0), SecretLib.SpringConfig.Snappy)
    Utility:Tween(self.SliderFill, "Position", UDim2.new(minPos, 0, 0, 0), SecretLib.SpringConfig.Snappy)
    Utility:Tween(self.MinKnob, "Position", UDim2.new(minPos, 0, 0.5, 0), SecretLib.SpringConfig.Snappy)
    Utility:Tween(self.MaxKnob, "Position", UDim2.new(maxPos, 0, 0.5, 0), SecretLib.SpringConfig.Snappy)
    
    if self.Flag then
        SecretLib.Flags[self.Flag] = {Min = self.MinValue, Max = self.MaxValue}
        DependencyManager:OnFlagChanged(self.Flag)
    end
    
    if self.Callback then
        task.spawn(self.Callback, self.MinValue, self.MaxValue)
    end
end

return MultiSlider

end

do

local Utility = 
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Watermark = {}
Watermark.__index = Watermark

function Watermark.new(config)
    local self = setmetatable({}, Watermark)
    
    self.Text = config.Text or "SecretLib"
    self.Format = config.Format
    self.Position = config.Position or UDim2.new(0, 10, 0, 10)
    self.ShowFPS = config.ShowFPS ~= false
    self.ShowPing = config.ShowPing ~= false
    self.ShowTime = config.ShowTime ~= false
    self.Visible = true
    
    self.Container = Utility:Create("Frame", {
        Size = UDim2.new(0, 200, 0, 28),
        Position = self.Position,
        BackgroundColor3 = SecretLib.Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 1000,
        Parent = SecretLib.ScreenGui
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Container
    })
    
    Utility:Create("UIStroke", {
        Color = SecretLib.Theme.Border,
        Thickness = 1,
        Parent = self.Container
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        Parent = self.Container
    })
    
    self.Label = Utility:Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = self:GetDisplayText(),
        TextColor3 = SecretLib.Theme.Text,
        TextSize = 12,
        Font = SecretLib.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    self.FPS = 0
    self.Ping = 0
    self.FrameCount = 0
    self.LastUpdate = tick()
    
    self.Connection = RunService.RenderStepped:Connect(function()
        self.FrameCount = self.FrameCount + 1
        
        local currentTime = tick()
        if currentTime - self.LastUpdate >= 1 then
            self.FPS = self.FrameCount
            self.FrameCount = 0
            self.LastUpdate = currentTime
            
            local player = Players.LocalPlayer
            if player then
                self.Ping = math.floor(player:GetNetworkPing() * 1000)
            end
            
            self.Label.Text = self:GetDisplayText()
            
            local textSize = Utility:GetTextSize(self.Label.Text, 12, SecretLib.FontBold, math.huge)
            self.Container.Size = UDim2.new(0, textSize.X + 20, 0, 28)
        end
    end)
    
    return self
end

function Watermark:GetDisplayText()
    if self.Format then
        return self.Format:gsub("{fps}", tostring(self.FPS))
                          :gsub("{ping}", tostring(self.Ping))
                          :gsub("{time}", os.date("%H:%M:%S"))
                          :gsub("{text}", self.Text)
    end
    
    local parts = {self.Text}
    
    if self.ShowFPS then
        table.insert(parts, string.format("%d FPS", self.FPS))
    end
    
    if self.ShowPing then
        table.insert(parts, string.format("%d ms", self.Ping))
    end
    
    if self.ShowTime then
        table.insert(parts, os.date("%H:%M:%S"))
    end
    
    return table.concat(parts, " | ")
end

function Watermark:SetVisible(visible)
    self.Visible = visible
    self.Container.Visible = visible
end

function Watermark:SetText(text)
    self.Text = text
    self.Label.Text = self:GetDisplayText()
end

function Watermark:SetPosition(position)
    self.Position = position
    self.Container.Position = position
end

function Watermark:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    
    if self.Container then
        self.Container:Destroy()
    end
end

return Watermark

end

getgenv().Toggles = getgenv().Toggles or {}
getgenv().Options = getgenv().Options or {}

return SecretLib
