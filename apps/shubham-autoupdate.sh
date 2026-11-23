#!/bin/bash
# Shubham OS — Live Auto-Update (runs as root)
# When Live starts, if a new version is found, it downloads and installs it automatically.
LOG=/var/log/shubham-update.log
exec >> "$LOG" 2>&1
echo "=== $(date) autoupdate check ==="
CUR=1
[ -f /etc/shubham-os-version ] && CUR=$(cat /etc/shubham-os-version 2>/dev/null || echo 1)
INFO=$(curl -fsSL --max-time 20 "https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main/updates/version.txt") || exit 0
LATEST=$(echo "$INFO" | awk -F= '$1=="VERSION" {print $2}')
SCRIPT=$(echo "$INFO" | awk -F= '$1=="SCRIPT" {print substr($0, index($0,"=")+1)}')
[ -z "$LATEST" ] && exit 0
[ -z "$SCRIPT" ] && exit 0
if [ "$LATEST" -gt "$CUR" ] 2>/dev/null; then
  echo "New version $LATEST found — installing..."
  curl -fsSL --max-time 60 "$SCRIPT" -o /tmp/shubham-os-auto-update.sh || exit 0
  bash /tmp/shubham-os-auto-update.sh
  echo "Auto-update complete: the version is now $LATEST."
fi
exit 0
