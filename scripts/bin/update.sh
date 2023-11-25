#! /bin/bash

# This script is a catch all program updater.

# DNF Updater
function dnfUpdate {
    if command -v dnf &> /dev/null; then
	echo Updating DNF...
	sudo dnf update #--exclude=wine*
    fi
}

# Apt Updater
function aptUpdate {
    if command -v apt &> /dev/null; then
	echo Updating APT...
	sudo apt update
	sudo apt upgrade
    fi
}

# Flatpack Updater
function flatpakUpdate {
    if command -v flatpak &> /dev/null; then
	echo Updating Flatpak...
	flatpak uninstall --unused
	flatpak update
    fi
}

# Checks if a program is installed and if it is runs an updater script
function updateProgram {
    if command -v $1 &> /dev/null; then
	sh $2
    fi
}

# Manually installed programs updater
function manualUpdate {
    if command -v dnf &> /dev/null; then
	echo Updating manually installed programs...
	SCRIPT_PATH="$HOME/bin/installers"
	updateProgram bitwig-studio $SCRIPT_PATH/bitwig-install.sh &
	updateProgram /opt/dragonframe5/bin/Dragonframe $SCRIPT_PATH/dragonframe-install.sh &
	updateProgram reaper $SCRIPT_PATH/reaper-install.sh &
	updateProgram /opt/resolve/bin/resolve $SCRIPT_PATH/resolve-install.sh &
	updateProgram /opt/keeweb/keeweb $SCRIPT_PATH/keeweb-install.sh &
	updateProgram yabridgectl $SCRIPT_PATH/yabridge-install.sh &
	wait
    fi
}

dnfUpdate
aptUpdate
echo ''
flatpakUpdate
echo ''
manualUpdate
