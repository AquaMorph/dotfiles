#! /bin/bash

# Automatic install script for KeeWeb password manager

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

keeweb=$(searchProgramInstalled KeeWeb)
keewebVersion=$(echo $keeweb | awk '{print $2;}' | filterVersion)
url=$(curl -s https://github.com/keeweb/keeweb/releases | grep .rpm | grep -Po '(?<=href=")[^"]*.rpm'| head -n 1)
url='https://github.com'$url
urlVersion=$(echo $url | filterVersion | head -n 1)

# Check if installed to the most recent version
checkUptoDate keeweb $keewebVersion $urlVersion
echo Installing KeeWeb $urlVersion

# Setting up and downloading package
mkdir -p ~/Downloads/installers
cd ~/Downloads/installers
wget $url

# Install package
sudo dnf install $(basename $url) -y

