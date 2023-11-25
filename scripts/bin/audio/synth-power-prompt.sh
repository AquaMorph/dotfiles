#!/usr/bin/env sh

# Script to bring up a prompt to set synth power state.

current='Keep current state'
off='Power synths off'
on='Power synths on'
selected=$(echo -e "${current}\n${off}\n${on}" | rofi -dmenu -p \
	   'Change synth power' -theme ~/.config/rofi/themes/aqua)

if [ "$selected" == "$off" ]; then
    python ~/.config/scripts/audio/synth-power.py -o
elif [ "$selected" == "$on" ]; then
    python ~/.config/scripts/audio/synth-power.py -d
fi
