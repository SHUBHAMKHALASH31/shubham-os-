#!/bin/bash
# ============================================================
#  SHUBHAM OS — One-Shot Build Script
#  Kali Linux par chalao — ye script khud:
#    1) live-build install karegi
#    2) Kali ka official live-build config legi
#    3) Shubham OS ka branding, wallpaper, toggle commands jodegi
#    4) ISO banayegi (Live + Install dono wali)
#  Zaroorat: Kali machine/VM, internet, ~25 GB khali jagah,
#             aur samay (pehli build me 1-3 ghante lag sakte hai)
# ============================================================
set -e
cd "$(dirname "$0")"

echo "==============================================="
echo "  SHUBHAM OS BUILD SHURU HO RAHA HAI"
echo "==============================================="

# --- Check: Kali/Debian hai ya nahi ---
if ! command -v apt >/dev/null 2>&1; then
  echo "ERROR: Ye script sirf Kali/Debian par chalegi."
  exit 1
fi

# --- Step 1: Tools install ---
echo "[1/5] live-build aur git install ho raha hai..."
sudo apt update
sudo apt install -y live-build git

# --- Step 2: Kali ka official build config ---
echo "[2/5] Kali live-build config download ho raha hai..."
if [ ! -d "shubham-os-build" ]; then
  git clone https://gitlab.com/kalilinux/build-scripts/live-build-config.git shubham-os-build
fi
cd shubham-os-build
PACK_DIR="$(cd .. && pwd)"
# Images base64 me aayi ho to PNG bana lo (GitHub text-push ke liye)
for B64 in images/*.b64; do [ -f "$B64" ] && base64 -d "$B64" > "${B64%.b64}"; done

# --- Step 3: Apna samaan sahi jagah par ---
echo "[3/5] Shubham OS ka branding joda ja raha hai..."
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

# Package list (XFCE variant me, na mile to common me)
if [ -d "kali-config/variant-xfce/package-lists" ]; then
  cp "$PACK_DIR/live-config/shubham.list.chroot" "kali-config/variant-xfce/package-lists/"
else
  mkdir -p "kali-config/common/package-lists"
  cp "$PACK_DIR/live-config/shubham.list.chroot" "kali-config/common/package-lists/"
fi

# --- Step 4: ISO build ---
echo "[4/5] ISO ban rahi hai... isme samay lagega, machine band mat karna."
./build.sh --verbose --variant xfce || ./build.sh --verbose

# --- Step 5: Result ---
echo "[5/5] Build khatm!"
echo "==============================================="
echo "  SHUBHAM OS ki ISO yaha milegi:"
ls -lh images/*.iso 2>/dev/null || find . -name "*.iso" -exec ls -lh {} \;
echo "  Is ISO ko VMware me boot karke Live chalao,"
echo "  ya Install karke try karo. Badhai ho!"
echo "==============================================="
