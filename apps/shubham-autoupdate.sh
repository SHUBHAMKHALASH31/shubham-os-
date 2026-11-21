#!/bin/bash
# Shubham OS — Live Auto-Update (root me chalta hai)
# Live start hone par naya version mile to khud download karke laga deta hai.
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
  echo "Naya version $LATEST mil gaya — lagaya ja raha hai..."
  curl -fsSL --max-time 60 "$SCRIPT" -o /tmp/shubham-os-auto-update.sh || exit 0
  bash /tmp/shubham-os-auto-update.sh
  echo "Auto-update pura: ab version $LATEST hai."
fi
exit 0
