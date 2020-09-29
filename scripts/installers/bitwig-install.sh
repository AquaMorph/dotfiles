#! /bin/bash

# Automatic install script for Bitwig Studio

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

site='https://www.bitwig.com/download/'
bitwig=$(sudo dnf list | grep bitwig-studio)
bitwigVersion=$(echo $bitwig | awk '{print $2;}'| filterVersion)
downloadPage=$(curl -s $site)
urlVersion=$(echo $downloadPage | filterVersion | head -n 1) # grep -Po 'Bitwig Studio \d{1,4}\.\d{1,4}\.\d{1,4}')
url=https://downloads-na.bitwig.com/stable/$urlVersion/bitwig-studio-$urlVersion.deb

checkUptoDate Bitwig $bitwigVersion $urlVersion

echo Installing Bitwig Studio $urlVersion

# Setting up and downloading package
downloadPackage bitwig $url $(basename $url)

# Converting to Fedora friendly package
echo Creating rpm package
package=$(sudo alien -r $(basename $url) | awk '{print $1;}')

# Installing package
sudo rpm -Uvh --nodeps --force $package
sudo ln -s /usr/lib64/libbz2.so.1.0** /usr/lib64/libbz2.so.1.0
