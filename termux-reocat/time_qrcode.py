# ***********************************************************
# * Copyright (c) 2024 litemoment.com. All rights reserved. *
# ***********************************************************
# Contact: webmaster@litemoment.com

# Script Description:
# Use zbar to detect QR from video frames

# python time_qrcode.py --file_name noqr.mp4

# F-Driod
# Termux
# Termux:Widget
# Termux:API

# Termux console
# pkg install zbar
# pkg install termux-api
# pkg install ffmpeg
# pkg install python
# pkg install opencv-python
# pip install moviepy
# pip install requests
# pip install pyzbar
# pip install ffmpeg-python

import cv2
import argparse
from datetime import datetime, timedelta
import platform
# import subprocess
import time
from pyzbar import pyzbar
# thrun off warning from c lib
import os
import sys
import ctypes

# Function to redirect stderr
def redirect_stderr(to=os.devnull):
    # Flush Python's STDERR buffer
    sys.stderr.flush()

    # Duplicate the file descriptor for the target file
    # and overwrite STDERR's file descriptor.
    with open(to, 'wb') as target:
        ctypes.CDLL(None).dup2(target.fileno(), sys.stderr.fileno())

# Use this function to suppress all output to stderr
redirect_stderr()


MAX_RETRIES = 3
datetime_format = "%m/%d/%Y %H:%M:%S"

# Function to check if the string is a valid datetime in the specified format
def is_valid_datetime(string, format):
    try:
        # Attempt to convert the string to a datetime object using the specified format
        datetime.strptime(string, format)
        return True  # Conversion successful, valid datetime string
    except ValueError:
        return False  # Conversion failed, not a valid datetime string


def main():
    args = parse_arguments()
    if not os.path.exists(args.file_name):
        return "Error: MP4 file does not exist."

    cap = cv2.VideoCapture(args.file_name)
    qr_detector = cv2.QRCodeDetector()
    frame_count = 0
    time_per_frame = 1000 / cap.get(cv2.CAP_PROP_FPS)  # Time per frame in milliseconds
    # result = "qrnotfound"
    result = "Error: QR not found in the beginning of video."
    qr_time_found = False

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret or (frame_count * time_per_frame) > args.process_length * 60000:
            break

        if frame_count % args.every_n_frames == 0:
            frame = scale_frame(frame, args.scale_percentage)

            retries = 0
            success = False
            # Convert frame to grayscale for QR code detection
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            while retries < MAX_RETRIES and not success:
                try:
                    # data, bbox, _ = qr_detector.detectAndDecode(frame)
                    # Detect QR codes
                    barcodes = pyzbar.decode(gray)
                    success = True
                except cv2.error as e:
                    print("An error occurred:", e)
                    retries += 1
                    # Optionally, wait before retrying
                    time.sleep(1)
    
            if success:
                for barcode in barcodes:
                    # Print QR content and current video play time in milliseconds
                    qr_content = barcode.data.decode("utf-8")
                    # Check if the QR content is a valid datetime string in the specified format
                    if is_valid_datetime(qr_content, datetime_format):
                        # print(f"'{qr_content}' is a valid datetime string in the format {datetime_format}.")
                        detected_datetime = datetime.strptime(qr_content, datetime_format)
                        new_birthtime = detected_datetime - timedelta(milliseconds=frame_count * time_per_frame)
                        change_file_timestamps(args.file_name, new_birthtime)
                        result = new_birthtime.strftime("%Y-%m-%d %H:%M:%S")
                        # print("result:[", result, "]")
                        qr_time_found = True
                        break
                    else:
                        # print(f"'{qr_content}' is not a valid datetime string in the format {datetime_format}.")
                        # check next code in same frame
                        pass
                
                if qr_time_found:
                    break

            else:
                # print("Failed to process frame, moving to the next one...")
                pass

        frame_count += 1

    cap.release()
    return result


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file_name", type=str, default="qr-fail.mp4")
    parser.add_argument("--process_length", type=int, default=10)  # in minutes
    parser.add_argument("--every_n_frames", type=int, default=6)
    parser.add_argument("--scale_percentage", type=int, default=25)
    return parser.parse_args()

def scale_frame(frame, scale_percent):
    width = int(frame.shape[1] * scale_percent / 100)
    height = int(frame.shape[0] * scale_percent / 100)
    return cv2.resize(frame, (width, height))

def is_datetime_string(data):
    try:
        datetime.strptime(data, "%m/%d/%Y %H:%M:%S")
        return True
    except ValueError:
        return False
        
def modify_mp4_metadata(input_file, output_file, date_time):
    # FFmpeg command to set metadata
    ffmpeg_command = [
        "ffmpeg", "-y",
        "-hide_banner",  # Hide FFmpeg banner
        "-loglevel", "panic",  # Suppress console output
        "-i", input_file,
        "-metadata", f"creation_time={date_time}",
        "-c", "copy",
        output_file
    ]

    try:
        # Run the FFmpeg command without console output
        subprocess.run(ffmpeg_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # print(f"Metadata set successfully for {output_file}")
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")

def change_file_timestamps(file_path, new_time):
    timestamp = new_time.timestamp()
    # formatted_time = new_time.strftime("%Y-%m-%dT%H:%M:%S")
    # print(formatted_time)

    if platform.system() == 'Windows':
        # For Windows, specific implementation is required for file system timestamps
        pass
    else:
        # For Unix-like systems, update the atime and mtime. ctime is updated automatically.
        os.utime(file_path, (timestamp, timestamp))


if __name__ == "__main__":
    # main()
    print(main())

