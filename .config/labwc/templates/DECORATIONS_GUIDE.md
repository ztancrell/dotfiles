# LabWC Window Decorations Guide

## What Controls Window Decorations?

Window decorations in LabWC are controlled by **TWO main files**:

### 1. `labwc.xml` (or `rc.xml`) - Layout & Behavior
Located at: `~/.config/labwc/labwc.xml`

This file controls:
- **Theme name** - which Openbox theme to use
- **Button layout** - which buttons appear and in what order
- **Titlebar visibility** - show/hide titlebar
- **Borders** - border width, visibility
- **Shadows** - drop shadows on windows
- **Corner radius** - rounded corners
- **Maximized decorations** - how decorations look when maximized

### 2. `themerc` file - Visual Appearance
Located at: `~/.local/share/themes/<theme-name>/openbox-3/themerc`
or: `/usr/share/themes/<theme-name>/openbox-3/themerc`

This file controls:
- **Colors** - titlebar colors, button colors, text colors
- **Button images** - the actual icons (XBM files) for close/max/min buttons
- **Padding** - spacing around buttons and titlebar
- **Borders** - border colors and styles
- **Fonts** - titlebar font settings
- **Gradients** - background gradients for titlebars and buttons

---

## Key Settings in `labwc.xml`

### Theme Section
```xml
<theme>
  <name>Clearlooks-3.4</name>              <!-- Theme name -->
  <button_layout>CM</button_layout>        <!-- Button order -->
  <title_layout>left</title_layout>        <!-- Title position -->
  <font>Sans 8</font>                      <!-- Titlebar font -->
  <cornerRadius>0</cornerRadius>           <!-- Rounded corners -->
  <keepBorder>no</keepBorder>              <!-- Keep border when disabled -->
  <dropShadows>no</dropShadows>            <!-- Window shadows -->
  <maximizedDecoration>none</maximizedDecoration>  <!-- Maximized style -->
</theme>
```

### Button Layout Codes
- `L` = Menu button (left side)
- `M` = Maximize button
- `C` = Close button
- `I` = Iconify/Minimize button
- `:` = Separator (left side vs right side)

Examples:
- `CM` = Close, Maximize (right side)
- `LMC` = Menu, Maximize, Close (left side)
- `:CM` = Title on left, Close+Maximize on right
- `LMC:` = Menu+Max+Close on left, title on right

### Window Section
```xml
<window>
  <border>none</border>                    <!-- Border style -->
  <border_width>0</border_width>           <!-- Border thickness -->
  <titlebar>enabled</titlebar>             <!-- Show titlebar -->
</window>
```

---

## Key Settings in `themerc` File

### Border & Padding
```
border.width: 1                            <!-- Window border width -->
padding.width: 2                           <!-- General padding -->
window.handle.width: 4                    <!-- Resize handle width -->
```

### Titlebar Colors (Active Window)
```
window.active.title.bg.color: #589bda      <!-- Titlebar background -->
window.active.title.bg.colorTo: #3c7cb7   <!-- Gradient end color -->
window.active.label.text.color: #ffffff   <!-- Title text color -->
```

### Titlebar Colors (Inactive Window)
```
window.inactive.title.bg.color: #efece6   <!-- Inactive titlebar -->
window.inactive.label.text.color: #000000 <!-- Inactive text -->
```

### Button Colors
```
window.active.button.unpressed.bg.color: #5ea0dd    <!-- Button normal -->
window.active.button.hover.bg.color: #171a21       <!-- Button hover -->
window.active.button.pressed.bg.color: #0b0d11      <!-- Button pressed -->
window.active.button.unpressed.image.color: #ffffff <!-- Button icon color -->
```

### Button Images
Button icons are XBM files (1-bit bitmap images) located in the theme directory:
- `close.xbm` - Close button icon
- `max.xbm` - Maximize button icon
- `iconify.xbm` - Minimize button icon
- `desk.xbm` - Desktop button icon
- `shade.xbm` - Shade button icon

---

## How to Customize Decorations

### Option 1: Edit Theme Settings in `labwc.xml`
Change button layout, shadows, borders, etc. directly in your config.

### Option 2: Override Theme Colors
Create `~/.config/labwc/themerc-override` to override specific theme settings:
```
# Override titlebar color
window.active.title.bg.color: #222222
window.inactive.title.bg.color: #111111

# Override button colors
window.active.button.unpressed.bg.color: #333333
window.active.button.hover.bg.color: #444444
```

### Option 3: Create Your Own Theme
1. Copy an existing theme:
   ```bash
   cp -r /usr/share/themes/Clearlooks-3.4 ~/.local/share/themes/MyTheme
   ```

2. Edit `~/.local/share/themes/MyTheme/openbox-3/themerc`

3. Change theme name in `labwc.xml`:
   ```xml
   <theme>
     <name>MyTheme</name>
   </theme>
   ```

### Option 4: Modify Button Icons
Replace XBM files in the theme directory with your own icons.

---

## LabWC vs LXQt

**LabWC** (what you're using):
- Window manager for Wayland
- Uses Openbox-compatible themes
- Config files: `labwc.xml` or `rc.xml` + `themerc`
- Controls decorations directly

**LXQt**:
- Desktop environment (not a window manager)
- Uses Qt themes and GTK themes
- If running on LabWC, decorations are controlled by LabWC
- If running on another WM, that WM controls decorations
- LXQt's appearance settings only affect Qt applications, not window decorations

---

## Quick Reference: Current Settings

Your current `labwc.xml` settings:
- Theme: `Clearlooks-3.4`
- Buttons: `CM` (Close, Maximize on right)
- Title: Left side
- Border: None (0px)
- Shadows: Disabled
- Corners: Square (0px radius)
- Maximized: No decorations

---

## Useful Commands

```bash
# Reload config without restarting
labwcctl reload

# List available themes
ls /usr/share/themes/*/openbox-3/themerc
ls ~/.local/share/themes/*/openbox-3/themerc

# View current theme's themerc
cat ~/.local/share/themes/<theme>/openbox-3/themerc
cat /usr/share/themes/<theme>/openbox-3/themerc
```

---

## Common Customizations

### Minimal Retro Look (what you have now)
- Theme: Classic Openbox theme (Clearlooks-3.4)
- Buttons: Just Close + Maximize (`CM`)
- No shadows, no borders, square corners

### Ultra Minimal
- Set `<titlebar>disabled</titlebar>` in `labwc.xml`
- Or use `<maximizedDecoration>none</maximizedDecoration>`

### Custom Colors
- Edit `themerc-override` or theme's `themerc` file
- Change `window.active.title.bg.color` and related settings

### Different Button Layout
- Change `<button_layout>` in `labwc.xml`
- Examples: `LMC`, `CM`, `ICM`, `:CM`, etc.
