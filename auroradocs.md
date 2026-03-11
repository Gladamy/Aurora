# Aurora UI Library
**Version 6.5.0** — A minimalistic, production-quality UI library for Roblox executors.

---

## Quick Start

```lua
local Aurora = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Gladamy/Aurora/refs/heads/main/Aurora.lua"
))()

local Window = Aurora:CreateWindow({ Title = "My Script" })
local Tab    = Window:CreateTab({ Name = "Main" })

Tab:CreateToggle({
    Text     = "God Mode",
    Default  = false,
    Callback = function(enabled)
        -- your logic here
    end,
})
```

---

## Aurora

### `Aurora:CreateWindow(config) → Window`

Creates and opens a new UI window.

| Field | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"Aurora"` | Text shown in the title bar |
| `Size` | UDim2 | `{0,620,0,420}` | Window size |
| `Position` | UDim2 | Screen center | Initial position |

```lua
local Window = Aurora:CreateWindow({
    Title    = "Aurora",
    Size     = UDim2.new(0, 640, 0, 440),
    Position = UDim2.new(0.5, -320, 0.5, -220),
})
```

---

### `Aurora:Notify(config)`

Displays a toast notification in the bottom-right corner. Multiple notifications stack automatically and reflow when one expires.

| Field | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"Notification"` | Bold header text |
| `Message` | string | `""` | Body text (wraps) |
| `Type` | string | `"Info"` | `"Info"` `"Success"` `"Warning"` `"Error"` |
| `Duration` | number | `3` | Seconds before dismissal |

```lua
Aurora:Notify({
    Title    = "Success",
    Message  = "ESP enabled.",
    Type     = "Success",
    Duration = 3,
})
```

---

### `Aurora:SetTheme(newTheme)`

Overrides one or more theme colours. Only affects elements created **after** the call.

```lua
Aurora:SetTheme({
    Primary = Color3.fromRGB(220, 60, 60),
    Glow    = Color3.fromRGB(220, 60, 60),
})
```

**Available keys:** `Primary` `Secondary` `Background` `Surface` `Text` `TextMuted` `Success` `Warning` `Error` `Border` `Glow`

---

## Window

### `Window:CreateTab(config) → Tab`

| Field | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Tab"` | Label shown in sidebar |
| `Icon` | string | `""` | Optional rbxassetid image URL |

```lua
local Tab = Window:CreateTab({ Name = "Visuals", Icon = "rbxassetid://123456" })
```

### `Window:SelectTab(index)`

Programmatically switches to a tab by its creation order (1-based).

```lua
Window:SelectTab(2)  -- switch to the second tab
```

### `Window:Destroy()`

Closes the UI, disconnects all connections, and destroys the ScreenGui.

```lua
Window:Destroy()
```

### `Window.OnTabChanged` *(Signal)*

Fires whenever the active tab changes.

```lua
Window.OnTabChanged:Connect(function(newTab, oldTab)
    print("Switched to:", newTab.Button.Name)
end)
```

---

## Tab

All element-creation methods return an **element object** with at minimum:

| Method | Description |
|---|---|
| `element.GetValue()` | Returns the current value |
| `element.SetValue(val)` | Sets the value and syncs the UI |
| `element.Destroy()` | Removes the element from the UI and the Elements list |
| `element.SetVisible(bool)` | Shows or hides the element without removing it |
| `element.SetEnabled(bool)` | Enables or disables interaction (dims when false) |
| `element.OnChanged` | Signal that fires when the value changes |

---

### `Tab:CreateButton(config) → element`

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Button"` |
| `Callback` | function | `nil` |

**Extra methods:** `element.SetText(string)`

```lua
local btn = Tab:CreateButton({
    Text     = "Teleport",
    Callback = function()
        game.Players.LocalPlayer.Character:MoveTo(Vector3.new(0, 10, 0))
    end,
})

btn.SetText("Teleport (ready)")
```

---

### `Tab:CreateToggle(config) → element`

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Toggle"` |
| `Default` | boolean | `false` |
| `Callback` | function(bool) | `nil` |

```lua
local toggle = Tab:CreateToggle({
    Text     = "ESP",
    Default  = false,
    Callback = function(enabled)
        ESP.Enabled = enabled
    end,
})

-- Programmatically:
toggle.SetValue(true)
print(toggle.GetValue())  -- true
```

---

### `Tab:CreateSlider(config) → element`

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Slider"` |
| `Min` | number | `0` |
| `Max` | number | `100` |
| `Default` | number | `Min` |
| `Increment` | number | `1` |
| `Callback` | function(number) | `nil` |

```lua
local slider = Tab:CreateSlider({
    Text      = "Walk Speed",
    Min       = 16,
    Max       = 200,
    Default   = 16,
    Increment = 1,
    Callback  = function(val)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end,
})

slider.SetValue(100)
print(slider.GetValue())  -- 100
```

---

### `Tab:CreateDropdown(config) → element`

Single-selection dropdown. Best for short lists (under ~12 options). For longer lists use `CreateSearchDropdown`.

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Dropdown"` |
| `Options` | table (array of strings) | `{}` |
| `Default` | string | `"Select..."` |
| `Callback` | function(string) | `nil` |

```lua
local drop = Tab:CreateDropdown({
    Text     = "Gamemode",
    Options  = { "Classic", "Ranked", "Casual" },
    Default  = "Classic",
    Callback = function(val)
        print("Selected:", val)
    end,
})

drop.SetValue("Ranked")
print(drop.GetValue())  -- "Ranked"
```

---

### `Tab:CreateSearchDropdown(config) → element`

Dropdown with a live search/filter input. Ideal for lists with many options (players, items, etc.). Options are hidden as you type; the list scrolls if results exceed `MaxVisible`.

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Search"` |
| `Options` | table (array of strings) | `{}` |
| `Default` | string | `"Select..."` |
| `MaxVisible` | number | `6` |
| `Callback` | function(string) | `nil` |

```lua
local playerList = {}
for _, p in ipairs(game.Players:GetPlayers()) do
    table.insert(playerList, p.Name)
end

local search = Tab:CreateSearchDropdown({
    Text       = "Target Player",
    Options    = playerList,
    MaxVisible = 5,
    Callback   = function(name)
        print("Targeting:", name)
    end,
})
```

---

### `Tab:CreateMultiSelect(config) → element`

Dropdown where multiple options can be selected simultaneously. Each row has a checkbox. The header summarises the selection count.

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Select"` |
| `Options` | table (array of strings) | `{}` |
| `Default` | table (array of strings) | `{}` |
| `Callback` | function(table) | `nil` |

**Extra methods:** `element.IsSelected(optionString) → bool`

`GetValue()` returns an **array** of currently selected strings.
`SetValue()` accepts an **array** of strings.

```lua
local multi = Tab:CreateMultiSelect({
    Text     = "ESP Categories",
    Options  = { "Players", "NPCs", "Items", "Vehicles" },
    Default  = { "Players" },
    Callback = function(selected)
        print("Selected:", table.concat(selected, ", "))
    end,
})

multi.SetValue({ "Players", "Items" })
print(multi.IsSelected("Players"))   -- true
print(multi.IsSelected("Vehicles"))  -- false
print(multi.GetValue())              -- { "Players", "Items" }
```

---

### `Tab:CreateInput(config) → element`

Text input field. Callback fires when Enter is pressed.

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Input"` |
| `Placeholder` | string | `"Type here..."` |
| `Callback` | function(string) | `nil` |

```lua
local input = Tab:CreateInput({
    Text        = "Server IP",
    Placeholder = "192.168.x.x",
    Callback    = function(val)
        Connect(val)
    end,
})

input.SetValue("127.0.0.1")
print(input.GetValue())
```

---

### `Tab:CreateNumberInput(config) → element`

A numeric stepper with `−` / `+` buttons and a typed fallback. Clamps to `[Min, Max]` and snaps to `Step`. Invalid typed input reverts to the last valid value.

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Number"` |
| `Min` | number | `-math.huge` |
| `Max` | number | `math.huge` |
| `Step` | number | `1` |
| `Default` | number | `0` |
| `Callback` | function(number) | `nil` |

```lua
local numInput = Tab:CreateNumberInput({
    Text    = "Jump Power",
    Min     = 0,
    Max     = 1000,
    Step    = 10,
    Default = 50,
    Callback = function(val)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = val
    end,
})

numInput.SetValue(150)
print(numInput.GetValue())  -- 150
```

---

### `Tab:CreateKeybind(config) → element`

A keybind capture button. Click it to enter listening mode, press any key to bind. Click again or click elsewhere to cancel.

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Keybind"` |
| `Default` | Enum.KeyCode | `Enum.KeyCode.Unknown` |
| `Callback` | function(KeyCode) | `nil` |

`GetValue()` returns an `Enum.KeyCode`.
`SetValue()` accepts an `Enum.KeyCode`.

```lua
local kb = Tab:CreateKeybind({
    Text     = "Open Menu",
    Default  = Enum.KeyCode.RightShift,
    Callback = function(key)
        print("Bound to:", key.Name)
    end,
})

-- Listen for the bind at runtime:
UserInputService.InputBegan:Connect(function(inp, processed)
    if not processed and inp.KeyCode == kb.GetValue() then
        Window.MainFrame.Visible = not Window.MainFrame.Visible
    end
end)
```

---

### `Tab:CreateColorPicker(config) → element`

An inline color picker. Click the preview swatch to expand. Drag the saturation/value pad, drag the hue bar, or type a hex code directly.

| Field | Type | Default |
|---|---|---|
| `Text` | string | `"Color"` |
| `Default` | Color3 | `Color3.new(1,1,1)` |
| `Callback` | function(Color3) | `nil` |

`GetValue()` returns a `Color3`.
`SetValue()` accepts a `Color3`.

```lua
local picker = Tab:CreateColorPicker({
    Text    = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        ESP.Color = color
    end,
})

picker.SetValue(Color3.fromRGB(0, 255, 0))
print(picker.GetValue())
```

---

### `Tab:CreateTable(config) → element`

Displays a scrollable, striped data table with a coloured header row. Rows are clickable. Best for player lists, leaderboards, logs, item inventories, or any structured data.

| Field | Type | Default | Description |
|---|---|---|---|
| `Columns` | table (strings) | `{"Column 1","Column 2"}` | Header labels |
| `Rows` | table (array of arrays) | `{}` | Initial row data |
| `MaxVisible` | number | `6` | Max rows before scroll |

**Extra methods:**

| Method | Description |
|---|---|
| `element.AddRow(rowData)` | Append one row (array of values) |
| `element.SetRows(rows)` | Replace all rows at once (also clears row colours) |
| `element.RemoveRow(index)` | Remove row by 1-based index, re-renders |
| `element.SetCell(row, col, value)` | Update a single cell without full re-render |
| `element.SetRowColor(index, Color3)` | Highlight a row with a custom colour; persists across hover |
| `element.ClearRowColor(index)` | Remove a custom colour, restore default even/odd |
| `element.Clear()` | Remove all rows (also clears row colours) |
| `element.GetRows()` | Returns a shallow copy of the current rows |
| `element.OnRowClicked` | Signal — fires `(rowIndex, rowData)` on click |

```lua
local tbl = Tab:CreateTable({
    Columns    = { "Player", "Kills", "Deaths", "Ping" },
    MaxVisible = 8,
})

for _, p in ipairs(game.Players:GetPlayers()) do
    tbl.AddRow({ p.Name, 0, 0, math.round(p:GetNetworkPing() * 1000) .. "ms" })
end

tbl.OnRowClicked:Connect(function(index, row)
    print("Clicked row", index, "— player:", row[1])
end)

-- Highlight row 2 in a rarity colour
tbl.SetRowColor(2, Color3.fromRGB(255, 165, 0))

-- Remove the highlight
tbl.ClearRowColor(2)

-- Update a single cell
tbl.SetCell(1, 2, 7)
```

---

### `Tab:CreateProgressBar(config) → element`

A horizontal progress bar with a percentage label. Value is always in the `0..1` range.

| Field | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Progress"` | Left label |
| `Default` | number | `0` | Initial value (0..1) |
| `Color` | Color3 | `Theme.Primary` | Fill colour |

**Extra methods:**

| Method | Description |
|---|---|
| `element.SetValue(pct)` | Update bar (0..1), tweens smoothly |
| `element.SetLabel(string)` | Update the left text label |
| `element.SetColor(Color3)` | Change the fill colour live |

```lua
local bar = Tab:CreateProgressBar({
    Text    = "Weight",
    Default = 0,
    Color   = Color3.fromRGB(46, 204, 113),
})

-- Update from your loop
local total   = getCurrentWeight()
local target  = getTargetWeight()
bar.SetValue(math.clamp(total / target, 0, 1))
bar.SetLabel(string.format("Weight  %.2f / %.2f kg", total, target))
```

---

### `Tab:CreateStatusLabel(config) → element`

A single-line label with a coloured dot and typed text colour. Designed for status lines that change type (Info / Success / Warning / Error) at runtime.

| Field | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `""` | Initial text |
| `Type` | string | `"Info"` | `"Info"` · `"Success"` · `"Warning"` · `"Error"` |

**Extra methods:**

| Method | Description |
|---|---|
| `element.SetValue(text, type?)` | Update text and optionally the type in one call |
| `element.SetText(string)` | Update text only |
| `element.SetType(string)` | Change type (updates dot + text colour) |

```lua
local status = Tab:CreateStatusLabel({ Text = "Idle.", Type = "Info" })

-- In your loop:
status.SetValue("Auto running…", "Success")

-- On error:
status.SetValue("Remote failed — retrying.", "Warning")

-- When stopped:
status.SetValue("Stopped.", "Error")
```

---

A read-only text label in the muted colour. Useful for descriptions or status messages.

**Extra methods:** `element.SetText(string)` · `element.GetValue()` · `element.SetValue(string)`

```lua
local lbl = Tab:CreateLabel("Script loaded successfully.")
lbl.SetText("Connected to server.")
print(lbl.GetValue())  -- "Connected to server."
```

---

### `Tab:CreateSection(text) → element`

A visual section divider with an uppercase header and a border line underneath.

```lua
Tab:CreateSection("Combat")
Tab:CreateToggle({ Text = "Silent Aim", ... })

Tab:CreateSection("Movement")
Tab:CreateSlider({ Text = "Speed", ... })
```

---

## Element API Reference

Every element returned by any `Tab:Create*` method exposes the following in addition to its own fields:

```lua
element.GetValue()          -- returns current value
element.SetValue(val)       -- sets value and syncs UI
element.OnChanged           -- Signal: fires on any value change
element.Destroy()           -- removes element from UI and Elements list
element.SetVisible(bool)    -- show/hide without destroying
element.SetEnabled(bool)    -- enable/disable (dims and blocks input when false)
element.Frame               -- the root GuiObject instance
```

### `SetEnabled` example — disabling dependents

```lua
local espToggle = Tab:CreateToggle({ Text = "ESP", Default = false })
local colorPicker = Tab:CreateColorPicker({ Text = "ESP Color" })
local espSlider   = Tab:CreateSlider({ Text = "ESP Range", Min = 0, Max = 1000 })

-- Start disabled
colorPicker.SetEnabled(false)
espSlider.SetEnabled(false)

espToggle.OnChanged:Connect(function(on)
    colorPicker.SetEnabled(on)
    espSlider.SetEnabled(on)
end)
```

### `SetVisible` example — conditional elements

```lua
local modeLabel = Tab:CreateLabel("Advanced mode active.")
modeLabel.SetVisible(false)

Tab:CreateToggle({
    Text     = "Advanced Mode",
    Callback = function(on)
        modeLabel.SetVisible(on)
    end,
})
```

---

## Signal API

Signals are returned on `OnChanged` (all elements) and `Window.OnTabChanged`.

```lua
-- Connect — fires every time
local conn = element.OnChanged:Connect(function(val)
    print("Value changed:", val)
end)
conn.Disconnect()  -- stop listening

-- Once — fires exactly once then auto-disconnects
local handle = element.OnChanged:Once(function(val)
    print("First change only:", val)
end)
handle.Disconnect()  -- cancel before it fires (optional)
```

`Signal:Once` is useful for "wait for the next event then act" patterns:

```lua
-- Buy seeds the moment the shop next restocks, then stop
shopRestockSignal:Once(function()
    buyAllSeeds()
end)
```

---

## Full Example

```lua
local Aurora = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Gladamy/Aurora/refs/heads/main/Aurora.lua"
))()

local Window = Aurora:CreateWindow({ Title = "MyScript v1.0" })

-- ── Combat ─────────────────────────────────
local Combat = Window:CreateTab({ Name = "Combat" })

Combat:CreateSection("Aimbot")

local silentAim = Combat:CreateToggle({
    Text     = "Silent Aim",
    Default  = false,
    Callback = function(on) Aimbot.Silent = on end,
})

local fovSlider = Combat:CreateSlider({
    Text      = "FOV",
    Min       = 1,
    Max       = 360,
    Default   = 90,
    Increment = 1,
    Callback  = function(val) Aimbot.FOV = val end,
})

-- Disable FOV slider when silent aim is off
fovSlider.SetEnabled(false)
silentAim.OnChanged:Connect(function(on)
    fovSlider.SetEnabled(on)
end)

Combat:CreateSection("Hitbox")
Combat:CreateNumberInput({
    Text     = "Hitbox Size",
    Min      = 1,
    Max      = 50,
    Step     = 1,
    Default  = 5,
    Callback = function(val) Hitbox.Size = val end,
})

-- ── Visuals ─────────────────────────────────
local Visuals = Window:CreateTab({ Name = "Visuals" })

Visuals:CreateSection("ESP")

local espToggle = Visuals:CreateToggle({ Text = "Enable ESP", Default = false })
local espColor  = Visuals:CreateColorPicker({ Text = "ESP Color", Default = Color3.fromRGB(255,0,0) })
local espCats   = Visuals:CreateMultiSelect({
    Text    = "Categories",
    Options = { "Players", "NPCs", "Items" },
    Default = { "Players" },
})

espColor.SetEnabled(false)
espCats.SetEnabled(false)

espToggle.OnChanged:Connect(function(on)
    espColor.SetEnabled(on)
    espCats.SetEnabled(on)
    ESP.Enabled = on
end)
espColor.OnChanged:Connect(function(c) ESP.Color = c end)

-- ── Settings ────────────────────────────────
local Settings = Window:CreateTab({ Name = "Settings" })

Settings:CreateSection("Keybinds")
Settings:CreateKeybind({
    Text    = "Toggle Menu",
    Default = Enum.KeyCode.RightShift,
    Callback = function(key)
        Aurora:Notify({ Title = "Keybind", Message = "Menu → " .. key.Name, Type = "Info" })
    end,
})

Settings:CreateSection("Theme")
Settings:CreateDropdown({
    Text    = "Accent",
    Options = { "Indigo", "Red", "Green", "Orange" },
    Default = "Indigo",
    Callback = function(val)
        local map = {
            Indigo = Color3.fromRGB(88,101,242),
            Red    = Color3.fromRGB(231,76,60),
            Green  = Color3.fromRGB(46,204,113),
            Orange = Color3.fromRGB(230,126,34),
        }
        Aurora:SetTheme({ Primary = map[val], Glow = map[val] })
    end,
})
```

---

---

## Troubleshooting

### UI doesn't appear after running the script

**Cause:** Your executor cached the old version of `Aurora.lua` from a previous `HttpGet` call.

**Fix:** Wait 30–60 seconds and re-run. Some executors cache HTTP responses aggressively. If it still fails, try appending a cache-busting query string:

```lua
local url = "https://raw.githubusercontent.com/Gladamy/Aurora/refs/heads/main/Aurora.lua"
local Aurora = loadstring(game:HttpGet(url .. "?v=" .. os.time()))()
```

---

### `attempt to index nil with 'Destroy'` (or any method)

**Cause:** Lua 5.1 scoping — a local variable used inside its own initializer closure is `nil` at capture time.

```lua
-- WRONG: tempBtn is nil inside the callback
local tempBtn = Tab:CreateButton({
    Callback = function() tempBtn.Destroy() end
})

-- CORRECT: declare first, assign second
local tempBtn
tempBtn = Tab:CreateButton({
    Callback = function() tempBtn.Destroy() end
})
```

---

### `attempt to index nil with 'X'` on a Signal or element method

**Cause:** You're calling the method with `:` (colon) instead of `.` (dot). Aurora element methods are plain functions stored as fields, not Lua methods.

```lua
-- WRONG
element:SetValue(true)
element:GetValue()

-- CORRECT
element.SetValue(true)
element.GetValue()
```

---

### Notifications overlap instead of stacking

**Cause:** Two separate scripts both loaded Aurora independently, creating two separate `notifQueue` tables.

**Fix:** Load Aurora once and share the reference:

```lua
-- In your main loader
_G.Aurora = loadstring(game:HttpGet(url))()

-- In other modules
local Aurora = _G.Aurora
```

---

### Window opens then immediately closes / flickers

**Cause:** `ResetOnSpawn` is `false` by default on the ScreenGui — but if your character respawns during the open animation the LocalPlayer's PlayerGui can momentarily reset depending on executor behaviour.

**Fix:** Wrap your init in `task.defer` to let the character finish loading:

```lua
task.defer(function()
    local Aurora = loadstring(game:HttpGet(url))()
    local Window = Aurora:CreateWindow({ Title = "My Script" })
    -- ...
end)
```

---

### `SetEnabled` doesn't visually update an element I built manually

**Cause:** `SetEnabled` only dims `TextLabel`, `TextButton`, and `TextBox` descendants. If you added a raw `Frame` with no text children, it won't visually change — only the overlay blocks input.

**Fix:** Add a `TextLabel` inside your custom frame, or call `element.SetVisible(false)` instead if you want it fully hidden.

---

### ColorPicker shows a white/grey box instead of a gradient

**Cause:** The hue `UIGradient` has 7 keypoints — older executors that don't fully support `UIGradient` on `Frame` instances will fall back to the `BackgroundColor3`.

**Fix:** No workaround needed for up-to-date executors (Synapse X, KRNL, Fluxus all support it). If you're on a stripped executor, the picker still functions — it just loses the rainbow bar visual.

---

### HTTP 403 / failed to load

**Cause:** The repository is private, or the raw URL has changed.

**Fix:** Ensure the repo is public and the branch name in the URL matches (`main` vs `master`). Test the URL directly in a browser first.

---

## Changelog

| Version | Changes |
|---|---|
| 6.5.0 | **New:** `Tab:CreateProgressBar` · `Tab:CreateStatusLabel` · `CreateTable.SetRowColor` / `ClearRowColor` (with correct MouseLeave restore via per-row upvalue) · `Signal:Once` single-fire connections |
| 6.4.0 | `TabContainer` reflow connection stored in `windowConnections` |
| 6.2.0 | `element.Destroy()` disconnects owned UIS connections (Slider/Keybind/ColorPicker) · `MultiSelect` + `ColorPicker` register in `_dropdownCollapse` · `RegisterElement` accepts `ownedConns` |
| 6.1.0 | `Signal:Fire` warns on callback error · `SetEnabled` clears `_origColor` on re-enable · `SetEnabled(false)` auto-collapses open dropdowns · `CloseBtn` uses `AbsolutePosition`/`AbsoluteSize` · `CreateLabel`/`CreateSection` expose `GetValue`/`SetValue` |
| 6.0.0 | `CreateTable` with full row API · Auto-sizing sidebar · Troubleshooting docs |
| 5.0.0 | `SetVisible` + `SetEnabled` · `CreateSearchDropdown` · Signal ID collision fix |
| 4.0.0 | `CreateMultiSelect` · `CreateNumberInput` · empty state |
| 3.1.0 | `CreateColorPicker` rewritten with UIGradient |
| 3.0.0 | Signal system · `CreateColorPicker` · `CreateKeybind` · `Destroy` · `SelectTab` · `OnTabChanged` |
| 2.1.0 | `SelectTab` fixed · glyph control buttons |
| 2.0.0 | Global/memory leak fixes · `CreateInput` · notification queue |
| 1.0.0 | Initial release |

---

## Config System

Aurora supports automatic persistence of UI state across sessions. When enabled, all element values (toggles, sliders, dropdowns, etc.) are saved to a JSON file and restored when the script runs again.

### Quick Start

```lua
local Window = Aurora:CreateWindow({ Title = "My Script" })

-- Enable auto-save with default key
Window:EnableAutoSave()

-- Or specify a custom config key
Window:EnableAutoSave({
    Key = "MyScript_v1",
    AutoSave = true,  -- Save on every change (default: true)
})
```

### Window Methods

#### `Window:EnableAutoSave(config) → boolean`

Enables automatic saving/loading. Returns `true` if an existing config was loaded.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Key` | string | `"default"` | Unique identifier for this config |
| `AutoSave` | boolean | `true` | Save automatically when values change |
| `Exclude` | table | `{}` | Array of element ConfigIds to skip |

```lua
-- Load existing or create new
local wasLoaded = Window:EnableAutoSave({ Key = "CombatSettings" })
if wasLoaded then
    Aurora:Notify({ Title = "Config Loaded", Type = "Success" })
end
```

#### `Window:SaveConfig(key) → boolean`

Manually save current state. If `key` is omitted, uses the key from `EnableAutoSave`.

```lua
Window:SaveConfig("Backup_" .. os.time())
```

#### `Window:LoadConfig(key) → boolean`

Manually load a config. Returns `true` if successful.

```lua
Window:LoadConfig("Backup_1234567890")
```

#### `Window:DeleteConfig(key) → boolean`

Delete a saved config file.

```lua
Window:DeleteConfig("old_config")
```

#### `Window:ListConfigs() → table`

Returns array of config names available in the folder.

```lua
local configs = Window:ListConfigs()
for _, name in ipairs(configs) do
    print("Found config: " .. name)
end
```

#### `Window:SetConfigFolder(path)`

Change the storage folder (default: `"AuroraConfigs"`).

```lua
Window:SetConfigFolder("MyScript/Configs")
```

### Element Config IDs

By default, elements are identified by their `Text` property. You can override this with `ConfigId`:

```lua
Tab:CreateToggle({
    Text = "God Mode",
    ConfigId = "god_mode_toggle",  -- Used in config file
    Default = false,
})
```

### Runtime-Only Elements

Some elements (like a "Run Script" toggle) shouldn't persist across sessions. Use `Persist = false`:

```lua
Tab:CreateToggle({
    Text = "Run Quests",
    Persist = false,  -- Never save this value
    Default = false,
})
```

### Config File Format

Configs are stored as JSON in the workspace folder:

```json
{
    "god_mode_toggle": {
        "type": "Toggle",
        "tab": "Main",
        "value": true
    },
    "walk_speed": {
        "type": "Slider",
        "tab": "Movement",
        "value": 32
    },
    "theme_color": {
        "type": "ColorPicker",
        "tab": "Settings",
        "value": { "__type": "Color3", "r": 1, "g": 0.5, "b": 0 }
    }
}
```

### Events

#### `Window.OnConfigLoaded`

Fired when a config is successfully loaded.

```lua
Window.OnConfigLoaded:Connect(function(key, data)
    print("Loaded config: " .. key)
end)
```

### Profile System Example

```lua
local profiles = { "PvP", "Farming", "Questing" }
local currentProfile = "PvP"

Tab:CreateDropdown({
    Text = "Profile",
    Options = profiles,
    Default = currentProfile,
    Callback = function(profile)
        Window:SaveConfig(currentProfile)
        Window:LoadConfig(profile)
        currentProfile = profile
    end,
})
```

### Supported Element Types

All element types support config persistence:

| Element | Value Type | Notes |
|---------|------------|-------|
| `Toggle` | `boolean` | |
| `Slider` | `number` | |
| `Dropdown` | `string` | Selected option |
| `SearchDropdown` | `string` | Selected option |
| `MultiSelect` | `table` | Array of selected strings |
| `Input` | `string` | Text content |
| `NumberInput` | `number` | |
| `Keybind` | `EnumItem` | Serialized as Enum.KeyCode |
| `ColorPicker` | `Color3` | RGB reconstruction |

### Manual Control

Disable auto-save and control saving manually:

```lua
Window:EnableAutoSave({
    Key = "Manual",
    AutoSave = false,
})

-- Save only on button press
Tab:CreateButton({
    Text = "Save Settings",
    Callback = function()
        Window:SaveConfig()
        Aurora:Notify({ Title = "Settings Saved!", Type = "Success" })
    end,
})
```

---

## v6.1 Bug Fix Details

### Signal:Fire error surfacing
Previously, if a callback connected to `OnChanged` or `Callback` threw an error, it was silently swallowed by `pcall`. This made debugging consumer code extremely difficult — callbacks could fail with no output. Now Aurora warns to the Roblox output with the error message and the source location.

```lua
-- This will now print a warning instead of failing silently:
myToggle.OnChanged:Connect(function(v)
    local _ = nil.foo  -- intentional error
end)
```

### SetEnabled: _origColor cleared on re-enable
When `SetEnabled(false)` is called, Aurora caches each text object's colour as an instance attribute (`_origColor`). Previously this was never cleared on re-enable, meaning if you disabled → re-enabled → changed theme → disabled → re-enabled again, the restored colour would be from the *first* disable cycle, not the current theme. The attribute is now cleared on re-enable so each new disable cycle always captures the fresh current colour.

### SetEnabled: auto-collapses open dropdowns
If a `CreateDropdown` or `CreateSearchDropdown` was open (expanded) when `SetEnabled(false)` was called, the popup would remain visible and interactive even though the element was supposed to be locked. Aurora now registers a collapse function for every dropdown in a weak-keyed table (`_dropdownCollapse`). `SetEnabled(false)` checks this table and collapses the dropdown before applying the overlay.

```lua
-- Safe: open the dropdown, then disable — it closes cleanly
myDropdown.SetEnabled(false)
```

### CloseBtn: correct collapse-to-centre after dragging
The close animation previously calculated the window centre using `Position.X.Offset + size.X.Offset / 2`. This is incorrect after the window has been dragged, because `Position` is the *current* runtime position not the *original* position, and mixing Scale/Offset components produced off-screen collapse targets. Now uses `AbsolutePosition` and `AbsoluteSize` which are always the true screen-space values regardless of where the window sits.

### CreateLabel / CreateSection: full element API
`CreateLabel` and `CreateSection` previously only exposed `SetText`, breaking the uniform API contract that all elements share `GetValue` / `SetValue`. Both now expose all three:

```lua
local lbl = Tab:CreateLabel("Hello")
lbl.GetValue()        -- → "Hello"
lbl.SetValue("World") -- updates text
lbl.SetText("World")  -- alias, identical behaviour

local sec = Tab:CreateSection("Settings")
sec.GetValue()            -- → "SETTINGS" (auto-uppercased)
sec.SetValue("Advanced")  -- → displays "ADVANCED"