#!/bin/bash

# Get device id of Synaptics TrackPad
id=$(xinput list --id-only 'SynPS/2 Synaptics TouchPad')

# Enables TrackPad
trackpadEnable() {
    xinput set-prop $id "Device Enabled" 1
    exit
}

# Disables TrackPad
trackpadDisable() {
    xinput set-prop $id "Device Enabled" 0
    exit
}

# Checks for disable flag
if [ ! -z $1 ] && [ $1 == '-d' ]; then
    echo flag worked
    trackpadDisable
fi

# Convert to an arry
read -a trackPadState <<< "$(xinput --list-props $id | grep "Device Enabled")"
devEnabled=${devString_array[3]}

# Flip the state of the TrackPad
if [ ${trackPadState[3]} -eq 1 ]; then
    trackpadDisable
else
    trackpadEnable
fi
