#!/usr/bin/env python3
# ShubhamOS Update — a 1-click updater like Windows Update
# Checks the version from the GitHub repo, then downloads and installs the update script.
import os, sys, threading, urllib.request

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

        self.status = Gtk.Label(label=f"Your version: Shubham OS {self.cur}\nPress the button below to check for updates.")
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
            path = "/tmp/shubham-os-update.sh"
            urllib.request.urlretrieve(url, path)
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
