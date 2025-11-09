#!/bin/bash

# Stop all waybar instances
killall -q waybar
while pgrep -x waybar >/dev/null; do sleep 0.1; done

waybar &
