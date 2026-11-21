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
# Toggle commands
sudo cp "$PACK_DIR/scripts/shubham-windows" "$ROOTFS/usr/local/bin/"
sudo cp "$PACK_DIR/scripts/shubham-kali"    "$ROOTFS/usr/local/bin/"
sudo chmod +x "$ROOTFS/usr/local/bin/shubham-windows" "$ROOTFS/usr/local/bin/shubham-kali"
# Default wallpaper (naye user ke liye, XFCE)
sudo mkdir -p "$ROOTFS/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
cat << 'XML' | sudo tee "$ROOTFS/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="image-path" type="string" value="/usr/share/backgrounds/shubham-os/wallpaper-kali-mode.jpg"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XML

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
