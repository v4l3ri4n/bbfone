#!/bin/bash

PORT=BBFONE_PORT

# set volume to 0, the volume is increased with python script
#amixer sset Master 0%

gst-launch -v udpsrc port=$PORT ! audio/x-opus, multistream=false ! opusdec ! audioconvert ! autoaudiosink &

# launch python script (listening to socket)
#python /usr/local/bin/bbfone-receiver.py