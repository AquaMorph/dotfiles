#! /bin/bash

# Automatic install script for yabridge an audio bridge for linux.

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

# Install wine if not already installed
if ! command -v wine &> /dev/null; then
    if command -v dnf &> /dev/null; then
	sudo dnf config-manager --add-repo \
	     https://dl.winehq.org/wine-builds/fedora/36/winehq.repo
    fi
    sudo $(packageManager) install winehq-staging
fi

program=yabridgectl
programVersion=$(yabridgectl --help | filterVersion)
url=$(curl -s https://github.com/robbert-vdh/yabridge/releases/ | grep .tar.gz \
    | grep -v ubuntu | grep -Po '(?<=href=")[^"]*.tar.gz'| head -n 1)
url='https://github.com'$url
urlVersion=$(echo $url | filterVersion | head -n 1)

# Check if installed to the most recent version
checkUptoDate $program $programVersion $urlVersion
echo Installing $program $urlVersion

# Setting up and downloading package
mkdir -p ~/Downloads/installers/${program}
cd ~/Downloads/installers/${program}
wget $url

# Install package
tar -xvzf *${urlVersion}.tar.gz
rm -rd ~/.local/share/yabridge
mv ./yabridge ~/.local/share/
sudo rm /bin/yabridgectl
sudo ln -s ~/.local/share/yabridge/yabridgectl /bin/yabridgectl
