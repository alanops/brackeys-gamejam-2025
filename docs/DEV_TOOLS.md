# Developer Tools Guide

## Overview
Comprehensive set of developer tools and helpers for rapid prototyping and debugging during game development.

## Debug Overlay (F3)
**Hotkey**: F3 to toggle

Displays real-time information:
- **FPS Counter** (color-coded: Green 55+, Yellow 30+, Red <30)
- **Player Position** (X, Y, Z coordinates)
- **Memory Usage** (in MB)
- **Time Scale** (current multiplier)
- **Controls Reference**

## Developer Console (F4)
**Hotkey**: F4 to toggle

### Available Commands:
- `help` - Show all commands
- `clear` - Clear console output
- `quit` - Return to main menu
- `restart` - Restart current scene
- `scene [path]` - Load specific scene
- `timescale [0.1-5.0]` - Adjust game speed
- `teleport x y z` - Move player to coordinates
- `noclip` - Toggle free camera mode
- `fps_limit [30/60/120/0]` - Set FPS cap
- `screenshot` - Take timestamped screenshot
- `godmode` - Toggle invincibility (when implemented)
- `give [item] [amount]` - Add items to inventory (when implemented)

### Console Features:
- **Command History** - Use ↑/↓ arrows to navigate
- **Auto-complete** - Tab completion for commands
- **Color-coded Output** - Success (green), errors (red), info (yellow)

## Noclip Mode (F5)
**Hotkey**: F5 to toggle, or use console command `noclip`

Features:
- **Free Flight** - Move in any direction including up/down
- **No Collision** - Pass through walls and objects
- **Camera-relative Movement** - WASD moves relative to camera view
- **Vertical Movement** - Space (up) / Page Down (down)
- **Faster Speed** - 10 units/sec vs normal 5 units/sec

## Scene Switcher (F6)
**Hotkey**: F6 to toggle

Quick scene navigation:
- **Predefined Scenes** - Main Menu, Dungeon Room, Test scenes
- **Add Current Scene** - Save current scene to quick-switch list
- **One-click Loading** - Instant scene transitions
- **Scene Path Display** - Shows full resource paths

## Time Controls
Accessible via console or direct hotkeys:
- `timescale 0.5` - Half speed (slow motion)
- `timescale 2.0` - Double speed
- `timescale 0.1` - Ultra slow motion for precise testing
- `timescale 1.0` - Normal speed

## Screenshot System
**Command**: `screenshot` in console

Features:
- **Automatic Naming** - Timestamps in format: screenshot_YYYYMMDD_HHMMSS.png
- **Auto-directory Creation** - Saves to user://screenshots/
- **Full Resolution** - Captures at current window resolution
- **Instant Feedback** - Console confirmation with filename

## Game Manager (Singleton)
Global system managing all dev tools:
- **Persistent Across Scenes** - Tools available everywhere
- **Centralized Commands** - Single point for global commands
- **Settings Management** - Stores debug preferences
- **Tool Coordination** - Prevents conflicts between systems

## Hotkey Reference
| Key | Function |
|-----|----------|
| F3 | Toggle Debug Overlay |
| F4 | Toggle Developer Console |
| F5 | Toggle Noclip Mode |
| F6 | Toggle Scene Switcher |
| R | Reset Current Scene |
| ESC | Release mouse / Pause |

## Developer Tips

### Quick Testing Workflow:
1. Press F3 to monitor performance
2. Use F6 to quickly switch between test scenes
3. Press F5 for noclip to explore level geometry
4. Use F4 console for precise testing (teleport, timescale)

### Performance Testing:
- Use `timescale` to test game logic at different speeds
- Monitor FPS counter for performance bottlenecks
- Use `fps_limit` to simulate different target framerates

### Level Design:
- Noclip mode for camera positioning and composition
- Teleport command for quick movement to specific areas
- Screenshot tool for documenting level layouts

### Debugging:
- Console provides immediate feedback for all actions
- Color-coded output helps identify issues quickly
- Command history saves time during repetitive testing

## Build Configuration
All dev tools are automatically disabled in release builds for performance and security.