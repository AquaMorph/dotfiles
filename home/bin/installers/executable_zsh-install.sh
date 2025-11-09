#!/usr/bin/env bash

# Install and set zsh as the default shell.

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

sudo $(packageManager) install zsh
chsh -s $(which zsh)
