#!/bin/bash
# Shubham OS — main panel (menu/apps/ghadi wala bar) ko UPAR se hata kar
# NEECHE le jaata hai, aur Update 6 wali chhoti dock strip (panel-2) hata deta hai.
# Session ke andar xfconf-query se lagta hai — value pakki rehti hai.
# Kaam pehle se ho chuka ho to kuch nahi karta (har login par chal sakta hai).
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
echo "$(date) panel neeche ja raha hai (p1='$P1' panel2=$HAS2)" >> "$LOG"

# Main panel neeche (bottom edge)
xfconf-query -c xfce4-panel -p /panels/panel-1/position --create -t string -s "p=10;x=0;y=0" 2>>"$LOG"

# Panel-2 (chhoti dock strip) ko panels list se hata do
ARGS=""
for v in $PANELS; do
  [ "$v" != "2" ] && ARGS="$ARGS -t int -s $v"
done
[ -z "$ARGS" ] && ARGS="-t int -s 1"
xfconf-query -c xfce4-panel -p /panels --create $ARGS 2>>"$LOG"

xfce4-panel -r >/dev/null 2>&1
echo "$(date) ho gaya — panel neeche, strip gayab" >> "$LOG"
