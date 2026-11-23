#!/bin/bash
# Shubham OS Update 14 - menu fix, part 2.
# Update 13 put the "Shubham OS Special Features" section into the system
# menu file, but the section stayed hidden: the Kali menu file has a
# Layout list near the top that names every section allowed to show,
# and the new section was not in that list. This update adds the section
# name to that Layout list. A backup is made first and the file is
# checked after the change; if the check fails, the original is kept.
# Nothing else is touched. Runs as root via pkexec.
echo "Shubham OS Update 14 (menu fix, part 2) is being applied..."

python3 << 'SHUBHAM_PY_14'
import os, shutil, sys
import xml.etree.ElementTree as ET

TARGET = "/etc/xdg/menus/xfce-applications.menu"
MENUNAME = "<Menuname>Shubham OS Special Features</Menuname>"

if not os.path.exists(TARGET):
    print("PROBLEM: menu file not found. Nothing was changed.")
    sys.exit(1)

with open(TARGET, encoding="utf-8", errors="replace") as fh:
    data = fh.read()

try:
    ET.fromstring(data)
except Exception as e:
    print("PROBLEM: the menu file could not be read (%s). Nothing was changed." % e)
    sys.exit(1)

if "Shubham OS Special Features" not in data:
    print("PROBLEM: the section from Update 13 is missing. Nothing was changed.")
    sys.exit(1)

if MENUNAME in data:
    print("The section is already in the show list.")
    sys.exit(0)

pos = data.find("</Layout>")
if pos == -1:
    print("PROBLEM: no Layout list found in the menu file. Nothing was changed.")
    sys.exit(1)

backup = TARGET + ".bak-shubham14"
if not os.path.exists(backup):
    shutil.copy2(TARGET, backup)

newdata = data[:pos] + MENUNAME + "\n" + data[pos:]
try:
    ET.fromstring(newdata)
except Exception as e:
    print("PROBLEM: the changed menu file failed its check (%s). Original kept." % e)
    sys.exit(1)

tmp = TARGET + ".tmp-shubham14"
with open(tmp, "w", encoding="utf-8") as fh:
    fh.write(newdata)
os.replace(tmp, TARGET)
print("Section added to the show list in: " + TARGET)
SHUBHAM_PY_14
PYRC=$?
if [ "$PYRC" -ne 0 ]; then
  echo "Shubham OS Update 14 FAILED at the menu step. Your old version is kept."
  exit 1
fi

echo "Checking the result..."
if grep -q "<Menuname>Shubham OS Special Features</Menuname>" /etc/xdg/menus/xfce-applications.menu; then
  echo "  OK  the section is in the show list"
else
  echo "  PROBLEM  the section is not in the show list"
  echo "Shubham OS Update 14 FAILED. Your old version is kept."
  exit 1
fi

echo 14 > /etc/shubham-os-version
echo "Shubham OS Update 14 done! Restart the system, then open the menu."
