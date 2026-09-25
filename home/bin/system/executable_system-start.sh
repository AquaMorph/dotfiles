#!/usr/bin/env bash

# Update Passwords
pass git pull

# Desktop
~/bin/connect-nas.sh
if [ "${XDG_SESSION_TYPE}" = "wayland" ]; then
  ~/bin/desktop/quickshell-start.sh
else
  systemctl --user start polybar
fi
systemctl --user restart streamdeck
/usr/libexec/polkit-gnome-authentication-agent-1 &

# Keyring
dbus-update-activation-environment --all
/usr/bin/gnome-keyring-daemon --start --components=secrets,pkcs11,ssh

# NextCloud sync client
nextcloud --background &
