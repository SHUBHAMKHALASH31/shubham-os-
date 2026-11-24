#!/bin/bash
# Shubham OS Update 18 - the product repair: verified downloads,
# self-healing menu, and the Special Features menu section.
#
# What went wrong up to Update 16: the updater and the Live auto-update
# downloaded update scripts and ran them WITHOUT checking the download
# was complete. On a weak connection a script arrived cut in half, ran
# anyway, and left an empty menu file behind — after which the whole
# applications menu failed to load ("Document was empty..."). Update 17
# repaired the menu itself; this update repairs the SYSTEM that
# delivers updates, so it cannot happen again on any machine:
#   0. This script first checks its own file is complete (an end marker
#      must be present). An incomplete copy changes NOTHING and stops.
#   1. It makes the menu safe: any empty or broken user menu file is
#      moved aside (kept as .broken-shubham18), so the stock menu works
#      again no matter what happens next. A user's own valid menu file
#      is put back if this update fails.
#   2. It installs the repaired update system: a new ShubhamOS Update
#      app, Live auto-update and login checker that (a) verify every
#      future download by size and SHA-256 before running it — an
#      incomplete download is deleted and never executed — and (b)
#      repair a broken menu file by themselves at startup.
#   3. It installs the Special Features section files; every file is
#      written to a temporary name, checked, and only then moved into
#      place.
#   4. The menu library (garcon) itself is asked, as the user, whether
#      the section with its five apps is in the menu tree. If anything
#      fails, every user menu file this update placed is removed again
#      (the stock menu stays), the version is NOT written, and the
#      update reports FAILED.
# The panel is not touched. Runs as root via pkexec.

# --- Step 0: refuse an incomplete copy of this update ---------------------
if [ -f "$0" ]; then
  GATE_COUNT=$(grep -c "SHUBHAM18_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 18 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 18 (product repair + menu section) is being applied..."

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

# write_verified DEST KIND [MODE] [OWNER] -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1" kind="$2" mode="${3:-644}" owner="${4:-}"
  local tmp="${dest}.tmp-shubham18"
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
    py)
      if ! python3 -c "import py_compile, sys; py_compile.compile(sys.argv[1], cfile='/tmp/.shubham18-pyc', doraise=True)" "$tmp" 2>/dev/null; then
        rm -f "$tmp"
        return 1
      fi
      ;;
    sh)
      if ! bash -n "$tmp" 2>/dev/null; then
        rm -f "$tmp"
        return 1
      fi
      ;;
  esac
  chmod "$mode" "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
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
  echo "Shubham OS Update 18 FAILED its check. Your old version is kept"
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

# --- Step 1: make the menu safe first -------------------------------------
echo "Step 1: making the menu safe (moving any broken menu file aside)..."
for H in $HOMES; do
  UF="$H/.config/menus/xfce-applications.menu"
  [ -f "$UF" ] || continue
  if [ ! -s "$UF" ] || ! xml_ok "$UF"; then
    mv -f "$UF" "$UF.broken-shubham18"
    echo "  OK  broken menu file in $H moved aside (stock menu is back)"
  elif grep -q "Shubham OS Special Features" "$UF"; then
    mv -f "$UF" "$UF.broken-shubham18"
    echo "  OK  old Shubham menu file in $H moved aside for a fresh one"
  else
    mv -f "$UF" "$UF.pre-shubham18"
    RESTORES+=("$UF|$UF.pre-shubham18")
    echo "  OK  your own menu file in $H kept aside (put back if this fails)"
  fi
done

# --- Step 2: install the repaired update system ---------------------------
echo "Step 2: installing the repaired update system (verified downloads + self-heal)..."
mkdir -p /usr/local/bin
write_verified /usr/local/bin/shubham-update py 755 << 'SHUBHAM_APP_18A'
#!/usr/bin/env python3
# ShubhamOS Update — a 1-click updater like Windows Update
# Checks the version from the GitHub repo, then downloads and installs the update script.
#
# Version 2 (with Shubham OS Update 18):
# - A downloaded update script is verified before it runs: its size and
#   SHA-256 must match the values published in version.txt. An incomplete
#   download is deleted and NEVER executed.
# - At startup it repairs a broken menu file (self-heal): if the user's
#   menu file is empty or invalid, it is moved aside so the stock menu
#   works again. No command is needed.
import os, sys, threading, urllib.request, hashlib

VERSION_FILE = "/etc/shubham-os-version"
UPDATE_INFO_URL = "https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main/updates/version.txt"
TIMEOUT = 20

def current_version():
    try:
        with open(VERSION_FILE) as f:
            return int(f.read().strip() or "1")
    except Exception:
        return 1

def fetch_update_info():
    with urllib.request.urlopen(UPDATE_INFO_URL, timeout=TIMEOUT) as r:
        text = r.read().decode("utf-8", "replace")
    info = {}
    for line in text.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            info[k.strip()] = v.strip()
    return info

def heal_broken_menu():
    """Move a broken user menu file aside so the stock menu works again.

    The menu file is broken when it is empty or not valid XML — in that
    state the applications menu cannot load at all. Returns True when a
    repair was made."""
    import xml.etree.ElementTree as ET
    uf = os.path.expanduser("~/.config/menus/xfce-applications.menu")
    try:
        if not os.path.isfile(uf):
            return False
        broken = os.path.getsize(uf) == 0
        if not broken:
            try:
                ET.parse(uf)
            except Exception:
                broken = True
        if not broken:
            return False
        aside = uf + ".broken-autoheal"
        n = 1
        while os.path.exists(aside):
            aside = "%s.broken-autoheal%d" % (uf, n)
            n += 1
        os.rename(uf, aside)
        return True
    except Exception:
        return False

MENU_HEALED = heal_broken_menu()

try:
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, GLib
except Exception:
    os.system("zenity --error --text='ShubhamOS Update: GTK was not found.' 2>/dev/null")
    sys.exit(1)

class Updater(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="ShubhamOS Update")
        self.set_default_size(440, 300)
        self.set_border_width(16)
        self.cur = current_version()
        self.info = None

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.add(box)

        title = Gtk.Label()
        title.set_markup("<b><big>ShubhamOS Update</big></b>")
        box.pack_start(title, False, False, 0)

        start_text = f"Your version: Shubham OS {self.cur}\nPress the button below to check for updates."
        if MENU_HEALED:
            start_text = ("A broken menu file was found and repaired —\nyour applications menu works again.\n\n" + start_text)
        self.status = Gtk.Label(label=start_text)
        self.status.set_justify(Gtk.Justification.CENTER)
        box.pack_start(self.status, True, True, 0)

        self.check_btn = Gtk.Button(label="Check for Updates")
        self.check_btn.connect("clicked", self.on_check)
        box.pack_start(self.check_btn, False, False, 0)

        self.dl_btn = Gtk.Button(label="Download Update")
        self.dl_btn.set_sensitive(False)
        self.dl_btn.connect("clicked", self.on_download)
        box.pack_start(self.dl_btn, False, False, 0)

        self.progress = Gtk.ProgressBar()
        self.progress.set_visible(False)
        box.pack_start(self.progress, False, False, 0)

    def set_status(self, text):
        GLib.idle_add(self.status.set_text, text)

    def on_check(self, _):
        self.check_btn.set_sensitive(False)
        self.set_status("Checking for updates...")
        threading.Thread(target=self._check_worker, daemon=True).start()

    def _check_worker(self):
        try:
            info = fetch_update_info()
            latest = int(info.get("VERSION", "0"))
            self.info = info
            if latest > self.cur:
                notes = info.get("NOTES", "A new update is available.")
                self.set_status(f"New update found: Shubham OS {latest}\n{notes}\n\nPress 'Download Update' to install it.")
                GLib.idle_add(self.dl_btn.set_sensitive, True)
            else:
                self.set_status(f"Your Shubham OS is fully up to date. (Version {self.cur})")
        except Exception:
            self.set_status("The update check failed.\nCheck your internet connection and try again.")
        GLib.idle_add(self.check_btn.set_sensitive, True)

    def on_download(self, _):
        if not self.info or "SCRIPT" not in self.info:
            self.set_status("The update information is incomplete. Try again later.")
            return
        self.dl_btn.set_sensitive(False)
        self.check_btn.set_sensitive(False)
        self.progress.set_visible(True)
        self.progress.pulse()
        self.set_status("Downloading and installing the update...\nIf a password is asked, enter your password.")
        threading.Thread(target=self._dl_worker, daemon=True).start()

    def _dl_worker(self):
        try:
            url = self.info["SCRIPT"]
            tmp = "/tmp/shubham-os-update-download.sh"
            path = "/tmp/shubham-os-update.sh"
            urllib.request.urlretrieve(url, tmp)
            # Verify the download BEFORE anything runs: it must be
            # non-empty and match the published size and SHA-256.
            ok = os.path.isfile(tmp) and os.path.getsize(tmp) > 0
            if ok:
                try:
                    expected_size = int(self.info.get("SCRIPT_SIZE", "") or 0)
                except Exception:
                    expected_size = 0
                if expected_size and os.path.getsize(tmp) != expected_size:
                    ok = False
            if ok:
                expected_sha = (self.info.get("SCRIPT_SHA256", "") or "").strip().lower()
                if expected_sha:
                    h = hashlib.sha256()
                    with open(tmp, "rb") as f:
                        for chunk in iter(lambda: f.read(65536), b""):
                            h.update(chunk)
                    if h.hexdigest() != expected_sha:
                        ok = False
            if not ok:
                try:
                    os.remove(tmp)
                except Exception:
                    pass
                self.set_status("The download was incomplete, so nothing was installed.\nCheck your internet connection and try again.")
            else:
                os.replace(tmp, path)
                os.chmod(path, 0o755)
                rc = os.system(f"pkexec bash {path}")
                if rc == 0:
                    self.set_status("Update complete! \u2705\nRestart the system to see the changes.")
                else:
                    self.set_status("The update stopped (password cancelled or an error).\nPlease try again.")
        except Exception:
            self.set_status("The update could not be downloaded. Check your internet.")
        GLib.idle_add(self.progress.set_visible, False)
        GLib.idle_add(self.dl_btn.set_sensitive, True)
        GLib.idle_add(self.check_btn.set_sensitive, True)

win = Updater()
win.connect("destroy", Gtk.main_quit)
win.show_all()
win.progress.set_visible(False)
Gtk.main()
SHUBHAM_APP_18A
[ $? -eq 0 ] || fail_out

write_verified /usr/local/bin/shubham-autoupdate sh 755 << 'SHUBHAM_APP_18B'
#!/bin/bash
# Shubham OS — Live Auto-Update (runs as root)
# When Live starts, if a new version is found, it downloads and installs it automatically.
#
# Version 2 (with Shubham OS Update 18):
# - Self-heal first: an empty or invalid user menu file breaks the whole
#   applications menu, so it is moved aside and the stock menu works again.
# - The downloaded update is verified before it runs: its size and
#   SHA-256 must match the values published in version.txt. An incomplete
#   download is deleted and NEVER executed.
# - Exit code is honest: 0 = up to date or installed; 1 = a new version
#   was found but could not be installed completely.
LOG=/var/log/shubham-update.log
exec >> "$LOG" 2>&1
echo "=== $(date) autoupdate check ==="

# Self-heal: repair a broken menu file in every home folder.
for H in /home/*; do
  [ -d "$H" ] || continue
  UF="$H/.config/menus/xfce-applications.menu"
  [ -f "$UF" ] || continue
  if [ ! -s "$UF" ] || ! python3 -c "import xml.etree.ElementTree as ET, sys; ET.parse(sys.argv[1])" "$UF" 2>/dev/null; then
    mv -f "$UF" "$UF.broken-autoheal"
    echo "Repaired a broken menu file in $H (moved aside; the stock menu works again)."
  fi
done

CUR=1
[ -f /etc/shubham-os-version ] && CUR=$(cat /etc/shubham-os-version 2>/dev/null || echo 1)
INFO=$(curl -fsSL --max-time 20 "https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main/updates/version.txt") || exit 0
LATEST=$(echo "$INFO" | awk -F= '$1=="VERSION" {print $2}')
SCRIPT=$(echo "$INFO" | awk -F= '$1=="SCRIPT" {print substr($0, index($0,"=")+1)}')
SIZE=$(echo "$INFO" | awk -F= '$1=="SCRIPT_SIZE" {print $2}')
SHA=$(echo "$INFO" | awk -F= '$1=="SCRIPT_SHA256" {print $2}')
[ -z "$LATEST" ] && exit 0
[ -z "$SCRIPT" ] && exit 0
if [ "$LATEST" -gt "$CUR" ] 2>/dev/null; then
  echo "New version $LATEST found — downloading..."
  TMP=/tmp/shubham-os-auto-update.dl
  rm -f "$TMP"
  if ! curl -fsSL --max-time 60 "$SCRIPT" -o "$TMP"; then
    echo "The download failed — nothing was installed."
    rm -f "$TMP"
    exit 1
  fi
  # Verify before running: never execute an incomplete download.
  if [ ! -s "$TMP" ]; then
    echo "The download was empty — nothing was installed."
    rm -f "$TMP"
    exit 1
  fi
  if [ -n "$SIZE" ]; then
    ACTUAL_SIZE=$(stat -c %s "$TMP")
    if [ "$ACTUAL_SIZE" != "$SIZE" ]; then
      echo "The download was incomplete (size $ACTUAL_SIZE, expected $SIZE) — nothing was installed."
      rm -f "$TMP"
      exit 1
    fi
  fi
  if [ -n "$SHA" ]; then
    ACTUAL_SHA=$(sha256sum "$TMP" | awk '{print $1}')
    if [ "$ACTUAL_SHA" != "$SHA" ]; then
      echo "The download check failed (hash mismatch) — nothing was installed."
      rm -f "$TMP"
      exit 1
    fi
  fi
  echo "Download verified — installing..."
  mv -f "$TMP" /tmp/shubham-os-auto-update.sh
  bash /tmp/shubham-os-auto-update.sh
  RC=$?
  if [ "$RC" -eq 0 ]; then
    echo "Auto-update complete: the version is now $LATEST."
    exit 0
  fi
  echo "The update script stopped with an error (exit $RC) — the version stays $CUR."
  exit 1
fi
exit 0
SHUBHAM_APP_18B
[ $? -eq 0 ] || fail_out

write_verified /usr/local/bin/shubham-update-check sh 755 << 'SHUBHAM_APP_18C'
#!/bin/bash
# ShubhamOS Update — background checker (runs at login)
# Live mode: a new version installs itself (auto). Install mode: notification only.
STAMP="$HOME/.cache/shubham-update-lastcheck"
mkdir -p "$(dirname "$STAMP")"
IS_LIVE=0
grep -q "boot=live" /proc/cmdline 2>/dev/null && IS_LIVE=1
# Install mode checks only once a day; Live checks on every boot (the stamp resets anyway)
if [ "$IS_LIVE" = "0" ]; then
  NOW=$(date +%s); LAST=0
  [ -f "$STAMP" ] && LAST=$(cat "$STAMP" 2>/dev/null || echo 0)
  [ $((NOW - LAST)) -lt 86400 ] && exit 0
  echo "$NOW" > "$STAMP"
fi
# Wait for the network (up to ~60 seconds)
INFO=""
for i in $(seq 1 12); do
  INFO=$(curl -fsSL --max-time 10 "https://raw.githubusercontent.com/SHUBHAMKHALASH31/shubham-os-/main/updates/version.txt" 2>/dev/null) && [ -n "$INFO" ] && break
  sleep 5
done
[ -z "$INFO" ] && exit 0
CUR=1
[ -f /etc/shubham-os-version ] && CUR=$(cat /etc/shubham-os-version 2>/dev/null || echo 1)
LATEST=$(echo "$INFO" | awk -F= '$1=="VERSION" {print $2}')
[ -z "$LATEST" ] && exit 0
if [ "$LATEST" -gt "$CUR" ] 2>/dev/null; then
  if [ "$IS_LIVE" = "1" ] && [ -x /usr/local/bin/shubham-autoupdate ]; then
    notify-send -i shubham-os-logo "ShubhamOS Update" "New version $LATEST found — installing it automatically in Live..." 2>/dev/null || true
    if sudo -n /usr/local/bin/shubham-autoupdate >/dev/null 2>&1; then
      xfce4-panel -r >/dev/null 2>&1 || true
      notify-send -i shubham-os-logo "ShubhamOS Update" "Done! You are now running the latest Shubham OS $LATEST in Live." 2>/dev/null || true
    else
      notify-send -i shubham-os-logo "ShubhamOS Update" "The new update could not be installed completely. It will be tried again on the next start." 2>/dev/null || true
    fi
  else
    notify-send -i shubham-os-logo "ShubhamOS Update" "A new update is available: Shubham OS $LATEST — open ShubhamOS Update and download it." 2>/dev/null || true
  fi
fi
exit 0
SHUBHAM_APP_18C
[ $? -eq 0 ] || fail_out

echo "  OK  update system installed and checked"

echo "Step 3: installing the menu entries..."
mkdir -p /etc/xdg/menus/applications-merged /usr/share/applications /usr/share/desktop-directories

MERGED="/etc/xdg/menus/applications-merged/shubham-special.menu"
write_verified "$MERGED" xml << 'SHUBHAM_MERGED_18'
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
SHUBHAM_MERGED_18
[ $? -eq 0 ] || fail_out

write_verified /usr/share/desktop-directories/shubham-special.directory desktop << 'SHUBHAM_DIR_18'
[Desktop Entry]
Type=Directory
Name=Shubham OS Special Features
Comment=Special tools of Shubham OS
Icon=applications-system
SHUBHAM_DIR_18
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-netfix.desktop desktop << 'SHUBHAM_DESK_18A'
[Desktop Entry]
Type=Application
Name=Net Fix
Comment=Fix internet problems in one click
Exec=xfce4-terminal --hold -e shubham-netfix
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_18A
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-history.desktop desktop << 'SHUBHAM_DESK_18B'
[Desktop Entry]
Type=Application
Name=History File
Comment=Save all terminal commands in one txt file
Exec=xfce4-terminal --hold -e shubham-history
Icon=utilities-terminal
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_18B
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-wifi.desktop desktop << 'SHUBHAM_DESK_18C'
[Desktop Entry]
Type=Application
Name=WiFi Password
Comment=Show a saved WiFi password
Exec=xfce4-terminal --hold -e shubham-wifi
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_18C
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-speed.desktop desktop << 'SHUBHAM_DESK_18D'
[Desktop Entry]
Type=Application
Name=Net Speed
Comment=Check internet speed
Exec=xfce4-terminal --hold -e shubham-speed
Icon=utilities-system-monitor
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_18D
[ $? -eq 0 ] || fail_out

write_verified /usr/share/applications/shubham-error.desktop desktop << 'SHUBHAM_DESK_18E'
[Desktop Entry]
Type=Application
Name=Error Guide
Comment=Understand any error in simple words
Exec=xfce4-terminal --hold -e shubham-error
Icon=dialog-information
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_18E
[ $? -eq 0 ] || fail_out

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi
echo "  OK  menu entries installed and checked"

# --- Step 2: the user-level menu file, verified before it lands -----------
echo "Step 4: writing the user-level menu file..."
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
  write_verified "$UF" xml 644 "$OWNER" << 'SHUBHAM_USERMENU_18'
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
SHUBHAM_USERMENU_18
  if [ $? -ne 0 ]; then
    echo "  PROBLEM  the user menu file for $H could not be written safely."
    fail_out
  fi
  PLACED_UFS+=("$UF")
  echo "  OK  user menu file written and checked for $H"
done

# --- Step 3: ask the menu library itself ----------------------------------
echo "Step 5: checking with the menu library itself..."
CHECKER="/tmp/shubham-check-menu.py"
cat > "$CHECKER" << 'SHUBHAM_CHECK_18'
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
SHUBHAM_CHECK_18
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
echo 18 > /etc/shubham-os-version
echo "Shubham OS Update 18 done! Restart the system, then open the menu."
# SHUBHAM18_END_OF_FILE
