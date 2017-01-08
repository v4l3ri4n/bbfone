#!/bin/bash

LISTENER_IP="192.168.0.47"
STREAM_NAME="bbfone"

nohup avplay -fflags nobuffer "rtmp://$LISTENER_IP/live/$STREAM_NAME" &

python /usr/local/bin/bbfone-receiver.py
