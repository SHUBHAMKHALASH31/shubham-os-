#!/bin/bash
# Shubham OS Update 12 - Batch 1 FIX.
# Update 11 put the menu files in place, but the six feature commands arrived
# empty (0 bytes) on some systems because they were downloaded one by one.
# This update carries every file INSIDE itself - nothing is downloaded -
# and it checks the size of every file at the end. If any file is empty,
# the update reports failure and keeps the old version number.
# Nothing else is touched. Runs as root via pkexec.
echo "Shubham OS Update 12 (Batch 1 fix) is being applied..."
cat > /usr/local/bin/shubham-help << 'SHUBHAM_EMBED_0'
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
SHUBHAM_EMBED_0
chmod 755 /usr/local/bin/shubham-help
cat > /usr/local/bin/shubham-netfix << 'SHUBHAM_EMBED_1'
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
SHUBHAM_EMBED_1
chmod 755 /usr/local/bin/shubham-netfix
cat > /usr/local/bin/shubham-history << 'SHUBHAM_EMBED_2'
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
SHUBHAM_EMBED_2
chmod 755 /usr/local/bin/shubham-history
cat > /usr/local/bin/shubham-wifi << 'SHUBHAM_EMBED_3'
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
SHUBHAM_EMBED_3
chmod 755 /usr/local/bin/shubham-wifi
cat > /usr/local/bin/shubham-speed << 'SHUBHAM_EMBED_4'
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
SHUBHAM_EMBED_4
chmod 755 /usr/local/bin/shubham-speed
cat > /usr/local/bin/shubham-error << 'SHUBHAM_EMBED_5'
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
SHUBHAM_EMBED_5
chmod 755 /usr/local/bin/shubham-error
mkdir -p /usr/share/applications /usr/share/desktop-directories /etc/xdg/menus/applications-merged
cat > /usr/share/applications/shubham-netfix.desktop << 'SHUBHAM_DESK_0'
[Desktop Entry]
Type=Application
Name=Net Fix
Comment=Fix internet problems in one click
Exec=xfce4-terminal --hold -e shubham-netfix
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_0
cat > /usr/share/applications/shubham-history.desktop << 'SHUBHAM_DESK_1'
[Desktop Entry]
Type=Application
Name=History File
Comment=Save all terminal commands in one txt file
Exec=xfce4-terminal --hold -e shubham-history
Icon=utilities-terminal
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_1
cat > /usr/share/applications/shubham-wifi.desktop << 'SHUBHAM_DESK_2'
[Desktop Entry]
Type=Application
Name=WiFi Password
Comment=Show a saved WiFi password
Exec=xfce4-terminal --hold -e shubham-wifi
Icon=network-wireless
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_2
cat > /usr/share/applications/shubham-speed.desktop << 'SHUBHAM_DESK_3'
[Desktop Entry]
Type=Application
Name=Net Speed
Comment=Check internet speed
Exec=xfce4-terminal --hold -e shubham-speed
Icon=utilities-system-monitor
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_3
cat > /usr/share/applications/shubham-error.desktop << 'SHUBHAM_DESK_4'
[Desktop Entry]
Type=Application
Name=Error Guide
Comment=Understand any error in simple words
Exec=xfce4-terminal --hold -e shubham-error
Icon=dialog-information
Terminal=false
Categories=X-Shubham-Special;
SHUBHAM_DESK_4
cat > /usr/share/desktop-directories/shubham-special.directory << 'SHUBHAM_DIR_1'
[Desktop Entry]
Type=Directory
Name=Shubham OS Special Features
Comment=Special tools of Shubham OS
Icon=applications-system
SHUBHAM_DIR_1
cat > /etc/xdg/menus/applications-merged/shubham-special.menu << 'SHUBHAM_MENU_1'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>Shubham OS Special Features</Name>
    <Directory>shubham-special.directory</Directory>
    <Include>
      <Category>X-Shubham-Special</Category>
    </Include>
  </Menu>
</Menu>
SHUBHAM_MENU_1

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi

echo "Checking every file..."
FAIL=0
for f in shubham-help shubham-netfix shubham-history shubham-wifi shubham-speed shubham-error; do
  if [ -s "/usr/local/bin/$f" ]; then
    echo "  OK  $f ($(stat -c%s "/usr/local/bin/$f") bytes)"
  else
    echo "  PROBLEM  $f is missing or empty"
    FAIL=1
  fi
done
for f in shubham-netfix.desktop shubham-history.desktop shubham-wifi.desktop shubham-speed.desktop shubham-error.desktop; do
  if [ -s "/usr/share/applications/$f" ]; then
    echo "  OK  $f"
  else
    echo "  PROBLEM  $f is missing or empty"
    FAIL=1
  fi
done

if [ "$FAIL" -ne 0 ]; then
  echo "Shubham OS Update 12 FAILED - some files did not install. Your old version is kept. Please try again."
  exit 1
fi

echo 12 > /etc/shubham-os-version
echo "Shubham OS Update 12 done! All Batch 1 commands are installed and checked."
echo "Type shubham-help in a terminal to see all commands."
