#! /bin/bash

# Kill Pulse
function killPulse() {
    pulseaudio -k
    killall pulseaudio
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
wait %1
ladish_control sload studio

# Make start up reliable
for i in {1..8}; do
    killPulse
    pulseaudio -D
done

# Eurorack audio interface
sh ~/.config/scripts/start-es-8.sh 

# Start up programs that use audio
if [ -z "$skipi3" ]; then
    echo Opening i3wm sound workspaces
    sleep .1 && i3-msg 'workspace 10; exec google-play-music-desktop-player'
    sleep .1 && i3-msg 'workspace 5; exec firefox'
fi
