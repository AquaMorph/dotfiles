#!/bin/bash

# Script to add another audio interface if available.

# Import library
source $(dirname $(realpath ${BASH_SOURCE[0]}))/audio-lib.sh

DEVICE_NAME='ES-9'
DEVICE_NUM=$(getCardNumber $DEVICE_NAME)
checkCard $DEVICE_NAME $DEVICE_NUM

# Rename Audio Devices

# Start up ES-5
pkill es-5-pipewire || true
/opt/es-5-pipewire/es-5-pipewire >/dev/null 2>/dev/null &
sleep 0.1
jack_connect ES-5:output "$DEVICE_NAME:playback_SL" || true
