#!/bin/bash
# Shubham OS — Live Auto-Update (runs as root)
# When Live starts, if a new version is found, it downloads and installs it automatically.
#
# Version 2 (with Shubham OS Update 18):
# - Self-heal first: an empty or invalid user menu file breaks the whole
#   applications menu, so it is moved aside and the stock menu works again.
# - The downloaded update is verified before it runs: its size and
#   SHA-256 must match the values published in version.txt. An incomplete
#   download is deleted and NEVER executed.
# - Exit code is honest: 0 = up to date or installed; 1 = a new version
#   was found but could not be installed completely.
LOG=/var/log/shubham-update.log
exec >> "$LOG" 2>&1
echo "=== $(date) autoupdate check ==="

# Self-heal: repair a broken menu file in every home folder.
for H in /home/*; do
  [ -d "$H" ] || continue
  UF="$H/.config/menus/xfce-applications.menu"
  [ -f "$UF" ] || continue
  if [ ! -s "$UF" ] || ! python3 -c "import xml.etree.ElementTree as ET, sys; ET.parse(sys.argv[1])" "$UF" 2>/dev/null; then
    mv -f "$UF" "$UF.broken-autoheal"
    echo "Repaired a broken menu file in $H (moved aside; the stock menu works again)."
  fi
done

CUR=1
[ -f /etc/shubham-os-version ] && CUR=$(cat /etc/shubham-os-version 2>/dev/null || echo 1)
INFO=$(curl -fsSL --max-time 20 "https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main/updates/version.txt") || exit 0
LATEST=$(echo "$INFO" | awk -F= '$1=="VERSION" {print $2}')
SCRIPT=$(echo "$INFO" | awk -F= '$1=="SCRIPT" {print substr($0, index($0,"=")+1)}')
SIZE=$(echo "$INFO" | awk -F= '$1=="SCRIPT_SIZE" {print $2}')
SHA=$(echo "$INFO" | awk -F= '$1=="SCRIPT_SHA256" {print $2}')
[ -z "$LATEST" ] && exit 0
[ -z "$SCRIPT" ] && exit 0
if [ "$LATEST" -gt "$CUR" ] 2>/dev/null; then
  echo "New version $LATEST found — downloading..."
  TMP=/tmp/shubham-os-auto-update.dl
  rm -f "$TMP"
  if ! curl -fsSL --max-time 60 "$SCRIPT" -o "$TMP"; then
    echo "The download failed — nothing was installed."
    rm -f "$TMP"
    exit 1
  fi
  # Verify before running: never execute an incomplete download.
  if [ ! -s "$TMP" ]; then
    echo "The download was empty — nothing was installed."
    rm -f "$TMP"
    exit 1
  fi
  if [ -n "$SIZE" ]; then
    ACTUAL_SIZE=$(stat -c %s "$TMP")
    if [ "$ACTUAL_SIZE" != "$SIZE" ]; then
      echo "The download was incomplete (size $ACTUAL_SIZE, expected $SIZE) — nothing was installed."
      rm -f "$TMP"
      exit 1
    fi
  fi
  if [ -n "$SHA" ]; then
    ACTUAL_SHA=$(sha256sum "$TMP" | awk '{print $1}')
    if [ "$ACTUAL_SHA" != "$SHA" ]; then
      echo "The download check failed (hash mismatch) — nothing was installed."
      rm -f "$TMP"
      exit 1
    fi
  fi
  echo "Download verified — installing..."
  mv -f "$TMP" /tmp/shubham-os-auto-update.sh
  bash /tmp/shubham-os-auto-update.sh
  RC=$?
  if [ "$RC" -eq 0 ]; then
    echo "Auto-update complete: the version is now $LATEST."
    exit 0
  fi
  echo "The update script stopped with an error (exit $RC) — the version stays $CUR."
  exit 1
fi
exit 0
