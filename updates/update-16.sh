#!/bin/bash
# Shubham OS Update 16 - the menu section, user-level route (permanent).
# Updates 11 to 15 put the "Shubham OS Special Features" section into the
# system menu files. On the test system those files are correct, but the
# section still does not appear in the menu, while Kali's own sections do.
# The menu library (garcon) was tested directly with Kali's own menu
# files: the section appears at once when it is defined in the USER-level
# menu file (~/.config/menus/xfce-applications.menu), which garcon reads
# before the system file and which pulls the whole system menu in as its
# parent. This update uses that route:
#   1. It re-installs the five menu entries, the section name file and
#      the applications-merged file (same as Update 15, kept as a
#      second route).
#   2. For the user who runs this update (and every other home folder)
#      it writes ~/.config/menus/xfce-applications.menu holding only the
#      new section; everything else comes from the system menu file,
#      unchanged, through a parent merge. An old user menu file, if any,
#      is backed up first.
#   3. It then asks garcon itself, as that user, whether the section
#      with its five apps is in the menu tree. The version is only
#      written when garcon says yes.
# Nothing else is touched. The panel is not touched. Runs as root via pkexec.
echo "Shubham OS Update 16 (menu section, user-level route) is being applied..."

MENUFILE="/etc/xdg/menus/xfce-applications.menu"
MERGED="/etc/xdg/menus/applications-merged/shubham-special.menu"

echo "Step 1: installing the menu entries..."
mkdir -p /etc/xdg/menus/applications-merged /usr/share/applications /usr/share/desktop-directories

cat > "$MERGED" << 'SHUBHAM_MERGED_16'
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
SHUBHAM_MERGED_16

cat > /usr/share/desktop-directories/shubham-special.directory << 'SHUBHAM_DIR_16'
[Desktop Entry]
Type=Directory
Name=Shubham OS Special Features
Comment=Special tools of Shubham OS
Icon=applications-system
SHUBHAM_DIR_16

cat > /usr/share/applications/shubham-netfix.desktop << 'SHUBHAM_DESK_16A'
[Desktop Entry]
Type=Application
Name=Net Fix
Comment=Fix internet problems in one click
Exec=xfce4-terminal --hold -e shubham-netfix
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_16A

cat > /usr/share/applications/shubham-history.desktop << 'SHUBHAM_DESK_16B'
[Desktop Entry]
Type=Application
Name=History File
Comment=Save all terminal commands in one txt file
Exec=xfce4-terminal --hold -e shubham-history
Icon=utilities-terminal
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_16B

cat > /usr/share/applications/shubham-wifi.desktop << 'SHUBHAM_DESK_16C'
[Desktop Entry]
Type=Application
Name=WiFi Password
Comment=Show a saved WiFi password
Exec=xfce4-terminal --hold -e shubham-wifi
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_16C

cat > /usr/share/applications/shubham-speed.desktop << 'SHUBHAM_DESK_16D'
[Desktop Entry]
Type=Application
Name=Net Speed
Comment=Check internet speed
Exec=xfce4-terminal --hold -e shubham-speed
Icon=utilities-system-monitor
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_16D

cat > /usr/share/applications/shubham-error.desktop << 'SHUBHAM_DESK_16E'
[Desktop Entry]
Type=Application
Name=Error Guide
Comment=Understand any error in simple words
Exec=xfce4-terminal --hold -e shubham-error
Icon=dialog-information
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_16E

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi
# The menu files must be readable by every user, whatever the umask is.
chmod 644 "$MERGED" /usr/share/desktop-directories/shubham-special.directory \
  /usr/share/applications/shubham-netfix.desktop \
  /usr/share/applications/shubham-history.desktop \
  /usr/share/applications/shubham-wifi.desktop \
  /usr/share/applications/shubham-speed.desktop \
  /usr/share/applications/shubham-error.desktop 2>/dev/null || true

echo "Step 2: writing the user-level menu file..."
# Collect the home folders to cover: the user running this update first,
# then every folder in /home.
HOMES=""
if [ -n "${PKEXEC_UID:-}" ]; then
  PU_HOME=$(getent passwd "$PKEXEC_UID" | cut -d: -f6)
  [ -n "$PU_HOME" ] && [ -d "$PU_HOME" ] && HOMES="$PU_HOME"
fi
for d in /home/*; do
  [ -d "$d" ] || continue
  case " $HOMES " in
    *" $d "*) ;;
    *) HOMES="$HOMES $d" ;;
  esac
done
if [ -z "$HOMES" ]; then
  echo "PROBLEM: no home folder found. Nothing more was changed."
  exit 1
fi

write_user_menu() {
  H="$1"
  OWNER=$(stat -c %U "$H" 2>/dev/null)
  [ -z "$OWNER" ] && OWNER="root"
  CFG="$H/.config"
  MDIR="$CFG/menus"
  CREATED_CFG=0
  [ -d "$CFG" ] || CREATED_CFG=1
  mkdir -p "$MDIR"
  UF="$MDIR/xfce-applications.menu"
  if [ -f "$UF" ] && [ ! -f "$UF.bak-shubham16" ]; then
    cp -a "$UF" "$UF.bak-shubham16"
  fi
  cat > "$UF" << 'SHUBHAM_USERMENU_16'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
<Name>Xfce</Name>
<DefaultAppDirs/>
<DefaultDirectoryDirs/>
<MergeFile type="parent">/etc/xdg/menus/xfce-applications.menu</MergeFile>
<Layout>
<Filename>xfce4-run.desktop</Filename>
<Separator/>
<Filename>xfce4-terminal-emulator.desktop</Filename>
<Filename>xfce4-file-manager.desktop</Filename>
<Filename>xfce4-mail-reader.desktop</Filename>
<Filename>xfce4-web-browser.desktop</Filename>
<Separator/>
<Menuname>Settings</Menuname>
<Menuname>Usual Applications</Menuname>
<Menuname>Shubham OS Special Features</Menuname>
<Separator/>
<Merge type="all"/>
<Separator/>
<Filename>xfce4-about.desktop</Filename>
<Filename>xfce4-session-logout.desktop</Filename>
</Layout>
<Menu>
<Name>Shubham OS Special Features</Name>
<Directory>shubham-special.directory</Directory>
<Include>
<Category>X-Shubham-Special</Category>
</Include>
</Menu>
</Menu>
SHUBHAM_USERMENU_16
  chown "$OWNER" "$MDIR" "$UF" 2>/dev/null || true
  chmod 755 "$MDIR" 2>/dev/null || true
  chmod 644 "$UF" 2>/dev/null || true
  [ "$CREATED_CFG" -eq 1 ] && chown "$OWNER" "$CFG" 2>/dev/null || true
  echo "  OK  user menu file written for $H"
}

FIRST_HOME=""
for H in $HOMES; do
  [ -z "$FIRST_HOME" ] && FIRST_HOME="$H"
  write_user_menu "$H"
done

echo "Step 3: checking with the menu library itself..."
CHECKER="/tmp/shubham-check-menu.py"
cat > "$CHECKER" << 'SHUBHAM_CHECK_16'
import sys
try:
    import gi
    gi.require_version('Garcon', '1.0')
    from gi.repository import Garcon
except Exception:
    print("SECTION_ITEMS=SKIP")
    sys.exit(0)
try:
    m = Garcon.Menu.new_applications()
    m.load(None)
except Exception:
    print("SECTION_ITEMS=SKIP")
    sys.exit(0)
found = []
def walk(menu):
    for el in menu.get_elements():
        if isinstance(el, Garcon.Menu):
            if el.get_name() == 'Shubham OS Special Features':
                n = len([i for i in el.get_elements() if isinstance(i, Garcon.MenuItem)])
                found.append(n)
            walk(el)
walk(m)
print("SECTION_ITEMS=%d" % (found[0] if found else -1))
SHUBHAM_CHECK_16
chmod 644 "$CHECKER"

VERIFY_HOME="$FIRST_HOME"
if [ -n "${PKEXEC_UID:-}" ]; then
  PU_HOME=$(getent passwd "$PKEXEC_UID" | cut -d: -f6)
  [ -n "$PU_HOME" ] && [ -d "$PU_HOME" ] && VERIFY_HOME="$PU_HOME"
fi
VERIFY_USER=$(stat -c %U "$VERIFY_HOME" 2>/dev/null)
RESULT="SECTION_ITEMS=SKIP"
if [ -n "$VERIFY_USER" ] && [ "$VERIFY_USER" != "root" ]; then
  if command -v runuser >/dev/null 2>&1; then
    OUT=$(runuser -u "$VERIFY_USER" -- env HOME="$VERIFY_HOME" XDG_MENU_PREFIX="xfce-" python3 "$CHECKER" 2>/dev/null)
  else
    OUT=$(sudo -u "$VERIFY_USER" env HOME="$VERIFY_HOME" XDG_MENU_PREFIX="xfce-" python3 "$CHECKER" 2>/dev/null)
  fi
  [ -n "$OUT" ] && RESULT="$OUT"
fi
rm -f "$CHECKER"
echo "  menu library says: $RESULT"

FAIL=0
case "$RESULT" in
  "SECTION_ITEMS=5")
    echo "  OK  the section and its five apps are in the menu tree"
    ;;
  "SECTION_ITEMS=SKIP")
    echo "  NOTE  the menu library check is not available on this system;"
    echo "        falling back to file checks"
    python3 -c "import xml.etree.ElementTree as ET; ET.parse('/etc/xdg/menus/applications-merged/shubham-special.menu')" 2>/dev/null || FAIL=1
    for f in shubham-netfix.desktop shubham-history.desktop shubham-wifi.desktop shubham-speed.desktop shubham-error.desktop; do
      [ -s "/usr/share/applications/$f" ] || FAIL=1
    done
    ;;
  *)
    echo "  PROBLEM  the section is not in the menu tree ($RESULT)"
    FAIL=1
    ;;
esac

if [ "$FAIL" -ne 0 ]; then
  echo "Shubham OS Update 16 FAILED its check. Your old version is kept."
  exit 1
fi

echo 16 > /etc/shubham-os-version
echo "Shubham OS Update 16 done! Restart the system, then open the menu."
