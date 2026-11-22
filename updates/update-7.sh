#!/bin/bash
# Shubham OS Update 7 — main panel neeche + Update 6 ki dock strip khatam.
# Upar wala bar (menu, apps, workspaces, ghadi) ab neeche aayega, Windows ki tarah.
# pkexec se root me chalta hai. Live aur install dono par chalega.
REPO_RAW="https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main"
echo "Shubham OS Update 7 lag raha hai..."

# --- Naam wala fix (Update 6 wala, yahan bhi pakka rakha hai) ---
REAL_UID="${PKEXEC_UID:-1000}"
REAL_USER=$(getent passwd "$REAL_UID" | cut -d: -f1)
[ -z "$REAL_USER" ] && REAL_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -n "$REAL_USER" ]; then
  usermod -c "Shubham OS Live" "$REAL_USER" || true
fi
for d in /usr/lib/live/config /etc/live/config /lib/live/config; do
  [ -d "$d" ] || continue
  grep -rl "Kali Live user" "$d" 2>/dev/null | while read -r f; do
    sed -i 's/Kali Live user/Shubham OS Live/g' "$f" 2>/dev/null || true
  done
done

# --- Purani dock wali machinery hatao (warna wo panel-2 wapas bana degi) ---
rm -f /etc/xdg/autostart/shubham-dock-fix.desktop /usr/local/bin/shubham-dock-fix

# --- Panel-bottom fixer: script + autostart ---
curl -fsSL "$REPO_RAW/apps/shubham-panel-bottom.sh" -o /usr/local/bin/shubham-panel-bottom || exit 1
chmod +x /usr/local/bin/shubham-panel-bottom
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/shubham-panel-bottom.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Shubham OS Panel Bottom
Exec=/usr/local/bin/shubham-panel-bottom
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# --- Chal rahe session me turant bhi laga do (sahi D-Bus ke saath) ---
if [ -n "$REAL_USER" ]; then
  RUID=$(id -u "$REAL_USER")
  if [ -S "/run/user/$RUID/bus" ]; then
    runuser -u "$REAL_USER" -- env DISPLAY=:0 XDG_RUNTIME_DIR="/run/user/$RUID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$RUID/bus" /usr/local/bin/shubham-panel-bottom || true
  fi
fi

echo 7 > /etc/shubham-os-version
echo "Shubham OS Update 7 ho gaya! Upar wala bar ab neeche aana chahiye."
