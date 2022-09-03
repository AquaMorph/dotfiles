#!/bin/bash

# Stop all polybar instances
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.1; done

for monitor in $(xrandr -q | grep -e "\sconnected\s" | cut -d' ' -f1); do
    if [ $monitor == 'DP-2' ] || [ $monitor == 'LVDS-1' ]; then
	MONITOR=$monitor polybar aqua &
    fi
done


