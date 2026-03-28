--[[
    lv.vila UI Library
    Clean, organized, and fully functional
    Uses only Roblox default assets - NO custom asset loading
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local cloneref = cloneref or function(obj) return obj end
local getgenv = getgenv or function() return _G end

local function getProtectedGui()
    local success, hui = pcall(function()
        return gethui and gethui()
    end)
    if success and hui then
        return hui
    end
    return game:GetService("CoreGui")
end

local Players = game:GetService("Players")
local CoreGui = cloneref(game:GetService("CoreGui"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local HttpService = cloneref(game:GetService("HttpService"))
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

-- Simple asset function using only Roblox default assets
local function getAsset(id)
    local assets = {
        square = "rbxasset://textures/ui/ScrollBarVerticalBackground.png",
        checkmark = "rbxasset://textures/ui/Box.png",
        triangle = "rbxasset://textures/ui/ScrollBarVerticalArrow.png",
        colorpicker = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        colorpicker_location = "rbxasset://textures/ui/Box.png",
        slider_location = "rbxasset://textures/ui/ScrollBarVerticalThumb.png",
        transparent_pattern = "rbxasset://textures/ui/TransparentBackground.png"
    }
    return assets[id] or "rbxasset://textures/ui/GuiImagePlaceholder.png"
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
    self.mouseInside = false
    self.position = position
    self.size = size
    self.title = title
    
    local guiParent = getProtectedGui()
    
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = generateGUID()
    self.gui.ResetOnSpawn = false
    self.gui.Parent = guiParent
    table.insert(self.objects, self.gui)
    
    -- Background
    local bg1 = Instance.new("Frame")
    bg1.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    bg1.BorderSizePixel = 0
    bg1.Size = size
    bg1.Position = position
    bg1.Parent = self.gui
    bg1.ZIndex = 0
    table.insert(self.objects, bg1)
    
    local bg2 = Instance.new("Frame")
    bg2.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    bg2.BorderSizePixel = 0
    bg2.Size = size - UDim2.new(0, 2, 0, 2)
    bg2.Position = position + UDim2.new(0, 1, 0, 1)
    bg2.Parent = self.gui
    bg2.ZIndex = 1
    table.insert(self.objects, bg2)
    
    local bg3 = Instance.new("Frame")
    bg3.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
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
    self.contentContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    self.contentContainer.BorderSizePixel = 0
    self.contentContainer.Size = UDim2.new(1, -2, 1, -44)
    self.contentContainer.Position = UDim2.new(0, 1, 0, 43)
    self.contentContainer.Parent = bg3
    self.contentContainer.ClipsDescendants = true
    self.contentContainer.ZIndex = 3
    table.insert(self.objects, self.contentContainer)
    
    -- Title bar
    local titleBarBg = Instance.new("Frame")
    titleBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBarBg.BorderSizePixel = 0
    titleBarBg.Size = UDim2.new(1, -2, 0, 20)
    titleBarBg.Position = position + UDim2.new(0, 3, 0, 3)
    titleBarBg.Parent = bg3
    titleBarBg.ZIndex = 3
    table.insert(self.objects, titleBarBg)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 12
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.Size = UDim2.new(1, -2, 0, 20)
    titleLabel.Position = position + UDim2.new(0, 3, 0, 3)
    titleLabel.Parent = bg3
    titleLabel.ZIndex = 4
    table.insert(self.objects, titleLabel)
    
    local titleLine = Instance.new("Frame")
    titleLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    titleLine.BorderSizePixel = 0
    titleLine.Size = UDim2.new(1, -2, 0, 1)
    titleLine.Position = position + UDim2.new(0, 3, 0, 22)
    titleLine.Parent = bg3
    titleLine.ZIndex = 5
    table.insert(self.objects, titleLine)
    
    -- Tab bar
    local tabBarBg = Instance.new("Frame")
    tabBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabBarBg.BorderSizePixel = 0
    tabBarBg.Size = UDim2.new(1, -2, 0, 20)
    tabBarBg.Position = position + UDim2.new(0, 3, 0, 24)
    tabBarBg.Parent = bg3
    tabBarBg.ZIndex = 6
    table.insert(self.objects, tabBarBg)
    
    local tabBarInner = Instance.new("Frame")
    tabBarInner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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
    self.dropContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    self.dropContainer.BackgroundTransparency = 0
    self.dropContainer.BorderSizePixel = 1
    self.dropContainer.BorderColor3 = Color3.fromRGB(30, 30, 30)
    self.dropContainer.Size = UDim2.new(0, 179, 0, 100)
    self.dropContainer.Position = UDim2.new(0, 0, 0, 0)
    self.dropContainer.Parent = self.gui
    self.dropContainer.ClipsDescendants = true
    self.dropContainer.Visible = false
    self.dropContainer.ZIndex = 9999
    self.dropContainer.CanvasSize = UDim2.new(0, 0, 0, 100)
    self.dropContainer.ScrollBarThickness = 3
    self.dropContainer.ScrollBarImageColor3 = Color3.fromRGB(129, 99, 251)
    self.dropContainer.ScrollBarImageTransparency = 0
    self.dropContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.dropContainer.TopImage = "rbxassetid://0"
    self.dropContainer.BottomImage = "rbxassetid://0"
    self.dropContainer.MidImage = getAsset("square")
    self.dropContainer.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
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
    self.keybindPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    self.keybindPopup.BorderSizePixel = 1
    self.keybindPopup.BorderColor3 = Color3.fromRGB(30, 30, 30)
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
    self.colorPicker.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    self.colorPicker.BorderSizePixel = 1
    self.colorPicker.BorderColor3 = Color3.fromRGB(30, 30, 30)
    self.colorPicker.Size = UDim2.new(0, 214, 0, 182)
    self.colorPicker.Position = UDim2.new(0, 10, 0, 10)
    self.colorPicker.Parent = self.gui
    self.colorPicker.Visible = false
    self.colorPicker.ZIndex = 9999
    table.insert(self.objects, self.colorPicker)
    
    -- Color wheel
    self.colorWheel = Instance.new("TextButton")
    self.colorWheel.BackgroundTransparency = 0
    self.colorWheel.BackgroundColor3 = Color3.fromRGB(129, 99, 251)
    self.colorWheel.BorderSizePixel = 0
    self.colorWheel.Size = UDim2.new(0, 180, 0, 180)
    self.colorWheel.Position = UDim2.new(0, 1, 0, 1)
    self.colorWheel.Parent = self.colorPicker
    self.colorWheel.Text = ""
    self.colorWheel.Visible = true
    self.colorWheel.AutoButtonColor = false
    self.colorWheel.ZIndex = 9999
    table.insert(self.objects, self.colorWheel)
    
    local colorWheelImage = Instance.new("ImageLabel")
    colorWheelImage.BackgroundTransparency = 1
    colorWheelImage.Image = getAsset("colorpicker")
    colorWheelImage.BorderSizePixel = 0
    colorWheelImage.Size = UDim2.new(1, 0, 1, 0)
    colorWheelImage.Position = UDim2.new(0, 0, 0, 0)
    colorWheelImage.Parent = self.colorWheel
    colorWheelImage.Visible = true
    colorWheelImage.ZIndex = 9999
    table.insert(self.objects, colorWheelImage)
    
    self.colorPickerLocation = Instance.new("Frame")
    self.colorPickerLocation.BackgroundTransparency = 1
    self.colorPickerLocation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.colorPickerLocation.BorderSizePixel = 0
    self.colorPickerLocation.Size = UDim2.new(0, 10, 0, 10)
    self.colorPickerLocation.Position = UDim2.new(1, -10, 0, 0)
    self.colorPickerLocation.Parent = self.colorWheel
    self.colorPickerLocation.Visible = true
    self.colorPickerLocation.ZIndex = 9999
    table.insert(self.objects, self.colorPickerLocation)
    
    -- Slider group
    local sliderGroup = Instance.new("Frame")
    sliderGroup.BackgroundTransparency = 0
    sliderGroup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    sliderGroup.BorderSizePixel = 0
    sliderGroup.Size = UDim2.new(0, 32, 0, 181)
    sliderGroup.Position = UDim2.new(0, 181, 0, 0)
    sliderGroup.Parent = self.colorPicker
    sliderGroup.Visible = true
    sliderGroup.ZIndex = 9999
    table.insert(self.objects, sliderGroup)
    
    -- Hue slider
    self.hueSlider = Instance.new("TextButton")
    self.hueSlider.BackgroundTransparency = 0
    self.hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.hueSlider.BorderSizePixel = 0
    self.hueSlider.Size = UDim2.new(0, 15, 0.994, 0)
    self.hueSlider.Position = UDim2.new(0, 1, 0, 1)
    self.hueSlider.Parent = sliderGroup
    self.hueSlider.Visible = true
    self.hueSlider.AutoButtonColor = false
    self.hueSlider.Text = ""
    self.hueSlider.ZIndex = 9999
    table.insert(self.objects, self.hueSlider)
    
    self.hueSliderLocation = Instance.new("ImageLabel")
    self.hueSliderLocation.BackgroundTransparency = 1
    self.hueSliderLocation.Image = getAsset("slider_location")
    self.hueSliderLocation.BorderSizePixel = 0
    self.hueSliderLocation.Size = UDim2.new(0, 15, 0, 5)
    self.hueSliderLocation.Position = UDim2.new(0, 0, 0, 0)
    self.hueSliderLocation.Parent = self.hueSlider
    self.hueSliderLocation.Visible = true
    self.hueSliderLocation.ZIndex = 9999
    table.insert(self.objects, self.hueSliderLocation)
    
    -- Opacity slider
    self.opacitySlider = Instance.new("TextButton")
    self.opacitySlider.BackgroundTransparency = 0
    self.opacitySlider.BackgroundColor3 = Color3.fromRGB(129, 99, 251)
    self.opacitySlider.BorderSizePixel = 0
    self.opacitySlider.Size = UDim2.new(0, 15, 0.994, 0)
    self.opacitySlider.Position = UDim2.new(0, 17, 0, 1)
    self.opacitySlider.Parent = sliderGroup
    self.opacitySlider.Visible = true
    self.opacitySlider.AutoButtonColor = false
    self.opacitySlider.Text = ""
    self.opacitySlider.ZIndex = 10000
    table.insert(self.objects, self.opacitySlider)
    
    self.opacitySliderLocation = Instance.new("ImageLabel")
    self.opacitySliderLocation.BackgroundTransparency = 1
    self.opacitySliderLocation.Image = getAsset("slider_location")
    self.opacitySliderLocation.BorderSizePixel = 0
    self.opacitySliderLocation.Size = UDim2.new(0, 15, 0, 5)
    self.opacitySliderLocation.Position = UDim2.new(0, 0, 0, 0)
    self.opacitySliderLocation.Parent = self.opacitySlider
    self.opacitySliderLocation.ImageColor3 = Color3.fromRGB(255, 255, 255)
    self.opacitySliderLocation.Visible = true
    self.opacitySliderLocation.ZIndex = 10000
    table.insert(self.objects, self.opacitySliderLocation)
    
    -- Keybind buttons
    self.toggleButton = Instance.new("TextButton")
    self.toggleButton.Text = "Toggle"
    self.toggleButton.TextColor3 = Color3.new(1, 1, 1)
    self.toggleButton.Font = Enum.Font.Gotham
    self.toggleButton.TextSize = 12
    self.toggleButton.BackgroundTransparency = 1
    self.toggleButton.Size = UDim2.new(1, 0, 0.5, 0)
    self.toggleButton.Position = UDim2.new(0, 0, 0, 0)
    self.toggleButton.Parent = self.keybindPopup
    self.toggleButton.ZIndex = 9999
    table.insert(self.objects, self.toggleButton)
    
    self.holdButton = Instance.new("TextButton")
    self.holdButton.Text = "Hold"
    self.holdButton.TextColor3 = Color3.new(1, 1, 1)
    self.holdButton.Font = Enum.Font.Gotham
    self.holdButton.TextSize = 12
    self.holdButton.BackgroundTransparency = 1
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
        if self.dragging then
            local delta = input.Position - self.dragStart
            local guiInset = CoreGui:GetGuiInset()
            local screenSize = workspace.CurrentCamera.ViewportSize - guiInset
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
    local function onColorWheelDown()
        self.colorWheelDown = true
    end
    
    local function onColorWheelUp()
        self.colorWheelDown = false
    end
    
    local function onColorWheelMove(x, y)
        y = y - CoreGui:GetGuiInset().Y
        if self.colorWheelDown and self.currentColor and self.colorWheel then
            local saturation = math.clamp((x - self.colorWheel.AbsolutePosition.X) / self.colorWheel.AbsoluteSize.X, 0, 1)
            local value = -(math.clamp((y - self.colorWheel.AbsolutePosition.Y) / self.colorWheel.AbsoluteSize.Y, 0, 1)) + 1
            local hue = self.currentColor.color:ToHSV()
            
            self.colorPickerLocation.Position = UDim2.new(0, math.clamp(saturation * self.colorWheel.AbsoluteSize.X, 0, 170), 0, math.clamp((-(value) + 1) * self.colorWheel.AbsoluteSize.Y, 0, 170))
            self.opacitySlider.BackgroundColor3 = Color3.fromHSV(hue, saturation, value)
            self.currentColor.color = Color3.fromHSV(hue, saturation, value)
            if self.currentColorBox then
                self.currentColorBox.BackgroundColor3 = self.currentColor.color
            end
        end
    end
    
    local function onColorWheelLeave()
        self.colorWheelDown = false
    end
    
    table.insert(self.connections, self.colorWheel.MouseButton1Down:Connect(onColorWheelDown))
    table.insert(self.connections, self.colorWheel.MouseButton1Up:Connect(onColorWheelUp))
    table.insert(self.connections, self.colorWheel.MouseMoved:Connect(onColorWheelMove))
    table.insert(self.connections, self.colorWheel.MouseLeave:Connect(onColorWheelLeave))
    
    local function onHueSliderDown()
        self.hueSliderDown = true
    end
    
    local function onHueSliderUp()
        self.hueSliderDown = false
    end
    
    local function onHueSliderMove(x, y)
        y = y - CoreGui:GetGuiInset().Y
        if self.hueSliderDown and self.currentColor and self.hueSlider then
            local hue = math.clamp((y - self.hueSlider.AbsolutePosition.Y) / self.hueSlider.AbsoluteSize.Y, 0, 1)
            self.hueSliderLocation.Position = UDim2.new(0, 0, 0, math.clamp(hue * self.hueSlider.AbsoluteSize.Y, 0, 175))
            
            local _, saturation, value = self.currentColor.color:ToHSV()
            self.opacitySlider.BackgroundColor3 = Color3.fromHSV(hue, saturation, value)
            self.colorWheel.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            self.currentColor.color = Color3.fromHSV(hue, saturation, value)
            if self.currentColorBox then
                self.currentColorBox.BackgroundColor3 = self.currentColor.color
            end
        end
    end
    
    local function onHueSliderLeave()
        self.hueSliderDown = false
    end
    
    table.insert(self.connections, self.hueSlider.MouseButton1Down:Connect(onHueSliderDown))
    table.insert(self.connections, self.hueSlider.MouseButton1Up:Connect(onHueSliderUp))
    table.insert(self.connections, self.hueSlider.MouseMoved:Connect(onHueSliderMove))
    table.insert(self.connections, self.hueSlider.MouseLeave:Connect(onHueSliderLeave))
    
    local function onOpacitySliderDown()
        self.opacitySliderDown = true
    end
    
    local function onOpacitySliderUp()
        self.opacitySliderDown = false
    end
    
    local function onOpacitySliderMove(x, y)
        y = y - CoreGui:GetGuiInset().Y
        if self.opacitySliderDown and self.currentColor and self.opacitySlider then
            local opacity = math.clamp((y - self.opacitySlider.AbsolutePosition.Y) / self.opacitySlider.AbsoluteSize.Y, 0, 1)
            self.opacitySliderLocation.Position = UDim2.new(0, 0, 0, math.clamp(opacity * self.opacitySlider.AbsoluteSize.Y, 0, 175))
            self.currentColor.transparency = opacity
        end
    end
    
    local function onOpacitySliderLeave()
        self.opacitySliderDown = false
    end
    
    table.insert(self.connections, self.opacitySlider.MouseButton1Down:Connect(onOpacitySliderDown))
    table.insert(self.connections, self.opacitySlider.MouseButton1Up:Connect(onOpacitySliderUp))
    table.insert(self.connections, self.opacitySlider.MouseMoved:Connect(onOpacitySliderMove))
    table.insert(self.connections, self.opacitySlider.MouseLeave:Connect(onOpacitySliderLeave))
    
    -- Keybind buttons
    local function onToggleClick()
        if self.currentKeybind then
            self.flags[self.currentKeybind].mode = "Toggle"
            self.keybindPopup.Visible = false
            self.currentKeybind = nil
        end
    end
    
    local function onHoldClick()
        if self.currentKeybind then
            self.flags[self.currentKeybind].mode = "Hold"
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
                    self.flags[self.currentKeybind].keycode = nil
                    self.flags[self.currentKeybind].state = false
                    self.currentKeybind = nil
                    self.keybindPopup.Visible = false
                else
                    self.flags[self.currentKeybind].keycode = input.KeyCode.Name
                    self.currentKeybind = nil
                    self.keybindPopup.Visible = false
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.flags[self.currentKeybind].keycode = "MouseButton1"
                self.currentKeybind = nil
                self.keybindPopup.Visible = false
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                self.flags[self.currentKeybind].keycode = "MouseButton2"
                self.currentKeybind = nil
                self.keybindPopup.Visible = false
            end
        end
    end
    
    local function onInputBeganKeybind(input)
        if self.currentKeybind then return end
        
        for flag, bind in pairs(self.flags) do
            if bind.keycode then
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
            if bind.keycode then
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
    
    -- Click outside dropdown
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
    
    -- Click outside color picker
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
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.Text = name
    button.Font = Enum.Font.GothamSemibold
    button.Size = UDim2.new(0, 100, 0, 18)
    button.Parent = self.tabBar[2]
    button.ZIndex = 8
    table.insert(self.objects, button)
    
    local index = #self.tabButtons + 1
    table.insert(self.tabButtons, button)
    
    local group = Instance.new("Frame")
    group.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    group.BorderSizePixel = 0
    group.Size = UDim2.new(1, 0, 1, 0)
    group.Position = UDim2.new(0, 0, 0, 0)
    group.Parent = self.contentContainer
    group.Visible = self.activeTab == index
    group.ZIndex = 9
    table.insert(self.objects, group)
    
    table.insert(self.tabGroups, group)
    
    local function onTabClick()
        self:setActiveTab(index)
    end
    
    table.insert(self.connections, button.MouseButton1Click:Connect(onTabClick))
    
    local Tab = {}
    Tab.__index = Tab
    
    function Tab:newGroup(groupName, right)
        groupName = groupName or ""
        right = right or false
        
        local groups = right and self.rightGroups or self.leftGroups
        local containers = right and self.rightContainers or self.leftContainers
        local index = #groups + 1
        
        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(30, 30, 30)
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.Position = UDim2.new(0, 0, 0, 0)
        frame.Parent = containers
        frame.AutomaticSize = Enum.AutomaticSize.XY
        frame.ClipsDescendants = true
        frame.ZIndex = 11
        table.insert(self.parent.objects, frame)
        
        table.insert(groups, frame)
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Size = UDim2.new(1, 0, 0, 18)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 12
        titleLabel.Text = groupName
        titleLabel.Font = Enum.Font.GothamSemibold
        titleLabel.Parent = frame
        titleLabel.ZIndex = 12
        table.insert(self.parent.objects, titleLabel)
        
        local container = Instance.new("Frame")
        container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        container.BorderSizePixel = 0
        container.Size = UDim2.new(1, 0, 0, 0)
        container.Position = UDim2.new(0, 0, 0, 18)
        container.Parent = frame
        container.AutomaticSize = Enum.AutomaticSize.XY
        container.ClipsDescendants = true
        container.ZIndex = 12
        table.insert(self.parent.objects, container)
        
        table.insert(containers, container)
        
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 4)
        layout.Parent = container
        table.insert(self.parent.objects, layout)
        
        local Group = {}
        Group.__index = Group
        
        function Group:newCheckbox(flag, options)
            options = options or {}
            
            local frame = Instance.new("Frame")
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BackgroundTransparency = 0
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 18)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.XY
            frame.ClipsDescendants = true
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 18)
            textLabel.Position = UDim2.new(0, 25, 0, 0)
            textLabel.TextColor3 = options.unsafe and Color3.fromRGB(182, 182, 101) or Color3.fromRGB(255, 255, 255)
            textLabel.TextSize = 12
            textLabel.Text = options.text
            textLabel.Font = Enum.Font.Gotham
            textLabel.Parent = frame
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
            button.BorderSizePixel = 1
            button.BorderColor3 = Color3.fromRGB(30, 30, 30)
            button.Size = UDim2.new(0, 14, 0, 14)
            button.Position = UDim2.new(0, 3, 0, 1)
            button.Text = ""
            button.Parent = frame
            button.AutoButtonColor = false
            button.ZIndex = 14
            table.insert(self.parent.objects, button)
            
            self.parent.flags[flag] = options.default or false
            
            local check = Instance.new("ImageLabel")
            check.BackgroundTransparency = 1
            check.Size = UDim2.new(0, 14, 0, 14)
            check.Position = UDim2.new(0, 0, 0, 0)
            check.Image = getAsset("checkmark")
            check.ImageColor3 = Color3.fromRGB(129, 99, 251)
            check.ScaleType = Enum.ScaleType.Fit
            check.Visible = self.parent.flags[flag]
            check.Parent = button
            check.ZIndex = 15
            table.insert(self.parent.objects, check)
            
            local function onClick()
                self.parent.flags[flag] = not self.parent.flags[flag]
                check.Visible = self.parent.flags[flag]
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
                end
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
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BackgroundTransparency = 0
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 34)
            frame.Position = UDim2.new(0, 3, 0, 0)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.XY
            frame.ClipsDescendants = true
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 0
            nameLabel.Size = UDim2.new(1, -65, 0, 20)
            nameLabel.Position = UDim2.new(0, 2, 0, 0)
            nameLabel.Text = tostring(options.text) .. ": "
            nameLabel.Parent = frame
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextColor3 = options.unsafe and Color3.fromRGB(182, 182, 101) or Color3.fromRGB(255, 255, 255)
            nameLabel.ZIndex = 14
            table.insert(self.parent.objects, nameLabel)
            
            local textSize = TextService:GetTextSize(nameLabel.ContentText, nameLabel.TextSize, nameLabel.Font, nameLabel.AbsoluteSize)
            
            self.parent.flags[flag] = options.default or 0
            
            local entry = Instance.new("TextBox")
            entry.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            entry.BackgroundTransparency = 0
            entry.BorderSizePixel = 0
            entry.Size = UDim2.new(1, -65 - textSize.X, 0, 20)
            entry.Position = UDim2.new(0, 0 + textSize.X, 0, 0)
            entry.Text = tostring(self.parent.flags[flag]) .. (options.suffix or "")
            entry.Parent = frame
            entry.Font = Enum.Font.Gotham
            entry.TextSize = 12
            entry.TextXAlignment = Enum.TextXAlignment.Left
            entry.TextColor3 = Color3.fromRGB(255, 255, 255)
            entry.ZIndex = 14
            table.insert(self.parent.objects, entry)
            
            local slider = Instance.new("Frame")
            slider.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            slider.BackgroundTransparency = 0
            slider.BorderSizePixel = 1
            slider.BorderColor3 = Color3.fromRGB(30, 30, 30)
            slider.Size = UDim2.new(1, -65, 0, 12)
            slider.Position = UDim2.new(0, 3, 0, 20)
            slider.Parent = frame
            slider.ZIndex = 14
            table.insert(self.parent.objects, slider)
            
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
            button.BackgroundTransparency = 0
            button.BorderSizePixel = 0
            button.Size = UDim2.new(1, 0, 1, 0)
            button.Position = UDim2.new(0, 0, 0, 0)
            button.Text = ""
            button.Parent = slider
            button.AutoButtonColor = false
            button.ZIndex = 15
            table.insert(self.parent.objects, button)
            
            local value = (self.parent.flags[flag] / (options.max - options.min)) - (options.min / (options.max - options.min))
            local sliderValue = Instance.new("Frame")
            sliderValue.BackgroundColor3 = Color3.fromRGB(129, 99, 251)
            sliderValue.BackgroundTransparency = 0
            sliderValue.BorderSizePixel = 0
            sliderValue.Size = UDim2.new(value, 0, 1, 0)
            sliderValue.Position = UDim2.new(0, 0, 0, 0)
            sliderValue.Parent = button
            sliderValue.ZIndex = 16
            table.insert(self.parent.objects, sliderValue)
            
            local isMouseDown = false
            local lastValue = self.parent.flags[flag]
            
            local function updateValue(x)
                local distance = button.AbsoluteSize.X
                local decimals = (options.decimals and options.decimals > 0) and (10 * options.decimals) or 1
                local mouseDistance = math.clamp((x - button.AbsolutePosition.X) / distance, 0, 1)
                local newValue = round(((options.max - options.min) * mouseDistance + options.min) * decimals) / decimals
                newValue = math.clamp(newValue, options.min, options.max)
                
                self.parent.flags[flag] = newValue
                entry.Text = tostring(self.parent.flags[flag]) .. (options.suffix or "")
                sliderValue.Size = UDim2.new((newValue / (options.max - options.min)) - (options.min / (options.max - options.min)), 0, 1, 0)
            end
            
            local function onMouseDown(x)
                isMouseDown = true
                updateValue(x)
            end
            
            local function onMouseMove(x)
                if isMouseDown then
                    updateValue(x)
                end
            end
            
            local function onMouseUp()
                isMouseDown = false
                if self.parent.flags[flag] ~= lastValue then
                    lastValue = self.parent.flags[flag]
                    if options.callback then
                        options.callback(self.parent.flags[flag])
                    end
                end
            end
            
            local function onMouseLeave()
                isMouseDown = false
                if self.parent.flags[flag] ~= lastValue then
                    lastValue = self.parent.flags[flag]
                    if options.callback then
                        options.callback(self.parent.flags[flag])
                    end
                end
            end
            
            local function onFocusLost(enterPressed)
                if enterPressed then
                    local val = tonumber(entry.Text)
                    if val then
                        val = math.clamp(val, options.min, options.max)
                        self.parent.flags[flag] = val
                        entry.Text = tostring(val) .. (options.suffix or "")
                        val = val / (options.max - options.min)
                        sliderValue.Size = UDim2.new(val, 0, 1, 0)
                        
                        if self.parent.flags[flag] ~= lastValue then
                            lastValue = self.parent.flags[flag]
                            if options.callback then
                                options.callback(self.parent.flags[flag])
                            end
                        end
                    else
                        entry.Text = tostring(self.parent.flags[flag]) .. (options.suffix or "")
                    end
                else
                    entry.Text = tostring(self.parent.flags[flag]) .. (options.suffix or "")
                end
            end
            
            table.insert(self.parent.connections, button.MouseButton1Down:Connect(onMouseDown))
            table.insert(self.parent.connections, button.MouseMoved:Connect(onMouseMove))
            table.insert(self.parent.connections, button.MouseButton1Up:Connect(onMouseUp))
            table.insert(self.parent.connections, button.MouseLeave:Connect(onMouseLeave))
            table.insert(self.parent.connections, entry.FocusLost:Connect(onFocusLost))
            
            local obj = {
                set_value = function(value)
                    value = math.clamp(value, options.min, options.max)
                    self.parent.flags[flag] = value
                    entry.Text = tostring(value) .. (options.suffix or "")
                    value = value / (options.max - options.min)
                    sliderValue.Size = UDim2.new(value, 0, 1, 0)
                    if options.callback then
                        options.callback(value)
                    end
                end
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
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BackgroundTransparency = 0
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 20)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.Parent = container
            frame.ClipsDescendants = true
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
            button.BackgroundTransparency = 0
            button.BorderSizePixel = 1
            button.BorderColor3 = Color3.fromRGB(30, 30, 30)
            button.Size = UDim2.new(1, -65, 1, -5)
            button.Position = UDim2.new(0, 3, 0, 2)
            button.Text = options.text
            button.Parent = frame
            button.AutoButtonColor = false
            button.Font = Enum.Font.Gotham
            button.TextSize = 12
            button.TextXAlignment = Enum.TextXAlignment.Center
            button.TextColor3 = options.unsafe and Color3.fromRGB(182, 182, 101) or Color3.fromRGB(255, 255, 255)
            button.ZIndex = 14
            table.insert(self.parent.objects, button)
            
            local function onClick()
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
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BackgroundTransparency = 0
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 39)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.Parent = container
            frame.AutomaticSize = Enum.AutomaticSize.XY
            frame.ClipsDescendants = true
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 16)
            textLabel.Position = UDim2.new(0, 2, 0, 0)
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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
            button.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
            button.BorderSizePixel = 1
            button.BorderColor3 = Color3.fromRGB(30, 30, 30)
            button.Size = UDim2.new(1, -65, 0, 20)
            button.Position = UDim2.new(0, 3, 0, 16)
            button.Text = getButtonText()
            button.Parent = frame
            button.AutoButtonColor = false
            button.Font = Enum.Font.Gotham
            button.TextSize = 12
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.ZIndex = 14
            table.insert(self.parent.objects, button)
            
            local arrow = Instance.new("ImageLabel")
            arrow.BackgroundTransparency = 1
            arrow.Size = UDim2.new(0, 10, 0, 10)
            arrow.Position = UDim2.new(1, -13, 0, 5)
            arrow.Image = getAsset("triangle")
            arrow.ImageColor3 = Color3.fromRGB(255, 255, 255)
            arrow.ScaleType = Enum.ScaleType.Fit
            arrow.Parent = button
            arrow.Rotation = -90
            arrow.ZIndex = 15
            table.insert(self.parent.objects, arrow)
            
            local function updateDropdown()
                if not self.parent.dropContainer then return end
                
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
                    drop.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    drop.BackgroundTransparency = 0
                    drop.BorderSizePixel = 1
                    drop.BorderColor3 = Color3.fromRGB(30, 30, 30)
                    drop.Size = UDim2.new(1, 1, 0, 20)
                    drop.Position = UDim2.new(0, 0, 0, 0)
                    drop.Text = tostring(val)
                    drop.Parent = self.parent.dropContainer
                    drop.AutoButtonColor = false
                    drop.Font = Enum.Font.Gotham
                    drop.TextSize = 12
                    drop.TextXAlignment = Enum.TextXAlignment.Left
                    drop.TextColor3 = isActive and Color3.fromRGB(129, 99, 251) or Color3.fromRGB(255, 255, 255)
                    drop.Visible = true
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
                                obj.TextColor3 = active and Color3.fromRGB(129, 99, 251) or Color3.fromRGB(255, 255, 255)
                                if not options.multi then
                                    obj.Visible = false
                                end
                            end
                        end
                        
                        button.Text = getButtonText()
                        if not options.multi and self.parent.dropContainer then
                            self.parent.dropContainer.Visible = false
                            arrow.Rotation = -90
                        end
                        
                        if options.callback then
                            options.callback(self.parent.flags[flag])
                        end
                    end
                    
                    table.insert(self.parent.connections, drop.MouseButton1Click:Connect(onDropClick))
                end
            end
            
            local function onButtonClick()
                if not self.parent.dropContainer then return end
                
                self.parent.dropContainer.Visible = not self.parent.dropContainer.Visible
                self.parent.dropContainer.Position = UDim2.new(0, button.AbsolutePosition.X, 0, button.AbsolutePosition.Y + button.AbsoluteSize.Y)
                arrow.Rotation = self.parent.dropContainer.Visible and -180 or -90
                
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
                end
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
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 30)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.Parent = container
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 10)
            textLabel.Position = UDim2.new(0, 2, 0, 1)
            textLabel.Text = options.text or flag
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextSize = 12
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            self.parent.flags[flag] = options.default or ""
            
            local entry = Instance.new("TextBox")
            entry.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
            entry.BackgroundTransparency = 0
            entry.BorderSizePixel = 1
            entry.BorderColor3 = Color3.fromRGB(30, 30, 30)
            entry.Size = UDim2.new(1, -65, 0, 14)
            entry.Position = UDim2.new(0, 3, 0, 13)
            entry.Text = self.parent.flags[flag]
            entry.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                end
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
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 10)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.Parent = container
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 10)
            textLabel.Position = UDim2.new(0, 2, 0, 1)
            textLabel.Text = options.text
            textLabel.TextColor3 = options.unsafe and Color3.fromRGB(182, 182, 101) or Color3.fromRGB(255, 255, 255)
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
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BackgroundTransparency = 0
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 20)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.Parent = container
            frame.ClipsDescendants = true
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 20)
            textLabel.Position = UDim2.new(0, 2, 0, 0)
            textLabel.Text = options.text or flag
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextSize = 12
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame
            textLabel.ZIndex = 14
            table.insert(self.parent.objects, textLabel)
            
            local obj = {
                set_value = function(value)
                    if value.keycode then
                        self.parent.flags[flag].keycode = value.keycode
                        self.parent.flags[flag].mode = value.mode
                    else
                        self.parent.flags[flag].keycode = nil
                        self.parent.flags[flag].mode = "Hold"
                    end
                end
            }
            
            self.parent.flags[flag] = {
                state = options.state or false,
                keycode = options.default and options.default.Name or nil,
                mode = options.mode or "Hold"
            }
            
            local keybind = Instance.new("TextButton")
            keybind.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            keybind.BackgroundTransparency = 1
            keybind.BorderSizePixel = 0
            keybind.Size = UDim2.new(0, 60, 1, 0)
            keybind.Position = UDim2.new(1, -62, 0, 0)
            keybind.TextColor3 = Color3.fromRGB(100, 100, 100)
            keybind.TextSize = 12
            keybind.Text = options.default == "MouseButton1" and "[MB1]" or options.default == "MouseButton2" and "[MB2]" or options.default and "[" .. tostring(options.default.Name) .. "]" or "[None]"
            keybind.Font = Enum.Font.GothamSemibold
            keybind.Parent = frame
            keybind.ZIndex = 13
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
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BackgroundTransparency = 0
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 20)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.Parent = container
            frame.ClipsDescendants = true
            frame.ZIndex = 13
            table.insert(self.parent.objects, frame)
            
            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, -65, 0, 20)
            textLabel.Position = UDim2.new(0, 2, 0, 0)
            textLabel.Text = options.text or flag
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                end
            }
            
            options.default = options.default or {}
            self.parent.flags[flag] = {
                color = options.default.color or Color3.fromRGB(255, 255, 255),
                transparency = options.default.transparency or 0
            }
            
            local colorContainer = Instance.new("TextButton")
            colorContainer.Size = UDim2.new(0, 35, 0, 10)
            colorContainer.Position = UDim2.new(1, -48, 0, 5)
            colorContainer.BackgroundTransparency = 0
            colorContainer.Text = ""
            colorContainer.BackgroundColor3 = self.parent.flags[flag].color
            colorContainer.BorderSizePixel = 1
            colorContainer.BorderColor3 = Color3.fromRGB(80, 80, 80)
            colorContainer.AutoButtonColor = false
            colorContainer.Parent = frame
            colorContainer.ZIndex = 14
            table.insert(self.parent.objects, colorContainer)
            
            local function onColorClick()
                self.parent.currentColor = self.parent.flags[flag]
                self.parent.currentColorBox = colorContainer
                
                local hue, saturation, value = self.parent.flags[flag].color:ToHSV()
                self.parent.colorPicker.Position = UDim2.new(0, colorContainer.AbsolutePosition.X + colorContainer.AbsoluteSize.X + 15, 0, colorContainer.AbsolutePosition.Y)
                self.parent.colorWheel.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                self.parent.opacitySlider.BackgroundColor3 = self.parent.flags[flag].color
                self.parent.colorPickerLocation.Position = UDim2.new(0, math.clamp(saturation * (self.parent.colorWheel.AbsoluteSize.X or 170), 0, 170), 0, math.clamp((-(value) + 1) * (self.parent.colorWheel.AbsoluteSize.Y or 170), 0, 170))
                self.parent.hueSliderLocation.Position = UDim2.new(0, 0, 0, math.clamp(hue * (self.parent.hueSlider.AbsoluteSize.Y or 175), 0, 175))
                self.parent.opacitySliderLocation.Position = UDim2.new(0, 0, 0, math.clamp(self.parent.flags[flag].transparency * (self.parent.opacitySlider.AbsoluteSize.Y or 175), 0, 175))
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
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = group
    table.insert(self.objects, layout)
    
    local leftScroll = Instance.new("ScrollingFrame")
    leftScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    leftScroll.BorderSizePixel = 0
    leftScroll.Size = UDim2.new(0.5, 0, 1, 0)
    leftScroll.Position = UDim2.new(0, 0, 0, 0)
    leftScroll.Parent = group
    leftScroll.ClipsDescendants = true
    leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftScroll.BottomImage = "rbxassetid://0"
    leftScroll.MidImage = getAsset("square")
    leftScroll.CanvasSize = UDim2.new(0, 0, 1, 0)
    leftScroll.ScrollBarThickness = 3
    leftScroll.ScrollBarImageTransparency = 0
    leftScroll.ScrollBarImageColor3 = Color3.fromRGB(129, 99, 251)
    leftScroll.TopImage = "rbxassetid://0"
    leftScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    leftScroll.ZIndex = 10
    table.insert(self.objects, leftScroll)
    
    local rightScroll = Instance.new("ScrollingFrame")
    rightScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    rightScroll.BorderSizePixel = 0
    rightScroll.Size = UDim2.new(0.5, 0, 1, 0)
    rightScroll.Position = UDim2.new(0.5, 0, 0, 0)
    rightScroll.Parent = group
    rightScroll.ClipsDescendants = true
    rightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    rightScroll.BottomImage = "rbxassetid://0"
    rightScroll.MidImage = getAsset("square")
    rightScroll.CanvasSize = UDim2.new(0, 0, 1, 0)
    rightScroll.ScrollBarThickness = 3
    rightScroll.ScrollBarImageTransparency = 0
    rightScroll.ScrollBarImageColor3 = Color3.fromRGB(129, 99, 251)
    rightScroll.TopImage = "rbxassetid://0"
    rightScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    rightScroll.ZIndex = 10
    table.insert(self.objects, rightScroll)
    
    local leftPadding = Instance.new("UIPadding")
    leftPadding.PaddingBottom = UDim.new(0, 1)
    leftPadding.PaddingLeft = UDim.new(0, 1)
    leftPadding.PaddingRight = UDim.new(0, 2)
    leftPadding.PaddingTop = UDim.new(0, 1)
    leftPadding.Parent = leftScroll
    table.insert(self.objects, leftPadding)
    
    local rightPadding = Instance.new("UIPadding")
    rightPadding.PaddingBottom = UDim.new(0, 1)
    rightPadding.PaddingLeft = UDim.new(0, 2)
    rightPadding.PaddingRight = UDim.new(0, 1)
    rightPadding.PaddingTop = UDim.new(0, 1)
    rightPadding.Parent = rightScroll
    table.insert(self.objects, rightPadding)
    
    local leftSpacer = Instance.new("Frame")
    leftSpacer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    leftSpacer.BorderSizePixel = 0
    leftSpacer.Size = UDim2.new(0, 0, 0, 0)
    leftSpacer.Position = UDim2.new(0, 0, 1, 0)
    leftSpacer.Parent = leftScroll
    leftSpacer.LayoutOrder = 9999
    table.insert(self.objects, leftSpacer)
    
    local rightSpacer = Instance.new("Frame")
    rightSpacer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    rightSpacer.BorderSizePixel = 0
    rightSpacer.Size = UDim2.new(0, 0, 0, 0)
    rightSpacer.Position = UDim2.new(0, 0, 1, 0)
    rightSpacer.Parent = rightScroll
    rightSpacer.LayoutOrder = 9999
    table.insert(self.objects, rightSpacer)
    
    local tabObj = {
        parent = self,
        leftScroll = leftScroll,
        rightScroll = rightScroll,
        leftGroups = {},
        rightGroups = {},
        leftContainers = {leftScroll},
        rightContainers = {rightScroll}
    }
    
    function tabObj:newGroup(groupName, right)
        return Tab.newGroup(self, groupName, right)
    end
    
    setmetatable(tabObj, Tab)
    
    self.tabs[name] = tabObj
    self:updateTabPositions()
    
    return tabObj
end

function Window:updateTabPositions()
    local distance = self.tabBar[2].AbsoluteSize.X / math.max(#self.tabButtons, 1)
    
    for i, button in ipairs(self.tabButtons) do
        button.Position = UDim2.new(0, distance * (i - 1), 0, 0)
        button.Size = UDim2.new(0, distance, 0, 18)
        button.TextColor3 = (i == self.activeTab) and Color3.fromRGB(129, 99, 251) or Color3.fromRGB(255, 255, 255)
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

function Library:apply_settings(tab)
    local menuGroup = tab:newGroup("Menu", false)
    local configGroup = tab:newGroup("Config", true)
    
    menuGroup:newLabel({ text = "Menu Key" })
    menuGroup:addKeybind("menu_key", {
        default = Enum.KeyCode.End,
        mode = "Toggle",
        state = true,
        ignore = true,
        callback = function(state)
            if getgenv().window and getgenv().window.gui then
                getgenv().window.gui.Enabled = state
            end
        end
    })
    
    menuGroup:newButton({
        text = "Copy JobId",
        callback = function()
            if setClipboard then
                setClipboard("Roblox.GameLauncher.joinGameInstance(" .. tostring(game.PlaceId) .. ", \"" .. tostring(game.JobId) .. "\")")
            end
        end
    })
    
    menuGroup:newButton({
        text = "Unload",
        callback = function()
            if getgenv().window then
                getgenv().window:destroy()
            end
            getgenv().library = nil
            getgenv().window = nil
        end
    })
    
    configGroup:newTextbox("config_name", { text = "Config Name", default = "", ignore = true })
    
    configGroup:newButton({
        text = "Save",
        callback = function()
            if not isFolder then return end
            local configName = "lv.vila/" .. tostring(getgenv().window.flags["config_name"]) .. ".json"
            if not isFolder("lv.vila") and makeFolder then
                makeFolder("lv.vila")
            end
            
            local fixedConfig = {}
            for key, value in pairs(getgenv().window.flags) do
                if not getgenv().window.ignore[key] then
                    if typeof(value) == "table" and value.color then
                        fixedConfig[key] = {
                            color = value.color:ToHex(),
                            transparency = value.transparency
                        }
                    else
                        fixedConfig[key] = value
                    end
                end
            end
            
            if writeFile then
                writeFile(configName, HttpService:JSONEncode(fixedConfig))
            end
        end
    })
    
    configGroup:newButton({
        text = "Load",
        callback = function()
            if not isFolder then return end
            local configName = "lv.vila/" .. tostring(getgenv().window.flags["config_name"]) .. ".json"
            if not isFolder("lv.vila") and makeFolder then
                makeFolder("lv.vila")
            end
            
            if isFile and isFile(configName) and readFile then
                local config = HttpService:JSONDecode(readFile(configName))
                for flag, value in pairs(config) do
                    if getgenv().window.options[flag] and not getgenv().window.ignore[flag] then
                        if typeof(value) == "table" and value.color then
                            getgenv().window.options[flag]:set_value({
                                color = Color3.fromHex(value.color),
                                transparency = value.transparency
                            })
                        else
                            getgenv().window.options[flag]:set_value(value)
                        end
                    end
                end
            end
        end
    })
end

setmetatable(Library, Library)
return Library
