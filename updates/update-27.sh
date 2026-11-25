# Shubham OS Update 27 - the FULL package update.
#
# Why: until now, each update carried only the one command it changed.
# A user who skipped an update silently missed its fix - for example,
# jumping from Update 24 to 26 missed the Carry fix from Update 25.
# That design was wrong. From Update 27 on, EVERY update carries ALL
# 17 feature commands at their newest version, plus the tools they
# need. Whatever version you are on, one update brings everything.
#
# What is inside (newest version of every command):
#   Batch 1: shubham-help, shubham-netfix, shubham-history,
#            shubham-wifi, shubham-speed, shubham-error
#   Batch 2: shubham-phone, shubham-locker, shubham-record,
#            shubham-guest, shubham-clean, shubham-recover
#   Batch 3: shubham-doctor, shubham-live, shubham-ghost
#   Batch 4: shubham-lab (with the fake OS desktop from Update 26),
#            shubham-carry (with the disk list fix from Update 25)
#   Tools:   ffmpeg, Tor, x11vnc, websockify, novnc, ClamAV,
#            cloudflared (internet links) and Google Chrome.
#
# Safety, the same as Updates 19 to 26:
#   0. This script first checks its own file is complete (an end marker
#      must be present). An incomplete copy changes NOTHING and stops.
#   1. Every command file is written to a temporary name, checked (not
#      empty, correct shell syntax), and only then moved into place.
#   2. Every command is checked by SHA-256 hash at the end.
#   3. If a needed tool is missing, the version is NOT written and the
#      update asks to be run again with good internet.
# The panel is not touched. Runs as root via pkexec.

# --- Step 0: refuse an incomplete copy of this update ---------------------
if [ -f "$0" ]; then
  GATE_COUNT=$(grep -c "SHUBHAM27_END_OF_FILE" "$0" 2>/dev/null)
  if [ -z "$GATE_COUNT" ] || [ "$GATE_COUNT" -lt 2 ]; then
    echo "Shubham OS Update 27 FAILED: the update file is incomplete"
    echo "(the download did not arrive fully). Nothing was changed."
    echo "Please run the update again."
    exit 1
  fi
fi

echo "Shubham OS Update 27 (full package) is being applied..."

# write_verified DEST -- content arrives on stdin.
# Writes to a temp file, checks it, and only then moves it into place.
write_verified() {
  local dest="$1"
  local tmp="${dest}.tmp-shubham27"
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
  echo "Shubham OS Update 27 FAILED its check. Your old version is kept."
  echo "Please tell the developer what the updater showed."
  exit 1
}

mkdir -p /usr/local/bin
echo "Step 1: installing all 17 feature commands (newest versions)..."
write_verified /usr/local/bin/shubham-help << 'SHUBHAM27_HELP'
#!/bin/bash
# Shubham OS - Help: shows all Shubham OS commands in one list.
cat << 'EOF'
Shubham OS - All Commands

shubham-windows  (full Windows look, Kali tools hidden)
shubham-kali     (full Kali mode, all tools back)

SPECIAL FEATURES
shubham-netfix   (fix internet problems)
shubham-history  (save all terminal commands in one txt file)
shubham-phone    (connect phone without cable)
shubham-locker   (lock files with a password)
shubham-record   (record your screen)
shubham-guest    (open guest mode)
shubham-clean    (clean junk, make PC light and fast)
shubham-wifi     (show a saved WiFi password)
shubham-recover  (bring back a deleted file)
shubham-error    (understand any error in simple words)
shubham-lab      (open the practice lab)
shubham-live     (show your screen live)
shubham-speed    (check internet speed)
shubham-carry    (carry your OS in a pen drive)
shubham-doctor   (full PC check and repair)
shubham-ghost    (hide your identity on the net)

You can also open every feature from the menu:
Shubham OS Special Features
EOF
SHUBHAM27_HELP
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-help"
write_verified /usr/local/bin/shubham-netfix << 'SHUBHAM27_NETFIX'
#!/bin/bash
# Shubham OS - Net Fix: restarts the network, clears old DNS settings and tests the internet.
echo "Net Fix is working..."

# Restart the network connection (NetworkManager).
if command -v nmcli >/dev/null 2>&1; then
  echo "Restarting the network..."
  nmcli networking off 2>/dev/null
  sleep 2
  nmcli networking on 2>/dev/null
  sleep 3
fi

# Clear the old DNS cache.
if command -v resolvectl >/dev/null 2>&1; then
  resolvectl flush-caches 2>/dev/null
fi

# Take a fresh network address, if the tool for it is present.
if command -v dhclient >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    dhclient -r 2>/dev/null
    dhclient 2>/dev/null
  elif command -v sudo >/dev/null 2>&1; then
    sudo dhclient -r 2>/dev/null
    sudo dhclient 2>/dev/null
  fi
  sleep 2
fi

# Test the internet.
echo "Testing the internet..."
if ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1 || ping -c 2 -W 3 1.1.1.1 >/dev/null 2>&1; then
  echo "Done - your internet is working."
else
  echo "The internet is still not working."
  echo "Check the WiFi or cable once, then run Net Fix again."
fi
SHUBHAM27_NETFIX
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-netfix"
write_verified /usr/local/bin/shubham-history << 'SHUBHAM27_HISTORY'
#!/bin/bash
# Shubham OS - History File: saves all terminal commands (first to last) in one txt file.
# It only asks where to save the file.
echo "History File - all your terminal commands in one file."
echo ""
read -r -p "Where to save? Press Enter for Desktop, or type a folder path: " DIR
if [ -z "$DIR" ]; then
  DIR="$HOME/Desktop"
fi
mkdir -p "$DIR" 2>/dev/null
OUT="$DIR/terminal-history.txt"

TMP="$(mktemp)"
# Bash history.
if [ -f "$HOME/.bash_history" ]; then
  cat "$HOME/.bash_history" >> "$TMP"
fi
# Zsh history (clean its time marks).
if [ -f "$HOME/.zsh_history" ]; then
  sed 's/^: [0-9][0-9]*:[0-9][0-9]*;//' "$HOME/.zsh_history" >> "$TMP"
fi

if [ ! -s "$TMP" ]; then
  echo "No commands found yet. Use the terminal first, then run this again."
  rm -f "$TMP"
  exit 0
fi

cat "$TMP" > "$OUT"
COUNT="$(wc -l < "$OUT")"
rm -f "$TMP"
echo "Saved: $OUT"
echo "Total commands in the file: $COUNT"
SHUBHAM27_HISTORY
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-history"
write_verified /usr/local/bin/shubham-wifi << 'SHUBHAM27_WIFI'
#!/bin/bash
# Shubham OS - WiFi Password: shows the password of a saved WiFi network.
if ! command -v nmcli >/dev/null 2>&1; then
  echo "NetworkManager is not found on this PC, so saved WiFi passwords cannot be read."
  exit 1
fi

mapfile -t CONNS < <(nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2 ~ /wireless/ {print $1}')
if [ "${#CONNS[@]}" -eq 0 ]; then
  echo "No saved WiFi networks found on this PC."
  exit 0
fi

echo "Saved WiFi networks on this PC:"
i=1
for c in "${CONNS[@]}"; do
  echo "  $i) $c"
  i=$((i+1))
done
echo ""
read -r -p "Type the number of the WiFi: " N
case "$N" in
  ''|*[!0-9]*) echo "That is not a number. Run it again."; exit 1 ;;
esac
if [ "$N" -lt 1 ] || [ "$N" -gt "${#CONNS[@]}" ]; then
  echo "That number is not in the list. Run it again."
  exit 1
fi

NAME="${CONNS[$((N-1))]}"
echo ""
echo "WiFi name: $NAME"
echo "Your PC password may be asked - it is for your safety."
PASS="$(sudo nmcli -s -g 802-11-wireless-security.psk connection show "$NAME" 2>/dev/null)"
if [ -n "$PASS" ]; then
  echo "Password: $PASS"
else
  echo "No saved password found for this WiFi (open network, or the password was never saved)."
fi
SHUBHAM27_WIFI
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-wifi"
write_verified /usr/local/bin/shubham-speed << 'SHUBHAM27_SPEED'
#!/bin/bash
# Shubham OS - Net Speed: tests internet speed in one command.
echo "Testing your internet speed, please wait..."

if command -v speedtest-cli >/dev/null 2>&1; then
  speedtest-cli --simple
  exit 0
fi
if python3 -c "import speedtest" >/dev/null 2>&1; then
  python3 -m speedtest --simple
  exit 0
fi

# Quick test without any extra tool: ping + download speed.
PING=""
if command -v ping >/dev/null 2>&1; then
  PING="$(ping -c 3 -W 3 8.8.8.8 2>/dev/null | tail -n 1 | awk -F/ '{print $5}')"
fi
if [ -n "$PING" ]; then
  echo "Ping: ${PING} ms"
fi

BPS="$(curl -o /dev/null -s -w '%{speed_download}' --max-time 30 'https://speed.cloudflare.com/__down?bytes=10000000' 2>/dev/null)"
if [ -z "$BPS" ] || [ "$BPS" = "0" ] || [ "$BPS" = "0.000" ]; then
  BPS="$(curl -o /dev/null -s -w '%{speed_download}' --max-time 30 'https://proof.ovh.net/files/10Mb.dat' 2>/dev/null)"
fi
if [ -n "$BPS" ] && [ "$BPS" != "0" ] && [ "$BPS" != "0.000" ]; then
  awk -v b="$BPS" 'BEGIN { printf "Download: %.1f Mbps\n", (b*8)/1000000 }'
  echo "(Quick test - download and ping only.)"
else
  echo "The speed test could not run. Check your internet and try again."
  exit 1
fi
SHUBHAM27_SPEED
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-speed"
write_verified /usr/local/bin/shubham-error << 'SHUBHAM27_ERROR'
#!/bin/bash
# Shubham OS - Error Guide: explains common errors in simple words, in your language.
# Use: shubham-error [hindi|gujarati|spanish|english] [error words...]
# With no words, it shows the common errors list.

LANG_CODE="en"
WORDS=""
for a in "$@"; do
  low="$(printf '%s' "$a" | tr 'A-Z' 'a-z')"
  case "$low" in
    hindi|hi) LANG_CODE="hi" ;;
    gujarati|gu) LANG_CODE="gu" ;;
    spanish|es) LANG_CODE="es" ;;
    english|en) LANG_CODE="en" ;;
    *) WORDS="$WORDS $a" ;;
  esac
done
WORDS="$(printf '%s' "$WORDS" | sed 's/^ //' | tr 'A-Z' 'a-z')"

t() {
  # t <key> : prints text in the chosen language
  case "$LANG_CODE:$1" in
    en:list) echo "Common errors - type a number, or type your error words:" ;;
    hi:list) echo "आम errors - number लिखो, या अपने error के शब्द लिखो:" ;;
    gu:list) echo "સામાન્ય errors - number લખો, કે તમારા error ના શબ્દો લખો:" ;;
    es:list) echo "Errores comunes - escribe un número, o escribe las palabras de tu error:" ;;
    en:hint) echo "This error is not in the guide yet. Hint: check the spelling of the command and the file name first - most errors come from a small typing mistake." ;;
    hi:hint) echo "यह error अभी guide में नहीं है। Hint: पहले command और file के नाम की spelling check करो - ज़्यादातर errors छोटी typing गलती से होते हैं।" ;;
    gu:hint) echo "આ error હજી guide માં નથી. Hint: પહેલા command અને file ના નામની spelling check કરો - મોટા ભાગના errors નાની typing ભૂલથી થાય છે." ;;
    es:hint) echo "Este error aún no está en la guía. Pista: revisa primero la ortografía del comando y del nombre del archivo - la mayoría de los errores vienen de una pequeña equivocación al escribir." ;;
  esac
}

entry() {
  # entry <key> : prints Meaning + Fix in the chosen language
  case "$LANG_CODE:$1" in
    en:notfound) echo "Meaning: The PC does not know this command. The tool is not installed, or the spelling is wrong."; echo "Fix: 1) Check the spelling. 2) If the tool is missing, install it: sudo apt install TOOL-NAME 3) Run the command again." ;;
    hi:notfound) echo "मतलब: PC इस command को नहीं जानता। Tool installed नहीं है, या spelling गलत है।"; echo "ठीक करो: 1) Spelling check करो। 2) Tool न हो तो install करो: sudo apt install TOOL-NAME 3) Command फिर से चलाओ।" ;;
    gu:notfound) echo "અર્થ: PC આ command ને ઓળખતો નથી. Tool installed નથી, કે spelling ખોટી છે."; echo "ઠીક કરો: 1) Spelling check કરો. 2) Tool ન હોય તો install કરો: sudo apt install TOOL-NAME 3) Command ફરી ચલાવો." ;;
    es:notfound) echo "Significado: El PC no conoce este comando. La herramienta no está instalada, o está mal escrito."; echo "Solución: 1) Revisa la ortografía. 2) Si falta la herramienta, instálala: sudo apt install NOMBRE 3) Ejecuta el comando de nuevo." ;;

    en:perm) echo "Meaning: You do not have the right to open or change this file."; echo "Fix: 1) If it is your own work, put sudo in front of the command. 2) Never use sudo on files you do not know." ;;
    hi:perm) echo "मतलब: तुम्हें इस file को खोलने या बदलने का हक नहीं है।"; echo "ठीक करो: 1) अपना काम हो तो command के आगे sudo लगाओ। 2) अनजान files पर sudo कभी मत लगाओ।" ;;
    gu:perm) echo "અર્થ: તમને આ file ખોલવાનો કે બદલવાનો હક નથી."; echo "ઠીક કરો: 1) તમારું પોતાનું કામ હોય તો command આગળ sudo લગાવો. 2) અજાણી files પર sudo ક્યારેય ન લગાવો." ;;
    es:perm) echo "Significado: No tienes derecho a abrir o cambiar este archivo."; echo "Solución: 1) Si es tu propio trabajo, pon sudo delante del comando. 2) Nunca uses sudo en archivos que no conoces." ;;

    en:dns) echo "Meaning: The PC cannot find websites by name. The name system (DNS) is not answering."; echo "Fix: 1) Check that WiFi or cable is connected. 2) Run shubham-netfix. 3) Restart the PC if it still fails." ;;
    hi:dns) echo "मतलब: PC नाम से websites नहीं ढूंढ पा रहा। Name system (DNS) जवाब नहीं दे रहा।"; echo "ठीक करो: 1) देखो WiFi या cable जुड़ा है। 2) shubham-netfix चलाओ। 3) फिर भी न हो तो PC restart करो।" ;;
    gu:dns) echo "અર્થ: PC નામથી websites શોધી શકતો નથી. Name system (DNS) જવાબ આપતું નથી."; echo "ઠીક કરો: 1) જુઓ WiFi કે cable જોડાયેલ છે. 2) shubham-netfix ચલાવો. 3) તો પણ ન થાય તો PC restart કરો." ;;
    es:dns) echo "Significado: El PC no encuentra los sitios por nombre. El sistema de nombres (DNS) no responde."; echo "Solución: 1) Revisa que el WiFi o el cable esté conectado. 2) Ejecuta shubham-netfix. 3) Reinicia el PC si sigue fallando." ;;

    en:space) echo "Meaning: The disk is full. There is no room to save or install anything."; echo "Fix: 1) Run shubham-clean to remove junk. 2) Delete big files you do not need. 3) Empty the Trash." ;;
    hi:space) echo "मतलब: Disk भर गई है। कुछ save या install करने की जगह नहीं है।"; echo "ठीक करो: 1) कबाड़ साफ करने के लिए shubham-clean चलाओ। 2) बड़ी files जो काम की नहीं, delete करो। 3) Trash खाली करो।" ;;
    gu:space) echo "અર્થ: Disk ભરાઈ ગઈ છે. કંઈ save કે install કરવાની જગ્યા નથી."; echo "ઠીક કરો: 1) કચરો સાફ કરવા shubham-clean ચલાવો. 2) મોટી files જે કામની નથી તે delete કરો. 3) Trash ખાલી કરો." ;;
    es:space) echo "Significado: El disco está lleno. No hay espacio para guardar ni instalar nada."; echo "Solución: 1) Ejecuta shubham-clean para quitar basura. 2) Borra archivos grandes que no necesitas. 3) Vacía la papelera." ;;

    en:locate) echo "Meaning: This software package was not found. The name may be wrong, or the list is old."; echo "Fix: 1) Run: sudo apt update 2) Check the package name spelling. 3) Install again." ;;
    hi:locate) echo "मतलब: यह software package नहीं मिला। नाम गलत हो सकता है, या list पुरानी है।"; echo "ठीक करो: 1) चलाओ: sudo apt update 2) Package के नाम की spelling देखो। 3) फिर install करो।" ;;
    gu:locate) echo "અર્થ: આ software package મળ્યું નથી. નામ ખોટું હોઈ શકે, કે list જૂની છે."; echo "ઠીક કરો: 1) ચલાવો: sudo apt update 2) Package ના નામની spelling જુઓ. 3) ફરી install કરો." ;;
    es:locate) echo "Significado: Este paquete de software no se encontró. El nombre puede estar mal, o la lista es vieja."; echo "Solución: 1) Ejecuta: sudo apt update 2) Revisa la ortografía del nombre. 3) Instala de nuevo." ;;

    en:refused) echo "Meaning: The other side said no. The service on that port is closed or not running."; echo "Fix: 1) Check the address and the port number. 2) Check that the service is running. 3) Check the firewall." ;;
    hi:refused) echo "मतलब: दूसरी तरफ से मना हो गया। उस port पर service बंद है या चल ही नहीं रही।"; echo "ठीक करो: 1) Address और port number देखो। 2) देखो service चल रही है। 3) Firewall check करो।" ;;
    gu:refused) echo "અર્થ: બીજી તરફથી ના આવી. તે port પર service બંધ છે કે ચાલતી જ નથી."; echo "ઠીક કરો: 1) Address અને port number જુઓ. 2) જુઓ service ચાલે છે. 3) Firewall check કરો." ;;
    es:refused) echo "Significado: El otro lado dijo que no. El servicio en ese puerto está cerrado o no está activo."; echo "Solución: 1) Revisa la dirección y el número de puerto. 2) Revisa que el servicio esté activo. 3) Revisa el firewall." ;;

    en:lock) echo "Meaning: Another software work is going on. The package system is busy."; echo "Fix: 1) Wait 2 minutes and try again. 2) Close any other update or install window. 3) Restart the PC if it stays locked." ;;
    hi:lock) echo "मतलब: कोई दूसरा software काम चल रहा है। Package system busy है।"; echo "ठीक करो: 1) 2 minute रुको और फिर कोशिश करो। 2) कोई दूसरी update या install window बंद करो। 3) Lock न खुले तो PC restart करो।" ;;
    gu:lock) echo "અર્થ: બીજું કોઈ software કામ ચાલે છે. Package system busy છે."; echo "ઠીક કરો: 1) 2 minute રાહ જુઓ અને ફરી પ્રયાસ કરો. 2) બીજી કોઈ update કે install window બંધ કરો. 3) Lock ન ખુલે તો PC restart કરો." ;;
    es:lock) echo "Significado: Hay otro trabajo de software en curso. El sistema de paquetes está ocupado."; echo "Solución: 1) Espera 2 minutos e inténtalo de nuevo. 2) Cierra cualquier otra ventana de actualización o instalación. 3) Reinicia el PC si sigue bloqueado." ;;

    en:apt404) echo "Meaning: The file was not found on the server. The list on your PC is old."; echo "Fix: 1) Run: sudo apt update 2) Try the install again." ;;
    hi:apt404) echo "मतलब: Server पर वह file नहीं मिली। तुम्हारे PC की list पुरानी है।"; echo "ठीक करो: 1) चलाओ: sudo apt update 2) फिर install करके देखो।" ;;
    gu:apt404) echo "અર્થ: Server પર તે file મળી નથી. તમારા PC ની list જૂની છે."; echo "ઠીક કરો: 1) ચલાવો: sudo apt update 2) ફરી install કરી જુઓ." ;;
    es:apt404) echo "Significado: El archivo no se encontró en el servidor. La lista de tu PC es vieja."; echo "Solución: 1) Ejecuta: sudo apt update 2) Intenta la instalación de nuevo." ;;

    en:unreach) echo "Meaning: The PC has no road to the network."; echo "Fix: 1) Check WiFi or cable. 2) Run shubham-netfix. 3) Restart the router if other devices also fail." ;;
    hi:unreach) echo "मतलब: PC के पास network तक कोई रास्ता नहीं है।"; echo "ठीक करो: 1) WiFi या cable देखो। 2) shubham-netfix चलाओ। 3) दूसरे devices भी बंद हों तो router restart करो।" ;;
    gu:unreach) echo "અર્થ: PC પાસે network સુધી કોઈ રસ્તો નથી."; echo "ઠીક કરો: 1) WiFi કે cable જુઓ. 2) shubham-netfix ચલાવો. 3) બીજા devices પણ બંધ હોય તો router restart કરો." ;;
    es:unreach) echo "Significado: El PC no tiene camino hacia la red."; echo "Solución: 1) Revisa el WiFi o el cable. 2) Ejecuta shubham-netfix. 3) Reinicia el router si otros aparatos también fallan." ;;

    en:nosuch) echo "Meaning: That file or folder is not at the place you typed."; echo "Fix: 1) Check the spelling of the name. 2) See where you are: pwd 3) See the files here: ls" ;;
    hi:nosuch) echo "मतलब: वह file या folder तुम्हारी लिखी जगह पर नहीं है।"; echo "ठीक करो: 1) नाम की spelling देखो। 2) देखो तुम हो कहाँ: pwd 3) यहाँ की files देखो: ls" ;;
    gu:nosuch) echo "અર્થ: તે file કે folder તમારી લખેલી જગ્યાએ નથી."; echo "ઠીક કરો: 1) નામની spelling જુઓ. 2) જુઓ તમે ક્યાં છો: pwd 3) અહીંની files જુઓ: ls" ;;
    es:nosuch) echo "Significado: Ese archivo o carpeta no está en el lugar que escribiste."; echo "Solución: 1) Revisa la ortografía del nombre. 2) Mira dónde estás: pwd 3) Mira los archivos aquí: ls" ;;
  esac
}

KEYS=(notfound perm dns space locate refused lock apt404 unreach nosuch)
NAMES_en=("command not found" "permission denied" "name resolution / DNS problem" "no space left on device" "unable to locate package" "connection refused" "package system lock" "404 not found (apt)" "network is unreachable" "no such file or directory")

match() {
  local w="$1"
  case "$w" in
    *"command not found"*) echo notfound ;;
    *"permission denied"*) echo perm ;;
    *"temporary failure in name resolution"*|*"could not resolve"*|*"name or service not known"*) echo dns ;;
    *"no space left"*) echo space ;;
    *"unable to locate package"*) echo locate ;;
    *"connection refused"*) echo refused ;;
    *"could not get lock"*|*"is locked by"*) echo lock ;;
    *"404"*|*"failed to fetch"*) echo apt404 ;;
    *"network is unreachable"*) echo unreach ;;
    *"no such file or directory"*) echo nosuch ;;
    *) echo "" ;;
  esac
}

if [ -z "$WORDS" ]; then
  t list
  i=1
  for n in "${NAMES_en[@]}"; do
    echo "  $i) $n"
    i=$((i+1))
  done
  read -r -p "> " INPUT
  case "$INPUT" in
    ''|*[!0-9]*)
      K="$(match "$(printf '%s' "$INPUT" | tr 'A-Z' 'a-z')")"
      if [ -n "$K" ]; then entry "$K"; else t hint; fi
      ;;
    *)
      if [ "$INPUT" -ge 1 ] && [ "$INPUT" -le "${#KEYS[@]}" ]; then
        entry "${KEYS[$((INPUT-1))]}"
      else
        t hint
      fi
      ;;
  esac
else
  K="$(match "$WORDS")"
  if [ -n "$K" ]; then entry "$K"; else t hint; fi
fi
SHUBHAM27_ERROR
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-error"
write_verified /usr/local/bin/shubham-phone << 'SHUBHAM27_PHONE'
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
SHUBHAM27_PHONE
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-phone"
write_verified /usr/local/bin/shubham-locker << 'SHUBHAM27_LOCKER'
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
SHUBHAM27_LOCKER
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-locker"
write_verified /usr/local/bin/shubham-record << 'SHUBHAM27_RECORD'
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
SHUBHAM27_RECORD
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-record"
write_verified /usr/local/bin/shubham-guest << 'SHUBHAM27_GUEST'
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
SHUBHAM27_GUEST
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-guest"
write_verified /usr/local/bin/shubham-clean << 'SHUBHAM27_CLEAN'
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
SHUBHAM27_CLEAN
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-clean"
write_verified /usr/local/bin/shubham-recover << 'SHUBHAM27_RECOVER'
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
SHUBHAM27_RECOVER
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-recover"
write_verified /usr/local/bin/shubham-doctor << 'SHUBHAM27_DOCTOR'
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
SHUBHAM27_DOCTOR
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-doctor"
write_verified /usr/local/bin/shubham-live << 'SHUBHAM27_LIVE'
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
SHUBHAM27_LIVE
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-live"
write_verified /usr/local/bin/shubham-ghost << 'SHUBHAM27_GHOST'
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
SHUBHAM27_GHOST
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-ghost"
write_verified /usr/local/bin/shubham-lab << 'SHUBHAM27_LAB'
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
SHUBHAM27_LAB
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-lab"
write_verified /usr/local/bin/shubham-carry << 'SHUBHAM27_CARRY'
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
SHUBHAM27_CARRY
[ $? -eq 0 ] || fail_out
echo "  OK  shubham-carry"

# --- Step 2: the tools these commands need --------------------------------
echo ""
echo "Step 2: installing the tools the commands need:"
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
  echo "Update 27 is NOT fully ready. Missing tools:$MISSING"
  echo "The 17 commands are installed, but some cannot work yet."
  echo "Connect to good internet and run this update again."
  echo "Your version was NOT changed, so the updater will offer Update 27 again."
  exit 1
fi

# --- Step 3: the internet-link tool (cloudflared) --------------------------
echo ""
echo "Step 3: the internet-link tool (cloudflared)..."
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

# --- Step 4: Google Chrome --------------------------------------------------
echo ""
echo "Step 4: Google Chrome..."
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

# --- Final check: every command must match its SHA-256 hash -----------------
echo ""
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
check_one help e4833b6498c59b0aca532578a728736c05aa6395ed7562881c46c3c93a850971
check_one netfix fb6a18de3e60f7c255f0408e2fa2791320bf415503d4e59aa46a5a317b34a8d5
check_one history dd5091a048fca4e4d2ae041259c9244dfec61ec1443da597a27030c8c77648b2
check_one wifi 37ca88c380d4cd12d4d1addfdd2afbe9b74c3813c31e9d88359c59c3ab93c1dc
check_one speed a9744e722356a0a575a362bba72d97b2fd1a90e5e9d6ef946a21747c43691cce
check_one error 96a5400470b117f0905c0a642aad797c4c68de533508294a4b47401d04ddcf51
check_one phone 717d566715b6f7167bdd9ebb2db09a5f4761b70dfc2842efcfcedf3afd7f15c7
check_one locker d992e362c4bd5ef07f257e97fee4f942aa0dd9c3f3f96c17aa038009633d18f9
check_one record c6f3ab647fed6a21222994b4f45965d1b99df16d8b67793e0c19a397caf02e2f
check_one guest fcf5283499d3d8423052f79bbcf8b44429453dbd3dc2322c12358a1d4f633448
check_one clean 1c972c08653a2fb2b4f7da6f06cf4d35d9d464e9b42b8143388a15c2850db6b5
check_one recover 22fa20b92ee84bb72541ee47293f6867f0dc92058111f6ebb5309d667101e321
check_one doctor 3a33621834976ed4a584cc564ea06124b5571cd63ee4a619038a871d994aeff9
check_one live 13df6f6e095021f90d923cbb1af2898128b7a3d50e5f7c100d50310bbe7e9cc8
check_one ghost 216eb05febe05623c3d4d90d1376b3b9540406d318ab7e915771a4c35aaf14a6
check_one lab 4365c8c026512a791fc203a1be72cf1225b2dd38fb121450d050a177537b1bef
check_one carry ae503c2b30a76eb71e67eb11c689892577b0c06a36dece7405766596c94e7b08

echo 27 > /etc/shubham-os-version
echo ""
echo "Shubham OS Update 27 done!"
echo "  - All 17 feature commands are now at their newest version,"
echo "    whichever version you were on before. Nothing is missed."
echo "  - Includes the Carry disk fix (Update 25) and the Lab fake"
echo "    OS desktop (Update 26)."
echo "  - From now on, every update is a full package like this one."
echo "Try it: run shubham-help to see all commands."
exit 0
# SHUBHAM27_END_OF_FILE
