#!/bin/bash
# Shubham OS Update 9 — SIRF swagat awaaz (Adam-jaisi bhaari awaaz: "Welcome to Shubham OS").
# Condition: Live me OS on hote hi (desktop aate hi); Install me lock/login screen ke BAAD.
# Panel ya kisi setting ko haath NAHI lagata — sirf awaaz wali file + autostart.
# pkexec se root me chalta hai. Live aur install dono par chalega.
REPO_RAW="https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main"
echo "Shubham OS Update 9 (swagat awaaz) lag raha hai..."

# Awaaz wali file (base64 -> wav)
mkdir -p /usr/share/shubham-os
curl -fsSL "$REPO_RAW/apps/shubham-greeting.b64" -o /tmp/shubham-greeting.b64 || exit 1
base64 -d /tmp/shubham-greeting.b64 > /usr/share/shubham-os/greeting.wav || exit 1
rm -f /tmp/shubham-greeting.b64

# Bajane wala script
curl -fsSL "$REPO_RAW/apps/shubham-greeting" -o /usr/local/bin/shubham-greeting || exit 1
chmod +x /usr/local/bin/shubham-greeting

# Autostart: session (desktop) shuru hote hi chalega — lock screen se pehle kabhi nahi
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/shubham-greeting.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Shubham OS Swagat Awaaz
Exec=/usr/local/bin/shubham-greeting
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# Abhi chal rahe session me EK baar baja kar dikha do (turant test)
REAL_UID="${PKEXEC_UID:-1000}"
REAL_USER=$(getent passwd "$REAL_UID" | cut -d: -f1)
[ -z "$REAL_USER" ] && REAL_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -n "$REAL_USER" ]; then
  RUID=$(id -u "$REAL_USER")
  if [ -S "/run/user/$RUID/bus" ]; then
    runuser -u "$REAL_USER" -- env DISPLAY=:0 XDG_RUNTIME_DIR="/run/user/$RUID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$RUID/bus" /usr/local/bin/shubham-greeting >/dev/null 2>&1 &
  fi
fi

echo 9 > /etc/shubham-os-version
echo "Shubham OS Update 9 ho gaya! Awaaz abhi ek baar baji hogi; ab har baar OS/login par bajegi."
