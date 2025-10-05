#!/usr/bin/env bash
# swaybg-picker — terminal wallpaper picker for sway with wallust integration

LOG=/tmp/swaybg-picker.log
LAST_WALLPAPER="$HOME/.config/sway/last-wallpaper"
exec > >(tee -a "$LOG") 2>&1

echo "=== swaybg-picker run at $(date) ==="
echo "PATH=$PATH"
echo "DISPLAY=$DISPLAY"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

WALLPAPER_DIR="${1:-$HOME/Pictures/Wallpapers}"

# Check dependencies
for dep in swaybg fzf swaymsg wallust; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "ERROR: Missing dependency: $dep"
        notify-send "Wallpaper Picker" "Missing dependency: $dep" 2>/dev/null
        exit 1
    fi
done

# Function to apply wallust and reload waybar
apply_wallust() {
    local wallpaper="$1"
    echo "Generating color scheme with wallust..."
    
    # Run wallust to generate colors from wallpaper
    wallust run "$wallpaper"
    
    # Reload waybar to apply new colors
    echo "Reloading waybar..."
    pkill -SIGUSR2 waybar || {
        echo "Restarting waybar..."
        pkill waybar
        sleep 0.2
        nohup waybar >/dev/null 2>&1 &
        disown
    }
}

# If --restore flag, just restore the last wallpaper
if [ "$1" = "--restore" ]; then
    if [ -f "$LAST_WALLPAPER" ]; then
        CHOICE=$(cat "$LAST_WALLPAPER")
        if [ -f "$CHOICE" ]; then
            echo "Restoring wallpaper: $CHOICE"
            
            # Apply wallust theme
            apply_wallust "$CHOICE"
            
            # Kill old instances
            pkill -x swaybg
            sleep 0.3
            
            # Detect outputs
            if command -v jq >/dev/null 2>&1; then
                mapfile -t OUTPUTS < <(swaymsg -t get_outputs | jq -r '.[] | select(.active==true) | .name')
            else
                mapfile -t OUTPUTS < <(swaymsg -t get_outputs | grep -oP '"name":\s*"\K[^"]+')
            fi
            
            # Apply wallpaper
            for out in "${OUTPUTS[@]}"; do
                echo "Starting swaybg for output: $out"
                nohup swaybg -o "$out" -i "$CHOICE" -m fill >/dev/null 2>&1 &
                disown
            done
            
            echo "Wallpaper restored successfully"
            exit 0
        else
            echo "Last wallpaper file not found: $CHOICE"
        fi
    else
        echo "No last wallpaper saved"
    fi
    exit 0
fi

# Find wallpapers
mapfile -t IMGS < <(find "$WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.svg" \) 2>/dev/null | sort)

if [ "${#IMGS[@]}" -eq 0 ]; then
    echo "ERROR: No images found in $WALLPAPER_DIR"
    notify-send "Wallpaper Picker" "No images in $WALLPAPER_DIR" 2>/dev/null
    exit 1
fi

echo "Found ${#IMGS[@]} wallpapers"

# Setup preview command
if command -v chafa >/dev/null 2>&1; then
    PREVIEW='chafa --size=40x20 {} 2>/dev/null || echo "Preview not available"'
else
    PREVIEW='file {}'
fi

# Pick with fzf
CHOICE=$(printf "%s\n" "${IMGS[@]}" | fzf \
    --preview "$PREVIEW" \
    --height=40% \
    --reverse \
    --border \
    --prompt="Wallpaper> " \
    --preview-window=right:50%)

[ -z "$CHOICE" ] && { echo "No wallpaper selected"; exit 0; }

echo "Selected: $CHOICE"

# Save the choice
echo "$CHOICE" > "$LAST_WALLPAPER"

# Apply wallust theme before setting wallpaper
apply_wallust "$CHOICE"

# Kill all old swaybg instances
echo "Stopping existing swaybg instances..."
pkill -x swaybg
sleep 0.3

# Detect active outputs
echo "Detecting outputs..."
if command -v jq >/dev/null 2>&1; then
    mapfile -t OUTPUTS < <(swaymsg -t get_outputs | jq -r '.[] | select(.active==true) | .name')
else
    mapfile -t OUTPUTS < <(swaymsg -t get_outputs | grep -oP '"name":\s*"\K[^"]+')
fi

if [ "${#OUTPUTS[@]}" -eq 0 ]; then
    echo "ERROR: No active outputs detected"
    notify-send "Wallpaper Picker" "No active outputs detected" 2>/dev/null
    exit 1
fi

echo "Active outputs: ${OUTPUTS[*]}"

# Start new swaybg per output with nohup and disown
for out in "${OUTPUTS[@]}"; do
    echo "Starting swaybg for output: $out"
    nohup swaybg -o "$out" -i "$CHOICE" -m fill >/dev/null 2>&1 &
    disown
done

notify-send "Wallpaper Changed" "$(basename "$CHOICE")" 2>/dev/null
echo "Wallpaper set successfully"