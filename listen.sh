#!/bin/bash
pipe="pifone.mp3"

if [[ ! -p $pipe ]]; then
    mkfifo $pipe
fi

while true
do
    echo "Press and hold [CTRL+C] to stop.."

    netcat -v 192.168.0.47 5000 > $pipe
done