#!/bin/bash
# Shubham OS — Mac-style dock (panel-2) SESSION ke andar se lagata hai.
# Pichli galti: panel ki file peeche se badli gayi thi, chalte hue xfconfd ne
# use overwrite kar diya — dock kabhi dikha hi nahi.
# Is baar xfconf-query seedha xfconfd se baat karta hai, value pakki rehti hai.
# Dock sahi haal me pehle se ho to kuch nahi karta (har login par chal sakta hai).
sleep 4
LOG="$HOME/.cache/shubham-os-dock.log"
mkdir -p "$(dirname "$LOG")" 2>/dev/null

POS=$(xfconf-query -c xfce4-panel -p /panels/panel-2/position 2>/dev/null)
IDS=$(xfconf-query -c xfce4-panel -p /panels/panel-2/plugin-ids 2>/dev/null | grep -E '^[0-9]+$')
if [ "$POS" = "p=10;x=0;y=0" ] && [ -n "$IDS" ]; then
  exit 0
fi
echo "$(date) dock fix chal raha hai (pos='$POS')" >> "$LOG"

# --- Dock ke scalar gun (neeche beech, bada size, halki transparency) ---
setp() { xfconf-query -c xfce4-panel -p "/panels/panel-2/$1" --create -t "$2" -s "$3" 2>>"$LOG"; }
setp position string "p=10;x=0;y=0"
setp length uint 1
setp length-adjust bool true
setp size uint 44
setp icon-size uint 34
setp mode uint 0
setp autohide-behavior uint 0
setp background-style uint 1
setp background-alpha uint 70

# --- Launchers: plugin-ids khaali ho tabhi banao ---
if [ -z "$IDS" ]; then
  MAXID=0
  for n in $(xfconf-query -c xfce4-panel -p /plugins -l 2>/dev/null | grep -o 'plugin-[0-9]*' | grep -o '[0-9]*$'); do
    [ "$n" -gt "$MAXID" ] && MAXID=$n
  done
  NEXT=$((MAXID + 1))
  APPS_DIR=/usr/share/applications
  DOCK_IDS=""
  add_one() {
    # Pehla maujuda alternative chun lo
    local desk=""
    for c in "$@"; do
      if [ -f "$APPS_DIR/$c" ]; then desk="$c"; break; fi
    done
    [ -z "$desk" ] && return
    local id=$NEXT; NEXT=$((NEXT + 1))
    xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" --create -t string -s "launcher" 2>>"$LOG"
    xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" --create -t string -s "$desk" 2>>"$LOG"
    DOCK_IDS="$DOCK_IDS $id"
  }
  add_one firefox-esr.desktop firefox.desktop
  add_one org.xfce.Thunar.desktop thunar.desktop
  add_one xfce4-terminal.desktop
  add_one shubham-update.desktop
  add_one xfce4-settings-manager.desktop
  if [ -n "$DOCK_IDS" ]; then
    ARGS=""
    for id in $DOCK_IDS; do ARGS="$ARGS -t int -s $id"; done
    xfconf-query -c xfce4-panel -p /panels/panel-2/plugin-ids --create $ARGS 2>>"$LOG"
  fi
fi

# --- /panels list me 2 pakka karo ---
CUR=$(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | grep -E '^[0-9]+$')
ARGS=""; HAS2=0
for v in $CUR; do
  ARGS="$ARGS -t int -s $v"
  [ "$v" = "2" ] && HAS2=1
done
[ -z "$ARGS" ] && ARGS="-t int -s 1"
[ "$HAS2" = "0" ] && ARGS="$ARGS -t int -s 2"
xfconf-query -c xfce4-panel -p /panels --create $ARGS 2>>"$LOG"

xfce4-panel -r >/dev/null 2>&1
echo "$(date) dock fix ho gaya, panel restart" >> "$LOG"
