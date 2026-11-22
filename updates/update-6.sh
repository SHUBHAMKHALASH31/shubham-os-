#!/bin/bash
# Shubham OS Update 6 — "Kali Live user" naam fix + Mac-style dock.
# pkexec se root me chalta hai. Live aur install dono par chalega.
REPO_RAW="https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main"
echo "Shubham OS Update 6 lag raha hai..."

# --- 1) Naam: asli user ka display name "Shubham OS Live" ---
REAL_UID="${PKEXEC_UID:-1000}"
REAL_USER=$(getent passwd "$REAL_UID" | cut -d: -f1)
[ -z "$REAL_USER" ] && REAL_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -n "$REAL_USER" ]; then
  usermod -c "Shubham OS Live" "$REAL_USER" || true
  echo "Naam badla: $REAL_USER -> Shubham OS Live"
fi
# Install hue system me har boot par naam sahi aaye — live-config ke source me bhi badlo
for d in /usr/lib/live/config /etc/live/config /lib/live/config; do
  [ -d "$d" ] || continue
  grep -rl "Kali Live user" "$d" 2>/dev/null | while read -r f; do
    sed -i 's/Kali Live user/Shubham OS Live/g' "$f" 2>/dev/null || true
  done
done

# --- 2) Dock fixer: session ke andar chalne wala script + autostart ---
curl -fsSL "$REPO_RAW/apps/shubham-dock-fix.sh" -o /usr/local/bin/shubham-dock-fix || exit 1
chmod +x /usr/local/bin/shubham-dock-fix
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/shubham-dock-fix.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Shubham OS Dock
Exec=/usr/local/bin/shubham-dock-fix
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# --- 3) Chal rahe session me turant bhi laga do (sahi D-Bus ke saath) ---
if [ -n "$REAL_USER" ]; then
  RUID=$(id -u "$REAL_USER")
  if [ -S "/run/user/$RUID/bus" ]; then
    runuser -u "$REAL_USER" -- env DISPLAY=:0 XDG_RUNTIME_DIR="/run/user/$RUID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$RUID/bus" /usr/local/bin/shubham-dock-fix || true
  fi
fi

echo 6 > /etc/shubham-os-version
echo "Shubham OS Update 6 ho gaya! Dock neeche dikhna chahiye; naam menu me panel restart ke baad badlega."
