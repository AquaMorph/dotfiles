#! /bin/bash

# Automatic install script for Bitwig Studio

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

site='https://www.bitwig.com/download/'
bitwig=$(searchProgramInstalled bitwig-studio)
bitwigVersion=$(echo $bitwig | awk '{print $2;}'| filterVersion)
urlVersion=$(curl -sL $site | grep 'Bitwig Studio' | filterVersion | head -n 1)
url=https://downloads.bitwig.com/stable/$urlVersion/bitwig-studio-$urlVersion.deb

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
