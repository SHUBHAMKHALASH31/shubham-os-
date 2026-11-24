# Shubham OS Update 24 - Practice Lab rebuilt (free lab, no levels).
#
# Why: the first Practice Lab worked like a quiz - it asked questions
# and waited for typed answers. That is not how a real lab works, and
# the user said so plainly. This update replaces shubham-lab with a
# free practice lab:
#   - shubham-lab starts fake web sites on this PC only (127.0.0.1):
#     a fake bank, a fake shop, a fake social site and a fake company
#     site, plus a Lab Home page that lists them.
#   - Chrome opens on the Lab Home page and a new terminal opens in
#     the lab folder.
#   - No levels, no questions. Real Kali tools (nmap, gobuster, nikto,
#     sqlmap, Burp) can be practised on the fake sites freely.
#   - Stop Lab and Reset Lab are in the same small menu.
# Only shubham-lab changes. The other 16 features are not touched.
#
# Safety, the same as Updates 19 to 23:
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
  GATE_COUNT=$(grep -c "SHUBHAM24_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 24 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 24 (Practice Lab rebuilt) is being applied..."

# write_verified DEST -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1"
  local tmp="${dest}.tmp-shubham24"
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
  echo "Shubham OS Update 24 FAILED its check. Your old version is kept."
  echo "Please tell the developer what the updater showed."
  exit 1
}

mkdir -p /usr/local/bin
echo "Step 1: installing the new Practice Lab..."
write_verified /usr/local/bin/shubham-lab << 'SHUBHAM_LAB_24A'
#!/bin/bash
# Shubham OS - Practice Lab: a free practice lab on this PC only.
# Fake practice web sites open in the browser. No levels, no questions.
# Use real Kali tools on them - everything is fake and stays on this PC.
LABDIR="$HOME/ShubhamLab"
STATEDIR="$HOME/.shubham-lab"
SERVER="$LABDIR/lab-server.py"
DB="$LABDIR/lab.db"
PIDFILE="$STATEDIR/server.pid"
LOGFILE="$STATEDIR/server.log"
HOME_URL="http://127.0.0.1:8080/"

write_server() {
  cat > "$SERVER" << 'PYEOF'
#!/usr/bin/env python3
# Shubham OS Practice Lab server - fake practice sites, this PC only.
# Everything here is fake. The bank query is weak ON PURPOSE: this is a
# practice target, like the training sites used in security courses.
import os, sys, sqlite3, html
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "lab.db")
PORT = 8080

CSS = """<style>
body{font-family:sans-serif;background:#10141d;color:#e9edf5;margin:0}
.bar{background:#1c2740;color:#ffd75e;padding:8px 14px;font-size:13px}
.wrap{max-width:760px;margin:0 auto;padding:22px 16px}
a{color:#7db4ff}
.card{background:#1a2130;border:1px solid #2c3850;border-radius:10px;padding:14px 16px;margin:12px 0}
input,button{padding:9px;margin:5px 0;border-radius:6px;border:1px solid #445}
button{background:#2f6fed;color:#fff;cursor:pointer}
.err{background:#4a1f24;border:1px solid #8a3038;padding:10px;border-radius:8px}
.ok{background:#1e4030;border:1px solid #2f7a4d;padding:10px;border-radius:8px}
small{color:#9aa7bd}
</style>"""

PRODUCTS = {
    1: ("Wireless Headphones", "Rs 1,499", "Fake headphones. Soft sound, long battery, only for practice."),
    2: ("Gaming Mouse", "Rs 899", "Fake gaming mouse. Fast clicks, only for practice."),
    3: ("Mechanical Keyboard", "Rs 2,499", "Fake keyboard. Loud keys, only for practice."),
    4: ("USB Pen Drive 64GB", "Rs 549", "Fake pen drive. Only for practice."),
}

def seed():
    con = sqlite3.connect(DB)
    cur = con.cursor()
    cur.execute("DROP TABLE IF EXISTS users")
    cur.execute("CREATE TABLE users (username TEXT, password TEXT, name TEXT, balance INTEGER)")
    cur.executemany("INSERT INTO users VALUES (?,?,?,?)", [
        ("admin", "admin123", "Admin", 50000),
        ("guest", "guest123", "Guest User", 1500),
        ("rahul", "rahul123", "Rahul", 2750),
    ])
    con.commit()
    con.close()
    print("Lab database ready:", DB)

def page(title, body):
    return ("<!doctype html><html><head><meta charset='utf-8'>"
            "<meta name='viewport' content='width=device-width, initial-scale=1'>"
            "<title>" + title + "</title>" + CSS + "</head><body>"
            "<div class='bar'>Shubham Lab - fake practice site, only on this PC</div>"
            "<div class='wrap'>" + body + "</div></body></html>")

class H(BaseHTTPRequestHandler):
    def send_html(self, body, code=200, ctype="text/html; charset=utf-8"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        u = urlparse(self.path)
        path = u.path
        if len(path) > 1 and path.endswith("/"):
            path = path[:-1]
        qs = parse_qs(u.query)
        if path == "/" or path == "":
            self.home()
        elif path == "/bank":
            self.bank_home()
        elif path == "/shop":
            self.shop_home()
        elif path == "/shop/search":
            self.shop_search(qs.get("q", [""])[0])
        elif path == "/shop/item":
            self.shop_item(qs.get("id", [""])[0])
        elif path == "/social":
            self.social_home()
        elif path == "/company":
            self.company_home()
        elif path == "/company/about":
            self.company_about()
        elif path == "/company/contact":
            self.company_contact()
        elif path == "/robots.txt" or path == "/company/robots.txt":
            self.robots()
        elif path == "/admin":
            self.admin_home()
        elif path == "/backup":
            self.backup_home()
        else:
            self.send_html(page("Not found", "<h1>404</h1><p>This fake page does not exist.</p><p><a href='/'>Lab Home</a></p>"), 404)

    def do_POST(self):
        u = urlparse(self.path)
        path = u.path
        if len(path) > 1 and path.endswith("/"):
            path = path[:-1]
        try:
            n = int(self.headers.get("Content-Length", 0))
        except ValueError:
            n = 0
        raw = self.rfile.read(n).decode("utf-8", "replace") if n > 0 else ""
        form = parse_qs(raw)
        if path == "/bank/login":
            self.bank_login(form)
        elif path == "/bank/transfer":
            self.send_html(page("Shubham Bank", "<div class='ok'>Transfer sent (fake). No real money moved - this is a practice site.</div><p><a href='/bank'>Back to Shubham Bank</a></p>"))
        elif path == "/social/login":
            self.social_login(form)
        elif path == "/admin/login":
            self.admin_login(form)
        else:
            self.send_html(page("Not found", "<h1>404</h1><p>This fake page does not exist.</p>"), 404)

    # ---------------- Lab Home ----------------
    def home(self):
        body = """<h1>Shubham OS - Practice Lab</h1>
<p>Welcome to your practice lab. Every site below is <b>fake</b> and runs
only on this PC (127.0.0.1). Nothing here is real, so practise freely.</p>
<div class='card'><h3><a href='/bank'>Shubham Bank</a></h3>
<p>A fake bank with a login page. Try the normal logins, then try your tools on it.</p></div>
<div class='card'><h3><a href='/shop'>Shubham Shop</a></h3>
<p>A fake shop with products and a search box. See what the search does with your words.</p></div>
<div class='card'><h3><a href='/social'>Shubham Social</a></h3>
<p>A fake social site. Any name you type becomes a profile - good for learning how fake pages fool people.</p></div>
<div class='card'><h3><a href='/company'>Shubham Company</a></h3>
<p>A fake company site. Hunt for the pages it tries to hide.</p></div>
<div class='card'><h3>Tools you can try</h3>
<p>nmap &nbsp; gobuster &nbsp; nikto &nbsp; sqlmap &nbsp; Burp Suite &nbsp; your browser</p>
<p><small>Point every tool at 127.0.0.1 only. This lab never touches the outside world.</small></p></div>"""
        self.send_html(page("Practice Lab", body))

    # ---------------- Bank ----------------
    def bank_home(self):
        body = """<h1>Shubham Bank</h1>
<p>Fake bank. Real practice.</p>
<div class='card'><form method='POST' action='/bank/login'>
<p>Username<br><input name='username' type='text'></p>
<p>Password<br><input name='password' type='password'></p>
<p><button type='submit'>Login</button></p></form>
<p><small>Practice logins: guest / guest123 &nbsp; rahul / rahul123</small></p></div>
<p><a href='/'>Lab Home</a></p>"""
        self.send_html(page("Shubham Bank", body))

    def bank_login(self, form):
        user = form.get("username", [""])[0]
        pw = form.get("password", [""])[0]
        row = None
        con = sqlite3.connect(DB)
        cur = con.cursor()
        # PRACTICE TARGET: this query is weak on purpose. It mixes the
        # typed words straight into the SQL line, like old training sites.
        q = "SELECT username, name, balance FROM users WHERE username = '%s' AND password = '%s'" % (user, pw)
        try:
            cur.execute(q)
            row = cur.fetchone()
        except sqlite3.Error:
            row = None
        con.close()
        if row:
            body = ("<h1>Shubham Bank - My Account</h1>"
                    "<div class='card'><p>Name: <b>" + html.escape(str(row[1])) + "</b></p>"
                    "<p>Username: " + html.escape(str(row[0])) + "</p>"
                    "<p>Balance: <b>Rs " + html.escape(str(row[2])) + "</b> (fake)</p></div>"
                    "<div class='card'><h3>Send money (fake)</h3>"
                    "<form method='POST' action='/bank/transfer'>"
                    "<p>To account<br><input name='to' type='text'></p>"
                    "<p>Amount<br><input name='amount' type='text'></p>"
                    "<p><button type='submit'>Send</button></p></form></div>"
                    "<p><a href='/bank'>Logout</a> &nbsp; <a href='/'>Lab Home</a></p>")
            self.send_html(page("Shubham Bank - Account", body))
        else:
            body = ("<h1>Shubham Bank</h1><div class='err'>Login failed. Wrong username or password.</div>"
                    "<p><a href='/bank'>Try again</a></p>")
            self.send_html(page("Shubham Bank", body))

    # ---------------- Shop ----------------
    def shop_home(self):
        items = ""
        for pid in sorted(PRODUCTS):
            name, price, _d = PRODUCTS[pid]
            items += "<div class='card'><h3><a href='/shop/item?id=%d'>%s</a></h3><p>%s</p></div>" % (pid, name, price)
        body = ("<h1>Shubham Shop</h1><p>Fake shop. Real practice.</p>"
                "<div class='card'><form method='GET' action='/shop/search'>"
                "<p>Search products<br><input name='q' type='text'> <button type='submit'>Search</button></p></form></div>"
                + items + "<p><a href='/'>Lab Home</a></p>")
        self.send_html(page("Shubham Shop", body))

    def shop_search(self, q):
        # PRACTICE TARGET: the typed words are shown back just as they
        # are, with no cleaning. That is the lesson of this page.
        body = ("<h1>Shubham Shop - Search</h1>"
                "<p>You searched for: " + q + "</p>"
                "<p>No products matched. Try a word like mouse or keyboard.</p>"
                "<p><a href='/shop'>Back to Shubham Shop</a></p>")
        self.send_html(page("Shubham Shop - Search", body))

    def shop_item(self, idv):
        try:
            pid = int(idv)
        except ValueError:
            pid = 0
        if pid in PRODUCTS:
            name, price, desc = PRODUCTS[pid]
            body = ("<h1>" + name + "</h1><div class='card'><p>Price: <b>" + price + "</b></p>"
                    "<p>" + desc + "</p><p><button>Add to cart (fake)</button></p></div>"
                    "<p><a href='/shop'>Back to Shubham Shop</a></p>")
        else:
            body = "<h1>Shubham Shop</h1><p>No product with that number.</p><p><a href='/shop'>Back to Shubham Shop</a></p>"
        self.send_html(page("Shubham Shop - Product", body))

    # ---------------- Social ----------------
    def social_home(self):
        body = """<h1>Shubham Social</h1>
<p>Fake social site. Type any name - it becomes a profile. That is how
fake pages are made, and why you should not trust every login page.</p>
<div class='card'><form method='POST' action='/social/login'>
<p>Username<br><input name='username' type='text'></p>
<p>Password<br><input name='password' type='password'></p>
<p><button type='submit'>Login</button></p></form></div>
<p><a href='/'>Lab Home</a></p>"""
        self.send_html(page("Shubham Social", body))

    def social_login(self, form):
        user = form.get("username", [""])[0] or "guest"
        ue = html.escape(user)
        body = ("<h1>Shubham Social - " + ue + "</h1>"
                "<div class='card'><h3>" + ue + "</h3><p>Fake profile. Joined today. 0 real friends.</p></div>"
                "<div class='card'><p><b>" + ue + "</b>: Hello! This is my first fake post.</p></div>"
                "<div class='card'><p><b>lab_bot</b>: Welcome to the practice lab. Everything here is fake.</p></div>"
                "<p><a href='/social'>Logout</a> &nbsp; <a href='/'>Lab Home</a></p>")
        self.send_html(page("Shubham Social - Profile", body))

    # ---------------- Company ----------------
    def company_home(self):
        body = """<h1>Shubham Company</h1>
<p>Fake company site. We make fake things for practice.</p>
<div class='card'><p><a href='/company/about'>About us</a></p>
<p><a href='/company/contact'>Contact</a></p></div>
<p><small>Some pages on this site are not linked here. Good tools can find them.</small></p>
<p><a href='/'>Lab Home</a></p>"""
        self.send_html(page("Shubham Company", body))

    def company_about(self):
        self.send_html(page("About - Shubham Company",
            "<h1>About us</h1><p>Shubham Company is a fake company. It exists only in this practice lab.</p><p><a href='/company'>Back</a></p>"))

    def company_contact(self):
        self.send_html(page("Contact - Shubham Company",
            "<h1>Contact</h1><p>Fake email: hello@example.invalid</p><p>Fake phone: 00000 00000</p><p><a href='/company'>Back</a></p>"))

    def robots(self):
        self.send_html("User-agent: *\nDisallow: /admin\nDisallow: /backup\n",
                       ctype="text/plain; charset=utf-8")

    def admin_home(self):
        body = """<h1>Admin Area</h1>
<p>Fake admin login. Staff only (not really - it is a practice page).</p>
<div class='card'><form method='POST' action='/admin/login'>
<p>Username<br><input name='username' type='text'></p>
<p>Password<br><input name='password' type='password'></p>
<p><button type='submit'>Login</button></p></form></div>
<p><a href='/'>Lab Home</a></p>"""
        self.send_html(page("Admin Area", body))

    def admin_login(self, form):
        body = ("<h1>Fake Admin Panel</h1><div class='ok'>You are in - because this panel is fake.</div>"
                "<div class='card'><p>Fake users today: 3</p><p>Fake sales today: Rs 0</p>"
                "<p>Lesson: a login page alone is not safety. Real sites must check every page, not just the form.</p></div>"
                "<p><a href='/'>Lab Home</a></p>")
        self.send_html(page("Fake Admin Panel", body))

    def backup_home(self):
        body = """<h1>Backup Files</h1>
<p>Fake backup area. These are only names on a page - there are no real files here.</p>
<div class='card'><p>bank-db-backup-2026-01.sql</p><p>users-list.csv</p><p>old-config.zip</p><p>site-full-backup.tar</p></div>
<p>Lesson: names like these should never be open on a real site.</p>
<p><a href='/'>Lab Home</a></p>"""
        self.send_html(page("Backup Files", body))

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "seed":
        seed()
        sys.exit(0)
    if not os.path.exists(DB):
        seed()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), H)
    print("Shubham Lab server at http://127.0.0.1:%d/" % PORT)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
PYEOF
}

is_running() {
  if [ -f "$PIDFILE" ]; then
    local p
    p=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$p" ] && kill -0 "$p" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

ensure_lab() {
  mkdir -p "$LABDIR" "$STATEDIR"
  write_server
  if [ ! -f "$DB" ]; then
    python3 "$SERVER" seed >/dev/null 2>&1
  fi
}

open_browser() {
  if command -v google-chrome >/dev/null 2>&1; then
    google-chrome "$HOME_URL" >/dev/null 2>&1 &
  elif command -v firefox >/dev/null 2>&1; then
    firefox "$HOME_URL" >/dev/null 2>&1 &
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$HOME_URL" >/dev/null 2>&1 &
  fi
}

open_terminal() {
  if command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal --working-directory="$LABDIR" >/dev/null 2>&1 &
  fi
}

print_targets() {
  echo ""
  echo "Practice targets (all fake, all on this PC only):"
  echo "  Lab Home:  $HOME_URL"
  echo "  Bank:      http://127.0.0.1:8080/bank"
  echo "  Shop:      http://127.0.0.1:8080/shop"
  echo "  Social:    http://127.0.0.1:8080/social"
  echo "  Company:   http://127.0.0.1:8080/company"
  echo ""
  echo "Tools you can try: nmap, gobuster, nikto, sqlmap, Burp Suite."
  echo "Do what you want - there are no levels and no questions."
  echo "To stop the lab: run shubham-lab and choose Stop Lab."
}

start_lab() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Python is not found on this PC, so the lab cannot run."
    exit 1
  fi
  ensure_lab
  if is_running; then
    echo "The Practice Lab is already running."
    print_targets
    open_browser
    open_terminal
    exit 0
  fi
  nohup python3 "$SERVER" > "$LOGFILE" 2>&1 &
  echo $! > "$PIDFILE"
  sleep 1
  if is_running; then
    echo "Practice Lab is ON."
    print_targets
    open_browser
    open_terminal
  else
    rm -f "$PIDFILE"
    echo "The lab could not start. The error is saved in: $LOGFILE"
    exit 1
  fi
}

stop_lab() {
  if [ -f "$PIDFILE" ]; then
    local p
    p=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$p" ] && kill -0 "$p" 2>/dev/null; then
      kill "$p" 2>/dev/null
      sleep 1
    fi
    rm -f "$PIDFILE"
    echo "Lab stopped. The lab sites are off."
  else
    echo "The lab is not running."
  fi
}

reset_lab() {
  if [ -f "$PIDFILE" ]; then
    local p
    p=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$p" ] && kill -0 "$p" 2>/dev/null; then
      kill "$p" 2>/dev/null
      sleep 1
    fi
    rm -f "$PIDFILE"
  fi
  rm -f "$DB"
  echo "Lab reset done. The fake sites will be fresh on the next start."
}

status_lab() {
  if is_running; then
    echo "Lab status: RUNNING"
    echo "Lab Home: $HOME_URL"
  else
    echo "Lab status: NOT running"
    echo "Start it with: shubham-lab, then choose Start Lab."
  fi
}

echo "Shubham OS - Practice Lab"
echo ""
echo "A free practice lab: fake web sites on this PC only."
echo "No levels, no questions - practise with real tools."
echo ""
echo "What do you want to do?"
echo "  1) Start Lab"
echo "  2) Stop Lab"
echo "  3) Reset Lab"
echo "  4) Lab Status"
read -r -p "Type 1, 2, 3 or 4: " CH

case "$CH" in
  1) start_lab ;;
  2) stop_lab ;;
  3) reset_lab ;;
  4) status_lab ;;
  *) echo "Please run it again and type 1, 2, 3 or 4." ;;
esac
SHUBHAM_LAB_24A
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-lab"

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
check_one lab ffaa733b6a967aaf56ed5b411befeb9bb2f61e90afc91418bec8adbba51d0d4c

echo 24 > /etc/shubham-os-version
echo ""
echo "Shubham OS Update 24 done!"
echo "  - shubham-lab is now a free practice lab: fake bank, shop,"
echo "    social and company sites on this PC only. No levels,"
echo "    no questions - practise with real tools."
echo "Type shubham-lab and choose Start Lab."
exit 0
# SHUBHAM24_END_OF_FILE
