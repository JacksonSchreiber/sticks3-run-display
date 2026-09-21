#!/bin/bash
# Show the Stick's serial log for N seconds (default 15).
source "$(dirname "$0")/env.sh"
PORT="${2:-$("$(dirname "$0")/find-port.sh")}"
timeout "${1:-15}" "$ARDUINO_CLI" monitor -p "$PORT" --config baudrate=115200 --quiet 2>&1 | tr -d '\r'
