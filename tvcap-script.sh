#!/bin/bash
#
#  tvcap-script by Andreas Schalk, easycap.blogspot.com (Dec. 2011)
#  This script is based an a template TV-script from Jose Catre-Vandis (Jan 2006).
#  The ascii artwork is based on a template i found here: http://www.retrojunkie.com/asciiart/electron/tv.txt
#  Contact: easycapdc60-blogspot@yahoo.de
#-----------------------------------------------------------------------------
#
#  FUNCTION: This script provides Zenity menues for viewing an capturing video with a tv-card on Linux.
#
#  Supported programs: MPlayer, MEncoder, VLC, Tvtime, Cheese und Sox
#
#-----------------------------------------------------------------------------
#
#  Basic options:
#
#  Change the following parameters for viewing/ capturing according to your needs
#
#-----------------------------------------------------------------------------
VERBOSE=1   # if '0', this script does not show messages window and does not ask for norm and input number anymore
NORM="PAL"  # preselect tv norm 'PAL' or 'NTSC'
INPUT_NR=0      # preselect input number of your easycap where video source is plugged in
input_width=720     # preselect width an height of video source (mplayer, vlc, mencoder)
input_height=576    # other possible combinations: 640/480; 320/240
ASPECT=169          # '169' (16:9) or '43' (4:3); this value affects video playback with mplayer or vlc only!
FREQ="48000"        # on soundproblems reduce audio frequency (44100 oder 32000 oder 8000)
TV_INPUT="no"       # if 'yes' the analogue antenna input of the tv-card will be used (mplayer only)
CHAN="chanlist=europe-west:channel=60"      # channel setting (nur mplayer/ mencoder) the analogue antenna input of the tv-card is used
NORM="PAL"          # preselect TV-norm 'PAL' oder 'NTSC'
INPUT_NR=1          # preselct the Input on the TV-card, where the videosource is plugged in ('0' normally is the antenna, '1' the first CVBS ...
#-----------------------------------------------------------------------------

MESSAGE=()
R_MESSAGE=()
EXITCODE=0

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#   test videodevices
##-----------------------------------------------------------------------------

declare -a VIDEO_DEV

VIDEO_DEV=( TRUE    none
            FALSE   none
            FALSE   none
            FALSE   none
            )
i1=0;
i2=0;
while `test -e "/dev/video${i1}"`; do
  VIDEO_DEV[$i2+1]="/dev/video${i1}";
  i1=$[$i1+1];
  i2=$[$i2+2];
done
if [ "xnone" = "x${VIDEO_DEV[1]}" ]; then
  zenity  --error --timeout=5 --text "Cannot find /dev/video0!\n Script ends in 5 seconds" --title "No videodevice!";
  exit 1;
fi

if [ "x${VIDEO_DEV[$i2+1]}" = "xnone" ];  then
    VIDEO_DEV[$i2]="" && VIDEO_DEV[$i2+1]="" && VIDEO_DEV[$i2+2]="" && VIDEO_DEV[$i2+3]="" && VIDEO_DEV[$i2+4]="" && VIDEO_DEV[$i2+5]="";
fi

DEV_VIDEO=$(zenity --list --text "Select videodevice" --radiolist --column "Choice" --column "Device" ${VIDEO_DEV[@]}) || exit 0

if [ ${VERBOSE} = 1 ]; then
#-----------------------------------------------------------------------------
#  select TV norm
#-----------------------------------------------------------------------------
title="Select tv norm"
NORM=`zenity --title="$title" --list --radiolist --column="Choice" \
    --column="Norm" --column="Description" \
    TRUE "PAL" "PAL Norm" \
    FALSE "NTSC" "NTSC Norm" \
    ` || exit 0
fi
#-----------------------------------------------------------------------------
#  select Input number
#-----------------------------------------------------------------------------
title="Select Input NR"
INPUT_NR=`zenity --title="$title" --list --radiolist --column="Choice" \
    --column="Input NR" --column="Description" \
    TRUE "0" "Input 1 (TV)" \
    FALSE "1" "Input 2" \
    FALSE "2" "Input 3" \
    FALSE "3" "Input 4" \
    FALSE "4" "Input 5" \
    FALSE "5" "Input 6"
    ` || exit 0
#-----------------------------------------------------------------------------


#-----------------------------------------------------------------------------
#  Check if snd_usb_audio module is loaded
#-----------------------------------------------------------------------------
SND_USB=`lsmod | grep snd_usb_audio | wc -l`
if  [ "${SND_USB}" -ge "1" ]; then
#  MESSAGE=("${MESSAGE[@]}" "\nNOTE: snd_usb_audio module was loaded and may conflict with your USB capture device")
   zenity  --info --text "NOTE: The snd_usb_audio module was loaded\nand may conflict with your USB capture device.\n \nIf sound problems appear,\nplug out your USB capturedevice and run\n rmmod snd_usb_audio \nas root in the terminal!" --title "Snd_usb_audio module loaded!"
fi

#-----------------------------------------------------------------------------
# test and select soundcard
#-----------------------------------------------------------------------------

if `test ! -e /dev/dsp` && [ -z "`ls -1 /proc/asound`" ]; then
    if_audio="no";
    echo "No soundcard detected";
    MESSAGE=("${MESSAGE[@]}" "Note: No soundcard can be found!\nSound is not supported.\n");
else
if_audio="yes"
declare -a SOUND_DEV

SOUND_DEV=( FALSE   /dev/dsp    OSS
            FALSE   card1   ALSA
            TRUE    card2   ALSA
            FALSE   card3   ALSA
            )

test ! -e /dev/dsp && echo "No dsp" && SOUND_DEV[0]="" && SOUND_DEV[1]="" && SOUND_DEV[2]=""

ALSA_CARD=$(cat /proc/asound/cards | cut -d":" -f1 -s)
declare -a ALSA_CARDS
ALSA_CARDS=(${ALSA_CARD})

i5=1
for P in ${ALSA_CARDS[@]}; do
    ALSA_NAME=$(echo ${ALSA_CARDS[$i5]} | tr -d [=[=] );
    SOUND_DEV[$i5+3]=$ALSA_NAME
    if [ "x${ALSA_NAME}" = "x" ];  then
    SOUND_DEV[$i5+2]="" && SOUND_DEV[$i5+3]="" && SOUND_DEV[$i5+4]=""
    fi
    i5=$[$i5+3];
done
fi

DEV_AUDIO=$(zenity --list --text "Select soundcard" --radiolist --column "Choice" --column "Device" --column "Type" ${SOUND_DEV[@]}) || exit 0

if [ $DEV_AUDIO = "/dev/dsp" ]; then
    AUDIO_TYPE="oss"
    else
    AUDIO_TYPE="alsa"
fi
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#   test, if devicenodes are read- and writable for unprivileged users
#-----------------------------------------------------------------------------

if [ -r ${DEV_VIDEO} ] && [ -w ${DEV_VIDEO} ]; then
MESSAGE=("${MESSAGE[@]}" "\nSUCCESS! ${DEV_VIDEO} is read- and writable!\n")
elif [ -e ${DEV_VIDEO} ]; then
zenity --info --text "Cannot access ${DEV_VIDEO}!\nRun 'sudo chmod a+rw ${DEV_VIDEO}'\nin the terminal!" --title "Message"
EXITCODE=1
fi

    if [ -r ${DEV_AUDIO} ] && [ -w ${DEV_AUDIO} ]; then
    MESSAGE=("${MESSAGE[@]}" "\nSUCCESS! ${DEV_AUDIO} is read- and writable!")
    elif [ -e ${DEV_AUDIO} ]; then
    zenity --info --text "\nCannot access ${DEV_AUDIO}!\nRun 'sudo chmod a+rw ${DEV_AUDIO}'\nin the terminal!" --title "Message"
    MESSAGE=("${MESSAGE[@]}" "\n\nCannot access ${DEV_AUDIO}!\nRun 'sudo chmod a+rw ${DEV_AUDIO}'\nin the terminal!!")
    if_audio="no"
    fi
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  find executable programs
#-----------------------------------------------------------------------------
PROG_LIST=( TRUE    vlc     #
            FALSE   mplayer     #
            FALSE   cheese      #
            FALSE   tvtime      #
            FALSE   mencoder    #
            FALSE   sox         #
            )

PROGS=(vlc mplayer cheese tvtime mencoder sox)
i4=0
for P in ${PROGS[@]}; do
            PROG=`which $P`
            if [ "x" = "x${PROG}" ] || [ ! -x ${PROG} ]; then
            echo "Cannot find or execute $P. Is t installed?"
            MESSAGE=("${MESSAGE[@]}" "\nCannot find or execute $P. Is it installed?")
            PROG_LIST[$i4]=""
            PROG_LIST[$i4+1]=""
                if [ "${PROG_LIST[11]}" = "" ]; then
                echo "Sox is needed for sound with tvtime!"
                MESSAGE=("${MESSAGE[@]}" "\nSox is needed for sound with tvtime!")
                fi
            fi
            i4=$i4+2
done
PROG_LIST[10]=""        # Sox does not show up on list
PROG_LIST[11]=""        #
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  messages are displayed and script ends
#-----------------------------------------------------------------------------
if [ ${EXITCODE} = 1 ]; then
    MESSAGE=("${MESSAGE[@]}" "\nScript ends")
fi
echo ${MESSAGE[*]}
#########################
if [ ${VERBOSE} = 1 ]; then
zenity --height="50" --info --text "${MESSAGE[*]}" --title "Messages"
fi

if [ ${EXITCODE} = 1 ]; then
    exit 1
fi
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  create logfile
#-----------------------------------------------------------------------------
LOGFILE="./test`echo "${DEV_VIDEO}" | sed -e "s,/dev/,," - `.log"

# echo "Log file is:  ${LOGFILE}"
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  zenity list - program choice
#-----------------------------------------------------------------------------

view_cap=$(zenity --list --width=250 --height=400 --text "  ___________\n |  .----------.  o|\n | |   Easy  | o|\n | |   CAP_  | o|\n |_\`-----------´ _|\n   ´\`          ´\`\\nTv-norm: $NORM  Input-Nr:$INPUT_NR\nVideodevice: $DEV_VIDEO $input_width x $input_height \nAudiodevice: $AUDIO_TYPE $DEV_AUDIO $FREQ Hz\nIs audio on? $if_audio\nLogfile: $LOGFILE " --radiolist --column "Choice" --column "program" ${PROG_LIST[@]}) || exit 0

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  mplayer command
#-----------------------------------------------------------------------------
if [ "alsa" = "${AUDIO_TYPE}" ]; then
M_AUDIO="buffersize=16:alsa:amode=1:forcechan=2:audiorate=${FREQ}:adevice=plughw.${DEV_AUDIO}"
elif [ "oss" = "${AUDIO_TYPE}" ]; then
M_AUDIO="adevice=${DEV_AUDIO}"
fi

if [ "$NORM" = "PAL" ]; then
    fps_count=25
else
    fps_count=30
fi

if [ "$ASPECT" = 169 ]; then
    M_ASPECT="-aspect 1.78"
#   elif [ "$ASPECT" = 43 ]; then
#   M_ASPECT="-aspect 1"
    else
    M_ASPECT=""
    fi

if [ "yes" = "${TV_INPUT}" ]; then
M_VIDEO="${CHAN}"
elif [ "no" = "${TV_INPUT}" ]; then
M_VIDEO="norm=${NORM}:width=${input_width}:height=${input_height}:outfmt=uyvy:device=${DEV_VIDEO}:input=${INPUT_NR}:fps=${fps_count}"
fi

#echo $M_VIDEO
#echo $M_AUDIO
#echo $view_cap

if [ "mplayer" = "${view_cap}" ]; then


if [ "$if_audio" = "yes" ]; then
1>${LOGFILE} 2>&1 \
mplayer tv:// -tv driver=v4l2:${M_VIDEO}:${M_AUDIO}:forceaudio:immediatemode=0 -hardframedrop ${M_ASPECT} -ao sdl, ${AUDIO_TYPE} -msglevel all=9

elif [ "$if_audio" = "no" ]; then
1>${LOGFILE} 2>&1 \
mplayer tv:// -tv driver=v4l2:${M_VIDEO} -hardframedrop ${M_ASPECT} -msglevel all=9 -nosound
fi
fi
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  vlc command
#-----------------------------------------------------------------------------
if [ "vlc" = "${view_cap}" ]; then

    if [ "alsa" = "${AUDIO_TYPE}" ]; then
    V_AUDIO="//plughw:${DEV_AUDIO}"
    elif [ "oss" = "${AUDIO_TYPE}" ]; then
    V_AUDIO="//${DEV_AUDIO}"
    fi

    if [ "$NORM" = "PAL" ]; then
    V_NORM="pal"
    elif [ "$NORM" = "NTSC" ]; then
    V_NORM="ntsc"
    fi

    if [ "$ASPECT" = 169 ]; then
    V_ASPECT="--aspect-ratio=16:9"
    elif [ "$ASPECT" = 43 ]; then
    V_ASPECT="--aspect-ratio=4:3"
    else
    V_ASPECT=""
    fi

1>${LOGFILE} 2>&1 \
vlc -vvv v4l2://${DEV_VIDEO}:input=${INPUT_NR}:width=$input_width:height=$input_height:norm=${V_NORM} ${V_ASPECT} :input-slave=${AUDIO_TYPE}:${V_AUDIO} --demux rawvideo
fi
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  tvtime command
#-----------------------------------------------------------------------------
if [ "tvtime" = "${view_cap}" ]; then
    if [ "alsa" = "${AUDIO_TYPE}" ]; then
    T_AUDIO="-t alsa plughw:${DEV_AUDIO} -s2 -c 2 -r ${FREQ} -s2 -t alsa default"
    elif [ "oss" = "${AUDIO_TYPE}" ]; then
    T_AUDIO="-t raw -s2 ${DEV_AUDIO} -c 2 -r ${FREQ} -s2 -t ossdsp /dev/dsp"
    fi
echo $T_AUDIO
1>${LOGFILE} 2>&1 \
>./tvtime.err
(tvtime -d ${DEV_VIDEO} -i 0 -n "${NORM}" 1>/dev/null 2>>./tvtime.err) &
rc=1
while [ 0 -ne ${rc} ];
do
  tvtime-command run_command "(sox -c 2 -r ${FREQ} ${T_AUDIO} 1>/dev/null 2>>./tvtime.err)" 1>/dev/null 2>>./tvtime.err
  rc=$?
  if [ 0 -eq ${rc} ]; then break; fi
  sleep 0.5
done
fi
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  cheese command
#-----------------------------------------------------------------------------
if [ "cheese" = "${view_cap}" ]; then
1>${LOGFILE} 2>&1 \
cheese
fi
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  mencoder command - recording section
#-----------------------------------------------------------------------------

if [ "mencoder" = "${view_cap}" ]; then

#Auswahl des Seitenverhältnisses der Aufnahme?
title="Chose aspect of your target file!"
aspect_type=`zenity  --width="400" --height="220" --title="$title" --list --radiolist --column="Click Here" \
    --column="choice" --column="source >> target" \
    TRUE "1" "4:3 > 4:3"\
    FALSE "2" "4:3 > scale=16:9" \
    FALSE "3" "4:3 > crop borders=16:9" \
    ` || exit 0

if [ "$aspect_type" = "1" ]; then
    crop_scale="scale=640:480"
elif [ "$aspect_type" = "2" ]; then
    crop_scale="scale=720:406"
elif [ "$aspect_type" = "3" ]; then
    crop_scale="crop=720:406:0:72"
fi

#################################################################################
#Quality?
title="What quality do you want to record at ?"
qual_type=`zenity  --width="380" --height="380" --title="$title" --list --radiolist --column="Click Here" \
    --column="Record Time" --column="Description" \
    FALSE "500" "Passable Quality"\
    FALSE "900" "OK Quality"\
    FALSE "1100" "VHS Quality"\
    TRUE "1300" "SVHS Quality"\
    FALSE "1500" "VCD Quality"\
    FALSE "1800" "SVCD Quality" \
    FALSE "2000" "Very Good Quality"\
    FALSE "2500" "High Quality" \
    FALSE "3000" "Excellent Quality"\
    ` || exit 0

##################################################################################
#How Long?
title="How long do you want to record for ?"
time_type=`zenity  --width="380" --height="500" --title="$title" --list --radiolist --column="Click Here" \
    --column="Record Time" --column="Description" \
    FALSE "00:00:00" "unlimited"\
    TRUE "00:00:30" "30 seconds for testing"\
    FALSE "00:10:00" "0.2 hours"\
    FALSE "00:30:00" "0.5 hours"\
    FALSE "00:45:00" "0.75 hours"\
    FALSE "01:00:00" "1 hour"\
    FALSE "01:15:00" "1.25 hours"\
    FALSE "01:30:00" "1.5 hours" \
    FALSE "01:45:00" "1.75 hours"\
    FALSE "02:00:00" "2 hours" \
    FALSE "02:15:00" "2.25 hours"\
    FALSE "02:30:00" "2.5 hours" \
    FALSE "02:45:00" "2.75 hours"\
    FALSE "03:00:00" "3 hours" \
    FALSE "03:15:00" "3.25 hours" \
    FALSE "03:30:00" "3.5 hours" \
    ` || exit 0

#M_TIME="-endpos $time_type"

#################################################################################
#user must enter a filename
filedate=$(date +%F_%H:%M-%S)
title="Please enter a filename for your recording, no spaces"
file_name=`zenity  --width="480" --height="150" --title="$title" --file-selection --save --confirm-overwrite --filename="tvcap_$filedate"` || exit 0

###########################################################################################
# summary
R_MESSAGE=("${R_MESSAGE[@]}" "\nRecording options:")
R_MESSAGE=("${R_MESSAGE[@]}" "\nRecording audio: $if_audio")
R_MESSAGE=("${R_MESSAGE[@]}" "\nRecording from Input $INPUT_NR - Norm: $NORM $fps_count fps")
R_MESSAGE=("${R_MESSAGE[@]}" "\nCrop and scale options: $crop_scale")
R_MESSAGE=("${R_MESSAGE[@]}" "\nEncoding quality: $qual_type kb/s")
R_MESSAGE=("${R_MESSAGE[@]}" "\nRecording time:$time_type hours")
R_MESSAGE=("${R_MESSAGE[@]}" "\nFile name: $file_name.avi ")

echo ${R_MESSAGE[*]}

if [ ${VERBOSE} = 1 ]; then
zenity --info --text "${R_MESSAGE[*]}" --title "Recording options"
fi
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#  mencoder line
#-----------------------------------------------------------------------------
if [ "$if_audio" = "yes" ]; then

zenity --info --title="Start recording with audio" --text="Press OK to start."

mencoder tv:// -tv driver=v4l2:norm=$NORM:width=$input_width:height=$input_height:outfmt=uyvy:device=${DEV_VIDEO}:input=${INPUT_NR}:fps=$fps_count:${M_AUDIO}:forceaudio:immediatemode=0 -msglevel all=9 -ovc lavc -ffourcc DX50 -lavcopts vcodec=mpeg4:mbd=2:turbo:vbitrate=$qual_type:keyint=15 -vf pp=lb,$crop_scale -oac mp3lame -endpos $time_type -o $file_name.avi | tee ${LOGFILE} | zenity --progress --pulsate --auto-close --auto-kill --text="Processing Video - length: $time_type H:M:S"

zenity --info --title="Job complete" --text="The recording is now complete."


elif [ "$if_audio" = "no" ]; then

zenity --info --title="Start recording without audio" --text="Press ok to start recording"
1>${LOGFILE} 2>&1 \
mencoder tv:// -tv driver=v4l2:norm=$NORM:width=$input_width:height=$input_height:outfmt=uyvy:device=${DEV_VIDEO}:input=${INPUT_NR}:fps=$fps_count -msglevel all=9 -nosound -ovc lavc -ffourcc DX50 -lavcopts vcodec=mpeg4:mbd=2:turbo:vbitrate=$qual_type:keyint=15 -vf pp=lb,$crop_scale -endpos $time_type -o $file_name.avi | tee ${LOGFILE} | zenity --progress --pulsate --auto-close --auto-kill --text="Processing Video - length: $time_type H:M:S"

zenity --info --title="Job complete" --text="The recording is now complete."

fi

fi
exit 1
