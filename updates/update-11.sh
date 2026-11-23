#!/bin/bash
# Shubham OS Update 11 - Special Features, Batch 1.
# Adds the "Shubham OS Special Features" menu section and five features:
# Net Fix, History File, WiFi Password, Net Speed and Error Guide,
# plus the shubham-help command. Nothing else is touched.
# Runs as root via pkexec, on Live and installed systems.
set -e
BASE="https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main"
echo "Shubham OS Update 11 (Special Features - Batch 1) is being applied..."

echo "Getting the feature commands..."
for f in shubham-help shubham-netfix shubham-history shubham-wifi shubham-speed shubham-error; do
  curl -fsSL "$BASE/scripts/$f" -o "/usr/local/bin/$f"
  chmod 755 "/usr/local/bin/$f"
  echo "  $f ready"
done

echo "Getting the menu entries..."
mkdir -p /usr/share/applications /usr/share/desktop-directories /etc/xdg/menus/applications-merged
for f in shubham-netfix.desktop shubham-history.desktop shubham-wifi.desktop shubham-speed.desktop shubham-error.desktop; do
  curl -fsSL "$BASE/apps/$f" -o "/usr/share/applications/$f"
done
curl -fsSL "$BASE/apps/shubham-special.directory" -o /usr/share/desktop-directories/shubham-special.directory
curl -fsSL "$BASE/apps/shubham-special.menu" -o /etc/xdg/menus/applications-merged/shubham-special.menu

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi

echo 11 > /etc/shubham-os-version
echo "Shubham OS Update 11 done!"
echo "Open the menu - Shubham OS Special Features - or type shubham-help in a terminal."
