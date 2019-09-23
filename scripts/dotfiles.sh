#! /bin/bash

# source backup sudo
files=(~/.zshrc ~/.config/.dotfiles/.zshrc 'n')

for (( i=0; i<${#files[@]} ; i+=3 )) ; do
    if [ -f ${files[i+1]} ]; then
	if [[ ${files[i+2]} == *'y'* ]]; then
	    rm ${files[i]}.bak
	    sudo mv ${files[i]} ${files[i]}.bak
	else
	    rm ${files[i]}.bak
	    mv ${files[i]} ${files[i]}.bak
	fi
    fi
    if [[ $* == *-b* ]]; then
	cp ${files[i]} ${files[i+1]}
    else
	if [[ ${files[i+2]} == *'y'* ]]; then
	    sudo ln -sf ${files[i+1]} ${files[i]}
	else
	    ln -sf ${files[i+1]} ${files[i]}
	fi
    fi
done
