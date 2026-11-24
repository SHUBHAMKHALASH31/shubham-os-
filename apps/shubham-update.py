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
