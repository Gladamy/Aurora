--// Aurora UI Library
--// A minimalistic, beautiful UI library for Roblox
--// Version: 6.5.0

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
    return setmetatable({_handlers = {}, _counter = 0}, Signal)
end

function Signal:Connect(fn)
    self._counter = self._counter + 1
    local id = self._counter
    self._handlers[id] = fn
    return {
        Disconnect = function()
            self._handlers[id] = nil
        end
    }
end

function Signal:Once(fn)
    -- Fires fn exactly once then auto-disconnects.
    -- Returns a handle with .Disconnect() in case you want to cancel before it fires.
    local handle
    handle = self:Connect(function(...)
        handle.Disconnect()
        fn(...)
    end)
    return handle
end

function Signal:Fire(...)
    for _, fn in pairs(self._handlers) do
        local ok, err = pcall(fn, ...)
        if not ok then
            warn("[Aurora Signal] Callback error: " .. tostring(err))
        end
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

    return conns   -- array of RBXScriptConnections, same type as everything else
end

-- ─────────────────────────────────────────────
--  Dropdown collapse registry
--  Weak keys so frames can be GC'd freely.
--  CreateDropdown / CreateSearchDropdown register
--  a collapse function here; SetEnabled calls it.
-- ─────────────────────────────────────────────

local _dropdownCollapse = setmetatable({}, { __mode = "k" })

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
        -- Use AbsolutePosition so the collapse-to-centre is correct
        -- regardless of where the window has been dragged
        local absPos  = MainFrame.AbsolutePosition
        local absSize = MainFrame.AbsoluteSize
        local cx = absPos.X + absSize.X / 2
        local cy = absPos.Y + absSize.Y / 2
        Tween(MainFrame, {
            Size     = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, cx, 0, cy),
        }, 0.3)
        task.wait(0.3)
        for _, c in ipairs(windowConnections) do
            if c and c.Disconnect then c:Disconnect() end
        end
        ScreenGui:Destroy()
    end)

    --// Tab sidebar — auto-sizing width
    local SIDEBAR_MIN = 110
    local SIDEBAR_MAX = 200
    local SIDEBAR_GAP = 8   -- gap between sidebar and content

    local TabContainer = Create("Frame", {
        Name             = "TabContainer",
        Parent           = MainFrame,
        Position         = UDim2.new(0, 8, 0, 48),
        Size             = UDim2.new(0, SIDEBAR_MIN, 1, -56),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.X,
    })
    AddCorner(TabContainer)
    Create("UIListLayout", {Parent = TabContainer, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
    Create("UIPadding", {
        Parent        = TabContainer,
        PaddingTop    = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 6), PaddingRight  = UDim.new(0, 6),
    })
    Create("UISizeConstraint", {
        Parent  = TabContainer,
        MinSize = Vector2.new(SIDEBAR_MIN, 0),
        MaxSize = Vector2.new(SIDEBAR_MAX, math.huge),
    })

    --// Content area
    local ContentContainer = Create("Frame", {
        Name             = "ContentContainer",
        Parent           = MainFrame,
        Position         = UDim2.new(0, 8 + SIDEBAR_MIN + SIDEBAR_GAP, 0, 48),
        Size             = UDim2.new(1, -(8 + SIDEBAR_MIN + SIDEBAR_GAP + 8), 1, -56),
        BackgroundColor3 = Aurora.Config.Theme.Surface,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })
    AddCorner(ContentContainer)

    -- Reflow ContentContainer whenever the sidebar width changes
    local reflowConn = TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local w = math.clamp(TabContainer.AbsoluteSize.X, SIDEBAR_MIN, SIDEBAR_MAX)
        ContentContainer.Position = UDim2.new(0, 8 + w + SIDEBAR_GAP, 0, 48)
        ContentContainer.Size     = UDim2.new(1, -(8 + w + SIDEBAR_GAP + 8), 1, -56)
    end)
    table.insert(windowConnections, reflowConn)

    -- Subtle bottom fade so sparse tabs don't end abruptly
    local FadeGradient = Create("Frame", {
        Parent             = ContentContainer,
        Position           = UDim2.new(0, 0, 1, -28),
        Size               = UDim2.new(1, 0, 0, 28),
        BackgroundColor3   = Aurora.Config.Theme.Surface,
        BorderSizePixel    = 0,
        ZIndex             = 10,
    })
    Create("UIGradient", {
        Parent       = FadeGradient,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
    })

    --// Window object
    local Window = {
        ScreenGui        = ScreenGui,
        MainFrame        = MainFrame,
        TabContainer     = TabContainer,
        ContentContainer = ContentContainer,
        Tabs             = {},
        ActiveTab        = nil,
        _configElements  = {},
        _title           = title,
        -- Events
        OnTabChanged     = Signal.new(),  -- fires (newTab, oldTab)
    }

    function Window:SaveConfig(name)
        return Aurora.ConfigManager:Save(name, self)
    end

    function Window:LoadConfig(name)
        local ok, err = Aurora.ConfigManager:Load(name, self)
        if ok then
            Aurora.ConfigManager:SetLastConfig(self._title, name)
        end
        return ok, err
    end

    function Window:SelectTab(index)
        local tab = self.Tabs[index]
        if tab and tab.Activate then tab.Activate() end
    end

    function Window:Destroy()
        for _, c in ipairs(windowConnections) do
            if c and c.Disconnect then c:Disconnect() end
        end
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
            AutomaticSize    = Enum.AutomaticSize.X,
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
            Size               = UDim2.new(0, 0, 1, 0),   -- width driven by AutomaticSize
            AutomaticSize      = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text               = tabName,
            TextColor3         = Aurora.Config.Theme.TextMuted,
            Font               = Aurora.Config.FontMedium,
            TextSize           = 13,
            TextXAlignment     = Enum.TextXAlignment.Left,
        })
        -- Right padding so text doesn't hug the edge
        Create("UIPadding", {
            Parent       = TabLabel,
            PaddingRight = UDim.new(0, 10),
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
            Name           = tabName,
            Button         = TabButton,
            Content        = TabContent,
            Elements       = {},
            Activate       = nil,
            OnElementAdded = Signal.new(),
        }

        -- Empty state — visible until first element is added
        local EmptyState = Create("TextLabel", {
            Parent             = TabContent,
            Size               = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Text               = "No elements yet.",
            TextColor3         = Aurora.Config.Theme.Border,
            Font               = Aurora.Config.Font,
            TextSize           = 13,
            TextXAlignment     = Enum.TextXAlignment.Center,
            LayoutOrder        = 9999,
        })

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

        -- ownedConns: UIS connections that belong exclusively to this element.
        -- Added to windowConnections for Window:Destroy() cleanup, AND
        -- disconnected + pruned immediately when element.Destroy() is called.
        local function RegisterElement(element, frame, ownedConns, cfg)
            cfg = cfg or {}
            ownedConns = ownedConns or {}
            for _, c in ipairs(ownedConns) do
                table.insert(windowConnections, c)
            end

            if #Tab.Elements == 0 then
                EmptyState.Visible = false
            end
            table.insert(Tab.Elements, element)
            Tab.OnElementAdded:Fire(element)

            -- Register for config tracking
            if cfg.ConfigName and element.GetValue and element.SetValue then
                if not Window._configElements[tabName] then
                    Window._configElements[tabName] = {}
                end
                Window._configElements[tabName][cfg.ConfigName] = element
            end

            element.Destroy = function()
                -- Remove from config tracking
                if cfg.ConfigName and Window._configElements[tabName] then
                    Window._configElements[tabName][cfg.ConfigName] = nil
                end
                for _, c in ipairs(ownedConns) do
                    if c and c.Disconnect then c:Disconnect() end
                    for i, wc in ipairs(windowConnections) do
                        if wc == c then table.remove(windowConnections, i) break end
                    end
                end
                frame:Destroy()
                for i, e in ipairs(Tab.Elements) do
                    if e == element then table.remove(Tab.Elements, i) break end
                end
                if #Tab.Elements == 0 then EmptyState.Visible = true end
            end

            -- SetVisible: show/hide without removing from Elements list
            element.SetVisible = function(visible)
                frame.Visible = visible
            end

            -- SetEnabled: dims and blocks interaction when false
            element.SetEnabled = function(enabled)
                -- Overlay that absorbs all input when disabled
                local overlay = frame:FindFirstChild("_DisabledOverlay")
                if enabled then
                    if overlay then overlay:Destroy() end
                    Tween(frame, {BackgroundTransparency = 0}, 0.15)
                    -- Restore text colours and clear cached value
                    for _, lbl in ipairs(frame:GetDescendants()) do
                        if lbl:IsA("TextLabel") or lbl:IsA("TextButton") or lbl:IsA("TextBox") then
                            if lbl:GetAttribute("_origColor") then
                                lbl.TextColor3 = Color3.fromHex(lbl:GetAttribute("_origColor"))
                                lbl:SetAttribute("_origColor", nil)  -- clear so theme changes apply correctly next time
                            end
                        end
                    end
                else
                    -- Collapse any open dropdown before locking
                    local collapse = _dropdownCollapse[frame]
                    if collapse then collapse() end
                    -- Store original colours once, dim all text
                    for _, lbl in ipairs(frame:GetDescendants()) do
                        if lbl:IsA("TextLabel") or lbl:IsA("TextButton") or lbl:IsA("TextBox") then
                            if not lbl:GetAttribute("_origColor") then
                                lbl:SetAttribute("_origColor", lbl.TextColor3:ToHex())
                            end
                            Tween(lbl, {TextColor3 = Aurora.Config.Theme.Border}, 0.15)
                        end
                    end
                    if not overlay then
                        overlay = Create("TextButton", {
                            Name               = "_DisabledOverlay",
                            Parent             = frame,
                            Size               = UDim2.new(1, 0, 1, 0),
                            BackgroundColor3   = Aurora.Config.Theme.Background,
                            BackgroundTransparency = 0.5,
                            BorderSizePixel    = 0,
                            ZIndex             = 99,
                            Text               = "",
                            AutoButtonColor    = false,
                        })
                        AddCorner(overlay, UDim.new(0, 4))
                    end
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
            }, frame, nil, cfg)
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

            -- c1/c2 are frame-local (destroyed with frame); c3/c4 are UIS globals — pass as ownedConns
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
            }, frame, { c3, c4 }, cfg)
        end

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

            -- Register collapse so SetEnabled(false) can close an open dropdown
            _dropdownCollapse[DropdownFrame] = function()
                if expanded then
                    expanded = false
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end
            end

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
            }, DropdownFrame, nil, cfg)
        end

        -- ── SearchDropdown ────────────────────

        function Tab:CreateSearchDropdown(cfg)
            cfg = cfg or {}
            local options   = cfg.Options or {}
            local selected  = cfg.Default or "Select..."
            local expanded  = false
            local OnChanged = Signal.new()
            local labelText = cfg.Text or "Search"
            local MAX_VISIBLE = cfg.MaxVisible or 6  -- max rows before scroll
            local ROW_H = 30

            local DropFrame = Create("Frame", {
                Parent           = TabContent,
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            AddCorner(DropFrame, UDim.new(0, 4))

            local HeaderLabel = Create("TextLabel", {
                Parent             = DropFrame,
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
                Parent             = DropFrame,
                Position           = UDim2.new(1, -28, 0, 0),
                Size               = UDim2.new(0, 20, 0, 36),
                BackgroundTransparency = 1,
                Text               = "▼",
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.FontBold,
                TextSize           = 11,
            })

            -- Search input (shown when expanded)
            local SearchBox = Create("TextBox", {
                Parent             = DropFrame,
                Position           = UDim2.new(0, 6, 0, 38),
                Size               = UDim2.new(1, -12, 0, 24),
                BackgroundColor3   = Aurora.Config.Theme.Surface,
                BorderSizePixel    = 0,
                Text               = "",
                PlaceholderText    = "Search...",
                PlaceholderColor3  = Aurora.Config.Theme.TextMuted,
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.Font,
                TextSize           = 12,
                ClearTextOnFocus   = true,
            })
            AddCorner(SearchBox, UDim.new(0, 4))
            Create("UIPadding", {Parent = SearchBox, PaddingLeft = UDim.new(0, 8)})

            -- Scrollable options list
            local ListFrame = Create("ScrollingFrame", {
                Parent               = DropFrame,
                Position             = UDim2.new(0, 0, 0, 66),
                Size                 = UDim2.new(1, 0, 0, math.min(#options, MAX_VISIBLE) * ROW_H),
                BackgroundColor3     = Aurora.Config.Theme.Surface,
                BorderSizePixel      = 0,
                ScrollBarThickness   = 2,
                ScrollBarImageColor3 = Aurora.Config.Theme.Border,
                AutomaticCanvasSize  = Enum.AutomaticSize.Y,
                CanvasSize           = UDim2.new(0, 0, 0, 0),
                ClipsDescendants     = true,
            })
            Create("UIListLayout", {Parent = ListFrame, SortOrder = Enum.SortOrder.LayoutOrder})

            -- Build option buttons, store references for filtering
            local optionBtns = {}
            for i, option in ipairs(options) do
                local ob = Create("TextButton", {
                    Parent           = ListFrame,
                    Size             = UDim2.new(1, 0, 0, ROW_H),
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
                    selected          = option
                    HeaderLabel.Text  = labelText .. ": " .. option
                    SearchBox.Text    = ""
                    if cfg.Callback then cfg.Callback(option) end
                    OnChanged:Fire(option)
                    -- Restore all rows and collapse
                    for _, btn in ipairs(optionBtns) do btn.Visible = true end
                    expanded = false
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end)
                optionBtns[i] = ob
            end

            -- Live filter on search text change
            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local query = SearchBox.Text:lower()
                local visible = 0
                for i, opt in ipairs(options) do
                    local show = query == "" or opt:lower():find(query, 1, true) ~= nil
                    optionBtns[i].Visible = show
                    if show then visible = visible + 1 end
                end
                -- Resize list to visible rows (capped at MAX_VISIBLE)
                local newH = math.min(visible, MAX_VISIBLE) * ROW_H
                ListFrame.Size = UDim2.new(1, 0, 0, newH)
                local totalH = 66 + newH
                DropFrame.Size = UDim2.new(1, 0, 0, totalH)
            end)

            local function TotalExpandedH()
                return 66 + math.min(#options, MAX_VISIBLE) * ROW_H
            end

            -- Toggle on header click
            Create("TextButton", {
                Parent             = DropFrame,
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text               = "",
            }).MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, TotalExpandedH())}, 0.2)
                    Tween(Arrow, {Rotation = 180}, 0.2)
                    SearchBox.Text = ""
                    for _, btn in ipairs(optionBtns) do btn.Visible = true end
                    ListFrame.Size = UDim2.new(1, 0, 0, math.min(#options, MAX_VISIBLE) * ROW_H)
                else
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end
            end)

            -- Register collapse so SetEnabled(false) can close an open search dropdown
            _dropdownCollapse[DropFrame] = function()
                if expanded then
                    expanded = false
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end
            end

            return RegisterElement({
                Frame     = DropFrame,
                OnChanged = OnChanged,
                GetValue  = function() return selected end,
                SetValue  = function(val)
                    if table.find(options, val) then
                        selected         = val
                        HeaderLabel.Text = labelText .. ": " .. val
                    end
                end,
            }, DropFrame, nil, cfg)
        end

        function Tab:CreateMultiSelect(cfg)
            cfg = cfg or {}
            local options   = cfg.Options  or {}
            local selected  = {}           -- set: option → true/false
            local expanded  = false
            local OnChanged = Signal.new()
            local labelText = cfg.Text or "Select"

            -- Seed defaults
            for _, opt in ipairs(cfg.Default or {}) do
                selected[opt] = true
            end

            local function SelectedList()
                local t = {}
                for _, opt in ipairs(options) do
                    if selected[opt] then t[#t + 1] = opt end
                end
                return t
            end

            local function HeaderText()
                local list = SelectedList()
                if #list == 0 then return labelText .. ": None"
                elseif #list == 1 then return labelText .. ": " .. list[1]
                else return labelText .. ": " .. #list .. " selected" end
            end

            local MultiFrame = Create("Frame", {
                Parent           = TabContent,
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            AddCorner(MultiFrame, UDim.new(0, 4))

            local Label = Create("TextLabel", {
                Parent             = MultiFrame,
                Position           = UDim2.new(0, 12, 0, 0),
                Size               = UDim2.new(1, -38, 0, 36),
                BackgroundTransparency = 1,
                Text               = HeaderText(),
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Left,
                TextTruncate       = Enum.TextTruncate.AtEnd,
            })

            local Arrow = Create("TextLabel", {
                Parent             = MultiFrame,
                Position           = UDim2.new(1, -28, 0, 0),
                Size               = UDim2.new(0, 20, 0, 36),
                BackgroundTransparency = 1,
                Text               = "▼",
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.FontBold,
                TextSize           = 11,
            })

            local OptionsFrame = Create("Frame", {
                Parent           = MultiFrame,
                Position         = UDim2.new(0, 0, 0, 36),
                Size             = UDim2.new(1, 0, 0, #options * 30),
                BackgroundColor3 = Aurora.Config.Theme.Surface,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            Create("UIListLayout", {Parent = OptionsFrame, SortOrder = Enum.SortOrder.LayoutOrder})

            for i, option in ipairs(options) do
                local row = Create("Frame", {
                    Parent           = OptionsFrame,
                    Size             = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Aurora.Config.Theme.Surface,
                    BorderSizePixel  = 0,
                    LayoutOrder      = i,
                })

                -- Checkbox
                local Box = Create("Frame", {
                    Parent           = row,
                    Position         = UDim2.new(0, 8, 0.5, -8),
                    Size             = UDim2.new(0, 16, 0, 16),
                    BackgroundColor3 = selected[option] and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border,
                    BorderSizePixel  = 0,
                })
                AddCorner(Box, UDim.new(0, 3))

                local Tick = Create("TextLabel", {
                    Parent             = Box,
                    Size               = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text               = selected[option] and "✓" or "",
                    TextColor3         = Aurora.Config.Theme.Text,
                    Font               = Aurora.Config.FontBold,
                    TextSize           = 11,
                })

                Create("TextLabel", {
                    Parent             = row,
                    Position           = UDim2.new(0, 32, 0, 0),
                    Size               = UDim2.new(1, -40, 1, 0),
                    BackgroundTransparency = 1,
                    Text               = option,
                    TextColor3         = selected[option] and Aurora.Config.Theme.Text or Aurora.Config.Theme.TextMuted,
                    Font               = Aurora.Config.FontMedium,
                    TextSize           = 13,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    Name               = "OptionLabel",
                })

                local RowBtn = Create("TextButton", {
                    Parent             = row,
                    Size               = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text               = "",
                })

                RowBtn.MouseEnter:Connect(function()
                    Tween(row, {BackgroundColor3 = Aurora.Config.Theme.Background}, 0.15)
                end)
                RowBtn.MouseLeave:Connect(function()
                    Tween(row, {BackgroundColor3 = Aurora.Config.Theme.Surface}, 0.15)
                end)
                RowBtn.MouseButton1Click:Connect(function()
                    selected[option] = not selected[option]
                    local on = selected[option]
                    Tween(Box, {BackgroundColor3 = on and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border}, 0.15)
                    Tick.Text = on and "✓" or ""
                    local lbl = row:FindFirstChild("OptionLabel")
                    if lbl then
                        Tween(lbl, {TextColor3 = on and Aurora.Config.Theme.Text or Aurora.Config.Theme.TextMuted}, 0.15)
                    end
                    Label.Text = HeaderText()
                    local vals = SelectedList()
                    if cfg.Callback then cfg.Callback(vals) end
                    OnChanged:Fire(vals)
                end)
            end

            -- Toggle
            Create("TextButton", {
                Parent             = MultiFrame,
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text               = "",
            }).MouseButton1Click:Connect(function()
                expanded = not expanded
                Tween(MultiFrame, {Size = UDim2.new(1, 0, 0, expanded and 36 + #options * 30 or 36)}, 0.2)
                Tween(Arrow, {Rotation = expanded and 180 or 0}, 0.2)
            end)

            -- Register collapse so SetEnabled(false) closes an open multi-select
            _dropdownCollapse[MultiFrame] = function()
                if expanded then
                    expanded = false
                    Tween(MultiFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end
            end

            return RegisterElement({
                Frame     = MultiFrame,
                OnChanged = OnChanged,
                GetValue  = function() return SelectedList() end,
                SetValue  = function(vals)
                    -- vals is an array of selected option strings
                    selected = {}
                    for _, v in ipairs(vals) do selected[v] = true end
                    Label.Text = HeaderText()
                    -- Sync checkboxes visually
                    for _, row in ipairs(OptionsFrame:GetChildren()) do
                        if row:IsA("Frame") then
                            local box  = row:FindFirstChildWhichIsA("Frame")
                            local tick = box and box:FindFirstChildWhichIsA("TextLabel")
                            local lbl  = row:FindFirstChild("OptionLabel")
                            local opt  = lbl and lbl.Text
                            local on   = opt and selected[opt] or false
                            if box  then box.BackgroundColor3 = on and Aurora.Config.Theme.Primary or Aurora.Config.Theme.Border end
                            if tick then tick.Text = on and "✓" or "" end
                            if lbl  then lbl.TextColor3 = on and Aurora.Config.Theme.Text or Aurora.Config.Theme.TextMuted end
                        end
                    end
                end,
                IsSelected = function(opt) return selected[opt] == true end,
            }, MultiFrame, nil, cfg)
        end

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
            }, frame, nil, cfg)
        end

        -- ── NumberInput ───────────────────────

        function Tab:CreateNumberInput(cfg)
            cfg = cfg or {}
            local min       = cfg.Min       or -math.huge
            local max       = cfg.Max       or math.huge
            local step      = cfg.Step      or 1
            local current   = math.clamp(cfg.Default or 0, min, max)
            local OnChanged = Signal.new()
            local frame     = BaseFrame(54)

            Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 6),
                Size               = UDim2.new(1, -24, 0, 16),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Number",
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 12,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            -- [ − ] [ value ] [ + ]  row
            local Row = Create("Frame", {
                Parent           = frame,
                Position         = UDim2.new(0, 10, 0, 26),
                Size             = UDim2.new(1, -20, 0, 22),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
            })

            local function MakeStepBtn(xAlign, symbol)
                local btn = Create("TextButton", {
                    Parent           = Row,
                    AnchorPoint      = Vector2.new(xAlign, 0),
                    Position         = UDim2.new(xAlign, 0, 0, 0),
                    Size             = UDim2.new(0, 26, 1, 0),
                    BackgroundColor3 = Aurora.Config.Theme.Surface,
                    Text             = symbol,
                    TextColor3       = Aurora.Config.Theme.Primary,
                    Font             = Aurora.Config.FontBold,
                    TextSize         = 16,
                    AutoButtonColor  = false,
                    BorderSizePixel  = 0,
                })
                AddCorner(btn, UDim.new(0, 4))
                btn.MouseEnter:Connect(function()
                    Tween(btn, {BackgroundColor3 = Aurora.Config.Theme.Primary, TextColor3 = Aurora.Config.Theme.Text}, 0.15)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, {BackgroundColor3 = Aurora.Config.Theme.Surface, TextColor3 = Aurora.Config.Theme.Primary}, 0.15)
                end)
                return btn
            end

            local MinusBtn = MakeStepBtn(0, "−")
            local PlusBtn  = MakeStepBtn(1, "+")

            local NumBox = Create("TextBox", {
                Parent             = Row,
                Position           = UDim2.new(0, 30, 0, 0),
                Size               = UDim2.new(1, -60, 1, 0),
                BackgroundColor3   = Aurora.Config.Theme.Surface,
                BorderSizePixel    = 0,
                Text               = tostring(current),
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontBold,
                TextSize           = 13,
                ClearTextOnFocus   = false,
                TextXAlignment     = Enum.TextXAlignment.Center,
            })
            AddCorner(NumBox, UDim.new(0, 4))

            local function Commit(val)
                val = math.clamp(math.floor(val / step + 0.5) * step, min, max)
                if val == current then
                    NumBox.Text = tostring(current) -- reset display if clamped
                    return
                end
                current     = val
                NumBox.Text = tostring(val)
                if cfg.Callback then cfg.Callback(val) end
                OnChanged:Fire(val)
            end

            MinusBtn.MouseButton1Click:Connect(function() Commit(current - step) end)
            PlusBtn.MouseButton1Click:Connect(function()  Commit(current + step) end)

            NumBox.FocusLost:Connect(function()
                local n = tonumber(NumBox.Text)
                if n then Commit(n)
                else NumBox.Text = tostring(current) end  -- revert invalid input
            end)

            return RegisterElement({
                Frame     = frame,
                OnChanged = OnChanged,
                GetValue  = function() return current end,
                SetValue  = function(val) Commit(val) end,
            }, frame, nil, cfg)
        end

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

            return RegisterElement({
                Frame     = frame,
                OnChanged = OnChanged,
                GetValue  = function() return current end,
                SetValue  = function(key)
                    current   = key
                    KeyBtn.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
                end,
            }, frame, { cancelCon }, cfg)
        end

        function Tab:CreateColorPicker(cfg)
            cfg = cfg or {}
            local color     = cfg.Default or Color3.fromRGB(255, 255, 255)
            local expanded  = false
            local OnChanged = Signal.new()

            local h, s, v   = Color3.toHSV(color)

            -- Expanded height: 36 header + 6 gap + 68 pads + 6 gap + 22 hex + 10 padding
            local EXPANDED_H = 148

            local PickerFrame = Create("Frame", {
                Parent           = TabContent,
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            AddCorner(PickerFrame, UDim.new(0, 4))

            -- Header
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

            -- Toggle expand
            Create("TextButton", {
                Parent             = PickerFrame,
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text               = "",
                ZIndex             = 10,
            }).MouseButton1Click:Connect(function()
                expanded = not expanded
                Tween(PickerFrame, {Size = UDim2.new(1, 0, 0, expanded and EXPANDED_H or 36)}, 0.25)
            end)

            -- Panel container
            local Panel = Create("Frame", {
                Parent             = PickerFrame,
                Position           = UDim2.new(0, 8, 0, 44),
                Size               = UDim2.new(1, -16, 0, 96),
                BackgroundTransparency = 1,
                BorderSizePixel    = 0,
            })

            -- ── SV Pad ───────────────────────
            -- Background: pure hue color
            local SVPad = Create("Frame", {
                Parent           = Panel,
                Position         = UDim2.new(0, 0, 0, 0),
                Size             = UDim2.new(1, -26, 0, 68),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                ZIndex           = 2,
            })
            AddCorner(SVPad, UDim.new(0, 4))

            -- White-to-transparent overlay (left = white, right = hue) — controls Saturation
            local WLayer = Create("Frame", {
                Parent             = SVPad,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundColor3   = Color3.new(1, 1, 1),
                BorderSizePixel    = 0,
                ZIndex             = 3,
            })
            Create("UIGradient", {
                Parent       = WLayer,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),   -- left: opaque white
                    NumberSequenceKeypoint.new(1, 1),   -- right: transparent (shows hue)
                }),
                Rotation = 0,
            })

            -- Transparent-to-black overlay (top = clear, bottom = black) — controls Value
            local BLayer = Create("Frame", {
                Parent             = SVPad,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundColor3   = Color3.new(0, 0, 0),
                BorderSizePixel    = 0,
                ZIndex             = 4,
            })
            Create("UIGradient", {
                Parent       = BLayer,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),   -- top: transparent
                    NumberSequenceKeypoint.new(1, 0),   -- bottom: opaque black
                }),
                Rotation = 90,
            })

            -- Invisible drag surface (above gradients)
            local SVDrag = Create("TextButton", {
                Parent             = SVPad,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = "",
                ZIndex             = 6,
            })

            -- Cursor dot
            local SVCursor = Create("Frame", {
                Parent           = SVPad,
                Size             = UDim2.new(0, 10, 0, 10),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(s, 0, 1 - v, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                ZIndex           = 7,
            })
            AddCorner(SVCursor, UDim.new(1, 0))

            -- ── Hue Bar ──────────────────────
            local HueBar = Create("Frame", {
                Parent           = Panel,
                Position         = UDim2.new(1, -20, 0, 0),
                Size             = UDim2.new(0, 14, 0, 68),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                ZIndex           = 2,
            })
            AddCorner(HueBar, UDim.new(0, 4))

            -- Full-spectrum UIGradient (top→bottom = 0°→360°)
            Create("UIGradient", {
                Parent   = HueBar,
                Color    = ColorSequence.new({
                    ColorSequenceKeypoint.new(0/6, Color3.fromHSV(0/6, 1, 1)),
                    ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
                    ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
                    ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
                    ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
                    ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
                    ColorSequenceKeypoint.new(1,   Color3.fromHSV(0,   1, 1)),
                }),
                Rotation = 90,
            })

            local HueDrag = Create("TextButton", {
                Parent             = HueBar,
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = "",
                ZIndex             = 3,
            })

            local HueCursor = Create("Frame", {
                Parent           = HueBar,
                Size             = UDim2.new(1, 0, 0, 4),
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = UDim2.new(0, 0, h, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                ZIndex           = 4,
            })
            AddCorner(HueCursor, UDim.new(1, 0))

            -- ── Hex Input ────────────────────
            local HexInput = Create("TextBox", {
                Parent             = Panel,
                Position           = UDim2.new(0, 0, 0, 74),
                Size               = UDim2.new(1, 0, 0, 22),
                BackgroundColor3   = Aurora.Config.Theme.Surface,
                BorderSizePixel    = 0,
                Text               = string.format("#%02X%02X%02X",
                    math.round(color.R * 255),
                    math.round(color.G * 255),
                    math.round(color.B * 255)),
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.Font,
                TextSize           = 12,
                ClearTextOnFocus   = false,
                ZIndex             = 2,
            })
            AddCorner(HexInput, UDim.new(0, 4))
            Create("UIPadding", {Parent = HexInput, PaddingLeft = UDim.new(0, 8)})

            -- ── Commit ───────────────────────
            local function Commit()
                color = Color3.fromHSV(h, s, v)
                Preview.BackgroundColor3 = color
                SVPad.BackgroundColor3   = Color3.fromHSV(h, 1, 1)
                SVCursor.Position        = UDim2.new(s, 0, 1 - v, 0)
                HueCursor.Position       = UDim2.new(0, 0, h, 0)
                HexInput.Text = string.format("#%02X%02X%02X",
                    math.round(color.R * 255),
                    math.round(color.G * 255),
                    math.round(color.B * 255))
                if cfg.Callback then cfg.Callback(color) end
                OnChanged:Fire(color)
            end

            -- SV drag
            local svDragging = false
            SVDrag.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    svDragging = true
                    -- Also sample on initial click
                    s = math.clamp((inp.Position.X - SVPad.AbsolutePosition.X) / SVPad.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((inp.Position.Y - SVPad.AbsolutePosition.Y) / SVPad.AbsoluteSize.Y, 0, 1)
                    Commit()
                end
            end)
            local svMove = UserInputService.InputChanged:Connect(function(inp)
                if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    s = math.clamp((inp.Position.X - SVPad.AbsolutePosition.X) / SVPad.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((inp.Position.Y - SVPad.AbsolutePosition.Y) / SVPad.AbsoluteSize.Y, 0, 1)
                    Commit()
                end
            end)
            local svEnd = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
            end)
            table.insert(windowConnections, svMove)
            table.insert(windowConnections, svEnd)
            -- Hue drag
            local hueDragging = false
            HueDrag.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = true
                    h = math.clamp((inp.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                    Commit()
                end
            end)
            local hueMove = UserInputService.InputChanged:Connect(function(inp)
                if hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    h = math.clamp((inp.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                    Commit()
                end
            end)
            local hueEnd = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
            end)

            -- Hex input: parse on Enter
            HexInput.FocusLost:Connect(function(enter)
                if not enter then return end
                local hex = HexInput.Text:gsub("#", "")
                if #hex == 6 then
                    local r = tonumber(hex:sub(1, 2), 16)
                    local g = tonumber(hex:sub(3, 4), 16)
                    local b = tonumber(hex:sub(5, 6), 16)
                    if r and g and b then
                        color  = Color3.fromRGB(r, g, b)
                        h, s, v = Color3.toHSV(color)
                        Commit()
                    end
                end
            end)

            -- Register collapse so SetEnabled(false) closes an open picker
            _dropdownCollapse[PickerFrame] = function()
                if expanded then
                    expanded = false
                    Tween(PickerFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.25)
                end
            end

            return RegisterElement({
                Frame     = PickerFrame,
                OnChanged = OnChanged,
                GetValue  = function() return color end,
                SetValue  = function(c)
                    color  = c
                    h, s, v = Color3.toHSV(c)
                    Commit()
                end,
            }, PickerFrame, { svMove, svEnd, hueMove, hueEnd }, cfg)
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
                Frame    = frame,
                GetValue = function() return lbl.Text end,
                SetValue = function(t) lbl.Text = tostring(t) end,
                SetText  = function(t) lbl.Text = tostring(t) end,
            }, frame)
        end

        function Tab:CreateSection(sectionText)
            local frame = Create("Frame", {
                Parent             = TabContent,
                Size               = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
            })
            local sectionLabel = Create("TextLabel", {
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
            return RegisterElement({
                Frame    = frame,
                GetValue = function() return sectionLabel.Text end,
                SetValue = function(t) sectionLabel.Text = tostring(t):upper() end,
                SetText  = function(t) sectionLabel.Text = tostring(t):upper() end,
            }, frame)
        end

        -- ── ProgressBar ───────────────────────

        function Tab:CreateProgressBar(cfg)
            cfg = cfg or {}
            local value     = math.clamp(cfg.Default or 0, 0, 1)  -- always 0..1
            local OnChanged = Signal.new()

            local frame = BaseFrame(46)

            local Label = Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 12, 0, 6),
                Size               = UDim2.new(1, -60, 0, 16),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Progress",
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.FontMedium,
                TextSize           = 12,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            local PctLabel = Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(1, -50, 0, 6),
                Size               = UDim2.new(0, 42, 0, 16),
                BackgroundTransparency = 1,
                Text               = "0%",
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.Font,
                TextSize           = 12,
                TextXAlignment     = Enum.TextXAlignment.Right,
            })

            local Track = Create("Frame", {
                Parent           = frame,
                Position         = UDim2.new(0, 10, 0, 30),
                Size             = UDim2.new(1, -20, 0, 8),
                BackgroundColor3 = Aurora.Config.Theme.Surface,
                BorderSizePixel  = 0,
            })
            AddCorner(Track, UDim.new(1, 0))

            local barColor = cfg.Color or Aurora.Config.Theme.Primary
            local Fill = Create("Frame", {
                Parent           = Track,
                Size             = UDim2.new(value, 0, 1, 0),
                BackgroundColor3 = barColor,
                BorderSizePixel  = 0,
            })
            AddCorner(Fill, UDim.new(1, 0))

            local function Apply(pct)
                pct   = math.clamp(pct, 0, 1)
                value = pct
                Tween(Fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2)
                PctLabel.Text = math.floor(pct * 100) .. "%"
                OnChanged:Fire(pct)
            end

            Apply(value)  -- seed initial display

            return RegisterElement({
                Frame     = frame,
                OnChanged = OnChanged,
                GetValue  = function() return value end,
                SetValue  = function(pct) Apply(pct) end,
                SetLabel  = function(t) Label.Text = tostring(t) end,
                SetColor  = function(c)
                    barColor              = c
                    Fill.BackgroundColor3 = c
                end,
            }, frame)
        end

        -- ── StatusLabel ───────────────────────

        function Tab:CreateStatusLabel(cfg)
            cfg = cfg or {}
            local typeColors = {
                Info    = Aurora.Config.Theme.Primary,
                Success = Aurora.Config.Theme.Success,
                Warning = Aurora.Config.Theme.Warning,
                Error   = Aurora.Config.Theme.Error,
            }
            local currentType = cfg.Type or "Info"
            local OnChanged   = Signal.new()

            local frame = Create("Frame", {
                Parent             = TabContent,
                Size               = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
            })

            local Dot = Create("Frame", {
                Parent           = frame,
                Position         = UDim2.new(0, 2, 0.5, -4),
                Size             = UDim2.new(0, 8, 0, 8),
                BackgroundColor3 = typeColors[currentType],
                BorderSizePixel  = 0,
            })
            AddCorner(Dot, UDim.new(1, 0))

            local Lbl = Create("TextLabel", {
                Parent             = frame,
                Position           = UDim2.new(0, 16, 0, 0),
                Size               = UDim2.new(1, -16, 1, 0),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "",
                TextColor3         = typeColors[currentType],
                Font               = Aurora.Config.FontMedium,
                TextSize           = 12,
                TextXAlignment     = Enum.TextXAlignment.Left,
                TextTruncate       = Enum.TextTruncate.AtEnd,
            })

            local function ApplyType(t)
                currentType = t
                local c = typeColors[t] or typeColors.Info
                Dot.BackgroundColor3 = c
                Lbl.TextColor3       = c
            end

            return RegisterElement({
                Frame     = frame,
                OnChanged = OnChanged,
                GetValue  = function() return Lbl.Text end,
                -- SetValue(text, type?) — type is optional
                SetValue  = function(t, typ)
                    Lbl.Text = tostring(t)
                    if typ then ApplyType(typ) end
                    OnChanged:Fire(Lbl.Text)
                end,
                SetText   = function(t) Lbl.Text = tostring(t) end,
                SetType   = ApplyType,
            }, frame)
        end

        -- ── Table ─────────────────────────────

        function Tab:CreateTable(cfg)
            cfg = cfg or {}
            local columns  = cfg.Columns  or { "Column 1", "Column 2" }
            local rows     = cfg.Rows     or {}
            local rowH     = 28
            local headerH  = 28
            local maxRows  = cfg.MaxVisible or 6
            local OnRowClicked = Signal.new()

            local numCols  = #columns
            local colW     = 1 / numCols

            -- Outer frame: header + scrollable body
            local TableFrame = Create("Frame", {
                Parent           = TabContent,
                Size             = UDim2.new(1, 0, 0, headerH + math.min(#rows, maxRows) * rowH),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel  = 0,
                ClipsDescendants = false,
            })
            AddCorner(TableFrame, UDim.new(0, 4))

            -- ── Header row ───────────────────
            local Header = Create("Frame", {
                Parent           = TableFrame,
                Size             = UDim2.new(1, 0, 0, headerH),
                BackgroundColor3 = Aurora.Config.Theme.Primary,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            AddCorner(Header, UDim.new(0, 4))
            -- Patch bottom corners of header so it sits flush on the body
            Create("Frame", {
                Parent           = Header,
                Position         = UDim2.new(0, 0, 1, -6),
                Size             = UDim2.new(1, 0, 0, 6),
                BackgroundColor3 = Aurora.Config.Theme.Primary,
                BorderSizePixel  = 0,
            })

            for i, col in ipairs(columns) do
                Create("TextLabel", {
                    Parent             = Header,
                    Position           = UDim2.new((i-1) * colW, 8, 0, 0),
                    Size               = UDim2.new(colW, -8, 1, 0),
                    BackgroundTransparency = 1,
                    Text               = col,
                    TextColor3         = Aurora.Config.Theme.Text,
                    Font               = Aurora.Config.FontBold,
                    TextSize           = 12,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    TextTruncate       = Enum.TextTruncate.AtEnd,
                })
                -- Column divider (skip after last)
                if i < numCols then
                    Create("Frame", {
                        Parent           = Header,
                        Position         = UDim2.new(i * colW, 0, 0.1, 0),
                        Size             = UDim2.new(0, 1, 0.8, 0),
                        BackgroundColor3 = Color3.new(1,1,1),
                        BackgroundTransparency = 0.7,
                        BorderSizePixel  = 0,
                    })
                end
            end

            -- ── Scrollable body ──────────────
            local Body = Create("ScrollingFrame", {
                Parent               = TableFrame,
                Position             = UDim2.new(0, 0, 0, headerH),
                Size                 = UDim2.new(1, 0, 1, -headerH),
                BackgroundColor3     = Aurora.Config.Theme.Background,
                BorderSizePixel      = 0,
                ScrollBarThickness   = 2,
                ScrollBarImageColor3 = Aurora.Config.Theme.Border,
                AutomaticCanvasSize  = Enum.AutomaticSize.Y,
                CanvasSize           = UDim2.new(0, 0, 0, 0),
                ClipsDescendants     = true,
            })
            -- Round only the bottom corners
            AddCorner(Body, UDim.new(0, 4))
            Create("UIListLayout", {Parent = Body, SortOrder = Enum.SortOrder.LayoutOrder})

            -- Internal: render a single row
            local rowObjects     = {}
            local rowColors      = {}   -- index → Color3 override (nil = use default)
            local rowBaseSetters = {}   -- index → fn(color) that updates MouseLeave restore target

            local function RenderRow(rowData, index)
                local defaultColor = index % 2 == 0
                    and Aurora.Config.Theme.Surface
                    or  Aurora.Config.Theme.Background
                local baseColor = rowColors[index] or defaultColor

                local rowFrame = Create("Frame", {
                    Parent           = Body,
                    Size             = UDim2.new(1, 0, 0, rowH),
                    BackgroundColor3 = baseColor,
                    BorderSizePixel  = 0,
                    LayoutOrder      = index,
                })

                for c, cell in ipairs(rowData) do
                    Create("TextLabel", {
                        Parent             = rowFrame,
                        Position           = UDim2.new((c-1) * colW, 8, 0, 0),
                        Size               = UDim2.new(colW, -8, 1, 0),
                        BackgroundTransparency = 1,
                        Text               = tostring(cell),
                        TextColor3         = Aurora.Config.Theme.Text,
                        Font               = Aurora.Config.Font,
                        TextSize           = 12,
                        TextXAlignment     = Enum.TextXAlignment.Left,
                        TextTruncate       = Enum.TextTruncate.AtEnd,
                    })
                end

                -- currentBase is upvalue shared between MouseLeave and rowBaseSetters
                local currentBase = baseColor
                rowBaseSetters[index] = function(c)
                    currentBase           = c
                    rowFrame.BackgroundColor3 = c
                end

                local rowBtn = Create("TextButton", {
                    Parent             = rowFrame,
                    Size               = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text               = "",
                })
                rowBtn.MouseEnter:Connect(function()
                    Tween(rowFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}, 0.12)
                end)
                rowBtn.MouseLeave:Connect(function()
                    Tween(rowFrame, {BackgroundColor3 = currentBase}, 0.12)
                end)
                rowBtn.MouseButton1Click:Connect(function()
                    OnRowClicked:Fire(index, rowData)
                end)

                return rowFrame
            end

            -- Render initial rows
            for i, rowData in ipairs(rows) do
                rowObjects[i] = RenderRow(rowData, i)
            end

            -- Resize outer frame to fit visible rows
            local function Resize()
                local visible = math.min(#rows, maxRows)
                TableFrame.Size = UDim2.new(1, 0, 0, headerH + visible * rowH)
            end
            Resize()

            -- Element API
            local element = {
                Frame        = TableFrame,
                OnRowClicked = OnRowClicked,

                -- Replace all rows at once (clears row colours)
                SetRows = function(newRows)
                    rows         = newRows
                    rowColors    = {}
                    rowBaseSetters = {}
                    for _, obj in ipairs(rowObjects) do obj:Destroy() end
                    rowObjects = {}
                    for i, rowData in ipairs(rows) do
                        rowObjects[i] = RenderRow(rowData, i)
                    end
                    Resize()
                end,

                -- Append a single row
                AddRow = function(rowData)
                    table.insert(rows, rowData)
                    local i = #rows
                    rowObjects[i] = RenderRow(rowData, i)
                    Resize()
                end,

                -- Remove a row by index, re-render all (alternating colours need reindex)
                RemoveRow = function(index)
                    if not rows[index] then return end
                    table.remove(rows, index)
                    -- Shift rowColors down
                    local newColors = {}
                    for i, c in pairs(rowColors) do
                        if i > index then newColors[i - 1] = c
                        elseif i < index then newColors[i] = c end
                    end
                    rowColors      = newColors
                    rowBaseSetters = {}
                    for _, obj in ipairs(rowObjects) do obj:Destroy() end
                    rowObjects = {}
                    for i, rowData in ipairs(rows) do
                        rowObjects[i] = RenderRow(rowData, i)
                    end
                    Resize()
                end,

                -- Update a single cell without full re-render
                SetCell = function(rowIndex, colIndex, value)
                    if not rows[rowIndex] then return end
                    rows[rowIndex][colIndex] = value
                    local rowFrame = rowObjects[rowIndex]
                    if rowFrame then
                        local labels = {}
                        for _, c in ipairs(rowFrame:GetChildren()) do
                            if c:IsA("TextLabel") then table.insert(labels, c) end
                        end
                        table.sort(labels, function(a, b)
                            return a.Position.X.Scale < b.Position.X.Scale
                        end)
                        if labels[colIndex] then
                            labels[colIndex].Text = tostring(value)
                        end
                    end
                end,

                -- Highlight a row with a custom colour; persists across hover
                SetRowColor = function(index, color)
                    rowColors[index] = color
                    if rowBaseSetters[index] then
                        rowBaseSetters[index](color)
                    end
                end,

                -- Remove a custom row colour, restore default even/odd
                ClearRowColor = function(index)
                    rowColors[index] = nil
                    if rowBaseSetters[index] then
                        local defaultColor = index % 2 == 0
                            and Aurora.Config.Theme.Surface
                            or  Aurora.Config.Theme.Background
                        rowBaseSetters[index](defaultColor)
                    end
                end,

                -- Clear all rows (also clears row colours)
                Clear = function()
                    rows           = {}
                    rowColors      = {}
                    rowBaseSetters = {}
                    for _, obj in ipairs(rowObjects) do obj:Destroy() end
                    rowObjects = {}
                    Resize()
                end,

                GetRows = function()
                    local copy = {}
                    for i, row in ipairs(rows) do copy[i] = row end
                    return copy
                end,
            }

            return RegisterElement(element, TableFrame)
        end

        -- ── Config Manager UI ─────────────────

        function Tab:CreateConfigManager(cfg)
            cfg = cfg or {}
            local managerFrame = Create("Frame", {
                Parent           = TabContent,
                Size             = UDim2.new(1, 0, 0, 180),
                BackgroundColor3 = Aurora.Config.Theme.Background,
                BorderSizePixel  = 0,
            })
            AddCorner(managerFrame, UDim.new(0, 4))

            -- Title
            Create("TextLabel", {
                Parent             = managerFrame,
                Position           = UDim2.new(0, 12, 0, 8),
                Size               = UDim2.new(1, -24, 0, 18),
                BackgroundTransparency = 1,
                Text               = cfg.Text or "Configuration Manager",
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.FontBold,
                TextSize           = 14,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            -- Config name input
            local NameInput = Create("TextBox", {
                Parent             = managerFrame,
                Position           = UDim2.new(0, 12, 0, 32),
                Size               = UDim2.new(1, -24, 0, 28),
                BackgroundColor3   = Aurora.Config.Theme.Surface,
                BorderSizePixel    = 0,
                Text               = "",
                PlaceholderText    = "Config name...",
                PlaceholderColor3  = Aurora.Config.Theme.TextMuted,
                TextColor3         = Aurora.Config.Theme.Text,
                Font               = Aurora.Config.Font,
                TextSize           = 13,
                ClearTextOnFocus   = false,
            })
            AddCorner(NameInput, UDim.new(0, 4))
            Create("UIPadding", {Parent = NameInput, PaddingLeft = UDim.new(0, 8)})

            -- Buttons row 1: Save, Load, Delete
            local function MakeBtn(text, xPos, color)
                local btn = Create("TextButton", {
                    Parent           = managerFrame,
                    Position         = UDim2.new(0, 12 + xPos, 0, 68),
                    Size             = UDim2.new(0, 80, 0, 28),
                    BackgroundColor3 = color or Aurora.Config.Theme.Primary,
                    Text             = text,
                    TextColor3       = Aurora.Config.Theme.Text,
                    Font             = Aurora.Config.FontMedium,
                    TextSize         = 12,
                    AutoButtonColor  = false,
                    BorderSizePixel  = 0,
                })
                AddCorner(btn, UDim.new(0, 4))
                btn.MouseEnter:Connect(function()
                    Tween(btn, {BackgroundColor3 = Color3.fromRGB(45, 45, 60)}, 0.15)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, {BackgroundColor3 = color or Aurora.Config.Theme.Primary}, 0.15)
                end)
                return btn
            end

            local SaveBtn   = MakeBtn("Save", 0, Aurora.Config.Theme.Success)
            local LoadBtn   = MakeBtn("Load", 88)
            local DeleteBtn = MakeBtn("Delete", 176, Aurora.Config.Theme.Error)
            local ListBtn   = MakeBtn("Refresh", 264, Aurora.Config.Theme.Warning)

            -- Status label
            local StatusLabel = Create("TextLabel", {
                Parent             = managerFrame,
                Position           = UDim2.new(0, 12, 0, 104),
                Size               = UDim2.new(1, -24, 0, 16),
                BackgroundTransparency = 1,
                Text               = "Ready",
                TextColor3         = Aurora.Config.Theme.TextMuted,
                Font               = Aurora.Config.Font,
                TextSize           = 11,
                TextXAlignment     = Enum.TextXAlignment.Left,
            })

            -- Config list (scrolling frame showing available configs)
            local ListFrame = Create("ScrollingFrame", {
                Parent               = managerFrame,
                Position             = UDim2.new(0, 12, 0, 124),
                Size                 = UDim2.new(1, -24, 0, 50),
                BackgroundColor3     = Aurora.Config.Theme.Surface,
                BorderSizePixel      = 0,
                ScrollBarThickness   = 2,
                ScrollBarImageColor3 = Aurora.Config.Theme.Border,
                AutomaticCanvasSize  = Enum.AutomaticSize.Y,
                CanvasSize           = UDim2.new(0, 0, 0, 0),
            })
            AddCorner(ListFrame, UDim.new(0, 4))
            Create("UIListLayout", {Parent = ListFrame, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
            Create("UIPadding", {Parent = ListFrame, PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)})

            local function UpdateStatus(msg, isError)
                StatusLabel.Text = msg
                StatusLabel.TextColor3 = isError and Aurora.Config.Theme.Error or Aurora.Config.Theme.Success
                task.delay(3, function()
                    StatusLabel.Text = "Ready"
                    StatusLabel.TextColor3 = Aurora.Config.Theme.TextMuted
                end)
            end

            local function RefreshList()
                for _, child in ipairs(ListFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                local configs = Aurora.ConfigManager:List(Window._title)
                for _, name in ipairs(configs) do
                    local btn = Create("TextButton", {
                        Parent           = ListFrame,
                        Size             = UDim2.new(1, 0, 0, 20),
                        BackgroundTransparency = 1,
                        Text             = name,
                        TextColor3       = Aurora.Config.Theme.TextMuted,
                        Font             = Aurora.Config.Font,
                        TextSize         = 11,
                        TextXAlignment   = Enum.TextXAlignment.Left,
                        AutoButtonColor  = false,
                    })
                    btn.MouseEnter:Connect(function()
                        Tween(btn, {TextColor3 = Aurora.Config.Theme.Text}, 0.15)
                    end)
                    btn.MouseLeave:Connect(function()
                        Tween(btn, {TextColor3 = Aurora.Config.Theme.TextMuted}, 0.15)
                    end)
                    btn.MouseButton1Click:Connect(function()
                        NameInput.Text = name
                    end)
                end
            end

            SaveBtn.MouseButton1Click:Connect(function()
                local name = NameInput.Text:gsub("^%s*(.-)%s*$", "%1") -- trim
                if name == "" then UpdateStatus("Enter a config name", true) return end
                local ok, err = Window:SaveConfig(name)
                if ok then
                    UpdateStatus("Saved: " .. name)
                    RefreshList()
                else
                    UpdateStatus("Save failed: " .. (err or "unknown"), true)
                end
            end)

            LoadBtn.MouseButton1Click:Connect(function()
                local name = NameInput.Text:gsub("^%s*(.-)%s*$", "%1")
                if name == "" then UpdateStatus("Enter a config name", true) return end
                local ok, err = Window:LoadConfig(name)
                if ok then
                    UpdateStatus("Loaded: " .. name)
                else
                    UpdateStatus("Load failed: " .. (err or "unknown"), true)
                end
            end)

            DeleteBtn.MouseButton1Click:Connect(function()
                local name = NameInput.Text:gsub("^%s*(.-)%s*$", "%1")
                if name == "" then UpdateStatus("Enter a config name", true) return end
                local ok = Aurora.ConfigManager:Delete(name, Window._title)
                if ok then
                    UpdateStatus("Deleted: " .. name)
                    NameInput.Text = ""
                    RefreshList()
                else
                    UpdateStatus("Delete failed", true)
                end
            end)

            ListBtn.MouseButton1Click:Connect(function()
                RefreshList()
                UpdateStatus("Config list refreshed")
            end)

            -- Initial refresh
            RefreshList()

            -- Auto-load last config if requested
            if cfg.AutoLoad then
                local lastConfig = Aurora.ConfigManager:GetLastConfig(Window._title)
                if lastConfig then
                    NameInput.Text = lastConfig
                    Window:LoadConfig(lastConfig)
                end
            end

            return RegisterElement({
                Frame       = managerFrame,
                RefreshList = RefreshList,
            }, managerFrame)
        end

        if #Window.Tabs == 0 then
            TabButton.BackgroundColor3 = Aurora.Config.Theme.Primary
            TabLabel.TextColor3        = Aurora.Config.Theme.Text
            TabContent.Visible         = true
            Window.ActiveTab           = Tab
        end

        table.insert(Window.Tabs, Tab)
        return Tab
    end

    local dragConns = MakeDraggable(MainFrame, TitleBar)
    for _, c in ipairs(dragConns) do
        table.insert(windowConnections, c)
    end

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

-- ─────────────────────────────────────────────
--  Config Manager
-- ─────────────────────────────────────────────

Aurora.ConfigManager = {
    _folder = "AuroraConfigs",
    _ext = ".json",
}

-- Sanitize filename for filesystem safety
local function SanitizeFilename(name)
    return name:gsub("[\\/:%*%?\"<>|]", "_")
end

-- Get full path for a config
function Aurora.ConfigManager:_getPath(name, windowTitle)
    local folder = self._folder .. "/" .. SanitizeFilename(windowTitle or "Default")
    return folder .. "/" .. SanitizeFilename(name) .. self._ext
end

-- Ensure folder exists
function Aurora.ConfigManager:_ensureFolder(windowTitle)
    local folder = self._folder .. "/" .. SanitizeFilename(windowTitle or "Default")
    if not isfolder(folder) then
        makefolder(folder)
    end
    return folder
end

-- Serialize Color3 to hex
local function Color3ToHex(c)
    return string.format("#%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

-- Deserialize hex to Color3
local function HexToColor3(hex)
    local h = hex:gsub("#", "")
    return Color3.fromRGB(tonumber(h:sub(1,2), 16) or 255, tonumber(h:sub(3,4), 16) or 255, tonumber(h:sub(5,6), 16) or 255)
end

-- Serialize KeyCode to string
local function KeyCodeToString(kc)
    return kc.Name
end

-- Deserialize string to KeyCode
local function StringToKeyCode(s)
    return Enum.KeyCode[s] or Enum.KeyCode.Unknown
end

-- Serialize value based on type
local function SerializeValue(val)
    if typeof(val) == "Color3" then
        return { __type = "Color3", value = Color3ToHex(val) }
    elseif typeof(val) == "EnumItem" then
        return { __type = "Enum", enum = tostring(val.EnumType), value = val.Name }
    else
        return val
    end
end

-- Deserialize value
local function DeserializeValue(val)
    if type(val) == "table" and val.__type then
        if val.__type == "Color3" then
            return HexToColor3(val.value)
        elseif val.__type == "Enum" then
            -- Handle KeyCode specifically
            if val.enum == "KeyCode" then
                return StringToKeyCode(val.value)
            end
        end
    end
    return val
end

-- Save current window state to config
function Aurora.ConfigManager:Save(name, window, metadata)
    if not name or name == "" then return false, "Invalid config name" end
    
    local folder = self:_ensureFolder(window._title)
    local path = self:_getPath(name, window._title)
    
    local values = {}
    
    -- Iterate through all tracked elements
    for tabName, elements in pairs(window._configElements or {}) do
        values[tabName] = {}
        for elementName, element in pairs(elements) do
            if element and element.GetValue then
                local ok, val = pcall(element.GetValue)
                if ok then
                    values[tabName][elementName] = SerializeValue(val)
                end
            end
        end
    end
    
    local data = {
        version = "6.5.0",
        created = os.time(),
        modified = os.time(),
        metadata = metadata or {},
        values = values,
    }
    
    local ok, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)
    
    if not ok then
        return false, "Failed to encode: " .. tostring(encoded)
    end
    
    writefile(path, encoded)
    return true, nil
end

-- Load config and apply to window
function Aurora.ConfigManager:Load(name, window)
    if not name or name == "" then return false, "Invalid config name" end
    
    local path = self:_getPath(name, window._title)
    if not isfile(path) then
        return false, "Config not found"
    end
    
    local ok, data = pcall(function()
        local content = readfile(path)
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    
    if not ok then
        return false, "Failed to decode: " .. tostring(data)
    end
    
    -- Apply values
    for tabName, elements in pairs(data.values or {}) do
        local tabElements = window._configElements and window._configElements[tabName]
        if tabElements then
            for elementName, savedVal in pairs(elements) do
                local element = tabElements[elementName]
                if element and element.SetValue then
                    local val = DeserializeValue(savedVal)
                    pcall(function() element.SetValue(val) end)
                end
            end
        end
    end
    
    return true, data
end

-- Delete a config
function Aurora.ConfigManager:Delete(name, windowTitle)
    local path = self:_getPath(name, windowTitle)
    if isfile(path) then
        delfile(path)
        return true
    end
    return false
end

-- List all configs for a window
function Aurora.ConfigManager:List(windowTitle)
    local folder = self._folder .. "/" .. SanitizeFilename(windowTitle or "Default")
    if not isfolder(folder) then
        return {}
    end
    
    local configs = {}
    for _, file in ipairs(listfiles(folder)) do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    
    table.sort(configs)
    return configs
end

-- Export config as JSON string
function Aurora.ConfigManager:Export(name, windowTitle)
    local path = self:_getPath(name, windowTitle)
    if not isfile(path) then
        return nil
    end
    return readfile(path)
end

-- Import config from JSON string
function Aurora.ConfigManager:Import(name, dataStr, windowTitle)
    if not name or name == "" then return false, "Invalid config name" end
    
    local ok, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(dataStr)
    end)
    
    if not ok then
        return false, "Invalid JSON: " .. tostring(data)
    end
    
    -- Validate structure
    if type(data.values) ~= "table" then
        return false, "Invalid config structure"
    end
    
    local folder = self:_ensureFolder(windowTitle)
    local path = self:_getPath(name, windowTitle)
    
    data.modified = os.time()
    if not data.created then data.created = os.time() end
    
    local ok2, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)
    
    if not ok2 then
        return false, "Failed to encode: " .. tostring(encoded)
    end
    
    writefile(path, encoded)
    return true, nil
end

-- Enable auto-save at interval (seconds)
function Aurora.ConfigManager:EnableAutoSave(interval, window, configName)
    if self._autoSaveConn then
        self._autoSaveConn:Disconnect()
        self._autoSaveConn = nil
    end
    
    if not interval or interval <= 0 then return end
    
    self._autoSaveConn = task.spawn(function()
        while true do
            task.wait(interval)
            if window and window._configElements and configName then
                self:Save(configName, window)
            end
        end
    end)
end

-- Get last loaded/saved config
function Aurora.ConfigManager:GetLastConfig(windowTitle)
    local path = self:_getPath("__last", windowTitle)
    if isfile(path) then
        return readfile(path)
    end
    return nil
end

-- Set last loaded/saved config
function Aurora.ConfigManager:SetLastConfig(windowTitle, configName)
    local folder = self:_ensureFolder(windowTitle)
    local path = self:_getPath("__last", windowTitle)
    writefile(path, configName)
end

return Aurora
