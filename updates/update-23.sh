# Shubham OS Update 23 - Batch 4: Practice Lab, Carry My OS, Google Chrome.
#
# The last batch of the Special Features (17 of 17 after this update):
#   1. shubham-lab   - Practice Lab: real Kali commands on a closed lab
#      (files in a lab folder + a small web page on 127.0.0.1 only).
#      Levels with save and continue, plus your own notes practice.
#   2. shubham-carry - Carry My OS: put the Shubham OS ISO on a pen
#      drive, with a second "persistence" part that saves settings and
#      work - the same method as the official Kali USB guide (dd, then
#      fdisk, ext4 partition named persistence, persistence.conf).
#   3. Google Chrome - installed from Google's official .deb package.
#
# Safety, the same as Updates 19 to 22:
#   0. This script first checks its own file is complete (an end marker
#      must be present). An incomplete copy changes NOTHING and stops.
#   1. Every command file is written to a temporary name, checked (not
#      empty, correct shell syntax), and only then moved into place.
#   2. Both new commands are checked by SHA-256 hash at the end.
#   3. Chrome must be present and able to report its version.
#   4. If anything fails, the version is NOT written and the update
#      reports FAILED.
# Nothing else on the system is touched. The panel is not touched.
# Runs as root via pkexec.

# --- Step 0: refuse an incomplete copy of this update ---------------------
if [ -f "$0" ]; then
  GATE_COUNT=$(grep -c "SHUBHAM23_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 23 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 23 (Batch 4 - Lab, Carry, Chrome) is being applied..."

# write_verified DEST -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1"
  local tmp="${dest}.tmp-shubham23"
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
  echo "Shubham OS Update 23 FAILED its check. Your old version is kept."
  echo "Please tell the developer what the updater showed."
  exit 1
}

mkdir -p /usr/local/bin
echo "Step 1: installing the Batch 4 commands..."
write_verified /usr/local/bin/shubham-lab << 'SHUBHAM_B4_23A'
#!/bin/bash
# Shubham OS - Practice Lab: a safe ground to practise real Kali commands.
# Every command is an original Kali command. The lab targets live only
# on this PC (files in the lab folder and a small web page on
# 127.0.0.1) - practice never touches the outside world.
LABDIR="$HOME/ShubhamLab"
STATEDIR="$HOME/.shubham-lab"
STATE="$STATEDIR/state"
PORT=8080

WORDS="tiger river mango rocket silver monsoon peacock thunder lotus cactus falcon harvest crystal breeze velvet"
pick_word() { local a=($WORDS); echo "${a[$((RANDOM % 15))]}"; }

save_state() {
  printf 'LEVEL=%s\nL1_COUNT=%s\nL2_WORD=%s\nL3_WORD=%s\nL5_WORD=%s\nL6_CODE=%s\nNOTES_POS=%s\n' \
    "$LEVEL" "$L1_COUNT" "$L2_WORD" "$L3_WORD" "$L5_WORD" "$L6_CODE" "$NOTES_POS" > "$STATE"
}
load_state() {
  LEVEL=1; L1_COUNT=0; L2_WORD=""; L3_WORD=""; L5_WORD=""; L6_CODE=""; NOTES_POS=0
  [ -f "$STATE" ] && . "$STATE"
}

server_start() {
  if [ -f "$STATEDIR/server.pid" ]; then
    local p; p=$(cat "$STATEDIR/server.pid" 2>/dev/null)
    if [ -n "$p" ] && kill -0 "$p" 2>/dev/null; then return 0; fi
  fi
  nohup python3 -m http.server $PORT --bind 127.0.0.1 --directory "$LABDIR/web" >/dev/null 2>&1 &
  echo $! > "$STATEDIR/server.pid"
  sleep 1
}
server_stop() {
  if [ -f "$STATEDIR/server.pid" ]; then
    kill "$(cat "$STATEDIR/server.pid" 2>/dev/null)" 2>/dev/null
    rm -f "$STATEDIR/server.pid"
  fi
}

make_ground() {
  rm -rf "$LABDIR"
  mkdir -p "$LABDIR/targets" "$LABDIR/web" "$STATEDIR"
  local i
  for i in 1 2 3 4 5 6 7; do echo "Practice file number $i. Nothing secret here." > "$LABDIR/targets/file-$i.txt"; done
  L2_WORD=$(pick_word)
  echo "The secret word is: $L2_WORD" > "$LABDIR/targets/.hidden-file"
  L3_WORD=$(pick_word)
  echo "The locked word is: $L3_WORD" > "$LABDIR/targets/locked.txt"
  chmod 000 "$LABDIR/targets/locked.txt"
  L5_WORD=$(pick_word)
  cat > "$LABDIR/web/index.html" <<EOF
<html><head><title>Shubham Lab Target</title></head>
<body><h1>Shubham Lab - Practice Target</h1>
<p>This page lives only on this PC. It is your practice target.</p>
<p>Today's code word is: <b>$L5_WORD</b></p>
</body></html>
EOF
  L6_CODE=$(( (RANDOM % 9000) + 1000 ))
  : > "$LABDIR/log.txt"
  for i in $(seq 1 40); do echo "INFO  system check $i done, all normal" >> "$LABDIR/log.txt"; done
  echo "ERROR code $L6_CODE found in the practice log" >> "$LABDIR/log.txt"
  for i in $(seq 41 60); do echo "INFO  system check $i done, all normal" >> "$LABDIR/log.txt"; done
  echo "This is the lab banner. Nothing here yet." > "$LABDIR/banner.txt"
  echo "Shubham Lab practice report. The eagle flies at dawn." > "$LABDIR/targets/report.txt"
  L1_COUNT=$(ls -1 "$LABDIR/targets" | wc -l)
  cat > "$LABDIR/Sample-Notes.txt" <<'EOF'
# My first practice set
ls
pwd
whoami
# Files
cat /etc/os-release
ss -tlnp
EOF
  LEVEL=1; NOTES_POS=0
  save_state
}

ask() { # $1 = correct answer; returns 0 if correct or saved
  local want="$1" ans
  read -r -p "Your answer (or type save): " ans
  if [ "$ans" = "save" ] || [ "$ans" = "Save" ]; then
    save_state
    echo "Saved. Run shubham-lab and choose Saved Lab to continue from here."
    echo "The lab web page stays ON, only on this PC (127.0.0.1)."
    exit 0
  fi
  if [ "$ans" = "$want" ]; then return 0; fi
  echo "Not right. Try again - the answer is case-sensitive."
  return 1
}

practice() {
  load_state
  server_start
  echo ""
  echo "Practice Lab - the commands are real Kali commands."
  echo "Do each task in a SECOND terminal, then type the answer here."
  while [ "$LEVEL" -le 8 ]; do
    echo ""
    case "$LEVEL" in
      1) echo "LEVEL 1 - Look around"
         echo "Task: How many files are inside the lab targets folder?"
         echo "Command that helps:  ls $LABDIR/targets"
         ask "$L1_COUNT" || continue ;;
      2) echo "LEVEL 2 - Find the hidden file"
         echo "Task: A hidden file in the targets folder holds a secret word. Type the word."
         echo "Command that helps:  ls -a $LABDIR/targets   then   cat the hidden file"
         ask "$L2_WORD" || continue ;;
      3) echo "LEVEL 3 - The locked file"
         echo "Task: locked.txt cannot be read. Give it read permission, read it, type the word."
         echo "Command that helps:  chmod +r $LABDIR/targets/locked.txt   then   cat it"
         ask "$L3_WORD" || continue ;;
      4) echo "LEVEL 4 - Scan your own PC"
         echo "Task: Scan this PC (127.0.0.1) and find the lab web page port. Type the port number."
         echo "Command that helps:  nmap 127.0.0.1"
         ask "$PORT" || continue ;;
      5) echo "LEVEL 5 - See the lab page"
         echo "Task: The lab page shows a code word. Type the word."
         echo "Command that helps:  curl http://127.0.0.1:$PORT"
         ask "$L5_WORD" || continue ;;
      6) echo "LEVEL 6 - Hunt in the log"
         echo "Task: The lab log has one ERROR line with a code number. Type the number."
         echo "Command that helps:  grep ERROR $LABDIR/log.txt"
         ask "$L6_CODE" || continue ;;
      7) echo "LEVEL 7 - Hash a file"
         echo "Task: Find the sha256 hash of report.txt. Type its FIRST 8 letters/numbers."
         echo "Command that helps:  sha256sum $LABDIR/targets/report.txt"
         local h; h=$(sha256sum "$LABDIR/targets/report.txt" 2>/dev/null | cut -c1-8)
         ask "$h" || continue ;;
      8) echo "LEVEL 8 - Change the banner"
         echo "Task: Put this exact text in the banner file:  SHUBHAM LAB DONE"
         echo "Command that helps:  echo \"SHUBHAM LAB DONE\" > $LABDIR/banner.txt"
         read -r -p "Do it in the second terminal, then press Enter (or type save): " ans8
         if [ "$ans8" = "save" ]; then save_state; echo "Saved. Continue any time with Saved Lab."; exit 0; fi
         if [ "$(cat "$LABDIR/banner.txt" 2>/dev/null)" = "SHUBHAM LAB DONE" ]; then
           :
         else
           echo "The banner does not say it yet. Try again."
           continue
         fi ;;
    esac
    echo "Correct! Level $LEVEL done."
    LEVEL=$((LEVEL + 1))
    save_state
  done
  echo ""
  echo "==============================================="
  echo "PRACTICE LAB COMPLETE - all 8 levels done."
  echo "You used real Kali commands, on a closed lab."
  echo "Choose Reset in the menu to play again with new secrets."
  echo "==============================================="
}

notes_practice() {
  local file="$LABDIR/my-notes.txt"
  if [ ! -s "$file" ]; then
    echo "No notes imported yet. Choose Import Notes first."
    exit 0
  fi
  load_state
  mapfile -t LINES < "$file"
  local total=${#LINES[@]} i title="" cmd
  if [ "$NOTES_POS" -ge "$total" ]; then NOTES_POS=0; fi
  echo ""
  echo "My Notes Practice - the lab only SHOWS each command."
  echo "You run it yourself in a second terminal. Nothing runs by itself."
  for ((i = NOTES_POS; i < total; i++)); do
    cmd="${LINES[$i]}"
    case "$cmd" in
      \#*) title="${cmd#\# }" ;;
      "") ;;
      *) echo ""
         [ -n "$title" ] && echo "Topic: $title"
         echo "Command:  $cmd"
         read -r -p "Press Enter for the next command, or type save: " a
         NOTES_POS=$((i + 1)); save_state
         if [ "$a" = "save" ]; then echo "Saved at command $NOTES_POS of $total."; exit 0; fi ;;
    esac
  done
  NOTES_POS=0; save_state
  echo "Notes finished. Next time they start from the top again."
}

import_notes() {
  mkdir -p "$LABDIR" "$STATEDIR"
  if [ ! -f "$LABDIR/Sample-Notes.txt" ]; then
    cat > "$LABDIR/Sample-Notes.txt" <<'EOF'
# My first practice set
ls
pwd
whoami
# Files
cat /etc/os-release
ss -tlnp
EOF
  fi
  if [ ! -f "$STATEDIR/notes-shown" ]; then
    echo ""
    echo "Notes format - only this format can be imported:"
    echo "  - One command on one line."
    echo "  - A line starting with # is a topic title, not a command."
    echo "  - Empty lines are skipped."
    echo "Rules:"
    echo "  - Imported commands become practice cards in your lab."
    echo "  - The lab only SHOWS a command. You run it yourself."
    echo "  - The lab never runs your notes commands by itself."
    echo "A sample file is here: $LABDIR/Sample-Notes.txt"
    touch "$STATEDIR/notes-shown"
  fi
  echo ""
  read -r -p "Type the path of your notes file: " NF
  NF="${NF/#\~/$HOME}"
  if [ ! -f "$NF" ]; then
    echo "That file was not found. Nothing was imported."
    exit 1
  fi
  local count=0 line
  : > "$LABDIR/my-notes.txt"
  while IFS= read -r line || [ -n "$line" ]; do
    echo "$line" >> "$LABDIR/my-notes.txt"
    case "$line" in \#*|"") ;; *) count=$((count + 1)) ;; esac
  done < "$NF"
  load_state; NOTES_POS=0; save_state
  echo "Imported. Your notes hold $count commands."
  echo "Choose My Notes Practice in the menu to practise from them."
}

echo "Shubham OS - Practice Lab"
echo ""
echo "What do you want to do?"
echo "  1) New Lab        (fresh ground, new secrets, start at Level 1)"
echo "  2) Saved Lab      (continue from your saved level)"
echo "  3) My Notes Practice"
echo "  4) Import Notes"
echo "  5) Reset Lab      (stop the lab page, wipe the ground and progress)"
read -r -p "Type 1, 2, 3, 4 or 5: " CH

case "$CH" in
  1) if [ -f "$STATE" ]; then
       read -r -p "An old lab exists. A New Lab wipes it. Start new? (y/n): " GO
       [ "$GO" = "y" ] || [ "$GO" = "Y" ] || { echo "OK, nothing was changed."; exit 0; }
     fi
     server_stop
     make_ground
     echo "New Lab is ready in: $LABDIR"
     practice ;;
  2) if [ ! -f "$STATE" ]; then
       echo "No saved lab found. Choose New Lab first."
       exit 0
     fi
     load_state
     if [ "$LEVEL" -gt 8 ]; then
       echo "Your saved lab is already complete. Choose Reset, then New Lab."
       exit 0
     fi
     echo "Continuing from Level $LEVEL."
     practice ;;
  3) notes_practice ;;
  4) import_notes ;;
  5) read -r -p "Reset wipes the lab ground and your progress. Are you sure? (y/n): " GO
     if [ "$GO" = "y" ] || [ "$GO" = "Y" ]; then
       server_stop
       rm -rf "$LABDIR" "$STATEDIR"
       echo "Lab reset done. The ground is empty and the lab page is stopped."
     else
       echo "OK, nothing was changed."
     fi ;;
  *) echo "Please run it again and type 1, 2, 3, 4 or 5." ;;
esac
SHUBHAM_B4_23A
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-lab"

write_verified /usr/local/bin/shubham-carry << 'SHUBHAM_B4_23B'
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

# --- Find pen drives --------------------------------------------------------
ROOT_DISK=$(lsblk -no PKNAME "$(findmnt -no SOURCE / 2>/dev/null)" 2>/dev/null | head -1)
mapfile -t USB_LINES < <(lsblk -dpno NAME,TRAN,RM,SIZE,MODEL 2>/dev/null | awk '$2 == "usb" || $3 == 1 {print}')
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
SHUBHAM_B4_23B
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-carry"

echo ""
echo "Step 2: Google Chrome..."
if command -v google-chrome >/dev/null 2>&1; then
  echo "  OK  Google Chrome is already here"
else
  echo "  Downloading Google Chrome from Google's official site..."
  apt-get update -qq >/dev/null 2>&1
  if curl -fsSL -o /tmp/google-chrome-shubham.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" 2>/dev/null; then
    apt-get install -y /tmp/google-chrome-shubham.deb >/dev/null 2>&1
  fi
  rm -f /tmp/google-chrome-shubham.deb
fi
if ! command -v google-chrome >/dev/null 2>&1 || ! google-chrome --version >/dev/null 2>&1; then
  echo "  PROBLEM  Google Chrome could not be installed. Check the internet."
  fail_out
fi
echo "  OK  Google Chrome is ready"

# --- Final check: every new command must match its SHA-256 hash --------------
echo ""
echo "Final check - matching every new command by its hash..."
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
check_one lab   fa0ffb376e0df196bc66780fe64577f0471614e331a6d234246abcdc3e025c95
check_one carry 6f7379aeaef37850230770f9ada4646f2e1420e8fd45e6b141bd5e7b14feb05e

echo 23 > /etc/shubham-os-version
echo ""
echo "Shubham OS Update 23 done!"
echo "  - shubham-lab   - the Practice Lab is ready"
echo "  - shubham-carry - Carry My OS is ready"
echo "  - Google Chrome is installed"
echo "All 17 Special Features are now complete."
echo "Type shubham-help to see all commands."
exit 0
# SHUBHAM23_END_OF_FILE
