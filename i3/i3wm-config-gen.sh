#! /bin/bash

# Load user settings from config file.
. ~/.config/settings.conf

cat ~/.config/i3/shared.conf ~/.config/i3/${computer}.conf > ~/.config/i3/config
