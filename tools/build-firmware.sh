#!/bin/bash
# Compile the firmware with arduino-cli on the Windows side.
set -e; source "$(dirname "$0")/env.sh"
"$ARDUINO_CLI" compile --fqbn "$FQBN" --build-path "$FW_BUILD_WIN" \
  --warnings default "$@" "$REPO_WIN\\firmware\\runstick" 2>&1 | tr -d '\r'
