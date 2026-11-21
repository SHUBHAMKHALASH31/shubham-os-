#!/bin/bash
# Shubham OS — session ke andar lagne wale badlav (wallpaper, dock)
# Update ke baad agle login par EK baar chalta hai, phir khud hat jata hai.
sleep 3
WP=/usr/share/backgrounds/shubham-os/wallpaper-kali-mode.jpg
if [ -f "$WP" ]; then
  for p in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "last-image$"); do
    xfconf-query -c xfce4-desktop -p "$p" -s "$WP" 2>/dev/null
  done
fi
PANEL_XML="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [ -f "$PANEL_XML" ] && [ -f /usr/local/bin/panel-pin.py ]; then
  python3 /usr/local/bin/panel-pin.py "$PANEL_XML" /usr/share/applications >/dev/null 2>&1
  xfce4-panel -r >/dev/null 2>&1
fi
rm -f "$HOME/.config/autostart/shubham-session-fix.desktop"
