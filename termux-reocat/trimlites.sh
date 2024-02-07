#!/bin/bash
# ***********************************************************
# * Copyright (c) 2024 litemoment.com. All rights reserved. *
# ***********************************************************
# Contact: webmaster@litemoment.com

# Script Description:
# Read datetime and call python cloud_lites.py to download lites and trim

# bash trimlites.sh videos
# bash trimlites.sh videos/20240126.mp4
# bash trimlites.sh videos/2024-01-26-20240126120744.mp4

# Check if an argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <mp4_filename_or_directory_path>"
    exit 1
fi

input_path="$1"

if [ -f "$input_path" ]; then
    # It's a file, check if it's an mp4
    if [[ $input_path == *.mp4 ]]; then
        # Check if file exists
        if [ ! -e "$input_path" ]; then
            echo "File not found: $input_path"
            exit 1
        fi
        # Set the file to process
        file_to_process="$input_path"
    else
        echo "The provided file is not an mp4 file."
        exit 1
    fi
elif [ -d "$input_path" ]; then
    # It's a directory, check if it exists and find the newest mp4 file
    # Mac
    # newest_file=$(find "$input_path" -maxdepth 1 -type f -name '*.mp4' -exec stat -f "%m %N" {} \; | sort -rn | head -n 1 | cut -d' ' -f2-)
	# Termux
	newest_file=$(find "$input_path" -maxdepth 1 -type f -name '*.mp4' -print0 | xargs -0 ls -t | head -n 1)
	
    if [ -z "$newest_file" ]; then
        echo "No mp4 files found in the directory."
        exit 1
    fi
    file_to_process="$newest_file"
else
    echo "Invalid input: Not a valid file or directory."
    exit 1
fi

# Show the file to process and ask the user if they want to continue with this file
echo "File to process: $file_to_process"

# Extract basename without extension
basename=$(basename "$file_to_process" .mp4)

# Use '-' as separator to get the last part as a datetime string
datetime_str=$(echo "$basename" | awk -F '-' '{print $NF}')

# Check if the datetime string is 14 characters long
if [ ${#datetime_str} -ne 14 ]; then
    echo "Invalid datetime format in filename"
    exit 1
fi

# Extract and validate each part of the datetime string
year=${datetime_str:0:4}
month=${datetime_str:4:2}
day=${datetime_str:6:2}
hour=${datetime_str:8:2}
minute=${datetime_str:10:2}
second=${datetime_str:12:2}

# Validate the datetime components
is_valid_date() {
    [ "$1" -ge 1 ] && [ "$1" -le 31 ] && [ "$2" -ge 1 ] && [ "$2" -le 12 ] && [ "$3" -ge 0 ] && [ "$3" -le 23 ] && [ "$4" -ge 0 ] && [ "$4" -le 59 ] && [ "$5" -ge 0 ] && [ "$5" -le 59 ]
}

if ! is_valid_date $day $month $hour $minute $second; then
    echo "Invalid datetime components in filename"
    exit 1
fi

# Reconstruct the datetime in 'YYYY-MM-DD HH:MM:SS' format
formatted_datetime="$year-$month-$day $hour:$minute:$second"

# Display filename and formatted datetime string
echo "Filename: $file_to_process"
echo "Datetime: $formatted_datetime"


read -p "Do you want to continue with this file, b for brightness correction? (y/n/b): " -r

# Check user input
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # User chose yes
    echo "You chose to proceed."
	echo "Downloading cloud lites, wait..."
    folder_path=$(dirname "$file_to_process")
    base_name=$(basename "$file_to_process")
    echo "Changing directory to: $folder_path"
    cd "$folder_path" || { echo "Failed to change directory."; exit 1; }
    echo "Current directory: $(pwd)"
    echo "Basename: $base_name"
    echo "Full Path: $file_to_process"
	echo "Datetime: $formatted_datetime"
    # Run logic for "yes" response
	python ../cloud_lites.py --input_video $base_name --datetime_string "$formatted_datetime"
	# Check the return code of the Python script
	if [ $? -ne 0 ]; then
	    echo "Error: Cloud script failed."
	else
	    echo "Cloud script ran successfully."
		echo "To update media gallery, run:"
		# Get the base name of the file without extension
		base_name=$(basename "$base_name" .mp4)
		# Define the scan folder name
		scan_folder_name="${base_name}_lites"
		echo "termux-media-scan -v -r ${scan_folder_name}"
		termux-media-scan -v -r ${scan_folder_name}
	fi
elif [[ $REPLY =~ ^[Bb]$ ]]; then
    # User chose brightness correction
    echo "You chose to proceed with brightness correction."
	echo "Downloading cloud lites, wait..."
    folder_path=$(dirname "$file_to_process")
    base_name=$(basename "$file_to_process")
    echo "Changing directory to: $folder_path"
    cd "$folder_path" || { echo "Failed to change directory."; exit 1; }
    echo "Current directory: $(pwd)"
    echo "Basename: $base_name"
    echo "Full Path: $file_to_process"
	echo "Datetime: $formatted_datetime"
    # Run logic for "yes" response
	python ../cloud_lites.py --input_video $base_name --datetime_string "$formatted_datetime" -b
	# Check the return code of the Python script
	if [ $? -ne 0 ]; then
	    echo "Error: Cloud script failed."
	else
	    echo "Cloud script ran successfully."
		echo "To update media gallery, run:"
		# Get the base name of the file without extension
		base_name=$(basename "$base_name" .mp4)
		# Define the scan folder name
		scan_folder_name="${base_name}_lites"
		echo "termux-media-scan -v -r ${scan_folder_name}"
		termux-media-scan -v -r ${scan_folder_name}
	fi
else
    # User chose no or other input
    echo "Operation cancelled."
    exit 0
fi
