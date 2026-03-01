#!/bin/bash

APP_NAME="$1"
FALLBACK="$2"
AERO="/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"

WINDOWS=$($AERO list-windows --all --format '%{window-id} %{app-name}' \
    | grep -i "$APP_NAME" \
    | awk '{print $1}')

if [ -z "$WINDOWS" ]; then
    open -a "$FALLBACK"
    exit 0
fi

FOCUSED=$($AERO list-windows --focused --format '%{window-id}' 2>/dev/null)

WINDOW_ARRAY=($WINDOWS)
COUNT=${#WINDOW_ARRAY[@]}

if [ "$COUNT" -eq 1 ]; then
    $AERO focus --window-id "${WINDOW_ARRAY[0]}"
    exit 0
fi

NEXT_INDEX=0
for i in "${!WINDOW_ARRAY[@]}"; do
    if [ "${WINDOW_ARRAY[$i]}" == "$FOCUSED" ]; then
        NEXT_INDEX=$(( (i + 1) % COUNT ))
        break
    fi
done

$AERO focus --window-id "${WINDOW_ARRAY[$NEXT_INDEX]}"