--[[
    lv.vila UI Library - Fixed & Improved
    Clean, organized, and fully functional
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Enhanced cloneref with protection
local cloneref = cloneref or function(obj) 
    if type(obj) == "table" then
        return obj
    end
    return obj 
end

local getrenv = getrenv or function() return _G end
local getgenv = getgenv or function() return _G end

-- Get protected GUI container
local function getProtectedGui()
    local success, hui = pcall(function()
        return gethui and gethui()
    end)
    if success and hui then
        return hui
    end
    
    local coreGui = game:GetService("CoreGui")
    if coreGui then
        return coreGui
    end
    
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- Services
local Players = game:GetService("Players")
local CoreGui = cloneref(game:GetService("CoreGui"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TweenService = game:GetService("TweenService")
local LocalPlayer = cloneref(Players.LocalPlayer)

-- Executor detection
local function getExecutorName()
    local executors = {
        getexecutorname, identifyexecutor, whatexecutor, executorname
    }
    for _, func in ipairs(executors) do
        local success, result = pcall(function()
            return func and func()
        end)
        if success and result and result ~= "" then
            return result:lower()
        end
    end
    return "unwhitelisted"
end

local executor = getExecutorName()
local bannedExecutors = {
    "solara", "xeno", "jjsploit", "delta", "pluto", 
    "cheathub", "ronix", "script-ware", "oxygen u"
}

local function isBannedExecutor()
    if executor == "unwhitelisted" then
        return true
    end
    for _, banned in ipairs(bannedExecutors) do
        if executor:find(banned) then
            return true
        end
    end
    return false
end

if isBannedExecutor() then
    LocalPlayer:Kick("[lv.vila] Unwhitelisted executor detected")
    return
end

-- Simple utilities
local function tableFind(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

local function round(num)
    return math.floor(num + 0.5)
end

local function generateGUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return template:gsub("[xy]", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

-- Safe function wrapper for file operations
local function safeFunction(name, fallback)
    local func = _G[name] or (getgenv and getgenv()[name]) or fallback
    if not func then
        return function(...)
            return nil
        end
    end
    return func
end

local isFolder = safeFunction("isfolder")
local makeFolder = safeFunction("makefolder")
local isFile = safeFunction("isfile")
local writeFile = safeFunction("writefile")
local readFile = safeFunction("readfile")
local setClipboard = safeFunction("setclipboard")

-- Get screen size safely
local function getScreenSize()
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
    if viewport then
        return viewport
    end
    return Vector2.new(1920, 1080)
end

-- Animation helper
local function animate(object, properties, duration, style)
    style = style or Enum.EasingStyle.Quad
    local tween = TweenService:Create(object, TweenInfo.new(duration, style, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

-- UI Library
local Library = {}
Library.__index = Library

-- Window class
local Window = {}
Window.__index = Window

function Window.new(title, position, size)
    title = title or "lv.vila"
    position = position or UDim2.new(0.5, -250, 0.5, -300)
    size = size or UDim2.new(0, 500, 0, 600)
    
    local self = setmetatable({}, Window)
    
    self.objects = {}
    self.connections = {}
    self.flags = {}
    self.options = {}
    self.ignore = {}
    self.dragging = false
    self.dragStart = nil
    self.position = position
    self.size = size
    self.title = title
    self.hidden = false
    self.theme = {
        accent = Color3.fromRGB(129, 99, 251),
        background = Color3.fromRGB(12, 12, 12),
        secondary = Color3.fromRGB(20, 20, 20),
        border = Color3.fromRGB(30, 30, 30),
        text = Color3.fromRGB(255, 255, 255),
        unsafe = Color3.fromRGB(182, 182, 101)
    }
    
    local guiParent = getProtectedGui()
    
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = generateGUID()
    self.gui.ResetOnSpawn = false
    self.gui.IgnoreGuiInset = true
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local success, protected = pcall(function()
        return syn and syn.protect_gui or protect_gui
    end)
    if success and protected then
        pcall(protected, self.gui)
    end
    
    self.gui.Parent = guiParent
    table.insert(self.objects, self.gui)
    self.gui.Enabled = false
    
    -- Background
    local bg1 = Instance.new("Frame")
    bg1.BackgroundColor3 = self.theme.background
    bg1.BorderSizePixel = 0
    bg1.Size = size
    bg1.Position = position
    bg1.Parent = self.gui
    bg1.ZIndex = 0
    table.insert(self.objects, bg1)
    
    local bg2 = Instance.new("Frame")
    bg2.BackgroundColor3 = self.theme.secondary
    bg2.BorderSizePixel = 0
    bg2.Size = size - UDim2.new(0, 2, 0, 2)
    bg2.Position = position + UDim2.new(0, 1, 0, 1)
    bg2.Parent = self.gui
    bg2.ZIndex = 1
    table.insert(self.objects, bg2)
    
    local bg3 = Instance.new("Frame")
    bg3.BackgroundColor3 = self.theme.background
    bg3.BorderSizePixel = 0
    bg3.Size = size - UDim2.new(0, 4, 0, 4)
    bg3.Position = position + UDim2.new(0, 2, 0, 2)
    bg3.Parent = self.gui
    bg3.ClipsDescendants = true
    bg3.ZIndex = 2
    table.insert(self.objects, bg3)
    
    self.background = {bg1, bg2, bg3}
    
    -- Content container
    self.contentContainer = Instance.new("Frame")
    self.contentContainer.BackgroundColor3 = self.theme.background
    self.contentContainer.BorderSizePixel = 0
    self.contentContainer.Size = UDim2.new(1, -2, 1, -44)
    self.contentContainer.Position = UDim2.new(0, 1, 0, 43)
    self.contentContainer.Parent = bg3
    self.contentContainer.ClipsDescendants = true
    self.contentContainer.ZIndex = 3
    table.insert(self.objects, self.contentContainer)
    
    -- Title bar
    local titleBarBg = Instance.new("Frame")
    titleBarBg.BackgroundColor3 = self.theme.secondary
    titleBarBg.BorderSizePixel = 0
    titleBarBg.Size = UDim2.new(1, -2, 0, 20)
    titleBarBg.Position = position + UDim2.new(0, 3, 0, 3)
    titleBarBg.Parent = bg3
    titleBarBg.ZIndex = 3
    table.insert(self.objects, titleBarBg)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = self.theme.text
    titleLabel.TextSize = 12
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.Size = UDim2.new(1, -2, 0, 20)
    titleLabel.Position = position + UDim2.new(0, 3, 0, 3)
    titleLabel.Parent = bg3
    titleLabel.ZIndex = 4
    table.insert(self.objects, titleLabel)
    
    local titleLine = Instance.new("Frame")
    titleLine.BackgroundColor3 = self.theme.accent
    titleLine.BorderSizePixel = 0
    titleLine.Size = UDim2.new(1, -2, 0, 1)
    titleLine.Position = position + UDim2.new(0, 3, 0, 22)
    titleLine.Parent = bg3
    titleLine.ZIndex = 5
    table.insert(self.objects, titleLine)
    self.titleLine = titleLine
    
    -- Tab bar
    local tabBarBg = Instance.new("Frame")
    tabBarBg.BackgroundColor3 = self.theme.secondary
    tabBarBg.BorderSizePixel = 0
    tabBarBg.Size = UDim2.new(1, -2, 0, 20)
    tabBarBg.Position = position + UDim2.new(0, 3, 0, 24)
    tabBarBg.Parent = bg3
    tabBarBg.ZIndex = 6
    table.insert(self.objects, tabBarBg)
    
    local tabBarInner = Instance.new("Frame")
    tabBarInner.BackgroundColor3 = self.theme.background
    tabBarInner.BorderSizePixel = 0
    tabBarInner.Size = UDim2.new(1, -4, 0, 18)
    tabBarInner.Position = position + UDim2.new(0, 4, 0, 25)
    tabBarInner.Parent = bg3
    tabBarInner.ZIndex = 7
    tabBarInner.ClipsDescendants = true
    table.insert(self.objects, tabBarInner)
    
    self.tabBar = {tabBarBg, tabBarInner}
    
    -- Dropdown container
    self.dropContainer = Instance.new("ScrollingFrame")
    self.dropContainer.BackgroundColor3 = self.theme.secondary
    self.dropContainer.BackgroundTransparency = 0
    self.dropContainer.BorderSizePixel = 1
    self.dropContainer.BorderColor3 = self.theme.border
    self.dropContainer.Size = UDim2.new(0, 179, 0, 100)
    self.dropContainer.Position = UDim2.new(0, 0, 0, 0)
    self.dropContainer.Parent = self.gui
    self.dropContainer.ClipsDescendants = true
    self.dropContainer.Visible = false
    self.dropContainer.ZIndex = 9999
    self.dropContainer.CanvasSize = UDim2.new(0, 0, 0, 100)
    self.dropContainer.ScrollBarThickness = 3
    self.dropContainer.ScrollBarImageColor3 = self.theme.accent
    self.dropContainer.ScrollBarImageTransparency = 0
    self.dropContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.dropContainer.TopImage = "rbxassetid://0"
    self.dropContainer.BottomImage = "rbxassetid://0"
    self.dropContainer.MidImage = "rbxasset://textures/ui/ScrollBarVerticalBackground.png"
    table.insert(self.objects, self.dropContainer)
    
    local dropPadding = Instance.new("UIPadding")
    dropPadding.PaddingTop = UDim.new(0, 2)
    dropPadding.PaddingBottom = UDim.new(0, 2)
    dropPadding.PaddingLeft = UDim.new(0, 2)
    dropPadding.PaddingRight = UDim.new(0, 3)
    dropPadding.Parent = self.dropContainer
    table.insert(self.objects, dropPadding)
    
    local dropLayout = Instance.new("UIListLayout")
    dropLayout.Padding = UDim.new(0, 3)
    dropLayout.Parent = self.dropContainer
    dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
    table.insert(self.objects, dropLayout)
    
    -- Keybind popup
    self.keybindPopup = Instance.new("Frame")
    self.keybindPopup.BackgroundTransparency = 0
    self.keybindPopup.BackgroundColor3 = self.theme.secondary
    self.keybindPopup.BorderSizePixel = 1
    self.keybindPopup.BorderColor3 = self.theme.border
    self.keybindPopup.Size = UDim2.new(0, 50, 0, 40)
    self.keybindPopup.Position = UDim2.new(0, 0, 0, 0)
    self.keybindPopup.Parent = self.gui
    self.keybindPopup.Visible = false
    self.keybindPopup.ZIndex = 9999
    table.insert(self.objects, self.keybindPopup)
    
    local keybindLayout = Instance.new("UIListLayout")
    keybindLayout.FillDirection = Enum.FillDirection.Vertical
    keybindLayout.SortOrder = Enum.SortOrder.LayoutOrder
    keybindLayout.Padding = UDim.new(0, 0)
    keybindLayout.Parent = self.keybindPopup
    table.insert(self.objects, keybindLayout)
    
    -- Color picker
    self.colorPicker = Instance.new("Frame")
    self.colorPicker.BackgroundTransparency = 0
    self.colorPicker.BackgroundColor3 = self.theme.secondary
    self.colorPicker.BorderSizePixel = 1
    self.colorPicker.BorderColor3 = self.theme.border
    self.colorPicker.Size = UDim2.new(0, 200, 0, 180)
    self.colorPicker.Position = UDim2.new(0, 10, 0, 10)
    self.colorPicker.Parent = self.gui
    self.colorPicker.Visible = false
    self.colorPicker.ZIndex = 9999
    table.insert(self.objects, self.colorPicker)
    
    -- Simple color wheel using frames
    self.colorWheel = Instance.new("Frame")
    self.colorWheel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    self.colorWheel.BorderSizePixel = 1
    self.colorWheel.BorderColor3 = self.theme.border
    self.colorWheel.Size = UDim2.new(0, 150, 0, 150)
    self.colorWheel.Position = UDim2.new(0, 5, 0, 5)
    self.colorWheel.Parent = self.colorPicker
    self.colorWheel.ZIndex = 9999
    table.insert(self.objects, self.colorWheel)
    
    -- Saturation gradient
    local satGradient = Instance.new("UIGradient")
    satGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    satGradient.Rotation = 90
    satGradient.Parent = self.colorWheel
    
    local brightGradient = Instance.new("UIGradient")
    brightGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    brightGradient.Rotation = 0
    brightGradient.Parent = self.colorWheel
    
    self.colorPickerLocation = Instance.new("Frame")
    self.colorPickerLocation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.colorPickerLocation.BorderSizePixel = 1
    self.colorPickerLocation.BorderColor3 = Color3.fromRGB(0, 0, 0)
    self.colorPickerLocation.Size = UDim2.new(0, 8, 0, 8)
    self.colorPickerLocation.Position = UDim2.new(0, 0, 0, 0)
    self.colorPickerLocation.Parent = self.colorWheel
    self.colorPickerLocation.ZIndex = 10000
    table.insert(self.objects, self.colorPickerLocation)
    
    -- Hue slider
    self.hueSlider = Instance.new("Frame")
    self.hueSlider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    self.hueSlider.BorderSizePixel = 1
    self.hueSlider.BorderColor3 = self.theme.border
    self.hueSlider.Size = UDim2.new(0, 15, 0, 150)
    self.hueSlider.Position = UDim2.new(0, 160, 0, 5)
    self.hueSlider.Parent = self.colorPicker
    self.hueSlider.ZIndex = 9999
    table.insert(self.objects, self.hueSlider)
    
    local hueGradient = Instance.new("UIGradient")
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    })
    hueGradient.Rotation = 90
    hueGradient.Parent = self.hueSlider
    
    self.hueSliderLocation = Instance.new("Frame")
    self.hueSliderLocation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.hueSliderLocation.BorderSizePixel = 1
    self.hueSliderLocation.BorderColor3 = Color3.fromRGB(0, 0, 0)
    self.hueSliderLocation.Size = UDim2.new(1, 0, 0, 4)
    self.hueSliderLocation.Position = UDim2.new(0, 0, 0, 0)
    self.hueSliderLocation.Parent = self.hueSlider
    self.hueSliderLocation.ZIndex = 10000
    table.insert(self.objects, self.hueSliderLocation)
    
    -- Opacity slider
    self.opacitySlider = Instance.new("Frame")
    self.opacitySlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.opacitySlider.BorderSizePixel = 1
    self.opacitySlider.BorderColor3 = self.theme.border
    self.opacitySlider.Size = UDim2.new(0, 15, 0, 150)
    self.opacitySlider.Position = UDim2.new(0, 180, 0, 5)
    self.opacitySlider.Parent = self.colorPicker
    self.opacitySlider.ZIndex = 9999
    table.insert(self.objects, self.opacitySlider)
    
    local opacityGradient = Instance.new("UIGradient")
    opacityGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    opacityGradient.Rotation = 90
    opacityGradient.Parent = self.opacitySlider
    
    self.opacitySliderLocation = Instance.new("Frame")
    self.opacitySliderLocation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.opacitySliderLocation.BorderSizePixel = 1
    self.opacitySliderLocation.BorderColor3 = Color3.fromRGB(0, 0, 0)
    self.opacitySliderLocation.Size = UDim2.new(1, 0, 0, 4)
    self.opacitySliderLocation.Position = UDim2.new(0, 0, 0, 0)
    self.opacitySliderLocation.Parent = self.opacitySlider
    self.opacitySliderLocation.ZIndex = 10000
    table.insert(self.objects, self.opacitySliderLocation)
    
    self.toggleButton = Instance.new("TextButton")
    self.toggleButton.Text = "Toggle"
    self.toggleButton.TextColor3 = self.theme.text
    self.toggleButton.Font = Enum.Font.Gotham
    self.toggleButton.TextSize = 12
    self.toggleButton.BackgroundColor3 = self.theme.background
    self.toggleButton.BorderSizePixel = 1
    self.toggleButton.BorderColor3 = self.theme.border
    self.toggleButton.Size = UDim2.new(1, 0, 0.5, 0)
    self.toggleButton.Position = UDim2.new(0, 0, 0, 0)
    self.toggleButton.Parent = self.keybindPopup
    self.toggleButton.ZIndex = 9999
    table.insert(self.objects, self.toggleButton)
    
    self.holdButton = Instance.new("TextButton")
    self.holdButton.Text = "Hold"
    self.holdButton.TextColor3 = self.theme.text
    self.holdButton.Font = Enum.Font.Gotham
    self.holdButton.TextSize = 12
    self.holdButton.BackgroundColor3 = self.theme.background
    self.holdButton.BorderSizePixel = 1
    self.holdButton.BorderColor3 = self.theme.border
    self.holdButton.Size = UDim2.new(1, 0, 0.5, 0)
    self.holdButton.Position = UDim2.new(0, 0, 0, 0)
    self.holdButton.Parent = self.keybindPopup
    self.holdButton.ZIndex = 9999
    table.insert(self.objects, self.holdButton)
    
    self.tabs = {}
    self.tabButtons = {}
    self.tabGroups = {}
    self.activeTab = nil
    self.currentKeybind = nil
    self.currentColor = nil
    self.currentColorBox = nil
    self.dropFlag = nil
    self.colorWheelDown = false
    self.hueSliderDown = false
    self.opacitySliderDown = false
    
    -- Dragging
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and self.mouseInside then
            self.dragging = true
            self.dragStart = input.Position
        end
    end
    
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.dragging = false
        end
    end
    
    local function onMouseMove(input)
        if self.dragging and self.dragStart then
            local delta = input.Position - self.dragStart
            local screenSize = getScreenSize()
            local padding = 10
            
            local newX = math.clamp(self.position.X.Offset + delta.X, padding, screenSize.X - self.size.X.Offset - padding)
            local newY = math.clamp(self.position.Y.Offset + delta.Y, padding, screenSize.Y - self.size.Y.Offset - padding)
            
            self.position = UDim2.new(self.position.X.Scale, newX, self.position.Y.Scale, newY)
            self.dragStart = input.Position
            self:update()
        end
    end
    
    local function onMouseEnter()
        self.mouseInside = true
    end
    
    local function onMouseLeave()
        self.mouseInside = false
    end
    
    table.insert(self.connections, bg1.InputBegan:Connect(onInputBegan))
    table.insert(self.connections, bg1.InputEnded:Connect(onInputEnded))
    table.insert(self.connections, bg1.MouseEnter:Connect(onMouseEnter))
    table.insert(self.connections, bg1.MouseLeave:Connect(onMouseLeave))
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and self.dragging then
            onMouseMove(input)
        end
    end))
    
    -- Color picker events
    local function onColorWheelDown(input)
        self.colorWheelDown = true
        onColorWheelMove(input)
    end
    
    local function onColorWheelUp()
        self.colorWheelDown = false
    end
    
    local function onColorWheelMove(input)
        if self.colorWheelDown and self.currentColor then
            local x = input.Position.X
            local y = input.Position.Y
            local wheelPos = self.colorWheel.AbsolutePosition
            local wheelSize = self.colorWheel.AbsoluteSize
            
            local sat = math.clamp((x - wheelPos.X) / wheelSize.X, 0, 1)
            local val = math.clamp(1 - ((y - wheelPos.Y) / wheelSize.Y), 0, 1)
            local hue = self.currentColor.hue or 0
            
            self.currentColor.color = Color3.fromHSV(hue, sat, val)
            self.currentColor.hue = hue
            self.currentColor.sat = sat
            self.currentColor.val = val
            
            self.colorPickerLocation.Position = UDim2.new(0, sat * wheelSize.X - 4, 0, (1 - val) * wheelSize.Y - 4)
            
            if self.currentColorBox then
                self.currentColorBox.BackgroundColor3 = self.currentColor.color
            end
        end
    end
    
    table.insert(self.connections, self.colorWheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            onColorWheelDown(input)
        end
    end))
    table.insert(self.connections, self.colorWheel.InputEnded:Connect(onColorWheelUp))
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            onColorWheelMove(input)
        end
    end))
    
    local function onHueSliderDown(input)
        self.hueSliderDown = true
        onHueSliderMove(input)
    end
    
    local function onHueSliderUp()
        self.hueSliderDown = false
    end
    
    local function onHueSliderMove(input)
        if self.hueSliderDown and self.currentColor then
            local y = input.Position.Y
            local sliderPos = self.hueSlider.AbsolutePosition.Y
            local sliderSize = self.hueSlider.AbsoluteSize.Y
            
            local hue = math.clamp((y - sliderPos) / sliderSize, 0, 1)
            self.currentColor.hue = hue
            self.currentColor.color = Color3.fromHSV(hue, self.currentColor.sat or 0, self.currentColor.val or 1)
            
            self.hueSliderLocation.Position = UDim2.new(0, 0, 0, hue * sliderSize - 2)
            
            local sat = self.currentColor.sat or 0
            local val = self.currentColor.val or 1
            self.colorWheel.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            
            if self.currentColorBox then
                self.currentColorBox.BackgroundColor3 = self.currentColor.color
            end
        end
    end
    
    table.insert(self.connections, self.hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            onHueSliderDown(input)
        end
    end))
    table.insert(self.connections, self.hueSlider.InputEnded:Connect(onHueSliderUp))
    
    local function onOpacitySliderDown(input)
        self.opacitySliderDown = true
        onOpacitySliderMove(input)
    end
    
    local function onOpacitySliderUp()
        self.opacitySliderDown = false
    end
    
    local function onOpacitySliderMove(input)
        if self.opacitySliderDown and self.currentColor then
            local y = input.Position.Y
            local sliderPos = self.opacitySlider.AbsolutePosition.Y
            local sliderSize = self.opacitySlider.AbsoluteSize.Y
            
            local opacity = math.clamp(1 - ((y - sliderPos) / sliderSize), 0, 1)
            self.currentColor.transparency = opacity
            
            self.opacitySliderLocation.Position = UDim2.new(0, 0, 0, (1 - opacity) * sliderSize - 2)
        end
    end
    
    table.insert(self.connections, self.opacitySlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            onOpacitySliderDown(input)
        end
    end))
    table.insert(self.connections, self.opacitySlider.InputEnded:Connect(onOpacitySliderUp))
    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            onHueSliderMove(input)
            onOpacitySliderMove(input)
        end
    end))
    
    local function onToggleClick()
        if self.currentKeybind then
            if type(self.flags[self.currentKeybind]) == "table" then
                self.flags[self.currentKeybind].mode = "Toggle"
            end
            self.keybindPopup.Visible = false
            self.currentKeybind = nil
        end
    end
    
    local function onHoldClick()
        if self.currentKeybind then
            if type(self.flags[self.currentKeybind]) == "table" then
                self.flags[self.currentKeybind].mode = "Hold"
            end
            self.keybindPopup.Visible = false
            self.currentKeybind = nil
        end
    end
    
    table.insert(self.connections, self.toggleButton.MouseButton1Click:Connect(onToggleClick))
    table.insert(self.connections, self.holdButton.MouseButton1Click:Connect(onHoldClick))
    
    -- Input handling
    local function onInputBeganGlobal(input)
        if self.currentKeybind then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                    if type(self.flags[self.currentKeybind]) == "table" then
                        self.flags[self.currentKeybind].keycode = nil
                        self.flags[self.currentKeybind].state = false
                    end
                    self.currentKeybind = nil
                    self.keybindPopup.Visible = false
                else
                    if type(self.flags[self.currentKeybind]) == "table" then
                        self.flags[self.currentKeybind].keycode = input.KeyCode.Name
                    end
                    self.currentKeybind = nil
                    self.keybindPopup.Visible = false
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                if type(self.flags[self.currentKeybind]) == "table" then
                    self.flags[self.currentKeybind].keycode = "MouseButton1"
                end
                self.currentKeybind = nil
                self.keybindPopup.Visible = false
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                if type(self.flags[self.currentKeybind]) == "table" then
                    self.flags[self.currentKeybind].keycode = "MouseButton2"
                end
                self.currentKeybind = nil
                self.keybindPopup.Visible = false
            end
        end
    end
    
    local function onInputBeganKeybind(input)
        if self.currentKeybind then return end
        
        for flag, bind in pairs(self.flags) do
            if type(bind) == "table" and bind.keycode then
                local triggered = false
                
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == bind.keycode then
                    triggered = true
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 and bind.keycode == "MouseButton1" then
                    triggered = true
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 and bind.keycode == "MouseButton2" then
                    triggered = true
                end
                
                if triggered then
                    if bind.mode == "Hold" then
                        bind.state = true
                        if self.options[flag] and self.options[flag].callback then
                            self.options[flag].callback(bind.state)
                        end
                    elseif bind.mode == "Toggle" then
                        bind.state = not bind.state
                        if self.options[flag] and self.options[flag].callback then
                            self.options[flag].callback(bind.state)
                        end
                    end
                end
            end
        end
    end
    
    local function onInputEndedKeybind(input)
        for flag, bind in pairs(self.flags) do
            if type(bind) == "table" and bind.keycode then
                local triggered = false
                
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == bind.keycode then
                    triggered = true
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 and bind.keycode == "MouseButton1" then
                    triggered = true
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 and bind.keycode == "MouseButton2" then
                    triggered = true
                end
                
                if triggered and bind.mode == "Hold" then
                    bind.state = false
                    if self.options[flag] and self.options[flag].callback then
                        self.options[flag].callback(bind.state)
                    end
                end
            end
        end
    end
    
    table.insert(self.connections, UserInputService.InputBegan:Connect(onInputBeganGlobal))
    table.insert(self.connections, UserInputService.InputBegan:Connect(onInputBeganKeybind))
    table.insert(self.connections, UserInputService.InputEnded:Connect(onInputEndedKeybind))
    
    local function onInputBeganDropdown(input)
        if not self.dropContainer or not self.dropContainer.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        
        local pos = self.dropContainer.AbsolutePosition
        local size = self.dropContainer.AbsoluteSize
        
        if input.Position.X < pos.X or input.Position.X > pos.X + size.X or
           input.Position.Y < pos.Y or input.Position.Y > pos.Y + size.Y then
            self.dropContainer.Visible = false
            self.dropFlag = nil
        end
    end
    
    table.insert(self.connections, UserInputService.InputBegan:Connect(onInputBeganDropdown))
    
    local function onInputBeganColorPicker(input)
        if not self.colorPicker or not self.colorPicker.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        
        local pos = self.colorPicker.AbsolutePosition
        local size = self.colorPicker.AbsoluteSize
        
        if input.Position.X < pos.X or input.Position.X > pos.X + size.X or
           input.Position.Y < pos.Y or input.Position.Y > pos.Y + size.Y then
            self.colorPicker.Visible = false
        end
    end
    
    table.insert(self.connections, UserInputService.InputBegan:Connect(onInputBeganColorPicker))
    
    getgenv().flags = self.flags
    getgenv().options = self.options
    
    return self
end

function Window:update()
    if self.background[1] then
        self.background[1].Size = self.size
        self.background[1].Position = self.position
    end
    if self.background[2] then
        self.background[2].Size = self.size - UDim2.new(0, 2, 0, 2)
        self.background[2].Position = self.position + UDim2.new(0, 1, 0, 1)
    end
    if self.background[3] then
        self.background[3].Size = self.size - UDim2.new(0, 4, 0, 4)
        self.background[3].Position = self.position + UDim2.new(0, 2, 0, 2)
    end
end

function Window:addObject(className, properties)
    local obj = Instance.new(className)
    for prop, value in pairs(properties) do
        obj[prop] = value
    end
    table.insert(self.objects, obj)
    return obj
end

function Window:newTab(name)
    name = name or ""
    
    if not self.activeTab then
        self.activeTab = #self.tabButtons + 1
    end
    
    if self.tabs[name] then
        return self.tabs[name]
    end
    
    local button = Instance.new("TextButton")
    button.BackgroundTransparency = 1
    button.TextColor3 = self.theme.text
    button.TextSize = 12
    button.Text = name
    button.Font = Enum.Font.GothamSemibold
    button.Size = UDim2.new(0, 100, 0, 18)
    button.Parent = self.tabBar[2]
    button.ZIndex = 8
    table.insert(self.objects, button)
    
    local index = #self.tabButtons + 1
    table.insert(self.tabButtons, button)
    
    local group = Instance.new("ScrollingFrame")
    group.BackgroundColor3 = self.theme.background
    group.BorderSizePixel = 0
    group.Size = UDim2.new(1, 0, 1, 0)
    group.Position = UDim2.new(0, 0, 0, 0)
    group.Parent = self.contentContainer
    group.Visible = self.activeTab == index
    group.ZIndex = 9
    group.AutomaticCanvasSize = Enum.AutomaticSize.Y
    group.ScrollBarThickness = 6
    group.ScrollBarImageColor3 = self.theme.accent
    group.CanvasSize = UDim2.new(0, 0, 0, 0)
    table.insert(self.objects, group)
    
    table.insert(self.tabGroups, group)
    
    local function onTabClick()
        self:setActiveTab(index)
        animate(button, {TextColor3 = self.theme.accent}, 0.2)
    end
    
    table.insert(self.connections, button.MouseButton1Click:Connect(onTabClick))
    
    -- Create the tab object with all methods
    local tabObject = {}
    
    -- Store tab data
    tabObject.parent = self
    tabObject.scrollFrame = group
    tabObject.groups = {}
    
    -- Define the newGroup method
    function tabObject:newGroup(groupName, right)
        groupName = groupName or ""
        right = right or false
        
        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = self.parent.theme.secondary
        frame.BorderSizePixel = 1
        frame.BorderColor3 = self.parent.theme.border
        frame.Size = UDim2.new(right and 0.49 or 1, -4, 0, 0)
        frame.Position = UDim2.new(right and 0.51 or 0, 2, 0, 0)
        frame.Parent = self.scrollFrame
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.ClipsDescendants = true
        frame.ZIndex = 11
        table.insert(self.parent.objects, frame)
        
        table.insert(self.groups, frame)
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Size = UDim2.new(1, -4, 0, 18)
        titleLabel.Position = UDim2.new(0, 2, 0, 2)
        titleLabel.TextColor3 = self.parent.theme.text
        titleLabel.TextSize = 12
        titleLabel.Text = groupName
        titleLabel.Font = Enum.Font.GothamSemibold
        titleLabel.Parent = frame
        titleLabel.ZIndex = 12
        table.insert(self.parent.objects, titleLabel)
        
        local container = Instance.new("Frame")
        container.BackgroundColor3 = self.parent.theme.secondary
        container.BorderSizePixel = 0
        container.Size = UDim2.new(1, -4, 0, 0)
        container.Position = UDim2.new(0, 2, 0, 22)
        container.Parent = frame
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.ClipsDescendants = true
        container.ZIndex = 12
        table.insert(self.parent.objects, container)
        
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 4)
        layout.Parent = container
        table.insert(self.parent.objects, layout)
        
        -- Group object
        local Group = {}
        Group.__index = Group
        
        function Group:newCheckbox(flag, options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 18)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = self.parent.theme.background
            button.BorderSizePixel = 1
            button.BorderColor3 = self.parent.theme.border
            button.Size = UDim2.new(0, 14, 0, 14)
            button.Position = UDim2.new(0, 0, 0, 2)
            button.Text = ""
            button.Parent = frame
            button.AutoButtonColor = false
            button.ZIndex = 14
            table.insert(self.parent.objects, button)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -20, 0, 18)
            textLabel.Position = UDim2.new(0, 20, 0, 0)
            textLabel.TextColor3 = options.unsafe and self.parent.theme.unsafe or self.parent.theme.text
            textLabel.TextSize = 12
            textLabel.Text = options.text
            textLabel.Font = Enum.Font.Gotham
            textLabel.Parent = frame
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            self.parent.flags[flag] = options.default or false
            
            local check = Instance.new("Frame")
            check.BackgroundColor3 = self.parent.theme.accent
            check.Size = UDim2.new(0, 12, 0, 12)
            check.Position = UDim2.new(0, 1, 0, 1)
            check.Visible = self.parent.flags[flag]
            check.Parent = button
            check.ZIndex = 15
            table.insert(self.parent.objects, check)
            
            local function onClick()
                self.parent.flags[flag] = not self.parent.flags[flag]
                animate(check, {Visible = self.parent.flags[flag]}, 0.1)
                if options.callback then
                    options.callback(self.parent.flags[flag])
                end
            end
            
            table.insert(self.parent.connections, button.MouseButton1Click:Connect(onClick))
            
            local obj = {
                set_value = function(value)
                    self.parent.flags[flag] = value
                    check.Visible = value
                    if options.callback then
                        options.callback(value)
                    end
                end,
                callback = options.callback
            }
            
            self.parent.options[flag] = obj
            if options.ignore then
                self.parent.ignore[flag] = true
            end
            
            return obj
        end
        
        function Group:newSlider(flag, options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 34)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(1, -70, 0, 20)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.Text = options.text .. ": "
            nameLabel.Parent = frame
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextColor3 = options.unsafe and self.parent.theme.unsafe or self.parent.theme.text
            nameLabel.ZIndex = 14
            table.insert(self.parent.objects, nameLabel)
            
            self.parent.flags[flag] = options.default or 0
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.BackgroundTransparency = 1
            valueLabel.Size = UDim2.new(0, 50, 0, 20)
            valueLabel.Position = UDim2.new(1, -55, 0, 0)
            valueLabel.Text = tostring(self.parent.flags[flag]) .. (options.suffix or "")
            valueLabel.Parent = frame
            valueLabel.Font = Enum.Font.Gotham
            valueLabel.TextSize = 12
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.TextColor3 = self.parent.theme.text
            valueLabel.ZIndex = 14
            table.insert(self.parent.objects, valueLabel)
            
            local slider = Instance.new("Frame")
            slider.BackgroundColor3 = self.parent.theme.background
            slider.BorderSizePixel = 1
            slider.BorderColor3 = self.parent.theme.border
            slider.Size = UDim2.new(1, 0, 0, 12)
            slider.Position = UDim2.new(0, 0, 0, 20)
            slider.Parent = frame
            slider.ZIndex = 14
            table.insert(self.parent.objects, slider)
            
            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = self.parent.theme.accent
            fill.BorderSizePixel = 0
            fill.Size = UDim2.new((self.parent.flags[flag] - options.min) / (options.max - options.min), 0, 1, 0)
            fill.Parent = slider
            fill.ZIndex = 15
            table.insert(self.parent.objects, fill)
            
            local isDragging = false
            
            local function updateValue(x)
                local relativeX = math.clamp((x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                local newValue = options.min + (options.max - options.min) * relativeX
                if options.decimals then
                    newValue = math.floor(newValue * (10 ^ options.decimals) + 0.5) / (10 ^ options.decimals)
                else
                    newValue = math.floor(newValue + 0.5)
                end
                newValue = math.clamp(newValue, options.min, options.max)
                
                self.parent.flags[flag] = newValue
                valueLabel.Text = tostring(newValue) .. (options.suffix or "")
                fill.Size = UDim2.new((newValue - options.min) / (options.max - options.min), 0, 1, 0)
            end
            
            local function onInputBegan(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = true
                    updateValue(input.Position.X)
                end
            end
            
            local function onInputEnded()
                if isDragging then
                    isDragging = false
                    if options.callback then
                        options.callback(self.parent.flags[flag])
                    end
                end
            end
            
            local function onInputChanged(input)
                if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateValue(input.Position.X)
                end
            end
            
            table.insert(self.parent.connections, slider.InputBegan:Connect(onInputBegan))
            table.insert(self.parent.connections, slider.InputEnded:Connect(onInputEnded))
            table.insert(self.parent.connections, UserInputService.InputChanged:Connect(onInputChanged))
            
            local obj = {
                set_value = function(value)
                    value = math.clamp(value, options.min, options.max)
                    self.parent.flags[flag] = value
                    valueLabel.Text = tostring(value) .. (options.suffix or "")
                    fill.Size = UDim2.new((value - options.min) / (options.max - options.min), 0, 1, 0)
                    if options.callback then
                        options.callback(value)
                    end
                end,
                callback = options.callback
            }
            
            self.parent.options[flag] = obj
            if options.ignore then
                self.parent.ignore[flag] = true
            end
            
            return obj
        end
        
        function Group:newButton(options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 24)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = self.parent.theme.background
            button.BorderSizePixel = 1
            button.BorderColor3 = self.parent.theme.border
            button.Size = UDim2.new(1, 0, 0, 20)
            button.Position = UDim2.new(0, 0, 0, 2)
            button.Text = options.text
            button.Parent = frame
            button.AutoButtonColor = false
            button.Font = Enum.Font.Gotham
            button.TextSize = 12
            button.TextColor3 = options.unsafe and self.parent.theme.unsafe or self.parent.theme.text
            button.ZIndex = 14
            table.insert(self.parent.objects, button)
            
            local function onClick()
                animate(button, {BackgroundColor3 = self.parent.theme.accent}, 0.1)
                task.wait(0.1)
                animate(button, {BackgroundColor3 = self.parent.theme.background}, 0.1)
                if options.callback then
                    options.callback()
                end
            end
            
            table.insert(self.parent.connections, button.MouseButton1Click:Connect(onClick))
            
            return {}
        end
        
        function Group:newList(flag, options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 39)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 16)
            textLabel.Position = UDim2.new(0, 0, 0, 0)
            textLabel.TextColor3 = self.parent.theme.text
            textLabel.TextSize = 12
            textLabel.Text = options.text
            textLabel.Font = Enum.Font.Gotham
            textLabel.Parent = frame
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            self.parent.flags[flag] = options.default or (options.multi and {} or "")
            
            local function getButtonText()
                if options.multi then
                    local buffer = ""
                    for _, val in ipairs(self.parent.flags[flag]) do
                        buffer = buffer .. " " .. tostring(val) .. ","
                    end
                    return buffer ~= "" and buffer:sub(1, -2) or "None"
                else
                    return tostring(self.parent.flags[flag]) ~= "" and tostring(self.parent.flags[flag]) or "None"
                end
            end
            
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = self.parent.theme.background
            button.BorderSizePixel = 1
            button.BorderColor3 = self.parent.theme.border
            button.Size = UDim2.new(1, -65, 0, 20)
            button.Position = UDim2.new(0, 0, 0, 16)
            button.Text = getButtonText()
            button.Parent = frame
            button.AutoButtonColor = false
            button.Font = Enum.Font.Gotham
            button.TextSize = 12
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.TextColor3 = self.parent.theme.text
            button.ZIndex = 14
            table.insert(self.parent.objects, button)
            
            local arrow = Instance.new("TextLabel")
            arrow.BackgroundTransparency = 1
            arrow.Size = UDim2.new(0, 20, 0, 20)
            arrow.Position = UDim2.new(1, -25, 0, 0)
            arrow.Text = "▼"
            arrow.TextColor3 = self.parent.theme.text
            arrow.TextSize = 10
            arrow.Font = Enum.Font.Gotham
            arrow.Parent = button
            arrow.ZIndex = 15
            table.insert(self.parent.objects, arrow)
            
            local function updateDropdown()
                for _, child in pairs(self.parent.dropContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                
                for _, val in ipairs(options.values) do
                    local isActive = false
                    if options.multi then
                        isActive = tableFind(self.parent.flags[flag], val) ~= nil
                    else
                        isActive = self.parent.flags[flag] == val
                    end
                    
                    local drop = Instance.new("TextButton")
                    drop.BackgroundColor3 = self.parent.theme.background
                    drop.BorderSizePixel = 1
                    drop.BorderColor3 = self.parent.theme.border
                    drop.Size = UDim2.new(1, 1, 0, 20)
                    drop.Text = tostring(val)
                    drop.Parent = self.parent.dropContainer
                    drop.AutoButtonColor = false
                    drop.Font = Enum.Font.Gotham
                    drop.TextSize = 12
                    drop.TextXAlignment = Enum.TextXAlignment.Left
                    drop.TextColor3 = isActive and self.parent.theme.accent or self.parent.theme.text
                    drop.ZIndex = 10000
                    table.insert(self.parent.objects, drop)
                    
                    local function onDropClick()
                        if options.multi then
                            local idx = tableFind(self.parent.flags[flag], val)
                            if idx then
                                table.remove(self.parent.flags[flag], idx)
                            else
                                table.insert(self.parent.flags[flag], val)
                            end
                        else
                            self.parent.flags[flag] = val
                        end
                        
                        for _, obj in pairs(self.parent.dropContainer:GetChildren()) do
                            if obj:IsA("TextButton") then
                                local active = false
                                if options.multi then
                                    active = tableFind(self.parent.flags[flag], obj.Text) ~= nil
                                else
                                    active = self.parent.flags[flag] == obj.Text
                                end
                                obj.TextColor3 = active and self.parent.theme.accent or self.parent.theme.text
                                if not options.multi then
                                    obj.Visible = false
                                end
                            end
                        end
                        
                        button.Text = getButtonText()
                        if not options.multi then
                            self.parent.dropContainer.Visible = false
                            arrow.Text = "▼"
                        end
                        
                        if options.callback then
                            options.callback(self.parent.flags[flag])
                        end
                    end
                    
                    table.insert(self.parent.connections, drop.MouseButton1Click:Connect(onDropClick))
                end
            end
            
            local function onButtonClick()
                self.parent.dropContainer.Visible = not self.parent.dropContainer.Visible
                self.parent.dropContainer.Position = UDim2.new(0, button.AbsolutePosition.X, 0, button.AbsolutePosition.Y + button.AbsoluteSize.Y)
                arrow.Text = self.parent.dropContainer.Visible and "▲" or "▼"
                
                if self.parent.dropContainer.Visible then
                    self.parent.dropFlag = flag
                    updateDropdown()
                end
            end
            
            table.insert(self.parent.connections, button.MouseButton1Click:Connect(onButtonClick))
            
            local obj = {
                set_value = function(value)
                    self.parent.flags[flag] = value
                    if self.parent.dropFlag == flag then
                        updateDropdown()
                    end
                    button.Text = getButtonText()
                    if options.callback then
                        options.callback(value)
                    end
                end,
                set_values = function(values)
                    options.values = values
                    if self.parent.dropFlag == flag then
                        updateDropdown()
                    end
                end,
                callback = options.callback
            }
            
            self.parent.options[flag] = obj
            if options.ignore then
                self.parent.ignore[flag] = true
            end
            
            return obj
        end
        
        function Group:newTextbox(flag, options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 34)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 14)
            textLabel.Position = UDim2.new(0, 0, 0, 0)
            textLabel.Text = options.text or flag
            textLabel.TextColor3 = self.parent.theme.text
            textLabel.TextSize = 12
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            self.parent.flags[flag] = options.default or ""
            
            local entry = Instance.new("TextBox")
            entry.BackgroundColor3 = self.parent.theme.background
            entry.BorderSizePixel = 1
            entry.BorderColor3 = self.parent.theme.border
            entry.Size = UDim2.new(1, -65, 0, 20)
            entry.Position = UDim2.new(0, 0, 0, 14)
            entry.Text = self.parent.flags[flag]
            entry.TextColor3 = self.parent.theme.text
            entry.TextSize = 12
            entry.Font = Enum.Font.Gotham
            entry.TextXAlignment = Enum.TextXAlignment.Left
            entry.Parent = frame
            entry.ClipsDescendants = true
            entry.ClearTextOnFocus = false
            entry.ZIndex = 14
            table.insert(self.parent.objects, entry)
            
            local lastValue = self.parent.flags[flag]
            
            local function onFocusLost(enterPressed)
                if enterPressed then
                    self.parent.flags[flag] = entry.Text
                    if self.parent.flags[flag] ~= lastValue then
                        lastValue = self.parent.flags[flag]
                        if options.callback then
                            options.callback(self.parent.flags[flag])
                        end
                    end
                else
                    entry.Text = self.parent.flags[flag]
                end
            end
            
            table.insert(self.parent.connections, entry.FocusLost:Connect(onFocusLost))
            
            local obj = {
                set_value = function(value)
                    self.parent.flags[flag] = value
                    entry.Text = value
                    if options.callback then
                        options.callback(value)
                    end
                end,
                callback = options.callback
            }
            
            self.parent.options[flag] = obj
            if options.ignore then
                self.parent.ignore[flag] = true
            end
            
            return obj
        end
        
        function Group:newLabel(options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 14)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 14)
            textLabel.Position = UDim2.new(0, 0, 0, 0)
            textLabel.Text = options.text
            textLabel.TextColor3 = options.unsafe and self.parent.theme.unsafe or self.parent.theme.text
            textLabel.TextSize = 12
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            return {}
        end
        
        function Group:addKeybind(flag, options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 24)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -80, 0, 20)
            textLabel.Position = UDim2.new(0, 0, 0, 2)
            textLabel.Text = options.text or flag
            textLabel.TextColor3 = self.parent.theme.text
            textLabel.TextSize = 12
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            local obj = {
                set_value = function(value)
                    if value.keycode then
                        if type(self.parent.flags[flag]) == "table" then
                            self.parent.flags[flag].keycode = value.keycode
                            self.parent.flags[flag].mode = value.mode
                        else
                            self.parent.flags[flag] = {
                                state = false,
                                keycode = value.keycode,
                                mode = value.mode
                            }
                        end
                    else
                        if type(self.parent.flags[flag]) == "table" then
                            self.parent.flags[flag].keycode = nil
                            self.parent.flags[flag].mode = "Hold"
                        else
                            self.parent.flags[flag] = {
                                state = false,
                                keycode = nil,
                                mode = "Hold"
                            }
                        end
                    end
                end,
                callback = options.callback
            }
            
            self.parent.flags[flag] = {
                state = options.state or false,
                keycode = options.default and options.default.Name or nil,
                mode = options.mode or "Hold"
            }
            
            local keybind = Instance.new("TextButton")
            keybind.BackgroundColor3 = self.parent.theme.background
            keybind.BorderSizePixel = 1
            keybind.BorderColor3 = self.parent.theme.border
            keybind.Size = UDim2.new(0, 80, 0, 20)
            keybind.Position = UDim2.new(1, -85, 0, 2)
            keybind.TextColor3 = self.parent.theme.text
            keybind.TextSize = 11
            keybind.Text = options.default == "MouseButton1" and "[MB1]" or options.default == "MouseButton2" and "[MB2]" or options.default and "[" .. tostring(options.default.Name) .. "]" or "[None]"
            keybind.Font = Enum.Font.GothamSemibold
            keybind.Parent = frame
            keybind.ZIndex = 14
            table.insert(self.parent.objects, keybind)
            
            local function onKeybindClick()
                self.parent.currentKeybind = flag
                self.parent.keybindPopup.Visible = true
                self.parent.keybindPopup.Position = UDim2.new(0, keybind.AbsolutePosition.X + keybind.AbsoluteSize.X, 0, keybind.AbsolutePosition.Y)
            end
            
            local function onKeybindRightClick()
                self.parent.flags[flag] = {
                    state = false,
                    keycode = nil,
                    mode = "Hold"
                }
                keybind.Text = "[None]"
                if options.callback then
                    options.callback(self.parent.flags[flag])
                end
            end
            
            table.insert(self.parent.connections, keybind.MouseButton1Click:Connect(onKeybindClick))
            table.insert(self.parent.connections, keybind.MouseButton2Click:Connect(onKeybindRightClick))
            
            self.parent.options[flag] = obj
            if options.ignore then
                self.parent.ignore[flag] = true
            end
            
            return obj
        end
        
        function Group:addColorpicker(flag, options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 24)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -80, 0, 20)
            textLabel.Position = UDim2.new(0, 0, 0, 2)
            textLabel.Text = options.text or flag
            textLabel.TextColor3 = self.parent.theme.text
            textLabel.TextSize = 12
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            local obj = {
                set_value = function(value)
                    self.parent.flags[flag] = {
                        color = value.color or Color3.fromRGB(255, 255, 255),
                        transparency = value.transparency or 0
                    }
                    if colorContainer then
                        colorContainer.BackgroundColor3 = value.color or Color3.fromRGB(255, 255, 255)
                    end
                end,
                callback = options.callback
            }
            
            options.default = options.default or {}
            self.parent.flags[flag] = {
                color = options.default.color or Color3.fromRGB(255, 255, 255),
                transparency = options.default.transparency or 0,
                hue = 0,
                sat = 1,
                val = 1
            }
            
            local colorContainer = Instance.new("TextButton")
            colorContainer.Size = UDim2.new(0, 40, 0, 18)
            colorContainer.Position = UDim2.new(1, -45, 0, 3)
            colorContainer.BackgroundColor3 = self.parent.flags[flag].color
            colorContainer.BorderSizePixel = 1
            colorContainer.BorderColor3 = self.parent.theme.border
            colorContainer.AutoButtonColor = false
            colorContainer.Text = ""
            colorContainer.Parent = frame
            colorContainer.ZIndex = 14
            table.insert(self.parent.objects, colorContainer)
            
            local function onColorClick()
                self.parent.currentColor = self.parent.flags[flag]
                self.parent.currentColorBox = colorContainer
                
                local hue, sat, val = self.parent.flags[flag].color:ToHSV()
                self.parent.flags[flag].hue = hue
                self.parent.flags[flag].sat = sat
                self.parent.flags[flag].val = val
                
                self.parent.colorPicker.Position = UDim2.new(0, colorContainer.AbsolutePosition.X + colorContainer.AbsoluteSize.X + 5, 0, colorContainer.AbsolutePosition.Y - 50)
                self.parent.colorWheel.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                self.parent.colorPickerLocation.Position = UDim2.new(0, sat * 150 - 4, 0, (1 - val) * 150 - 4)
                self.parent.hueSliderLocation.Position = UDim2.new(0, 0, 0, hue * 150 - 2)
                self.parent.opacitySliderLocation.Position = UDim2.new(0, 0, 0, (1 - self.parent.flags[flag].transparency) * 150 - 2)
                self.parent.colorPicker.Visible = true
            end
            
            table.insert(self.parent.connections, colorContainer.MouseButton1Click:Connect(onColorClick))
            
            self.parent.options[flag] = obj
            if options.ignore then
                self.parent.ignore[flag] = true
            end
            
            return obj
        end
        
        setmetatable(Group, Group)
        
        local groupObj = setmetatable({}, Group)
        groupObj.parent = self.parent
        groupObj.container = container
        
        return groupObj
    end
    
    self.tabs[name] = tabObject
    self:updateTabPositions()
    
    return tabObject
end

function Window:updateTabPositions()
    local distance = self.tabBar[2].AbsoluteSize.X / math.max(#self.tabButtons, 1)
    
    for i, button in ipairs(self.tabButtons) do
        button.Position = UDim2.new(0, distance * (i - 1), 0, 0)
        button.Size = UDim2.new(0, distance, 0, 18)
        button.TextColor3 = (i == self.activeTab) and self.theme.accent or self.theme.text
    end
end

function Window:setActiveTab(index)
    self.activeTab = index
    self:updateTabPositions()
    
    for i, group in ipairs(self.tabGroups) do
        group.Visible = i == index
    end
end

function Window:destroy()
    for _, obj in ipairs(self.objects) do
        obj:Destroy()
    end
    for _, conn in ipairs(self.connections) do
        conn:Disconnect()
    end
end

function Library:new_window(title, position, size)
    return Window.new(title, position, size)
end

function Library:apply_settings(window)
    if not window or not window.newTab then
        warn("[lv.vila] Cannot apply settings: Invalid window")
        return
    end
    
    local settingsTab = window:newTab("Settings")
    
    if not settingsTab then
        warn("[lv.vila] Failed to create settings tab")
        return
    end
    
    local menuGroup = settingsTab:newGroup("Menu", false)
    local configGroup = settingsTab:newGroup("Config", true)
    local themeGroup = settingsTab:newGroup("Theme", true)
    
    if not menuGroup or not configGroup or not themeGroup then
        warn("[lv.vila] Failed to create settings groups")
        return
    end
    
    -- Menu keybind
    menuGroup:addKeybind("menu_key", {
        default = Enum.KeyCode.RightControl,
        mode = "Toggle",
        state = true,
        ignore = true,
        callback = function(state)
            if window and window.gui then
                window.gui.Enabled = state
                window.hidden = not state
            end
        end
    })
    
    -- Copy JobId button
    menuGroup:newButton({
        text = "Copy JobId",
        callback = function()
            if setClipboard then
                setClipboard("Roblox.GameLauncher.joinGameInstance(" .. tostring(game.PlaceId) .. ", \"" .. tostring(game.JobId) .. "\")")
                print("[lv.vila] JobId copied to clipboard!")
            end
        end
    })
    
    -- Unload button
    menuGroup:newButton({
        text = "Unload",
        callback = function()
            if window and window.destroy then
                window:destroy()
            end
            getgenv().library = nil
            getgenv().window = nil
            print("[lv.vila] UI Unloaded!")
        end
    })
    
    -- Config name
    configGroup:newTextbox("config_name", { 
        text = "Config Name", 
        default = "config", 
        ignore = true 
    })
    
    -- Save button with feedback
    configGroup:newButton({
        text = "Save Config",
        callback = function()
            local isFolderFn = safeFunction("isfolder")
            local makeFolderFn = safeFunction("makefolder")
            local writeFileFn = safeFunction("writefile")
            
            if not isFolderFn or not writeFileFn then 
                warn("[lv.vila] File operations not supported")
                print("[lv.vila] ❌ Failed to save config - file operations not supported")
                return 
            end
            
            local configName = "lv.vila/" .. tostring(window.flags["config_name"]) .. ".json"
            if not isFolderFn("lv.vila") and makeFolderFn then
                makeFolderFn("lv.vila")
            end
            
            local fixedConfig = {}
            for key, value in pairs(window.flags) do
                if not window.ignore[key] then
                    if type(value) == "table" and value.color then
                        fixedConfig[key] = {
                            color = value.color:ToHex(),
                            transparency = value.transparency
                        }
                    elseif type(value) == "table" and value.keycode then
                        fixedConfig[key] = {
                            keycode = value.keycode,
                            mode = value.mode
                        }
                    else
                        fixedConfig[key] = value
                    end
                end
            end
            
            writeFileFn(configName, HttpService:JSONEncode(fixedConfig))
            print("[lv.vila] ✓ Config saved as: " .. configName)
        end
    })
    
    -- Load button with feedback
    configGroup:newButton({
        text = "Load Config",
        callback = function()
            local isFolderFn = safeFunction("isfolder")
            local isFileFn = safeFunction("isfile")
            local readFileFn = safeFunction("readfile")
            
            if not isFolderFn or not isFileFn or not readFileFn then
                warn("[lv.vila] File operations not supported")
                print("[lv.vila] ❌ Failed to load config - file operations not supported")
                return
            end
            
            local configName = "lv.vila/" .. tostring(window.flags["config_name"]) .. ".json"
            if not isFolderFn("lv.vila") then
                local makeFolderFn = safeFunction("makefolder")
                if makeFolderFn then
                    makeFolderFn("lv.vila")
                end
            end
            
            if isFileFn(configName) then
                local config = HttpService:JSONDecode(readFileFn(configName))
                for flag, value in pairs(config) do
                    if window.options[flag] and not window.ignore[flag] then
                        if type(value) == "table" and value.color then
                            window.options[flag]:set_value({
                                color = Color3.fromHex(value.color),
                                transparency = value.transparency
                            })
                        elseif type(value) == "table" and value.keycode then
                            window.options[flag]:set_value({
                                keycode = value.keycode,
                                mode = value.mode
                            })
                        else
                            window.options[flag]:set_value(value)
                        end
                    end
                end
                print("[lv.vila] ✓ Config loaded from: " .. configName)
            else
                print("[lv.vila] ❌ Config not found: " .. configName)
            end
        end
    })
    
    -- Theme colors
    local accentPicker = themeGroup:addColorpicker("accent_color", {
        text = "Accent Color",
        default = {
            color = window.theme.accent,
            transparency = 0
        },
        ignore = true,
        callback = function(value)
            window.theme.accent = value.color
            for _, obj in pairs(window.objects) do
                if obj:IsA("Frame") and obj.BackgroundColor3 == window.theme.accent then
                    obj.BackgroundColor3 = value.color
                end
                if obj:IsA("TextButton") and obj.TextColor3 == window.theme.accent then
                    obj.TextColor3 = value.color
                end
                if obj:IsA("ImageLabel") and obj.ImageColor3 == window.theme.accent then
                    obj.ImageColor3 = value.color
                end
            end
            if window.titleLine then
                window.titleLine.BackgroundColor3 = value.color
            end
        end
    })
    
    local bgPicker = themeGroup:addColorpicker("bg_color", {
        text = "Background Color",
        default = {
            color = window.theme.background,
            transparency = 0
        },
        ignore = true,
        callback = function(value)
            window.theme.background = value.color
            for _, obj in pairs(window.objects) do
                if obj:IsA("Frame") and obj.BackgroundColor3 == window.theme.background then
                    obj.BackgroundColor3 = value.color
                end
            end
        end
    })
    
    -- Reset theme button
    themeGroup:newButton({
        text = "Reset Theme",
        callback = function()
            accentPicker:set_value({color = Color3.fromRGB(129, 99, 251), transparency = 0})
            bgPicker:set_value({color = Color3.fromRGB(12, 12, 12), transparency = 0})
            print("[lv.vila] ✓ Theme reset to default")
        end
    })
end

setmetatable(Library, Library)
return Library
