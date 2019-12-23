#! /bin/bash

dotdir=~/dotfiles

#      src                                dest                   sudo
files=($dotdir/.zshrc                     ~/                     'n'
       $dotdir/alacritty                  ~/.config/             'n'
       $dotdir/g13                        ~/.config/             'n'
       $dotdir/gtk-3.0/settings.ini       ~/.config/gtk-3.0/     'n'
       $dotdir/gtk-4.0/settings.ini       ~/.config/gtk-4.0/     'n'
       $dotdir/i3                         ~/.config/             'n'
       $dotdir/i3status                   ~/.config/             'n'
       $dotdir/kitty                      ~/.config/             'n'
       $dotdir/polybar                    ~/.config/             'n'
       $dotdir/rofi                       ~/.config/             'n'
       $dotdir/scripts                    ~/.config/             'n')

# arg parser
for arg in "$@"
do
    # Skip commands that need root access
    if [[ $arg == *"-nr"* ]]; then
	noRoot=true
    fi
done

echo Setting up dotfiles...

# Loop through config files
for (( i=0; i<${#files[@]} ; i+=3 )) ; do
    # Check if sudo is needed
    pre=''
    if [[ ${files[i+2]} == *'y'* ]]; then
	if [ $noRoot ]; then
	    echo Skipping ${files[i]} because root is required
	    continue
	fi
    	pre='sudo'
    fi

    destPath=${files[i+1]}$(basename "${files[i]}")

    # Check if file already exists
    if [ -e $destPath ]; then
	# Check if path is not a sybolic link
	if ! [ -L $destPath ]; then
	    echo Backing up $destPath
	    $pre mv $destPath ${destPath}.bak
	# File already set up
	else
	    echo The file $destPath is already set up
	    continue
	fi
    # Create missing directories
    else
	$pre mkdir -p "$(dirname "$destPath")"
    fi
    echo Creating symbolic link from ${files[i]} to ${files[i+1]}
    $pre ln -sf ${files[i]} ${files[i+1]}
done
