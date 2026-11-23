#!/bin/bash
# Shubham OS — sets the values to move the main panel to the bottom from INSIDE the session.
# Lesson from Update 7: "xfce4-panel -r" (restart) backfired — the panel closed
# and did not come back. This script has NO restart command.
# Only xfconf values are set; the panel will come to the bottom by itself at the next login.
sleep 3
LOG="$HOME/.cache/shubham-os-bar.log"
mkdir -p "$(dirname "$LOG")" 2>/dev/null

P1=$(xfconf-query -c xfce4-panel -p /panels/panel-1/position 2>/dev/null)
PANELS=$(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | grep -E '^[0-9]+$')
HAS2=0
for v in $PANELS; do [ "$v" = "2" ] && HAS2=1; done

if [ "$P1" = "p=10;x=0;y=0" ] && [ "$HAS2" = "0" ]; then
  exit 0
fi
echo "$(date) values are being set (p1='$P1' panel2=$HAS2)" >> "$LOG"

# Main panel to the bottom (bottom edge) — value only, no restart
xfconf-query -c xfce4-panel -p /panels/panel-1/position --create -t string -s "p=10;x=0;y=0" 2>>"$LOG"

# Remove Panel-2 (small dock strip) from the panels list
ARGS=""
for v in $PANELS; do
  [ "$v" != "2" ] && ARGS="$ARGS -t int -s $v"
done
[ -z "$ARGS" ] && ARGS="-t int -s 1"
xfconf-query -c xfce4-panel -p /panels --create $ARGS 2>>"$LOG"

echo "$(date) values set — the panel will move to the bottom at the next login" >> "$LOG"
