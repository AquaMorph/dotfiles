#!/usr/bin/env bash

# Automatic install script for SuperSlicer.

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

function desktopFile() {
    echo 'Creating desktop file'
    echo '[Desktop Entry]' > $1
    echo "Name=${2}" >> $1
    echo 'Comment=3D printing slicer' >> $1
    echo "Exec=${3}" >> $1
    echo 'Icon=' >> $1
    echo 'Type=Application' >> $1
    echo 'Terminal=false' >> $1
}

program='SuperSlicer'
programPath="${HOME}/.local/bin/${program}.AppImage"
programVersion=$($programPath --help | grep SuperSlicer | filterVersion)
url=$(curl -s https://api.github.com/repos/supermerill/SuperSlicer/releases)
urlVersion=$(echo $url | grep tag_name | filterVersion | head -n 1)
url=$(echo "$url" | grep browser_download | grep ubuntu | head -n 1 | \
	  tr -d '"'| awk '{print $2}')

# Check if installed to the most recent version
checkUptoDate $program $programVersion $urlVersion
echo Installing $program $urlVersion

# Setting up and downloading package
cd $(dirname $programPath)
rm $programPath
wget $url -O $program.AppImage
chmod +x $programPath

# Create desktop file
desktopPath="${HOME}/.local/share/applications/${program}.desktop"
if [ ! -f $desktopPath ]; then
    desktopFile $desktopPath $program $programPath
fi
