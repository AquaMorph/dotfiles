#!/bin/bash

# Script to add another audio interface if available.

# Import library
source $(dirname ${BASH_SOURCE[0]})/audio-lib.sh

DEVICE_NAME='ES-9'
DEVICE_NUM=$(getCardNumber $DEVICE_NAME)
checkCard $DEVICE_NAME $DEVICE_NUM

# Start up audio interface
alsa_in -d hw:$DEVICE_NUM -j "$DEVICENAME In" -c 16 -q 1 &
alsa_out -d hw:$DEVICE_NUM -j "$DEVICENAME Out" -c 16 -q 1 &
