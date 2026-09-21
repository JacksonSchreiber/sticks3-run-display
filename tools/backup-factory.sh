#!/bin/bash
# Read the whole 8 MB flash to a file BEFORE the first upload. M5Stack publishes
# no restore image for the StickS3, so this is the only way back to stock.
set -e; source "$(dirname "$0")/env.sh"
PORT="${1:-$("$(dirname "$0")/find-port.sh")}"
[ -n "$PORT" ] || { echo "No Stick found on USB."; exit 1; }
ESPTOOL="$(ls "$WINHOME_WSL"/AppData/Local/Arduino15/packages/m5stack/tools/esptool_py/*/esptool.exe | head -1)"
mkdir -p /mnt/c/dev/backups
"$ESPTOOL" --chip esp32s3 --port "$PORT" --baud 921600 read_flash 0 0x800000 'C:\dev\backups\sticks3_factory_8MB.bin' 2>&1 | tr -d '\r' | tail -8
