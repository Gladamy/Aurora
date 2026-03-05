--// Aurora UI Library v2.1 - Bug Fixes
--// Fixed: Content rendering, clipping, layout updates

local Aurora = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

--// Wait for character to prevent nil errors
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

--// Device Detection (safer)
local DeviceType = "Desktop"
local TouchEnabled = UserInputService.TouchEnabled
local KeyboardEnabled = UserInputService.KeyboardEnabled

if TouchEnabled and not KeyboardEnabled then
    DeviceType = "Mobile"
elseif workspace.CurrentCamera.ViewportSize.X < 800 then
    DeviceType = "Mobile"
end

--// Config
Aurora.Config = {
    Theme = {
        Primary = Color3.fromRGB(88, 101, 242),
        Secondary = Color3.fromRGB(30, 30, 35),
        Background = Color3.fromRGB(18, 18, 22),
        Surface = Color3.fromRGB(25, 25, 30),
        Text = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(150, 150, 160),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        Border = Color3.fromRGB(40, 40, 50),
    },
    Animation = {
        Duration = 0.3,
        Easing = Enum.EasingStyle.Quart,
        Direction = Enum.EasingDirection.Out,
    },
}

--// Utility
local function Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        instance[prop] = value
    end
    return instance
end

local function Tween(instance, properties, duration)
    local tweenInfo = TweenInfo.new(
        duration or Aurora.Config.Animation.Duration,
        Aurora.Config.Animation.Easing,
        Aurora.Config.Animation.Direction
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

--// Main Window
function Aurora:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Aurora"
    local toggleKey = config.ToggleKey or Enum.KeyCode.Insert
    
    --// ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = "AuroraUI_" .. tostring(math.random(1000, 9999)),
        Parent = game:GetService("CoreGui"),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    })
    
    --// Main Frame
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        Position = UDim2.new(0.5, -350, 0.5, -225),
        Size = UDim2.new(0, 700, 0, 450),
        BackgroundColor3 = Aurora.Config.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = MainFrame,
    })
    
    --// Shadow
    local Shadow = Create("ImageLabel", {
        Name = "Shadow",
        Parent = MainFrame,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 40, 1, 40),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
    })
    
    --// Title Bar
    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = TitleBar,
    })
    
    -- Fix bottom corners
    Create("Frame", {
        Parent = TitleBar,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    
    --// Title
    Create("TextLabel", {
        Name = "Title",
        Parent = TitleBar,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Aurora.Config.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    })
    
    --// Close Button
    local CloseBtn = Create("TextButton", {
        Name = "Close",
        Parent = TitleBar,
        Position = UDim2.new(1, -35, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Aurora.Config.Theme.Error,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = CloseBtn})
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    --// Minimize Button
    local MinBtn = Create("TextButton", {
        Name = "Minimize",
        Parent = TitleBar,
        Position = UDim2.new(1, -60, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Aurora.Config.Theme.Warning,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = MinBtn})
    
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, {Size = UDim2.new(0, 700, 0, 40)}, 0.3)
        else
            Tween(MainFrame, {Size = UDim2.new(0, 700, 0, 450)}, 0.3)
        end
    end)
    
    --// Tab Container
    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Parent = MainFrame,
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(0, 130, 1, -60),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TabContainer})
    
    local TabList = Create("UIListLayout", {
        Parent = TabContainer,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    
    Create("UIPadding", {
        Parent = TabContainer,
        PaddingTop = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    })
    
    --// Content Container
    local ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        Parent = MainFrame,
        Position = UDim2.new(0, 150, 0, 50),
        Size = UDim2.new(1, -160, 1, -60),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = ContentContainer})
    
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
        
        -- Tab Button
        local TabBtn = Create("TextButton", {
            Name = tabName .. "Tab",
            Parent = TabContainer,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Aurora.Config.Theme.Background,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #Window.Tabs + 1,
            ZIndex = 3,
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = TabBtn})
        
        local TabLbl = Create("TextLabel", {
            Name = "Label",
            Parent = TabBtn,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = Aurora.Config.Theme.TextMuted,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4,
        })
        
        -- Tab Content - CRITICAL FIX: Parent to ContentContainer directly
        local TabContent = Create("ScrollingFrame", {
            Name = tabName .. "Content",
            Parent = ContentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Aurora.Config.Theme.Primary,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0), -- Will auto-update
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 3,
        })
        
        -- CRITICAL FIX: Proper list layout with padding
        local ContentList = Create("UIListLayout", {
            Parent = TabContent,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        
        Create("UIPadding", {
            Parent = TabContent,
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        })
        
        -- CRITICAL FIX: Force layout update
        ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 20)
        end)
        
        local Tab = {
            Button = TabBtn,
            Content = TabContent,
        }
        
        -- Tab Selection
        TabBtn.MouseButton1Click:Connect(function()
            if Window.ActiveTab == Tab then return end
            
            if Window.ActiveTab then
                Window.ActiveTab.Content.Visible = false
                Tween(Window.ActiveTab.Button, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
                Window.ActiveTab.Button.Label.TextColor3 = Aurora.Config.Theme.TextMuted
            end
            
            Window.ActiveTab = Tab
            TabContent.Visible = true
            Tween(TabBtn, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.2)
            TabLbl.TextColor3 = Aurora.Config.Theme.Text
            
            -- Entrance animation
            TabContent.Position = UDim2.new(0.02, 0, 0, 0)
            Tween(TabContent, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
        end)
        
        --// Button Element
        function Tab:CreateButton(config)
            config = config or {}
            local text = config.Text or "Button"
            local callback = config.Callback or function() end
            
            local BtnFrame = Create("Frame", {
                Name = "Button",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
                LayoutOrder = #TabContent:GetChildren(),
                ZIndex = 4,
            })
            
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = BtnFrame})
            
            local Btn = Create("TextButton", {
                Name = "Click",
                Parent = BtnFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                ZIndex = 5,
            })
            
            Btn.MouseEnter:Connect(function()
                Tween(BtnFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.2)
            end)
            
            Btn.MouseLeave:Connect(function()
                Tween(BtnFrame, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
            end)
            
            Btn.MouseButton1Click:Connect(callback)
            
            return BtnFrame
        end
        
        --// Toggle Element
        function Tab:CreateToggle(config)
            config = config or {}
            local text = config.Text or "Toggle"
            local default = config.Default or false
            local callback = config.Callback or function() end
            
            local ToggleFrame = Create("Frame", {
                Name = "Toggle",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
                LayoutOrder = #TabContent:GetChildren(),
                ZIndex = 4,
            })
            
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = ToggleFrame})
            
            Create("TextLabel", {
                Parent = ToggleFrame,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            })
            
            local ToggleBtn = Create("Frame", {
                Parent = ToggleFrame,
                Position = UDim2.new(1, -44, 0.5, -10),
                Size = UDim2.new(0, 36, 0, 20),
                BackgroundColor3 = default and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border,
                BorderSizePixel = 0,
                ZIndex = 5,
            })
            
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ToggleBtn})
            
            local Circle = Create("Frame", {
                Parent = ToggleBtn,
                Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 6,
            })
            
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Circle})
            
            local toggled = default
            
            local ClickArea = Create("TextButton", {
                Parent = ToggleFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 10,
            })
            
            ClickArea.MouseButton1Click:Connect(function()
                toggled = not toggled
                local color = toggled and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border
                local pos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                
                Tween(ToggleBtn, {BackgroundColor3 = color}, 0.2)
                Tween(Circle, {Position = pos}, 0.2)
                callback(toggled)
            end)
            
            return ToggleFrame
        end
        
        --// Label Element
        function Tab:CreateLabel(text)
            local LabelFrame = Create("Frame", {
                Name = "Label",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                LayoutOrder = #TabContent:GetChildren(),
                ZIndex = 4,
            })
            
            Create("TextLabel", {
                Parent = LabelFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = text or "Label",
                TextColor3 = Aurora.Config.Theme.TextMuted,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            })
            
            return LabelFrame
        end
        
        --// Section Element
        function Tab:CreateSection(text)
            local SectionFrame = Create("Frame", {
                Name = "Section",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                LayoutOrder = #TabContent:GetChildren(),
                ZIndex = 4,
            })
            
            Create("TextLabel", {
                Parent = SectionFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = text or "Section",
                TextColor3 = Aurora.Config.Theme.Primary,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            })
            
            Create("Frame", {
                Parent = SectionFrame,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Aurora.Config.Theme.Border,
                BorderSizePixel = 0,
                ZIndex = 5,
            })
            
            return SectionFrame
        end
        
        -- Initialize first tab
        if #Window.Tabs == 0 then
            TabBtn.BackgroundColor3 = Aurora.Config.Theme.Primary
            TabLbl.TextColor3 = Aurora.Config.Theme.Text
            TabContent.Visible = true
            Window.ActiveTab = Tab
        end
        
        table.insert(Window.Tabs, Tab)
        return Tab
    end
    
    --// Draggable
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
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    --// Toggle Key
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
    
    --// Intro Animation
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    Tween(MainFrame, {
        Size = UDim2.new(0, 700, 0, 450),
        Position = UDim2.new(0.5, -350, 0.5, -225)
    }, 0.5, Enum.EasingStyle.Back)
    
    return Window
end

--// Notification System
function Aurora:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local message = config.Message or ""
    local nType = config.Type or "Info"
    local duration = config.Duration or 3
    
    local colors = {
        Info = Aurora.Config.Theme.Primary,
        Success = Aurora.Config.Theme.Success,
        Warning = Aurora.Config.Theme.Warning,
        Error = Aurora.Config.Theme.Error,
    }
    
    local color = colors[nType] or colors.Info
    
    local NotifGui = Create("ScreenGui", {
        Name = "AuroraNotif",
        Parent = game:GetService("CoreGui"),
        ResetOnSpawn = false,
    })
    
    local Frame = Create("Frame", {
        Parent = NotifGui,
        Position = UDim2.new(1, -300, 1, -100),
        Size = UDim2.new(0, 260, 0, 70),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Frame})
    
    Create("Frame", {
        Parent = Frame,
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    })
    
    Create("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Aurora.Config.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    Create("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 15, 0, 32),
        Size = UDim2.new(1, -30, 0, 30),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Aurora.Config.Theme.TextMuted,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Animation
    Frame.Position = UDim2.new(1, 0, 1, -100)
    Tween(Frame, {Position = UDim2.new(1, -280, 1, -100)}, 0.4)
    
    task.delay(duration, function()
        Tween(Frame, {Position = UDim2.new(1, 20, 1, -100)}, 0.4).Completed:Wait()
        NotifGui:Destroy()
    end)
end

return Aurora
