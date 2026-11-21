#!/bin/bash
# ShubhamOS Update — background checker (login par chalta hai)
# GitHub par naya version mile to notification deta hai. Din me ek baar hi check karta hai.
STAMP="$HOME/.cache/shubham-update-lastcheck"
mkdir -p "$(dirname "$STAMP")"
NOW=$(date +%s)
LAST=0
[ -f "$STAMP" ] && LAST=$(cat "$STAMP" 2>/dev/null || echo 0)
# 24 ghante = 86400 sec; usse pehle dobara check nahi
[ $((NOW - LAST)) -lt 86400 ] && exit 0
echo "$NOW" > "$STAMP"

CUR=1
[ -f /etc/shubham-os-version ] && CUR=$(cat /etc/shubham-os-version 2>/dev/null || echo 1)
INFO=$(curl -fsSL --max-time 15 "https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main/updates/version.txt" 2>/dev/null) || exit 0
LATEST=$(echo "$INFO" | awk -F= '$1=="VERSION" {print $2}')
[ -z "$LATEST" ] && exit 0
if [ "$LATEST" -gt "$CUR" ] 2>/dev/null; then
  notify-send -i shubham-os-logo "ShubhamOS Update" "Naya update uplabdh hai: Shubham OS $LATEST — ShubhamOS Update kholkar Download karo." 2>/dev/null || true
fi
exit 0
