#! /bin/bash

# This script is a catch all program updater.

# Chezmoi Updater
function chezmoiUpdate {
    if command -v chezmoi &> /dev/null; then
	echo Updating chezmoi dotfiles...
	chezmoi update || return $?
        if [[ "$(uname -s)" == "Darwin" ]]; then
          # SIGUSR2 reloads Ghostty's config without terminating it; ignore if not running.
          pkill -USR2 -x ghostty || [[ $? -eq 1 ]]
        fi
    fi
}

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
	sudo apt update && sudo apt upgrade
    fi
}

# Flatpack Updater
function flatpakUpdate {
    if command -v flatpak &> /dev/null; then
	echo Updating Flatpak...
	flatpak uninstall --unused && flatpak update
    fi
}

# Appimage Updater
function appimageUpdate {
    if command -v am &> /dev/null; then
	echo Updating AppImages...
	am update
    fi
}

# Homebrew Updater
function brewUpdate {
    if command -v brew &> /dev/null; then
	echo Updating Homebrew...
	brew update && brew upgrade
    fi
}

# Pass Repository Updater
function passUpdate {
    if [ -d "$HOME/.password-store/.git" ] && [ -d "$HOME/.password-store" ]; then
        echo Updating pass repository...
        git -C "$HOME/.password-store" pull
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

update_failed=0

# Report failures while allowing the remaining updaters to run.
function run_updater {
  if ! "$1"; then
    echo "Updater failed: $1" >&2
    update_failed=1
  fi
}

run_updater chezmoiUpdate
echo ''
run_updater brewUpdate
run_updater dnfUpdate
run_updater aptUpdate
echo ''
run_updater flatpakUpdate
echo ''
run_updater appimageUpdate
echo ''
run_updater manualUpdate
echo ''
run_updater passUpdate

exit "$update_failed"
