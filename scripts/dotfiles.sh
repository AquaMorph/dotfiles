#! /bin/bash

# source backup sudo
files=(~/.zshrc ~/.config/.dotfiles/.zshrc 'n')

echo Setting up dotfiles

for (( i=0; i<${#files[@]} ; i+=3 )) ; do
    # Check if sudo is needed
    pre=''
    if [[ ${files[i+2]} == *'y'* ]]; then
	pre='sudo'
    fi
    if [ -f ${files[i]} ]; then
	if ! [ -L ${files[i]} ]; then
	    echo Backing up ${files[i+1]}
	    ${pre} rm ${files[i]}.bak
	    ${pre} mv ${files[i]} ${files[i]}.bak
	fi
    fi
    if [[ $* == *-b* ]]; then
	cp ${files[i]} ${files[i+1]}
    else
	${pre} ln -sf ${files[i+1]} ${files[i]}
    fi
done
