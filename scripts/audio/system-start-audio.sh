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

# Close any active audio
killPulse

# Start up jack
cadence-session-start --system-start &
wait %1 && sleep 1
ladish_control sload studio

# Make start up reliable
killPulse
fixPulse
pulseaudio -D

# Eurorack audio interface
sh ~/.config/scripts/audio/es8start.sh 
sh ~/.config/scripts/audio/es9start.sh

launchi3
systemctl --user restart polybar
