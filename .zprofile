sh ~/.config/scripts/install.sh -nr

if [[ $computer == 'w530' ]]; then
    if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
	exec startx
    fi
fi
