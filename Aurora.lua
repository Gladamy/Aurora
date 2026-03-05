--// Aurora UI Library
--// A minimalistic, beautiful UI library for Roblox
--// Version: 1.0.0

local Aurora = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// Configuration
Aurora.Config = {
    Theme = {
        Primary = Color3.fromRGB(88, 101, 242),      -- Soft indigo
        Secondary = Color3.fromRGB(30, 30, 35),       -- Dark charcoal
        Background = Color3.fromRGB(18, 18, 22),      -- Near black
        Surface = Color3.fromRGB(25, 25, 30),         -- Elevated surface
        Text = Color3.fromRGB(245, 245, 250),         -- Off-white
        TextMuted = Color3.fromRGB(150, 150, 160),    -- Muted text
        Success = Color3.fromRGB(46, 204, 113),       -- Soft green
        Warning = Color3.fromRGB(241, 196, 15),       -- Soft yellow
        Error = Color3.fromRGB(231, 76, 60),          -- Soft red
        Border = Color3.fromRGB(40, 40, 50),          -- Subtle border
        Glow = Color3.fromRGB(88, 101, 242),          -- Primary glow
    },
    Animation = {
        Duration = 0.3,
        Easing = Enum.EasingStyle.Quart,
        Direction = Enum.EasingDirection.Out,
    },
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    CornerRadius = UDim.new(0, 6),
    ShadowTransparency = 0.7,
}

--// Utility Functions
local function Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        instance[prop] = value
    end
    return instance
end

local function Tween(instance, properties, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(
        duration or Aurora.Config.Animation.Duration,
        easingStyle or Aurora.Config.Animation.Easing,
        easingDirection or Aurora.Config.Animation.Direction
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
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
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--// Shadow Effect
local function AddShadow(parent, intensity)
    intensity = intensity or 1
    local shadow = Create("ImageLabel", {
        Name = "Shadow",
        Parent = parent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 24, 1, 24),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = Aurora.Config.ShadowTransparency * intensity,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = parent.ZIndex - 1,
    })
    return shadow
end

--// Main Window Creation
function Aurora:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Aurora"
    local size = config.Size or UDim2.new(0, 600, 0, 400)
    local position = config.Position or UDim2.new(0.5, -300, 0.5, -200)
    
    --// ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = "AuroraUI",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    --// Main Frame
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        Position = position,
        Size = size,
        BackgroundColor3 = Aurora.Config.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    
    Create("UICorner", {
        CornerRadius = Aurora.Config.CornerRadius,
        Parent = MainFrame,
    })
    
    AddShadow(MainFrame, 1.2)
    
    --// Title Bar
    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = TitleBar,
    })
    
    -- Fix bottom corners
    local TitleBarFix = Create("Frame", {
        Name = "Fix",
        Parent = TitleBar,
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    --// Title Label
    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = TitleBar,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Aurora.Config.Theme.Text,
        Font = Aurora.Config.FontBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    --// Close Button
    local CloseButton = Create("TextButton", {
        Name = "Close",
        Parent = TitleBar,
        Position = UDim2.new(1, -35, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Aurora.Config.Theme.Error,
        Text = "",
        AutoButtonColor = false,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = CloseButton,
    })
    
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.2)
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Aurora.Config.Theme.Error}, 0.2)
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + size.X.Offset/2, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + size.Y.Offset/2)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    --// Minimize Button
    local MinimizeButton = Create("TextButton", {
        Name = "Minimize",
        Parent = TitleBar,
        Position = UDim2.new(1, -60, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Aurora.Config.Theme.Warning,
        Text = "",
        AutoButtonColor = false,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = MinimizeButton,
    })
    
    local minimized = false
    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, {Size = UDim2.new(0, size.X.Offset, 0, 40)}, 0.3)
        else
            Tween(MainFrame, {Size = size}, 0.3)
        end
    end)
    
    --// Tab Container
    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Parent = MainFrame,
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(0, 120, 1, -60),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    Create("UICorner", {
        CornerRadius = Aurora.Config.CornerRadius,
        Parent = TabContainer,
    })
    
    local TabList = Create("UIListLayout", {
        Parent = TabContainer,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    
    Create("UIPadding", {
        Parent = TabContainer,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    })
    
    --// Content Container
    local ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        Parent = MainFrame,
        Position = UDim2.new(0, 140, 0, 50),
        Size = UDim2.new(1, -150, 1, -60),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    
    Create("UICorner", {
        CornerRadius = Aurora.Config.CornerRadius,
        Parent = ContentContainer,
    })
    
    --// Window Object
    local Window = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        TabContainer = TabContainer,
        ContentContainer = ContentContainer,
        Tabs = {},
        ActiveTab = nil,
    }
    
    --// Tab Creation
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or ""
        
        --// Tab Button
        local TabButton = Create("TextButton", {
            Name = tabName .. "Tab",
            Parent = TabContainer,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Aurora.Config.Theme.Background,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #Window.Tabs + 1,
        })
        
        Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = TabButton,
        })
        
        local TabLabel = Create("TextLabel", {
            Name = "Label",
            Parent = TabButton,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = Aurora.Config.Theme.TextMuted,
            Font = Aurora.Config.FontMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        --// Tab Content
        local TabContent = Create("ScrollingFrame", {
            Name = tabName .. "Content",
            Parent = ContentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Aurora.Config.Theme.Primary,
            Visible = false,
        })
        
        Create("UIListLayout", {
            Parent = TabContent,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        
        Create("UIPadding", {
            Parent = TabContent,
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        })
        
        --// Tab Object
        local Tab = {
            Button = TabButton,
            Content = TabContent,
            Elements = {},
        }
        
        --// Tab Selection Logic
        TabButton.MouseButton1Click:Connect(function()
            if Window.ActiveTab == Tab then return end
            
            -- Deactivate current
            if Window.ActiveTab then
                Tween(Window.ActiveTab.Button, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
                Tween(Window.ActiveTab.Button.Label, {TextColor3 = Aurora.Config.Theme.TextMuted}, 0.2)
                Window.ActiveTab.Content.Visible = false
            end
            
            -- Activate new
            Window.ActiveTab = Tab
            Tween(TabButton, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.2)
            Tween(TabLabel, {TextColor3 = Aurora.Config.Theme.Text}, 0.2)
            TabContent.Visible = true
            
            -- Animation
            TabContent.CanvasPosition = Vector2.new(0, 0)
            TabContent.Size = UDim2.new(1, 0, 0.95, 0)
            Tween(TabContent, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
        end)
        
        --// Element Creation Functions
        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local btnText = btnConfig.Text or "Button"
            local callback = btnConfig.Callback or function() end
            
            local ButtonFrame = Create("Frame", {
                Name = "Button",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = ButtonFrame,
            })
            
            local Button = Create("TextButton", {
                Name = "Click",
                Parent = ButtonFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = btnText,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = 14,
                AutoButtonColor = false,
            })
            
            --// Hover Effects
            Button.MouseEnter:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.2)
            end)
            
            Button.MouseLeave:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
            end)
            
            Button.MouseButton1Down:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.1)
            end)
            
            Button.MouseButton1Up:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.1)
            end)
            
            Button.MouseButton1Click:Connect(function()
                callback()
            end)
            
            table.insert(Tab.Elements, ButtonFrame)
            return Button
        end
        
        function Tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local toggleText = toggleConfig.Text or "Toggle"
            local default = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end
            
            local ToggleFrame = Create("Frame", {
                Name = "Toggle",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = ToggleFrame,
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = ToggleFrame,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text = toggleText,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ToggleButton = Create("Frame", {
                Name = "ToggleButton",
                Parent = ToggleFrame,
                Position = UDim2.new(1, -44, 0.5, -10),
                Size = UDim2.new(0, 36, 0, 20),
                BackgroundColor3 = default and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = ToggleButton,
            })
            
            local Circle = Create("Frame", {
                Name = "Circle",
                Parent = ToggleButton,
                Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Circle,
            })
            
            local toggled = default
            
            local ClickArea = Create("TextButton", {
                Name = "Click",
                Parent = ToggleFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
            })
            
            ClickArea.MouseButton1Click:Connect(function()
                toggled = not toggled
                local targetColor = toggled and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border
                local targetPos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                
                Tween(ToggleButton, {BackgroundColor3 = targetColor}, 0.2)
                Tween(Circle, {Position = targetPos}, 0.2)
                callback(toggled)
            end)
            
            table.insert(Tab.Elements, ToggleFrame)
            return {Frame = ToggleFrame, GetValue = function() return toggled end, SetValue = function(val) toggled = val end}
        end
        
        function Tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local sliderText = sliderConfig.Text or "Slider"
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local default = sliderConfig.Default or min
            local increment = sliderConfig.Increment or 1
            local callback = sliderConfig.Callback or function() end
            
            local SliderFrame = Create("Frame", {
                Name = "Slider",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = SliderFrame,
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = SliderFrame,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -60, 0, 16),
                BackgroundTransparency = 1,
                Text = sliderText,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ValueLabel = Create("TextLabel", {
                Name = "Value",
                Parent = SliderFrame,
                Position = UDim2.new(1, -50, 0, 8),
                Size = UDim2.new(0, 40, 0, 16),
                BackgroundTransparency = 1,
                Text = tostring(default),
                TextColor3 = Aurora.Config.Theme.Primary,
                Font = Aurora.Config.FontBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            
            local SliderBar = Create("Frame", {
                Name = "Bar",
                Parent = SliderFrame,
                Position = UDim2.new(0, 12, 0, 32),
                Size = UDim2.new(1, -24, 0, 4),
                BackgroundColor3 = Aurora.Config.Theme.Border,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = SliderBar,
            })
            
            local Fill = Create("Frame", {
                Name = "Fill",
                Parent = SliderBar,
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Aurora.Config.Theme.Primary,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Fill,
            })
            
            local Knob = Create("Frame", {
                Name = "Knob",
                Parent = SliderBar,
                Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6),
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Knob,
            })
            
            local dragging = false
            
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pos)
                value = math.floor(value / increment + 0.5) * increment
                
                local fillScale = (value - min) / (max - min)
                Fill.Size = UDim2.new(fillScale, 0, 1, 0)
                Knob.Position = UDim2.new(fillScale, -6, 0.5, -6)
                ValueLabel.Text = tostring(value)
                callback(value)
            end
            
            Knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            
            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    UpdateSlider(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            table.insert(Tab.Elements, SliderFrame)
            return {Frame = SliderFrame, GetValue = function() return tonumber(ValueLabel.Text) end}
        end
        
        function Tab:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local dropdownText = dropdownConfig.Text or "Dropdown"
            local options = dropdownConfig.Options or {}
            default = dropdownConfig.Default or "Select..."
            local callback = dropdownConfig.Callback or function() end
            
            local DropdownFrame = Create("Frame", {
                Name = "Dropdown",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = DropdownFrame,
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = DropdownFrame,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -50, 0, 36),
                BackgroundTransparency = 1,
                Text = dropdownText,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local Arrow = Create("TextLabel", {
                Name = "Arrow",
                Parent = DropdownFrame,
                Position = UDim2.new(1, -30, 0, 0),
                Size = UDim2.new(0, 20, 0, 36),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = Aurora.Config.Theme.TextMuted,
                Font = Aurora.Config.FontBold,
                TextSize = 12,
            })
            
            local OptionsFrame = Create("Frame", {
                Name = "Options",
                Parent = DropdownFrame,
                Position = UDim2.new(0, 0, 0, 36),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = Aurora.Config.Theme.Surface,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            })
            
            local OptionsList = Create("UIListLayout", {
                Parent = OptionsFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            
            local expanded = false
            local selected = default
            
            for i, option in ipairs(options) do
                local OptionBtn = Create("TextButton", {
                    Name = option,
                    Parent = OptionsFrame,
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Aurora.Config.Theme.Surface,
                    Text = option,
                    TextColor3 = Aurora.Config.Theme.TextMuted,
                    Font = Aurora.Config.FontMedium,
                    TextSize = 13,
                    LayoutOrder = i,
                })
                
                OptionBtn.MouseEnter:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
                end)
                
                OptionBtn.MouseLeave:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Aurora.Config.Theme.Surface}, 0.2)
                end)
                
                OptionBtn.MouseButton1Click:Connect(function()
                    selected = option
                    Label.Text = dropdownText .. ": " .. option
                    callback(option)
                    expanded = false
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end)
            end
            
            local ClickArea = Create("TextButton", {
                Name = "Click",
                Parent = DropdownFrame,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "",
            })
            
            ClickArea.MouseButton1Click:Connect(function()
                expanded = not expanded
                local targetSize = expanded and UDim2.new(1, 0, 0, 36 + #options * 30) or UDim2.new(1, 0, 0, 36)
                Tween(DropdownFrame, {Size = targetSize}, 0.2)
                Tween(Arrow, {Rotation = expanded and 180 or 0}, 0.2)
            end)
            
            table.insert(Tab.Elements, DropdownFrame)
            return {Frame = DropdownFrame, GetValue = function() return selected end}
        end
        
        function Tab:CreateLabel(text)
            local LabelFrame = Create("Frame", {
                Name = "Label",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
            })
            
            local Label = Create("TextLabel", {
                Name = "Text",
                Parent = LabelFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = text or "Label",
                TextColor3 = Aurora.Config.Theme.TextMuted,
                Font = Aurora.Config.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            table.insert(Tab.Elements, LabelFrame)
            return Label
        end
        
        function Tab:CreateSection(sectionText)
            local SectionFrame = Create("Frame", {
                Name = "Section",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
            })
            
            local SectionLabel = Create("TextLabel", {
                Name = "Title",
                Parent = SectionFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = sectionText or "Section",
                TextColor3 = Aurora.Config.Theme.Primary,
                Font = Aurora.Config.FontBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local Line = Create("Frame", {
                Name = "Line",
                Parent = SectionFrame,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Aurora.Config.Theme.Border,
                BorderSizePixel = 0,
            })
            
            table.insert(Tab.Elements, SectionFrame)
            return SectionFrame
        end
        
        --// Initialize first tab
        if #Window.Tabs == 0 then
            TabButton.BackgroundColor3 = Aurora.Config.Theme.Primary
            TabLabel.TextColor3 = Aurora.Config.Theme.Text
            TabContent.Visible = true
            Window.ActiveTab = Tab
        end
        
        table.insert(Window.Tabs, Tab)
        return Tab
    end
    
    --// Make window draggable
    MakeDraggable(MainFrame, TitleBar)
    
    --// Intro Animation
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(position.X.Scale, position.X.Offset + size.X.Offset/2, position.Y.Scale, position.Y.Offset + size.Y.Offset/2)
    
    Tween(MainFrame, {
        Size = size,
        Position = position
    }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    return Window
end

--// Notification System
function Aurora:Notify(notifyConfig)
    notifyConfig = notifyConfig or {}
    local title = notifyConfig.Title or "Notification"
    local message = notifyConfig.Message or ""
    local notifyType = notifyConfig.Type or "Info" -- Info, Success, Warning, Error
    local duration = notifyConfig.Duration or 3
    
    local colors = {
        Info = Aurora.Config.Theme.Primary,
        Success = Aurora.Config.Theme.Success,
        Warning = Aurora.Config.Theme.Warning,
        Error = Aurora.Config.Theme.Error,
    }
    
    local color = colors[notifyType] or colors.Info
    
    --// Notification Container
    local NotifGui = Create("ScreenGui", {
        Name = "AuroraNotifications",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false,
    })
    
    local NotifFrame = Create("Frame", {
        Name = "Notification",
        Parent = NotifGui,
        Position = UDim2.new(1, -320, 1, -100),
        Size = UDim2.new(0, 280, 0, 80),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    Create("UICorner", {
        CornerRadius = Aurora.Config.CornerRadius,
        Parent = NotifFrame,
    })
    
    AddShadow(NotifFrame, 0.8)
    
    --// Accent Bar
    local AccentBar = Create("Frame", {
        Name = "Accent",
        Parent = NotifFrame,
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = AccentBar,
    })
    
    local Fix = Create("Frame", {
        Parent = AccentBar,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    })
    
    --// Content
    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = NotifFrame,
        Position = UDim2.new(0, 16, 0, 12),
        Size = UDim2.new(1, -32, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Aurora.Config.Theme.Text,
        Font = Aurora.Config.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local MessageLabel = Create("TextLabel", {
        Name = "Message",
        Parent = NotifFrame,
        Position = UDim2.new(0, 16, 0, 34),
        Size = UDim2.new(1, -32, 0, 40),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Aurora.Config.Theme.TextMuted,
        Font = Aurora.Config.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    })
    
    --// Progress Bar
    local ProgressBar = Create("Frame", {
        Name = "Progress",
        Parent = NotifFrame,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    })
    
    --// Animation
    NotifFrame.Position = UDim2.new(1, 0, 1, -100)
    Tween(NotifFrame, {Position = UDim2.new(1, -320, 1, -100)}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    Tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)
    
    task.delay(duration, function()
        Tween(NotifFrame, {Position = UDim2.new(1, 20, 1, -100)}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.4)
        NotifGui:Destroy()
    end)
end

--// Theme Customization
function Aurora:SetTheme(newTheme)
    for key, value in pairs(newTheme) do
        if Aurora.Config.Theme[key] then
            Aurora.Config.Theme[key] = value
        end
    end
end

return Aurora
