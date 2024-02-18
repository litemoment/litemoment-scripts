#!/bin/bash
# ***********************************************************
# * Copyright (c) 2024 litemoment.com. All rights reserved. *
# ***********************************************************
# Contact: webmaster@litemoment.com

# Script Description:
# Run ffmpeg concat demuxer 5 mins REOCAM files into one 4k video.

# Steps:
# 1. bash reocat.sh
# 2. bash qrtime.sh videos
# 3. bash trimlites.sh videos

# Navigate to the directory of the current script
cd -- "$(dirname "$BASH_SOURCE")"
# Display the current working directory
pwd

# SDUSB is the folder under Android's DCIM used for storing SD card recordings
SDNAME="litemoment-scripts"
MOUNTPATH="../.."
# Define the output directory
OUTPUTDIR="videos"
# Boolean flag to track if datetime_string from filename
filename_datetime_set=false

# where to find ffmpeg
export PATH=$PATH:~/LitemomentV5/.meta/utils/ffmpeg/

# Discover the newest folder under the specified path
VIDEOPATH=$(ls -td $MOUNTPATH/$SDNAME/Mp4Record/* | head -1)
echo "Newest video path is: $VIDEOPATH"
VIDEODIR="$(basename "$VIDEOPATH")"
echo "Discovered folder name: $VIDEODIR"

# Ask user for confirmation to proceed
while true; do
    read -rp "Proceed with folder '$VIDEODIR'?, t for time of REOCAM filename (y/n/t): " yn
    yn=$(echo "$yn" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase using tr

    if [ "$yn" = "y" ]; then
        break
    elif [ "$yn" = "t" ]; then
		filename_datetime_set=true
        break
    elif [ "$yn" = "n" ]; then
        echo "Available folders:"
        ls -1 $MOUNTPATH/$SDNAME/Mp4Record/
        while true; do
            read -rp "Enter the name of the folder you wish to use(ctrl+c to exit): " user_input
            if [ -d "$MOUNTPATH/$SDNAME/Mp4Record/$user_input" ]; then
                VIDEODIR=$user_input
                echo "Selected folder: $VIDEODIR"
                break
            else
                echo "Folder does not exist, please try again."
            fi
        done
        break
    else
        echo "Please answer y or n."
    fi
done

VIDEOFILENAME="$VIDEODIR"

# Check if OUTPUTDIR exists, create it if not
if [ ! -d "$OUTPUTDIR" ]; then
  echo "Creating directory: $OUTPUTDIR"
  mkdir -p "$OUTPUTDIR"
fi

# Define the input directory based on video directory
IN_DIR="$MOUNTPATH/$SDNAME/Mp4Record/$VIDEODIR"
# Create a list file for concatenating videos
CONCAT_LIST="concat-list-$VIDEODIR.txt"

# Check if the input directory exists
if [ -d "$IN_DIR" ]; then
  echo "$IN_DIR exists."
  
  # Check if datetime_string is set correctly
  if $filename_datetime_set; then
	  
	  # Find all MP4 files in the newest folder and sort them
	  mp4_files=($(ls "$IN_DIR"/*.mp4 | sort))

	  # Check if there are any MP4 files
	  if [ ${#mp4_files[@]} -eq 0 ]; then
	      echo "No MP4 files found in the newest folder."
	      exit 1
	  fi

	  # Extract the datetime string from the first MP4 file's name
	  filename="${mp4_files[0]##*/}" # Extract filename from path
	  if [[ $filename =~ ^RecM02_([0-9]{8})_([0-9]{6}) ]]; then
	      datetime_string="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
	      echo "Datetime string extracted: $datetime_string"
		  VIDEOFILENAME="$VIDEODIR-$datetime_string"
	  else
	      echo "No MP4 files found or filename format is incorrect."
	      exit 1
	  fi

      echo "Datetime string has been set to $datetime_string"
  else
      echo "Datetime string was not set."
  fi

  # Loop through each video file and append it to the list
  for f in ${IN_DIR}/RecM*.mp4; do 
    echo "file '$f'" >> $CONCAT_LIST
  done

  # Concatenate videos using ffmpeg and output to the specified directory
  ffmpeg -y -noautorotate -safe 0 -f concat -i $CONCAT_LIST -c copy $OUTPUTDIR/$VIDEOFILENAME.mp4

  # Remove the temporary list file after concatenation
  rm "$CONCAT_LIST"
else
  echo "Directory $IN_DIR not found."
fi
