#! /bin/bash

# Load user settings from config file.
. ~/.config/settings.conf

for file in *.aax; do
    convertedFile="./${file%%.*}.m4b"
    if [ ! -f "$convertedFile" ]; then
	ffmpeg -y -activation_bytes ${activation_bytes} -i ./${file} -codec copy $convertedFile
    fi
done
