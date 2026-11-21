#!/bin/bash
# Shubham OS Update 3 — purani install/Live par naye features lagata hai.
# pkexec se root me chalta hai. Live mode me test ke liye bhi chalega (restart par Live reset hoga).
REPO_RAW="https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main"
echo "Shubham OS Update 3 lag raha hai..."

# Toggle commands (gehara switch)
curl -fsSL "$REPO_RAW/scripts/shubham-windows" -o /usr/local/bin/shubham-windows || exit 1
curl -fsSL "$REPO_RAW/scripts/shubham-kali"    -o /usr/local/bin/shubham-kali || exit 1
chmod +x /usr/local/bin/shubham-windows /usr/local/bin/shubham-kali

# Updater app + uska menu entry
curl -fsSL "$REPO_RAW/apps/shubham-update.py"      -o /usr/local/bin/shubham-update || exit 1
chmod +x /usr/local/bin/shubham-update
curl -fsSL "$REPO_RAW/apps/shubham-update.desktop" -o /usr/share/applications/shubham-update.desktop || true
curl -fsSL "$REPO_RAW/apps/shubham-update-check.sh" -o /usr/local/bin/shubham-update-check || true
chmod +x /usr/local/bin/shubham-update-check 2>/dev/null || true
mkdir -p /etc/xdg/autostart
curl -fsSL "$REPO_RAW/apps/shubham-update-autostart.desktop" -o /etc/xdg/autostart/shubham-update-autostart.desktop || true

# Images (repo ke IMAGE-URLS.txt se taaza link)
IMG_LIST=$(curl -fsSL "$REPO_RAW/images/IMAGE-URLS.txt" || echo "")
img_url() { echo "$IMG_LIST" | awk -v f="$1" '$1==f {print $2}'; }
mkdir -p /usr/share/backgrounds/shubham-os
U=$(img_url shubham-os-logo.jpg);       [ -n "$U" ] && curl -fsSL "$U" -o /usr/share/pixmaps/shubham-os-logo.jpg || true
U=$(img_url wallpaper-kali-mode.jpg);   [ -n "$U" ] && curl -fsSL "$U" -o /usr/share/backgrounds/shubham-os/wallpaper-kali-mode.jpg || true
U=$(img_url wallpaper-windows-mode.jpg); [ -n "$U" ] && curl -fsSL "$U" -o /usr/share/backgrounds/shubham-os/wallpaper-windows-mode.jpg || true

# Menu me Kali naam -> Shubham OS
for f in /usr/share/applications/*.desktop; do
  case "$(basename "$f")" in
    *kali*) sed -i 's/^Name=Kali Linux/Name=Shubham OS/; s/^Name=Kali Tools/Name=Shubham OS Tools/; s/^Name=Kali Docs/Name=Shubham OS Docs/; s/^Name=Kali Bugs/Name=Shubham OS Bugs/' "$f" 2>/dev/null || true ;;
  esac
done

echo 3 > /etc/shubham-os-version

# Asli user ke session wale kaam
REAL_UID="${PKEXEC_UID:-1000}"
REAL_USER=$(getent passwd "$REAL_UID" | cut -d: -f1)
if [ -n "$REAL_USER" ]; then
  HOME_DIR=$(getent passwd "$REAL_UID" | cut -d: -f6)
  if getent passwd "$REAL_USER" | grep -q "Kali Live user"; then
    usermod -c "Shubham OS Live" "$REAL_USER" || true
  fi
  if [ -f /usr/share/pixmaps/shubham-os-logo.jpg ]; then
    cp /usr/share/pixmaps/shubham-os-logo.jpg "$HOME_DIR/.face" && chown "$REAL_USER" "$HOME_DIR/.face" || true
  fi
  curl -fsSL "$REPO_RAW/scripts/panel-pin.py" -o /tmp/panel-pin.py || true
  PANEL_XML="$HOME_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
  if [ -s /tmp/panel-pin.py ] && [ -f "$PANEL_XML" ]; then
    python3 /tmp/panel-pin.py "$PANEL_XML" /usr/share/applications || true
    chown "$REAL_USER" "$PANEL_XML" || true
  fi
  if [ -f /usr/share/backgrounds/shubham-os/wallpaper-kali-mode.jpg ]; then
    runuser -u "$REAL_USER" -- bash -c 'for p in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "last-image$"); do xfconf-query -c xfce4-desktop -p "$p" -s /usr/share/backgrounds/shubham-os/wallpaper-kali-mode.jpg 2>/dev/null; done' || true
  fi
fi
echo "Shubham OS Update 3 ho gaya! Restart karke dekho."
