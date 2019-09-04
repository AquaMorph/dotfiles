#! /bin/bash

# source backup sudo
files=(~/.zshrc ~/.config/.dotfiles/.zshrc 'n')

for (( i=0; i<${#files[@]} ; i+=3 )) ; do
    if [[ $* == *-b* ]]; then
	cp ${files[i]} ${files[i+1]}
    else
	if [[ ${files[i+2]} == *'y'* ]]; then
	    sudo cp ${files[i+1]} ${files[i]}
	else
	    cp ${files[i+1]} ${files[i]}
	fi
    fi
done
