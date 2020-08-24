#! /bin/bash

# Automatic install script for Bitwig Studio

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

bitwig=$(sudo dnf list | grep bitwig-studio)
bitwigVersion=$(echo $bitwig | awk '{print $2;}'| filterVersion)
url=$(curl -s https://www.bitwig.com/en/download.html | grep .deb | grep -Po '(?<=href=")[^"]*.deb')
urlVersion=$(echo $url | awk -F "-" '{ print $3 }' | rev | cut -f 2- -d '.' | rev)

checkUptoDate Bitwig $bitwigVersion $urlVersion

echo Installing Bitwig Studio $urlVersion

# Setting up and downloading package
mkdir -p ~/Downloads/installers
cd ~/Downloads/installers
wget $url

# Converting to Fedora friendly package
echo Creating rpm package
package=$(sudo alien -r $(basename $url) | awk '{print $1;}')

# Installing package
sudo rpm -Uvh --nodeps --force $package
sudo ln -s /usr/lib64/libbz2.so.1.0** /usr/lib64/libbz2.so.1.0
