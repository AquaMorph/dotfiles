#!/bin/bash

# Script to add another audio interface if available.

DEVICE_NAME='ES-8'
DEVICE_NUM=$(getCardNumber $DEVICE_NAME)
checkCard $DEVICE_NAME $DEVICE_NUM

# Start up audio interface
alsa_in -d hw:$DEVICENUM -j "$DEVICENAME In" -q 1 &
alsa_out -d hw:$DEVICENUM -j "$DEVICENAME Out" -q 1 &
