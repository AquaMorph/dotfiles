#! /bin/bash

if [[ $* == *-b* ]]; then
    cp /etc/hosts ~/.config/.dotfiles/hosts
else
    sudo cp ~/.config/.dotfiles/hosts /etc/hosts
fi
       
