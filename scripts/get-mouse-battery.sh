#! /bin/bash

mouseState=$(upower -i /org/freedesktop/UPower/devices/mouse_hidpp_battery_0)
batteryPercentage=$(echo $mouseState | grep percentage | grep -Po '\d+%')
charging=$(echo $mouseState | grep 'state: charging')

if [ ! -z "$charging" ]; then
    echo Charging
else
    echo $batteryPercentage
fi
