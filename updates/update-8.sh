#!/bin/bash
# Shubham OS Update 8 — SURAKSHIT panel-neeche fix.
# Update 7 me panel-restart wala command ulta pad gaya tha (panel band ho gaya).
# Is update me koi restart nahi hota: sirf values set hoti hain,
# panel agle login/restart par khud neeche aata hai.
# pkexec se root me chalta hai. Live aur install dono par chalega.
REPO_RAW="https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main"
echo "Shubham OS Update 8 lag raha hai..."

# --- Naam wala fix (purana, pakka rakha hai) ---
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

# --- Purani (khatarnak) machinery hatao ---
rm -f /etc/xdg/autostart/shubham-dock-fix.desktop /usr/local/bin/shubham-dock-fix
rm -f /etc/xdg/autostart/shubham-panel-bottom.desktop /usr/local/bin/shubham-panel-bottom

# --- Bar fixer: script + autostart (bina restart ke) ---
curl -fsSL "$REPO_RAW/apps/shubham-bar-fix.sh" -o /usr/local/bin/shubham-bar-fix || exit 1
chmod +x /usr/local/bin/shubham-bar-fix
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/shubham-bar-fix.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Shubham OS Bar Fix
Exec=/usr/local/bin/shubham-bar-fix
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# --- Chal rahe session me values abhi set kar do (sirf xfconf, koi restart nahi) ---
if [ -n "$REAL_USER" ]; then
  RUID=$(id -u "$REAL_USER")
  if [ -S "/run/user/$RUID/bus" ]; then
    runuser -u "$REAL_USER" -- env DISPLAY=:0 XDG_RUNTIME_DIR="/run/user/$RUID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$RUID/bus" /usr/local/bin/shubham-bar-fix || true
  fi
fi

echo 8 > /etc/shubham-os-version
echo "Shubham OS Update 8 ho gaya! Ab ek baar LOGOUT karke wapas LOGIN karo — panel neeche aayega."
