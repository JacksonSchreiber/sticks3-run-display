#!/bin/bash
# Build (and unit-test) the Android app with Gradle on the Windows side.
# Usage: build-app.sh [gradle tasks...]   default: test assembleDebug
set -e; source "$(dirname "$0")/env.sh"
TASKS="${*:-testDebugUnitTest assembleDebug}"
cat > /mnt/c/dev/.cache/run_gradle.bat <<BAT
@echo off
set "JAVA_HOME=$(wslpath -w "$JAVA_HOME_WSL")"
set "ANDROID_HOME=$(wslpath -w "$ANDROID_HOME_WSL")"
cd /d "$REPO_WIN\\app"
call gradlew.bat --no-daemon --console=plain $TASKS
BAT
sed -i 's/$/\r/' /mnt/c/dev/.cache/run_gradle.bat
cmd.exe /c 'C:\dev\.cache\run_gradle.bat' 2>&1 | tr -d '\r'
