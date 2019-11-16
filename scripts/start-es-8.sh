#!/bin/bash

# Script to add another audio interface if available.

DEVICENAME='ES-8'
DEVICENUM="$(cat /proc/asound/cards | grep -m 1 $DEVICENAME | grep -o '[0-9]' | head -1)"

if test -z "$DEVICENUM"
   then
       echo $DEVICENAME not connected
       exit 1
   else
       echo $DEVICENAME found at hw:$DEVICENUM
fi

# Start up audio interface
alsa_in -d hw:$DEVICENUM -j "$DEVICENAME In" &
alsa_out -d hw:$DEVICENUM -j "$DEVICENAME Out" &
