#!/usr/bin/env bash

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

sudo $(packageManager) install sway waybar rofi mako alacritty
