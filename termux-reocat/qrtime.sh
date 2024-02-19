#!/bin/bash
# ***********************************************************
# * Copyright (c) 2024 litemoment.com. All rights reserved. *
# ***********************************************************
# Contact: webmaster@litemoment.com

# Script Description:
# Run python time_qrcode.py to detect QR time from video stream, save to meta and basename, optional call trim script.

# bash qrtime.sh videos/2024-01-26.mp4
# bash qrtime.sh videos

# where to find ffmpeg
export PATH=$PATH:~/LitemomentV5/.meta/utils/ffmpeg/

# Function to check if string exists in filename
string_in_filename() {
    local string="$1"
    local filename="$2"

    # Extract filename without extension
    local name="${filename%.*}"

    # Check if the string exists in the filename
    if [[ $name == *"$string"* ]]; then
        return 0  # String found in filename
    else
        return 1  # String not found in filename
    fi
}

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
read -p "Do you want to continue with this file? (y/n): " -r

# Check user input
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # User chose yes
    folder_path=$(dirname "$file_to_process")
    base_name=$(basename "$file_to_process")
    echo "Changing directory to: $folder_path"
    cd "$folder_path" || { echo "Failed to change directory."; exit 1; }
    echo "Current directory: $(pwd)"
    echo "Basename: $base_name"
    echo "Full Path: $file_to_process"

	# Run the Python script and capture its output
	echo "Detecting QR time from video, wait..."
	input_file="$base_name"
	output=$(python ../time_qrcode.py --file_name "$input_file")

	# Check for errors
	if [[ $output == "Error:"* ]]; then
	    echo $output
	    exit 1
	fi

	output_clean=$(echo $output | sed -e 's/[^A-Za-z0-9._]//g')

	# echo $output
	# echo $output_clean
	
	# Skip new file creation if this is processed already
	if string_in_filename "$output_clean" "$input_file"; then
	    echo "Timestamp '$output_clean' is present in filename '$input_file' before the extension."
		echo "Use existing file $input_file"
		new_file_name="$input_file"
	else
	    echo "Timestamp '$output_clean' is not present in filename '$input_file' before the extension."
		# Rename the file based on the script's output
		new_file_name="${input_file%.*}-$output_clean.mp4"

		ffmpeg -i "$input_file" -metadata "creation_time=$output" -c copy "$new_file_name"

		# mv "$input_file" "$new_file_name"
		if [ -e "$new_file_name" ]; then
		    echo "New file $new_file_name generated."
		    # rm "$input_file"
		else
		    echo "Sigh, did not work."
		fi

		echo "File saved to $new_file_name"
	fi

	echo "Have you uploaded lites to cloud account? (y/n)"
	read response

	# Convert response to lowercase for case-insensitive comparison
	response_lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')

	if [ "$response_lower" == "y" ]; then
	    echo "You chose to proceed."
		echo "Downloading cloud lites, wait..."
	    # Run logic for "yes" response
		python ../cloud_lites.py --input_video $new_file_name --datetime_string "$output"
		# Check the return code of the Python script
		if [ $? -ne 0 ]; then
		    echo "Error: Cloud script failed."
		else
		    echo "Cloud script ran successfully."
			echo "To update media gallery, run:"
			# Get the base name of the file without extension
			base_name=$(basename "$new_file_name" .mp4)
			# Define the scan folder name
			scan_folder_name="${base_name}_lites"
			echo "termux-media-scan -v -r ${scan_folder_name}"
			termux-media-scan -v -r ${scan_folder_name}
		fi
	elif [ "$response_lower" == "b" ]; then
	    echo "You chose to proceed with brightness correction."
		echo "Downloading cloud lites, wait..."
	    # Run logic for "yes" response
		python ../cloud_lites.py --input_video $new_file_name --datetime_string "$output" -b
		# Check the return code of the Python script
		if [ $? -ne 0 ]; then
		    echo "Error: Cloud script failed."
		else
		    echo "Cloud script ran successfully."
			echo "To update media gallery, run:"
			# Get the base name of the file without extension
			base_name=$(basename "$new_file_name" .mp4)
			# Define the scan folder name
			scan_folder_name="${base_name}_lites"
			echo "termux-media-scan -v -r ${scan_folder_name}"
			termux-media-scan -v -r ${scan_folder_name}
		fi
	elif [ "$response_lower" == "n" ]; then
	    echo "You chose not to proceed."
	    # Run logic for "no" response
		echo "upload lites to your cloud account and run:"
		echo "cd $folder_path&&python ../cloud_lites.py --input_video $new_file_name --datetime_string \"$output\";cd .."
	else
	    echo "Invalid response. Please enter 'y' or 'n'."
	    # Run logic for invalid response
		echo "upload lites to your cloud account and run:"
		echo "cd $folder_path&&python ../cloud_lites.py --input_video $new_file_name --datetime_string \"$output\";cd .."
	fi

else
    # User chose no or other input
    echo "Operation cancelled."
    exit 0
fi

