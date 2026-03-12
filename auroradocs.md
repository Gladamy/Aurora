# Aurora UI Library — v7.0 Developer Reference

> A Roblox Lua UI library for building in-game script interfaces.  
> Single-file distributable · 16 element types · Full config persistence · Zero global pollution

---

## Table of Contents

1. [Loading Aurora](#1-loading-aurora)
2. [Aurora (top-level API)](#2-aurora-top-level-api)
3. [Window](#3-window)
4. [Tab](#4-tab)
5. [Elements — common API](#5-elements--common-api)
6. [Elements — reference](#6-elements--reference)
   - [Button](#button)
   - [Toggle](#toggle)
   - [Slider](#slider)
   - [Dropdown](#dropdown)
   - [SearchDropdown](#searchdropdown)
   - [MultiSelect](#multiselect)
   - [Input](#input)
   - [NumberInput](#numberinput)
   - [Keybind](#keybind)
   - [ColorPicker](#colorpicker)
   - [Label](#label)
   - [Section](#section)
   - [ProgressBar](#progressbar)
   - [StatusLabel](#statuslabel)
   - [Table](#table)
   - [Row](#row)
7. [Notifications](#7-notifications)
8. [Themes & Config](#8-themes--config)
9. [Config System](#9-config-system)
10. [Signal](#10-signal)
11. [Internals & Architecture](#11-internals--architecture)
12. [Build System](#12-build-system)

---

## 1. Loading Aurora

```lua
local Aurora = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YourRepo/Aurora/main/Aurora.lua"
))()
```

Aurora returns a single table. No globals are set. Everything lives under the returned object.

---

## 2. Aurora (top-level API)

```lua
Aurora:CreateWindow(config)   -- creates and opens a new window
Aurora:Notify(cfg)            -- shared singleton notification
Aurora:SetTheme(theme)        -- patch theme colours at runtime
Aurora:CreateConfig(options)  -- create a config persistence object
Aurora.Config                 -- read-only access to current Config table
```

### `Aurora:CreateWindow(config)`

| Key | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"Aurora"` | Text shown in the title bar |
| `Size` | UDim2 | `UDim2.new(0, 620, 0, 420)` | Initial window size |
| `Position` | UDim2 | Centred on screen | Initial position |

Returns a [Window](#3-window) object.

```lua
local win = Aurora:CreateWindow({
    Title    = "My Script",
    Size     = UDim2.new(0, 680, 0, 520),
    Position = UDim2.new(0.5, -340, 0.5, -260),
})
```

### `Aurora:Notify(cfg)`

Shows a toast notification using the shared singleton layer. See [Notifications](#7-notifications) for the full `cfg` reference.

### `Aurora:SetTheme(theme)`

Patches one or more theme colour keys. **Only affects elements created after the call.** Silently ignores unknown keys.

```lua
Aurora:SetTheme({
    Primary = Color3.fromRGB(255, 80, 80),
    Success = Color3.fromRGB(0, 220, 100),
})
```

Valid keys: `Primary`, `Secondary`, `Background`, `Surface`, `Text`, `TextMuted`, `Success`, `Warning`, `Error`, `Border`, `Glow`.

### `Aurora:CreateConfig(options)`

See [Config System](#9-config-system).

### `Aurora.Config`

Direct reference to the internal Config table. Useful for reading animation settings or theme values at runtime.

```lua
print(Aurora.Config.Theme.Primary)
print(Aurora.Config.Animation.Duration)   -- default 0.3
print(Aurora.Config.Animation.Easing)     -- default Enum.EasingStyle.Quart
```

---

## 3. Window

### Properties

| Property | Type | Description |
|---|---|---|
| `ScreenGui` | ScreenGui | The ScreenGui instance parented to PlayerGui |
| `MainFrame` | Frame | The outermost draggable frame |
| `TabContainer` | Frame | The sidebar that holds tab buttons |
| `ContentContainer` | Frame | The right-hand panel that holds tab content |
| `Tabs` | Tab[] | Array of all tabs in creation order |
| `ActiveTab` | Tab | The currently visible tab |
| `OnTabChanged` | Signal | Fires `(newTab, oldTab)` when tabs switch |

### Methods

#### `Window:CreateTab(config)`

| Key | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Tab"` | Display name in the sidebar |
| `Icon` | string | `""` | Roblox asset ID string for a 16×16 icon shown left of the name. Leave empty for text-only. |

Returns a [Tab](#4-tab) object.

The first tab created is auto-activated. `OnTabChanged` does **not** fire for this initial activation.

```lua
local tab = win:CreateTab({ Name = "Settings", Icon = "rbxassetid://123456" })
```

#### `Window:SelectTab(index)`

Programmatically switch to a tab by its 1-based index in `Window.Tabs`.

```lua
win:SelectTab(2)   -- switches to the second tab
```

#### `Window:Notify(cfg)`

Shows a notification scoped to this window's own layer. Two windows can never corrupt each other's stacks. See [Notifications](#7-notifications).

#### `Window:Destroy()`

Tears down the entire window:
1. Disconnects all element-level connections across all tabs (via each element's ConnSet)
2. Disconnects window-level connections (drag, sidebar reflow)
3. Destroys the per-window notification layer if it was created
4. Destroys the ScreenGui (cascades to all children)

### Built-in controls

- **Close button (✕)** — animates the window to zero size, then calls `Window:Destroy()`
- **Minimise button (—)** — toggles the window height between `40px` (title bar only) and the original size, with a 0.3s tween
- **Drag** — the window is draggable by clicking and dragging the title bar

### Intro animation

The window opens with a Back/Out tween (`0.5s`) from the centre of its target position, expanding outward to its full size.

---

## 4. Tab

### Properties

| Property | Type | Description |
|---|---|---|
| `Name` | string | The tab's display name |
| `Button` | TextButton | The sidebar button instance |
| `Label` | TextLabel | The text label inside the sidebar button |
| `Content` | ScrollingFrame | The scrollable content area |
| `Elements` | Element[] | All elements registered to this tab |
| `OnElementAdded` | Signal | Fires with the element whenever a new element is registered |

### Methods

#### `Tab:Activate()`

Switches the window to this tab. Fires `Window.OnTabChanged` with `(self, previousTab)`. Does nothing if this tab is already active.

```lua
tab:Activate()
```

### Element constructors

All element constructors follow the pattern `Tab:Create*(cfg)` and return an element object. Every element automatically receives the [common element API](#5-elements--common-api).

| Constructor | Description |
|---|---|
| `Tab:CreateButton(cfg)` | Clickable button |
| `Tab:CreateToggle(cfg)` | On/off toggle switch |
| `Tab:CreateSlider(cfg)` | Draggable numeric slider |
| `Tab:CreateDropdown(cfg)` | Single-select expandable dropdown |
| `Tab:CreateSearchDropdown(cfg)` | Dropdown with live search filter |
| `Tab:CreateMultiSelect(cfg)` | Multi-option select with checkboxes |
| `Tab:CreateInput(cfg)` | Text input field |
| `Tab:CreateNumberInput(cfg)` | Numeric input with ± step buttons |
| `Tab:CreateKeybind(cfg)` | Key capture input |
| `Tab:CreateColorPicker(cfg)` | HSV + hex colour picker |
| `Tab:CreateLabel(cfg)` | Static or dynamic text label |
| `Tab:CreateSection(cfg)` | Visual section divider with line |
| `Tab:CreateProgressBar(cfg)` | 0–1 progress bar |
| `Tab:CreateStatusLabel(cfg)` | Coloured status pill with dot |
| `Tab:CreateTable(cfg)` | Scrollable data table |
| `Tab:CreateRow(cfg)` | Horizontal layout container |

### Empty state

When a tab has no elements, a greyed-out `"No elements yet."` placeholder is shown. It disappears automatically when the first element is added and reappears if all elements are destroyed.

### Scroll bar

The content area is a `ScrollingFrame` with `ScrollBarThickness = 3` and a `Border`-coloured scroll bar. It auto-sizes vertically to fit its contents.

---

## 5. Elements — common API

Every element returned by a `Tab:Create*` call exposes these members, regardless of type.

### Properties

| Property | Type | Description |
|---|---|---|
| `Frame` | Frame | The root Roblox instance for this element |
| `OnChanged` | Signal | Fires on user interaction. **Never fires** when `SetValue` is called (except Label, StatusLabel, ProgressBar — see individual docs) |

### Methods

| Method | Description |
|---|---|
| `element.GetValue()` | Returns the element's current value |
| `element.SetValue(v)` | Updates the element silently — never fires `Callback` or `OnChanged` |
| `element.SetEnabled(bool)` | Enable or disable. Disabled elements show a semi-transparent overlay and greyed text. Expandable elements (Dropdown, SearchDropdown, MultiSelect, ColorPicker) auto-collapse when disabled. |
| `element.SetVisible(bool)` | Show or hide the element's frame |
| `element.Destroy()` | Remove the element from the UI, disconnect all connections, and remove it from `Tab.Elements` |

### The SetValue contract

`SetValue` is **always** silent. It updates the display and internal state without triggering `Callback` or `OnChanged`. This is a hard guarantee used by the Config System to apply saved values at load time without causing circular save→load→save loops.

**Exceptions:** `ProgressBar`, `StatusLabel`, and `Label` have no user interaction — `SetValue` is the only meaningful change mechanism for them, so their `OnChanged` **does** fire on `SetValue`.

---

## 6. Elements — reference

---

### Button

```lua
local btn = tab:CreateButton({
    Text     = "Do Something",
    Callback = function() print("clicked") end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Button"` | Button label |
| `Callback` | function | nil | Called on click |

**Extra methods:**

| Method | Description |
|---|---|
| `btn.SetText(text)` | Update the button label |

**Behaviour:** Hover darkens the background. MouseButton1Down flashes Primary colour. MouseButton1Up reverts to hover colour.

`GetValue()` returns `nil` — buttons have no value state.  
`OnChanged` is not present — use `Callback`.

---

### Toggle

```lua
local tog = tab:CreateToggle({
    Text     = "Auto Farm",
    Default  = false,
    Callback = function(value) print("toggle:", value) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Toggle"` | Label text |
| `Default` | bool | `false` | Initial state |
| `Callback` | function | nil | Called with `(bool)` on user interaction |

**Values:** `GetValue()` returns `bool`. `SetValue(bool)` coerces to boolean.

```lua
tog.SetValue(true)           -- silent, no callback
tog.GetValue()               -- true
tog.OnChanged:Connect(function(v) print(v) end)
```

---

### Slider

```lua
local sld = tab:CreateSlider({
    Text      = "Speed",
    Min       = 0,
    Max       = 100,
    Default   = 16,
    Increment = 1,
    Callback  = function(value) print("speed:", value) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Slider"` | Label text |
| `Min` | number | `0` | Minimum value |
| `Max` | number | `100` | Maximum value |
| `Default` | number | `Min` | Initial value, clamped to [Min, Max] |
| `Increment` | number | `1` | Snap increment. Value is always `Min + n * Increment` |
| `Callback` | function | nil | Called with `(number)` on drag |

**Values:** `GetValue()` returns `number`. `SetValue(number)` clamps and snaps silently.

The value label to the right of the label shows the current value in `Primary` colour. The track background uses `Border` colour; the fill and knob use `Primary`.

---

### Dropdown

```lua
local dd = tab:CreateDropdown({
    Text     = "Mode",
    Options  = { "Passive", "Aggressive", "Stealth" },
    Default  = "Passive",
    Callback = function(value) print("mode:", value) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Dropdown"` | Label shown in the header |
| `Options` | string[] | `{}` | List of option strings |
| `Default` | string | `"Select..."` | Initially selected option |
| `Callback` | function | nil | Called with `(string)` on selection |

**Values:** `GetValue()` returns the selected string. `SetValue(string)` selects silently if the value exists in the options list. If the value is not in the list, nothing happens.

**Extra methods:**

| Method | Description |
|---|---|
| `dd.SetOptions(options)` | Replace the option list at runtime. Clears and rebuilds all option buttons. Preserves the selected value if it still exists in the new list; otherwise falls back to the first option. Collapses the dropdown. Does **not** fire `Callback` or `OnChanged`. |

```lua
dd.SetOptions({ "Easy", "Normal", "Hard" })
dd.SetValue("Normal")
```

**Behaviour:** Clicking the header toggles expand/collapse with a tween. Clicking an option selects it, updates the header text, collapses, and fires `Callback` + `OnChanged`. The expandable height is `36 + N * 30` where N is the option count.

---

### SearchDropdown

```lua
local sd = tab:CreateSearchDropdown({
    Text       = "Fruit",
    Options    = { "Apple", "Banana", "Cherry", "Durian" },
    Default    = "Apple",
    MaxVisible = 6,
    Callback   = function(value) print("fruit:", value) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Search"` | Label shown in the header |
| `Options` | string[] | `{}` | Full option list |
| `Default` | string | `"Select..."` | Initially selected option |
| `MaxVisible` | number | `6` | Maximum rows shown before scrolling |
| `Callback` | function | nil | Called with `(string)` on selection |

**Values:** Same as Dropdown — `GetValue()` returns string, `SetValue(string)` is silent.

**Behaviour:** When expanded, a search TextBox appears at the top. Typing filters the visible options in real time (case-insensitive substring match). Clicking an option selects it and collapses. The panel height is capped at `36 + MaxVisible * 30 + 36` (header + rows + search bar).

---

### MultiSelect

```lua
local ms = tab:CreateMultiSelect({
    Text     = "Rarities",
    Options  = { "Common", "Uncommon", "Rare", "Epic", "Legendary" },
    Default  = { "Rare", "Epic", "Legendary" },
    Callback = function(selected) print(table.concat(selected, ", ")) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Select"` | Label shown in the header |
| `Options` | string[] | `{}` | List of option strings |
| `Default` | string[] | `{}` | Array of initially selected options |
| `Callback` | function | nil | Called with `(string[])` — array of currently selected options in original order |

**Values:** `GetValue()` returns a `string[]` of selected options in the original `Options` order. `SetValue(string[])` replaces the entire selection silently.

**Extra methods:**

| Method | Description |
|---|---|
| `ms.IsSelected(option)` | Returns `true` if the given option string is currently selected |

**Header text behaviour:**
- 0 selected → `"Rarities: None"`
- 1 selected → `"Rarities: Rare"`
- 2+ selected → `"Rarities: 3 selected"`

---

### Input

```lua
local inp = tab:CreateInput({
    Text        = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback    = function(value) print("entered:", value) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Input"` | Small label above the text box |
| `Placeholder` | string | `"Type here..."` | Placeholder text shown when empty |
| `Callback` | function | nil | Called with `(string)` **only when Enter is pressed** (FocusLost with `enter = true`) |

**Values:** `GetValue()` returns the current text box string. `SetValue(string)` sets the text silently.

> **Note:** `Callback` and `OnChanged` only fire when the user presses Enter, not on every keystroke and not on focus loss without Enter.

---

### NumberInput

```lua
local ni = tab:CreateNumberInput({
    Text    = "Delay (ms)",
    Min     = 0,
    Max     = 10000,
    Step    = 100,
    Default = 500,
    Callback = function(value) print("delay:", value) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Number"` | Small label above the row |
| `Min` | number | `-math.huge` | Minimum value |
| `Max` | number | `math.huge` | Maximum value |
| `Step` | number | `1` | Step size for ± buttons and snap rounding |
| `Default` | number | `0` | Initial value, clamped and snapped |
| `Callback` | function | nil | Called with `(number)` on commit |

**Values:** `GetValue()` returns `number`. `SetValue(number)` clamps and snaps silently.

**Behaviour:** The element has a `−` button on the left, a `+` button on the right, and a TextBox in the middle. Clicking `−`/`+` steps by `Step`. Typing a value in the box and losing focus commits it (clamps + snaps). Invalid text (non-numeric) reverts to the last valid value.

---

### Keybind

```lua
local kb = tab:CreateKeybind({
    Text     = "Toggle Script",
    Default  = Enum.KeyCode.RightShift,
    Callback = function(keyCode) print("bound to:", keyCode.Name) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Keybind"` | Label text |
| `Default` | Enum.KeyCode | `Enum.KeyCode.Unknown` | Initial key. `Unknown` displays as `"None"` |
| `Callback` | function | nil | Called with `(Enum.KeyCode)` when a key is bound |

**Values:** `GetValue()` returns `Enum.KeyCode`. `SetValue(Enum.KeyCode)` sets the key silently.

**Behaviour:** Clicking the key button enters listening mode (`"..."` is shown, button turns Primary colour). Press any keyboard key to bind it. Clicking anywhere else while listening cancels and restores the previous key. The element manages its own UIS connection which is cleaned up on `Destroy`.

```lua
kb.SetValue(Enum.KeyCode.F5)
print(kb.GetValue().Name)   -- "F5"
```

---

### ColorPicker

```lua
local cp = tab:CreateColorPicker({
    Text     = "Beam Color",
    Default  = Color3.fromRGB(88, 101, 242),
    Callback = function(color) print(color) end,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Color"` | Label text |
| `Default` | Color3 | `Color3.new(1,1,1)` | Initial colour |
| `Callback` | function | nil | Called with `(Color3)` on user interaction |

**Values:** `GetValue()` returns `Color3`. `SetValue(Color3)` sets silently.

**Behaviour:** The header shows the label and a small colour preview swatch. Clicking expands a panel with an SV (saturation/value) gradient pad and a separate hue strip. A hex TextBox below the pads also accepts typed hex values (`#RRGGBB` or `RRGGBB`, case-insensitive). The four UIS drag connections live in the element's own ConnSet and are cleaned up on `Destroy`.

---

### Label

```lua
local lbl = tab:CreateLabel({ Text = "Status: Idle" })
-- or shorthand:
local lbl = tab:CreateLabel("Status: Idle")
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Label"` | Display text |

Both `{ Text = "..." }` and a plain string are accepted.

**Extra methods:**

| Method | Description |
|---|---|
| `lbl.SetText(text)` | Update the label text (does not fire `OnChanged`) |

**SetValue behaviour (exception):** `lbl.SetValue(text)` updates the label AND fires `OnChanged`. This is intentional — Label has no user interaction, so `SetValue` is the only change mechanism.

```lua
lbl.SetValue("Status: Running")   -- fires OnChanged
lbl.SetText("Status: Running")    -- silent, no OnChanged
lbl.GetValue()                    -- returns current text string
```

---

### Section

```lua
local sec = tab:CreateSection({ Text = "Combat Settings" })
-- or shorthand:
local sec = tab:CreateSection("Combat Settings")
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Section"` | Section heading text |

Both `{ Text = "..." }` and a plain string are accepted.

**Behaviour:** The text is rendered **in uppercase** automatically. A 1px `Border`-coloured line is drawn below the label. Height is `28px`. Background is transparent (no card).

**Extra methods:**

| Method | Description |
|---|---|
| `sec.SetText(text)` | Update heading (auto-uppercased) |
| `sec.SetValue(text)` | Same as SetText (auto-uppercased) |
| `sec.GetValue()` | Returns the current uppercased text |

---

### ProgressBar

```lua
local pb = tab:CreateProgressBar({
    Text    = "Loading Assets",
    Default = 0,
    Color   = Color3.fromRGB(46, 204, 113),
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"Progress"` | Label above the bar |
| `Default` | number | `0` | Initial value, clamped to [0, 1] |
| `Color` | Color3 | `Config.Theme.Primary` | Fill colour |

**Values:** `GetValue()` returns the current fraction (0–1). 

**SetValue behaviour (exception):** `pb.SetValue(number)` updates the bar, the percentage label, fires `OnChanged`, and tweens the fill width (0.2s). There is no user interaction — `SetValue` is the only change mechanism.

**Extra methods:**

| Method | Description |
|---|---|
| `pb.SetLabel(text)` | Update the text label above the bar |
| `pb.SetColor(Color3)` | Change the fill colour at runtime |

```lua
pb.SetValue(0.75)    -- shows 75%, fires OnChanged
pb.SetLabel("Downloading map...")
pb.SetColor(Color3.fromRGB(255, 200, 0))
```

---

### StatusLabel

```lua
local sl = tab:CreateStatusLabel({
    Text = "Connection established",
    Type = "Success",
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `""` | Status message |
| `Type` | string | `"Info"` | One of: `"Info"` · `"Success"` · `"Warning"` · `"Error"` |

Type colours:
- `Info` → `Primary`
- `Success` → `Success` (green)
- `Warning` → `Warning` (yellow)
- `Error` → `Error` (red)

**SetValue behaviour (exception):** `sl.SetValue(text, type?)` updates the text and optionally the type, then fires `OnChanged`. Both the dot and label text change colour.

**Extra methods:**

| Method | Description |
|---|---|
| `sl.SetText(text)` | Update text only (silent, no type change, no `OnChanged`) |
| `sl.SetType(type)` | Update type/colour only (updates dot and text colour) |

```lua
sl.SetValue("Disconnected", "Error")          -- fires OnChanged
sl.SetText("Reconnecting...")                 -- silent
sl.SetType("Warning")
sl.GetValue()                                 -- returns current text string
```

---

### Table

```lua
local tbl = tab:CreateTable({
    Columns    = { "Name", "Value", "Status" },
    Rows       = {
        { "Speed",   "50",   "Active" },
        { "Gravity", "196",  "Active" },
    },
    MaxVisible = 6,
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Columns` | string[] | `{ "Column 1", "Column 2" }` | Column header names. Determines column count. |
| `Rows` | string[][] | `{}` | Initial row data. Each row is a string array matching column count. |
| `MaxVisible` | number | `6` | Maximum rows shown before the table scrolls internally |

**Extra methods:**

| Method | Description |
|---|---|
| `tbl.SetRows(rows)` | Replace all rows at once. Accepts `string[][]`. |
| `tbl.AddRow(rowData)` | Append a single row (`string[]`) |
| `tbl.RemoveRow(index)` | Remove a row by 1-based index. Only re-renders rows after the removed index (not a full rebuild). |
| `tbl.SetCell(rowIndex, colIndex, value)` | Update a single cell by 1-based indices |
| `tbl.SetRowColor(index, Color3)` | Tint a row's background. Integrates with the per-row hover system — hover uses this colour as its base. |
| `tbl.ClearRowColor(index)` | Restore a row to the default background |

**Signals:**

| Signal | Description |
|---|---|
| `tbl.OnRowClicked` | Fires `(rowIndex, rowData)` when a row is clicked. `rowData` is the `string[]` for that row. |

```lua
tbl.OnRowClicked:Connect(function(index, row)
    print("clicked row", index, ":", row[1])
end)

tbl.AddRow({ "Jump Power", "50", "Inactive" })
tbl.SetCell(1, 3, "Inactive")
tbl.SetRowColor(2, Color3.fromRGB(50, 80, 50))
tbl.RemoveRow(1)
```

---

### Row

```lua
local row = tab:CreateRow({
    Columns = 2,
    Gap     = 6,
    Height  = 36,
})

row.Add(tab:CreateButton({ Text = "Start" }))
row.Add(tab:CreateToggle({ Text = "Loop" }))
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Columns` | number | `2` | Number of equal-width columns |
| `Gap` | number | `6` | Pixel gap between columns |
| `Height` | number | `36` | Fixed row height in pixels |

**Methods:**

| Method | Description |
|---|---|
| `row.Add(element)` | Reparents an element's frame into the row and resizes it to fill one column. The element remains in `Tab.Elements` and keeps its full API. |

**Destroy propagation:** `row.Destroy()` calls `Destroy()` on all child elements added via `row.Add()`, then destroys the row frame itself.

> **Warning:** Expandable elements (Dropdown, SearchDropdown, MultiSelect, ColorPicker) will clip their expanded panels at the row's fixed height. Use rows for flat elements like buttons, toggles, sliders, labels, and section headers only.

```lua
-- Three-column row example
local row = tab:CreateRow({ Columns = 3, Gap = 4, Height = 36 })
row.Add(tab:CreateButton({ Text = "A", Callback = function() end }))
row.Add(tab:CreateButton({ Text = "B", Callback = function() end }))
row.Add(tab:CreateButton({ Text = "C", Callback = function() end }))
```

---

## 7. Notifications

### Config

```lua
Aurora:Notify({
    Title    = "Done",
    Message  = "All seeds purchased.",
    Type     = "Success",
    Duration = 4,
})

-- Per-window scope:
win:Notify({
    Title   = "Shop",
    Message = "Item unavailable.",
    Type    = "Warning",
})
```

| Key | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"Notification"` | Bold heading text |
| `Message` | string | `""` | Body text (wraps) |
| `Type` | string | `"Info"` | One of: `"Info"` · `"Success"` · `"Warning"` · `"Error"` |
| `Duration` | number | `3` | Seconds before the toast auto-dismisses |

### Scoping

- **`Aurora:Notify()`** — uses a lazily-created shared singleton `ScreenGui` in `PlayerGui`. Re-created if the ScreenGui is destroyed (e.g. on character respawn). All calls from all scripts share one stack.
- **`win:Notify()`** — each window creates its own notification layer on first use. Multiple windows never interfere.

### Visual

Each toast is a `280 × 80px` frame:
- A 4px left accent bar in the type colour
- Title in `Text` colour (bold, 14px)
- Message in `TextMuted` colour (13px, wraps)
- A 2px progress bar at the bottom that depletes over `Duration` seconds (linear tween)

Toasts slide in from the right (Quart/Out, 0.4s) and slide out to the right (Quart/In, 0.35s). Remaining toasts reposition when one is dismissed (0.25s tween).

---

## 8. Themes & Config

### Default theme

| Key | Default RGB | Usage |
|---|---|---|
| `Primary` | `88, 101, 242` | Buttons, active tab, slider fill, toggle on, section headers, keybind button |
| `Secondary` | `30, 30, 35` | (reserved) |
| `Background` | `18, 18, 22` | Main window, element cards |
| `Surface` | `25, 25, 30` | Title bar, tab sidebar, content container, dropdown panels |
| `Text` | `245, 245, 250` | Primary readable text |
| `TextMuted` | `150, 150, 160` | Secondary text, placeholders, inactive tabs, label text |
| `Success` | `46, 204, 113` | Success notifications and status labels |
| `Warning` | `241, 196, 15` | Warning notifications and status labels |
| `Error` | `231, 76, 60` | Error notifications and status labels, close button |
| `Border` | `55, 55, 68` | Section lines, scroll bar, disabled overlay, slider track |
| `Glow` | `88, 101, 242` | Shadow tint under windows and notifications |

### Default animation

| Key | Value |
|---|---|
| `Duration` | `0.3` seconds |
| `Easing` | `Enum.EasingStyle.Quart` |
| `Direction` | `Enum.EasingDirection.Out` |

### Default fonts

| Key | Value |
|---|---|
| `Font` | `Enum.Font.Gotham` |
| `FontBold` | `Enum.Font.GothamBold` |
| `FontMedium` | `Enum.Font.GothamMedium` |
| `CornerRadius` | `UDim.new(0, 6)` |
| `ShadowTransparency` | `0.7` |

---

## 9. Config System

The config system persists element values to JSON files on disk using the executor's file API. It supports multiple named profiles, last-profile memory across sessions, import/export, and an optional built-in UI panel.

### Setup

```lua
local cfg = Aurora:CreateConfig({
    Name     = "GardenShovel",
    Folder   = "Aurora",
    AutoSave = true,
    AutoLoad = true,
})
```

### Options

| Key | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Config"` | Filename stem. Saved as `Name.json` for the default profile, `Name_pvp.json` for a "pvp" profile, etc. |
| `Folder` | string | `"Aurora"` | Subfolder in the executor workspace. Created automatically if missing. |
| `Profile` | string | `"default"` | Starting profile. Overridden by the last-profile sidecar if `AutoLoad = true`. |
| `AutoSave` | bool | `true` | Automatically saves to disk whenever any linked element fires `OnChanged`. |
| `AutoLoad` | bool | `true` | Reads the last-profile sidecar at creation time, switches to that profile, and loads its saved values into a cache **before** any `Link()` calls. |

### Linking elements

```lua
cfg:Link("Speed",     speedSlider)
cfg:Link("GodMode",   godModeToggle)
cfg:Link("Color",     colorPicker)
cfg:Link("Webhook",   webhookInput)

-- Chainable:
cfg:Link("A", elemA):Link("B", elemB):Link("C", elemC)
```

`Link(key, element)`:
1. Snapshots the element's current value as its reset default
2. Applies any cached saved value silently via `SetValue` (so `Callback` never fires on load)
3. Wires `element.OnChanged → doSave` if `AutoSave = true`

### Config object API

| Method / Signal | Description |
|---|---|
| `cfg:Link(key, element)` | Link an element. Returns `self` for chaining. |
| `cfg:Save()` | Manually write current values to disk. Returns `self`. |
| `cfg:Load()` | Manually read values from disk and apply via `SetValue`. Returns `true` if the file was found. |
| `cfg:Reset()` | Restore all elements to their `Link`-time defaults. Clears the save file. Returns `self`. |
| `cfg:Export()` | Serialise current values to a JSON string. |
| `cfg:Import(str)` | Deserialise and apply values from a JSON string. Saves if `AutoSave = true`. Returns `true` on success, `false` on invalid JSON. |
| `cfg:SetProfile(name)` | Switch to a named profile. Loads its values, saves the choice to the last-profile sidecar, fires `OnProfileChanged`. Returns `self`. |
| `cfg:GetProfile()` | Returns the active profile name as a string. |
| `cfg:ListProfiles()` | Returns `string[]` of all discovered profile names (requires `listfiles` executor API). Always includes `"default"`. |
| `cfg:RenameProfile(newName)` | Rename the active profile. Copies the save file to the new name, deletes the old file. Returns `false` if: name is taken, name is empty, active profile is `"default"`. |
| `cfg:DeleteProfile(name)` | Delete a profile file. Switches to `"default"` if the deleted profile was active. Returns `false` if name is `"default"`. |
| `cfg:NextProfileName()` | Returns the next available auto-name: `"Profile 1"`, `"Profile 2"`, etc. |
| `cfg:HasStorage()` | Returns `true` if the executor exposes `writefile` / `readfile`. |
| `cfg:CreateControls(tab)` | Inject the built-in profile/import/export UI into a tab. |
| `cfg.OnSave` | Signal. Fires after each save. |
| `cfg.OnLoad` | Signal. Fires after each load. |
| `cfg.OnReset` | Signal. Fires after reset. |
| `cfg.OnProfileChanged` | Signal. Fires with `(profileName)` whenever `SetProfile` is called. |

### File layout

```
Aurora/
  GardenShovel.json                 ← default profile
  GardenShovel_pvp.json             ← "pvp" profile
  GardenShovel_harvest.json         ← "harvest" profile
  GardenShovel_lastProfile.txt      ← contains e.g. "pvp"
```

Profile names are encoded in the filename stem after the `_`. The default profile has no suffix. The last-profile sidecar always uses `Name_lastProfile.txt`.

### Built-in UI (`CreateControls`)

```lua
cfg:CreateControls(configTab)
```

Injects the following into `configTab` — no extra code needed:

```
Profile
  [Selected Profile ▼]           ← dropdown, all profiles listed
  [Create New Profile]            ← button, auto-names "Profile 1", "Profile 2"…
  [Rename Current Profile    ]    ← input, press Enter
  [Delete Current Profile]        ← button, protected against deleting "default"

Import / Export
  [Export to Clipboard]           ← copies JSON; falls back to console print
  [Import Config             ]    ← input, paste JSON and press Enter
  [Reset to Defaults]
```

The profile dropdown is kept in sync automatically: creating a profile calls `SetOptions(listProfiles())` + `SetValue(newName)`, and so does deleting.

### Executor API detection

The config system detects available executor APIs at load time:

| Flag | Condition |
|---|---|
| `HAS_FILE_API` | `writefile` and `readfile` are functions |
| `HAS_FOLDER_API` | `makefolder` is a function |
| `HAS_LIST_FILES` | `listfiles` is a function |
| `HAS_DELETE` | `deletefile` or `delfile` is a function |
| `HAS_CLIPBOARD` | `setclipboard` is a function |

If `HAS_FILE_API` is false, the config system operates in-memory only. `CreateControls` shows a Warning status label. No profile UI is shown.

`deletefile` is tried first; if unavailable, `delfile` is used. After deletion, `isfile` is called to verify the file is actually gone before returning success.

### What should not be saved

Do not link:
- Elements whose values are rebuilt from live game data on each run (e.g. a plant type selector populated from the current garden)
- Running-state toggles (e.g. "Auto Farm is currently active") that should always start `false`

---

## 10. Signal

Aurora uses a lightweight built-in Signal class. All `OnChanged`, `OnTabChanged`, `OnRowClicked`, `OnElementAdded`, and config signals use this system.

```lua
local s = Signal.new()

-- Connect (persists until disconnected)
local conn = s:Connect(function(value)
    print("received:", value)
end)

-- Once (auto-disconnects after first fire; returns handle to cancel early)
local onceConn = s:Once(function(value)
    print("received once:", value)
end)
onceConn.Disconnect()   -- cancel before it fires

-- Fire
s:Fire(42)

-- Disconnect
conn.Disconnect()
```

If a callback errors, the error is `warn`-ed with `[Aurora Signal] Callback error: ...` and the remaining handlers continue to fire.

Signals do not support `Wait()`. Use `task.wait()` patterns or `Once()` with a coroutine if you need to yield.

---

## 11. Internals & Architecture

### Key guarantees

**SetValue is always silent.** Every element's `SetValue` function updates internal state and the display without calling `Callback` or firing `OnChanged`. This prevents circular loops when the config system loads saved values. The only exceptions are display-only elements where `SetValue` is the only change mechanism: `Label`, `StatusLabel`, `ProgressBar`.

**Tab prototype.** All 16 `Create*` methods are defined once on `Tab.__index`. Creating 100 tabs allocates exactly the same number of method closures as creating 1.

**ConnSet.** Each element has its own `ConnSet` (a hash-keyed set of RBXScriptConnections). Global UIS connections (slider drag, keybind listening) go into the element's ConnSet rather than a window-level array. `element.Destroy()` calls `ConnSet:DisconnectAll()` immediately. `Window:Destroy()` iterates `tab._elementConnSets` and disconnects all of them. No connection can appear twice (hash key deduplication).

**Expandable base.** Dropdown, SearchDropdown, MultiSelect, and ColorPicker all use `Expandable.makeExpandable(frame, collapsedH, getExpandedH, arrowLabel?)`. One implementation drives the tween, the arrow rotation, and the global collapse registry (`_registry`). `SetEnabled(false)` calls `Expandable.tryCollapse(frame)` to collapse any open expandable before locking it.

**Tween cancellation.** `Utility.Tween(inst, props, duration, ...)` checks `_activeTweens[inst]` and cancels any in-flight tween on the same instance before creating a new one. This prevents animation jitter when rapidly toggling elements.

**Notification scoping.** Each `Notification.createLayer(guiParent)` creates a fully independent queue + ScreenGui. The shared singleton (`Aurora:Notify`) is lazily created and re-created if its ScreenGui is destroyed. `win:Notify()` creates a per-window layer on first call.

### Module build order

```
Signal
  └─ Config
       └─ ConnSet
            └─ Utility
                 └─ Expandable
                      └─ [16 element modules]
                           └─ Tab
                                └─ Notification
                                     └─ Window
                                          └─ ConfigSystem
                                               └─ Aurora (init)
```

Each module is wrapped in `local Name = (function() ... end)()`. Earlier locals are in scope as upvalues for later modules — no explicit dependency injection needed.

### Element frame heights (px)

| Element | Height |
|---|---|
| Button | 36 |
| Toggle | 36 |
| Slider | 50 |
| Dropdown | 36 (collapsed), 36 + N×30 (expanded) |
| SearchDropdown | 36 (collapsed), 36 + min(N,MaxVisible)×30 + 36 (expanded) |
| MultiSelect | 36 (collapsed), 36 + N×30 (expanded) |
| Input | 54 |
| NumberInput | 54 |
| Keybind | 36 |
| ColorPicker | 36 (collapsed), 148 (expanded) |
| Label | 22 |
| Section | 28 |
| ProgressBar | 46 |
| StatusLabel | 24 |
| Table | Varies (row count × 30 + header) |
| Row | Configurable (default 36) |

Tab content padding: `10px` top/bottom, `10px` left, `12px` right. Gap between elements: `8px`.

---

## 12. Build System

Aurora ships as a single `Aurora.lua` but is developed across 26 source modules in `src/`.

### Running a build

```bash
python3 build.py
```

Output: `Aurora.lua`

### Build manifest

`build_manifest.json` defines the module list and order. The builder:

1. Reads each file in order
2. Wraps it in `local ModuleName = (function() ... end)()`
3. Concatenates all modules
4. Writes the version header and timestamp

### Source file structure

```
src/
  Signal.lua
  Config.lua
  ConnSet.lua
  Utility.lua
  Expandable.lua
  Tab.lua
  Notification.lua
  Window.lua
  ConfigSystem.lua
  init.lua
  elements/
    Button.lua
    Toggle.lua
    Slider.lua
    Dropdown.lua
    SearchDropdown.lua
    MultiSelect.lua
    Input.lua
    NumberInput.lua
    Keybind.lua
    ColorPicker.lua
    Label.lua
    Section.lua
    ProgressBar.lua
    StatusLabel.lua
    Table.lua
    Row.lua
```

### Adding a new element

1. Create `src/elements/YourElement.lua`. It must return a function `(self, cfg)` where `self` is the Tab.
2. Call `self:RegisterElement({ ... }, frame)` at the end and return the result.
3. Add the module to `build_manifest.json` in the elements section.
4. Assign it in `src/Tab.lua`: `Tab.CreateYourElement = _YourElement`
5. Run `python3 build.py`.

The element automatically receives `SetEnabled`, `SetVisible`, `Destroy`, and `Frame` from `RegisterElement`. You only need to implement `GetValue`, `SetValue`, and `OnChanged` (plus any extra methods specific to your element).

---

*Aurora v7.0 — March 2026*
