--// Aurora UI Library v2.0
--// Enhanced: Mobile-first, persistent, polished
--// Version: 2.0.0

local Aurora = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// Device Detection
local DeviceType = "Desktop"
local TouchEnabled = UserInputService.TouchEnabled
local KeyboardEnabled = UserInputService.KeyboardEnabled
local ScreenSize = workspace.CurrentCamera.ViewportSize

if TouchEnabled and not KeyboardEnabled then
    DeviceType = "Mobile"
elseif ScreenSize.X < 800 then
    DeviceType = "Mobile"
end

--// Adaptive Configuration
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
        Glow = Color3.fromRGB(88, 101, 242),
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
    
    --// Adaptive Sizes
    Touch = {
        ButtonHeight = 48,
        ToggleHeight = 52,
        SliderHeight = 64,
        DropdownHeight = 48,
        TabHeight = 44,
        SidebarWidth = 140,
        CornerRadius = 8,
    },
    Desktop = {
        ButtonHeight = 36,
        ToggleHeight = 36,
        SliderHeight = 50,
        DropdownHeight = 36,
        TabHeight = 32,
        SidebarWidth = 120,
        CornerRadius = 6,
    }
}

--// Get adaptive value
local function GetAdaptive(desktopValue, mobileValue)
    if DeviceType == "Mobile" then
        return mobileValue or desktopValue
    end
    return desktopValue
end

--// Save/Load System
local SaveSystem = {
    Folder = "AuroraConfig",
    File = LocalPlayer.Name .. "_Aurora.json",
}

function SaveSystem:Save(data)
    local success, err = pcall(function()
        if not isfolder(self.Folder) then
            makefolder(self.Folder)
        end
        writefile(self.Folder .. "/" .. self.File, HttpService:JSONEncode(data))
    end)
    return success
end

function SaveSystem:Load()
    local success, data = pcall(function()
        if isfile(self.Folder .. "/" .. self.File) then
            return HttpService:JSONDecode(readfile(self.Folder .. "/" .. self.File))
        end
        return nil
    end)
    return success and data or nil
end

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

--// Enhanced Draggable (Touch + Mouse)
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos, touchConnection
    
    local function StartDrag(input)
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        if DeviceType == "Mobile" then
            -- Haptic feedback
            pcall(function()
                UserInputService:HapticFeedback(Enum.HapticFeedbackType.Light)
            end)
        end
    end
    
    local function UpdateDrag(input)
        if dragging then
            local delta = input.Position - dragStart
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, ScreenSize.X - frame.AbsoluteSize.X)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, ScreenSize.Y - frame.AbsoluteSize.Y)
            
            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end
    
    local function EndDrag()
        dragging = false
    end
    
    -- Mouse support
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            StartDrag(input)
        end
    end)
    
    -- Touch support
    handle.TouchBegan:Connect(function(input)
        StartDrag(input)
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            UpdateDrag(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            EndDrag()
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
        Position = UDim2.new(0.5, 0, 0.5, DeviceType == "Mobile" and 6 or 4),
        Size = UDim2.new(1, GetAdaptive(24, 32), 1, GetAdaptive(24, 32)),
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

--// Keybind Manager
local KeybindManager = {
    Binds = {},
    ToggleKey = Enum.KeyCode.Insert,
}

function KeybindManager:SetToggleKey(key)
    self.ToggleKey = key
end

function KeybindManager:Register(key, callback)
    self.Binds[key] = callback
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == KeybindManager.ToggleKey then
        -- Handled by window
    elseif KeybindManager.Binds[input.KeyCode] then
        KeybindManager.Binds[input.KeyCode]()
    end
end)

--// Main Window Creation
function Aurora:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Aurora"
    local size = config.Size or (DeviceType == "Mobile" and UDim2.new(0, math.min(400, ScreenSize.X - 40), 0, math.min(600, ScreenSize.Y - 100)) or UDim2.new(0, 700, 0, 450))
    local position = config.Position or UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    local toggleKey = config.ToggleKey or Enum.KeyCode.Insert
    
    KeybindManager:SetToggleKey(toggleKey)
    
    --// Load saved theme
    local savedData = SaveSystem:Load()
    if savedData and savedData.Theme then
        for key, value in pairs(savedData.Theme) do
            if typeof(value) == "table" and value.R then
                Aurora.Config.Theme[key] = Color3.fromRGB(value.R, value.G, value.B)
            end
        end
    end
    
    --// ScreenGui with mobile optimization
    local ScreenGui = Create("ScreenGui", {
        Name = "AuroraUI",
        Parent = DeviceType == "Mobile" and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui"),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    
    --// Safe area for mobile notches
    local SafeArea = Create("Frame", {
        Name = "SafeArea",
        Parent = ScreenGui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    })
    
    --// Main Frame
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = SafeArea,
        Position = position,
        Size = size,
        BackgroundColor3 = Aurora.Config.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = false, -- Allow dropdowns to overflow
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, GetAdaptive(6, 12)),
        Parent = MainFrame,
    })
    
    AddShadow(MainFrame, 1.2)
    
    --// Content Clipper (internal clipping only)
    local ContentClipper = Create("Frame", {
        Name = "ContentClipper",
        Parent = MainFrame,
        Position = UDim2.new(0, GetAdaptive(140, 160), 0, GetAdaptive(50, 60)),
        Size = UDim2.new(1, GetAdaptive(-150, -170), 1, GetAdaptive(-60, -70)),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })
    
    --// Title Bar
    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, GetAdaptive(40, 54)),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, GetAdaptive(6, 12)),
        Parent = TitleBar,
    })
    
    local TitleBarFix = Create("Frame", {
        Name = "Fix",
        Parent = TitleBar,
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    --// Title
    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = TitleBar,
        Position = UDim2.new(0, GetAdaptive(15, 20), 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Aurora.Config.Theme.Text,
        Font = Aurora.Config.FontBold,
        TextSize = GetAdaptive(16, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    --// Keybind Indicator
    local KeybindLabel = Create("TextLabel", {
        Name = "Keybind",
        Parent = TitleBar,
        Position = UDim2.new(1, GetAdaptive(-120, -140), 0, 0),
        Size = UDim2.new(0, 60, 1, 0),
        BackgroundTransparency = 1,
        Text = "[" .. toggleKey.Name .. "]",
        TextColor3 = Aurora.Config.Theme.TextMuted,
        Font = Aurora.Config.FontMedium,
        TextSize = GetAdaptive(12, 14),
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    
    --// Close Button
    local CloseButton = Create("TextButton", {
        Name = "Close",
        Parent = TitleBar,
        Position = UDim2.new(1, GetAdaptive(-35, -45), 0.5, -GetAdaptive(10, 12)),
        Size = UDim2.new(0, GetAdaptive(20, 24), 0, GetAdaptive(20, 24)),
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
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    --// Minimize Button
    local MinimizeButton = Create("TextButton", {
        Name = "Minimize",
        Parent = TitleBar,
        Position = UDim2.new(1, GetAdaptive(-60, -75), 0.5, -GetAdaptive(10, 12)),
        Size = UDim2.new(0, GetAdaptive(20, 24), 0, GetAdaptive(20, 24)),
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
            Tween(MainFrame, {Size = UDim2.new(0, size.X.Offset, 0, TitleBar.AbsoluteSize.Y)}, 0.3)
        else
            Tween(MainFrame, {Size = size}, 0.3)
        end
    end)
    
    --// Tab Container
    local TabContainer = Create("Frame", {
        Name = "TabContainer",
        Parent = MainFrame,
        Position = UDim2.new(0, 10, 0, TitleBar.AbsoluteSize.Y + 10),
        Size = UDim2.new(0, GetAdaptive(120, 140), 1, -(TitleBar.AbsoluteSize.Y + 20)),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, GetAdaptive(6, 10)),
        Parent = TabContainer,
    })
    
    local TabList = Create("UIListLayout", {
        Parent = TabContainer,
        Padding = UDim.new(0, GetAdaptive(5, 8)),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    
    Create("UIPadding", {
        Parent = TabContainer,
        PaddingTop = UDim.new(0, GetAdaptive(5, 8)),
        PaddingBottom = UDim.new(0, GetAdaptive(5, 8)),
        PaddingLeft = UDim.new(0, GetAdaptive(5, 8)),
        PaddingRight = UDim.new(0, GetAdaptive(5, 8)),
    })
    
    --// Content Container (outside clipper for dropdowns)
    local ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        Parent = MainFrame,
        Position = UDim2.new(0, TabContainer.AbsoluteSize.X + 20, 0, TitleBar.AbsoluteSize.Y + 10),
        Size = UDim2.new(1, -(TabContainer.AbsoluteSize.X + 30), 1, -(TitleBar.AbsoluteSize.Y + 20)),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = false, -- Allow dropdowns to overflow
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, GetAdaptive(6, 10)),
        Parent = ContentContainer,
    })
    
    --// Window Object
    local Window = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        TabContainer = TabContainer,
        ContentContainer = ContentContainer,
        ContentClipper = ContentClipper,
        Tabs = {},
        ActiveTab = nil,
        SaveData = savedData or {Theme = Aurora.Config.Theme, ToggleKey = toggleKey.Name},
    }
    
    --// Toggle Visibility with Keybind
    local visible = true
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey then
            visible = not visible
            if visible then
                MainFrame.Visible = true
                Tween(MainFrame, {Size = minimized and UDim2.new(0, size.X.Offset, 0, TitleBar.AbsoluteSize.Y) or size}, 0.3)
            else
                Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3).Completed:Connect(function()
                    MainFrame.Visible = false
                end)
            end
        end
    end)
    
    --// Save Function
    function Window:SaveConfig()
        local themeData = {}
        for key, color in pairs(Aurora.Config.Theme) do
            if typeof(color) == "Color3" then
                themeData[key] = {R = math.floor(color.R * 255), G = math.floor(color.G * 255), B = math.floor(color.B * 255)}
            end
        end
        self.SaveData.Theme = themeData
        SaveSystem:Save(self.SaveData)
    end
    
    --// Tab Creation
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or ""
        
        --// Tab Button
        local TabButton = Create("TextButton", {
            Name = tabName .. "Tab",
            Parent = TabContainer,
            Size = UDim2.new(1, 0, 0, GetAdaptive(32, 44)),
            BackgroundColor3 = Aurora.Config.Theme.Background,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #Window.Tabs + 1,
        })
        
        Create("UICorner", {
            CornerRadius = UDim.new(0, GetAdaptive(4, 8)),
            Parent = TabButton,
        })
        
        local TabLabel = Create("TextLabel", {
            Name = "Label",
            Parent = TabButton,
            Position = UDim2.new(0, GetAdaptive(10, 14), 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = Aurora.Config.Theme.TextMuted,
            Font = Aurora.Config.FontMedium,
            TextSize = GetAdaptive(13, 15),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        --// Tab Content (in clipper for scrolling, but dropdowns go to overlay)
        local TabContent = Create("ScrollingFrame", {
            Name = tabName .. "Content",
            Parent = ContentClipper,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = GetAdaptive(4, 6),
            ScrollBarImageColor3 = Aurora.Config.Theme.Primary,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        })
        
        local ContentLayout = Create("UIListLayout", {
            Parent = TabContent,
            Padding = UDim.new(0, GetAdaptive(10, 14)),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        
        Create("UIPadding", {
            Parent = TabContent,
            PaddingTop = UDim.new(0, GetAdaptive(10, 14)),
            PaddingBottom = UDim.new(0, GetAdaptive(10, 14)),
            PaddingLeft = UDim.new(0, GetAdaptive(10, 14)),
            PaddingRight = UDim.new(0, GetAdaptive(10, 14)),
        })
        
        --// Dropdown Overlay (solves clipping issue)
        local DropdownOverlay = Create("Frame", {
            Name = "DropdownOverlay",
            Parent = ContentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 100,
        })
        
        --// Tab Object
        local Tab = {
            Button = TabButton,
            Content = TabContent,
            DropdownOverlay = DropdownOverlay,
            Elements = {},
        }
        
        --// Tab Selection
        TabButton.MouseButton1Click:Connect(function()
            if Window.ActiveTab == Tab then return end
            
            if Window.ActiveTab then
                Tween(Window.ActiveTab.Button, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
                Tween(Window.ActiveTab.Button.Label, {TextColor3 = Aurora.Config.Theme.TextMuted}, 0.2)
                Window.ActiveTab.Content.Visible = false
                Window.ActiveTab.DropdownOverlay.Visible = false
            end
            
            Window.ActiveTab = Tab
            Tween(TabButton, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.2)
            Tween(TabLabel, {TextColor3 = Aurora.Config.Theme.Text}, 0.2)
            TabContent.Visible = true
            
            -- Slide animation
            TabContent.Position = UDim2.new(0.02, 0, 0, 0)
            Tween(TabContent, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart)
        end)
        
        --// Enhanced Button
        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local btnText = btnConfig.Text or "Button"
            local callback = btnConfig.Callback or function() end
            local keybind = btnConfig.Keybind
            
            local ButtonFrame = Create("Frame", {
                Name = "Button",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, GetAdaptive(36, 48)),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, GetAdaptive(4, 8)),
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
                TextSize = GetAdaptive(14, 16),
                AutoButtonColor = false,
            })
            
            -- Keybind indicator
            if keybind then
                local KeybindText = Create("TextLabel", {
                    Name = "Keybind",
                    Parent = ButtonFrame,
                    Position = UDim2.new(1, -50, 0, 0),
                    Size = UDim2.new(0, 40, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "[" .. keybind.Name .. "]",
                    TextColor3 = Aurora.Config.Theme.TextMuted,
                    Font = Aurora.Config.FontMedium,
                    TextSize = GetAdaptive(11, 13),
                    TextXAlignment = Enum.TextXAlignment.Right,
                })
                
                KeybindManager:Register(keybind, callback)
            end
            
            -- Touch/Mouse effects
            local function Hover()
                Tween(ButtonFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.2)
            end
            
            local function Unhover()
                Tween(ButtonFrame, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
            end
            
            local function Press()
                Tween(ButtonFrame, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.1)
                if DeviceType == "Mobile" then
                    pcall(function()
                        UserInputService:HapticFeedback(Enum.HapticFeedbackType.Medium)
                    end)
                end
            end
            
            local function Release()
                Tween(ButtonFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.1)
                callback()
            end
            
            Button.MouseEnter:Connect(Hover)
            Button.MouseLeave:Connect(Unhover)
            Button.MouseButton1Down:Connect(Press)
            Button.MouseButton1Up:Connect(Release)
            Button.TouchTap:Connect(Release)
            
            table.insert(Tab.Elements, ButtonFrame)
            return Button
        end
        
        --// Enhanced Toggle
        function Tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local toggleText = toggleConfig.Text or "Toggle"
            local default = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end
            local flag = toggleConfig.Flag
            
            local ToggleFrame = Create("Frame", {
                Name = "Toggle",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, GetAdaptive(36, 52)),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, GetAdaptive(4, 8)),
                Parent = ToggleFrame,
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = ToggleFrame,
                Position = UDim2.new(0, GetAdaptive(12, 16), 0, 0),
                Size = UDim2.new(1, -80, 1, 0),
                BackgroundTransparency = 1,
                Text = toggleText,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = GetAdaptive(14, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            -- Larger touch target for mobile
            local ToggleButton = Create("Frame", {
                Name = "ToggleButton",
                Parent = ToggleFrame,
                Position = UDim2.new(1, GetAdaptive(-44, -56), 0.5, -GetAdaptive(10, 14)),
                Size = UDim2.new(0, GetAdaptive(36, 48), 0, GetAdaptive(20, 28)),
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
                Position = default and UDim2.new(1, -GetAdaptive(18, 24), 0.5, -GetAdaptive(8, 11)) or UDim2.new(0, 2, 0.5, -GetAdaptive(8, 11)),
                Size = UDim2.new(0, GetAdaptive(16, 22), 0, GetAdaptive(16, 22)),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Circle,
            })
            
            local toggled = default
            if flag then
                Window.SaveData[flag] = toggled
            end
            
            local function UpdateToggle()
                local targetColor = toggled and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border
                local targetPos = toggled and UDim2.new(1, -GetAdaptive(18, 24), 0.5, -GetAdaptive(8, 11)) or UDim2.new(0, 2, 0.5, -GetAdaptive(8, 11))
                
                Tween(ToggleButton, {BackgroundColor3 = targetColor}, 0.2)
                Tween(Circle, {Position = targetPos}, 0.2)
                
                if DeviceType == "Mobile" and toggled ~= default then
                    pcall(function()
                        UserInputService:HapticFeedback(Enum.HapticFeedbackType.Light)
                    end)
                end
                
                if flag then
                    Window.SaveData[flag] = toggled
                end
                
                callback(toggled)
            end
            
            local ClickArea = Create("TextButton", {
                Name = "Click",
                Parent = ToggleFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
            })
            
            ClickArea.MouseButton1Click:Connect(function()
                toggled = not toggled
                UpdateToggle()
            end)
            
            table.insert(Tab.Elements, ToggleFrame)
            
            return {
                Frame = ToggleFrame,
                GetValue = function() return toggled end,
                SetValue = function(val)
                    toggled = val
                    UpdateToggle()
                end
            }
        end
        
        --// Enhanced Slider
        function Tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local sliderText = sliderConfig.Text or "Slider"
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local default = sliderConfig.Default or min
            local increment = sliderConfig.Increment or 1
            local callback = sliderConfig.Callback or function() end
            local flag = sliderConfig.Flag
            
            local SliderFrame = Create("Frame", {
                Name = "Slider",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, GetAdaptive(50, 68)),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, GetAdaptive(4, 8)),
                Parent = SliderFrame,
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = SliderFrame,
                Position = UDim2.new(0, GetAdaptive(12, 16), 0, GetAdaptive(8, 12)),
                Size = UDim2.new(1, -70, 0, GetAdaptive(16, 20)),
                BackgroundTransparency = 1,
                Text = sliderText,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = GetAdaptive(14, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ValueLabel = Create("TextLabel", {
                Name = "Value",
                Parent = SliderFrame,
                Position = UDim2.new(1, -60, 0, GetAdaptive(8, 12)),
                Size = UDim2.new(0, 50, 0, GetAdaptive(16, 20)),
                BackgroundTransparency = 1,
                Text = tostring(default),
                TextColor3 = Aurora.Config.Theme.Primary,
                Font = Aurora.Config.FontBold,
                TextSize = GetAdaptive(14, 16),
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            
            local SliderBar = Create("Frame", {
                Name = "Bar",
                Parent = SliderFrame,
                Position = UDim2.new(0, GetAdaptive(12, 16), 0, GetAdaptive(32, 44)),
                Size = UDim2.new(1, -GetAdaptive(24, 32), 0, GetAdaptive(6, 8)),
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
            
            -- Larger knob for mobile
            local knobSize = GetAdaptive(12, 20)
            local Knob = Create("Frame", {
                Name = "Knob",
                Parent = SliderBar,
                Position = UDim2.new((default - min) / (max - min), -knobSize/2, 0.5, -knobSize/2),
                Size = UDim2.new(0, knobSize, 0, knobSize),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 2,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = Knob,
            })
            
            -- Glow effect
            local KnobGlow = Create("ImageLabel", {
                Name = "Glow",
                Parent = Knob,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1.5, 0, 1.5, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6014261993",
                ImageColor3 = Aurora.Config.Theme.Primary,
                ImageTransparency = 0.8,
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(49, 49, 450, 450),
                ZIndex = 1,
            })
            
            local dragging = false
            local currentValue = default
            
            if flag then
                Window.SaveData[flag] = currentValue
            end
            
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pos)
                value = math.floor(value / increment + 0.5) * increment
                value = math.clamp(value, min, max)
                
                if value ~= currentValue then
                    currentValue = value
                    local fillScale = (value - min) / (max - min)
                    
                    Fill.Size = UDim2.new(fillScale, 0, 1, 0)
                    Knob.Position = UDim2.new(fillScale, -knobSize/2, 0.5, -knobSize/2)
                    ValueLabel.Text = tostring(value)
                    
                    if flag then
                        Window.SaveData[flag] = value
                    end
                    
                    callback(value)
                    
                    if DeviceType == "Mobile" then
                        pcall(function()
                            UserInputService:HapticFeedback(Enum.HapticFeedbackType.Light)
                        end)
                    end
                end
            end
            
            -- Touch and mouse support
            Knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Tween(Knob, {Size = UDim2.new(0, knobSize * 1.2, 0, knobSize * 1.2)}, 0.1)
                    Tween(KnobGlow, {ImageTransparency = 0.5}, 0.1)
                end
            end)
            
            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateSlider(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        dragging = false
                        Tween(Knob, {Size = UDim2.new(0, knobSize, 0, knobSize)}, 0.1)
                        Tween(KnobGlow, {ImageTransparency = 0.8}, 0.1)
                    end
                end
            end)
            
            table.insert(Tab.Elements, SliderFrame)
            
            return {
                Frame = SliderFrame,
                GetValue = function() return currentValue end,
                SetValue = function(val)
                    currentValue = math.clamp(val, min, max)
                    local fillScale = (currentValue - min) / (max - min)
                    Fill.Size = UDim2.new(fillScale, 0, 1, 0)
                    Knob.Position = UDim2.new(fillScale, -knobSize/2, 0.5, -knobSize/2)
                    ValueLabel.Text = tostring(currentValue)
                    callback(currentValue)
                end
            }
        end
        
        --// Fixed Dropdown (No clipping issues)
        function Tab:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local dropdownText = dropdownConfig.Text or "Dropdown"
            local options = dropdownConfig.Options or {}
            local default = dropdownConfig.Default
            local callback = dropdownConfig.Callback or function() end
            local flag = dropdownConfig.Flag
            
            local DropdownFrame = Create("Frame", {
                Name = "Dropdown",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, GetAdaptive(36, 48)),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
                ZIndex = 10,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, GetAdaptive(4, 8)),
                Parent = DropdownFrame,
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = DropdownFrame,
                Position = UDim2.new(0, GetAdaptive(12, 16), 0, 0),
                Size = UDim2.new(1, -50, 1, 0),
                BackgroundTransparency = 1,
                Text = dropdownText .. (default and (": " .. default) or ""),
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = GetAdaptive(14, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local Arrow = Create("ImageLabel", {
                Name = "Arrow",
                Parent = DropdownFrame,
                Position = UDim2.new(1, -30, 0.5, -6),
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundTransparency = 1,
                Image = "rbxassetid://7072706663", -- Chevron
                ImageColor3 = Aurora.Config.Theme.TextMuted,
            })
            
            --// Options Container (in overlay to avoid clipping)
            local OptionsContainer = Create("Frame", {
                Name = "OptionsContainer",
                Parent = Tab.DropdownOverlay,
                Position = UDim2.new(0, 0, 0, 0), -- Will be set dynamically
                Size = UDim2.new(0, 0, 0, 0), -- Will be set dynamically
                BackgroundColor3 = Aurora.Config.Theme.Surface,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 100,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, GetAdaptive(4, 8)),
                Parent = OptionsContainer,
            })
            
            AddShadow(OptionsContainer, 0.6)
            
            local OptionsList = Create("UIListLayout", {
                Parent = OptionsContainer,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
            })
            
            Create("UIPadding", {
                Parent = OptionsContainer,
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
            })
            
            local expanded = false
            local selected = default
            
            if flag and default then
                Window.SaveData[flag] = default
            end
            
            for i, option in ipairs(options) do
                local OptionBtn = Create("TextButton", {
                    Name = option,
                    Parent = OptionsContainer,
                    Size = UDim2.new(1, 0, 0, GetAdaptive(30, 40)),
                    BackgroundColor3 = Aurora.Config.Theme.Surface,
                    Text = option,
                    TextColor3 = Aurora.Config.Theme.TextMuted,
                    Font = Aurora.Config.FontMedium,
                    TextSize = GetAdaptive(13, 15),
                    LayoutOrder = i,
                    ZIndex = 101,
                })
                
                Create("UICorner", {
                    CornerRadius = UDim.new(0, GetAdaptive(2, 4)),
                    Parent = OptionBtn,
                })
                
                OptionBtn.MouseEnter:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Aurora.Config.Theme.Background, TextColor3 = Aurora.Config.Theme.Text}, 0.2)
                end)
                
                OptionBtn.MouseLeave:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Aurora.Config.Theme.Surface, TextColor3 = Aurora.Config.Theme.TextMuted}, 0.2)
                end)
                
                OptionBtn.MouseButton1Click:Connect(function()
                    selected = option
                    Label.Text = dropdownText .. ": " .. option
                    
                    if flag then
                        Window.SaveData[flag] = option
                    end
                    
                    callback(option)
                    
                    expanded = false
                    Tween(OptionsContainer, {Size = UDim2.new(0, OptionsContainer.AbsoluteSize.X, 0, 0)}, 0.2).Completed:Connect(function()
                        OptionsContainer.Visible = false
                    end)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                    
                    if DeviceType == "Mobile" then
                        pcall(function()
                            UserInputService:HapticFeedback(Enum.HapticFeedbackType.Light)
                        end)
                    end
                end)
            end
            
            -- Position options container when expanding
            local function PositionOptions()
                local absPos = DropdownFrame.AbsolutePosition
                local absSize = DropdownFrame.AbsoluteSize
                OptionsContainer.Position = UDim2.new(0, absPos.X - ContentContainer.AbsolutePosition.X, 0, absPos.Y - ContentContainer.AbsolutePosition.Y + absSize.Y + 4)
                OptionsContainer.Size = UDim2.new(0, absSize.X, 0, 0)
            end
            
            local ClickArea = Create("TextButton", {
                Name = "Click",
                Parent = DropdownFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
            })
            
            ClickArea.MouseButton1Click:Connect(function()
                expanded = not expanded
                
                if expanded then
                    Tab.DropdownOverlay.Visible = true
                    OptionsContainer.Visible = true
                    PositionOptions()
                    
                    local targetHeight = math.min(#options * GetAdaptive(32, 42) + 8, 200)
                    Tween(OptionsContainer, {Size = UDim2.new(0, OptionsContainer.AbsoluteSize.X, 0, targetHeight)}, 0.2)
                    Tween(Arrow, {Rotation = 180}, 0.2)
                else
                    Tween(OptionsContainer, {Size = UDim2.new(0, OptionsContainer.AbsoluteSize.X, 0, 0)}, 0.2).Completed:Connect(function()
                        OptionsContainer.Visible = false
                        Tab.DropdownOverlay.Visible = false
                    end)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end
            end)
            
            -- Close when clicking outside
            Tab.DropdownOverlay.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if expanded then
                        expanded = false
                        Tween(OptionsContainer, {Size = UDim2.new(0, OptionsContainer.AbsoluteSize.X, 0, 0)}, 0.2).Completed:Connect(function()
                            OptionsContainer.Visible = false
                            Tab.DropdownOverlay.Visible = false
                        end)
                        Tween(Arrow, {Rotation = 0}, 0.2)
                    end
                end
            end)
            
            table.insert(Tab.Elements, DropdownFrame)
            
            return {
                Frame = DropdownFrame,
                GetValue = function() return selected end,
                SetValue = function(val)
                    if table.find(options, val) then
                        selected = val
                        Label.Text = dropdownText .. ": " .. val
                        if flag then
                            Window.SaveData[flag] = val
                        end
                    end
                end,
                Refresh = function(newOptions)
                    options = newOptions
                    for _, child in ipairs(OptionsContainer:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    -- Rebuild options...
                end
            }
        end
        
        --// Color Picker (New)
        function Tab:CreateColorPicker(pickerConfig)
            pickerConfig = pickerConfig or {}
            local pickerText = pickerConfig.Text or "Color"
            local default = pickerConfig.Default or Color3.fromRGB(255, 255, 255)
            local callback = pickerConfig.Callback or function() end
            local flag = pickerConfig.Flag
            
            local ColorFrame = Create("Frame", {
                Name = "ColorPicker",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, GetAdaptive(36, 48)),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, GetAdaptive(4, 8)),
                Parent = ColorFrame,
            })
            
            local Label = Create("TextLabel", {
                Name = "Label",
                Parent = ColorFrame,
                Position = UDim2.new(0, GetAdaptive(12, 16), 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text = pickerText,
                TextColor3 = Aurora.Config.Theme.Text,
                Font = Aurora.Config.FontMedium,
                TextSize = GetAdaptive(14, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ColorDisplay = Create("Frame", {
                Name = "Color",
                Parent = ColorFrame,
                Position = UDim2.new(1, -44, 0.5, -10),
                Size = UDim2.new(0, 32, 0, 20),
                BackgroundColor3 = default,
                BorderSizePixel = 0,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = ColorDisplay,
            })
            
            local currentColor = default
            
            local ClickArea = Create("TextButton", {
                Name = "Click",
                Parent = ColorFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
            })
            
            ClickArea.MouseButton1Click:Connect(function()
                -- Simple RGB input for now, can be expanded to full picker
                -- This is a placeholder for full HSV picker implementation
                callback(currentColor)
            end)
            
            table.insert(Tab.Elements, ColorFrame)
            
            return {
                Frame = ColorFrame,
                GetValue = function() return currentColor end,
                SetValue = function(color)
                    currentColor = color
                    ColorDisplay.BackgroundColor3 = color
                    callback(color)
                end
            }
        end
        
        --// Label & Section (unchanged but enhanced)
        function Tab:CreateLabel(text)
            local LabelFrame = Create("Frame", {
                Name = "Label",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, GetAdaptive(24, 28)),
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
                TextSize = GetAdaptive(12, 14),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            table.insert(Tab.Elements, LabelFrame)
            return Label
        end
        
        function Tab:CreateSection(sectionText)
            local SectionFrame = Create("Frame", {
                Name = "Section",
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, GetAdaptive(30, 36)),
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
                TextSize = GetAdaptive(13, 15),
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
    
    --// Auto-save on exit
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then
            Window:SaveConfig()
        end
    end)
    
    --// Make draggable
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

--// Enhanced Notification System
function Aurora:Notify(notifyConfig)
    notifyConfig = notifyConfig or {}
    local title = notifyConfig.Title or "Notification"
    local message = notifyConfig.Message or ""
    local notifyType = notifyConfig.Type or "Info"
    local duration = notifyConfig.Duration or 3
    local actions = notifyConfig.Actions -- { {Text = "Confirm", Callback = function} }
    
    local colors = {
        Info = Aurora.Config.Theme.Primary,
        Success = Aurora.Config.Theme.Success,
        Warning = Aurora.Config.Theme.Warning,
        Error = Aurora.Config.Theme.Error,
    }
    
    local color = colors[notifyType] or colors.Info
    
    --// Notification Container (supports stacking)
    local NotifGui = Create("ScreenGui", {
        Name = "AuroraNotifications",
        Parent = DeviceType == "Mobile" and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui"),
        ResetOnSpawn = false,
        DisplayOrder = 1000,
    })
    
    -- Calculate position based on existing notifications
    local existingNotifs = 0
    for _, gui in ipairs((DeviceType == "Mobile" and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")):GetChildren()) do
        if gui.Name == "AuroraNotifications" then
            existingNotifs = existingNotifs + 1
        end
    end
    
    local NotifFrame = Create("Frame", {
        Name = "Notification",
        Parent = NotifGui,
        Position = UDim2.new(1, -20, 1, -(100 + (existingNotifs * 90))),
        Size = UDim2.new(0, GetAdaptive(280, 320), 0, actions and 100 or 80),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel = 0,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, GetAdaptive(6, 10)),
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
        CornerRadius = UDim.new(0, GetAdaptive(6, 10)),
        Parent = AccentBar,
    })
    
    --// Content
    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = NotifFrame,
        Position = UDim2.new(0, GetAdaptive(16, 20), 0, 12),
        Size = UDim2.new(1, -32, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Aurora.Config.Theme.Text,
        Font = Aurora.Config.FontBold,
        TextSize = GetAdaptive(14, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local MessageLabel = Create("TextLabel", {
        Name = "Message",
        Parent = NotifFrame,
        Position = UDim2.new(0, GetAdaptive(16, 20), 0, 34),
        Size = UDim2.new(1, -32, 0, actions and 30 or 40),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Aurora.Config.Theme.TextMuted,
        Font = Aurora.Config.Font,
        TextSize = GetAdaptive(13, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    })
    
    --// Action Buttons
    if actions then
        local ActionsFrame = Create("Frame", {
            Name = "Actions",
            Parent = NotifFrame,
            Position = UDim2.new(0, GetAdaptive(16, 20), 1, -36),
            Size = UDim2.new(1, -32, 0, 30),
            BackgroundTransparency = 1,
        })
        
        local ActionLayout = Create("UIListLayout", {
            Parent = ActionsFrame,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8),
        })
        
        for _, action in ipairs(actions) do
            local ActionBtn = Create("TextButton", {
                Name = action.Text,
                Parent = ActionsFrame,
                Size = UDim2.new(0, 60, 1, 0),
                BackgroundColor3 = color,
                Text = action.Text,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Aurora.Config.FontMedium,
                TextSize = 12,
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = ActionBtn,
            })
            
            ActionBtn.MouseButton1Click:Connect(function()
                action.Callback()
                Tween(NotifFrame, {Position = UDim2.new(1, 20, NotifFrame.Position.Y.Scale, NotifFrame.Position.Y.Offset)}, 0.3)
                task.wait(0.3)
                NotifGui:Destroy()
            end)
        end
    end
    
    --// Progress Bar
    local ProgressBar = Create("Frame", {
        Name = "Progress",
        Parent = NotifFrame,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    })
    
    --// Swipe to dismiss (mobile)
    if DeviceType == "Mobile" then
        local touchStart = nil
        NotifFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                touchStart = input.Position.X
            end
        end)
        
        NotifFrame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and touchStart then
                local delta = input.Position.X - touchStart
                if delta > 50 then -- Swiped right
                    Tween(NotifFrame, {Position = UDim2.new(1, 20, NotifFrame.Position.Y.Scale, NotifFrame.Position.Y.Offset)}, 0.3)
                    task.wait(0.3)
                    NotifGui:Destroy()
                end
                touchStart = nil
            end
        end)
    end
    
    --// Animation
    NotifFrame.Position = UDim2.new(1, 0, NotifFrame.Position.Y.Scale, NotifFrame.Position.Y.Offset)
    Tween(NotifFrame, {Position = UDim2.new(1, GetAdaptive(-300, -340), NotifFrame.Position.Y.Scale, NotifFrame.Position.Y.Offset)}, 0.4, Enum.EasingStyle.Quart)
    
    Tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)
    
    task.delay(duration, function()
        if NotifGui.Parent then
            Tween(NotifFrame, {Position = UDim2.new(1, 20, NotifFrame.Position.Y.Scale, NotifFrame.Position.Y.Offset)}, 0.4, Enum.EasingStyle.Quart)
            task.wait(0.4)
            NotifGui:Destroy()
        end
    end)
end

--// Theme Customization with Persistence
function Aurora:SetTheme(newTheme)
    for key, value in pairs(newTheme) do
        if Aurora.Config.Theme[key] then
            Aurora.Config.Theme[key] = value
        end
    end
    
    -- Save to file
    local themeData = {}
    for k, color in pairs(Aurora.Config.Theme) do
        if typeof(color) == "Color3" then
            themeData[k] = {R = math.floor(color.R * 255), G = math.floor(color.G * 255), B = math.floor(color.B * 255)}
        end
    end
    
    local saveData = SaveSystem:Load() or {}
    saveData.Theme = themeData
    SaveSystem:Save(saveData)
end

return Aurora
