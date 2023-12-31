#!/bin/bash
# ***********************************************************
# * Copyright (c) 2023 litemoment.com. All rights reserved. *
# ***********************************************************
# Contact: webmaster@litemoment.com

cd -- "$(dirname "$BASH_SOURCE")"
pwd

# SDUSB is the folder under your Android DCIM to store SD card recordings
SDNAME="SDUSB"
MOUNTPATH="../.."

# if allow user input for dir name, uncomment below 2 lines
# echo "folder name? example: 2023-12-06"
# read VIDEODIR

# if use newest dir name, uncomment below 4 lines
VIDEOPATH=$(ls -td $MOUNTPATH/$SDNAME/Mp4Record/* | head -1)
echo "Video path is $VIDEOPATH"
VIDEODIR="$(basename "$VIDEOPATH")"
echo "folder name is $VIDEODIR"

IN_DIR="$MOUNTPATH/$SDNAME/Mp4Record/$VIDEODIR";
CONCAT_LIST="concat-list-$VIDEODIR.txt"

if [ -d "$IN_DIR" ]; then
  echo "$IN_DIR does exist."
  for f in ${IN_DIR}/RecM*.mp4; do echo "file '$f'" >> $CONCAT_LIST; done
  ffmpeg -noautorotate -safe 0 -f concat -i $CONCAT_LIST -c copy $VIDEODIR.mp4
  rm "$CONCAT_LIST"
else
  echo "$IN_DIR not found."
fi
