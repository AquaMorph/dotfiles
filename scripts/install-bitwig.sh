#! /bin/bash

# Automatic install script for Bitwig Studio

# Program version number comparison
function versionGreater() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

bitwig=$(dnf list | grep bitwig-studio)
bitwigVersion=$(echo $bitwig | awk '{print $2;}')
url=$(curl -s https://www.bitwig.com/en/download.html | grep .deb | grep -Po '(?<=href=")[^"]*.deb')
urlVersion=$(echo $url | awk -F "-" '{ print $3 }' | rev | cut -f 2- -d '.' | rev)

# Check if installed to the most recent version
if versionGreater $bitwigVersion $urlVersion; then
    echo Bitwig is up to date. Installed version $bitwigVersion Web version $urlVersion
    exit
fi
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
