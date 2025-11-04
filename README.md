# ButtonBot

**Automated button detection and execution for IDEs and applications**

ButtonBot detects visual buttons on screen and automatically executes clicks or hotkeys. Perfect for automating repetitive IDE interactions.

## Features

- 🔍 **Image-based detection** - Detects buttons anywhere on screen
- ⚡ **Configurable actions** - Click or send hotkeys
- 🎯 **Per-button settings** - Individual timing and behavior
- ⌨️ **Smart typing detection** - Won't interrupt while you're typing
- 🔧 **GUI configuration** - Easy visual editor
- 🔄 **Hot reload** - Update config without restarting

## Installation

```bash
# Install AutoHotkey v2.0
choco install autohotkey

# Run ButtonBot
cd buttonbot
.\ButtonBot.ahk
```

## Quick Start

### 1. Capture a Button

1. Take a screenshot of the button you want to automate (`Win+Shift+S`)
2. Save as `my_button.png` in the `images/` folder

### 2. Configure

```bash
# Open configuration editor
.\ButtonBotConfig.ahk
```

Or press `Ctrl+Alt+Shift+C` (configurable)

### 3. Add Button

1. Click "➕ Add Button"
2. Select your button image from `images/`
3. Choose action:
   - **Click**: Clicks the button
   - **Hotkey**: Sends keyboard shortcut (e.g., `Ctrl+Shift+\`)
4. Configure timing (or leave blank for defaults)
5. Save

### 4. Reload

Press `Ctrl+Alt+Shift+R` (configurable) to reload ButtonBot with new settings.

## Configuration

### Global Settings

```ini
[Defaults]
Interval=200              # Detection speed (ms)
KeyPressDelay=4000        # Wait after typing (ms)
DetectionCooldown=2000    # Time between detections (ms)
ImageVariation=50         # Image match tolerance (0-255)
ReloadHotkey=^!+r         # Hotkey to reload script
ConfigHotkey=^!+c         # Hotkey to open config editor
```

### Button Configuration

```ini
[Button1]
File=run_button.png       # Image file (in images/ folder)
Action=hotkey             # click or hotkey
Hotkey=^+\                # Keyboard shortcut (if action=hotkey)
Enabled=true              # Enable/disable button
# Optional overrides (leave blank to use defaults):
Interval=200
KeyPressDelay=4000
DetectionCooldown=2000
ImageVariation=50
```

## Hotkey Format

- `^` = Ctrl
- `!` = Alt
- `+` = Shift
- `#` = Win

Examples:
- `^+\` = Ctrl+Shift+\
- `^r` = Ctrl+R
- `F5` = F5
- `^!+c` = Ctrl+Alt+Shift+C

## Default Hotkeys

- `Ctrl+Alt+Shift+R` - Reload ButtonBot
- `Ctrl+Alt+Shift+C` - Open configuration editor
- `Ctrl+Alt+P` - Pause/Resume detection
- `Ctrl+Alt+Q` - Exit ButtonBot

All hotkeys are configurable.

## Use Cases

- **IDE automation**: Auto-approve command execution prompts
- **Chat interfaces**: Auto-scroll to bottom
- **Repetitive workflows**: Automate button clicks
- **Testing**: Simulate user interactions

## How It Works

1. ButtonBot scans the active window for configured button images
2. When detected, waits for typing to stop (KeyPressDelay)
3. Executes the configured action (click or hotkey)
4. Waits before detecting again (DetectionCooldown)

## Configuration Tips

**Slow detection?**
- Reduce `KeyPressDelay` to 2000 (2 seconds)

**Multiple executions?**
- Increase `DetectionCooldown` to 3000 (3 seconds)

**Interrupts typing?**
- Increase `KeyPressDelay` to 6000 (6 seconds)

**Button not detected?**
- Increase `ImageVariation` to 80
- Recapture button with better quality

## Project Structure

```
buttonbot/
├── ButtonBot.ahk           # Main script
├── ButtonBotConfig.ahk     # Configuration GUI
├── install.bat             # Automated installer
├── README.md               # This file
├── config/
│   ├── config.ini          # Your configuration
│   └── config.example.ini  # Example configuration
├── images/
│   ├── run_button.png      # Your button images
│   └── ArrowDown.png
└── .io/                    # Internal documentation
```

## License

MIT License - Free to use and modify

## Contributing

Contributions welcome! This is a neutral, open-source automation tool.

## Author

Created for automating repetitive IDE interactions.
