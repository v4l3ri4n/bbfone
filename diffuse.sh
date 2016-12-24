#!/bin/bash

DEVICE="plughw:1,0"
PORT=5000
echo "starting netcat for $DEVICE Port $PORT"
while true
do
    echo "Press and hold [CTRL+C] to stop.."
    echo ""
    arecord -f cd -D $DEVICE | netcat -v -l -p $PORT
done