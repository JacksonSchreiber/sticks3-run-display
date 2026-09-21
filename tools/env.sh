# Source this from the other tools/*.sh scripts.
# Everything here runs as a *Windows* process via WSL interop, so builds never
# use WSL memory. Never compile firmware or run Gradle inside WSL.
REPO_WSL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_WIN="$(wslpath -w "$REPO_WSL")"
WINHOME_WSL="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"

ARDUINO_CLI="/mnt/c/Program Files/Arduino CLI/arduino-cli.exe"
FQBN="m5stack:esp32:m5stack_sticks3"
# Build output lives outside the repo so it never lands in git or a synced folder.
FW_BUILD_WIN='C:\dev\.build\runstick'

JAVA_HOME_WSL="$(ls -d "/mnt/c/Program Files/Eclipse Adoptium/"jdk-17* 2>/dev/null | head -1)"
ANDROID_HOME_WSL="$WINHOME_WSL/AppData/Local/Android/Sdk"
ADB="$(ls "$WINHOME_WSL"/AppData/Local/Microsoft/WinGet/Packages/Google.PlatformTools_*/platform-tools/adb.exe 2>/dev/null | head -1)"
