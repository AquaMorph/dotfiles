#!/bin/bash

# Script to add another audio interface if available.

# Import library
source $(dirname $(realpath ${BASH_SOURCE[0]}))/audio-lib.sh

DEVICE_NAME='ES-9'
DEVICE_NUM=$(getCardNumber $DEVICE_NAME)
checkCard $DEVICE_NAME $DEVICE_NUM

# Start up audio interface
alsa_in -d hw:$DEVICE_NUM -j "$DEVICE_NAME In" -c 16 -q 1 &
alsa_out -d hw:$DEVICE_NUM -j "$DEVICE_NAME Out" -c 16 -q 1 &
pkill es5jack || true
~/.cargo/bin/es5jack >/dev/null 2>/dev/null &
sleep 0.1
jack_connect es-5:out "$DEVICE_NAME Out:playback_9" || true
