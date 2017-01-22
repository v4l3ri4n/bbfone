#!/bin/bash

DEVICE="hw:1,0" # sound card
PORT=BBFONE_PORT
RECEIVER="BBFONE_RECEIVER"

# launch record in background
nohup gst-launch -v gstrtpbin alsasrc device="$DEVICE" ! opusenc audio=false ! udpsink port=$PORT host="$RECEIVER" &

# launch python script (detecting noise)
#python /usr/local/bin/bbfone-diffuser.py
