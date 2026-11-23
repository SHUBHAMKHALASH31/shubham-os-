#!/bin/bash
# Shubham OS Update 10 — removes the welcome voice (greeting) completely.
# Deletes the greeting autostart entry, the player script and the sound file.
# Nothing else is touched. Runs as root via pkexec, on Live and installed systems.
echo "Shubham OS Update 10 (remove welcome voice) is being applied..."

rm -f /etc/xdg/autostart/shubham-greeting.desktop
rm -f /usr/local/bin/shubham-greeting
rm -f /usr/share/shubham-os/greeting.wav

echo 10 > /etc/shubham-os-version
echo "Shubham OS Update 10 done! The welcome voice has been removed."
