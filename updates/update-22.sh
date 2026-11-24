# Shubham OS Update 22 - Link and Ghost fix.
#
# What was wrong and what this update does:
#   1. shubham-live and shubham-phone gave a link that only worked
#      inside the PC's own network. On a PC whose system runs inside
#      VMware, the phone cannot reach that link at all. Both commands
#      now make a real internet link with a free Cloudflare tunnel -
#      the link opens from ANY network. This update installs the
#      tunnel tool (cloudflared) from Cloudflare's official release.
#   2. shubham-ghost could not turn on: the old Ghost had written one
#      wrong line into Tor's settings file, and Tor refused to start.
#      This update removes that line, and the new Ghost writes only
#      correct lines and lets Tor check its own file first.
#   The phone code is now 8 numbers, because the link is on the
#   internet.
#
# Safety, the same as Updates 19 to 21:
#   0. This script first checks its own file is complete (an end marker
#      must be present). An incomplete copy changes NOTHING and stops.
#   1. Every command file is written to a temporary name, checked (not
#      empty, correct shell syntax), and only then moved into place.
#   2. The three fixed commands are checked by SHA-256 hash at the end.
#   3. If anything fails, the version is NOT written and the update
#      reports FAILED.
# Nothing else on the system is touched. The panel is not touched.
# Runs as root via pkexec.

# --- Step 0: refuse an incomplete copy of this update ---------------------
if [ -f "$0" ]; then
  GATE_COUNT=$(grep -c "SHUBHAM22_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 22 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 22 (Link and Ghost fix) is being applied..."

# write_verified DEST -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1"
  local tmp="${dest}.tmp-shubham22"
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
  echo "Shubham OS Update 22 FAILED its check. Your old version is kept."
  echo "Please tell the developer what the updater showed."
  exit 1
}

mkdir -p /usr/local/bin
echo "Step 1: healing Tor's settings file..."
if [ -f /etc/tor/torrc ] && grep -q "^AutomakeHostsOnResolve 1" /etc/tor/torrc 2>/dev/null; then
  sed -i "/^AutomakeHostsOnResolve 1$/d" /etc/tor/torrc 2>/dev/null
  echo "  OK  a wrong line left by the old Ghost was removed from Tor's file"
else
  echo "  OK  Tor's settings file is clean"
fi

echo ""
echo "Step 2: the internet-link tool (cloudflared)..."
if [ -x /usr/local/bin/cloudflared ]; then
  echo "  OK  cloudflared is already here"
else
  echo "  Downloading cloudflared from Cloudflare's official site..."
  if curl -fsSL -o /usr/local/bin/cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" 2>/dev/null; then
    chmod 755 /usr/local/bin/cloudflared 2>/dev/null
  fi
fi
CF_SIZE=0
[ -f /usr/local/bin/cloudflared ] && CF_SIZE=$(wc -c < /usr/local/bin/cloudflared)
if [ ! -x /usr/local/bin/cloudflared ] || [ "$CF_SIZE" -lt 20000000 ] || ! /usr/local/bin/cloudflared --version >/dev/null 2>&1; then
  echo "  PROBLEM  cloudflared could not be installed. Check the internet."
  fail_out
fi
echo "  OK  cloudflared is ready"

echo ""
echo "Step 3: installing the fixed commands..."
write_verified /usr/local/bin/shubham-live << 'SHUBHAM_FIX_22A'
#!/bin/bash
# Shubham OS - Live Screen: show your screen live to any person, on any
# network. A free Cloudflare tunnel gives a public internet link.
# They can only watch. They cannot click or change anything.
# Run it once to start. Run it again to stop.
PIDFILE="$HOME/.shubham-live.pid"
PASSFILE="$HOME/.shubham-live.pass"
TUNLOG="$HOME/.shubham-live.log"

stop_live() {
  if [ -f "$PIDFILE" ]; then
    while read -r P; do
      [ -n "$P" ] && kill "$P" 2>/dev/null
    done < "$PIDFILE"
    rm -f "$PIDFILE"
  fi
  rm -f "$PASSFILE" "$TUNLOG"
  echo "Live Screen is stopped. Nobody can see your screen now."
  echo "The internet link is dead too."
}

if [ -f "$PIDFILE" ]; then
  FIRST_PID="$(head -1 "$PIDFILE" 2>/dev/null)"
  if [ -n "$FIRST_PID" ] && kill -0 "$FIRST_PID" 2>/dev/null; then
    stop_live
    exit 0
  fi
  rm -f "$PIDFILE" "$PASSFILE" "$TUNLOG"
fi

if ! command -v x11vnc >/dev/null 2>&1; then
  echo "x11vnc is not found on this PC, so Live Screen cannot run."
  exit 1
fi
if ! command -v websockify >/dev/null 2>&1 || [ ! -f /usr/share/novnc/vnc.html ]; then
  echo "The browser viewer (novnc) is not found on this PC, so Live Screen cannot run."
  exit 1
fi
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is not found on this PC, so Live Screen cannot make"
  echo "an internet link. Run the Shubham OS update once more."
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

echo "Making your internet link (some seconds)..."
rm -f "$TUNLOG"
nohup cloudflared tunnel --url http://localhost:6080 --no-autoupdate \
  > "$TUNLOG" 2>&1 &
TUN_PID=$!
TUNNEL=""
for _ in $(seq 1 30); do
  TUNNEL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$TUNLOG" 2>/dev/null | grep -v '^https://api\.' | head -1)
  [ -n "$TUNNEL" ] && break
  kill -0 "$TUN_PID" 2>/dev/null || break
  sleep 1
done

printf '%s\n%s\n%s\n' "$VNC_PID" "$WEB_PID" "$TUN_PID" > "$PIDFILE"

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP" ] && IP="this-PC"
echo ""
echo "Live Screen is ON."
echo ""
if [ -n "$TUNNEL" ]; then
  echo "  Internet link:  $TUNNEL/vnc.html"
else
  echo "  Internet link:  NOT made - the tunnel could not start."
  echo "                  Check the internet and run shubham-live again."
fi
echo "  Code:           $CODE"
echo ""
if [ -n "$TUNNEL" ]; then
  echo "Send the internet link and code to the person. It opens from any"
  echo "network - any WiFi, any mobile data, anywhere. They type the code"
  echo "and can watch your screen. Only watch - no clicking, no changing."
  echo "The link works only while Live Screen is ON. When you stop, the"
  echo "link dies at once."
else
  echo "Only the same-WiFi link below is working right now."
fi
echo ""
echo "  Local link:     http://$IP:6080/vnc.html (only inside this PC's own network)"
echo ""
echo "Run shubham-live again to stop at once."
SHUBHAM_FIX_22A
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-live"

write_verified /usr/local/bin/shubham-ghost << 'SHUBHAM_FIX_22B'
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
# First remove any lines an older Ghost added (one of them was wrong and
# stopped Tor from starting at all), then add the correct lines and let
# Tor itself check the file before anything is started.
for L in "TransPort 9040" "DNSPort 5353" "SocksPort 9050" "AutomakeHostsOnResolve 1"; do
  sudo sed -i "/^${L}$/d" /etc/tor/torrc 2>/dev/null
done
printf 'SocksPort 9050\nTransPort 9040\nDNSPort 5353\n' | sudo tee -a /etc/tor/torrc >/dev/null 2>&1
if ! sudo tor --verify-config >/dev/null 2>&1; then
  for L in "TransPort 9040" "DNSPort 5353" "SocksPort 9050"; do
    sudo sed -i "/^${L}$/d" /etc/tor/torrc 2>/dev/null
  done
  echo "Tor's settings file has a problem, so Ghost Mode is NOT on."
  echo "Your name and MAC were not changed."
  rm -rf "$STATEDIR"
  exit 1
fi
sudo service tor start >/dev/null 2>&1 || sudo systemctl start tor >/dev/null 2>&1
TOR_OK=0
for _ in $(seq 1 20); do
  if ss -ltn 2>/dev/null | grep -q ":9040"; then TOR_OK=1; break; fi
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
SHUBHAM_FIX_22B
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-ghost"

write_verified /usr/local/bin/shubham-phone << 'SHUBHAM_FIX_22C'
#!/bin/bash
# Shubham OS - Phone Connect: connect your phone with your PC, no cable needed.
# Run it, open the address on your phone, type the code, then send files both ways.
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python is not found on this PC, so Phone Connect cannot run."
  exit 1
fi
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is not found on this PC, so Phone Connect cannot make"
  echo "an internet link. Run the Shubham OS update once more."
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
CODE=$(printf '%08d' $(( (RANDOM << 15 | RANDOM) % 90000000 + 10000000 )))

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

echo "Making your internet link (some seconds)..."
TUNLOG="$HOME/.shubham-phone.log"
rm -f "$TUNLOG"
nohup cloudflared tunnel --url "http://localhost:$PORT" --no-autoupdate \
  > "$TUNLOG" 2>&1 &
TUN_PID=$!
TUNNEL=""
for _ in $(seq 1 30); do
  TUNNEL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$TUNLOG" 2>/dev/null | grep -v '^https://api\.' | head -1)
  [ -n "$TUNNEL" ] && break
  kill -0 "$TUN_PID" 2>/dev/null || break
  sleep 1
done

echo "Phone Connect is ON."
echo ""
if [ -n "$TUNNEL" ]; then
  echo "On your phone, open this internet link (any network works):"
  echo "  $TUNNEL"
  echo ""
  echo "Local link (only inside this PC's own network):"
  echo "  http://$IP:$PORT"
else
  echo "The internet link could NOT be made. Check the internet and"
  echo "run shubham-phone again."
  echo ""
  echo "Local link (only inside this PC's own network):"
  echo "  http://$IP:$PORT"
fi
echo ""
echo "Code: $CODE"
echo ""
echo "Files in this folder can be downloaded on the phone: $SHARE"
echo "Files sent from the phone also land in that folder."
echo "The links work only while Phone Connect is ON."
echo "Press Ctrl+C to stop."
echo ""
SHUBHAM_SHARE="$SHARE" SHUBHAM_CODE="$CODE" python3 "$SERVER" "$PORT"
kill "$TUN_PID" 2>/dev/null
rm -f "$SERVER" "$TUNLOG"
SHUBHAM_FIX_22C
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-phone"

# --- Final check: every fixed command must match its SHA-256 hash ---------
echo "Final check - matching every fixed command by its hash..."
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
check_one live  13df6f6e095021f90d923cbb1af2898128b7a3d50e5f7c100d50310bbe7e9cc8
check_one ghost 216eb05febe05623c3d4d90d1376b3b9540406d318ab7e915771a4c35aaf14a6
check_one phone 717d566715b6f7167bdd9ebb2db09a5f4761b70dfc2842efcfcedf3afd7f15c7

echo 22 > /etc/shubham-os-version
echo ""
echo "Shubham OS Update 22 done!"
echo "  - shubham-live and shubham-phone now make an internet link"
echo "    that opens from ANY network."
echo "  - shubham-ghost is fixed - Tor starts properly now."
echo "Type shubham-help to see all commands."
exit 0
# SHUBHAM22_END_OF_FILE
