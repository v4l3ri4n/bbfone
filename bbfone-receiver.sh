#!/bin/bash

LISTENER_IP="192.168.0.47"
STREAM_NAME="bbfone"

# set volum to 0, the volume is increased with python script
amixer sset Master 0%

# play stream in background
avplay -fflags nobuffer "rtmp://$LISTENER_IP/live/$STREAM_NAME" &

# launch python script (listening to socket)
python /usr/local/bin/bbfone-receiver.py
