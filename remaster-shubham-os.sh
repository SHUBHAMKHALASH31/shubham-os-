#!/bin/bash
# ============================================================
#  SHUBHAM OS — REMASTER (JUGAAD) SCRIPT
#  Tayyar Kali Live ISO ko khol kar andar Shubham OS ka
#  branding daal kar wapas band karti hai — nayi ISO taiyar.
#  Live-build wali lambi build ki jagah ye shortcut hai.
#
#  Chalana:
#    ./remaster-shubham-os.sh /path/to/kali-live.iso
#  Zaroorat: Kali machine/VM, internet (chhote tools ke liye),
#            VM me ~25 GB khali jagah
# ============================================================
set -e
cd "$(dirname "$0")"
PACK_DIR="$(pwd)"
# Images base64 me aayi ho to PNG bana lo (GitHub text-push ke liye)
for B64 in images/*.b64; do [ -f "$B64" ] && base64 -d "$B64" > "${B64%.b64}"; done
# Images repo me na ho to link se le lo (images/IMAGE-URLS.txt)
if [ -f images/IMAGE-URLS.txt ]; then while read -r INAME IURL; do [ -f "images/$INAME" ] || curl -sL -o "images/$INAME" "$IURL"; done < images/IMAGE-URLS.txt; fi

ISO_IN="${1:-}"
if [ -z "$ISO_IN" ] || [ ! -f "$ISO_IN" ]; then
  echo "ERROR: Kali Live ISO nahi mili."
  echo "Aise chalao:  ./remaster-shubham-os.sh ~/Downloads/kali-linux-live.iso"
  exit 1
fi

echo "==============================================="
echo "  SHUBHAM OS REMASTER SHURU"
echo "  Base ISO: $ISO_IN"
echo "==============================================="

echo "[1/7] Chhote tools install ho rahe hai..."
sudo apt update
sudo apt install -y squashfs-tools xorriso rsync

WORK="$HOME/shubham-remaster"
ISO_MNT="$WORK/mnt"
ISO_COPY="$WORK/iso-copy"
ROOTFS="$WORK/rootfs"
rm -rf "$WORK"
mkdir -p "$ISO_MNT" "$ISO_COPY" "$ROOTFS"

echo "[2/7] ISO khul rahi hai..."
sudo mount -o loop "$ISO_IN" "$ISO_MNT"
rsync -a "$ISO_MNT/" "$ISO_COPY/"
sudo umount "$ISO_MNT"
chmod -R u+w "$ISO_COPY"

SQ="$ISO_COPY/live/filesystem.squashfs"
if [ ! -f "$SQ" ]; then
  echo "ERROR: live/filesystem.squashfs nahi mili — ye Live ISO nahi lagti."
  exit 1
fi

echo "[3/7] System ki file khul rahi hai (thoda time lagega)..."
sudo unsquashfs -d "$ROOTFS" "$SQ" > /dev/null

echo "[4/7] Shubham OS ka branding dal raha hai..."
# Pehchan
sudo cp "$PACK_DIR/branding/os-release" "$ROOTFS/etc/os-release"
sudo cp "$PACK_DIR/branding/os-release" "$ROOTFS/usr/lib/os-release"
sudo cp "$PACK_DIR/branding/hostname"   "$ROOTFS/etc/hostname"
sudo cp "$PACK_DIR/branding/motd"       "$ROOTFS/etc/motd"
# Wallpaper + logo
sudo mkdir -p "$ROOTFS/usr/share/backgrounds/shubham-os"
sudo cp "$PACK_DIR/images/wallpaper-kali-mode.jpg"    "$ROOTFS/usr/share/backgrounds/shubham-os/"
sudo cp "$PACK_DIR/images/wallpaper-windows-mode.jpg" "$ROOTFS/usr/share/backgrounds/shubham-os/"
sudo cp "$PACK_DIR/images/shubham-os-logo.jpg"        "$ROOTFS/usr/share/pixmaps/"
# --- v2 FIX: wallpaper sach me apply ho — 3 pakke tareeke ---
# (a) Kali ke stock wallpaper files ko hi apne wale se badal do (format same rakhkar)
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
# (b) kali-undercover ke apne wallpaper bhi badal do — Windows mode me wahi lagta hai
while IFS= read -r -d '' f; do
  replace_img "$PACK_DIR/images/wallpaper-windows-mode.jpg" "$f"
done < <(sudo find "$ROOTFS/usr/share" -ipath '*undercover*' -type f \( -iname '*.jpg' -o -iname '*.png' \) -print0 2>/dev/null)
# (c) XFCE config — skel aur maujuda kali user dono ke liye, sahi property (last-image) ke saath
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

echo "[4.5/7] v3 branding: boot logo, user naam, menu naam, updater, dock..."
# (i) Plymouth boot logo (start wala dragon) -> apna golden emblem
while IFS= read -r -d '' f; do
  DIM=$(sudo identify -format '%wx%h' "$f" 2>/dev/null || echo "")
  if [ -n "$DIM" ]; then
    sudo convert "$PACK_DIR/images/shubham-os-logo.jpg" -resize "$DIM" "$f" 2>/dev/null || sudo cp "$PACK_DIR/images/shubham-os-logo.jpg" "$f"
  fi
done < <(sudo find "$ROOTFS/usr/share/plymouth/themes" -type f -iname '*.png' \( -iname '*logo*' -o -iname '*watermark*' \) -print0 2>/dev/null)
# (ii) Live user ka display naam: "Kali Live user" -> "Shubham OS Live"
for d in "$ROOTFS/usr/lib/live/config" "$ROOTFS/etc/live/config" "$ROOTFS/lib/live/config"; do
  if [ -d "$d" ]; then
    sudo grep -rl 'Kali Live user' "$d" 2>/dev/null | while IFS= read -r f; do
      sudo sed -i 's/Kali Live user/Shubham OS Live/g' "$f"
    done
  fi
done
# (iii) User avatar (menu ke neeche dikhta hai) -> apna logo
sudo cp "$PACK_DIR/images/shubham-os-logo.jpg" "$ROOTFS/etc/skel/.face" 2>/dev/null || true
if [ -d "$ROOTFS/home/kali" ]; then
  sudo cp "$PACK_DIR/images/shubham-os-logo.jpg" "$ROOTFS/home/kali/.face" 2>/dev/null || true
fi
# (iv) Menu ke OS-level naam: Kali Linux/Tools/Docs/Bugs -> Shubham OS ...
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
# Live Auto-Update machinery (Live start hote hi latest version khud lag jaye)
sudo cp "$PACK_DIR/apps/shubham-autoupdate.sh" "$ROOTFS/usr/local/bin/shubham-autoupdate"
sudo chmod +x "$ROOTFS/usr/local/bin/shubham-autoupdate"
sudo cp "$PACK_DIR/apps/shubham-live-sudoers" "$ROOTFS/etc/sudoers.d/shubham-live-update"
sudo chmod 440 "$ROOTFS/etc/sudoers.d/shubham-live-update"
echo "5" | sudo tee "$ROOTFS/etc/shubham-os-version" > /dev/null
# (vi) Taskbar me updater pin + neeche Mac-jaisa dock (system default panel par)
if [ -f "$ROOTFS/etc/xdg/xfce4/panel/default.xml" ]; then
  python3 "$PACK_DIR/scripts/panel-pin.py" "$ROOTFS/etc/xdg/xfce4/panel/default.xml" "$ROOTFS/usr/share/applications" || true
fi

# (vii) Security: Firewall default ON (nftables) — bahar se sab band, andar se sab khula (Windows Firewall jaisa)
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

echo "[5/7] Boot menu me naam aur user badal raha hai..."
# GRUB: menuentry wali line par naam; linux wali line par user/hostname
GRUBCFG="$ISO_COPY/boot/grub/grub.cfg"
if [ -f "$GRUBCFG" ]; then
  sed -i '/menuentry/ s/Kali GNU\/Linux/Shubham OS/g; /menuentry/ s/Kali/Shubham OS/g' "$GRUBCFG"
  sed -i '/^[[:space:]]*linux/ { /username=/! s/ ---/ username=shubham hostname=shubham-os ---/; /username=/! s/$/ username=shubham hostname=shubham-os/ }' "$GRUBCFG"
fi
# ISOLINUX: menu label par naam; append wali line par user/hostname
for CFG in "$ISO_COPY"/isolinux/live.cfg "$ISO_COPY"/syslinux/live.cfg; do
  if [ -f "$CFG" ]; then
    sed -i '/menu label/ s/Kali/Shubham OS/g' "$CFG"
    sed -i '/append boot=live/ { /username=/! s/ ---/ username=shubham hostname=shubham-os ---/; /username=/! s/$/ username=shubham hostname=shubham-os/ }' "$CFG"
  fi
done

# v3: Boot menu ka title + option naam + splash image (KALI wala bada logo)
for CFG in "$ISO_COPY"/isolinux/live.cfg "$ISO_COPY"/syslinux/live.cfg; do
  if [ -f "$CFG" ]; then
    sed -i '/menu title/ { s/Kali Linux/Shubham OS/g; s/Kali/Shubham OS/g }' "$CFG"
    sed -i '/menu label/ { s/Live system/Shubham OS Live/g; s/Start installer/Install Shubham OS/g }' "$CFG"
  fi
done
# Boot splash: apne dark wallpaper se 640x480 branded splash banao aur har splash.png par lagao
if command -v convert >/dev/null 2>&1; then
  convert "$PACK_DIR/images/wallpaper-kali-mode.jpg" -resize 640x480^ -gravity center -extent 640x480 /tmp/shubham-splash.png 2>/dev/null || true
  if [ -f /tmp/shubham-splash.png ]; then
    while IFS= read -r -d '' s; do cp /tmp/shubham-splash.png "$s"; done < <(find "$ISO_COPY" -name 'splash.png' -print0 2>/dev/null)
  fi
fi
# GRUB theme ke text files me bhi Kali -> Shubham OS
grep -rl 'Kali' "$ISO_COPY/boot/grub" 2>/dev/null | while IFS= read -r f; do
  case "$f" in *.cfg|*.txt|*.theme) sed -i 's/Kali Linux/Shubham OS/g; s/Kali/Shubham OS/g' "$f" ;; esac
done

echo "[6/7] System wapas pack ho raha hai (sabse lamba hissa)..."
sudo rm -f "$SQ"
sudo mksquashfs "$ROOTFS" "$SQ" -comp xz -noappend > /dev/null

echo "[7/7] Nayee ISO ban rahi hai..."
ISO_OUT="$HOME/ShubhamOS-v1.iso"
xorriso -indev "$ISO_IN" -outdev "$ISO_OUT" -boot_image any replay \
  -map "$SQ" /live/filesystem.squashfs \
  -map "$GRUBCFG" /boot/grub/grub.cfg 2>/dev/null || \
xorriso -indev "$ISO_IN" -outdev "$ISO_OUT" -boot_image any replay \
  -map "$SQ" /live/filesystem.squashfs

sudo rm -rf "$WORK"
echo "==============================================="
echo "  HO GAYA! Shubham OS ki ISO taiyar hai:"
ls -lh "$ISO_OUT"
echo "  Ise VMware me nayi VM bana kar boot karo —"
echo "  pehle Live chalao, phir Install try karo."
echo "==============================================="
