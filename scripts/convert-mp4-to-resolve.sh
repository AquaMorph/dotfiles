#! /bin/bash

# Create backup directory
mkdir -p ./converted

# Convert files
for file in *.mp4 *.MP4; do
    ffmpeg -i $file -acodec pcm_s16le -vcodec copy ./converted/${file%%.*}.mov
done
