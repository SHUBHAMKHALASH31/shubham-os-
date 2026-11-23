#!/bin/bash
# Shubham OS — moves the main panel (the bar with menu/apps/clock) from the TOP
# to the BOTTOM, and removes the small dock strip (panel-2) from Update 6.
# Applied from inside the session with xfconf-query — the value stays fixed.
# If the work is already done, it does nothing (can run at every login).
sleep 3
LOG="$HOME/.cache/shubham-os-panel.log"
mkdir -p "$(dirname "$LOG")" 2>/dev/null

P1=$(xfconf-query -c xfce4-panel -p /panels/panel-1/position 2>/dev/null)
PANELS=$(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | grep -E '^[0-9]+$')
HAS2=0
for v in $PANELS; do [ "$v" = "2" ] && HAS2=1; done

if [ "$P1" = "p=10;x=0;y=0" ] && [ "$HAS2" = "0" ]; then
  exit 0
fi
echo "$(date) panel is moving to the bottom (p1='$P1' panel2=$HAS2)" >> "$LOG"

# Main panel to the bottom (bottom edge)
xfconf-query -c xfce4-panel -p /panels/panel-1/position --create -t string -s "p=10;x=0;y=0" 2>>"$LOG"

# Remove Panel-2 (small dock strip) from the panels list
ARGS=""
for v in $PANELS; do
  [ "$v" != "2" ] && ARGS="$ARGS -t int -s $v"
done
[ -z "$ARGS" ] && ARGS="-t int -s 1"
xfconf-query -c xfce4-panel -p /panels --create $ARGS 2>>"$LOG"

xfce4-panel -r >/dev/null 2>&1
echo "$(date) done — panel at bottom, strip gone" >> "$LOG"
