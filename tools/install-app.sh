#!/bin/bash
# Install the debug APK on the USB-connected phone. Uses the Windows adb.exe;
# never install adb inside WSL (two adb servers fight over port 5037).
set -e; source "$(dirname "$0")/env.sh"
APK="$REPO_WSL/app/app/build/outputs/apk/debug/app-debug.apk"
[ -f "$APK" ] || { echo "No APK. Run tools/build-app.sh first."; exit 1; }
"$ADB" devices | tr -d '\r'
"$ADB" install -r "$(wslpath -w "$APK")" | tr -d '\r'
