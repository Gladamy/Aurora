--// Aurora UI Library
--// A minimalistic, beautiful UI library for Roblox
--// Version: 2.0.0

local Aurora = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ─────────────────────────────────────────────
--  Configuration
-- ─────────────────────────────────────────────

Aurora.Config = {
    Theme = {
        Primary     = Color3.fromRGB(88,  101, 242),
        Secondary   = Color3.fromRGB(30,  30,  35),
        Background  = Color3.fromRGB(18,  18,  22),
        Surface     = Color3.fromRGB(25,  25,  30),
        Text        = Color3.fromRGB(245, 245, 250),
        TextMuted   = Color3.fromRGB(150, 150, 160),
        Success     = Color3.fromRGB(46,  204, 113),
        Warning     = Color3.fromRGB(241, 196, 15),
        Error       = Color3.fromRGB(231, 76,  60),
        Border      = Color3.fromRGB(40,  40,  50),
        Glow        = Color3.fromRGB(88,  101, 242),
    },
    Animation = {
        Duration  = 0.3,
        Easing    = Enum.EasingStyle.Quart,
        Direction = Enum.EasingDirection.Out,
    },
    Font       = Enum.Font.Gotham,
    FontBold   = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    CornerRadius       = UDim.new(0, 6),
    ShadowTransparency = 0.7,
}

-- ─────────────────────────────────────────────
--  Internal notification queue
-- ─────────────────────────────────────────────

local notifQueue   = {}
local NOTIF_HEIGHT = 80
local NOTIF_GAP    = 10
local NOTIF_X      = -320   -- offset from right edge

local function _repositionNotifs()
    for i, data in ipairs(notifQueue) do
        local targetY = -(i * (NOTIF_HEIGHT + NOTIF_GAP))
        Tween(data.frame, {Position = UDim2.new(1, NOTIF_X, 1, targetY)}, 0.25)
    end
end

-- ─────────────────────────────────────────────
--  Utility
-- ─────────────────────────────────────────────

local function Create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

-- Forward-declare Tween so it can be used in _repositionNotifs above
Tween = function(inst, props, duration, easingStyle, easingDirection)
    local info = TweenInfo.new(
        duration      or Aurora.Config.Animation.Duration,
        easingStyle   or Aurora.Config.Animation.Easing,
        easingDirection or Aurora.Config.Animation.Direction
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function AddShadow(parent, intensity)
    intensity = intensity or 1
    return Create("ImageLabel", {
        Name             = "Shadow",
        Parent           = parent,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 4),
        Size             = UDim2.new(1, 24, 1, 24),
        BackgroundTransparency = 1,
        Image            = "rbxassetid://6014261993",
        ImageColor3      = Color3.new(0, 0, 0),
        ImageTransparency = Aurora.Config.ShadowTransparency * intensity,
        ScaleType        = Enum.ScaleType.Slice,
        SliceCenter      = Rect.new(49, 49, 450, 450),
        ZIndex           = parent.ZIndex - 1,
    })
end

local function AddCorner(parent, radius)
    return Create("UICorner", {CornerRadius = radius or Aurora.Config.CornerRadius, Parent = parent})
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    local conns = {}
    conns[1] = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)

    conns[2] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    conns[3] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Returns disconnect function for cleanup
    return function()
        for _, c in ipairs(conns) do c:Disconnect() end
    end
end

-- ─────────────────────────────────────────────
--  Window
-- ─────────────────────────────────────────────

function Aurora:CreateWindow(config)
    config   = config or {}
    local title    = config.Title    or "Aurora"
    local size     = config.Size     or UDim2.new(0, 620, 0, 420)
    local position = config.Position or UDim2.new(0.5, -310, 0.5, -210)

    local connections = {}  -- all connections owned by this window

    --// ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name           = "AuroraUI",
        Parent         = LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    --// Main Frame
    local MainFrame = Create("Frame", {
        Name             = "MainFrame",
        Parent           = ScreenGui,
        Position         = position,
        Size             = size,
        BackgroundColor3 = Aurora.Config.Theme.Background,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })
    AddCorner(MainFrame)
    AddShadow(MainFrame, 1.2)

    --// Title Bar
    local TitleBar = Create("Frame", {
        Name             = "TitleBar",
        Parent           = MainFrame,
        Size             = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
    })
    AddCorner(TitleBar)

    -- Patch bottom-rounded corners on titlebar
    Create("Frame", {
        Parent           = TitleBar,
        Position         = UDim2.new(0, 0, 1, -8),
        Size             = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
    })

    Create("TextLabel", {
        Name               = "Title",
        Parent             = TitleBar,
        Position           = UDim2.new(0, 15, 0, 0),
        Size               = UDim2.new(1, -120, 1, 0),
        BackgroundTransparency = 1,
        Text               = title,
        TextColor3         = Aurora.Config.Theme.Text,
        Font               = Aurora.Config.FontBold,
        TextSize           = 16,
        TextXAlignment     = Enum.TextXAlignment.Left,
    })

    --// Window control buttons (close / minimize)
    local function MakeControlBtn(xOffset, icon, bgColor)
        local btn = Create("TextButton", {
            Parent           = TitleBar,
            Position         = UDim2.new(1, xOffset, 0.5, -10),
            Size             = UDim2.new(0, 20, 0, 20),
            BackgroundColor3 = Aurora.Config.Theme.Surface,
            Text             = icon,
            TextColor3       = bgColor,
            Font             = Aurora.Config.FontBold,
            TextSize         = 13,
            AutoButtonColor  = false,
            BorderSizePixel  = 0,
        })
        AddCorner(btn, UDim.new(0, 4))

        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = bgColor, TextColor3 = Aurora.Config.Theme.Text}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = Aurora.Config.Theme.Surface, TextColor3 = bgColor}, 0.15)
        end)
        return btn
    end

    local CloseBtn    = MakeControlBtn(-28, "✕", Aurora.Config.Theme.Error)
    local MinimizeBtn = MakeControlBtn(-54, "—", Aurora.Config.Theme.TextMuted)

    CloseBtn.MouseButton1Click:Connect(function()
        local cx = MainFrame.Position.X.Offset + size.X.Offset / 2
        local cy = MainFrame.Position.Y.Offset + size.Y.Offset / 2
        Tween(MainFrame, {
            Size     = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(MainFrame.Position.X.Scale, cx, MainFrame.Position.Y.Scale, cy),
        }, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
        -- Disconnect all window-level connections
        for _, c in ipairs(connections) do c:Disconnect() end
    end)

    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(MainFrame, {Size = minimized and UDim2.new(0, size.X.Offset, 0, 40) or size}, 0.3)
    end)

    --// Tab sidebar (wider for icon + label)
    local TabContainer = Create("Frame", {
        Name             = "TabContainer",
        Parent           = MainFrame,
        Position         = UDim2.new(0, 8, 0, 48),
        Size             = UDim2.new(0, 130, 1, -56),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
    })
    AddCorner(TabContainer)

    Create("UIListLayout", {
        Parent    = TabContainer,
        Padding   = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {
        Parent        = TabContainer,
        PaddingTop    = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 6),
        PaddingRight  = UDim.new(0, 6),
    })

    --// Content area
    local ContentContainer = Create("Frame", {
        Name             = "ContentContainer",
        Parent           = MainFrame,
        Position         = UDim2.new(0, 146, 0, 48),
        Size             = UDim2.new(1, -154, 1, -56),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })
    AddCorner(ContentContainer)

    --// Window object
    local Window = {
        ScreenGui        = ScreenGui,
        MainFrame        = MainFrame,
        TabContainer     = TabContainer,
        ContentContainer = ContentContainer,
        Tabs             = {},
        ActiveTab        = nil,
        _connections     = connections,
    }

    -- Programmatically activate a tab
    function Window:SelectTab(index)
        local tab = self.Tabs[index]
        if tab and tab.Activate then tab.Activate() end
    end

    -- ─────────────────────────────────────────
    --  Tab creation
    -- ─────────────────────────────────────────

    function Window:CreateTab(tabConfig)
        tabConfig   = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or ""   -- now actually rendered

        --// Tab button
        local TabButton = Create("TextButton", {
            Name             = tabName .. "Tab",
            Parent           = TabContainer,
            Size             = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Aurora.Config.Theme.Background,
            Text             = "",
            AutoButtonColor  = false,
            LayoutOrder      = #Window.Tabs + 1,
        })
        AddCorner(TabButton, UDim.new(0, 4))

        -- Icon (optional)
        if tabIcon ~= "" then
            Create("ImageLabel", {
                Name               = "Icon",
                Parent             = TabButton,
                Position           = UDim2.new(0, 8, 0.5, -8),
                Size               = UDim2.new(0, 16, 0, 16),
                BackgroundTransparency = 1,
                Image              = tabIcon,
                ImageColor3        = Aurora.Config.Theme.TextMuted,
            })
        end

        local iconOffset = (tabIcon ~= "") and 30 or 10
        local TabLabel = Create("TextLabel", {
            Name               = "Label",
            Parent             = TabButton,
            Position           = UDim2.new(0, iconOffset, 0, 0),
            Size               = UDim2.new(1, -iconOffset - 4, 1, 0),
            BackgroundTransparency = 1,
            Text               = tabName,
            TextColor3         = Aurora.Config.Theme.TextMuted,
            Font               = Aurora.Config.FontMedium,
            TextSize           = 13,
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextTruncate       = Enum.TextTruncate.AtEnd,
        })

        --// Tab content (scrollable)
        local TabContent = Create("ScrollingFrame", {
            Name                 = tabName .. "Content",
            Parent               = ContentContainer,
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            ScrollBarThickness   = 2,
            ScrollBarImageColor3 = Aurora.Config.Theme.Primary,
            Visible              = false,
            AutomaticCanvasSize  = Enum.AutomaticSize.Y,
            CanvasSize           = UDim2.new(0, 0, 0, 0),
        })

        Create("UIListLayout", {
            Parent    = TabContent,
            Padding   = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        Create("UIPadding", {
            Parent        = TabContent,
            PaddingTop    = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 12),
        })

        --// Tab object
        local Tab = {
            Button   = TabButton,
            Content  = TabContent,
            Elements = {},
            Activate = nil,  -- set below after closure is defined
        }

        local function Activate()
            if Window.ActiveTab == Tab then return end

            if Window.ActiveTab then
                Tween(Window.ActiveTab.Button, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
                Tween(Window.ActiveTab.Button.Label, {TextColor3 = Aurora.Config.Theme.TextMuted}, 0.2)
                if Window.ActiveTab.Button:FindFirstChild("Icon") then
                    Tween(Window.ActiveTab.Button.Icon, {ImageColor3 = Aurora.Config.Theme.TextMuted}, 0.2)
                end
                Window.ActiveTab.Content.Visible = false
            end

            Window.ActiveTab = Tab
            Tween(TabButton, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.2)
            Tween(TabLabel,  {TextColor3 = Aurora.Config.Theme.Text}, 0.2)
            if TabButton:FindFirstChild("Icon") then
                Tween(TabButton.Icon, {ImageColor3 = Aurora.Config.Theme.Text}, 0.2)
            end

            TabContent.Visible = true
            TabContent.CanvasPosition = Vector2.new(0, 0)
        end

        Tab.Activate = Activate
        TabButton.MouseButton1Click:Connect(Activate)

        -- ─────────────────────────────────────
        --  Element helpers
        -- ─────────────────────────────────────

        local function BaseFrame(height)
            local f = Create("Frame", {
                Parent           = TabContent,
                Size             = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel  = 0,
            })
            AddCorner(f, UDim.new(0, 4))
            return f
        end

        -- ── Button ────────────────────────────

        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local btnText  = btnConfig.Text     or "Button"
            local callback = btnConfig.Callback or function() end

            local frame = BaseFrame(36)

            local btn = Create("TextButton", {
                Parent             = frame,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = btnText,
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 14,
                AutoButtonColor    = false,
            })

            btn.MouseEnter:Connect(function()
                Tween(frame, {BackgroundColor3 = Color3.fromRGB(38, 38, 48)}, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                Tween(frame, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.15)
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(frame, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.1)
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(frame, {BackgroundColor3 = Color3.fromRGB(38, 38, 48)}, 0.1)
            end)
            btn.MouseButton1Click:Connect(callback)

            table.insert(Tab.Elements, frame)
            return {Frame = frame, SetText = function(t) btn.Text = t end}
        end

        -- ── Toggle ────────────────────────────

        function Tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local toggleText = toggleConfig.Text     or "Toggle"
            local toggled    = toggleConfig.Default  or false
            local callback   = toggleConfig.Callback or function() end

            local frame = BaseFrame(36)

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 0),
                Size               = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text               = toggleText,
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            local Track = Create("Frame", {
                Parent           = frame,
                Position         = UDim2.new(1, -46, 0.5, -10),
                Size             = UDim2.new(0, 36, 0, 20),
                BackgroundColor3 = toggled and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border,
                BorderSizePixel  = 0,
            })
            AddCorner(Track, UDim.new(1, 0))

            local Circle = Create("Frame", {
                Parent           = Track,
                Position         = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                Size             = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
            })
            AddCorner(Circle, UDim.new(1, 0))

            local function Refresh()
                Tween(Track,  {BackgroundColor3 = toggled and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border}, 0.2)
                Tween(Circle, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
            end

            Create("TextButton", {
                Parent             = frame,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = "",
            }).MouseButton1Click:Connect(function()
                toggled = not toggled
                Refresh()
                callback(toggled)
            end)

            table.insert(Tab.Elements, frame)
            return {
                Frame    = frame,
                GetValue = function() return toggled end,
                SetValue = function(val)         -- now properly syncs visuals
                    toggled = val
                    Refresh()
                    callback(toggled)
                end,
            }
        end

        -- ── Slider ────────────────────────────

        function Tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local sliderText = sliderConfig.Text      or "Slider"
            local min        = sliderConfig.Min       or 0
            local max        = sliderConfig.Max       or 100
            local default    = sliderConfig.Default   or min
            local increment  = sliderConfig.Increment or 1
            local callback   = sliderConfig.Callback  or function() end

            local frame = BaseFrame(50)

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 8),
                Size               = UDim2.new(1, -60, 0, 16),
                BackgroundTransparency = 1,
                Text               = sliderText,
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            local ValueLabel = Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(1, -52, 0, 8),
                Size               = UDim2.new(0, 42, 0, 16),
                BackgroundTransparency = 1,
                Text               = tostring(default),
                TextColor3         = Aurora.Config.Theme.Primary,
                Font               = Aurora.Config.FontBold,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Right,
            })

            local SliderBar = Create("Frame", {
                Parent           = frame,
                Position         = UDim2.new(0, 12, 0, 32),
                Size             = UDim2.new(1, -24, 0, 4),
                BackgroundColor3 = Aurora.Config.Theme.Border,
                BorderSizePixel  = 0,
            })
            AddCorner(SliderBar, UDim.new(1, 0))

            local Fill = Create("Frame", {
                Parent           = SliderBar,
                Size             = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Aurora.Config.Theme.Primary,
                BorderSizePixel  = 0,
            })
            AddCorner(Fill, UDim.new(1, 0))

            local Knob = Create("Frame", {
                Parent           = SliderBar,
                Position         = UDim2.new((default - min) / (max - min), -6, 0.5, -6),
                Size             = UDim2.new(0, 12, 0, 12),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
            })
            AddCorner(Knob, UDim.new(1, 0))

            local sliderDragging = false
            local currentValue   = default

            local function UpdateSlider(inputX)
                local pct   = math.clamp((inputX - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local raw   = min + (max - min) * pct
                local value = math.floor(raw / increment + 0.5) * increment
                value       = math.clamp(value, min, max)

                if value == currentValue then return end
                currentValue = value

                local fill = (value - min) / (max - min)
                Fill.Size      = UDim2.new(fill, 0, 1, 0)
                Knob.Position  = UDim2.new(fill, -6, 0.5, -6)
                ValueLabel.Text = tostring(value)
                callback(value)
            end

            -- Connections stored so they can be GC'd when window is closed
            local c1 = Knob.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliderDragging = true
                end
            end)
            local c2 = SliderBar.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliderDragging = true
                    UpdateSlider(inp.Position.X)
                end
            end)
            local c3 = UserInputService.InputChanged:Connect(function(inp)
                if sliderDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(inp.Position.X)
                end
            end)
            local c4 = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliderDragging = false
                end
            end)

            table.insert(connections, c3)
            table.insert(connections, c4)

            table.insert(Tab.Elements, frame)
            return {
                Frame    = frame,
                GetValue = function() return currentValue end,
                SetValue = function(val)
                    val = math.clamp(val, min, max)
                    currentValue = val
                    local fill = (val - min) / (max - min)
                    Fill.Size       = UDim2.new(fill, 0, 1, 0)
                    Knob.Position   = UDim2.new(fill, -6, 0.5, -6)
                    ValueLabel.Text = tostring(val)
                end,
            }
        end

        -- ── Dropdown ─────────────────────────

        function Tab:CreateDropdown(dropdownConfig)
            dropdownConfig  = dropdownConfig or {}
            local labelText = dropdownConfig.Text     or "Dropdown"
            local options   = dropdownConfig.Options  or {}
            local default   = dropdownConfig.Default  or "Select..."   -- local, fixes global leak
            local callback  = dropdownConfig.Callback or function() end

            local selected  = default
            local expanded  = false

            local DropdownFrame = Create("Frame", {
                Parent           = TabContent,
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            AddCorner(DropdownFrame, UDim.new(0, 4))

            local Label = Create("TextLabel", {
                Parent             = DropdownFrame,
                Position           = UDim2.new(0, 12, 0, 0),
                Size               = UDim2.new(1, -38, 0, 36),
                BackgroundTransparency = 1,
                Text               = labelText .. ": " .. selected,
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Left,
                TextTruncate       = Enum.TextTruncate.AtEnd,
            })

            local Arrow = Create("TextLabel", {
                Parent             = DropdownFrame,
                Position           = UDim2.new(1, -28, 0, 0),
                Size               = UDim2.new(0, 20, 0, 36),
                BackgroundTransparency = 1,
                Text               = "▼",
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.FontBold,
                TextSize           = 11,
            })

            local OptionsFrame = Create("Frame", {
                Parent           = DropdownFrame,
                Position         = UDim2.new(0, 0, 0, 36),
                Size             = UDim2.new(1, 0, 0, #options * 30),
                BackgroundColor3 = Aurora.Config.Theme.Surface,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })

            Create("UIListLayout", {
                Parent    = OptionsFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            for i, option in ipairs(options) do
                local optBtn = Create("TextButton", {
                    Parent           = OptionsFrame,
                    Size             = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Aurora.Config.Theme.Surface,
                    Text             = option,
                    TextColor3       = Aurora.Config.Theme.TextMuted,
                    Font             = Aurora.Config.FontMedium,
                    TextSize         = 13,
                    LayoutOrder      = i,
                    AutoButtonColor  = false,
                })

                optBtn.MouseEnter:Connect(function()
                    Tween(optBtn, {BackgroundColor3 = Aurora.Config.Theme.Background, TextColor3 = Aurora.Config.Theme.Text}, 0.15)
                end)
                optBtn.MouseLeave:Connect(function()
                    Tween(optBtn, {BackgroundColor3 = Aurora.Config.Theme.Surface, TextColor3 = Aurora.Config.Theme.TextMuted}, 0.15)
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected    = option
                    Label.Text  = labelText .. ": " .. option
                    callback(option)
                    expanded    = false
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow,         {Rotation = 0}, 0.2)
                end)
            end

            Create("TextButton", {
                Parent             = DropdownFrame,
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text               = "",
            }).MouseButton1Click:Connect(function()
                expanded = not expanded
                local targetH = expanded and 36 + #options * 30 or 36
                Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
                Tween(Arrow,         {Rotation = expanded and 180 or 0}, 0.2)
            end)

            table.insert(Tab.Elements, DropdownFrame)
            return {
                Frame    = DropdownFrame,
                GetValue = function() return selected end,
                SetValue = function(val)
                    if table.find(options, val) then
                        selected   = val
                        Label.Text = labelText .. ": " .. val
                    end
                end,
            }
        end

        -- ── TextBox (input field) ─────────────  NEW

        function Tab:CreateInput(inputConfig)
            inputConfig    = inputConfig or {}
            local labelTxt = inputConfig.Text        or "Input"
            local placeholder = inputConfig.Placeholder or "Enter text..."
            local callback = inputConfig.Callback    or function() end

            local frame = BaseFrame(54)

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 6),
                Size               = UDim2.new(1, -24, 0, 16),
                BackgroundTransparency = 1,
                Text               = labelTxt,
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 12,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            local InputBox = Create("TextBox", {
                Parent             = frame,
                Position           = UDim2.new(0, 10, 0, 26),
                Size               = UDim2.new(1, -20, 0, 22),
                BackgroundColor3   = Aurora.Config.Theme.Surface,
                BorderSizePixel    = 0,
                Text               = "",
                PlaceholderText    = placeholder,
                PlaceholderColor3  = Aurora.Config.Theme.TextMuted,
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.Font,
                TextSize           = 13,
                ClearTextOnFocus   = false,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })
            AddCorner(InputBox, UDim.new(0, 4))
            Create("UIPadding", {
                Parent      = InputBox,
                PaddingLeft = UDim.new(0, 8),
            })

            -- Highlight border on focus
            local Border = Create("Frame", {
                Parent           = InputBox,
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
            })
            AddCorner(Border, UDim.new(0, 4))

            InputBox.Focused:Connect(function()
                Tween(InputBox, {BackgroundColor3 = Color3.fromRGB(32, 32, 40)}, 0.15)
            end)
            InputBox.FocusLost:Connect(function(enterPressed)
                Tween(InputBox, {BackgroundColor3 = Aurora.Config.Theme.Surface}, 0.15)
                if enterPressed then callback(InputBox.Text) end
            end)

            table.insert(Tab.Elements, frame)
            return {
                Frame    = frame,
                GetValue = function() return InputBox.Text end,
                SetValue = function(val) InputBox.Text = val end,
            }
        end

        -- ── Label ─────────────────────────────

        function Tab:CreateLabel(text)
            local frame = Create("Frame", {
                Parent             = TabContent,
                Size               = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
            })

            local lbl = Create("TextLabel", {
                Parent             = frame,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = text or "Label",
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.Font,
                TextSize           = 12,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            table.insert(Tab.Elements, frame)
            return {Frame = frame, SetText = function(t) lbl.Text = t end}
        end

        -- ── Section ───────────────────────────

        function Tab:CreateSection(sectionText)
            local frame = Create("Frame", {
                Parent             = TabContent,
                Size               = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
            })

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 0, 0, 0),
                Size               = UDim2.new(1, 0, 1, -1),
                BackgroundTransparency = 1,
                Text               = sectionText or "Section",
                TextColor3         = Aurora.Config.Theme.Primary,
                Font               = Aurora.Config.FontBold,
                TextSize           = 12,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            Create("Frame", {
                Parent           = frame,
                Position         = UDim2.new(0, 0, 1, -1),
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Aurora.Config.Theme.Border,
                BorderSizePixel  = 0,
            })

            table.insert(Tab.Elements, frame)
            return frame
        end

        -- Auto-select first tab
        if #Window.Tabs == 0 then
            TabButton.BackgroundColor3 = Aurora.Config.Theme.Primary
            TabLabel.TextColor3        = Aurora.Config.Theme.Text
            TabContent.Visible         = true
            Window.ActiveTab           = Tab
        end

        table.insert(Window.Tabs, Tab)
        return Tab
    end

    -- Draggable — disconnect stored for cleanup
    local dragDisconnect = MakeDraggable(MainFrame, TitleBar)

    -- Intro animation
    MainFrame.Size     = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(
        position.X.Scale, position.X.Offset + size.X.Offset / 2,
        position.Y.Scale, position.Y.Offset + size.Y.Offset / 2
    )
    Tween(MainFrame, {Size = size, Position = position}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return Window
end

-- ─────────────────────────────────────────────
--  Notification System  (queued, non-overlapping)
-- ─────────────────────────────────────────────

local _notifGui -- single ScreenGui for all notifications

function Aurora:Notify(notifyConfig)
    notifyConfig = notifyConfig or {}
    local title      = notifyConfig.Title    or "Notification"
    local message    = notifyConfig.Message  or ""
    local notifType  = notifyConfig.Type     or "Info"
    local duration   = notifyConfig.Duration or 3

    local colorMap = {
        Info    = Aurora.Config.Theme.Primary,
        Success = Aurora.Config.Theme.Success,
        Warning = Aurora.Config.Theme.Warning,
        Error   = Aurora.Config.Theme.Error,
    }
    local color = colorMap[notifType] or colorMap.Info

    -- Shared container
    if not _notifGui or not _notifGui.Parent then
        _notifGui = Create("ScreenGui", {
            Name         = "AuroraNotifications",
            Parent       = LocalPlayer:WaitForChild("PlayerGui"),
            ResetOnSpawn = false,
        })
    end

    local slotIndex = #notifQueue + 1
    local posY      = -(slotIndex * (NOTIF_HEIGHT + NOTIF_GAP))

    local NotifFrame = Create("Frame", {
        Name             = "Notification",
        Parent           = _notifGui,
        Position         = UDim2.new(1, 20, 1, posY),   -- starts off-screen right
        Size             = UDim2.new(0, 280, 0, NOTIF_HEIGHT),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
    })
    AddCorner(NotifFrame)
    AddShadow(NotifFrame, 0.8)

    -- Accent bar
    local AccentBar = Create("Frame", {
        Parent           = NotifFrame,
        Size             = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
    })
    AddCorner(AccentBar, UDim.new(0, 4))
    -- Patch right side of rounded corner so it flush-fills
    Create("Frame", {
        Parent           = AccentBar,
        Position         = UDim2.new(0.5, 0, 0, 0),
        Size             = UDim2.new(0.5, 0, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
    })

    Create("TextLabel", {
        Parent             = NotifFrame,
        Position           = UDim2.new(0, 16, 0, 10),
        Size               = UDim2.new(1, -32, 0, 20),
        BackgroundTransparency = 1,
        Text               = title,
        TextColor3         = Aurora.Config.Theme.Text,
        Font               = Aurora.Config.FontBold,
        TextSize           = 14,
        TextXAlignment     = Enum.TextXAlignment.Left,
    })

    Create("TextLabel", {
        Parent             = NotifFrame,
        Position           = UDim2.new(0, 16, 0, 32),
        Size               = UDim2.new(1, -32, 0, 36),
        BackgroundTransparency = 1,
        Text               = message,
        TextColor3         = Aurora.Config.Theme.TextMuted,
        Font               = Aurora.Config.Font,
        TextSize           = 13,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextWrapped        = true,
    })

    -- Progress bar
    local Progress = Create("Frame", {
        Parent           = NotifFrame,
        Position         = UDim2.new(0, 0, 1, -2),
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
    })

    -- Register in queue
    local entry = {frame = NotifFrame}
    table.insert(notifQueue, entry)

    -- Slide in
    Tween(NotifFrame, {Position = UDim2.new(1, NOTIF_X, 1, posY)}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    Tween(Progress,   {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        -- Slide out
        Tween(NotifFrame, {Position = UDim2.new(1, 20, 1, posY)}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.35)
        NotifFrame:Destroy()

        -- Remove from queue and restack remaining
        for i, e in ipairs(notifQueue) do
            if e == entry then table.remove(notifQueue, i) break end
        end
        _repositionNotifs()
    end)
end

-- ─────────────────────────────────────────────
--  Theme API
-- ─────────────────────────────────────────────

function Aurora:SetTheme(newTheme)
    for k, v in pairs(newTheme) do
        if Aurora.Config.Theme[k] ~= nil then
            Aurora.Config.Theme[k] = v
        end
    end
end

return Aurora
