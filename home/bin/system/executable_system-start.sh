#!/usr/bin/env bash

# Update Passwords
pass git pull

# Desktop
~/bin/connect-nas.sh
~/bin/desktop/quickshell-start.sh
systemctl --user restart streamdeck
/usr/libexec/polkit-gnome-authentication-agent-1 &

# D-Bus activation environment
dbus-update-activation-environment --all

# NextCloud sync client
nextcloud --background &
