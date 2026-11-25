# Shubham OS Update 25 - Carry My OS disk list fix.
#
# Why: shubham-carry listed pen drives with the filter TRAN=usb OR RM=1.
# That filter had two faults: it showed the VMware CD drive /dev/sr0 in
# the list, and it hid VMware virtual disks (sata, RM 0). So a virtual
# disk could not be used to test Carry without a real pen drive.
# This update changes ONLY the disk list:
#   - any whole disk (TYPE disk) is listed, pen drive or virtual disk;
#   - CD drives (/dev/sr*) are never listed;
#   - the system disk itself is never listed (it is still refused too).
# Everything else in carry is unchanged: the ISO finder, the typed
# capital YES warning, dd conv=fsync, the fdisk persistence part
# (official Kali sequence), mkfs.ext4 -L persistence and
# persistence.conf "/ union".
# Only shubham-carry changes. The other 16 features are not touched.
#
# Safety, the same as Updates 19 to 24:
#   0. This script first checks its own file is complete (an end marker
#      must be present). An incomplete copy changes NOTHING and stops.
#   1. The command file is written to a temporary name, checked (not
#      empty, correct shell syntax), and only then moved into place.
#   2. The new command is checked by SHA-256 hash at the end.
#   3. If anything fails, the version is NOT written and the update
#      reports FAILED.
# The panel is not touched. Runs as root via pkexec.

# --- Step 0: refuse an incomplete copy of this update ---------------------
if [ -f "$0" ]; then
  GATE_COUNT=$(grep -c "SHUBHAM25_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 25 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 25 (Carry disk list fix) is being applied..."

# write_verified DEST -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1"
  local tmp="${dest}.tmp-shubham25"
  if ! cat > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"
    return 1
  fi
  if ! bash -n "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    return 1
  fi
  chmod 755 "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  if ! mv -f "$tmp" "$dest"; then
    rm -f "$tmp"
    return 1
  fi
  return 0
}

fail_out() {
  echo "Shubham OS Update 25 FAILED its check. Your old version is kept."
  echo "Please tell the developer what the updater showed."
  exit 1
}

mkdir -p /usr/local/bin
echo "Step 1: installing the fixed Carry My OS..."
write_verified /usr/local/bin/shubham-carry << 'SHUBHAM_CARRY_25A'
#!/bin/bash
# Shubham OS - Carry My OS: put your whole Shubham OS on a pen drive.
# Boot any PC from it. A second part on the pen drive saves your
# settings and work (persistence), so they are there next time too.
# Nothing starts by itself - you pick the pen drive and say YES.

echo "Carry My OS - your whole system on a pen drive."
echo ""

# --- Find the Shubham OS ISO file -----------------------------------------
mapfile -t ISOS < <({ find "$HOME" -maxdepth 1 -iname "*.iso" 2>/dev/null; find "$HOME/Downloads" "$HOME/Desktop" -maxdepth 1 -iname "*.iso" 2>/dev/null; } | sort -u)
if [ "${#ISOS[@]}" -eq 0 ]; then
  echo "The Shubham OS ISO file is not on this PC."
  echo "Put ShubhamOS.iso in your Downloads folder, then run this again."
  exit 1
fi
ISO=""
if [ "${#ISOS[@]}" -eq 1 ]; then
  ISO="${ISOS[0]}"
else
  echo "ISO files found:"
  for i in "${!ISOS[@]}"; do echo "  $((i + 1))) ${ISOS[$i]}"; done
  read -r -p "Type the number of the Shubham OS ISO: " N
  case "$N" in ''|*[!0-9]*) echo "That is not a number. Run it again."; exit 1 ;; esac
  if [ "$N" -lt 1 ] || [ "$N" -gt "${#ISOS[@]}" ]; then
    echo "That number is not in the list. Run it again."
    exit 1
  fi
  ISO="${ISOS[$((N - 1))]}"
fi
ISO_SIZE=$(stat -c %s "$ISO" 2>/dev/null || echo 0)
echo "Using ISO: $ISO"

# --- Find disks -------------------------------------------------------------
# Any whole disk can be used, not only a pen drive: a virtual disk in
# VMware works the same way for a test. CD drives are never listed,
# and the system disk itself is never listed.
ROOT_DISK=$(lsblk -no PKNAME "$(findmnt -no SOURCE / 2>/dev/null)" 2>/dev/null | head -1)
mapfile -t USB_LINES < <(lsblk -dpno NAME,TRAN,RM,SIZE,MODEL,TYPE 2>/dev/null | awk -v root="$ROOT_DISK" '$NF == "disk" && $1 !~ /^\/dev\/sr/ && (root == "" || $1 != "/dev/" root) {print}')
DEV=""
if [ "${#USB_LINES[@]}" -eq 0 ]; then
  echo "No pen drive found. Put a pen drive in the PC, then run this again."
  exit 1
elif [ "${#USB_LINES[@]}" -eq 1 ]; then
  DEV=$(echo "${USB_LINES[0]}" | awk '{print $1}')
  if [ "$DEV" = "/dev/$ROOT_DISK" ] && [ -n "$ROOT_DISK" ]; then
    echo "The only drive found is the system drive itself. Put a pen drive in."
    exit 1
  fi
  echo "Pen drive found: ${USB_LINES[0]}"
else
  echo "Pen drives found:"
  for i in "${!USB_LINES[@]}"; do echo "  $((i + 1))) ${USB_LINES[$i]}"; done
  read -r -p "Type the number of the pen drive: " N
  case "$N" in ''|*[!0-9]*) echo "That is not a number. Run it again."; exit 1 ;; esac
  if [ "$N" -lt 1 ] || [ "$N" -gt "${#USB_LINES[@]}" ]; then
    echo "That number is not in the list. Run it again."
    exit 1
  fi
  DEV=$(echo "${USB_LINES[$((N - 1))]}" | awk '{print $1}')
fi
if [ -n "$ROOT_DISK" ] && [ "$DEV" = "/dev/$ROOT_DISK" ]; then
  echo "That is the system drive itself. Stopped - it will NOT be touched."
  exit 1
fi
DEV_SIZE=$(lsblk -dbno SIZE "$DEV" 2>/dev/null | head -1)
if [ -z "$DEV_SIZE" ] || [ "$ISO_SIZE" -ge "$DEV_SIZE" ]; then
  echo "The pen drive is too small for this ISO. Use a bigger pen drive."
  exit 1
fi

# --- The warning ------------------------------------------------------------
echo ""
echo "WARNING - read this first."
echo "Pen drive:  $DEV"
echo "ALL old data on this pen drive will be ERASED. Fully."
echo "The PC's own disks are not touched."
echo ""
read -r -p "Type YES in capital letters to continue: " GO
if [ "$GO" != "YES" ]; then
  echo "OK, stopped. Nothing was changed."
  exit 0
fi

echo ""
echo "Your PC password may be asked - it is for your safety."
sudo -v || { echo "Stopped. Nothing was changed."; exit 1; }

echo "Copying the system to the pen drive. This can take 20 to 40 minutes..."
if ! sudo dd if="$ISO" of="$DEV" bs=4M status=progress conv=fsync 2>&1; then
  echo "The copy failed. The pen drive may be bad. Nothing else was touched."
  exit 1
fi
sync
sudo partx -u "$DEV" 2>/dev/null
sleep 2

# --- The second part: persistence -------------------------------------------
FREE_START=$(( (ISO_SIZE / 1048576) + 1 ))
DEV_MIB=$(( DEV_SIZE / 1048576 ))
if [ $((DEV_MIB - FREE_START)) -gt 512 ]; then
  echo "Making the second part (it saves your settings and work)..."
  if printf "p\nn\np\n\n\n\n\np\nw\n" | sudo fdisk "$DEV" >/dev/null 2>&1; then
    sudo partx -u "$DEV" 2>/dev/null
    sleep 2
    PART=$(lsblk -no PATH "$DEV" 2>/dev/null | tail -1)
    if [ -n "$PART" ] && [ "$PART" != "$DEV" ] && sudo mkfs.ext4 -F -L persistence "$PART" >/dev/null 2>&1; then
      MNT=$(mktemp -d)
      if sudo mount "$PART" "$MNT" 2>/dev/null; then
        echo "/ union" | sudo tee "$MNT/persistence.conf" >/dev/null
        sudo umount "$MNT"
        echo "  OK  second part is ready (name: persistence)"
      else
        echo "  The second part was made, but its settings file could not be written."
      fi
      rmdir "$MNT" 2>/dev/null
    else
      echo "  The second part could not be made. The OS part is still fine."
    fi
  else
    echo "  The second part could not be made. The OS part is still fine."
  fi
else
  echo "The pen drive has no room for a second part. The OS part is ready."
fi

echo ""
echo "Done! Your Shubham OS is on the pen drive."
echo ""
echo "To use it on any PC:"
echo "  1. Put the pen drive in the PC."
echo "  2. Restart the PC and press the boot key (F12, Esc or F8)."
echo "  3. Choose the pen drive from the list."
echo "  4. If the start menu shows a Persistence option, choose it -"
echo "     your settings and work will be saved on the pen drive."
echo ""
echo "You can take the pen drive out now."
SHUBHAM_CARRY_25A
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-carry"

# --- Final check: the command must match its SHA-256 hash --------------------
echo ""
echo "Final check - matching the command by its hash..."
check_one() {
  local name="$1" want="$2"
  local f="/usr/local/bin/shubham-$name"
  local got=""
  if [ -f "$f" ]; then got=$(sha256sum "$f" 2>/dev/null | awk '{print $1}'); fi
  if [ "$got" != "$want" ]; then
    echo "  PROBLEM  shubham-$name does not match its hash."
    fail_out
  fi
  echo "  OK  shubham-$name ($(wc -c < "$f") bytes, hash matched)"
}
check_one carry ae503c2b30a76eb71e67eb11c689892577b0c06a36dece7405766596c94e7b08

echo 25 > /etc/shubham-os-version
echo ""
echo "Shubham OS Update 25 done!"
echo "  - shubham-carry now lists every real disk except the"
echo "    system disk, so a VMware virtual disk can be used to"
echo "    test Carry without a pen drive. CD drives are never"
echo "    listed. The YES warning and the copy are unchanged."
echo "Try it: add a virtual disk in VMware, then run shubham-carry."
exit 0
# SHUBHAM25_END_OF_FILE
