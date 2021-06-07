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
	updateProgram bitwig-studio ~/.config/scripts/installers/bitwig-install.sh &
	updateProgram dragonframe ~/.config/scripts/installers/dragonframe-install.sh &
	updateProgram reaper ~/.config/scripts/installers/reaper-install.sh &
	updateProgram /opt/resolve/bin/resolve ~/.config/scripts/installers/resolve-install.sh &
	updateProgram /opt/keeweb/keeweb ~/.config/scripts/installers/keeweb-install.sh &
	updateProgram yabridgectl ~/.config/scripts/installers/yabridge-install.sh &
	wait
    fi
}

dnfUpdate
aptUpdate
printf '\n'
flatpakUpdate
printf '\n'
manualUpdate
