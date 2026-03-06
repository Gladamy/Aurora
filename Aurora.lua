--// Aurora UI Library
--// A minimalistic, beautiful UI library for Roblox
--// Version: 3.0.0

local Aurora = {}
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ─────────────────────────────────────────────
--  Configuration
-- ─────────────────────────────────────────────

Aurora.Config = {
    Theme = {
        Primary    = Color3.fromRGB(88,  101, 242),
        Secondary  = Color3.fromRGB(30,  30,  35),
        Background = Color3.fromRGB(18,  18,  22),
        Surface    = Color3.fromRGB(25,  25,  30),
        Text       = Color3.fromRGB(245, 245, 250),
        TextMuted  = Color3.fromRGB(150, 150, 160),
        Success    = Color3.fromRGB(46,  204, 113),
        Warning    = Color3.fromRGB(241, 196, 15),
        Error      = Color3.fromRGB(231, 76,  60),
        Border     = Color3.fromRGB(55,  55,  68),   -- brighter: was 40,40,50
        Glow       = Color3.fromRGB(88,  101, 242),
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
--  Signal — lightweight pub/sub event system
-- ─────────────────────────────────────────────

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({_handlers = {}}, Signal)
end

function Signal:Connect(fn)
    local id = #self._handlers + 1
    self._handlers[id] = fn
    return {
        Disconnect = function()
            self._handlers[id] = nil
        end
    }
end

function Signal:Fire(...)
    for _, fn in pairs(self._handlers) do
        pcall(fn, ...)
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

-- local Tween — no longer pollutes global environment
local function Tween(inst, props, duration, easingStyle, easingDir)
    local info = TweenInfo.new(
        duration    or Aurora.Config.Animation.Duration,
        easingStyle or Aurora.Config.Animation.Easing,
        easingDir   or Aurora.Config.Animation.Direction
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function AddCorner(parent, radius)
    return Create("UICorner", {
        CornerRadius = radius or Aurora.Config.CornerRadius,
        Parent       = parent,
    })
end

local function AddShadow(parent, intensity)
    return Create("ImageLabel", {
        Name                  = "Shadow",
        Parent                = parent,
        AnchorPoint           = Vector2.new(0.5, 0.5),
        Position              = UDim2.new(0.5, 0, 0.5, 4),
        Size                  = UDim2.new(1, 24, 1, 24),
        BackgroundTransparency = 1,
        Image                 = "rbxassetid://6014261993",
        ImageColor3           = Color3.new(0, 0, 0),
        ImageTransparency     = Aurora.Config.ShadowTransparency * (intensity or 1),
        ScaleType             = Enum.ScaleType.Slice,
        SliceCenter           = Rect.new(49, 49, 450, 450),
        ZIndex                = parent.ZIndex - 1,
    })
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    local conns = {}

    conns[1] = handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.Position
        end
    end)

    conns[2] = UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    conns[3] = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return function()
        for _, c in ipairs(conns) do c:Disconnect() end
    end
end

-- ─────────────────────────────────────────────
--  Notification queue
-- ─────────────────────────────────────────────

local notifQueue   = {}
local NOTIF_HEIGHT = 80
local NOTIF_GAP    = 8
local NOTIF_X      = -300

local function RepositionNotifs()
    for i, data in ipairs(notifQueue) do
        local targetY = -(i * (NOTIF_HEIGHT + NOTIF_GAP))
        Tween(data.frame, {Position = UDim2.new(1, NOTIF_X, 1, targetY)}, 0.25)
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

    local windowConnections = {}

    local ScreenGui = Create("ScreenGui", {
        Name           = "AuroraUI",
        Parent         = LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

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

    --// Title bar
    local TitleBar = Create("Frame", {
        Name             = "TitleBar",
        Parent           = MainFrame,
        Size             = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
    })
    AddCorner(TitleBar)
    Create("Frame", {  -- patch bottom corners
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

    --// Control buttons (✕ / —)
    local function MakeControlBtn(xOffset, icon, iconColor)
        local btn = Create("TextButton", {
            Parent           = TitleBar,
            Position         = UDim2.new(1, xOffset, 0.5, -10),
            Size             = UDim2.new(0, 20, 0, 20),
            BackgroundColor3 = Aurora.Config.Theme.Surface,
            Text             = icon,
            TextColor3       = iconColor,
            Font             = Aurora.Config.FontBold,
            TextSize         = 13,
            AutoButtonColor  = false,
            BorderSizePixel  = 0,
        })
        AddCorner(btn, UDim.new(0, 4))
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = iconColor, TextColor3 = Aurora.Config.Theme.Text}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = Aurora.Config.Theme.Surface, TextColor3 = iconColor}, 0.15)
        end)
        return btn
    end

    local CloseBtn    = MakeControlBtn(-28, "✕", Aurora.Config.Theme.Error)
    local MinimizeBtn = MakeControlBtn(-54, "—", Aurora.Config.Theme.TextMuted)

    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(MainFrame, {Size = minimized and UDim2.new(0, size.X.Offset, 0, 40) or size}, 0.3)
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        local cx = MainFrame.Position.X.Offset + size.X.Offset / 2
        local cy = MainFrame.Position.Y.Offset + size.Y.Offset / 2
        Tween(MainFrame, {
            Size     = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(MainFrame.Position.X.Scale, cx, MainFrame.Position.Y.Scale, cy),
        }, 0.3)
        task.wait(0.3)
        for _, c in ipairs(windowConnections) do c:Disconnect() end
        ScreenGui:Destroy()
    end)

    --// Tab sidebar
    local TabContainer = Create("Frame", {
        Name             = "TabContainer",
        Parent           = MainFrame,
        Position         = UDim2.new(0, 8, 0, 48),
        Size             = UDim2.new(0, 130, 1, -56),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
    })
    AddCorner(TabContainer)
    Create("UIListLayout", {Parent = TabContainer, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
    Create("UIPadding", {
        Parent        = TabContainer,
        PaddingTop    = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 6), PaddingRight  = UDim.new(0, 6),
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
        -- Events
        OnTabChanged     = Signal.new(),  -- fires (newTab, oldTab)
    }

    function Window:SelectTab(index)
        local tab = self.Tabs[index]
        if tab and tab.Activate then tab.Activate() end
    end

    function Window:Destroy()
        for _, c in ipairs(windowConnections) do c:Disconnect() end
        ScreenGui:Destroy()
    end

    -- ─────────────────────────────────────────
    --  Tab creation
    -- ─────────────────────────────────────────

    function Window:CreateTab(tabConfig)
        tabConfig     = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or ""

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

        local TabContent = Create("ScrollingFrame", {
            Name                 = tabName .. "Content",
            Parent               = ContentContainer,
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            ScrollBarThickness   = 3,
            ScrollBarImageColor3 = Aurora.Config.Theme.Border,
            Visible              = false,
            AutomaticCanvasSize  = Enum.AutomaticSize.Y,
            CanvasSize           = UDim2.new(0, 0, 0, 0),
        })
        Create("UIListLayout", {Parent = TabContent, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
        Create("UIPadding", {
            Parent        = TabContent,
            PaddingTop    = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft   = UDim.new(0, 10), PaddingRight  = UDim.new(0, 12),
        })

        local Tab = {
            Button   = TabButton,
            Content  = TabContent,
            Elements = {},
            Activate = nil,
            -- Events
            OnElementAdded = Signal.new(),
        }

        local function Activate()
            if Window.ActiveTab == Tab then return end
            local oldTab = Window.ActiveTab

            if oldTab then
                Tween(oldTab.Button,       {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.2)
                Tween(oldTab.Button.Label, {TextColor3 = Aurora.Config.Theme.TextMuted}, 0.2)
                if oldTab.Button:FindFirstChild("Icon") then
                    Tween(oldTab.Button.Icon, {ImageColor3 = Aurora.Config.Theme.TextMuted}, 0.2)
                end
                oldTab.Content.Visible = false
            end

            Window.ActiveTab = Tab
            Tween(TabButton, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.2)
            Tween(TabLabel,  {TextColor3 = Aurora.Config.Theme.Text}, 0.2)
            if TabButton:FindFirstChild("Icon") then
                Tween(TabButton.Icon, {ImageColor3 = Aurora.Config.Theme.Text}, 0.2)
            end
            TabContent.Visible = true
            TabContent.CanvasPosition = Vector2.new(0, 0)

            Window.OnTabChanged:Fire(Tab, oldTab)
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

        local function RegisterElement(element, frame)
            table.insert(Tab.Elements, element)
            Tab.OnElementAdded:Fire(element)
            -- Expose Destroy on every element
            element.Destroy = function()
                frame:Destroy()
                for i, e in ipairs(Tab.Elements) do
                    if e == element then table.remove(Tab.Elements, i) break end
                end
            end
            return element
        end

        -- ── Button ────────────────────────────

        function Tab:CreateButton(cfg)
            cfg = cfg or {}
            local frame = BaseFrame(36)
            local btn = Create("TextButton", {
                Parent             = frame,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Button",
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 14,
                AutoButtonColor    = false,
            })
            btn.MouseEnter:Connect(function()
                Tween(frame, {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                Tween(frame, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.15)
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(frame, {BackgroundColor3 = Aurora.Config.Theme.Primary}, 0.1)
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(frame, {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}, 0.1)
            end)
            btn.MouseButton1Click:Connect(cfg.Callback or function() end)

            return RegisterElement({
                Frame   = frame,
                SetText = function(t) btn.Text = t end,
            }, frame)
        end

        -- ── Toggle ────────────────────────────

        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local toggled = cfg.Default or false
            local OnChanged = Signal.new()
            local frame = BaseFrame(36)

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 0),
                Size               = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Toggle",
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

            local function Refresh(silent)
                Tween(Track,  {BackgroundColor3 = toggled and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border}, 0.2)
                Tween(Circle, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
                if not silent then
                    if cfg.Callback then cfg.Callback(toggled) end
                    OnChanged:Fire(toggled)
                end
            end

            Create("TextButton", {
                Parent             = frame,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = "",
            }).MouseButton1Click:Connect(function()
                toggled = not toggled
                Refresh(false)
            end)

            return RegisterElement({
                Frame     = frame,
                OnChanged = OnChanged,
                GetValue  = function() return toggled end,
                SetValue  = function(val)
                    if toggled ~= val then
                        toggled = val
                        Refresh(false)
                    end
                end,
            }, frame)
        end

        -- ── Slider ────────────────────────────

        function Tab:CreateSlider(cfg)
            cfg = cfg or {}
            local min       = cfg.Min       or 0
            local max       = cfg.Max       or 100
            local increment = cfg.Increment or 1
            local current   = math.clamp(cfg.Default or min, min, max)
            local OnChanged = Signal.new()
            local frame = BaseFrame(50)

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 8),
                Size               = UDim2.new(1, -60, 0, 16),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Slider",
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
                Text               = tostring(current),
                TextColor3         = Aurora.Config.Theme.Primary,
                Font               = Aurora.Config.FontBold,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Right,
            })

            local Bar = Create("Frame", {
                Parent           = frame,
                Position         = UDim2.new(0, 12, 0, 32),
                Size             = UDim2.new(1, -24, 0, 4),
                BackgroundColor3 = Aurora.Config.Theme.Border,
                BorderSizePixel  = 0,
            })
            AddCorner(Bar, UDim.new(1, 0))

            local Fill = Create("Frame", {
                Parent           = Bar,
                Size             = UDim2.new((current - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Aurora.Config.Theme.Primary,
                BorderSizePixel  = 0,
            })
            AddCorner(Fill, UDim.new(1, 0))

            local Knob = Create("Frame", {
                Parent           = Bar,
                Position         = UDim2.new((current - min) / (max - min), -6, 0.5, -6),
                Size             = UDim2.new(0, 12, 0, 12),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
            })
            AddCorner(Knob, UDim.new(1, 0))

            local dragging = false

            local function Apply(inputX)
                local pct   = math.clamp((inputX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                local raw   = min + (max - min) * pct
                local value = math.clamp(math.floor(raw / increment + 0.5) * increment, min, max)
                if value == current then return end
                current = value
                local f = (value - min) / (max - min)
                Fill.Size      = UDim2.new(f, 0, 1, 0)
                Knob.Position  = UDim2.new(f, -6, 0.5, -6)
                ValueLabel.Text = tostring(value)
                if cfg.Callback then cfg.Callback(value) end
                OnChanged:Fire(value)
            end

            local c1 = Knob.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
            end)
            local c2 = Bar.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    Apply(inp.Position.X)
                end
            end)
            local c3 = UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    Apply(inp.Position.X)
                end
            end)
            local c4 = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            table.insert(windowConnections, c3)
            table.insert(windowConnections, c4)

            return RegisterElement({
                Frame     = frame,
                OnChanged = OnChanged,
                GetValue  = function() return current end,
                SetValue  = function(val)
                    val = math.clamp(val, min, max)
                    current = val
                    local f = (val - min) / (max - min)
                    Fill.Size       = UDim2.new(f, 0, 1, 0)
                    Knob.Position   = UDim2.new(f, -6, 0.5, -6)
                    ValueLabel.Text = tostring(val)
                end,
            }, frame)
        end

        -- ── Dropdown ─────────────────────────

        function Tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local options  = cfg.Options or {}
            local selected = cfg.Default or "Select..."
            local expanded = false
            local OnChanged = Signal.new()

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
                Text               = (cfg.Text or "Dropdown") .. ": " .. selected,
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
            Create("UIListLayout", {Parent = OptionsFrame, SortOrder = Enum.SortOrder.LayoutOrder})

            for i, option in ipairs(options) do
                local ob = Create("TextButton", {
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
                ob.MouseEnter:Connect(function()
                    Tween(ob, {BackgroundColor3 = Aurora.Config.Theme.Background, TextColor3 = Aurora.Config.Theme.Text}, 0.15)
                end)
                ob.MouseLeave:Connect(function()
                    Tween(ob, {BackgroundColor3 = Aurora.Config.Theme.Surface, TextColor3 = Aurora.Config.Theme.TextMuted}, 0.15)
                end)
                ob.MouseButton1Click:Connect(function()
                    selected   = option
                    Label.Text = (cfg.Text or "Dropdown") .. ": " .. option
                    if cfg.Callback then cfg.Callback(option) end
                    OnChanged:Fire(option)
                    expanded = false
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end)
            end

            Create("TextButton", {
                Parent             = DropdownFrame,
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text               = "",
            }).MouseButton1Click:Connect(function()
                expanded = not expanded
                Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, expanded and 36 + #options * 30 or 36)}, 0.2)
                Tween(Arrow, {Rotation = expanded and 180 or 0}, 0.2)
            end)

            return RegisterElement({
                Frame     = DropdownFrame,
                OnChanged = OnChanged,
                GetValue  = function() return selected end,
                SetValue  = function(val)
                    if table.find(options, val) then
                        selected   = val
                        Label.Text = (cfg.Text or "Dropdown") .. ": " .. val
                    end
                end,
            }, DropdownFrame)
        end

        -- ── Input ─────────────────────────────

        function Tab:CreateInput(cfg)
            cfg = cfg or {}
            local OnChanged = Signal.new()
            local frame = BaseFrame(54)

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 6),
                Size               = UDim2.new(1, -24, 0, 16),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Input",
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
                PlaceholderText    = cfg.Placeholder or "Type here...",
                PlaceholderColor3  = Aurora.Config.Theme.TextMuted,
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.Font,
                TextSize           = 13,
                ClearTextOnFocus   = false,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })
            AddCorner(InputBox, UDim.new(0, 4))
            Create("UIPadding", {Parent = InputBox, PaddingLeft = UDim.new(0, 8)})

            InputBox.Focused:Connect(function()
                Tween(InputBox, {BackgroundColor3 = Color3.fromRGB(32, 32, 42)}, 0.15)
            end)
            InputBox.FocusLost:Connect(function(enter)
                Tween(InputBox, {BackgroundColor3 = Aurora.Config.Theme.Surface}, 0.15)
                if enter then
                    if cfg.Callback then cfg.Callback(InputBox.Text) end
                    OnChanged:Fire(InputBox.Text)
                end
            end)

            return RegisterElement({
                Frame     = frame,
                OnChanged = OnChanged,
                GetValue  = function() return InputBox.Text end,
                SetValue  = function(val) InputBox.Text = val end,
            }, frame)
        end

        -- ── Keybind ───────────────────────────  NEW

        function Tab:CreateKeybind(cfg)
            cfg = cfg or {}
            local current   = cfg.Default or Enum.KeyCode.Unknown
            local listening = false
            local OnChanged = Signal.new()
            local frame = BaseFrame(36)

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 0),
                Size               = UDim2.new(1, -110, 1, 0),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Keybind",
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            local KeyBtn = Create("TextButton", {
                Parent           = frame,
                Position         = UDim2.new(1, -98, 0.5, -12),
                Size             = UDim2.new(0, 88, 0, 24),
                BackgroundColor3 = Aurora.Config.Theme.Surface,
                Text             = current == Enum.KeyCode.Unknown and "None" or current.Name,
                TextColor3       = Aurora.Config.Theme.Primary,
                Font             = Aurora.Config.FontBold,
                TextSize         = 12,
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
            })
            AddCorner(KeyBtn, UDim.new(0, 4))

            local keyCon  -- connection for capturing the next key

            local function StopListening()
                listening = false
                KeyBtn.BackgroundColor3 = Aurora.Config.Theme.Surface
                KeyBtn.TextColor3       = Aurora.Config.Theme.Primary
                if keyCon then keyCon:Disconnect() keyCon = nil end
            end

            local function StartListening()
                listening = true
                KeyBtn.Text            = "..."
                KeyBtn.BackgroundColor3 = Aurora.Config.Theme.Primary
                KeyBtn.TextColor3       = Aurora.Config.Theme.Text

                keyCon = UserInputService.InputBegan:Connect(function(inp, processed)
                    if processed then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        current       = inp.KeyCode
                        KeyBtn.Text   = inp.KeyCode.Name
                        if cfg.Callback then cfg.Callback(current) end
                        OnChanged:Fire(current)
                        StopListening()
                    end
                end)
            end

            KeyBtn.MouseButton1Click:Connect(function()
                if listening then StopListening() else StartListening() end
            end)

            -- Cancel on click elsewhere
            local cancelCon = UserInputService.InputBegan:Connect(function(inp)
                if listening and inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    StopListening()
                    KeyBtn.Text = current == Enum.KeyCode.Unknown and "None" or current.Name
                end
            end)
            table.insert(windowConnections, cancelCon)

            return RegisterElement({
                Frame     = frame,
                OnChanged = OnChanged,
                GetValue  = function() return current end,
                SetValue  = function(key)
                    current   = key
                    KeyBtn.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
                end,
            }, frame)
        end

        -- ── ColorPicker ───────────────────────  NEW

        function Tab:CreateColorPicker(cfg)
            cfg = cfg or {}
            local color     = cfg.Default or Color3.fromRGB(255, 255, 255)
            local expanded  = false
            local OnChanged = Signal.new()

            -- Convert Color3 → H,S,V
            local function toHSV(c)
                return Color3.toHSV(c)
            end

            local h, s, v = toHSV(color)

            local PICKER_H = 140  -- expanded panel height

            local PickerFrame = Create("Frame", {
                Parent           = TabContent,
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            AddCorner(PickerFrame, UDim.new(0, 4))

            -- Header row
            Create("TextLabel", {
                Parent             = PickerFrame,
                Position           = UDim2.new(0, 12, 0, 0),
                Size               = UDim2.new(1, -56, 0, 36),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Color",
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            local Preview = Create("Frame", {
                Parent           = PickerFrame,
                Position         = UDim2.new(1, -42, 0.5, -10),
                Size             = UDim2.new(0, 28, 0, 20),
                BackgroundColor3 = color,
                BorderSizePixel  = 0,
            })
            AddCorner(Preview, UDim.new(0, 4))

            local ToggleBtn = Create("TextButton", {
                Parent             = PickerFrame,
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text               = "",
            })

            -- ── Expanded panel ────────────────

            local Panel = Create("Frame", {
                Parent           = PickerFrame,
                Position         = UDim2.new(0, 8, 0, 42),
                Size             = UDim2.new(1, -16, 0, PICKER_H - 48),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
            })

            -- Saturation / Value 2D pad
            local SVPad = Create("ImageButton", {
                Parent           = Panel,
                Position         = UDim2.new(0, 0, 0, 0),
                Size             = UDim2.new(1, -28, 0, 68),
                Image            = "rbxassetid://698052001", -- SV gradient
                ImageColor3      = Color3.fromHSV(h, 1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
            })
            AddCorner(SVPad, UDim.new(0, 4))

            local SVCursor = Create("Frame", {
                Parent           = SVPad,
                Size             = UDim2.new(0, 10, 0, 10),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(s, 0, 1 - v, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
            })
            AddCorner(SVCursor, UDim.new(1, 0))

            -- Hue bar (vertical, right side)
            local HueBar = Create("ImageButton", {
                Parent           = Panel,
                Position         = UDim2.new(1, -22, 0, 0),
                Size             = UDim2.new(0, 16, 0, 68),
                Image            = "rbxassetid://698053677", -- hue gradient
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
            })
            AddCorner(HueBar, UDim.new(0, 4))

            local HueCursor = Create("Frame", {
                Parent           = HueBar,
                Size             = UDim2.new(1, 0, 0, 4),
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = UDim2.new(0, 0, h, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
            })
            AddCorner(HueCursor, UDim.new(1, 0))

            -- Hex input
            local HexInput = Create("TextBox", {
                Parent           = Panel,
                Position         = UDim2.new(0, 0, 0, 74),
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Aurora.Config.Theme.Surface,
                BorderSizePixel  = 0,
                Text             = string.format("#%02X%02X%02X",
                    math.round(color.R * 255),
                    math.round(color.G * 255),
                    math.round(color.B * 255)),
                TextColor3       = Aurora.Config.Theme.Text,
                Font             = Aurora.Config.Font,
                TextSize         = 12,
                ClearTextOnFocus = false,
            })
            AddCorner(HexInput, UDim.new(0, 4))
            Create("UIPadding", {Parent = HexInput, PaddingLeft = UDim.new(0, 8)})

            local function Commit()
                color = Color3.fromHSV(h, s, v)
                Preview.BackgroundColor3 = color
                SVPad.ImageColor3        = Color3.fromHSV(h, 1, 1)
                SVCursor.Position        = UDim2.new(s, 0, 1 - v, 0)
                HueCursor.Position       = UDim2.new(0, 0, h, 0)
                HexInput.Text = string.format("#%02X%02X%02X",
                    math.round(color.R * 255),
                    math.round(color.G * 255),
                    math.round(color.B * 255))
                if cfg.Callback then cfg.Callback(color) end
                OnChanged:Fire(color)
            end

            -- SV pad drag
            local svDrag = false
            SVPad.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
            end)
            local c1 = UserInputService.InputChanged:Connect(function(inp)
                if svDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    s = math.clamp((inp.Position.X - SVPad.AbsolutePosition.X) / SVPad.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((inp.Position.Y - SVPad.AbsolutePosition.Y) / SVPad.AbsoluteSize.Y, 0, 1)
                    Commit()
                end
            end)
            local c2 = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
            end)
            table.insert(windowConnections, c1)
            table.insert(windowConnections, c2)

            -- Hue bar drag
            local hueDrag = false
            HueBar.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
            end)
            local c3 = UserInputService.InputChanged:Connect(function(inp)
                if hueDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    h = math.clamp((inp.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                    Commit()
                end
            end)
            local c4 = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
            end)
            table.insert(windowConnections, c3)
            table.insert(windowConnections, c4)

            -- Hex input
            HexInput.FocusLost:Connect(function(enter)
                if not enter then return end
                local hex = HexInput.Text:gsub("#", "")
                if #hex == 6 then
                    local r = tonumber(hex:sub(1,2), 16)
                    local g = tonumber(hex:sub(3,4), 16)
                    local b = tonumber(hex:sub(5,6), 16)
                    if r and g and b then
                        color = Color3.fromRGB(r, g, b)
                        h, s, v = toHSV(color)
                        Commit()
                    end
                end
            end)

            -- Toggle expand
            ToggleBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                Tween(PickerFrame, {Size = UDim2.new(1, 0, 0, expanded and PICKER_H or 36)}, 0.25)
            end)

            return RegisterElement({
                Frame     = PickerFrame,
                OnChanged = OnChanged,
                GetValue  = function() return color end,
                SetValue  = function(c)
                    color = c
                    h, s, v = toHSV(c)
                    Commit()
                end,
            }, PickerFrame)
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
            return RegisterElement({
                Frame   = frame,
                SetText = function(t) lbl.Text = t end,
            }, frame)
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
                Size               = UDim2.new(1, 0, 1, -1),
                BackgroundTransparency = 1,
                Text               = (sectionText or "Section"):upper(),
                TextColor3         = Aurora.Config.Theme.Primary,
                Font               = Aurora.Config.FontBold,
                TextSize           = 11,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })
            -- Higher contrast divider
            Create("Frame", {
                Parent           = frame,
                Position         = UDim2.new(0, 0, 1, -1),
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Aurora.Config.Theme.Border,
                BorderSizePixel  = 0,
            })
            return RegisterElement({Frame = frame}, frame)
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

    local _dragDisconnect = MakeDraggable(MainFrame, TitleBar)

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
--  Notification system
-- ─────────────────────────────────────────────

local _notifGui

function Aurora:Notify(cfg)
    cfg = cfg or {}
    local colorMap = {
        Info    = Aurora.Config.Theme.Primary,
        Success = Aurora.Config.Theme.Success,
        Warning = Aurora.Config.Theme.Warning,
        Error   = Aurora.Config.Theme.Error,
    }
    local color    = colorMap[cfg.Type or "Info"] or colorMap.Info
    local duration = cfg.Duration or 3

    if not _notifGui or not _notifGui.Parent then
        _notifGui = Create("ScreenGui", {
            Name         = "AuroraNotifications",
            Parent       = LocalPlayer:WaitForChild("PlayerGui"),
            ResetOnSpawn = false,
        })
    end

    local slotIndex = #notifQueue + 1
    local posY      = -(slotIndex * (NOTIF_HEIGHT + NOTIF_GAP))

    local frame = Create("Frame", {
        Parent           = _notifGui,
        Position         = UDim2.new(1, 20, 1, posY),
        Size             = UDim2.new(0, 280, 0, NOTIF_HEIGHT),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
    })
    AddCorner(frame)
    AddShadow(frame, 0.8)

    local AccentBar = Create("Frame", {
        Parent = frame, Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = color, BorderSizePixel = 0,
    })
    AddCorner(AccentBar, UDim.new(0, 4))
    Create("Frame", {
        Parent = AccentBar, Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundColor3 = color, BorderSizePixel = 0,
    })

    Create("TextLabel", {
        Parent = frame, Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(1, -32, 0, 20), BackgroundTransparency = 1,
        Text = cfg.Title or "Notification", TextColor3 = Aurora.Config.Theme.Text,
        Font = Aurora.Config.FontBold, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    Create("TextLabel", {
        Parent = frame, Position = UDim2.new(0, 16, 0, 32),
        Size = UDim2.new(1, -32, 0, 36), BackgroundTransparency = 1,
        Text = cfg.Message or "", TextColor3 = Aurora.Config.Theme.TextMuted,
        Font = Aurora.Config.Font, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    })

    local Progress = Create("Frame", {
        Parent = frame, Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = color, BorderSizePixel = 0,
    })

    local entry = {frame = frame}
    table.insert(notifQueue, entry)

    Tween(frame,    {Position = UDim2.new(1, NOTIF_X, 1, posY)}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    Tween(Progress, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(frame, {Position = UDim2.new(1, 20, 1, posY)}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.35)
        frame:Destroy()
        for i, e in ipairs(notifQueue) do
            if e == entry then table.remove(notifQueue, i) break end
        end
        RepositionNotifs()
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
