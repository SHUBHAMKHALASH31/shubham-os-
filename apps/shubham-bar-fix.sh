#!/bin/bash
# Shubham OS — main panel ko neeche le jaane ki values SESSION ke andar set karta hai.
# Update 7 ki seekh: "xfce4-panel -r" (restart) ulta pad gaya tha — panel band
# hokar wapas nahi aaya. Is script me KOI restart command nahi hai.
# Sirf xfconf values set hoti hain; panel agle login par khud neeche aayega.
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
echo "$(date) values set ho rahi hain (p1='$P1' panel2=$HAS2)" >> "$LOG"

# Main panel neeche (bottom edge) — sirf value, koi restart nahi
xfconf-query -c xfce4-panel -p /panels/panel-1/position --create -t string -s "p=10;x=0;y=0" 2>>"$LOG"

# Panel-2 (chhoti dock strip) panels list se hata do
ARGS=""
for v in $PANELS; do
  [ "$v" != "2" ] && ARGS="$ARGS -t int -s $v"
done
[ -z "$ARGS" ] && ARGS="-t int -s 1"
xfconf-query -c xfce4-panel -p /panels --create $ARGS 2>>"$LOG"

echo "$(date) values set — agle login par panel neeche aayega" >> "$LOG"
