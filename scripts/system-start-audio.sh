#! /bin/bash

# Kill Pulse
pulseaudio -k

# Start up jack
cadence-session-start --system-start &
wait %1
ladish_control sload Working7-29-19

# Dumb hack to make audio setup right
for i in {1..8}
do
    pulseaudio -k
    sleep 0.1
    pulseaudio -D
done

# Start up eurorack interface
alsa_in -d hw:1 &
alsa_out -d hw:1 &

# Start up music player
sleep .1 && i3-msg 'workspace 10; exec google-play-music-desktop-player'
