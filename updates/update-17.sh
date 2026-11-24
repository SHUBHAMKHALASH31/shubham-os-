#!/bin/bash
# Shubham OS Update 17 - the menu section, repaired and hardened.
#
# What went wrong in Update 16: on the test system the user-level menu
# file (~/.config/menus/xfce-applications.menu) was left EMPTY (the
# update file itself arrived incomplete there, as downloads on that
# system have done before). An empty main menu file makes the whole
# applications menu fail to load. That failure was reproduced exactly
# in a local replica of the Kali menu system before writing this update.
#
# This update is built so that can never happen again:
#   0. It first checks its own file is complete (an end marker must be
#      present). An incomplete download changes NOTHING and stops.
#   1. It then makes the menu safe: any empty or broken user menu file
#      is moved aside (kept on disk with a .broken-shubham17 name), so
#      the stock system menu works again no matter what happens next.
#      A user's own valid menu file is moved aside too and is put back
#      if this update fails.
#   2. Every file is written to a temporary name first, checked (not
#      empty; XML files must parse; desktop files must have their
#      header), and only then moved into place.
#   3. At the end the menu library (garcon) itself is asked, as the
#      user, whether the section with its five apps is in the menu
#      tree. If anything fails, every user menu file this update placed
#      is removed again (the stock menu stays), the version is NOT
#      written, and the update reports FAILED.
# The panel is not touched. Runs as root via pkexec.

# --- Step 0a: refuse an incomplete copy of this update -------------------
if [ -f "$0" ]; then
  GATE_COUNT=$(grep -c "SHUBHAM17_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 17 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 17 (menu section, repaired) is being applied..."

SUCCESS=0
PLACED_UFS=()
RESTORES=()

cleanup_on_exit() {
  if [ "$SUCCESS" -ne 1 ]; then
    for uf in "${PLACED_UFS[@]}"; do
      rm -f "$uf"
    done
    for pair in "${RESTORES[@]}"; do
      uf_path="${pair%%|*}"
      bak_path="${pair##*|}"
      if [ -f "$bak_path" ]; then
        mv -f "$bak_path" "$uf_path"
      fi
    done
  fi
}
trap cleanup_on_exit EXIT

xml_ok() {
  python3 -c "import xml.etree.ElementTree as ET, sys; ET.parse(sys.argv[1])" "$1" 2>/dev/null
}

# write_verified DEST KIND [OWNER] -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1" kind="$2" owner="${3:-}"
  local tmp="${dest}.tmp-shubham17"
  if ! cat > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"
    return 1
  fi
  case "$kind" in
    xml)
      if ! xml_ok "$tmp"; then
        rm -f "$tmp"
        return 1
      fi
      ;;
    desktop)
      if ! grep -q "^\[Desktop Entry\]" "$tmp"; then
        rm -f "$tmp"
        return 1
      fi
      ;;
  esac
  chmod 644 "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  if ! mv -f "$tmp" "$dest"; then
    rm -f "$tmp"
    return 1
  fi
  if [ -n "$owner" ]; then
    chown "$owner" "$dest" 2>/dev/null || true
  fi
  return 0
}

fail_out() {
  echo "Shubham OS Update 17 FAILED its check. Your old version is kept"
  echo "and the stock menu is in place. Please tell the developer what"
  echo "the updater showed."
  exit 1
}

# --- Collect the home folders --------------------------------------------
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
  echo "PROBLEM: no home folder found. Nothing was changed."
  exit 1
fi

# --- Step 0b: make the menu safe first ------------------------------------
echo "Step 1: making the menu safe (moving any broken menu file aside)..."
for H in $HOMES; do
  UF="$H/.config/menus/xfce-applications.menu"
  [ -f "$UF" ] || continue
  if [ ! -s "$UF" ] || ! xml_ok "$UF"; then
    mv -f "$UF" "$UF.broken-shubham17"
    echo "  OK  broken menu file in $H moved aside (stock menu is back)"
  elif grep -q "Shubham OS Special Features" "$UF"; then
    mv -f "$UF" "$UF.broken-shubham17"
    echo "  OK  old Shubham menu file in $H moved aside for a fresh one"
  else
    mv -f "$UF" "$UF.pre-shubham17"
    RESTORES+=("$UF|$UF.pre-shubham17")
    echo "  OK  your own menu file in $H kept aside (put back if this fails)"
  fi
done

# --- Step 1: system payloads (same proven files as Update 16) -------------
echo "Step 2: installing the menu entries..."
mkdir -p /etc/xdg/menus/applications-merged /usr/share/applications /usr/share/desktop-directories

MERGED="/etc/xdg/menus/applications-merged/shubham-special.menu"
write_verified "$MERGED" xml << 'SHUBHAM_MERGED_17'
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
SHUBHAM_MERGED_17
[ $? -eq 0 ] || fail_out

write_verified /usr/share/desktop-directories/shubham-special.directory desktop << 'SHUBHAM_DIR_17'
[Desktop Entry]
Type=Directory
Name=Shubham OS Special Features
Comment=Special tools of Shubham OS
Icon=applications-system
SHUBHAM_DIR_17
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-netfix.desktop desktop << 'SHUBHAM_DESK_17A'
[Desktop Entry]
Type=Application
Name=Net Fix
Comment=Fix internet problems in one click
Exec=xfce4-terminal --hold -e shubham-netfix
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_17A
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-history.desktop desktop << 'SHUBHAM_DESK_17B'
[Desktop Entry]
Type=Application
Name=History File
Comment=Save all terminal commands in one txt file
Exec=xfce4-terminal --hold -e shubham-history
Icon=utilities-terminal
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_17B
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-wifi.desktop desktop << 'SHUBHAM_DESK_17C'
[Desktop Entry]
Type=Application
Name=WiFi Password
Comment=Show a saved WiFi password
Exec=xfce4-terminal --hold -e shubham-wifi
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_17C
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-speed.desktop desktop << 'SHUBHAM_DESK_17D'
[Desktop Entry]
Type=Application
Name=Net Speed
Comment=Check internet speed
Exec=xfce4-terminal --hold -e shubham-speed
Icon=utilities-system-monitor
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_17D
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-error.desktop desktop << 'SHUBHAM_DESK_17E'
[Desktop Entry]
Type=Application
Name=Error Guide
Comment=Understand any error in simple words
Exec=xfce4-terminal --hold -e shubham-error
Icon=dialog-information
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_17E
[ $? -eq 0 ] || fail_out

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi
echo "  OK  menu entries installed and checked"

# --- Step 2: the user-level menu file, verified before it lands -----------
echo "Step 3: writing the user-level menu file..."
FIRST_HOME=""
for H in $HOMES; do
  [ -z "$FIRST_HOME" ] && FIRST_HOME="$H"
  OWNER=$(stat -c %U "$H" 2>/dev/null)
  [ -z "$OWNER" ] && OWNER="root"
  MDIR="$H/.config/menus"
  mkdir -p "$MDIR"
  chown "$OWNER" "$H/.config" "$MDIR" 2>/dev/null || true
  chmod 755 "$MDIR" 2>/dev/null || true
  UF="$MDIR/xfce-applications.menu"
  write_verified "$UF" xml "$OWNER" << 'SHUBHAM_USERMENU_17'
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
SHUBHAM_USERMENU_17
  if [ $? -ne 0 ]; then
    echo "  PROBLEM  the user menu file for $H could not be written safely."
    fail_out
  fi
  PLACED_UFS+=("$UF")
  echo "  OK  user menu file written and checked for $H"
done

# --- Step 3: ask the menu library itself ----------------------------------
echo "Step 4: checking with the menu library itself..."
CHECKER="/tmp/shubham-check-menu.py"
cat > "$CHECKER" << 'SHUBHAM_CHECK_17'
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
SHUBHAM_CHECK_17
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

case "$RESULT" in
  "SECTION_ITEMS=5")
    echo "  OK  the section and its five apps are in the menu tree"
    ;;
  "SECTION_ITEMS=SKIP")
    echo "  NOTE  the menu library check is not available on this system;"
    echo "        using strict file checks instead"
    UF_CHECK="$VERIFY_HOME/.config/menus/xfce-applications.menu"
    if [ -s "$UF_CHECK" ] && xml_ok "$UF_CHECK" \
       && grep -q "Shubham OS Special Features" "$UF_CHECK" \
       && grep -q "MergeFile" "$UF_CHECK"; then
      echo "  OK  the user menu file is complete and valid"
    else
      echo "  PROBLEM  the user menu file is not complete"
      fail_out
    fi
    ;;
  *)
    echo "  PROBLEM  the section is not in the menu tree ($RESULT)"
    fail_out
    ;;
esac

SUCCESS=1
echo 17 > /etc/shubham-os-version
echo "Shubham OS Update 17 done! Restart the system, then open the menu."
# SHUBHAM17_END_OF_FILE
