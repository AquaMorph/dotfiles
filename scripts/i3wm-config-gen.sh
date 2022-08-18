#! /bin/bash

# Load user settings from config file.
. ~/.config/settings.conf

cat ~/.config/i3/shared.conf ~/.config/i3/${computer}.conf > ~/.config/i3/config

if command -v i3-msg &> /dev/null; then
    i3-msg reload
elif command -v swaymsg &> /dev/null; then
    swaymsg reload
fi
