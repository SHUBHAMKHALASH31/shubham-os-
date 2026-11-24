# Shubham OS Update 21 - Special Features Batch 3, plus the Record fix.
#
# New commands:
#   shubham-doctor  (full PC check and repair)
#   shubham-live    (show your screen live, watch only)
#   shubham-ghost   (new identity, net the hidden way via Tor)
#
# Also in this update:
#   - The six Batch 2 commands are installed once more, so their state
#     is certain whatever happened in Updates 19 and 20.
#   - The tools some commands need are installed too: ffmpeg (Record
#     could not run without it - that was the Record problem), Tor
#     (Ghost), x11vnc + novnc (Live) and ClamAV (Doctor virus check).
#
# Safety, the same as Updates 19 and 20:
#   0. This script first checks its own file is complete (an end marker
#      must be present). An incomplete copy changes NOTHING and stops.
#   1. Every file is written to a temporary name, checked (not empty,
#      correct shell syntax), and only then moved into place.
#   2. All nine commands are checked by SHA-256 hash at the end.
#   3. The needed tools are checked at the end too. If a tool is
#      missing, the version is NOT written, so this update is offered
#      again - run it once more with good internet.
# Nothing else on the system is touched. The panel is not touched.
# Runs as root via pkexec.

# --- Step 0: refuse an incomplete copy of this update ---------------------
if [ -f "$0" ]; then
  GATE_COUNT=$(grep -c "SHUBHAM21_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 21 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 21 (Batch 3 + Record fix) is being applied..."

# write_verified DEST -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1"
  local tmp="${dest}.tmp-shubham21"
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
  echo "Shubham OS Update 21 FAILED its check. Your old version is kept."
  echo "Please tell the developer what the updater showed."
  exit 1
}

mkdir -p /usr/local/bin
echo "Installing all nine commands (Batch 2 once more, Batch 3 new)..."
write_verified /usr/local/bin/shubham-phone << 'SHUBHAM_B2_21A'
#!/bin/bash
# Shubham OS - Phone Connect: connect your phone with your PC, no cable needed.
# Run it, open the address on your phone, type the code, then send files both ways.
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python is not found on this PC, so Phone Connect cannot run."
  exit 1
fi

SHARE="$HOME/PhoneShare"
mkdir -p "$SHARE"
PORT=8377
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [ -z "$IP" ]; then
  echo "No network found. Connect this PC to WiFi first, then run it again."
  exit 1
fi
CODE="$(( (RANDOM % 9000) + 1000 ))"

SERVER="$(mktemp /tmp/shubham-phone-XXXXXX.py)"
cat > "$SERVER" << 'PYEOF'
import os, sys, html
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote

SHARE = os.environ["SHUBHAM_SHARE"]
CODE = os.environ["SHUBHAM_CODE"]

PAGE_LOGIN = """<!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Shubham OS - Phone Connect</title></head>
<body style="font-family:sans-serif;max-width:480px;margin:40px auto;padding:0 16px">
<h2>Shubham OS - Phone Connect</h2>
<p>Type the code shown on the PC screen:</p>
<form method="POST" action="/login"><input name="code" inputmode="numeric" style="font-size:20px;padding:8px;width:140px">
<button style="font-size:20px;padding:8px 16px">Connect</button></form>
</body></html>"""

def page_main():
    files = sorted(f for f in os.listdir(SHARE) if os.path.isfile(os.path.join(SHARE, f)))
    items = "".join('<li><a href="/file/%s">%s</a></li>' % (html.escape(f), html.escape(f)) for f in files)
    if not items:
        items = "<li>No files yet. Put a file in the PhoneShare folder on the PC, or send one from this phone.</li>"
    return """<!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Shubham OS - Phone Connect</title></head>
<body style="font-family:sans-serif;max-width:480px;margin:40px auto;padding:0 16px">
<h2>Shubham OS - Phone Connect</h2>
<h3>Send a file to the PC</h3>
<form method="POST" action="/upload" enctype="multipart/form-data">
<input type="file" name="file"><br><br><button style="font-size:18px;padding:8px 16px">Send</button></form>
<h3>Files on the PC (tap to download)</h3>
<ul>%s</ul>
</body></html>""" % items

class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass
    def ok_code(self):
        c = self.headers.get("Cookie", "")
        return ("code=" + CODE) in c
    def send_html(self, text, status=200, extra=None):
        b = text.encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(b)))
        if extra:
            self.send_header("Set-Cookie", extra)
        self.end_headers()
        self.wfile.write(b)
    def do_GET(self):
        path = unquote(self.path.split("?")[0])
        if path.startswith("/file/"):
            if not self.ok_code():
                self.send_html(PAGE_LOGIN)
                return
            name = os.path.basename(path[6:])
            full = os.path.join(SHARE, name)
            if not os.path.isfile(full):
                self.send_html("File not found.", 404)
                return
            data = open(full, "rb").read()
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", 'attachment; filename="%s"' % name)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        if not self.ok_code():
            self.send_html(PAGE_LOGIN)
            return
        self.send_html(page_main())
    def do_POST(self):
        if self.path == "/login":
            n = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(n).decode("utf-8", "replace")
            if ("code=" + CODE) in body:
                self.send_html("<html><body><p>Connected. <a href='/'>Open Phone Connect</a></p></body></html>",
                               extra="code=" + CODE + "; Path=/")
            else:
                self.send_html("<html><body><p>Wrong code. Go back and try again.</p></body></html>")
            return
        if self.path == "/upload":
            if not self.ok_code():
                self.send_html(PAGE_LOGIN)
                return
            ctype = self.headers.get("Content-Type", "")
            n = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(n)
            boundary = None
            for part in ctype.split(";"):
                part = part.strip()
                if part.startswith("boundary="):
                    boundary = part[9:].strip('"')
            saved = None
            if boundary:
                bnd = ("--" + boundary).encode()
                for chunk in body.split(bnd):
                    if b'filename="' in chunk:
                        head, _, data = chunk.partition(b"\r\n\r\n")
                        fname = head.split(b'filename="')[1].split(b'"')[0].decode("utf-8", "replace")
                        fname = os.path.basename(fname)
                        if fname:
                            if data.endswith(b"\r\n"):
                                data = data[:-2]
                            with open(os.path.join(SHARE, fname), "wb") as f:
                                f.write(data)
                            saved = fname
                        break
            if saved:
                self.send_html("<html><body><p>File saved on the PC: %s</p><p><a href='/'>Back</a></p></body></html>" % html.escape(saved))
            else:
                self.send_html("<html><body><p>No file was received. Go back and try again.</p></body></html>")
            return
        self.send_html("Not found.", 404)

ThreadingHTTPServer(("0.0.0.0", int(sys.argv[1])), H).serve_forever()
PYEOF

echo "Phone Connect is ON."
echo ""
echo "On your phone, open this address:"
echo "  http://$IP:$PORT"
echo ""
echo "Code: $CODE"
echo ""
echo "Files in this folder can be downloaded on the phone: $SHARE"
echo "Files sent from the phone also land in that folder."
echo "Press Ctrl+C to stop."
echo ""
SHUBHAM_SHARE="$SHARE" SHUBHAM_CODE="$CODE" python3 "$SERVER" "$PORT"
rm -f "$SERVER"
SHUBHAM_B2_21A
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-phone"

write_verified /usr/local/bin/shubham-locker << 'SHUBHAM_B2_21B'
#!/bin/bash
# Shubham OS - Data Locker: lock any file or folder with your own password.
# A locked file goes inside the locker and disappears from its place.
# Run the command again and unlock it with the same password.
if ! command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is not found on this PC, so Data Locker cannot run."
  exit 1
fi

LOCKER="$HOME/.shubham-locker"
mkdir -p "$LOCKER"
chmod 700 "$LOCKER" 2>/dev/null
PASSFILE="$LOCKER/.passhash"
INDEX="$LOCKER/index.txt"
touch "$INDEX"

hash_of() { printf '%s' "$1" | sha256sum | awk '{print $1}'; }

if [ ! -f "$PASSFILE" ]; then
  echo "Welcome to Data Locker. First time only - set your locker password."
  read -r -s -p "New password: " PW1; echo ""
  read -r -s -p "Type it again: " PW2; echo ""
  if [ -z "$PW1" ] || [ "$PW1" != "$PW2" ]; then
    echo "The two passwords do not match, or the password was empty. Run it again."
    exit 1
  fi
  hash_of "$PW1" > "$PASSFILE"
  chmod 600 "$PASSFILE"
  PW="$PW1"
  echo "Password set. Do not forget it - a locked file cannot be opened without it."
else
  read -r -s -p "Your locker password: " PW; echo ""
  if [ "$(hash_of "$PW")" != "$(cat "$PASSFILE")" ]; then
    echo "Wrong password. Nothing was changed."
    exit 1
  fi
fi

echo ""
echo "What do you want to do?"
echo "  1) Lock a file or folder"
echo "  2) Unlock a file or folder"
read -r -p "Type 1 or 2: " CH

if [ "$CH" = "1" ]; then
  read -r -p "Type (or drop) the path of the file or folder: " TARGET
  TARGET="$(printf '%s' "$TARGET" | sed "s/^'//; s/'$//; s/^\"//; s/\"$//")"
  TARGET="${TARGET/#\~/$HOME}"
  if [ ! -e "$TARGET" ]; then
    echo "That file or folder was not found. Run it again and check the path."
    exit 1
  fi
  BASE="$(basename "$TARGET")"
  PARENT="$(dirname "$TARGET")"
  STAMP="$(date +%Y%m%d-%H%M%S)"
  SAFE="$(printf '%s' "$BASE" | tr -c 'A-Za-z0-9._-' '_')"
  STORED="${SAFE}-${STAMP}.locked"
  TMPENC="$LOCKER/.tmp-$STORED"
  if tar -czf - -C "$PARENT" "$BASE" 2>/dev/null | openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$PW" -out "$TMPENC" && [ -s "$TMPENC" ]; then
    mv -f "$TMPENC" "$LOCKER/$STORED"
    printf '%s|%s|%s\n' "$STORED" "$TARGET" "$BASE" >> "$INDEX"
    rm -rf "$TARGET"
    echo ""
    echo "Locked: $BASE"
    echo "It is gone from its place and safe inside the locker."
  else
    rm -f "$TMPENC"
    echo "Locking failed. Your file was NOT touched."
    exit 1
  fi

elif [ "$CH" = "2" ]; then
  if [ ! -s "$INDEX" ]; then
    echo "The locker is empty. Nothing to unlock."
    exit 0
  fi
  echo ""
  echo "Files in the locker:"
  i=1
  while IFS='|' read -r STORED ORIG BASE; do
    echo "  $i) $BASE  (was at: $ORIG)"
    i=$((i+1))
  done < "$INDEX"
  TOTAL=$((i-1))
  echo ""
  read -r -p "Type the number to unlock: " N
  case "$N" in
    ''|*[!0-9]*) echo "That is not a number. Run it again."; exit 1 ;;
  esac
  if [ "$N" -lt 1 ] || [ "$N" -gt "$TOTAL" ]; then
    echo "That number is not in the list. Run it again."
    exit 1
  fi
  LINE="$(sed -n "${N}p" "$INDEX")"
  STORED="$(printf '%s' "$LINE" | cut -d'|' -f1)"
  ORIG="$(printf '%s' "$LINE" | cut -d'|' -f2)"
  BASE="$(printf '%s' "$LINE" | cut -d'|' -f3)"
  if [ -e "$ORIG" ]; then
    echo "A file or folder is already at the old place: $ORIG"
    echo "Move it first, then unlock again. Nothing was changed."
    exit 1
  fi
  TMPTAR="$(mktemp /tmp/shubham-unlock-XXXXXX.tar.gz)"
  if openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$PW" -in "$LOCKER/$STORED" -out "$TMPTAR" 2>/dev/null && [ -s "$TMPTAR" ]; then
    mkdir -p "$(dirname "$ORIG")"
    if tar -xzf "$TMPTAR" -C "$(dirname "$ORIG")" 2>/dev/null && [ -e "$ORIG" ]; then
      rm -f "$LOCKER/$STORED"
      sed -i "${N}d" "$INDEX"
      echo ""
      echo "Unlocked: $BASE"
      echo "It is back at: $ORIG"
    else
      echo "Unlocking failed. Your locked file is still safe in the locker."
      rm -f "$TMPTAR"
      exit 1
    fi
  else
    echo "Unlocking failed. Your locked file is still safe in the locker."
    rm -f "$TMPTAR"
    exit 1
  fi
  rm -f "$TMPTAR"

else
  echo "Please run it again and type 1 or 2."
  exit 1
fi
SHUBHAM_B2_21B
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-locker"

write_verified /usr/local/bin/shubham-record << 'SHUBHAM_B2_21C'
#!/bin/bash
# Shubham OS - Screen Record: record your whole screen as a video.
# Run it once to start. Run it again to stop. The video is saved in Videos.
PIDFILE="$HOME/.shubham-record.pid"
INFOFILE="$HOME/.shubham-record.info"

if [ -f "$PIDFILE" ]; then
  PID="$(cat "$PIDFILE" 2>/dev/null)"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    OUT="$(cat "$INFOFILE" 2>/dev/null)"
    kill -INT "$PID" 2>/dev/null
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      kill -0 "$PID" 2>/dev/null || break
      sleep 0.5
    done
    rm -f "$PIDFILE" "$INFOFILE"
    echo "Recording stopped."
    if [ -n "$OUT" ] && [ -f "$OUT" ]; then
      echo "Your video is saved: $OUT"
    fi
    exit 0
  fi
  rm -f "$PIDFILE" "$INFOFILE"
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is not found on this PC, so Screen Record cannot run."
  exit 1
fi

export DISPLAY="${DISPLAY:-:0}"

mkdir -p "$HOME/Videos"
OUT="$HOME/Videos/Shubham-Record-$(date +%Y%m%d-%H%M%S).mp4"

# No size is given on purpose: ffmpeg takes the full screen by itself,
# so this works on any screen, big or small.
nohup ffmpeg -y -f x11grab -framerate 30 -i "$DISPLAY" \
  -f pulse -i default -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac \
  "$OUT" >/dev/null 2>&1 &
PID=$!
sleep 1
if ! kill -0 "$PID" 2>/dev/null; then
  # No mic or sound device - record video only.
  nohup ffmpeg -y -f x11grab -framerate 30 -i "$DISPLAY" \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p \
    "$OUT" >/dev/null 2>&1 &
  PID=$!
  sleep 1
fi
if ! kill -0 "$PID" 2>/dev/null; then
  echo "Recording could not start. Is the screen on?"
  rm -f "$OUT"
  exit 1
fi

printf '%s' "$PID" > "$PIDFILE"
printf '%s' "$OUT" > "$INFOFILE"
echo "Recording started. Do your work on the PC."
echo "Run shubham-record again to stop."
echo "The video will be saved in your Videos folder."
SHUBHAM_B2_21C
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-record"

write_verified /usr/local/bin/shubham-guest << 'SHUBHAM_B2_21D'
#!/bin/bash
# Shubham OS - Guest Mode: give your PC to someone else, safely.
# The guest gets a clean, empty account. Your files stay hidden and safe.
# Nothing the guest does is saved - the account is made fresh every time.
GUEST="shubham-guest"

echo "Guest Mode - a clean, empty account for someone else."
echo ""
echo "What do you want to do?"
echo "  1) Start Guest Mode (make a fresh guest account)"
echo "  2) Remove the guest account fully"
read -r -p "Type 1 or 2: " CH

if [ "$CH" = "1" ]; then
  echo ""
  echo "Your PC password may be asked - it is for your safety."
  if id "$GUEST" >/dev/null 2>&1; then
    echo "An old guest account was found. It will be removed and made fresh,"
    echo "so nothing from the last guest stays."
    sudo userdel -r "$GUEST" 2>/dev/null
  fi
  if ! sudo useradd -m -s /bin/bash "$GUEST"; then
    echo "The guest account could not be made. Nothing was changed."
    exit 1
  fi
  echo "$GUEST:guest" | sudo chpasswd
  # Keep your own files private from the guest.
  PERM="$(stat -c %a "$HOME" 2>/dev/null)"
  case "$PERM" in
    *[!0]*[0-9]) ;;
    *) chmod 750 "$HOME" 2>/dev/null ;;
  esac
  echo ""
  echo "Guest Mode is ready."
  echo "  Guest name: $GUEST"
  echo "  Guest password: guest"
  echo ""
  echo "Now log out, and log in with the guest name."
  echo "Your files stay hidden and safe. When the guest logs out,"
  echo "log in with your own account - everything is as it was."
  echo ""
  read -r -p "Log out now? (y/n): " GO
  if [ "$GO" = "y" ] || [ "$GO" = "Y" ]; then
    xfce4-session-logout --logout 2>/dev/null || echo "Please log out from the menu."
  fi

elif [ "$CH" = "2" ]; then
  echo ""
  echo "Your PC password may be asked - it is for your safety."
  if id "$GUEST" >/dev/null 2>&1; then
    if sudo userdel -r "$GUEST" 2>/dev/null; then
      echo "The guest account and all its files are removed."
    else
      echo "It could not be removed. Is the guest logged in right now?"
      echo "Log the guest out first, then run this again."
      exit 1
    fi
  else
    echo "There is no guest account on this PC."
  fi

else
  echo "Please run it again and type 1 or 2."
  exit 1
fi
SHUBHAM_B2_21D
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-guest"

write_verified /usr/local/bin/shubham-clean << 'SHUBHAM_B2_21E'
#!/bin/bash
# Shubham OS - Speed Up PC: cleans the junk - old temp files, cache and useless logs.
# It shows how much junk it found, cleans it, then shows how much space was freed.

size_of() {
  if [ -e "$1" ]; then du -sb "$1" 2>/dev/null | awk '{print $1}'; else echo 0; fi
}
human() {
  numfmt --to=iec-i --suffix=B "$1" 2>/dev/null || echo "$1 bytes"
}

TARGETS=("$HOME/.cache" "$HOME/.local/share/Trash" "$HOME/.thumbnails")

echo "Speed Up PC - let us see the junk on this PC."
echo ""
TOTAL=0
for T in "${TARGETS[@]}"; do
  S="$(size_of "$T")"
  TOTAL=$((TOTAL + S))
  case "$T" in
    *".cache") NAME="App cache and temp files" ;;
    *"Trash") NAME="Trash (deleted files)" ;;
    *".thumbnails") NAME="Old photo thumbnails" ;;
    *) NAME="$T" ;;
  esac
  echo "  $NAME: $(human "$S")"
done
echo ""
echo "Total junk found: $(human "$TOTAL")"

if [ "$TOTAL" -eq 0 ]; then
  echo "Your PC is already clean. Nothing to do."
  exit 0
fi

read -r -p "Clean it now? (y/n): " GO
if [ "$GO" != "y" ] && [ "$GO" != "Y" ]; then
  echo "OK, nothing was cleaned."
  exit 0
fi

for T in "${TARGETS[@]}"; do
  if [ -d "$T" ]; then
    find "$T" -mindepth 1 -delete 2>/dev/null
  fi
done

AFTER=0
for T in "${TARGETS[@]}"; do
  AFTER=$((AFTER + $(size_of "$T")))
done
FREED=$((TOTAL - AFTER))
echo ""
echo "Done. Space freed: $(human "$FREED")"
echo "Your PC should feel lighter now."
SHUBHAM_B2_21E
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-clean"

write_verified /usr/local/bin/shubham-recover << 'SHUBHAM_B2_21F'
#!/bin/bash
# Shubham OS - File Recovery: bring back a file you deleted by mistake.
# Deleted files stay in a hidden backup (the Trash) for 7 days.
# Run it, pick the file from the list, and it goes back to its old place.
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python is not found on this PC, so File Recovery cannot run."
  exit 1
fi

TRASH="$HOME/.local/share/Trash"
FILES="$TRASH/files"
INFO="$TRASH/info"
mkdir -p "$FILES" "$INFO"

decode() {
  python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))" "$1"
}

# Clean backups older than 7 days.
CLEANED=0
for I in "$INFO"/*.trashinfo; do
  [ -f "$I" ] || continue
  DDATE="$(grep '^DeletionDate=' "$I" 2>/dev/null | head -1 | cut -d= -f2)"
  case "$DDATE" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*)
      if [ -n "$(find "$I" -newermt "$DDATE + 7 days" 2>/dev/null)" ] || \
         [ "$(date -d "$DDATE + 7 days" +%s 2>/dev/null || echo 0)" -lt "$(date +%s)" ]; then
        B="$(basename "$I" .trashinfo)"
        rm -f "$FILES/$B" "$I"
        CLEANED=$((CLEANED + 1))
      fi
      ;;
  esac
done
if [ "$CLEANED" -gt 0 ]; then
  echo "Old backups (more than 7 days) cleaned: $CLEANED"
  echo ""
fi

# Make the list.
NAMES=()
ORIGS=()
DATES=()
for I in "$INFO"/*.trashinfo; do
  [ -f "$I" ] || continue
  B="$(basename "$I" .trashinfo)"
  [ -e "$FILES/$B" ] || continue
  P="$(grep '^Path=' "$I" 2>/dev/null | head -1 | cut -d= -f2-)"
  D="$(grep '^DeletionDate=' "$I" 2>/dev/null | head -1 | cut -d= -f2)"
  ORIG="$(decode "$P")"
  NAMES+=("$B")
  ORIGS+=("$ORIG")
  DATES+=("$D")
done

if [ "${#NAMES[@]}" -eq 0 ]; then
  echo "No deleted files found right now."
  echo "Files deleted in the file manager come here and stay for 7 days."
  echo "Files deleted with rm in the terminal cannot come back."
  exit 0
fi

echo "Your deleted files:"
i=1
for K in "${!NAMES[@]}"; do
  echo "  $i) $(basename "${ORIGS[$K]}")"
  echo "     was at: ${ORIGS[$K]}"
  echo "     deleted: ${DATES[$K]}"
  i=$((i+1))
done
echo ""
read -r -p "Type the number of the file you want back: " N
case "$N" in
  ''|*[!0-9]*) echo "That is not a number. Run it again."; exit 1 ;;
esac
if [ "$N" -lt 1 ] || [ "$N" -gt "${#NAMES[@]}" ]; then
  echo "That number is not in the list. Run it again."
  exit 1
fi

B="${NAMES[$((N-1))]}"
ORIG="${ORIGS[$((N-1))]}"
if [ -e "$ORIG" ]; then
  echo "A file is already at the old place: $ORIG"
  echo "Move it first, then run this again. Nothing was changed."
  exit 1
fi
mkdir -p "$(dirname "$ORIG")"
if mv "$FILES/$B" "$ORIG"; then
  rm -f "$INFO/$B.trashinfo"
  echo ""
  echo "Your file is back: $ORIG"
else
  echo "The file could not be put back. It is still safe in the list."
  exit 1
fi
SHUBHAM_B2_21F
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-recover"
write_verified /usr/local/bin/shubham-doctor << 'SHUBHAM_B3_21G'
#!/bin/bash
# Shubham OS - PC Doctor: one click checks the whole PC and fixes what it can.
# Checks: disk space, disk health, virus, broken packages and services,
# slow start, and junk. At the end it prints a simple report.

PROBLEMS=0
FIXED=0
declare -a REPORT

ok()   { REPORT+=("  OK   $1"); }
warn() { REPORT+=("  !!   $1"); PROBLEMS=$((PROBLEMS + 1)); }
note() { REPORT+=("  --   $1"); }

human() { numfmt --to=iec-i --suffix=B "$1" 2>/dev/null || echo "$1 bytes"; }
size_of() { if [ -e "$1" ]; then du -sb "$1" 2>/dev/null | awk '{print $1}'; else echo 0; fi; }

echo "PC Doctor - checking your whole PC, one by one."
echo ""

# --- 1. Disk space ---------------------------------------------------------
echo "1. Disk space..."
DISK_LINE=$(df -P / 2>/dev/null | tail -1)
DISK_PCT=$(echo "$DISK_LINE" | awk '{print $5}' | tr -d '%')
if [ -n "$DISK_PCT" ]; then
  if [ "$DISK_PCT" -ge 90 ]; then
    warn "Disk is almost full ($DISK_PCT% used). Delete big files you do not need."
  else
    ok "Disk space is fine ($DISK_PCT% used)."
  fi
else
  note "Disk space could not be read."
fi

# --- 2. Disk health --------------------------------------------------------
echo "2. Disk health..."
if command -v smartctl >/dev/null 2>&1; then
  HEALTH_DONE=0
  for DEV in /dev/sda /dev/nvme0n1; do
    if [ -b "$DEV" ]; then
      H=$(sudo smartctl -H "$DEV" 2>/dev/null | grep -i "overall-health" | awk -F: '{print $2}' | tr -d ' ')
      if [ -n "$H" ]; then
        HEALTH_DONE=1
        if [ "$H" = "PASSED" ]; then ok "Disk $DEV health: PASSED."; else warn "Disk $DEV health: $H - save your files now."; fi
      fi
    fi
  done
  [ "$HEALTH_DONE" -eq 0 ] && note "Disk health could not be read on this PC."
else
  note "Disk health tool (smartmontools) is not installed - this check is skipped."
fi

# --- 3. Virus check --------------------------------------------------------
echo "3. Virus check..."
if command -v clamscan >/dev/null 2>&1; then
  if ! ls /var/lib/clamav/*.cvd /var/lib/clamav/*.cld >/dev/null 2>&1; then
    echo "   First time: downloading the virus list. This can take some minutes..."
    sudo freshclam >/dev/null 2>&1 || freshclam >/dev/null 2>&1
  fi
  SCAN_DIRS=""
  for D in "$HOME/Downloads" "$HOME/Desktop" "$HOME/Documents"; do
    [ -d "$D" ] && SCAN_DIRS="$SCAN_DIRS $D"
  done
  if [ -n "$SCAN_DIRS" ] && ls /var/lib/clamav/*.cvd /var/lib/clamav/*.cld >/dev/null 2>&1; then
    echo "   Scanning Downloads, Desktop and Documents..."
    SCAN_OUT=$(clamscan -r -i --max-filesize=100M $SCAN_DIRS 2>/dev/null)
    INFECTED=$(echo "$SCAN_OUT" | grep "Infected files:" | awk '{print $3}')
    if [ -z "$INFECTED" ]; then
      note "Virus scan could not finish."
    elif [ "$INFECTED" = "0" ]; then
      ok "Virus check: no virus found."
    else
      warn "Virus check: $INFECTED bad file(s) found. Do not open them."
      echo "$SCAN_OUT" | grep -i "FOUND" | head -5 | sed 's/^/   /'
    fi
  else
    note "Virus list is not ready - virus check is skipped this time."
  fi
else
  note "Virus scanner (ClamAV) is not installed - virus check is skipped."
fi

# --- 4. Broken packages and services ---------------------------------------
echo "4. Broken packages and services..."
AUDIT=$(dpkg --audit 2>/dev/null)
if [ -n "$AUDIT" ]; then
  warn "Some packages are half-fixed or broken."
  echo "   Fixing them now (your password may be asked)..."
  if sudo dpkg --configure -a >/dev/null 2>&1 && sudo apt-get install -f -y >/dev/null 2>&1; then
    if [ -z "$(dpkg --audit 2>/dev/null)" ]; then
      FIXED=$((FIXED + 1))
      REPORT+=("  FIXED Broken packages are repaired.")
    else
      warn "Some packages are still broken after the fix. Tell the developer."
    fi
  else
    warn "The package fix could not run. Check your internet and try again."
  fi
else
  ok "No broken packages."
fi
if command -v systemctl >/dev/null 2>&1; then
  FAILED_SVC=$(systemctl --failed --no-legend 2>/dev/null | grep -c .)
  if [ "${FAILED_SVC:-0}" -gt 0 ]; then
    warn "$FAILED_SVC system service(s) have failed. The PC still works, but tell the developer."
    systemctl --failed --no-legend 2>/dev/null | head -3 | sed 's/^/   /'
  else
    ok "All system services are running."
  fi
fi

# --- 5. Slow start ---------------------------------------------------------
echo "5. Start speed..."
if command -v systemd-analyze >/dev/null 2>&1; then
  BOOT=$(systemd-analyze 2>/dev/null | head -1)
  if [ -n "$BOOT" ]; then
    ok "Start report: $BOOT"
    echo "   The slowest parts at start:"
    systemd-analyze blame 2>/dev/null | head -5 | sed 's/^/   /'
  else
    note "Start speed could not be read."
  fi
else
  note "Start speed tool is not on this PC - this check is skipped."
fi

# --- 6. Junk (report only) ---------------------------------------------------
echo "6. Junk on the PC..."
TOTAL=0
for T in "$HOME/.cache" "$HOME/.local/share/Trash" "$HOME/.thumbnails"; do
  TOTAL=$((TOTAL + $(size_of "$T")))
done
if [ "$TOTAL" -gt 104857600 ]; then
  warn "Junk found: $(human "$TOTAL"). Run shubham-clean to remove it."
else
  ok "Junk is small ($(human "$TOTAL"))."
fi

# --- Report ------------------------------------------------------------------
echo ""
echo "================ PC Doctor Report ================"
for L in "${REPORT[@]}"; do echo "$L"; done
echo ""
echo "Problems found: $PROBLEMS"
echo "Fixed by Doctor: $FIXED"
if [ "$PROBLEMS" -eq 0 ]; then
  echo "Your PC is healthy. Nothing to worry about."
else
  echo "Read the !! lines above - they tell you what still needs care."
fi
SHUBHAM_B3_21G
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-doctor"

write_verified /usr/local/bin/shubham-live << 'SHUBHAM_B3_21H'
#!/bin/bash
# Shubham OS - Live Screen: show your screen live to another person.
# They can only watch. They cannot click or change anything.
# Run it once to start. Run it again to stop.
PIDFILE="$HOME/.shubham-live.pid"
PASSFILE="$HOME/.shubham-live.pass"

stop_live() {
  if [ -f "$PIDFILE" ]; then
    while read -r P; do
      [ -n "$P" ] && kill "$P" 2>/dev/null
    done < "$PIDFILE"
    rm -f "$PIDFILE"
  fi
  rm -f "$PASSFILE"
  echo "Live Screen is stopped. Nobody can see your screen now."
}

if [ -f "$PIDFILE" ]; then
  FIRST_PID="$(head -1 "$PIDFILE" 2>/dev/null)"
  if [ -n "$FIRST_PID" ] && kill -0 "$FIRST_PID" 2>/dev/null; then
    stop_live
    exit 0
  fi
  rm -f "$PIDFILE" "$PASSFILE"
fi

if ! command -v x11vnc >/dev/null 2>&1; then
  echo "x11vnc is not found on this PC, so Live Screen cannot run."
  exit 1
fi
if ! command -v websockify >/dev/null 2>&1 || [ ! -f /usr/share/novnc/vnc.html ]; then
  echo "The browser viewer (novnc) is not found on this PC, so Live Screen cannot run."
  exit 1
fi

echo "WARNING - read this first."
echo "Anyone who has your link and code can WATCH your screen, live."
echo "They can only watch. They cannot click or change anything."
echo "Give the link and code only to a person you trust."
echo ""
read -r -p "Start Live Screen? (y/n): " GO
if [ "$GO" != "y" ] && [ "$GO" != "Y" ]; then
  echo "OK, nothing was started."
  exit 0
fi

export DISPLAY="${DISPLAY:-:0}"
CODE=$(printf '%08d' $(( (RANDOM << 15 | RANDOM) % 90000000 + 10000000 )))

x11vnc -storepasswd "$CODE" "$PASSFILE" >/dev/null 2>&1
nohup x11vnc -display "$DISPLAY" -viewonly -shared -forever \
  -rfbport 5900 -rfbauth "$PASSFILE" >/dev/null 2>&1 &
VNC_PID=$!
sleep 1
nohup websockify --web /usr/share/novnc 6080 localhost:5900 >/dev/null 2>&1 &
WEB_PID=$!
sleep 1

if ! kill -0 "$VNC_PID" 2>/dev/null || ! kill -0 "$WEB_PID" 2>/dev/null; then
  kill "$VNC_PID" "$WEB_PID" 2>/dev/null
  rm -f "$PASSFILE"
  echo "Live Screen could not start. Is the screen on?"
  exit 1
fi

printf '%s\n%s\n' "$VNC_PID" "$WEB_PID" > "$PIDFILE"

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP" ] && IP="this-PC"
echo ""
echo "Live Screen is ON."
echo ""
echo "  Link:  http://$IP:6080/vnc.html"
echo "  Code:  $CODE"
echo ""
echo "Send the link and code to the person. They open the link in any"
echo "browser, type the code, and they can watch your screen."
echo "This link works for people on your own network (same WiFi)."
echo "Run shubham-live again to stop at once."
SHUBHAM_B3_21H
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-live"

write_verified /usr/local/bin/shubham-ghost << 'SHUBHAM_B3_21I'
#!/bin/bash
# Shubham OS - Ghost Mode: one click gives your PC a new identity and
# sends your net traffic the hidden way (Tor). Run it again and
# everything comes back: old name, old MAC, direct net.
STATEDIR="$HOME/.shubham-ghost"
STATE="$STATEDIR/state"

rand_mac() {
  printf '%02x:%02x:%02x:%02x:%02x:%02x' \
    $(( (RANDOM % 64) * 4 + 2 )) $((RANDOM % 256)) $((RANDOM % 256)) \
    $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256))
}
rand_name() {
  local chars="ABCDEFGHJKLMNPQRSTUVWXYZ23456789" out=""
  for _ in 1 2 3 4 5 6; do out="$out${chars:$((RANDOM % 32)):1}"; done
  echo "DESKTOP-$out"
}

tor_rules_off() {
  for _ in 1 2 3 4 5; do
    sudo iptables -t nat -D OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null || break
  done
  for _ in 1 2 3 4 5; do
    sudo iptables -t nat -D OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040 2>/dev/null || break
  done
  for PREFIX in "127.0.0.0/8" "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"; do
    sudo iptables -t nat -D OUTPUT -d "$PREFIX" -j RETURN 2>/dev/null
  done
  sudo iptables -t nat -D OUTPUT -m owner --uid-owner debian-tor -j RETURN 2>/dev/null
}

# ------------------------------- OFF -------------------------------------
if [ -f "$STATE" ]; then
  # shellcheck disable=SC1090
  . "$STATE"
  echo "Turning Ghost Mode OFF..."
  tor_rules_off
  if [ -n "$GHOST_IF" ] && [ -n "$GHOST_MAC" ]; then
    sudo ip link set dev "$GHOST_IF" down 2>/dev/null
    sudo ip link set dev "$GHOST_IF" address "$GHOST_MAC" 2>/dev/null
    sudo ip link set dev "$GHOST_IF" up 2>/dev/null
  fi
  if [ -n "$GHOST_HOST" ]; then
    sudo hostname "$GHOST_HOST" 2>/dev/null
    echo "$GHOST_HOST" | sudo tee /etc/hostname >/dev/null 2>&1
    sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$GHOST_HOST/" /etc/hosts 2>/dev/null
  fi
  sudo service tor stop >/dev/null 2>&1 || sudo systemctl stop tor >/dev/null 2>&1
  rm -rf "$STATEDIR"
  echo "Ghost Mode is OFF."
  echo "Your old PC name, old MAC and direct net are back."
  exit 0
fi

# ------------------------------- ON --------------------------------------
if ! command -v tor >/dev/null 2>&1; then
  echo "Tor is not found on this PC, so Ghost Mode cannot run."
  exit 1
fi

IF=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
if [ -z "$IF" ]; then
  echo "No internet connection found. Connect to the internet first."
  exit 1
fi
OLD_MAC=$(cat "/sys/class/net/$IF/address" 2>/dev/null)
OLD_HOST=$(hostname)

echo "Turning Ghost Mode ON..."
echo "(Your password may be asked - Ghost Mode needs it to change"
echo " the PC name, the MAC and the net route.)"
sudo -v || { echo "Ghost Mode stopped. Nothing was changed."; exit 1; }

mkdir -p "$STATEDIR"
printf 'GHOST_IF=%s\nGHOST_MAC=%s\nGHOST_HOST=%s\n' "$IF" "$OLD_MAC" "$OLD_HOST" > "$STATE"

# Tor must be ready first - if Tor fails, nothing else is changed.
if ! grep -q "^TransPort 9040" /etc/tor/torrc 2>/dev/null; then
  printf 'TransPort 9040\nDNSPort 5353\nAutomakeHostsOnResolve 1\n' | sudo tee -a /etc/tor/torrc >/dev/null 2>&1
fi
sudo service tor start >/dev/null 2>&1 || sudo systemctl start tor >/dev/null 2>&1
TOR_OK=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if ss -ltn 2>/dev/null | grep -q ":9050"; then TOR_OK=1; break; fi
  sleep 1
done
if [ "$TOR_OK" -ne 1 ]; then
  echo "Tor could not start, so Ghost Mode is NOT on."
  echo "Your name and MAC were not changed."
  rm -rf "$STATEDIR"
  exit 1
fi

# Send the traffic the hidden way. Tor's own traffic and your home
# network stay direct, everything else goes through Tor.
sudo iptables -t nat -I OUTPUT 1 -m owner --uid-owner debian-tor -j RETURN 2>/dev/null
sudo iptables -t nat -I OUTPUT 1 -d 192.168.0.0/16 -j RETURN 2>/dev/null
sudo iptables -t nat -I OUTPUT 1 -d 172.16.0.0/12 -j RETURN 2>/dev/null
sudo iptables -t nat -I OUTPUT 1 -d 10.0.0.0/8 -j RETURN 2>/dev/null
sudo iptables -t nat -I OUTPUT 1 -d 127.0.0.0/8 -j RETURN 2>/dev/null
sudo iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
sudo iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040 2>/dev/null

# New identity: new MAC and new PC name.
NEW_MAC=$(rand_mac)
NEW_HOST=$(rand_name)
sudo ip link set dev "$IF" down 2>/dev/null
sudo ip link set dev "$IF" address "$NEW_MAC" 2>/dev/null
sudo ip link set dev "$IF" up 2>/dev/null
sudo hostname "$NEW_HOST" 2>/dev/null
echo "$NEW_HOST" | sudo tee /etc/hostname >/dev/null 2>&1
if grep -q "^127\.0\.1\.1" /etc/hosts 2>/dev/null; then
  sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NEW_HOST/" /etc/hosts 2>/dev/null
else
  echo "127.0.1.1	$NEW_HOST" | sudo tee -a /etc/hosts >/dev/null 2>&1
fi
sleep 2

echo ""
echo "Ghost Mode is ON."
echo "  PC name (new):  $NEW_HOST"
echo "  MAC (new):      $NEW_MAC"
CHECK=$(curl -s --max-time 25 https://check.torproject.org/api/ip 2>/dev/null)
if echo "$CHECK" | grep -q '"IsTor":true'; then
  NEW_IP=$(echo "$CHECK" | sed -n 's/.*"IP":"\([^"]*\)".*/\1/p')
  echo "  Hidden route:   working. The world sees this IP: $NEW_IP"
else
  echo "  Hidden route:   ON, but the check site could not confirm it."
  echo "                  Wait a few seconds and open any site."
fi
echo ""
echo "Know these three things:"
echo "  - The net is a little slow in Ghost Mode. This is normal."
echo "  - Your internet company can see that you are online."
echo "    It cannot see what you are doing."
echo "  - Some sites, like bank sites, may block the hidden route."
echo ""
echo "Run shubham-ghost again to turn it OFF and get everything back."
SHUBHAM_B3_21I
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-ghost"

# --- Final check: every file must match its SHA-256 hash exactly ---------
echo "Final check - matching every command by its hash..."
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
check_one phone   e0c72618daae9f263ba7dd2d3ef91860f1e0beb2ba8f5fd8834f0a87bb9f1cf0
check_one locker  d992e362c4bd5ef07f257e97fee4f942aa0dd9c3f3f96c17aa038009633d18f9
check_one record  c6f3ab647fed6a21222994b4f45965d1b99df16d8b67793e0c19a397caf02e2f
check_one guest   fcf5283499d3d8423052f79bbcf8b44429453dbd3dc2322c12358a1d4f633448
check_one clean   1c972c08653a2fb2b4f7da6f06cf4d35d9d464e9b42b8143388a15c2850db6b5
check_one recover 22fa20b92ee84bb72541ee47293f6867f0dc92058111f6ebb5309d667101e321
check_one doctor  3a33621834976ed4a584cc564ea06124b5571cd63ee4a619038a871d994aeff9
check_one live    d90662d1124d0a25d4d9a6b17c3fe91b027ea114408e2861581da881f8355b1d
check_one ghost   da0a06990e738b04a7c22bc6b859f2a7af52f914dc624ee4cf2ae9fb2de787df

# --- Run proof: shubham-clean must actually speak -------------------------
echo ""
echo "Run proof - starting shubham-clean once (answer is n, nothing is cleaned):"
CLEAN_OUT=$(printf 'n\n' | /usr/local/bin/shubham-clean 2>&1 | head -3)
if [ -z "$CLEAN_OUT" ]; then
  echo "  PROBLEM  shubham-clean gave no output."
  fail_out
fi
echo "$CLEAN_OUT" | sed 's/^/  /'
echo "  OK  shubham-clean runs and prints."

# --- The tools these commands need -----------------------------------------
echo ""
echo "Now installing the tools these commands need:"
echo "  ffmpeg (for Record), Tor (for Ghost), x11vnc + novnc (for Live),"
echo "  ClamAV (for the Doctor virus check). This can take some minutes..."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg tor x11vnc websockify novnc clamav clamav-freshclam

echo ""
echo "Checking the tools..."
MISSING=""
need_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "  OK  $1 is here"
  else
    echo "  PROBLEM  $1 is missing"
    MISSING="$MISSING $1"
  fi
}
need_cmd ffmpeg
need_cmd tor
need_cmd x11vnc
need_cmd websockify
need_cmd clamscan
if [ -f /usr/share/novnc/vnc.html ]; then
  echo "  OK  novnc is here"
else
  echo "  PROBLEM  novnc is missing"
  MISSING="$MISSING novnc"
fi

if [ -n "$MISSING" ]; then
  echo ""
  echo "Update 21 is NOT fully ready. Missing tools:$MISSING"
  echo "The nine commands are installed, but some cannot work yet."
  echo "Connect to good internet and run this update again."
  echo "Your version was NOT changed, so the updater will offer Update 21 again."
  exit 1
fi

echo 21 > /etc/shubham-os-version
echo ""
echo "Shubham OS Update 21 done! Batch 3 is in, and Record is fixed."
echo "First time shubham-doctor runs, it downloads the virus list -"
echo "that can take some minutes. After that it is fast."
echo "Type shubham-help to see all commands."
exit 0
# SHUBHAM21_END_OF_FILE
