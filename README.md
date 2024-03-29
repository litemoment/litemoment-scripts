# litemoment-scripts
 Addon scripts for litemoment video processing

reocat can merge Reolink camera SD card recordings to a single MP4 file, it's fast. Here you can find Mac/Win/Android(Termux) versions. All require ffmpeg installed as dependency.

**Mac:**

brew install ffmpeg

copy script folder to hard drive and run, read source code for options

```
chmod +x reocat.sh.command
```

**Win:**

copy script folder to hard drive

**Step 1: Confirm the Drive Letter**\
Copy the "win-reocat" directory to the hard drive of your Windows computer. Please open and edit the 10th line of the script "reocat.bat":
```batch
set "targetDir=E:\Mp4Record"
```
Change the drive letter "E:" to the letter assigned to your computer after inserting the card.

**Step 2: Insert the SD card from the grassroots veo camera and verify the correct drive letter.**\
Run "reocat.bat." Upon successful execution, a complete 4K video of the event will be generated.

ffmpeg.org for Win32 binary download and install

1. Download FFmpeg:
	- Visit the official FFmpeg website: https://ffmpeg.org/download.html
	- Scroll down to the "Windows Builds" section.
	- Click on the link for the latest build.
2. Extract the Zip File:
	- After downloading, extract the contents of the zip file to a location on your computer.
3. Add FFmpeg to System Path:
	- For convenient usage, you may want to add the path to the FFmpeg executable to your system's PATH environment variable.
	- Right-click on "This PC" or "Computer" on your desktop or in File Explorer.
	- Select "Properties."
	- Click on "Advanced system settings."
	- Click on "Environment Variables."
	- Under "System variables," find the "Path" variable and click "Edit."
	- Click "New" and add the path to the folder containing the FFmpeg executable.
4. Test FFmpeg Installation:
	- Open a new Command Prompt or PowerShell window.
	- Type ffmpeg -version and press Enter. You should see information about the FFmpeg version if the installation was successful.


**Android:** *You have to copy recording date folder to internal storage before processing

**Experimental: Now you can quickly trim video with Android without PC**
1. Install termux-reocat scripts
2. Record QR Screen Time at the beginning of video
3. Upload lite clicks to cloud after game(LiteButton, WebApp or Flic 2, watch tutorial videos)
4. Copy video from REOCAM SD card to Android
5. Run termux-reocat to trim lites in just minutes
6. Optional: You can use Google photo or other app like "Video Crop" to process trimed lites right on your phone

Android QR Screen Time Companion App APK download
https://www.litemoment.com/update/apk/QR_Screen_Time.apk

Install Termux,Termux:API,Termux:Widget (F-Droid has the official release, Play Store version is obseleted)

**Step 1: Install Termux - Note that F-Droid is the official distribution channel for Termux.**
```bash
pkg upgr
pkg install ffmpeg
termux-setup-storage
pkg install zbar
pkg install termux-api
pkg install python
pkg install opencv-python
pkg install rsync
pip install moviepy
pip install requests
pip install pyzbar
pip install ffmpeg-python
pip install jinja2

Note: --fix-missing might be needed
```

**Step 2: Create a Working Directory**
```bash
mkdir -p storage/dcim/litemoment-scripts/Mp4Record
cp -r termux-reocat storage/dcim/litemoment-scripts/
```

**Step 3: Usage Instructions**\
Copy the date directory (e.g., 2023-12-15) from the SD card's Mp4Record to the phone's storage in the directory DCIM/litemoment/Mp4Record using the system file manager. In Termux, enter:
```bash
cd storage/dcim/litemoment-scripts/termux-reocat
bash reocat.sh
```

Upon successful execution, a merged 4K video of the recordings will be generated.

