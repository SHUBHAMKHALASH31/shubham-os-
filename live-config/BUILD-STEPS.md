# Shubham OS — Build Steps (PC par chalenge, Muse ke sath step-by-step)

## Taiyaari (Kali VM ya PC ki Kali par)
1. sudo apt update && sudo apt install -y live-build git
2. Kali ka official live-build config lena:
   git clone https://gitlab.com/kalilinux/build-scripts/live-build-config.git shubham-os-build
3. cd shubham-os-build

## Apna samaan jodna
4. Is folder ke package-lists/shubham.list.chroot ko
   kali-config/variant-xfce/package-lists/ ke andar copy karna
5. Branding files (../branding/os-release, hostname, motd) ko
   kali-config/common/includes.chroot/etc/ ke andar rakhna
6. Toggle commands (shubham-windows, shubham-kali) ko
   kali-config/common/includes.chroot/usr/local/bin/ me rakhna + chmod +x
7. Wallpaper aur logo ko includes.chroot/usr/share/backgrounds/ aur
   /usr/share/pixmaps/ me rakhna

## ISO banana
8. ./build.sh --verbose --variant xfce
   (pehli baar time lagega — chai bana lena)
9. Taiyar ISO: images/ folder me milegi — Live + Install dono wali

## Test
10. VMware me nayi VM → ISO boot → Live chalao → phir Install karke dekho
11. Dono mode toggle karke check: shubham-windows / shubham-kali

Note: Har command build ke samay pehle verify karke hi chalegi — ye sirf roadmap hai.
