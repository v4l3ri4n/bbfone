#!/bin/bash

DEVICE="plughw:1,0" # sound card
RTMP_SERVER="127.0.0.1"
STREAM_NAME="bbfone"

# launch record in background
nohup arecord -f S32_LE -c 1 -r 44100 -D $DEVICE | \
    avconv -i pipe:0  \
        -acodec mp3 \
        -ab 64k \
        -ac 1 \
        -strict -2 \
        -f flv -metadata streamName=$STREAM_NAME rtmp://$RTMP_SERVER/live/$STREAM_NAME &

# /root/bin/ffmpeg -f alsa -ss 0 -i $DEVICE  \
    # -acodec mp3 \
    # -ar 44100 \
    # -ab 64k \
    # -ac 1 \
    # -strict -2 \
    # -f flv -metadata streamName=$STREAM_NAME rtmp://$RTMP_SERVER/live/$STREAM_NAME

# launch python script (detecting noise)
python /usr/local/bin/bbfone-diffuser.py
