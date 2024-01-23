#! /bin/bash

# Automatic install script for Dragonframe

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

# Fix issue with shared library files.
function postInstallFix() {
  sudo rm /opt/dragonframe2024/lib/libtiff.so.5
  sudo rm /opt/dragonframe2024/lib/libudev.so.0
  sudo ln -s -f /lib64/libudev.so.1 /opt/dragonframe2024/lib/libudev.so.0
}

dragonframe=$(searchProgramInstalled dragonframe20* | \
		  awk 'END {print $(NF-2), $(NF-1), $NF}')
dragonframeVersion=$(echo $dragonframe | awk '{print $2;}' | filterVersion)
url=$(curl -s https://www.dragonframe.com/downloads/ \
	   -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:104.0) Gecko/20100101 Firefox/104.0" | \
	  grep .rpm | grep downloadButton | grep downloadButton | \
	  grep -io 'https://[a-z0-9+-._/]*.rpm' | head -n 1)
urlVersion=$(echo $url | awk -F "-" '{ print $2 }')

# Check if installed to the most recent version
checkUptoDate dragonframe $dragonframeVersion $urlVersion
echo Installing Dragonframe $urlVersion

# Setting up and downloading package
mkdir -p ~/Downloads/installers/dragonframe
cd ~/Downloads/installers/dragonframe
wget $url

# Install package
sudo dnf install $(basename "$url") -y

