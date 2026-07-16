# Waybar Style Options

## Taskbar Button Sizing

The taskbar buttons use a fixed width for even, symmetric active highlights. Adjust in `style.css`:

```css
#taskbar button {
    min-width: 36px;    /* Minimum width - change for larger/smaller buttons */
    padding: 6px;       /* Equal padding on all sides */
    ...
}
```

- **Larger buttons:** Try `min-width: 40px` or `min-width: 44px`
- **Smaller buttons:** Try `min-width: 32px` or `min-width: 28px`
- **Uneven appearance:** If the active box still looks asymmetric, try `padding: 6px 4px 6px 8px` (left/right compensation)

## Output (Monitor)

Waybar shows only on the primary monitor (DP-1). To change, edit `config`:

```json
"output": "DP-1"
```

Use your monitor name (e.g. `"HDMI-A-1"`) or remove the line to show on all monitors.
