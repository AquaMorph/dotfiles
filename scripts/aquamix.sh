#!/bin/bash

# Script to manuage audio mixing the the main audio interface.

# Import library
source $(dirname ${BASH_SOURCE[0]})/audio-lib.sh

INTERFACE_NAME='Scarlett 18i20'
INTERFACE_NUM=$(getCardNumber $INTERFACE_NAME)

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
    setMonoOne $1 $2 $3
    setMonoTwo $1 $2 $3
    setMonoThree $1 $2 $3
    setStereoOne $1 $2 $3
    setStereoTwo $1 $2 $3
}

setInstruments $ZERO_DB
setMic $MUTE
setComputerAudio $ZERO_DB
