#! /bin/bash

# Automatic install script for DaVinci Resolve

# Import library
source $(dirname ${BASH_SOURCE[0]})/install-lib.sh

versionFile=/opt/resolve/version.txt

resolveVersion=$(cat /opt/resolve/docs/ReadMe.html | grep 'DaVinci Resolve Studio' | filterVersion)
url=$(python $(dirname ${BASH_SOURCE[0]})/blackmagic-parser.py | head -n 1)
urlVersion=$(echo $url |  awk '{print $1;}')
downloadID=$(echo $url |  awk '{print $2;}')
referId=$(echo $url |  awk '{print $3;}')

# Check for beta
major=$(echo $urlVersion | cut -d. -f1)
minor=$(echo $urlVersion | cut -d. -f2)
micro=$(echo $urlVersion | cut -d. -f3)
beta=$(echo $urlVersion | cut -d. -f4)

if [ -n "$beta" ]; then
    packageName="DaVinci_Resolve_Studio_${major}.${minor}b${beta}"
else
    packageName="DaVinci_Resolve_Studio_${urlVersion}"
fi

# Get version if beta installed
if [ -n $resolveVersion ]; then
    resolveVersion=$(cat $versionFile)
fi

checkUptoDate Resolve $resolveVersion $urlVersion

downloadUrl="https://www.blackmagicdesign.com/api/register/us/download/${downloadID}"
useragent="User-Agent: Mozilla/5.0 (X11; Linux) \
                        AppleWebKit/537.36 (KHTML, like Gecko) \
                        Chrome/77.0.3865.75 \
                        Safari/537.36"
reqjson="{ \
    \"firstname\": \"Fedora\", \
    \"lastname\": \"Linux\", \
    \"email\": \"user@getfedora.org\", \
    \"phone\": \"919-555-7428\", \
    \"country\": \"us\", \
    \"state\": \"North Carolina\", \
    \"city\": \"Raleigh\", \
    \"product\": \"DaVinci Resolve\" \
}"
zipUrl="$(curl \
            -s \
            -H 'Host: www.blackmagicdesign.com' \
            -H 'Accept: application/json, text/plain, */*' \
            -H 'Origin: https://www.blackmagicdesign.com' \
            -H "$useragent" \
            -H 'Content-Type: application/json;charset=UTF-8' \
            -H "Referer: https://www.blackmagicdesign.com/support/download/${referId}/Linux" \
            -H 'Accept-Encoding: gzip, deflate, br' \
            -H 'Accept-Language: en-US,en;q=0.9' \
            -H 'Authority: www.blackmagicdesign.com' \
            -H 'Cookie: _ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294' \
            --data-ascii "$reqjson" \
            --compressed \
            "$downloadUrl")"

# Setting up and downloading package
downloadPackage resolve $zipUrl "${packageName}.zip"

# Installing package
sudo dnf install libxcrypt-compat
unzip -o $packageName
sudo ./*${packageName}*.run -i -y

# Version number backup
sudo echo $urlVersion > $versionFile

# Graphics card fix
sudo rm /etc/OpenCL/vendors/mesa.icd
sudo rm /etc/OpenCL/vendors/pocl.icd

# Keyboard mapping fix
setxkbmap -option 'caps:super'
