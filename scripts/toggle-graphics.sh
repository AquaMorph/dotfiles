#! /bin/bash

# Script to toggle graphical

defTarget=$(systemctl get-default)

if [[ $defTarget == 'graphical.target' ]]
then
    echo 'Changing default target to nongraphical shell'
    sudo systemctl set-default multi-user.target
else
    echo 'Changing default target to graphical shell'
    sudo systemctl set-default graphical.target
fi
echo
echo 'Default target changed to '$(systemctl get-default)
echo 'Please reboot for the change to take effect'
