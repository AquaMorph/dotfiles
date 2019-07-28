#! /bin/bash

# Kill Pulse
pulseaudio -k

# Start up jack
cadence-session-start --system-start
ladish_control sload Working7-27-19

# Dumb hack to make audio setup right
for i in {1..10}
do
    pulseaudio -k
    sleep 0.1
    pulseaudio -D
done

# Start up music player
sleep .1 && i3-msg 'workspace 10; exec google-play-music-desktop-player'
