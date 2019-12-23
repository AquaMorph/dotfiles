#! /bin/bash

dotdir=~/dotfiles

# src dest sudo
files=($dotdir/.zshrc ~/ 'n' \
       ${dotdir}/alacritty/alacritty.yml ~/.config/alacritty/ 'n'
       ${dotdir}/g13 ~/.config/ 'n')

echo Setting up dotfiles...

# Loop through config files
for (( i=0; i<${#files[@]} ; i+=3 )) ; do
    # Check if sudo is needed
    pre=''
    if [[ ${files[i+2]} == *'y'* ]]; then
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
    else
	echo $pre mkdir -p "$(dirname "$destPath")"
    fi
    echo Creating symbolic link from ${files[i]} to ${files[i+1]}
    $pre ln -sf ${files[i]} ${files[i+1]}
done
