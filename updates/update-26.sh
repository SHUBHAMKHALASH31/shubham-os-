# Shubham OS Update 26 - Practice Lab gets a fake OS desktop.
#
# Why: the lab opened a plain list page in Chrome. Now Start Lab opens
# a full fake Shubham OS desktop inside Chrome: a desktop with icons,
# movable windows, a practice terminal whose commands answer like the
# real tools (nmap, gobuster, nikto, sqlmap, curl), fake Chrome and
# Firefox windows for the lab sites, and a fake Google that only finds
# lab sites. It is all a web page - the feel is original, the engine
# is simulated, and everything stays on this PC.
# The old Lab Home page moves to /home (nothing is lost), the lab
# sites (/bank /shop /social /company /admin /backup) are unchanged,
# and the real terminal still opens beside Chrome for the real tools.
# Only shubham-lab changes. The other 16 features are not touched.
#
# Safety, the same as Updates 19 to 25:
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
  GATE_COUNT=$(grep -c "SHUBHAM26_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 26 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 26 (Lab Desktop) is being applied..."

# write_verified DEST -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1"
  local tmp="${dest}.tmp-shubham26"
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
  echo "Shubham OS Update 26 FAILED its check. Your old version is kept."
  echo "Please tell the developer what the updater showed."
  exit 1
}

mkdir -p /usr/local/bin
echo "Step 1: installing the new Practice Lab (with the fake OS desktop)..."
write_verified /usr/local/bin/shubham-lab << 'SHUBHAM_LAB_26A'
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

DESKTOP = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Shubham OS - Practice Lab</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
html,body{height:100%;overflow:hidden}
body{font-family:'Segoe UI',system-ui,sans-serif;background:#07090f;color:#e9edf5;
 background:radial-gradient(1200px 700px at 78% 30%, #2a1410 0%, #0d0a12 55%, #05060a 100%)}
#shield{position:fixed;right:6%;top:16%;font-size:300px;color:rgba(212,175,55,.07);pointer-events:none;user-select:none;line-height:1}
#topbar{position:fixed;top:0;left:0;right:0;height:36px;background:rgba(8,8,12,.92);
 border-bottom:1px solid rgba(212,175,55,.45);display:flex;align-items:center;
 padding:0 14px;font-size:13px;z-index:5000}
#topbar .brand{color:#ffd75e;font-weight:700;letter-spacing:.4px}
#topbar .lab{color:#9aa7bd;margin-left:10px}
#topbar .clock{margin-left:auto;color:#e9edf5}
#desktop{position:fixed;inset:36px 0 44px 0;padding:18px}
.icon{width:96px;text-align:center;padding:10px 4px;border-radius:10px;cursor:pointer;
 margin-bottom:8px;border:1px solid transparent;user-select:none}
.icon:hover{background:rgba(255,255,255,.06);border-color:rgba(212,175,55,.35)}
.icon .glyph{font-size:38px;line-height:1.15}
.icon .lbl{font-size:12.5px;color:#f2f4f8;text-shadow:0 1px 3px #000;margin-top:3px}
#note{position:fixed;right:16px;bottom:58px;max-width:300px;background:rgba(10,12,18,.78);
 border:1px solid rgba(212,175,55,.35);border-radius:10px;padding:10px 12px;font-size:12.5px;color:#c8d2e0;z-index:10}
#note b{color:#ffd75e}
#taskbar{position:fixed;left:0;right:0;bottom:0;height:44px;background:rgba(8,8,12,.94);
 border-top:1px solid rgba(212,175,55,.45);display:flex;align-items:center;padding:0 10px;gap:8px;z-index:5000}
#taskbar .start{color:#0a0a0a;background:linear-gradient(180deg,#f5d67b,#d4af37);font-weight:700;
 border-radius:8px;padding:6px 14px;font-size:13px;cursor:pointer}
.tbtn{background:#1a2130;border:1px solid #2c3850;color:#e9edf5;border-radius:8px;
 padding:6px 12px;font-size:12.5px;cursor:pointer;max-width:190px;white-space:nowrap;overflow:hidden}
.tbtn.active{border-color:#d4af37;color:#ffd75e}
.win{position:fixed;width:760px;height:500px;max-width:94vw;max-height:82vh;background:#10141d;
 border:1px solid #3a4358;border-radius:11px;box-shadow:0 18px 50px rgba(0,0,0,.65);
 display:flex;flex-direction:column;overflow:hidden}
.win .tbar{background:linear-gradient(180deg,#232c42,#171e2e);padding:8px 12px;display:flex;
 align-items:center;gap:8px;cursor:move;user-select:none;border-bottom:1px solid #2c3850}
.win .tbar .ttl{font-size:13.5px;font-weight:600;color:#f2f4f8}
.win .tbar .btns{margin-left:auto;display:flex;gap:6px}
.win .tbar .wb{width:26px;height:22px;border-radius:5px;border:1px solid #44506a;background:#1c2436;
 color:#dfe6f2;cursor:pointer;font-size:12px;line-height:1}
.win .tbar .wb.close:hover{background:#a32731;border-color:#a32731}
.win .body{flex:1;display:flex;flex-direction:column;min-height:0;background:#0b0e14}
.term{flex:1;overflow-y:auto;padding:10px 12px;font-family:'DejaVu Sans Mono',Consolas,monospace;
 font-size:13.5px;line-height:1.5;color:#d7e0ee;white-space:pre-wrap;word-break:break-word;cursor:text}
.term .prompt{color:#ffd75e}
.term .cmd{color:#fff}
.tinput{display:flex;padding:8px 12px;border-top:1px solid #232c42;background:#0b0e14;
 font-family:'DejaVu Sans Mono',Consolas,monospace;font-size:13.5px}
.tinput .prompt{color:#ffd75e;white-space:nowrap}
.tinput input{flex:1;background:transparent;border:0;outline:0;color:#fff;
 font-family:inherit;font-size:13.5px;padding-left:6px}
.bbar{display:flex;gap:8px;align-items:center;padding:8px;background:#171e2e;border-bottom:1px solid #2c3850}
.bbar .nav{width:30px;height:30px;border-radius:50%;border:1px solid #44506a;background:#1c2436;color:#dfe6f2;cursor:pointer}
.bbar .addr{flex:1;background:#0b0e14;border:1px solid #44506a;border-radius:16px;color:#e9edf5;
 padding:7px 14px;font-size:13px;outline:0}
.bbar .addr:focus{border-color:#d4af37}
.bmarks{display:flex;gap:14px;padding:6px 12px;background:#131927;border-bottom:1px solid #232c42;font-size:12.5px}
.bmarks a{color:#9fc2ff;text-decoration:none;cursor:pointer}
.bmarks a:hover{color:#ffd75e}
.win iframe{flex:1;border:0;width:100%;background:#10141d}
.about{padding:18px;font-size:14px;line-height:1.65;color:#d7e0ee;overflow-y:auto}
.about b{color:#ffd75e}
</style>
</head>
<body>
<div id="shield">&#128737;</div>
<div id="topbar"><span class="brand">Shubham OS</span><span class="lab">Practice Lab</span><span class="clock" id="clock"></span></div>
<div id="desktop">
  <div class="icon" data-app="terminal"><div class="glyph">&#128187;</div><div class="lbl">Terminal</div></div>
  <div class="icon" data-app="chrome"><div class="glyph">&#127760;</div><div class="lbl">Chrome</div></div>
  <div class="icon" data-app="firefox"><div class="glyph">&#129418;</div><div class="lbl">Firefox</div></div>
  <div class="icon" data-app="sites"><div class="glyph">&#127919;</div><div class="lbl">Lab Sites</div></div>
  <div class="icon" data-app="google"><div class="glyph">&#128269;</div><div class="lbl">Google</div></div>
  <div class="icon" data-app="about"><div class="glyph">&#128737;</div><div class="lbl">About Lab</div></div>
</div>
<div id="note"><b>Practice Lab.</b> Everything on this desktop is fake and safe. The real tools run in the real terminal window that opened with the lab.</div>
<div id="taskbar"><div class="start">&#128737; Shubham</div><div id="tbtns" style="display:flex;gap:8px"></div></div>
<script>
/* ============ Lab terminal engine (pure logic, no DOM) ============ */
var LabTerm = (function () {
  var cwd = '/home/shubham';
  var FS = {
    '/home/shubham': { dir: true, children: ['notes.txt', 'targets.txt', 'lab'] },
    '/home/shubham/notes.txt': { text: 'Lab notes\n- Point every tool at 127.0.0.1 only.\n- The bank login is weak on purpose. Try sqlmap on it.\n- robots.txt hides two paths. Find them with gobuster.' },
    '/home/shubham/targets.txt': { text: 'http://127.0.0.1:8080/bank\nhttp://127.0.0.1:8080/shop\nhttp://127.0.0.1:8080/social\nhttp://127.0.0.1:8080/company' },
    '/home/shubham/lab': { dir: true, children: ['lab-server.py', 'lab.db'] },
    '/home/shubham/lab/lab-server.py': { text: '# Shubham OS Practice Lab server - fake practice sites, this PC only.\n# Everything here is fake. The bank query is weak ON PURPOSE:\n# this is a practice target, like the training sites used in\n# security courses. (Only the first lines are shown.)' },
    '/home/shubham/lab/lab.db': { text: 'Binary file. Use the bank site - or sqlmap - to see what is inside.' }
  };
  function resolve(p) {
    if (!p || p === '~') return '/home/shubham';
    if (p === '.') return cwd;
    if (p === '..') { var parts = cwd.split('/'); parts.pop(); return parts.join('/') || '/'; }
    if (p.charAt(0) !== '/') p = cwd + '/' + p;
    var out = [];
    p.split('/').forEach(function (s) {
      if (s === '..') out.pop(); else if (s && s !== '.') out.push(s);
    });
    return '/' + out.join('/');
  }
  function isLocal(u) { return /127\.0\.0\.1|localhost/.test(u); }
  function L() { return Array.prototype.slice.call(arguments); }

  function nmap(target) {
    if (target && !isLocal(target) && target !== 'shubham-os') {
      return L('This practice lab only scans this PC (127.0.0.1).',
               'Try: nmap 127.0.0.1');
    }
    return L('Starting Nmap 7.94 ( https://nmap.org )',
      'Nmap scan report for 127.0.0.1',
      'Host is up (0.00021s latency).',
      'Not shown: 999 closed tcp ports (reset)',
      'PORT     STATE SERVICE',
      '8080/tcp open  http',
      '',
      'Nmap done: 1 IP address (1 host up) scanned in 1.87 seconds');
  }
  function gobuster(url) {
    if (!url || !isLocal(url)) return L('Usage inside this lab: gobuster dir -u http://127.0.0.1:8080 -w common.txt');
    return L('===============================================================',
      'Gobuster v3.6 - by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)',
      '===============================================================',
      '[+] Url:                     http://127.0.0.1:8080',
      '[+] Method:                  GET',
      '[+] Threads:                 10',
      '[+] Wordlist:                /usr/share/wordlists/dirb/common.txt',
      '[+] Negative Status codes:   404',
      '===============================================================',
      '/home                 (Status: 200) [Size: 2310]',
      '/bank                 (Status: 200) [Size: 1180]',
      '/shop                 (Status: 200) [Size: 1420]',
      '/social               (Status: 200) [Size: 1095]',
      '/company              (Status: 200) [Size: 990]',
      '/google               (Status: 200) [Size: 860]',
      '/robots.txt           (Status: 200) [Size: 62]',
      '/admin                (Status: 200) [Size: 1040]',
      '/backup               (Status: 200) [Size: 1215]',
      '===============================================================');
  }
  function nikto(url) {
    if (!url || !isLocal(url)) return L('Usage inside this lab: nikto -h http://127.0.0.1:8080');
    return L('- Nikto v2.5.0',
      '---------------------------------------------------------------------------',
      '+ Target IP:          127.0.0.1',
      '+ Target Hostname:    127.0.0.1',
      '+ Target Port:        8080',
      '+ Start Time:         today (lab time)',
      '---------------------------------------------------------------------------',
      '+ Server: BaseHTTP/0.6 Python/3',
      "+ /robots.txt: Entry '/admin' is returned in the robots file.",
      "+ /robots.txt: Entry '/backup' is returned in the robots file.",
      '+ /admin: Admin login page found.',
      '+ /backup: Backup file names are listed in plain view.',
      '+ 6 requests: 0 error(s) and 4 item(s) reported on remote host',
      '---------------------------------------------------------------------------');
  }
  function sqlmap(url) {
    if (!url || url.indexOf('bank') === -1) {
      return L('sqlmap/1.8#stable - automatic SQL injection and database takeover tool',
        '[INFO] testing connection to the target URL',
        '[WARNING] no injection point was found on that page.',
        'Hint: try the bank login page: sqlmap -u "http://127.0.0.1:8080/bank/login" --data="username=a&password=b" --dump');
    }
    return L('sqlmap/1.8#stable - automatic SQL injection and database takeover tool',
      '[*] starting (lab time)',
      '[INFO] testing connection to the target URL',
      '[INFO] checking if the target is protected by some kind of WAF/IPS',
      '[INFO] testing if the target URL content is stable',
      '[INFO] target URL content is stable',
      "[INFO] testing if POST parameter 'username' is dynamic",
      "[INFO] POST parameter 'username' appears to be dynamic",
      "[INFO] heuristic (basic) test shows that POST parameter 'username' might be injectable",
      "[INFO] testing for SQL injection on POST parameter 'username'",
      "[INFO] POST parameter 'username' is 'Generic UNION query' injectable",
      '[INFO] the back-end DBMS is SQLite',
      '[INFO] fetching tables for database: main',
      'Database: main',
      '[1 table]',
      '+-------+',
      '| users |',
      '+-------+',
      "[INFO] fetching entries for table 'users' in database 'main'",
      'Database: main',
      'Table: users',
      '[3 entries]',
      '+----------+----------+------------+---------+',
      '| username | password | name       | balance |',
      '+----------+----------+------------+---------+',
      '| admin    | admin123 | Admin      | 50000   |',
      '| guest    | guest123 | Guest User | 1500    |',
      '| rahul    | rahul123 | Rahul      | 2750    |',
      '+----------+----------+------------+---------+',
      '[*] ending (lab time)');
  }
  function ping(host) {
    if (!host) return L('Usage: ping <host>  - try: ping 127.0.0.1');
    if (!isLocal(host) && host !== 'shubham-os' && !/^\d+\.\d+\.\d+\.\d+$/.test(host)) {
      return L('ping: ' + host + ': Name or service not known');
    }
    var ip = isLocal(host) || host === 'shubham-os' ? '127.0.0.1' : host;
    return L('PING ' + host + ' (' + ip + ') 56(84) bytes of data.',
      '64 bytes from ' + ip + ': icmp_seq=1 ttl=64 time=0.041 ms',
      '64 bytes from ' + ip + ': icmp_seq=2 ttl=64 time=0.052 ms',
      '64 bytes from ' + ip + ': icmp_seq=3 ttl=64 time=0.038 ms',
      '64 bytes from ' + ip + ': icmp_seq=4 ttl=64 time=0.044 ms',
      '',
      '--- ' + host + ' ping statistics ---',
      '4 packets transmitted, 4 received, 0% packet loss');
  }

  function exec(raw) {
    var input = raw.trim();
    if (!input) return { lines: [] };
    var parts = input.split(/\s+/);
    var cmd = parts[0].toLowerCase();
    var args = parts.slice(1);
    switch (cmd) {
      case 'help': return { lines: L(
        'Commands in this lab terminal:',
        '  help                    show this list',
        '  whoami  hostname  pwd   the basics',
        '  ls  cd  cat             look around the fake files',
        '  ip a                    show network addresses',
        '  ping <host>             test if a host answers',
        '  nmap <host>             scan ports (this PC only)',
        '  gobuster dir -u <url>   find hidden pages on a lab site',
        '  nikto -h <url>          scan a lab site for known problems',
        '  sqlmap -u <url>         test a lab page for SQL injection',
        '  curl <url>              fetch a page as plain text',
        '  open <site>             open a lab site: bank shop social company google home',
        '  clear                   clean the terminal',
        '  exit                    close the terminal') };
      case 'whoami': return { lines: ['shubham'] };
      case 'hostname': return { lines: ['shubham-os'] };
      case 'pwd': return { lines: [cwd] };
      case 'clear': return { lines: [], clear: true };
      case 'exit': return { lines: [], exit: true };
      case 'ls': {
        var p = resolve(args[0] || '.');
        var node = FS[p];
        if (!node) return { lines: ['ls: cannot access ' + (args[0] || p) + ': No such file or directory'] };
        if (!node.dir) return { lines: [p.split('/').pop()] };
        return { lines: [node.children.join('   ')] };
      }
      case 'cd': {
        var t = resolve(args[0] || '~');
        var n = FS[t];
        if (!n) return { lines: ['bash: cd: ' + (args[0] || '') + ': No such file or directory'] };
        if (!n.dir) return { lines: ['bash: cd: ' + args[0] + ': Not a directory'] };
        cwd = t; return { lines: [] };
      }
      case 'cat': {
        if (!args[0]) return { lines: ['Usage: cat <file>'] };
        var f = FS[resolve(args[0])];
        if (!f) return { lines: ['cat: ' + args[0] + ': No such file or directory'] };
        if (f.dir) return { lines: ['cat: ' + args[0] + ': Is a directory'] };
        return { lines: f.text.split('\n') };
      }
      case 'echo': return { lines: [args.join(' ')] };
      case 'ip': case 'ifconfig': return { lines: L(
        '1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536',
        '    inet 127.0.0.1/8 scope host lo',
        '2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500',
        '    inet 192.168.37.133/24 brd 192.168.37.255 scope global eth0') };
      case 'ping': return { lines: ping(args[0]) };
      case 'nmap': return { lines: nmap(args.filter(function (a) { return a.charAt(0) !== '-'; })[0]) };
      case 'gobuster': {
        var ui = args.indexOf('-u');
        return { lines: gobuster(ui >= 0 ? args[ui + 1] : '') };
      }
      case 'nikto': {
        var hi = args.indexOf('-h');
        return { lines: nikto(hi >= 0 ? args[hi + 1] : args[0]) };
      }
      case 'sqlmap': {
        var si = args.indexOf('-u');
        var su = si >= 0 ? args[si + 1] : '';
        su = su.replace(/^"|"$/g, '');
        return { lines: sqlmap(su) };
      }
      case 'curl': case 'wget': {
        if (!args[0]) return { lines: ['Usage: ' + cmd + ' <url>'] };
        return { lines: [], curl: args[0], wget: cmd === 'wget' };
      }
      case 'open': {
        var site = (args[0] || '').toLowerCase();
        if (['bank', 'shop', 'social', 'company', 'google', 'home'].indexOf(site) >= 0) {
          return { lines: ['Opening ' + site + ' in the lab browser...'], open: site };
        }
        return { lines: ['open: pick one of: bank shop social company google home'] };
      }
      case 'sudo': return { lines: ['This practice terminal needs no root. Everything here is already open to you.'] };
      case 'msfvenom': return { lines: L(
        'This lab does not create payloads.',
        'The lab is for practising on the fake web sites on this PC only.') };
      case 'msfconsole': return { lines: L(
        'The exploit console is not part of this web lab.',
        'For web practice here, try: help') };
      case 'hydra': case 'john': case 'hashcat': case 'aircrack-ng':
        return { lines: ['bash: ' + cmd + ': command not found (not installed in this lab)'] };
      default: return { lines: ['bash: ' + cmd + ': command not found  (type: help)'] };
    }
  }
  return { exec: exec, cwd: function () { return cwd; } };
})();
</script>
<script>
/* ============ Desktop UI ============ */
(function () {
  var zTop = 100, wins = {};
  var tbtns = document.getElementById('tbtns');
  function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
  function clock() {
    var d = new Date(), p = function (n) { return (n < 10 ? '0' : '') + n; };
    document.getElementById('clock').textContent =
      p(d.getHours()) + ':' + p(d.getMinutes()) + '  ' + p(d.getDate()) + '/' + p(d.getMonth() + 1) + '/' + d.getFullYear();
  }
  setInterval(clock, 5000); clock();

  var SITES = { bank: '/bank', shop: '/shop', social: '/social', company: '/company', google: '/google', home: '/home' };
  function siteUrl(name) { return location.protocol + '//' + location.host + SITES[name]; }
  function parseAddr(v) {
    v = v.trim();
    if (!v) return siteUrl('home');
    var low = v.toLowerCase();
    for (var k in SITES) { if (low === k || low === k + '.lab' || low === 'www.' + k + '.lab') return siteUrl(k); }
    var m = v.match(/127\.0\.0\.1:8080(\/\S*)?/);
    if (m) return location.protocol + '//' + location.host + (m[1] || '/home');
    if (/^https?:\/\//.test(v) && isLocalUrl(v)) return v;
    return location.protocol + '//' + location.host + '/google?q=' + encodeURIComponent(v);
  }
  function isLocalUrl(u) { try { return new URL(u).host === location.host; } catch (e) { return false; } }

  function makeWin(key, title, w, h) {
    if (wins[key]) { focusWin(key); wins[key].el.style.display = 'flex'; return wins[key]; }
    var el = document.createElement('div');
    el.className = 'win';
    el.style.width = (w || 760) + 'px'; el.style.height = (h || 500) + 'px';
    el.style.left = (60 + Object.keys(wins).length * 36) + 'px';
    el.style.top = (70 + Object.keys(wins).length * 30) + 'px';
    el.innerHTML = '<div class="tbar"><span class="ttl">' + esc(title) + '</span>' +
      '<span class="btns"><button class="wb min">&#8211;</button><button class="wb close">&#10005;</button></span></div>' +
      '<div class="body"></div>';
    document.body.appendChild(el);
    var rec = { el: el, body: el.querySelector('.body'), key: key };
    wins[key] = rec;
    el.querySelector('.close').onclick = function () { closeWin(key); };
    el.querySelector('.min').onclick = function () { el.style.display = 'none'; };
    el.addEventListener('mousedown', function () { focusWin(key); });
    dragWin(el, el.querySelector('.tbar'));
    var b = document.createElement('button');
    b.className = 'tbtn'; b.textContent = title; b.id = 'tb-' + key;
    b.onclick = function () {
      if (el.style.display === 'none') { el.style.display = 'flex'; focusWin(key); }
      else if (el.style.zIndex == zTop) { el.style.display = 'none'; }
      else focusWin(key);
    };
    tbtns.appendChild(b);
    focusWin(key);
    return rec;
  }
  function focusWin(key) {
    var rec = wins[key]; if (!rec) return;
    rec.el.style.zIndex = ++zTop;
    var bs = tbtns.querySelectorAll('.tbtn');
    for (var i = 0; i < bs.length; i++) bs[i].classList.remove('active');
    var b = document.getElementById('tb-' + key); if (b) b.classList.add('active');
  }
  function closeWin(key) {
    var rec = wins[key]; if (!rec) return;
    rec.el.remove();
    var b = document.getElementById('tb-' + key); if (b) b.remove();
    delete wins[key];
  }
  function dragWin(el, handle) {
    var sx, sy, ox, oy, on = false;
    handle.addEventListener('mousedown', function (e) {
      if (e.target.tagName === 'BUTTON') return;
      on = true; sx = e.clientX; sy = e.clientY; ox = el.offsetLeft; oy = el.offsetTop;
    });
    document.addEventListener('mousemove', function (e) {
      if (!on) return;
      el.style.left = Math.max(0, ox + e.clientX - sx) + 'px';
      el.style.top = Math.max(38, oy + e.clientY - sy) + 'px';
    });
    document.addEventListener('mouseup', function () { on = false; });
  }

  /* ---------- Terminal app ---------- */
  function openTerminal() {
    var rec = makeWin('terminal', 'Terminal - shubham@shubham-os', 780, 520);
    if (rec.done) { var i = rec.body.querySelector('input'); if (i) i.focus(); return; }
    rec.done = true;
    rec.body.innerHTML = '<div class="term"></div>' +
      '<div class="tinput"><span class="prompt"></span><input type="text" autocomplete="off" spellcheck="false"></div>';
    var out = rec.body.querySelector('.term');
    var input = rec.body.querySelector('input');
    var promptEl = rec.body.querySelector('.tinput .prompt');
    var hist = [], hIdx = -1;
    function promptText() {
      var c = LabTerm.cwd().replace('/home/shubham', '~');
      return 'shubham@shubham-os:' + c + '$';
    }
    function setPrompt() { promptEl.textContent = promptText(); }
    function print(line) {
      var d = document.createElement('div');
      d.innerHTML = esc(line) || '&nbsp;';
      out.appendChild(d); out.scrollTop = out.scrollHeight;
    }
    function printCmd(cmd) {
      var d = document.createElement('div');
      d.innerHTML = '<span class="prompt">' + esc(promptText()) + '</span> <span class="cmd">' + esc(cmd) + '</span>';
      out.appendChild(d); out.scrollTop = out.scrollHeight;
    }
    print('Welcome to the Shubham OS Practice Lab terminal.');
    print('Everything here is fake and safe. Type: help');
    setPrompt(); input.focus();
    out.addEventListener('click', function () { input.focus(); });
    input.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowUp') { e.preventDefault(); if (hIdx < hist.length - 1) { hIdx++; input.value = hist[hIdx]; } return; }
      if (e.key === 'ArrowDown') { e.preventDefault(); if (hIdx > 0) { hIdx--; input.value = hist[hIdx]; } else { hIdx = -1; input.value = ''; } return; }
      if (e.key !== 'Enter') return;
      var cmd = input.value; input.value = ''; hIdx = -1;
      if (cmd.trim()) hist.unshift(cmd);
      printCmd(cmd);
      var r = LabTerm.exec(cmd);
      if (r.clear) { out.innerHTML = ''; setPrompt(); return; }
      if (r.exit) { closeWin('terminal'); return; }
      var lines = r.lines || [], i = 0;
      function step() {
        var n = 0;
        while (i < lines.length && n < 3) { print(lines[i]); i++; n++; }
        if (i < lines.length) setTimeout(step, 24);
        else after();
      }
      function after() {
        if (r.open) openBrowser('chrome', r.open);
        if (r.curl) doCurl(r.curl, r.wget);
        setPrompt();
      }
      if (lines.length) step(); else after();
    });
    function doCurl(url, isWget) {
      if (!isLocalUrl(url) && !/127\.0\.0\.1|localhost/.test(url)) {
        print("curl: (6) Could not resolve host - this lab only fetches pages on this PC.");
        print('Try: curl http://127.0.0.1:8080/bank');
        return;
      }
      fetch(url).then(function (resp) { return resp.text(); }).then(function (t) {
        if (isWget) {
          print("Saving to: 'index.html'");
          print('Length: ' + t.length + ' [text/html]');
          print("Saved - 'index.html' [" + t.length + '/' + t.length + ']');
        } else {
          var ls = t.split('\n').slice(0, 45);
          ls.forEach(print);
          if (t.split('\n').length > 45) print('... (page cut short in this view)');
        }
      }).catch(function () { print('curl: (7) Failed to connect to that page.'); });
    }
  }

  /* ---------- Browser app ---------- */
  function openBrowser(kind, startSite) {
    var title = kind === 'firefox' ? 'Firefox - Lab Browser' : 'Chrome - Lab Browser';
    var rec = makeWin(kind, title, 860, 560);
    if (!rec.done) {
      rec.done = true;
      rec.body.innerHTML =
        '<div class="bbar"><button class="nav back">&#8592;</button><button class="nav fwd">&#8594;</button>' +
        '<input class="addr" type="text" spellcheck="false"><button class="nav go">&#8635;</button></div>' +
        '<div class="bmarks"><a data-s="home">Lab Home</a><a data-s="bank">Bank</a><a data-s="shop">Shop</a>' +
        '<a data-s="social">Social</a><a data-s="company">Company</a><a data-s="google">Google</a></div>' +
        '<iframe></iframe>';
      var frame = rec.body.querySelector('iframe');
      var addr = rec.body.querySelector('.addr');
      rec.frame = frame;
      function go(v) { frame.src = parseAddr(v); addr.value = v; }
      rec.go = go;
      addr.addEventListener('keydown', function (e) { if (e.key === 'Enter') go(addr.value); });
      rec.body.querySelector('.go').onclick = function () { go(addr.value); };
      rec.body.querySelector('.back').onclick = function () { try { frame.contentWindow.history.back(); } catch (e) {} };
      rec.body.querySelector('.fwd').onclick = function () { try { frame.contentWindow.history.forward(); } catch (e) {} };
      var marks = rec.body.querySelectorAll('.bmarks a');
      for (var i = 0; i < marks.length; i++) {
        marks[i].onclick = (function (a) { return function () { go(a.getAttribute('data-s')); }; })(marks[i]);
      }
      go(startSite || 'home');
    } else if (startSite && rec.go) { rec.go(startSite); }
    rec.el.style.display = 'flex'; focusWin(kind);
  }

  /* ---------- About app ---------- */
  function openAbout() {
    var rec = makeWin('about', 'About this Lab', 520, 380);
    if (rec.done) return;
    rec.done = true;
    rec.body.innerHTML = '<div class="about">' +
      '<p><b>Shubham OS - Practice Lab</b></p>' +
      '<p>This whole desktop is a web page inside your browser. It only <i>looks</i> like a full OS - that is the fun of it.</p>' +
      '<p style="margin-top:8px">The <b>Terminal</b> here is a practice terminal: its commands are simulated, but they answer the way the real tools do.</p>' +
      '<p style="margin-top:8px">The <b>Chrome</b> and <b>Firefox</b> windows open the fake lab sites - Bank, Shop, Social, Company and a fake Google.</p>' +
      '<p style="margin-top:8px">For the <b>real</b> tools, use the real terminal window that opened with the lab, and point them at 127.0.0.1:8080.</p>' +
      '<p style="margin-top:8px">Everything is fake. Nothing leaves this PC.</p></div>';
  }

  var icons = document.querySelectorAll('.icon');
  for (var i = 0; i < icons.length; i++) {
    icons[i].addEventListener('dblclick', function () { launch(this.getAttribute('data-app')); });
    icons[i].addEventListener('click', function () { launch(this.getAttribute('data-app')); });
  }
  function launch(app) {
    if (app === 'terminal') openTerminal();
    else if (app === 'chrome') openBrowser('chrome');
    else if (app === 'firefox') openBrowser('firefox');
    else if (app === 'sites') openBrowser('chrome', 'home');
    else if (app === 'google') openBrowser('chrome', 'google');
    else if (app === 'about') openAbout();
  }
  document.querySelector('.start').addEventListener('click', function () { openAbout(); });
  openTerminal();
})();
</script>
</body>
</html>
"""

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
        if path == "/" or path == "" or path == "/desktop":
            self.desktop()
        elif path == "/home":
            self.home()
        elif path == "/google":
            self.google(qs.get("q", [""])[0])
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
            self.send_html(page("Not found", "<h1>404</h1><p>This fake page does not exist.</p><p><a href='/home'>Lab Home</a></p>"), 404)

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


    # ---------------- Fake OS Desktop ----------------
    def desktop(self):
        self.send_html(DESKTOP)

    # ---------------- Fake Google ----------------
    def google(self, q):
        qe = html.escape(q)
        results = ""
        if q:
            sites = [
                ("/bank", "Shubham Bank", "Fake bank with a login page. Real practice."),
                ("/shop", "Shubham Shop", "Fake shop with products and a search box."),
                ("/social", "Shubham Social", "Fake social site. Any name becomes a profile."),
                ("/company", "Shubham Company", "Fake company site. Some pages are hidden."),
                ("/home", "Shubham Lab Home", "All the fake practice sites in one place."),
            ]
            cards = ""
            for url, name, desc in sites:
                cards += ("<div class='card'><p><a href='" + url + "'>" + name + "</a></p>"
                          "<p><small>http://127.0.0.1:8080" + url + "</small></p><p>" + desc + "</p></div>")
            results = "<p>About 5 fake results for <b>" + qe + "</b> (0.42 seconds)</p>" + cards
        body = ("<div style='text-align:center;margin-top:60px'>"
                "<h1 style='font-size:56px'><span style='color:#7db4ff'>G</span><span style='color:#ff7d7d'>o</span>"
                "<span style='color:#ffd75e'>o</span><span style='color:#7db4ff'>g</span>"
                "<span style='color:#7dd87d'>l</span><span style='color:#ff7d7d'>e</span></h1>"
                "<p><small>Fake Google - only in this lab. It only finds lab sites.</small></p>"
                "<form method='GET' action='/google'><input name='q' type='text' value='" + qe + "' style='width:70%'> "
                "<button type='submit'>Search</button></form></div>" + results)
        self.send_html(page("Google (fake)", body))

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
<div class='card'><h3><a href='/'>Lab Desktop</a></h3>
<p>The fake Shubham OS desktop - a terminal, Chrome, Firefox and a fake Google, all inside your browser.</p></div>
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
<p><a href='/home'>Lab Home</a></p>"""
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
                    "<p><a href='/bank'>Logout</a> &nbsp; <a href='/home'>Lab Home</a></p>")
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
                + items + "<p><a href='/home'>Lab Home</a></p>")
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
<p><a href='/home'>Lab Home</a></p>"""
        self.send_html(page("Shubham Social", body))

    def social_login(self, form):
        user = form.get("username", [""])[0] or "guest"
        ue = html.escape(user)
        body = ("<h1>Shubham Social - " + ue + "</h1>"
                "<div class='card'><h3>" + ue + "</h3><p>Fake profile. Joined today. 0 real friends.</p></div>"
                "<div class='card'><p><b>" + ue + "</b>: Hello! This is my first fake post.</p></div>"
                "<div class='card'><p><b>lab_bot</b>: Welcome to the practice lab. Everything here is fake.</p></div>"
                "<p><a href='/social'>Logout</a> &nbsp; <a href='/home'>Lab Home</a></p>")
        self.send_html(page("Shubham Social - Profile", body))

    # ---------------- Company ----------------
    def company_home(self):
        body = """<h1>Shubham Company</h1>
<p>Fake company site. We make fake things for practice.</p>
<div class='card'><p><a href='/company/about'>About us</a></p>
<p><a href='/company/contact'>Contact</a></p></div>
<p><small>Some pages on this site are not linked here. Good tools can find them.</small></p>
<p><a href='/home'>Lab Home</a></p>"""
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
<p><a href='/home'>Lab Home</a></p>"""
        self.send_html(page("Admin Area", body))

    def admin_login(self, form):
        body = ("<h1>Fake Admin Panel</h1><div class='ok'>You are in - because this panel is fake.</div>"
                "<div class='card'><p>Fake users today: 3</p><p>Fake sales today: Rs 0</p>"
                "<p>Lesson: a login page alone is not safety. Real sites must check every page, not just the form.</p></div>"
                "<p><a href='/home'>Lab Home</a></p>")
        self.send_html(page("Fake Admin Panel", body))

    def backup_home(self):
        body = """<h1>Backup Files</h1>
<p>Fake backup area. These are only names on a page - there are no real files here.</p>
<div class='card'><p>bank-db-backup-2026-01.sql</p><p>users-list.csv</p><p>old-config.zip</p><p>site-full-backup.tar</p></div>
<p>Lesson: names like these should never be open on a real site.</p>
<p><a href='/home'>Lab Home</a></p>"""
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
  echo "  Lab Desktop: $HOME_URL  (opens by itself in Chrome)"
  echo "  Lab Home:  http://127.0.0.1:8080/home"
  echo "  Bank:      http://127.0.0.1:8080/bank"
  echo "  Shop:      http://127.0.0.1:8080/shop"
  echo "  Social:    http://127.0.0.1:8080/social"
  echo "  Company:   http://127.0.0.1:8080/company"
  echo "  Google:    http://127.0.0.1:8080/google  (fake)"
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
SHUBHAM_LAB_26A
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
check_one lab 4365c8c026512a791fc203a1be72cf1225b2dd38fb121450d050a177537b1bef

echo 26 > /etc/shubham-os-version
echo ""
echo "Shubham OS Update 26 done!"
echo "  - Start Lab now opens a fake Shubham OS desktop in Chrome:"
echo "    a practice terminal, Chrome and Firefox windows, a fake"
echo "    Google, and all the lab sites inside it."
echo "  - The old Lab Home page is at http://127.0.0.1:8080/home"
echo "  - The real terminal still opens for the real tools."
echo "Try it: run shubham-lab and choose Start Lab."
exit 0
# SHUBHAM26_END_OF_FILE
