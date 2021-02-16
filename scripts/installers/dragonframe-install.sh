#! /bin/bash

# Automatic install script for Dragonframe

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

dragonframe=$(sudo dnf list | grep dragonframe)
dragonframeVersion=$(echo $dragonframe | awk '{print $2;}' | filterVersion)
url=$(curl -s https://www.dragonframe.com/downloads/ | grep .rpm | grep downloadButton | grep -Po '(?<=href=")[^"]*.rpm')
urlVersion=$(echo $url | awk -F "-" '{ print $2 }')

# Check if installed to the most recent version
checkUptoDate dragonframe $dragonframeVersion $urlVersion
echo Installing Dragonframe $urlVersion

# Setting up and downloading package
mkdir -p ~/Downloads/installers/dragonframe
cd ~/Downloads/installers/dragonframe
wget $url

# Install package
sudo dnf install $(basename $url) -y

