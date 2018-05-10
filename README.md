# video_research
bash scripts being developed for VLC camera automation

## Instructions For Use
### Setup
Run `./dependency_install` to install script dependencies

For remote backups install rclone https://rclone.org/install/  
Configure for Google dive storage https://rclone.org/drive/  


In myplay, set  
`WhichDrive="someDriveName"`  

### Usage
Run `./myplay` to stream webcam video to video folders inside __/video__  

If program is not getting all possible video and audio sources, use diagnostic script `./list_video` to list out video ports, video formats, and sound sources
