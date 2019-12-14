#! /bin/bash

# Kill Pulse
pulseaudio -k

# Start up jack
cadence-session-start --system-start &
wait %1
ladish_control sload studio

# Dumb hack to make audio setup right
for i in {1..8}
do
    pulseaudio -k
    sleep 0.1
    pulseaudio -D
done

sh ~/.config/scripts/start-es-8.sh 

# Start up programs that use audio
sleep .1 && i3-msg 'workspace 10; exec google-play-music-desktop-player'
sleep .1 && i3-msg 'workspace 5; exec firefox'
