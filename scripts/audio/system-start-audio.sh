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
	sleep 6 && python ~/.config/scripts/start-firefox.py
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

sleep .35

# Wire sinks
pactl set-default-sink speakers
pactl set-default-source sm7b
sleep .35
pw-link -o && pw-link -i
pw-link speakers:monitor_FL alsa_output.usb-Focusrite_Scarlett_18i20_USB-00.multichannel-output:playback_FL
pw-link speakers:monitor_FR alsa_output.usb-Focusrite_Scarlett_18i20_USB-00.multichannel-output:playback_FR

pw-link alsa_input.usb-Focusrite_Scarlett_18i20_USB-00.multichannel-input:capture_RR sm7b:input_FL
pw-link alsa_input.usb-Focusrite_Scarlett_18i20_USB-00.multichannel-input:capture_RR sm7b:input_FR

# Rename Audio Devices
for n in `seq 0 17` ; do
    jack_property -p -s "alsa:pcm:2:hw:2,0:capture:capture_${n}" http://jackaudio.org/metadata/pretty-name "capture_$((n+1))"
done
for n in `seq 0 19` ; do
    jack_property -p -s "alsa:pcm:2:hw:2,0:playback:playback_${n}" http://jackaudio.org/metadata/pretty-name "playback_$((n+1))"
done
for n in `seq 0 19` ; do
    jack_property -p -s "alsa:pcm:2:hw:2,0:playback:monitor_${n}" http://jackaudio.org/metadata/pretty-name "monitor_$((n+1))"
done

# Eurorack audio interface
sh ~/.config/scripts/audio/es9start.sh

launchi3
systemctl --user restart polybar
