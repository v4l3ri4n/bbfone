#!/bin/bash

DEVICE="hw:1,0" # sound card
PORT=4000
RECEIVERIP="parents.local"

# launch record in background
nohup gst-launch -v gstrtpbin alsasrc device="$DEVICE" ! opusenc ! udpsink port=$PORT host="$RECEIVERIP" &

# launch python script (detecting noise)
#python /usr/local/bin/bbfone-diffuser.py
