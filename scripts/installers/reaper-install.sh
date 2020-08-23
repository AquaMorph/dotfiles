#! /bin/bash

# Automatic install script for Reaper

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

# Get download url
reaperVersion=$(head /opt/REAPER/whatsnew.txt |  grep -Go '[0-9]\.[0-9][0-9]')
reaperSite='https://www.reaper.fm/'
downloadPage=$(curl -s ${reaperSite}download.php)
urlVersion=$(echo "$downloadPage" | grep -A 2 'Linux x86_64' | grep -Go '[0-9]\.[0-9][0-9]')
url=$reaperSite$(echo "$downloadPage" | grep linux_x86_64 | grep -Po '(?<=href=")[^"]*')

checkUptoDate Reaper $reaperVersion $urlVersion

# Setting up and downloading package
mkdir -p ~/Downloads/installers
cd ~/Downloads/installers
wget $url

# Install Reaper. Requires user input
tar -xf $(basename $url)
reaperDir=reaper_linux_x86_64
sudo sh ./$reaperDir/install-reaper.sh --install /opt --integrate-sys-desktop --usr-local-bin-symlink

# Delete extracted directory
rm -rd $reaperDir
