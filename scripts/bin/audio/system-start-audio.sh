#! /bin/bash

# Kill Pulse.
function killPulse() {
    systemctl --user stop pulseaudio.socket
    systemctl --user stop pulseaudio.service
    pulseaudio -k
    killall pulseaudio
}

# Start Pulseaudio properly.
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

# Start up programs that use audio.
function launchi3() {
    if [ -z "$skipi3" ]; then
	echo Opening i3wm sound workspaces
	sleep .1 && i3-msg 'workspace 5; exec firefox'
	sleep 5.1 && python ~/bin/start-firefox.py
    fi
}

# Set up sinks.
function setupSinks() {
    pactl set-default-sink speakers
    pactl set-default-source sm7b
}

# Connect sinks to audio interface
function connectSinks() {
    pw-link speakers:monitor_FL alsa_output.usb-Focusrite_Clarett__8Pre_00002325-00.pro-output-0:playback_AUX0
    pw-link speakers:monitor_FR alsa_output.usb-Focusrite_Clarett__8Pre_00002325-00.pro-output-0:playback_AUX1

    pw-link alsa_input.usb-Focusrite_Clarett__8Pre_00002325-00.pro-input-0:capture_AUX3 sm7b:input_FL
    pw-link alsa_input.usb-Focusrite_Clarett__8Pre_00002325-00.pro-input-0:capture_AUX3 sm7b:input_FR
    return $?
}

function renameInterface() {
    for n in `seq 0 17` ; do
	jack_property -p -s "alsa:pcm:2:hw:2,0:capture:capture_${n}" http://jackaudio.org/metadata/pretty-name "capture_$((n+1))"
    done
    for n in `seq 0 19` ; do
	jack_property -p -s "alsa:pcm:2:hw:2,0:playback:playback_${n}" http://jackaudio.org/metadata/pretty-name "playback_$((n+1))"
    done
    for n in `seq 0 19` ; do
	jack_property -p -s "alsa:pcm:2:hw:2,0:playback:monitor_${n}" http://jackaudio.org/metadata/pretty-name "monitor_$((n+1))"
    done
}

# arg parser
for arg in "$@"
do
    # Skip commands for i3wm
    if [[ $arg == *"-s"* ]]; then
	skipi3=true
    fi
done

# Wire sinks
setupSinks
connectSinks
status=$?
while [[ $status -eq 0 ]]; do
    echo "Connecting Sinks"
    connectSinks
    status=$?
    sleep 1
done

# Rename Audio Devices
#renameInterface

# Eurorack audio interface
sh ~/bin/audio/es9start.sh

launchi3
systemctl --user restart polybar
