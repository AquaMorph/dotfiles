#! /bin/bash

# Automatic install script for Reaper

# Get download url
reaperSite='https://www.reaper.fm/'
url=$reaperSite$(curl -s ${reaperSite}download.php | grep linux_x86_64 | grep -Po '(?<=href=")[^"]*')

# Setting up and downloading package
mkdir -p ~/Downloads/installers
cd ~/Downloads/installers
wget $url

# Install Reaper. Requires user input
tar -xf $(basename $url)
reaperDir=reaper_linux_x86_64
sudo sh ./$reaperDir/install-reaper.sh

# Delete extracted directory
rm -rd $reaperDir
