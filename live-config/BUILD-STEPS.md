# Shubham OS — Build Steps (run on a PC, step-by-step with Muse)

## Preparation (on a Kali VM or Kali on a PC)
1. sudo apt update && sudo apt install -y live-build git
2. Get the official Kali live-build config:
   git clone https://gitlab.com/kalilinux/build-scripts/live-build-config.git shubham-os-build
3. cd shubham-os-build

## Add your files
4. Copy this folder's package-lists/shubham.list.chroot
   into kali-config/variant-xfce/package-lists/
5. Put the branding files (../branding/os-release, hostname, motd)
   inside kali-config/common/includes.chroot/etc/
6. Put the toggle commands (shubham-windows, shubham-kali)
   in kali-config/common/includes.chroot/usr/local/bin/ + chmod +x
7. Put the wallpaper and logo in includes.chroot/usr/share/backgrounds/ and
   /usr/share/pixmaps/

## Build the ISO
8. ./build.sh --verbose --variant xfce
   (the first time takes a while — make some tea)
9. The finished ISO: found in the images/ folder — with both Live + Install

## Test
10. New VM in VMware → boot the ISO → run Live → then try Install
11. Check by toggling both modes: shubham-windows / shubham-kali

Note: Every command will be verified before running at build time — this is only a roadmap.
