# Mix names
MONITOR_LEFT='A'
MONITOR_RIGHT='B'
HEADPHONE_01_LEFT='C'
HEADPHONE_01_RIGHT='D'
HEADPHONE_02_LEFT='E'
HEADPHONE_02_RIGHT='F'
BLANK_LEFT="G"
BLANK_RIGHT='H'

# Level constants
MUTE='0'
ZERO_DB='0db'

# Formats a number to match the matrix numbering.
function formatMatrixNum() {
    printf "%02d" $1
}

# Returns audio card number with matching card name.
function getCardNumber() {
    echo $(cat /proc/asound/cards | grep -m 1 $1 | grep -Po '\d{1,2}' | head -1)
}

# Checks if the card exists and if not exits.
#
# $1 card name
# $2 card number
function checkCard() {
    if [ -z "$2" ]; then
	echo $1 not connected
	exit 1
    else
	echo $1 found at hw:$2
    fi
}

# Prints a list of all controls for the given sound card.
function printControls() {
    amixer -c $1 controls
}

# Sets a mix to a level.
#
# $1 card number
# $2 matrix number
# $3 mix channel
function setMix() {
    amixer -c $1 set "Mix $3 Input $(formatMatrixNum $2)" $4
}


# Sets the volume levels for a mono mix.
#
# $1 card number
# $2 matrix number
# $3 mix left channel
# $4 mix right channel
# $5 volume
function setMonoMix() {
    setMix $1 $2 $3 $5
    setMix $1 $2 $4 $5
}

# Sets the volume levels for a stereo mix.
#
# $1 card number
# $2 matrix number
# $3 mix left channel
# $4 mix right channel
# $5 volume
function setStereoMix() {
    matrix=$2
    setMix $1 $matrix       $3 $5
    setMix $1 $matrix       $4 $MUTE
    setMix $1 $((matrix+1)) $3 $MUTE
    setMix $1 $((matrix+1)) $4 $5
}


# Sets the volume levels for a mono mix for several outputs.
#
# $1 card number
# $2 matrix number
# $3 mix left channel
# $4 mix right channel
# $5 monitor volume
# $6 first headphone volume
# $7 second headphone volume
function setMono() {
    monitor=$3
    headphone1=$4
    headphone2=$5
    if [ -n $headphone1 ]; then headphone1=$monitor; fi
    if [ -n $headphone2 ]; then headphone2=$monitor; fi
    setMonoMix $1 $2 $MONITOR_LEFT      $MONITOR_RIGHT      $monitor
    setMonoMix $1 $2 $HEADPHONE_01_LEFT $HEADPHONE_01_RIGHT $headphone1
    setMonoMix $1 $2 $HEADPHONE_02_LEFT $HEADPHONE_02_RIGHT $headphone2
    setMonoMix $1 $2 $BLANK_LEFT        $BLANK_RIGHT        $MUTE
}

# Sets the volume levels for a stereo mix for several outputs.
#
# $1 card number
# $2 matrix number
# $3 mix left channel
# $4 mix right channel
# $5 monitor volume
# $6 first headphone volume
# $7 second headphone volume
function setStereo() {
    monitor=$3
    headphone1=$4
    headphone2=$5
    if [ -n $headphone1 ]; then headphone1=$monitor; fi
    if [ -n $headphone2 ]; then headphone2=$monitor; fi
    setStereoMix $1 $2 $MONITOR_LEFT      $MONITOR_RIGHT      $monitor
    setStereoMix $1 $2 $HEADPHONE_01_LEFT $HEADPHONE_01_RIGHT $headphone1
    setStereoMix $1 $2 $HEADPHONE_02_LEFT $HEADPHONE_02_RIGHT $headphone2
    setStereoMix $1 $2 $BLANK_LEFT        $BLANK_RIGHT        $MUTE
}
