sh ~/.config/scripts/setup.sh -nr

# Load user settings from config file.
. ~/.config/settings.conf

if [[ $computer == 'w530' ]]; then
    if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
	exec startx
    fi
fi
