# ***********************************************************
# * Copyright (c) 2024 litemoment.com. All rights reserved. *
# ***********************************************************
# Contact: webmaster@litemoment.com

# Script Description:
# Download (account required) lites from litemoment cloud and trim video, optionally enhance brightness

# python your_script_name.py --username myusername --password mypassword --datetime_string "2024-01-26 15:00:00" --input_video "path/to/your/video.mp4"
# time python cloud_lites.py --input_video 2024-01-24.mp4
# time python cloud_lites.py --input_video 2024-01-26-20240126120744.mp4 --datetime_string "2024-01-26 12:07:44"

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

import argparse
import datetime
import requests as rq
import urllib.parse
import base64
import ffmpeg
import os
import pathlib
import sys
import platform

# Constants
CLOUDAPI_BASE = "https://rest.litemoment.com"
THREE_HOURS_IN_SECONDS = 3 * 60 * 60
MAX_NUMBER_RESULTS = 100
DEFAULT_MAP = {"LITE": "LITE", "VAR": "VAR", "HADD": "GOAL"}
DEFAULT_TO_REPETITION_TIME = 5
HINDSIGHT_POSTROLL = 10  # Assuming a value for hindsight postroll
MIN_TRIM_DURATION = 3

# Specify the path to ffmpeg and ffprobe binaries
ffmpeg_binary = 'ffmpeg'
ffprobe_binary = 'ffprobe'

# Function to generate timeline and trim videos
def generate_timeline(username, password, datetime_beginning_obj, with_event_type, hindsight, input_video):
    timestamp = datetime_beginning_obj.timestamp()

    # Generate URI
    condition = "/events?sort=-eventTS&max_results=" + str(MAX_NUMBER_RESULTS)
    b = (base64.b64encode(bytes(username + ":" + password, "utf-8"))).decode("utf-8")
    header = {"Authorization": "Basic " + b}
    where = '{"$and":[{"eventTS":{"$gte":' + str(timestamp) + '}},{"eventTS":{"$lte":' + str(timestamp + THREE_HOURS_IN_SECONDS) + "}}]}"
    where = urllib.parse.quote(where)
    url = CLOUDAPI_BASE + condition + "&where=" + where
    print("url:", url)

    # Get response
    response = rq.get(url, headers=header)
    if response.status_code != 200:
        print("Wrong Username or Password")
        return
    try:
        events = response.json()["_items"]
    except:
        print("Invalid time input")
        return

    # Generate output and trim videos
    litesArray = []
    for lite in events:
        eventType = lite["eventType"]
        eventTS = lite["eventTS"]
        diff = eventTS - timestamp - hindsight
        if diff < 0:
            diff = 0
        litesArray.append((diff, eventType, eventTS))

    # check litesArray length > 0
    if len(litesArray) < 1:
        print("No lites found from cloud, please upload and verify account info.")
        sys.exit(1)

    litesArray = list(set(i for i in litesArray))
    litesArray.sort(key=lambda x: x[0])

    # Get the total duration of the input video
    video_info = ffmpeg.probe(input_video, cmd=ffprobe_binary)
    video_duration = float(video_info['streams'][0]['duration'])

    # Create subfolder named after the basename of the input video
    input_video_basename = pathlib.Path(input_video).stem
    output_folder = f"{input_video_basename}_lites"
    os.makedirs(output_folder, exist_ok=True)

    last_time = -1
    trimmed_videos = []
    for i, (t, eventType, et) in enumerate(litesArray):
        if last_time != -1 and t - last_time <= DEFAULT_TO_REPETITION_TIME:
            continue
        last_time = t

        mappedEventType = DEFAULT_MAP.get(eventType, "")

        # Calculate the trim length (hindsight + hindsight_postroll)
        trim_length = hindsight + HINDSIGHT_POSTROLL

        # Determine the start time and duration for trimming
        start_time = t #/ 1000  # Convert milliseconds to seconds
        start_time_formated = str(datetime.timedelta(seconds=start_time))
        
        if video_duration - start_time < MIN_TRIM_DURATION:
            break
        
        duration = trim_length if start_time + trim_length < video_duration else video_duration - start_time
        # print(trim_length, video_duration, start_time, start_time + trim_length, duration, video_duration - start_time)
        # exit()

        # Trim the video using ffmpeg
        formatted_index = f"{i:03d}"  # Format index as a three-digit number
        # output_file = os.path.join(output_folder, f'trimmed_{input_video_basename}_{formatted_index}_{mappedEventType}.mp4')
        output_file = os.path.join(output_folder, f'{input_video_basename}_{formatted_index}_{mappedEventType}.mp4')
        
        # Convert eventTS timestamp to local time
        et_local_datetime = datetime.datetime.fromtimestamp(et)
        et_local_datetime_string = et_local_datetime.strftime("%Y-%m-%d %H:%M:%S")
        print(output_file, start_time, start_time_formated, duration, et_local_datetime_string)
        # exit()
        # ffmpeg -y -i trim_20231117133241.700_Larry.mp4 -vf "eq=brightness=0.2:contrast=1.2" Larry.mp4
        # Define the filter
        if args.brightness:
            print("Brightness correction set to True")
            (
                ffmpeg
                .input(input_video, ss=start_time, t=duration)
                .output(output_file, vf="eq=brightness=0.2:contrast=1.2", **{'c:a': 'copy', 'c:v': 'libx264', 'crf': 23, 'preset': 'veryfast'})
                .overwrite_output()
                # .global_args('-y')
                .run(cmd=ffmpeg_binary)
            )
        else:
            print("Brightness correction set to False")
            (
                ffmpeg
                .input(input_video, ss=start_time, t=duration)
                .output(output_file,  c='copy')
                .overwrite_output()
                # .global_args('-y')
                .run(cmd=ffmpeg_binary)
            )

        new_birthtime = et - hindsight
        change_file_timestamps(output_file, new_birthtime)
        trimmed_videos.append(output_file)

    return trimmed_videos

def change_file_timestamps(file_path, timestamp):
    if platform.system() == 'Windows':
        # For Windows, specific implementation is required for file system timestamps
        pass
    else:
        # For Unix-like systems, update the atime and mtime. ctime is updated automatically.
        os.utime(file_path, (timestamp, timestamp))

# Start of main
if __name__ == "__main__":
    # Create the parser
    parser = argparse.ArgumentParser(description='Process command line arguments.')

    # Add arguments with default values
    parser.add_argument('--username', default='myusername', help='Username for the API')
    parser.add_argument('--password', default='mypassword', help='Password for the API')
    parser.add_argument('--datetime_string', default='2024-01-24 12:01:49', help='Datetime string in the format YYYY-MM-DD HH:MM:SS')
    parser.add_argument('--input_video', default='in.mp4', help='Input video file')
    parser.add_argument('-b', '--brightness', default=False, action='store_true', help="Set brightness correction")

    # Parse the arguments
    args = parser.parse_args()

    # Use the parsed arguments
    username = args.username
    password = args.password
    datetime_string = args.datetime_string
    input_video = args.input_video
    datetime_format = '%Y-%m-%d %H:%M:%S'

    with_event_type = True 
    hindsight = 20  # Hindsight value
    trimmed_videos = generate_timeline(username, password, datetime.datetime.strptime(datetime_string, datetime_format), with_event_type, hindsight, input_video)

    print("Trimmed videos:", len(trimmed_videos), "From:",input_video)
