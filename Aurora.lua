--// Aurora UI Library v1.1
--// Bug fixes + Polish (Not Over-Engineered)

local Aurora = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Config — Fixed TextMuted contrast (150 → 180)
Aurora.Config = {
    Theme = {
        Primary = Color3.fromRGB(88, 101, 242),
        Secondary = Color3.fromRGB(30, 30, 35),
        Background = Color3.fromRGB(18, 18, 22),
        Surface = Color3.fromRGB(25, 25, 30),
        Text = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(180, 180, 190), -- FIXED: Better contrast
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        Border = Color3.fromRGB(40, 40, 50),
    },
    Animation = {
        Duration = 0.25,
        Easing = Enum.EasingStyle.Quart,
        Direction = Enum.EasingDirection.Out,
    },
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    CornerRadius = UDim.new(0, 6),
}

--// Utility
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

--// Notification Queue System — FIXED: Stacking
local NotificationQueue = {}
local ActiveNotifications = {}
local MaxVisibleNotifications = 4
local NotificationSpacing = 90

local function UpdateNotificationPositions()
    for i, notif in ipairs(ActiveNotifications) do
        local targetY = 1, -(i * NotificationSpacing) - 20
        Tween(notif.Frame, {
            Position = UDim2.new(1, -320, targetY)
        }, 0.3)
    end
end

local function ProcessNotificationQueue()
    while #NotificationQueue > 0 and #ActiveNotifications < MaxVisibleNotifications do
        local notifData = table.remove(NotificationQueue, 1)
        
        local NotifGui = Create("ScreenGui", {
            Name = "AuroraNotif_" .. tick(),
            Parent = LocalPlayer:WaitForChild("PlayerGui"),
            ResetOnSpawn = false,
            DisplayOrder = 100,
        })
        
        local NotifFrame = Create("Frame", {
            Name = "Notification",
            Parent = NotifGui,
            Position = UDim2.new(1, 0, 1, -100), -- Start off-screen
            Size = UDim2.new(0, 280, 0, 80),
            BackgroundColor3 = Aurora.Config.Theme.Surface,
            BorderSizePixel = 0,
        })
        
        Create("UICorner", {CornerRadius = Aurora.Config.CornerRadius, Parent = NotifFrame})
        
        -- Shadow
        local Shadow = Create("ImageLabel", {
            Parent = NotifFrame,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 4),
            Size = UDim2.new(1, 20, 1, 20),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6014261993",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.8,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ZIndex = -1,
        })
        
        local AccentBar = Create("Frame", {
            Parent = NotifFrame,
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = notifData.Color,
            BorderSizePixel = 0,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = AccentBar})
        
        Create("TextLabel", {
            Parent = NotifFrame,
            Position = UDim2.new(0, 16, 0, 12),
            Size = UDim2.new(1, -32, 0, 20),
            BackgroundTransparency = 1,
            Text = notifData.Title,
            TextColor3 = Aurora.Config.Theme.Text,
            Font = Aurora.Config.FontBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        Create("TextLabel", {
            Parent = NotifFrame,
            Position = UDim2.new(0, 16, 0, 34),
            Size = UDim2.new(1, -32, 0, 40),
            BackgroundTransparency = 1,
            Text = notifData.Message,
            TextColor3 = Aurora.Config.Theme.TextMuted,
            Font = Aurora.Config.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
        
        local ProgressBar = Create("Frame", {
            Parent = NotifFrame,
            Position = UDim2.new(0, 0, 1, -2),
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = notifData.Color,
            BorderSizePixel = 0,
        })
        
        table.insert(ActiveNotifications, {Frame = NotifFrame, Gui = NotifGui})
        UpdateNotificationPositions()
        
        -- Slide in
        task.wait(0.05)
        Tween(NotifFrame, {Position = UDim2.new(1, -320, NotifFrame.Position.Y.Scale, NotifFrame.Position.Y.Offset)}, 0.4)
        
        -- Progress animation
        Tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 2)}, notifData.Duration)
        
        -- Cleanup
        task.delay(notifData.Duration, function()
            Tween(NotifFrame, {Position = UDim2.new(1, 20, NotifFrame.Position.Y.Scale, NotifFrame.Position.Y.Offset)}, 0.3)
            task.wait(0.3)
            
            for i, n in ipairs(ActiveNotifications) do
                if n.Frame == NotifFrame then
                    table.remove(ActiveNotifications, i)
                    break
                end
            end
            
            NotifGui:Destroy()
            UpdateNotificationPositions()
            ProcessNotificationQueue()
        end)
    end
end

function Aurora:Notify(config)
    config = config or {}
    local colors = {
        Info = Aurora.Config.Theme.Primary,
        Success = Aurora.Config.Theme.Success,
        Warning = Aurora.Config.Theme.Warning,
        Error = Aurora.Config.Theme.Error,
    }
    
    table.insert(NotificationQueue, {
        Title = config.Title or "Notification",
        Message = config.Message or "",
        Color = colors[config.Type] or colors.Info,
        Duration = config.Duration or 3,
    })
    
    ProcessNotificationQueue()
end

--// Window Creation (Fixed Slider Default Value)
function Aurora:CreateWindow(config)
    config = config or {}
    
    local ScreenGui = Create("ScreenGui", {
        Name = "Aurora",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false,
    })
    
    local MainFrame = Create("Frame", {
        Name = "Main",
        Parent = ScreenGui,
        Position = config.Position or UDim2.new(0.5, -300, 0.5, -200),
        Size = UDim2.new(0, 0, 0, 0), -- Start small for animation
        BackgroundColor3 = Aurora.Config.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    
    Create("UICorner", {CornerRadius = Aurora.Config.CornerRadius, Parent = MainFrame})
    
    -- Shadow
    Create("ImageLabel", {
        Parent = MainFrame,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 24, 1, 24),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1,
    })
    
    -- Title Bar
    local TitleBar = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TitleBar})
    
    -- Fix bottom corners
    Create("Frame", {
        Parent = TitleBar,
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    Create("TextLabel", {
        Parent = TitleBar,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Title or "Aurora",
        TextColor3 = Aurora.Config.Theme.Text,
        Font = Aurora.Config.FontBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Close Button (with tooltip on hover - nice to have)
    local CloseBtn = Create("TextButton", {
        Parent = TitleBar,
        Position = UDim2.new(1, -35, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Aurora.Config.Theme.Error,
        Text = "×",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Aurora.Config.FontBold,
        TextSize = 14,
        AutoButtonColor = false,
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = CloseBtn})
    
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.2)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Aurora.Config.Theme.Error}, 0.2)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    -- Minimize
    local MinBtn = Create("TextButton", {
        Parent = TitleBar,
        Position = UDim2.new(1, -60, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Aurora.Config.Theme.Warning,
        Text = "−",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Aurora.Config.FontBold,
        TextSize = 14,
        AutoButtonColor = false,
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = MinBtn})
    
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(MainFrame, {Size = minimized and UDim2.new(0, 600, 0, 40) or UDim2.new(0, 600, 0, 400)}, 0.3)
    end)
    
    -- Containers
    local TabContainer = Create("Frame", {
        Parent = MainFrame,
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(0, 120, 1, -60),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    Create("UICorner", {CornerRadius = Aurora.Config.CornerRadius, Parent = TabContainer})
    
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
    
    local ContentContainer = Create("Frame", {
        Parent = MainFrame,
        Position = UDim2.new(0, 140, 0, 50),
        Size = UDim2.new(1, -150, 1, -60),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    Create("UICorner", {CornerRadius = Aurora.Config.CornerRadius, Parent = ContentContainer})
    
    local Window = {
        Tabs = {},
        ActiveTab = nil,
    }
    
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        
        local TabBtn = Create("TextButton", {
            Parent = TabContainer,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Aurora.Config.Theme.Background,
            Text = tabConfig.Name or "Tab",
            TextColor3 = Aurora.Config.Theme.TextMuted,
            Font = Aurora.Config.FontMedium,
            TextSize = 13,
            AutoButtonColor = false,
            LayoutOrder = #Window.Tabs + 1,
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = TabBtn})
        
        local Content = Create("ScrollingFrame", {
            Parent = ContentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Aurora.Config.Theme.Primary,
            Visible = false,
        })
        
        Create("UIListLayout", {
            Parent = Content,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        Create("UIPadding", {
            Parent = Content,
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        })
        
        local Tab = {
            Button = TabBtn,
            Content = Content,
        }
        
        TabBtn.MouseButton1Click:Connect(function()
            if Window.ActiveTab == Tab then return end
            
            if Window.ActiveTab then
                Tween(Window.ActiveTab.Button, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
                Tween(Window.ActiveTab.Button, {TextColor3 = Aurora.Config.Theme.TextMuted}, 0.2)
                Window.ActiveTab.Content.Visible = false
            end
            
            Window.ActiveTab = Tab
            Tween(TabBtn, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.2)
            Tween(TabBtn, {TextColor3 = Aurora.Config.Theme.Text}, 0.2)
            Content.Visible = true
            Content.Size = UDim2.new(1, 0, 0.9, 0)
            Tween(Content, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
        end)
        
        -- FIXED: Slider with correct default value rendering
        function Tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local default = math.clamp(sliderConfig.Default or min, min, max)
            local callback = sliderConfig.Callback or function() end
            
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Frame})
            
            Create("TextLabel", {
                Parent = Frame,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -60, 0, 16),
                BackgroundTransparency = 1,
                Text = sliderConfig.Text or "Slider",
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ValueLabel = Create("TextLabel", {
                Parent = Frame,
                Position = UDim2.new(1, -50, 0, 8),
                Size = UDim2.new(0, 40, 0, 16),
                BackgroundTransparency = 1,
                Text = tostring(default),
                TextColor3 = Aurora.Config.Theme.Primary,
                Font = Aurora.Config.FontBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            
            local Bar = Create("Frame", {
                Parent = Frame,
                Position = UDim2.new(0, 12, 0, 32),
                Size = UDim2.new(1, -24, 0, 4),
                BackgroundColor3 = Aurora.Config.Theme.Border,
                BorderSizePixel = 0,
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Bar})
            
            -- FIXED: Calculate initial fill based on default value
            local initialScale = (default - min) / (max - min)
            
            local Fill = Create("Frame", {
                Parent = Bar,
                Size = UDim2.new(initialScale, 0, 1, 0), -- FIXED: Use calculated scale
                BackgroundColor3 = Aurora.Config.Theme.Primary,
                BorderSizePixel = 0,
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Fill})
            
            local Knob = Create("Frame", {
                Parent = Bar,
                Position = UDim2.new(initialScale, -6, 0.5, -6), -- FIXED: Match fill position
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Knob})
            
            -- FIXED: Grab cursor
            Knob.Active = true
            
            local dragging = false
            local currentValue = default
            
            local function Update(input)
                local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                local value = min + (max - min) * pos
                value = math.floor(value + 0.5)
                value = math.clamp(value, min, max)
                
                if value ~= currentValue then
                    currentValue = value
                    local scale = (value - min) / (max - min)
                    Fill.Size = UDim2.new(scale, 0, 1, 0)
                    Knob.Position = UDim2.new(scale, -6, 0.5, -6)
                    ValueLabel.Text = tostring(value)
                    callback(value)
                end
            end
            
            Knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            
            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    Update(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    Update(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            return Frame
        end
        
        -- FIXED: Dropdown with opacity fade
        function Tab:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local options = dropdownConfig.Options or {}
            local selected = dropdownConfig.Default or "Select..."
            
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Frame})
            
            local Label = Create("TextLabel", {
                Parent = Frame,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
                BackgroundTransparency = 1,
                Text = selected,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local Arrow = Create("TextLabel", {
                Parent = Frame,
                Position = UDim2.new(1, -30, 0, 0),
                Size = UDim2.new(0, 20, 0, 36),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = Aurora.Config.Theme.TextMuted,
                Font = Aurora.Config.FontBold,
                TextSize = 12,
            })
            
            local OptionsFrame = Create("Frame", {
                Parent = Frame,
                Position = UDim2.new(0, 0, 0, 36),
                Size = UDim2.new(1, 0, 0, #options * 30),
                BackgroundColor3 = Aurora.Config.Theme.Surface,
                BorderSizePixel = 0,
                BackgroundTransparency = 1, -- FIXED: Start transparent
            })
            
            local OptionsList = Create("UIListLayout", {
                Parent = OptionsFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            
            for i, option in ipairs(options) do
                local Btn = Create("TextButton", {
                    Parent = OptionsFrame,
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Aurora.Config.Theme.Surface,
                    Text = option,
                    TextColor3 = Aurora.Config.Theme.TextMuted,
                    Font = Aurora.Config.FontMedium,
                    TextSize = 13,
                    BackgroundTransparency = 1, -- FIXED: Start transparent
                    LayoutOrder = i,
                })
                
                Btn.MouseEnter:Connect(function()
                    Tween(Btn, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, {BackgroundColor3 = Aurora.Config.Theme.Surface}, 0.2)
                end)
                Btn.MouseButton1Click:Connect(function()
                    Label.Text = option
                    dropdownConfig.Callback(option)
                    expanded = false
                    Tween(Frame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                    Tween(OptionsFrame, {BackgroundTransparency = 1}, 0.2)
                    for _, child in ipairs(OptionsFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            Tween(child, {BackgroundTransparency = 1, TextTransparency = 1}, 0.15)
                        end
                    end
                end)
            end
            
            local expanded = false
            local ClickArea = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "",
            })
            
            ClickArea.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    Tween(Frame, {Size = UDim2.new(1, 0, 0, 36 + #options * 30)}, 0.2)
                    Tween(Arrow, {Rotation = 180}, 0.2)
                    Tween(OptionsFrame, {BackgroundTransparency = 0}, 0.2)
                    for _, child in ipairs(OptionsFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.BackgroundTransparency = 0
                            Tween(child, {TextTransparency = 0}, 0.15)
                        end
                    end
                else
                    Tween(Frame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                    Tween(OptionsFrame, {BackgroundTransparency = 1}, 0.2)
                    for _, child in ipairs(OptionsFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            Tween(child, {BackgroundTransparency = 1, TextTransparency = 1}, 0.15)
                        end
                    end
                end
            end)
            
            return Frame
        end
        
        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Frame})
            
            local Btn = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = btnConfig.Text or "Button",
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = 14,
                AutoButtonColor = false,
            })
            
            Btn.MouseEnter:Connect(function()
                Tween(Frame, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.2)
            end)
            Btn.MouseLeave:Connect(function()
                Tween(Frame, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
            end)
            Btn.MouseButton1Down:Connect(function()
                Tween(Frame, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.1)
            end)
            Btn.MouseButton1Up:Connect(function()
                Tween(Frame, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.1)
            end)
            Btn.MouseButton1Click:Connect(btnConfig.Callback or function() end)
            
            return Frame
        end
        
        function Tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local state = toggleConfig.Default or false
            
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Frame})
            
            Create("TextLabel", {
                Parent = Frame,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text = toggleConfig.Text or "Toggle",
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ToggleBtn = Create("Frame", {
                Parent = Frame,
                Position = UDim2.new(1, -44, 0.5, -10),
                Size = UDim2.new(0, 36, 0, 20),
                BackgroundColor3 = state and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border,
                BorderSizePixel = 0,
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ToggleBtn})
            
            local Circle = Create("Frame", {
                Parent = ToggleBtn,
                Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Circle})
            
            local Click = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
            })
            
            Click.MouseButton1Click:Connect(function()
                state = not state
                Tween(ToggleBtn, {BackgroundColor3 = state and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border}, 0.2)
                Tween(Circle, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
                toggleConfig.Callback(state)
            end)
            
            return Frame
        end
        
        if #Window.Tabs == 0 then
            TabBtn.BackgroundColor3 = Aurora.Config.Theme.Primary
            TabBtn.TextColor3 = Aurora.Config.Theme.Text
            Content.Visible = true
            Window.ActiveTab = Tab
        end
        
        table.insert(Window.Tabs, Tab)
        return Tab
    end
    
    -- Draggable
    local dragging = false
    local dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Intro animation
    local targetSize = config.Size or UDim2.new(0, 600, 0, 400)
    Tween(MainFrame, {Size = targetSize}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    return Window
end

return Aurora
