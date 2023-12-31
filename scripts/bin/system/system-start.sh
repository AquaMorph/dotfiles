#!/usr/bin/env bash

# Update Passwords
pass git pull

# Desktop
~/bin/connect-nas.sh
systemctl --user start polybar
systemctl --user restart streamdeck
waybar &
/usr/libexec/polkit-gnome-authentication-agent-1 &

# Keyring
dbus-update-activation-environment --all
/usr/bin/gnome-keyring-daemon --start --components=secrets,pkcs11,ssh

# NextCloud sync client
nextcloud --background &
