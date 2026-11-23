#!/bin/bash
# ShubhamOS Update — background checker (runs at login)
# Live mode: a new version installs itself (auto). Install mode: notification only.
STAMP="$HOME/.cache/shubham-update-lastcheck"
mkdir -p "$(dirname "$STAMP")"
IS_LIVE=0
grep -q "boot=live" /proc/cmdline 2>/dev/null && IS_LIVE=1
# Install mode checks only once a day; Live checks on every boot (the stamp resets anyway)
if [ "$IS_LIVE" = "0" ]; then
  NOW=$(date +%s); LAST=0
  [ -f "$STAMP" ] && LAST=$(cat "$STAMP" 2>/dev/null || echo 0)
  [ $((NOW - LAST)) -lt 86400 ] && exit 0
  echo "$NOW" > "$STAMP"
fi
# Wait for the network (up to ~60 seconds)
INFO=""
for i in $(seq 1 12); do
  INFO=$(curl -fsSL --max-time 10 "https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main/updates/version.txt" 2>/dev/null) && [ -n "$INFO" ] && break
  sleep 5
done
[ -z "$INFO" ] && exit 0
CUR=1
[ -f /etc/shubham-os-version ] && CUR=$(cat /etc/shubham-os-version 2>/dev/null || echo 1)
LATEST=$(echo "$INFO" | awk -F= '$1=="VERSION" {print $2}')
[ -z "$LATEST" ] && exit 0
if [ "$LATEST" -gt "$CUR" ] 2>/dev/null; then
  if [ "$IS_LIVE" = "1" ] && [ -x /usr/local/bin/shubham-autoupdate ]; then
    notify-send -i shubham-os-logo "ShubhamOS Update" "New version $LATEST found — installing it automatically in Live..." 2>/dev/null || true
    sudo -n /usr/local/bin/shubham-autoupdate >/dev/null 2>&1
    xfce4-panel -r >/dev/null 2>&1 || true
    notify-send -i shubham-os-logo "ShubhamOS Update" "Done! You are now running the latest Shubham OS $LATEST in Live." 2>/dev/null || true
  else
    notify-send -i shubham-os-logo "ShubhamOS Update" "A new update is available: Shubham OS $LATEST — open ShubhamOS Update and download it." 2>/dev/null || true
  fi
fi
exit 0
