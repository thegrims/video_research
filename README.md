# video_research
bash scripts that were developed to automatically grab all video from plugged in USB webcams, store the videos in folders marked by the date and time of recording, and upload them to google drive once recording is complete.

## Run Description
In linux, video I/O is done through /dev/video* where * is the index of the plugged in webcam. The list of cameras goes from 0 to # of cameras plugged in -1.

The bash control script queries /dev/video* and gets a list of webcams plugged in. Then for each webcam, the script starts an instance of the ffmpeg software which streams video to a file.

When Ctrl+C is pressed, the operating system sends a SIGINT signal to the control script, which transfers to a signal handler function.

The signal handler script makes a new directory with the days time and date, moves all video files to that location, and uploads the new directory and it’s contents to Google Drive.

The script then kills off all of the ffmpeg scripts and the video recording software that they are running.

![alt text](https://raw.githubusercontent.com/osudrl/video_research/master/controlFlow.png)


## Instructions For Use
### Setup
Run `./dependency_install` to install script dependencies

For remote backups install rclone https://rclone.org/install/  
Configure for Google dive storage https://rclone.org/drive/  

In myplay, set  
`WhichDrive="someDriveName"`  

### Possible Hardware Setup Issues

#### Cable Length
Signals carried by USB cables degrade as they are carried over distance, the longer the cable, the weaker the signal. At up to 30 feet, the USB cables we used to transmit our video footage push the USB signal of video footage to the limit. The video signal is very weak. This means that USB cables longer than 30 feet will probably not work, nor will multiple 15 foot USB cables connected in sequence.

#### Electromagnetic Radiation Sources
Because of signal weakness in 30 foot cables, it means that they are subject to electromagnetic radiation from things like power transformers, which will disrupt the video signal before it reaches the computer. When planning the location of the webcams for recording CASSIE, we had to take into account EM signal disruption and mount the cameras to areas that were not affected by EM radiation from a large treadmill motor.


#### USB 3 vs 2
The USB 2.0 controller bandwidth is limited to 480 mbits per second, whereas USB 3.0 is limited to 5 gbits per second. 
We had problems testing our system until we realized that it was necessary to upgrade to a computer with a USB 3.0 controller


### Usage
Run `./myplay` to stream webcam video to video folders inside __/video__

Press `Ctrl+C` to stop recording and save

If program is not getting all possible video and audio sources, use diagnostic script `./list_video` to list out video ports, video formats, and sound sources
