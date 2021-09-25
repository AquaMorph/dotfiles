#! /bin/bash

# Kill Pulse
function killPulse() {
    systemctl --user stop pulseaudio.socket
    systemctl --user stop pulseaudio.service
    pulseaudio -k
    killall pulseaudio
}

# Start Pulseaudio properly
function fixPulse() {
    PULSE="$(alsamixer 2>&1 | killall alsamixer)"
    if [[ $PULSE == *'Connection refused'* ]]; then
	echo 'Fixing Pulseaudio'
	killPulse
	sleep 0.1
	pulseaudio -D
	fixPulse
    else
	echo 'Pulseaudio is working correctly'
    fi
}

# Start up programs that use audio
function launchi3() {
    if [ -z "$skipi3" ]; then
	echo Opening i3wm sound workspaces
	sleep .1 && i3-msg 'workspace 5; exec firefox'
	sleep 8 && python ~/.config/scripts/start-firefox.py
    fi
}

# arg parser
for arg in "$@"
do
    # Skip commands for i3wm
    if [[ $arg == *"-s"* ]]; then
	skipi3=true
    fi
done

sleep 0.1

# Create sinks
pactl load-module module-null-sink sink_name=speakers
pactl load-module module-null-sink sink_name=mic
pactl set-default-sink speakers

# Wire sinks
sleep 2
pw-link -o && pw-link -i
pw-link speakers:monitor_FL alsa_output.usb-Focusrite_Scarlett_18i20_USB-00.pro-output-0:playback_AUX0
pw-link speakers:monitor_FR alsa_output.usb-Focusrite_Scarlett_18i20_USB-00.pro-output-0:playback_AUX1

pw-link alsa_input.usb-Focusrite_Scarlett_18i20_USB-00.pro-input-0:capture_AUX3 mic:playback_FL
pw-link alsa_input.usb-Focusrite_Scarlett_18i20_USB-00.pro-input-0:capture_AUX3 mic:playback_FR

# Eurorack audio interface
sh ~/.config/scripts/audio/es8start.sh 
sh ~/.config/scripts/audio/es9start.sh

launchi3
systemctl --user restart polybar
