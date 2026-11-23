#!/bin/bash
# Shubham OS Update 15 - the menu section, the Kali way (permanent).
# Kali's own sections (01 to 16) reach the menu through a file in
# /etc/xdg/menus/applications-merged/ whose root is named "Applications"
# and which carries its own Layout list. This update does the same:
#   1. It removes the section that Updates 13/14 wrote into the system
#      menu file, so that file returns to its original state.
#   2. It writes the section into applications-merged/shubham-special.menu
#      in Kali's own pattern, with its own Layout list, and pulls the five
#      apps in by category AND by file name (two ways, so one must work).
#   3. It re-installs the five menu entries and the section name file.
# Backups are made first and every file is checked at the end.
# Nothing else is touched. Runs as root via pkexec.
echo "Shubham OS Update 15 (menu section, the Kali way) is being applied..."

MENUFILE="/etc/xdg/menus/xfce-applications.menu"
MERGED="/etc/xdg/menus/applications-merged/shubham-special.menu"

echo "Step 1: cleaning the system menu file..."
python3 << 'SHUBHAM_PY_15'
import os, re, shutil, sys
import xml.etree.ElementTree as ET

TARGET = "/etc/xdg/menus/xfce-applications.menu"
if not os.path.exists(TARGET):
    print("PROBLEM: menu file not found. Nothing was changed.")
    sys.exit(1)

with open(TARGET, encoding="utf-8", errors="replace") as fh:
    data = fh.read()

backup = TARGET + ".bak-shubham15"
if not os.path.exists(backup):
    shutil.copy2(TARGET, backup)

new = data
# Remove the Menuname line added by Update 14.
new = new.replace("<Menuname>Shubham OS Special Features</Menuname>\n", "")
new = new.replace("<Menuname>Shubham OS Special Features</Menuname>", "")
# Remove the whole Menu block added by Update 13 (comment + block).
new = re.sub(r"<!-- Shubham OS Special Features \(added by Shubham OS Update 13\) -->\s*<Menu>.*?</Menu>\s*", "", new, flags=re.S)

if new != data:
    try:
        ET.fromstring(new)
    except Exception as e:
        print("PROBLEM: cleaned menu file failed its check (%s). Original kept." % e)
        sys.exit(1)
    tmp = TARGET + ".tmp-shubham15"
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write(new)
    os.replace(tmp, TARGET)
    print("System menu file cleaned.")
else:
    print("System menu file was already clean.")
SHUBHAM_PY_15
if [ "$?" -ne 0 ]; then
  echo "Shubham OS Update 15 FAILED at step 1. Your old version is kept."
  exit 1
fi

echo "Step 2: writing the section the Kali way..."
mkdir -p /etc/xdg/menus/applications-merged /usr/share/applications /usr/share/desktop-directories

cat > "$MERGED" << 'SHUBHAM_MERGED_15'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
<Name>Applications</Name>
<Layout>
<Menuname>Shubham OS Special Features</Menuname>
<Merge type="all"/>
</Layout>
<Menu>
<Name>Shubham OS Special Features</Name>
<Directory>shubham-special.directory</Directory>
<Include>
<Category>X-Shubham-Special</Category>
<Filename>shubham-netfix.desktop</Filename>
<Filename>shubham-history.desktop</Filename>
<Filename>shubham-wifi.desktop</Filename>
<Filename>shubham-speed.desktop</Filename>
<Filename>shubham-error.desktop</Filename>
</Include>
</Menu>
</Menu>
SHUBHAM_MERGED_15

cat > /usr/share/desktop-directories/shubham-special.directory << 'SHUBHAM_DIR_15'
[Desktop Entry]
Type=Directory
Name=Shubham OS Special Features
Comment=Special tools of Shubham OS
Icon=applications-system
SHUBHAM_DIR_15

cat > /usr/share/applications/shubham-netfix.desktop << 'SHUBHAM_DESK_15A'
[Desktop Entry]
Type=Application
Name=Net Fix
Comment=Fix internet problems in one click
Exec=xfce4-terminal --hold -e shubham-netfix
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_15A

cat > /usr/share/applications/shubham-history.desktop << 'SHUBHAM_DESK_15B'
[Desktop Entry]
Type=Application
Name=History File
Comment=Save all terminal commands in one txt file
Exec=xfce4-terminal --hold -e shubham-history
Icon=utilities-terminal
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_15B

cat > /usr/share/applications/shubham-wifi.desktop << 'SHUBHAM_DESK_15C'
[Desktop Entry]
Type=Application
Name=WiFi Password
Comment=Show a saved WiFi password
Exec=xfce4-terminal --hold -e shubham-wifi
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_15C

cat > /usr/share/applications/shubham-speed.desktop << 'SHUBHAM_DESK_15D'
[Desktop Entry]
Type=Application
Name=Net Speed
Comment=Check internet speed
Exec=xfce4-terminal --hold -e shubham-speed
Icon=utilities-system-monitor
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_15D

cat > /usr/share/applications/shubham-error.desktop << 'SHUBHAM_DESK_15E'
[Desktop Entry]
Type=Application
Name=Error Guide
Comment=Understand any error in simple words
Exec=xfce4-terminal --hold -e shubham-error
Icon=dialog-information
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_15E

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi

echo "Checking every file..."
FAIL=0
python3 -c "import xml.etree.ElementTree as ET; ET.parse('$MERGED')" 2>/dev/null && echo "  OK  merged menu file is valid" || { echo "  PROBLEM  merged menu file is not valid"; FAIL=1; }
grep -q "shubham-netfix.desktop" "$MERGED" && echo "  OK  the five apps are listed in the section" || { echo "  PROBLEM  apps are not listed in the section"; FAIL=1; }
if grep -q "Shubham OS Special Features" "$MENUFILE"; then
  echo "  PROBLEM  the old block is still in the system menu file"
  FAIL=1
else
  echo "  OK  system menu file is back to original"
fi
for f in shubham-netfix.desktop shubham-history.desktop shubham-wifi.desktop shubham-speed.desktop shubham-error.desktop; do
  if [ -s "/usr/share/applications/$f" ]; then
    echo "  OK  $f"
  else
    echo "  PROBLEM  $f is missing or empty"
    FAIL=1
  fi
done
if [ "$FAIL" -ne 0 ]; then
  echo "Shubham OS Update 15 FAILED. Your old version is kept."
  exit 1
fi

echo 15 > /etc/shubham-os-version
echo "Shubham OS Update 15 done! Restart the system, then open the menu."
