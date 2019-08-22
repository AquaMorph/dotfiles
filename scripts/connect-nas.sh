#! /bin/bash

# Load user settings from config file.
. ~/.config/settings.conf

if nc -z $nasip 80 2>/dev/null; then
    mount /mnt/share/lNAS
else
    echo "$nasip is unreachable"
fi
