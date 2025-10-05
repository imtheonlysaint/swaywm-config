# #!/usr/bin/env bash

# # Detect location via IP
# location_json=$(curl -s https://ipapi.co/json/)
# city=$(echo "$location_json" | jq -r '.city')
# lat=$(echo "$location_json" | jq -r '.latitude')
# lon=$(echo "$location_json" | jq -r '.longitude')

# # Fetch weather from Open-Meteo
# weather_json=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true")
# temp=$(echo "$weather_json" | jq -r '.current_weather.temperature')
# condition_code=$(echo "$weather_json" | jq -r '.current_weather.weathercode')

# # Map weather code to emoji
# emoji="?"
# case $condition_code in
#   0) emoji="☀️" ;;
#   1|2) emoji="🌤️" ;;
#   3) emoji="☁️" ;;
#   45|48) emoji="˖ ִֶָ  ☁️" ;;
#   51|53|55) emoji="🌦️" ;;
#   61|63|65) emoji="🌧️" ;;
#   71|73|75) emoji="❄️" ;;
#   80|81|82) emoji="🌧️" ;;
#   95|96|99) emoji="⛈️" ;;
# esac

# # Output JSON for Waybar
# echo "{\"text\": \"$emoji ${temp}°C\", \"tooltip\": \"$city\"}"

#!/usr/bin/env bash

# Configuration
readonly CITY="Bandung"
readonly LAT="-6.914744"
readonly LON="107.609810"
readonly CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather.json"
readonly CACHE_DURATION=600  # 10 minutes in seconds

# Weather code to emoji mapping
get_weather_emoji() {
    case $1 in
        0) echo " " ;;           # Clear sky
        1|2) echo " " ;;        # Mainly clear, partly cloudy
        3) echo " " ;;           # Overcast
        45|48) echo "󰖑 " ;;      # Fog
        51|53|55) echo " " ;;   # Drizzle
        61|63|65) echo " " ;;   # Rain
        71|73|75) echo " " ;;    # Snow
        80|81|82) echo " " ;;   # Showers
        95|96|99) echo " " ;;    # Thunderstorm
        *) echo "?" ;;            # Unknown
    esac
}

# Check if cache is valid
is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] || return 1
    
    local cache_time current_time
    cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    current_time=$(date +%s)
    
    (( current_time - cache_time < CACHE_DURATION ))
}

# Fetch weather data
fetch_weather() {
    curl -sf --max-time 5 \
        "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current_weather=true" \
        2>/dev/null
}

# Main execution
main() {
    # Use cached data if valid
    if is_cache_valid; then
        cat "$CACHE_FILE"
        exit 0
    fi
    
    # Fetch fresh data
    local weather_json
    weather_json=$(fetch_weather)
    
    if [[ -z "$weather_json" ]]; then
        # Return error state for Waybar
        echo '{"text": "⚠️", "tooltip": "Weather unavailable"}'
        exit 0
    fi
    
    # Parse response
    local temp condition_code
    temp=$(echo "$weather_json" | jq -r '.current_weather.temperature // "N/A"')
    condition_code=$(echo "$weather_json" | jq -r '.current_weather.weathercode // 999')
    
    # Validate parsed data
    if [[ "$temp" == "N/A" ]] || [[ "$condition_code" == "999" ]]; then
        echo '{"text": "⚠️", "tooltip": "Invalid weather data"}'
        exit 0
    fi
    
    # Generate output
    local emoji
    emoji=$(get_weather_emoji "$condition_code")
    
    # Build JSON manually to avoid jq issues
    printf '{"text": "%s %s°C", "tooltip": "%s"}\n' "$emoji" "$temp" "$CITY"
    
    # Cache the result
    mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null
    printf '{"text": "%s %s°C", "tooltip": "%s"}\n' "$emoji" "$temp" "$CITY" > "$CACHE_FILE"
}

main "$@"