#!/usr/bin/env bash
# swaybg-picker — terminal wallpaper picker for sway with wallust integration
# Enhanced UI version with better previews and information

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Constants
readonly SCRIPT_NAME="swaybg-picker"
readonly LOG_FILE="/tmp/${SCRIPT_NAME}.log"
readonly LAST_WALLPAPER="${HOME}/.config/sway/last-wallpaper"
readonly WALLPAPER_DIR="${1:-${HOME}/Pictures/Wallpapers}"
readonly REQUIRED_DEPS=(swaybg fzf swaymsg wallust)
readonly SUPPORTED_FORMATS=(-iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.svg")

# Logging setup
exec > >(tee -a "$LOG_FILE") 2>&1

# Logging functions
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

log_debug() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*"
}

# Send notification helper
send_notification() {
    local title="$1"
    local message="$2"
    local timeout="${3:-3000}"
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -t "$timeout" "$title" "$message" 2>/dev/null || true
}

# Check all required dependencies
check_dependencies() {
    local missing_deps=()
    
    for dep in "${REQUIRED_DEPS[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        send_notification "Wallpaper Picker" "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    log_debug "All dependencies found"
}

# Apply wallust color scheme and reload waybar
apply_wallust() {
    local wallpaper="$1"
    
    log_info "Generating color scheme with wallust..."
    if ! wallust run "$wallpaper"; then
        log_error "wallust failed to generate color scheme"
        return 1
    fi
    
    log_info "Reloading waybar..."
    if pkill -SIGUSR2 waybar; then
        log_debug "Waybar reloaded successfully"
    else
        log_info "Restarting waybar..."
        pkill waybar 2>/dev/null || true
        sleep 0.2
        nohup waybar >/dev/null 2>&1 & disown
    fi
}

# Get active sway outputs efficiently
get_active_outputs() {
    local outputs
    
    if command -v jq >/dev/null 2>&1; then
        # Use jq for robust JSON parsing
        mapfile -t outputs < <(swaymsg -t get_outputs | jq -r '.[] | select(.active==true) | .name')
    else
        # Fallback to grep (less reliable)
        mapfile -t outputs < <(swaymsg -t get_outputs | grep -oP '"name":\s*"\K[^"]+')
    fi
    
    if [[ ${#outputs[@]} -eq 0 ]]; then
        log_error "No active outputs detected"
        return 1
    fi
    
    printf '%s\n' "${outputs[@]}"
}

# Start swaybg for all outputs
start_swaybg() {
    local wallpaper="$1"
    local outputs
    
    # Kill existing instances first
    log_info "Stopping existing swaybg instances..."
    pkill -x swaybg 2>/dev/null || true
    sleep 0.3
    
    # Get active outputs
    log_info "Detecting active outputs..."
    if ! mapfile -t outputs < <(get_active_outputs); then
        send_notification "Wallpaper Picker" "No active outputs detected"
        return 1
    fi
    
    log_debug "Active outputs: ${outputs[*]}"
    
    # Start swaybg for each output
    for output in "${outputs[@]}"; do
        log_debug "Starting swaybg for output: $output"
        nohup swaybg -o "$output" -i "$wallpaper" -m fill >/dev/null 2>&1 & disown
    done
    
    return 0
}

# Restore last wallpaper
restore_wallpaper() {
    if [[ ! -f "$LAST_WALLPAPER" ]]; then
        log_info "No last wallpaper saved"
        exit 0
    fi
    
    local wallpaper
    wallpaper=$(<"$LAST_WALLPAPER")
    
    if [[ ! -f "$wallpaper" ]]; then
        log_error "Last wallpaper file not found: $wallpaper"
        exit 1
    fi
    
    log_info "Restoring wallpaper: $wallpaper"
    
    apply_wallust "$wallpaper"
    
    if start_swaybg "$wallpaper"; then
        log_info "Wallpaper restored successfully"
        exit 0
    else
        exit 1
    fi
}

# Find all wallpapers in directory
find_wallpapers() {
    local wallpapers
    
    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        log_error "Wallpaper directory not found: $WALLPAPER_DIR"
        send_notification "Wallpaper Picker" "Directory not found: $WALLPAPER_DIR"
        exit 1
    fi
    
    # Build find command with supported formats
    mapfile -t wallpapers < <(
        find "$WALLPAPER_DIR" -type f \( "${SUPPORTED_FORMATS[@]}" \) 2>/dev/null | sort
    )
    
    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        log_error "No images found in $WALLPAPER_DIR"
        send_notification "Wallpaper Picker" "No images found in $WALLPAPER_DIR"
        exit 1
    fi
    
    log_info "Found ${#wallpapers[@]} wallpapers"
    printf '%s\n' "${wallpapers[@]}"
}

# Get image information
get_image_info() {
    local file="$1"
    local filename filesize dimensions
    
    filename=$(basename "$file")
    filesize=$(du -h "$file" 2>/dev/null | cut -f1)
    
    # Get dimensions efficiently
    if command -v identify >/dev/null 2>&1; then
        dimensions=$(identify -format '%wx%h' "$file" 2>/dev/null || echo "")
    elif command -v file >/dev/null 2>&1; then
        dimensions=$(file "$file" 2>/dev/null | grep -oP '\d+\s*x\s*\d+' | head -1 | tr -d ' ')
    else
        dimensions=""
    fi
    
    # Output formatted information
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 File: $filename
📏 Size: $filesize
${dimensions:+🖼️  Dimensions: $dimensions}
📂 Path: $file
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Create preview script for fzf
create_preview_script() {
    local preview_script
    preview_script=$(mktemp)
    
    cat > "$preview_script" << 'PREVIEW_EOF'
#!/usr/bin/env bash
set -euo pipefail

file="$1"

# Reuse get_image_info function
get_image_info() {
    local file="$1"
    local filename filesize dimensions
    
    filename=$(basename "$file")
    filesize=$(du -h "$file" 2>/dev/null | cut -f1)
    
    if command -v identify >/dev/null 2>&1; then
        dimensions=$(identify -format '%wx%h' "$file" 2>/dev/null || echo "")
    elif command -v file >/dev/null 2>&1; then
        dimensions=$(file "$file" 2>/dev/null | grep -oP '\d+\s*x\s*\d+' | head -1 | tr -d ' ')
    else
        dimensions=""
    fi
    
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 File: $filename
📏 Size: $filesize
${dimensions:+🖼️  Dimensions: $dimensions}
📂 Path: $file
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

get_image_info "$file"

# High-quality terminal image preview (priority order)
if [[ "${TERM:-}" =~ kitty ]]; then
    kitty +kitten icat --align left --place 80x40@0x0 "$file" 2>/dev/null
elif command -v ueberzugpp >/dev/null 2>&1; then
    echo "Press Ctrl+C to return to selection"
    ueberzugpp layer --no-stdin --output x11 <<< "{\"action\":\"add\",\"identifier\":\"preview\",\"x\":0,\"y\":0,\"width\":80,\"height\":40,\"path\":\"$file\"}"
    sleep 0.1
elif command -v img2sixel >/dev/null 2>&1; then
    img2sixel -w 800 -h 600 "$file" 2>/dev/null
elif command -v chafa >/dev/null 2>&1; then
    chafa --size=80x40 --format=symbols --symbols=all \
          --colors=truecolor --dither=ordered "$file" 2>/dev/null
elif command -v viu >/dev/null 2>&1; then
    viu -w 80 -h 40 "$file" 2>/dev/null
else
    cat << 'SUGGEST'
⚠️  For best quality, install one of:
   • kitty terminal (best quality)
   • ueberzugpp (works in most terminals)
   • libsixel (img2sixel command)
   • chafa (basic support)

SUGGEST
    file "$file"
fi
PREVIEW_EOF
    
    chmod +x "$preview_script"
    echo "$preview_script"
}

# Run fzf wallpaper selector
select_wallpaper() {
    local -a wallpapers
    mapfile -t wallpapers < <(find_wallpapers)
    
    local preview_script
    preview_script=$(create_preview_script)
    
    # Ensure cleanup on exit
    trap "rm -f '$preview_script'" EXIT
    
    local selected
    selected=$(printf "%s\n" "${wallpapers[@]}" | fzf \
        --ansi \
        --preview="$preview_script {}" \
        --preview-window='right:60%:wrap' \
        --height='95%' \
        --border=rounded \
        --margin=1 \
        --padding=1 \
        --prompt='🖼️  Select Wallpaper › ' \
        --pointer='▶' \
        --marker='✓' \
        --header='Press ENTER to select | ESC to cancel | ↑↓ to navigate | Ctrl+/ toggle preview' \
        --header-first \
        --color='fg:#d0d0d0,bg:#1a1a1a,hl:#5fd7ff' \
        --color='fg+:#ffffff,bg+:#262626,hl+:#5fd7ff' \
        --color='info:#afaf87,prompt:#5fd7ff,pointer:#ff5f87' \
        --color='marker:#87ff00,spinner:#ff87d7,header:#87afaf' \
        --color='border:#262626,preview-bg:#1a1a1a' \
        --bind='ctrl-/:toggle-preview' \
        --bind='ctrl-u:preview-half-page-up' \
        --bind='ctrl-d:preview-half-page-down' \
        --with-nth='-1' \
        --delimiter='/' \
        --info=inline) || true
    
    echo "$selected"
}

# Apply selected wallpaper
apply_wallpaper() {
    local wallpaper="$1"
    
    log_info "Selected: $wallpaper"
    
    # Save selection
    echo "$wallpaper" > "$LAST_WALLPAPER"
    
    # Show loading notification
    send_notification "Wallpaper Picker" "⏳ Applying $(basename "$wallpaper")..." 2000
    
    # Apply wallust theme
    if ! apply_wallust "$wallpaper"; then
        log_error "Failed to apply wallust theme"
        send_notification "Wallpaper Picker" "Failed to generate color scheme"
        return 1
    fi
    
    # Set wallpaper
    if start_swaybg "$wallpaper"; then
        send_notification "Wallpaper Changed" "✓ $(basename "$wallpaper")"
        log_info "Wallpaper set successfully"
        return 0
    else
        send_notification "Wallpaper Picker" "Failed to set wallpaper"
        return 1
    fi
}

# Main function
main() {
    log_info "=== $SCRIPT_NAME started ==="
    log_debug "PATH=$PATH"
    log_debug "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
    
    # Check dependencies
    check_dependencies
    
    # Handle restore flag
    if [[ "${1:-}" == "--restore" ]]; then
        restore_wallpaper
    fi
    
    # Select wallpaper
    local selected
    selected=$(select_wallpaper)
    
    if [[ -z "$selected" ]]; then
        log_info "No wallpaper selected"
        exit 0
    fi
    
    # Apply wallpaper
    apply_wallpaper "$selected"
}

# Run main function
main "$@"