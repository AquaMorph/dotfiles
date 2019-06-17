#! /bin/bash

# Load user settings from config file.
. ~/.config/i3/settings.conf

cat ~/.config/i3/shared.conf ~/.config/i3/${computer}.conf > ~/.config/i3/config

i3-msg restart
