#!/bin/bash
# ============================================================
#  SHUBHAM OS — One-Shot Build Script
#  Run on Kali Linux — this script itself:
#    1) installs live-build
#    2) gets the official Kali live-build config
#    3) adds the Shubham OS branding, wallpaper, toggle commands
#    4) builds the ISO (with both Live + Install)
#  Needs: Kali machine/VM, internet, ~25 GB free space,
#             and time (the first build can take 1-3 hours)
# ============================================================
set -e
cd "$(dirname "$0")"

echo "==============================================="
echo "  SHUBHAM OS BUILD IS STARTING"
echo "==============================================="

# --- Check: is it Kali/Debian or not ---
if ! command -v apt >/dev/null 2>&1; then
  echo "ERROR: This script only runs on Kali/Debian."
  exit 1
fi

# --- Step 1: Tools install ---
echo "[1/5] Installing live-build and git..."
sudo apt update
sudo apt install -y live-build git

# --- Step 2: Official Kali build config ---
echo "[2/5] Downloading the Kali live-build config..."
if [ ! -d "shubham-os-build" ]; then
  git clone https://gitlab.com/kalilinux/build-scripts/live-build-config.git shubham-os-build
fi
cd shubham-os-build
PACK_DIR="$(cd .. && pwd)"
# If images came in base64, make PNGs (for GitHub text-push)
for B64 in images/*.b64; do [ -f "$B64" ] && base64 -d "$B64" > "${B64%.b64}"; done

# --- Step 3: Our files in the right place ---
echo "[3/5] Adding the Shubham OS branding..."
INC="kali-config/common/includes.chroot"
mkdir -p "$INC/usr/share/backgrounds/shubham-os"
mkdir -p "$INC/usr/share/pixmaps"
mkdir -p "$INC/usr/local/bin"
mkdir -p "$INC/etc"
mkdir -p "$INC/usr/lib"

cp "$PACK_DIR/images/wallpaper-kali-mode.jpg"    "$INC/usr/share/backgrounds/shubham-os/"
cp "$PACK_DIR/images/wallpaper-windows-mode.jpg" "$INC/usr/share/backgrounds/shubham-os/"
cp "$PACK_DIR/images/shubham-os-logo.jpg"        "$INC/usr/share/pixmaps/"
cp "$PACK_DIR/scripts/shubham-windows"           "$INC/usr/local/bin/"
cp "$PACK_DIR/scripts/shubham-kali"              "$INC/usr/local/bin/"
chmod +x "$INC/usr/local/bin/shubham-windows" "$INC/usr/local/bin/shubham-kali"
cp "$PACK_DIR/branding/os-release" "$INC/etc/os-release"
cp "$PACK_DIR/branding/os-release" "$INC/usr/lib/os-release"
cp "$PACK_DIR/branding/hostname"   "$INC/etc/hostname"
cp "$PACK_DIR/branding/motd"       "$INC/etc/motd"

# Package list (in the XFCE variant, or in common if not found)
if [ -d "kali-config/variant-xfce/package-lists" ]; then
  cp "$PACK_DIR/live-config/shubham.list.chroot" "kali-config/variant-xfce/package-lists/"
else
  mkdir -p "kali-config/common/package-lists"
  cp "$PACK_DIR/live-config/shubham.list.chroot" "kali-config/common/package-lists/"
fi

# --- Step 4: ISO build ---
echo "[4/5] The ISO is being built... this will take time, do not turn off the machine."
./build.sh --verbose --variant xfce || ./build.sh --verbose

# --- Step 5: Result ---
echo "[5/5] Build finished!"
echo "==============================================="
echo "  The Shubham OS ISO will be found here:"
ls -lh images/*.iso 2>/dev/null || find . -name "*.iso" -exec ls -lh {} \;
echo "  Boot this ISO in VMware and run Live,"
echo "  or Install it and try. Congratulations!"
echo "==============================================="
