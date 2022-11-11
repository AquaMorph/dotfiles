#!/bin/bash

# Script to manuage audio mixing the the main audio interface.

# Import library
source $(dirname ${BASH_SOURCE[0]})/audio-lib.sh

INTERFACE_NAME='Clarett+ 8Pre'
INTERFACE_NUM=$(getCardNumber $INTERFACE_NAME)
checkCard "$INTERFACE_NAME" "$INTERFACE_NUM"

# Sets the volume levels of the first mono instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setMonoOne() {
    setMono $INTERFACE_NUM 1 $1 $2 $3
}

# Sets the volume levels of the second mono instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setMonoTwo() {
    setMono $INTERFACE_NUM 2 $1 $2 $3
}

# Sets the volume levels of the third mono instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setMonoThree() {
    setMono $INTERFACE_NUM 3 $1 $2 $3
}

# Sets the volume levels of the first stereo instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setStereoOne() {
    setStereo $INTERFACE_NUM 5 $1 $2 $3
}

# Sets the volume levels of the second stereo instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setStereoTwo() {
    setStereo $INTERFACE_NUM 7 $1 $2 $3
}

# Sets the volume levels of the third stereo instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setStereoThree() {
    setStereo $INTERFACE_NUM 9 $1 $2 $3
}

# Sets the volume levels of the fourth stereo instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setStereoFour() {
    setStereo $INTERFACE_NUM 11 $1 $2 $3
}

# Sets the volume levels of the fifth stereo instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setStereoFive() {
    setStereo $INTERFACE_NUM 13 $1 $2 $3
}

# Sets the volume levels of the sixth stereo instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setStereoSix() {
    setStereo $INTERFACE_NUM 15 $1 $2 $3
}



# Sets the volume levels of the studio microphone.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setMic() {
    setMono $INTERFACE_NUM 4 $1 $2 $3
}

# Sets the volume levels of the computer.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setComputerAudio() {
    setStereo $INTERFACE_NUM 17 $1 $2 $3
}

# Sets the volume levels of all instrument.
#
# $1 monitor volume
# $2 first headphone volume
# $3 second headphone volume
function setInstruments() {
    setMonoOne     $1 $2 $3
    setMonoTwo     $1 $2 $3
    setMonoThree   $1 $2 $3
    setStereoOne   $1 $2 $3
    setStereoTwo   $1 $2 $3
    setStereoThree $1 $2 $3
    setStereoFour  $1 $2 $3
    setStereoFive  $1 $2 $3
    setStereoSix   $1 $2 $3
}

function DAWMode() {
    setInstruments $MUTE
    setMic $MUTE
    setComputerAudio $ZERO_DB
}

function NormalMode() {
    setInstruments $ZERO_DB
    setMic $MUTE
    setComputerAudio $ZERO_DB
}

function PrintHelp() {
    echo AquaMixer
    echo '-h --help    print out help options'
    echo '-d --daw     set interface to DAW mode'
    echo '-n --normal  set interface to normal mode'
    exit 0
}

for var in "$@"; do
    if [ $var == '-h' ] || [ $var == '--help' ]; then
	PrintHelp
    elif [ $var == '-d' ] || [ $var == '--daw' ]; then
	DAWMode
    elif [ $var == '-n' ] || [ $var == '--normal' ]; then
	NormalMode
    fi
done

