#!/bin/bash

while true; do
    # Date
    DATE=$(date +'%Y-%m-%d %X')

    # Volume (via pactl)
    VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1)
    MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
    if [ "$MUTE" = "yes" ]; then
        VOL="Muted"
    fi

    # CPU load
    CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage) "%"}')

    # Battery (acpi needed)
    if command -v acpi >/dev/null; then
        BATT=$(acpi -b | awk -F', ' '{print $2}' | head -n1)
    else
        BATT=""
    fi

    # Print to swaybar
    echo "CPU $CPU  VOL $VOL  BAT $BATT  $DATE"

    sleep 2
done
