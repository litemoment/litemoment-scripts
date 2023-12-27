@echo off
setlocal enabledelayedexpansion

set "targetDir=E:\Mp4Record"
set "concatFile=concat.txt"
set "newestDir="

rem Ensure the target directory exists
if not exist "%targetDir%" (
    echo Target directory not found: %targetDir%
    exit /b
)

rem Use a for loop to iterate over directories in descending order of last modified timestamp
for /f "delims=" %%i in ('dir /ad /o-d /b "%targetDir%"') do (
    set "newestDir=%targetDir%\%%i"
    goto :found_newest
)

:found_newest
rem Display the newest directory
if defined newestDir (
    echo Newest directory: %newestDir%
) else (
    echo No directories found in %targetDir%
    exit /b
)

rem Find all filenames matching "RecM*.mp4" in the newest directory
if not exist "%newestDir%\RecM*.mp4" (
    echo No matching files found in %newestDir%
    exit /b
)

rem Save full file paths to concat.txt
del /q "%concatFile%" 2>nul
for %%f in ("%newestDir%\RecM*.mp4") do (
    echo file '%%~dpfNXf'>>"%concatFile%"
)

echo File paths saved to %concatFile%

rem Get the last subfolder name of the newest directory
for %%d in ("%newestDir%") do set "lastSubfolder=%%~nxd"

echo %newestDir%
echo %lastSubfolder%
set "outputFile=%lastSubfolder%_video.mp4"
echo %outputFile%

rem Run ffmpeg to concatenate the files listed in concat.txt into the specified output file
if exist "%concatFile%" (
    rem set "outputFile=%lastSubfolder%_output.mp4"
    rem echo %outputFile%
    ffmpeg -noautorotate -f concat -safe 0 -i "%concatFile%" -c copy "%outputFile%"
    echo Concatenation complete. Output saved to %outputFile%
    
    rem Delete concat.txt after processing
    del "%concatFile%"
) else (
    echo %concatFile% not found. No files to concatenate.
)

endlocal
