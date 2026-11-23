#!/bin/bash
# ============================================================
#  SHUBHAM OS — REMASTER (SHORTCUT) SCRIPT
#  Opens a ready Kali Live ISO, puts the Shubham OS branding
#  inside and closes it back — a new ISO is ready.
#  This is a shortcut instead of the long live-build.
#
#  Run:
#    ./remaster-shubham-os.sh /path/to/kali-live.iso
#  Needs: Kali machine/VM, internet (for small tools),
#            ~25 GB free space in the VM
# ============================================================
set -e
cd "$(dirname "$0")"
PACK_DIR="$(pwd)"
# If images came in base64, make PNGs (for GitHub text-push)
for B64 in images/*.b64; do [ -f "$B64" ] && base64 -d "$B64" > "${B64%.b64}"; done
# If images are not in the repo, take them from the links (images/IMAGE-URLS.txt)
if [ -f images/IMAGE-URLS.txt ]; then while read -r INAME IURL; do [ -f "images/$INAME" ] || curl -sL -o "images/$INAME" "$IURL"; done < images/IMAGE-URLS.txt; fi

ISO_IN="${1:-}"
if [ -z "$ISO_IN" ] || [ ! -f "$ISO_IN" ]; then
  echo "ERROR: Kali Live ISO not found."
  echo "Run it like this:  ./remaster-shubham-os.sh ~/Downloads/kali-linux-live.iso"
  exit 1
fi

echo "==============================================="
echo "  SHUBHAM OS REMASTER STARTING"
echo "  Base ISO: $ISO_IN"
echo "==============================================="

echo "[1/7] Installing small tools..."
sudo apt update
sudo apt install -y squashfs-tools xorriso rsync

WORK="$HOME/shubham-remaster"
ISO_MNT="$WORK/mnt"
ISO_COPY="$WORK/iso-copy"
ROOTFS="$WORK/rootfs"
rm -rf "$WORK"
mkdir -p "$ISO_MNT" "$ISO_COPY" "$ROOTFS"

echo "[2/7] Opening the ISO..."
sudo mount -o loop "$ISO_IN" "$ISO_MNT"
rsync -a "$ISO_MNT/" "$ISO_COPY/"
sudo umount "$ISO_MNT"
chmod -R u+w "$ISO_COPY"

SQ="$ISO_COPY/live/filesystem.squashfs"
if [ ! -f "$SQ" ]; then
  echo "ERROR: live/filesystem.squashfs not found — this does not look like a Live ISO."
  exit 1
fi

echo "[3/7] Opening the system files (will take some time)..."
sudo unsquashfs -d "$ROOTFS" "$SQ" > /dev/null

echo "[4/7] Adding the Shubham OS branding..."
# Identity
sudo cp "$PACK_DIR/branding/os-release" "$ROOTFS/etc/os-release"
sudo cp "$PACK_DIR/branding/os-release" "$ROOTFS/usr/lib/os-release"
sudo cp "$PACK_DIR/branding/hostname"   "$ROOTFS/etc/hostname"
sudo cp "$PACK_DIR/branding/motd"       "$ROOTFS/etc/motd"
# Wallpaper + logo
sudo mkdir -p "$ROOTFS/usr/share/backgrounds/shubham-os"
sudo cp "$PACK_DIR/images/wallpaper-kali-mode.jpg"    "$ROOTFS/usr/share/backgrounds/shubham-os/"
sudo cp "$PACK_DIR/images/wallpaper-windows-mode.jpg" "$ROOTFS/usr/share/backgrounds/shubham-os/"
sudo cp "$PACK_DIR/images/shubham-os-logo.jpg"        "$ROOTFS/usr/share/pixmaps/"
# --- v2 FIX: make the wallpaper really apply — 3 sure ways ---
# (a) Replace Kali's stock wallpaper files with ours (keeping the same format)
sudo apt-get install -y imagemagick > /dev/null 2>&1 || true
replace_img() {
  case "$2" in
    *.png) sudo convert "$1" "$2" 2>/dev/null || sudo cp "$1" "$2" ;;
    *) sudo cp "$1" "$2" ;;
  esac
}
while IFS= read -r -d '' f; do
  replace_img "$PACK_DIR/images/wallpaper-kali-mode.jpg" "$f"
done < <(sudo find "$ROOTFS/usr/share/backgrounds" -type f \( -iname '*.jpg' -o -iname '*.png' \) ! -path '*shubham-os*' -print0 2>/dev/null)
# (b) Replace kali-undercover's own wallpapers too — that is what Windows mode uses
while IFS= read -r -d '' f; do
  replace_img "$PACK_DIR/images/wallpaper-windows-mode.jpg" "$f"
done < <(sudo find "$ROOTFS/usr/share" -ipath '*undercover*' -type f \( -iname '*.jpg' -o -iname '*.png' \) -print0 2>/dev/null)
# (c) XFCE config — for skel and the existing kali user both, with the correct property (last-image)
write_desktop_xml() {
  sudo mkdir -p "$1"
  cat << 'XML' | sudo tee "$1/xfce4-desktop.xml" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/shubham-os/wallpaper-kali-mode.jpg"/>
          <property name="image-path" type="string" value="/usr/share/backgrounds/shubham-os/wallpaper-kali-mode.jpg"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XML
}
write_desktop_xml "$ROOTFS/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
if [ -d "$ROOTFS/home/kali" ]; then
  write_desktop_xml "$ROOTFS/home/kali/.config/xfce4/xfconf/xfce-perchannel-xml"
fi
# Toggle commands
sudo cp "$PACK_DIR/scripts/shubham-windows" "$ROOTFS/usr/local/bin/"
sudo cp "$PACK_DIR/scripts/shubham-kali"    "$ROOTFS/usr/local/bin/"
sudo chmod +x "$ROOTFS/usr/local/bin/shubham-windows" "$ROOTFS/usr/local/bin/shubham-kali"

echo "[4.5/7] v3 branding: boot logo, user name, menu name, updater, dock..."
# (i) Plymouth boot logo (the dragon at start) -> our golden emblem
while IFS= read -r -d '' f; do
  DIM=$(sudo identify -format '%wx%h' "$f" 2>/dev/null || echo "")
  if [ -n "$DIM" ]; then
    sudo convert "$PACK_DIR/images/shubham-os-logo.jpg" -resize "$DIM" "$f" 2>/dev/null || sudo cp "$PACK_DIR/images/shubham-os-logo.jpg" "$f"
  fi
done < <(sudo find "$ROOTFS/usr/share/plymouth/themes" -type f -iname '*.png' \( -iname '*logo*' -o -iname '*watermark*' \) -print0 2>/dev/null)
# (ii) Live user's display name: "Kali Live user" -> "Shubham OS Live"
for d in "$ROOTFS/usr/lib/live/config" "$ROOTFS/etc/live/config" "$ROOTFS/lib/live/config"; do
  if [ -d "$d" ]; then
    sudo grep -rl 'Kali Live user' "$d" 2>/dev/null | while IFS= read -r f; do
      sudo sed -i 's/Kali Live user/Shubham OS Live/g' "$f"
    done
  fi
done
# (iii) User avatar (shown at the bottom of the menu) -> our logo
sudo cp "$PACK_DIR/images/shubham-os-logo.jpg" "$ROOTFS/etc/skel/.face" 2>/dev/null || true
if [ -d "$ROOTFS/home/kali" ]; then
  sudo cp "$PACK_DIR/images/shubham-os-logo.jpg" "$ROOTFS/home/kali/.face" 2>/dev/null || true
fi
# (iv) OS-level names in the menu: Kali Linux/Tools/Docs/Bugs -> Shubham OS ...
for f in "$ROOTFS"/usr/share/applications/*kali*.desktop; do
  [ -f "$f" ] && sudo sed -i 's/^Name=Kali Linux/Name=Shubham OS/; s/^Name=Kali Tools/Name=Shubham OS Tools/; s/^Name=Kali Docs/Name=Shubham OS Docs/; s/^Name=Kali Bugs/Name=Shubham OS Bugs/' "$f"
done
# (v) ShubhamOS Update app + version file
sudo cp "$PACK_DIR/apps/shubham-update.py" "$ROOTFS/usr/local/bin/shubham-update"
sudo chmod +x "$ROOTFS/usr/local/bin/shubham-update"
sudo cp "$PACK_DIR/apps/shubham-update.desktop" "$ROOTFS/usr/share/applications/"
sudo cp "$PACK_DIR/apps/shubham-update-check.sh" "$ROOTFS/usr/local/bin/shubham-update-check"
sudo chmod +x "$ROOTFS/usr/local/bin/shubham-update-check"
sudo mkdir -p "$ROOTFS/etc/xdg/autostart"
sudo cp "$PACK_DIR/apps/shubham-update-autostart.desktop" "$ROOTFS/etc/xdg/autostart/"
# Live Auto-Update machinery (the latest version installs itself as soon as Live starts)
sudo cp "$PACK_DIR/apps/shubham-autoupdate.sh" "$ROOTFS/usr/local/bin/shubham-autoupdate"
sudo chmod +x "$ROOTFS/usr/local/bin/shubham-autoupdate"
sudo cp "$PACK_DIR/apps/shubham-live-sudoers" "$ROOTFS/etc/sudoers.d/shubham-live-update"
sudo chmod 440 "$ROOTFS/etc/sudoers.d/shubham-live-update"
echo "5" | sudo tee "$ROOTFS/etc/shubham-os-version" > /dev/null
# (vi) Updater pin in the taskbar + Mac-like dock at the bottom (on the system default panel)
if [ -f "$ROOTFS/etc/xdg/xfce4/panel/default.xml" ]; then
  python3 "$PACK_DIR/scripts/panel-pin.py" "$ROOTFS/etc/xdg/xfce4/panel/default.xml" "$ROOTFS/usr/share/applications" || true
fi

# (vii) Security: Firewall ON by default (nftables) — everything closed from outside, everything open from inside (like Windows Firewall)
cat << 'NFT' | sudo tee "$ROOTFS/etc/nftables.conf" > /dev/null
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    iif "lo" accept
    ct state established,related accept
    ct state invalid drop
  }
  chain forward {
    type filter hook forward priority 0; policy drop;
  }
  chain output {
    type filter hook output priority 0; policy accept;
  }
}
NFT
sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
sudo ln -sf /lib/systemd/system/nftables.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/nftables.service"

echo "[5/7] Changing the name and user in the boot menu..."
# GRUB: name on the menuentry line; user/hostname on the linux line
GRUBCFG="$ISO_COPY/boot/grub/grub.cfg"
if [ -f "$GRUBCFG" ]; then
  sed -i '/menuentry/ s/Kali GNU\/Linux/Shubham OS/g; /menuentry/ s/Kali/Shubham OS/g' "$GRUBCFG"
  sed -i '/^[[:space:]]*linux/ { /username=/! s/ ---/ username=shubham hostname=shubham-os ---/; /username=/! s/$/ username=shubham hostname=shubham-os/ }' "$GRUBCFG"
fi
# ISOLINUX: name on the menu label; user/hostname on the append line
for CFG in "$ISO_COPY"/isolinux/live.cfg "$ISO_COPY"/syslinux/live.cfg; do
  if [ -f "$CFG" ]; then
    sed -i '/menu label/ s/Kali/Shubham OS/g' "$CFG"
    sed -i '/append boot=live/ { /username=/! s/ ---/ username=shubham hostname=shubham-os ---/; /username=/! s/$/ username=shubham hostname=shubham-os/ }' "$CFG"
  fi
done

# v3: Boot menu title + option names + splash image (the big KALI logo)
for CFG in "$ISO_COPY"/isolinux/live.cfg "$ISO_COPY"/syslinux/live.cfg; do
  if [ -f "$CFG" ]; then
    sed -i '/menu title/ { s/Kali Linux/Shubham OS/g; s/Kali/Shubham OS/g }' "$CFG"
    sed -i '/menu label/ { s/Live system/Shubham OS Live/g; s/Start installer/Install Shubham OS/g }' "$CFG"
  fi
done
# Boot splash: make a 640x480 branded splash from our dark wallpaper and put it on every splash.png
if command -v convert >/dev/null 2>&1; then
  convert "$PACK_DIR/images/wallpaper-kali-mode.jpg" -resize 640x480^ -gravity center -extent 640x480 /tmp/shubham-splash.png 2>/dev/null || true
  if [ -f /tmp/shubham-splash.png ]; then
    while IFS= read -r -d '' s; do cp /tmp/shubham-splash.png "$s"; done < <(find "$ISO_COPY" -name 'splash.png' -print0 2>/dev/null)
  fi
fi
# In GRUB theme text files too, Kali -> Shubham OS
grep -rl 'Kali' "$ISO_COPY/boot/grub" 2>/dev/null | while IFS= read -r f; do
  case "$f" in *.cfg|*.txt|*.theme) sed -i 's/Kali Linux/Shubham OS/g; s/Kali/Shubham OS/g' "$f" ;; esac
done

echo "[6/7] Packing the system back (the longest part)..."
sudo rm -f "$SQ"
sudo mksquashfs "$ROOTFS" "$SQ" -comp xz -noappend > /dev/null

echo "[7/7] Building the new ISO..."
ISO_OUT="$HOME/ShubhamOS-v1.iso"
xorriso -indev "$ISO_IN" -outdev "$ISO_OUT" -boot_image any replay \
  -map "$SQ" /live/filesystem.squashfs \
  -map "$GRUBCFG" /boot/grub/grub.cfg 2>/dev/null || \
xorriso -indev "$ISO_IN" -outdev "$ISO_OUT" -boot_image any replay \
  -map "$SQ" /live/filesystem.squashfs

sudo rm -rf "$WORK"
echo "==============================================="
echo "  DONE! The Shubham OS ISO is ready:"
ls -lh "$ISO_OUT"
echo "  Make a new VM in VMware and boot it —"
echo "  first run Live, then try Install."
echo "==============================================="
