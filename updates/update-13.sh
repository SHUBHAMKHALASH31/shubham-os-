#!/bin/bash
# Shubham OS Update 13 - menu fix only.
# The "Shubham OS Special Features" section did not appear in the menu,
# because the separate merged menu file is not read by this menu system.
# This update writes the section directly into the system menu file
# (/etc/xdg/menus/xfce-applications.menu), with a backup first and an
# XML check after. If anything is wrong, the original file is restored.
# It also re-installs the five menu entries and the section name file.
# Nothing else is touched. Runs as root via pkexec.
echo "Shubham OS Update 13 (menu fix) is being applied..."

mkdir -p /usr/share/applications /usr/share/desktop-directories

cat > /usr/share/desktop-directories/shubham-special.directory << 'SHUBHAM_DIR_13'
[Desktop Entry]
Type=Directory
Name=Shubham OS Special Features
Comment=Special tools of Shubham OS
Icon=applications-system
SHUBHAM_DIR_13

cat > /usr/share/applications/shubham-netfix.desktop << 'SHUBHAM_DESK_13A'
[Desktop Entry]
Type=Application
Name=Net Fix
Comment=Fix internet problems in one click
Exec=xfce4-terminal --hold -e shubham-netfix
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_13A

cat > /usr/share/applications/shubham-history.desktop << 'SHUBHAM_DESK_13B'
[Desktop Entry]
Type=Application
Name=History File
Comment=Save all terminal commands in one txt file
Exec=xfce4-terminal --hold -e shubham-history
Icon=utilities-terminal
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_13B

cat > /usr/share/applications/shubham-wifi.desktop << 'SHUBHAM_DESK_13C'
[Desktop Entry]
Type=Application
Name=WiFi Password
Comment=Show a saved WiFi password
Exec=xfce4-terminal --hold -e shubham-wifi
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_13C

cat > /usr/share/applications/shubham-speed.desktop << 'SHUBHAM_DESK_13D'
[Desktop Entry]
Type=Application
Name=Net Speed
Comment=Check internet speed
Exec=xfce4-terminal --hold -e shubham-speed
Icon=utilities-system-monitor
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_13D

cat > /usr/share/applications/shubham-error.desktop << 'SHUBHAM_DESK_13E'
[Desktop Entry]
Type=Application
Name=Error Guide
Comment=Understand any error in simple words
Exec=xfce4-terminal --hold -e shubham-error
Icon=dialog-information
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_13E

echo "Adding the section to the system menu file..."
python3 << 'SHUBHAM_PY_13'
import glob, os, shutil, sys
import xml.etree.ElementTree as ET

BLOCK = """<!-- Shubham OS Special Features (added by Shubham OS Update 13) -->
<Menu>
<Name>Shubham OS Special Features</Name>
<Directory>shubham-special.directory</Directory>
<Include>
<Category>X-Shubham-Special</Category>
</Include>
</Menu>
"""

candidates = []
xfce = "/etc/xdg/menus/xfce-applications.menu"
if os.path.exists(xfce):
    candidates.append(xfce)
for f in sorted(glob.glob("/etc/xdg/menus/*applications.menu")):
    if f not in candidates:
        candidates.append(f)

target = None
for f in candidates:
    try:
        with open(f, encoding="utf-8", errors="replace") as fh:
            data = fh.read()
        ET.fromstring(data)
        target = f
        break
    except Exception:
        continue

if target is None:
    print("PROBLEM: no readable system menu file found. Nothing was changed.")
    sys.exit(1)

with open(target, encoding="utf-8", errors="replace") as fh:
    data = fh.read()

if "Shubham OS Special Features" in data:
    print("The section is already in the menu file: " + target)
    sys.exit(0)

backup = target + ".bak-shubham13"
if not os.path.exists(backup):
    shutil.copy2(target, backup)

pos = data.rfind("</Menu>")
if pos == -1:
    print("PROBLEM: menu file has no closing Menu tag. Nothing was changed.")
    sys.exit(1)

newdata = data[:pos] + BLOCK + data[pos:]
try:
    ET.fromstring(newdata)
except Exception as e:
    print("PROBLEM: the changed menu file failed its check (%s). Original kept." % e)
    sys.exit(1)

tmp = target + ".tmp-shubham13"
with open(tmp, "w", encoding="utf-8") as fh:
    fh.write(newdata)
os.replace(tmp, target)
print("Section added to: " + target)
SHUBHAM_PY_13
PYRC=$?
if [ "$PYRC" -ne 0 ]; then
  echo "Shubham OS Update 13 FAILED at the menu step. Your old version is kept."
  exit 1
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi

echo "Checking every file..."
FAIL=0
grep -q "Shubham OS Special Features" /etc/xdg/menus/xfce-applications.menu 2>/dev/null || grep -lq "Shubham OS Special Features" /etc/xdg/menus/*applications.menu 2>/dev/null || FAIL=1
if [ "$FAIL" -ne 0 ]; then
  echo "  PROBLEM  the section is not in the menu file"
  echo "Shubham OS Update 13 FAILED. Your old version is kept."
  exit 1
fi
echo "  OK  menu section is in the system menu file"
for f in shubham-netfix.desktop shubham-history.desktop shubham-wifi.desktop shubham-speed.desktop shubham-error.desktop; do
  if [ -s "/usr/share/applications/$f" ]; then
    echo "  OK  $f"
  else
    echo "  PROBLEM  $f is missing or empty"
    FAIL=1
  fi
done
if [ "$FAIL" -ne 0 ]; then
  echo "Shubham OS Update 13 FAILED. Your old version is kept."
  exit 1
fi

echo 13 > /etc/shubham-os-version
echo "Shubham OS Update 13 done! Restart the system, then open the menu."
