#!/bin/bash
# Upload the last build. Put the Stick in download mode first:
# hold the side button ~2 s until the green LED blinks.
set -e; source "$(dirname "$0")/env.sh"
PORT="${1:-$("$(dirname "$0")/find-port.sh")}"
[ -n "$PORT" ] || { echo "No Stick found on USB (Espressif VID 0x303a)."; exit 1; }
echo "Flashing via $PORT"
"$ARDUINO_CLI" upload --fqbn "$FQBN" --input-dir "$FW_BUILD_WIN" -p "$PORT" 2>&1 | tr -d '\r' | tail -15
