#! /bin/bash

# Automatic install script for Dragonframe

# Program version number comparison
function versionGreater() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

dragonframe=$(dnf list | grep dragonframe)
dragonframeVersion=$(echo $dragonframe | awk '{print $2;}')
url=$(curl -s https://www.dragonframe.com/downloads/ | grep .rpm | grep downloadButton | grep -Po '(?<=href=")[^"]*.rpm')
urlVersion=$(echo $url | awk -F "-" '{ print $2 }')

# Check if installed to the most recent version
if versionGreater $dragonframeVersion $urlVersion; then
    echo Dragonframe is up to date. Installed version $dragonframeVersion Web version $urlVersion
    exit
fi
echo Installing Dragonframe $urlVersion

# Setting up and downloading package
mkdir -p ~/Downloads/installers
cd ~/Downloads/installers
wget $url

# Install package
sudo dnf install $(basename $url) -y

