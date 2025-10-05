#!/bin/bash
# Script to create modular Sway config structure

CONFIG_DIR="$HOME/.config/sway"

# Create directory structure
mkdir -p "$CONFIG_DIR/config.d"

echo "Creating modular Sway configuration files..."

# Main config file
cat > "$CONFIG_DIR/config" << 'EOF'
# Main Sway Configuration
# Modular setup - edit individual files in config.d/

### Variables
include $HOME/.config/sway/config.d/00-variables.conf

### Output (Monitors)
include $HOME/.config/sway/config.d/01-outputs.conf

### Input (Keyboard, Mouse, Touchpad)
include $HOME/.config/sway/config.d/02-input.conf

### Appearance
include $HOME/.config/sway/config.d/03-appearance.conf

### Keybindings
include $HOME/.config/sway/config.d/10-keybinds-basic.conf
include $HOME/.config/sway/config.d/11-keybinds-windows.conf
include $HOME/.config/sway/config.d/12-keybinds-workspaces.conf
include $HOME/.config/sway/config.d/13-keybinds-media.conf

### Modes
include $HOME/.config/sway/config.d/20-modes.conf

### Autostart
include $HOME/.config/sway/config.d/30-autostart.conf

### System config
include /etc/sway/config-vars.d/*
include /etc/sway/config.d/*
EOF

# 00-variables.conf
cat > "$CONFIG_DIR/config.d/00-variables.conf" << 'EOF'
# Variables Configuration

# Logo key. Use Mod1 for Alt, Mod4 for Super/Windows key
set $mod Mod4

# Home row direction keys (vim-style)
set $left h
set $down j
set $up k
set $right l

# Applications
set $term foot
set $browser firefox-esr
set $files nautilus
set $menu wofi --show drun

# Appearance
set $opacity 0.95
EOF

# 01-outputs.conf
cat > "$CONFIG_DIR/config.d/01-outputs.conf" << 'EOF'
# Output (Monitor) Configuration

# External HDMI monitor (left)
output HDMI-A-1 resolution 1920x1080@100Hz position 0,0 scale 1

# Internal laptop display (right)
output eDP-1 resolution 1920x1080@60Hz position 1920,0 scale 1.5

# Wallpaper
output * bg ~/Pictures/Wallpapers/1.jpg fill

# Get output names with: swaymsg -t get_outputs
EOF

# 02-input.conf
cat > "$CONFIG_DIR/config.d/02-input.conf" << 'EOF'
# Input Configuration

# Example touchpad configuration:
# input "2:14:SynPS/2_Synaptics_TouchPad" {
#     dwt enabled
#     tap enabled
#     natural_scroll enabled
#     middle_emulation enabled
# }

# Get input device names with: swaymsg -t get_inputs
EOF

# 03-appearance.conf
cat > "$CONFIG_DIR/config.d/03-appearance.conf" << 'EOF'
# Appearance Configuration

# Font
font pango:Monospace 11

# Window opacity
for_window [class=".*"] opacity $opacity
for_window [app_id=".*"] opacity $opacity

# Status Bar (using waybar instead)
# bar {
#     position top
#     status_command while date +'%Y-%m-%d %H:%M:%S'; do sleep 1; done
#     colors {
#         statusline #ffffff
#         background #323232
#         inactive_workspace #32323200 #32323200 #5c5c5c
#     }
# }
EOF

# 10-keybinds-basic.conf
cat > "$CONFIG_DIR/config.d/10-keybinds-basic.conf" << 'EOF'
# Basic Keybindings

# Start terminal
bindsym $mod+Return exec $term

# Start browser
bindsym $mod+b exec $browser

# Start file manager
bindsym $mod+e exec $files

# Start application launcher
bindsym $mod+d exec $menu

# Kill focused window
bindsym $mod+q kill

# Reload configuration
bindsym $mod+Shift+c reload

# Exit sway
bindsym $mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

# Screenshot
bindsym Print exec grim

# Drag floating windows
floating_modifier $mod normal
EOF

# 11-keybinds-windows.conf
cat > "$CONFIG_DIR/config.d/11-keybinds-windows.conf" << 'EOF'
# Window Management Keybindings

# Focus windows (vim keys)
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right

# Focus windows (arrow keys)
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Move windows (vim keys)
bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right

# Move windows (arrow keys)
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Layout modes
bindsym $mod+s layout stacking
bindsym $mod+p layout tabbed
bindsym $mod+w layout toggle split

# Fullscreen
bindsym $mod+f fullscreen

# Toggle floating
bindsym $mod+Shift+space floating toggle

# Toggle focus between tiling/floating
bindsym $mod+space focus mode_toggle

# Focus parent container
bindsym $mod+a focus parent

# Scratchpad
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus scratchpad show
EOF

# 12-keybinds-workspaces.conf
cat > "$CONFIG_DIR/config.d/12-keybinds-workspaces.conf" << 'EOF'
# Workspace Keybindings

# Cycle workspaces
bindsym $mod+Tab workspace next
bindsym $mod+Shift+Tab workspace prev

# Switch to workspace
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

# Move container to workspace
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10
EOF

# 13-keybinds-media.conf
cat > "$CONFIG_DIR/config.d/13-keybinds-media.conf" << 'EOF'
# Media and System Keybindings

# Volume controls (PulseAudio)
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle

# Brightness controls
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86MonBrightnessUp exec brightnessctl set 5%+
EOF

# 20-modes.conf
cat > "$CONFIG_DIR/config.d/20-modes.conf" << 'EOF'
# Modes Configuration

# Resize mode
mode "resize" {
    # Vim keys
    bindsym $left resize shrink width 10px
    bindsym $down resize grow height 10px
    bindsym $up resize shrink height 10px
    bindsym $right resize grow width 10px

    # Arrow keys
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px

    # Return to default mode
    bindsym Return mode "default"
    bindsym Escape mode "default"
}

bindsym $mod+r mode "resize"
EOF

# 30-autostart.conf
cat > "$CONFIG_DIR/config.d/30-autostart.conf" << 'EOF'
# Autostart Applications

# Waybar
exec_always pkill waybar; exec waybar

# EasyEffects
exec_always flatpak run com.github.wwmm.easyeffects --gapplication-service

# Notification daemon (mako)
exec_always sh -c '[ "$XDG_CURRENT_DESKTOP" = "sway" ] && mako'
EOF

echo "✓ Modular Sway config created successfully!"
echo ""
echo "Structure created:"
echo "  ~/.config/sway/config (main file)"
echo "  ~/.config/sway/config.d/"
echo "    ├── 00-variables.conf"
echo "    ├── 01-outputs.conf"
echo "    ├── 02-input.conf"
echo "    ├── 03-appearance.conf"
echo "    ├── 10-keybinds-basic.conf"
echo "    ├── 11-keybinds-windows.conf"
echo "    ├── 12-keybinds-workspaces.conf"
echo "    ├── 13-keybinds-media.conf"
echo "    ├── 20-modes.conf"
echo "    └── 30-autostart.conf"
echo ""
echo "Backup your current config first, then run:"
echo "  swaymsg reload"
