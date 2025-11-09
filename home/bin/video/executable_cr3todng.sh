#! /bin/bash

# Script to convert CR3 files to DNG.

WINE_PREFIX=$(echo $HOME/.dng-wine)
CONVERTER_PATH='C:\Program Files\Adobe\Adobe DNG Converter\Adobe DNG Converter.exe'
FLAGS='-c -fl -p1'

# Converts foreward slashes to back slashes.
function foreward2Back() {
    sed 's:/:\\:g'
}

# Converts a directory path a wine friendly path.
function dir2Wine() {
    echo 'z:'"$(echo $( cd "$1" >/dev/null 2>&1 ; pwd -P ) | foreward2Back)"
}

# Converts file path to a wine friendly path to the file.
function file2Wine() {
    echo $(dir2Wine $(dirname $1))\\$(basename $1)
}

# Converts a CR3 RAW file to DNG RAW.
function convertFile() {
    WINEPREFIX="$WINE_PREFIX" wine "$CONVERTER_PATH" \
    $FLAGS $2 "$(file2Wine $1)" &
}

# Converts all CR3 RAW files in a directory to DNG RAW.
function convertDir() {
    for file in $1*.cr3; do
	convertFile $file "-d $2"
    done
}

start=`date +%s%N`

src=$1
dst=$(dir2Wine $2)

if [[ -d $src ]]; then
    convertDir $src $dst
elif [[ -f $src ]]; then
    convertFile $src $dst
else
    echo "$src is not valid"
    exit 1
fi

wait
end=`date +%s%N`
echo Execution time was `expr $end - $start` nanoseconds.
