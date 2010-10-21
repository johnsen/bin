#!/bin/sh
v4l2-ctl -d /dev/video0 -v width=720,height=576
v4l2-ctl -d /dev/video0 -s pal-b
v4l2-ctl -d /dev/video0 -i 0
ivtv-tune -d /dev/video0 -t europa-west -f 175.255
cat /dev/video0 > finkers.mpg &
smplayer finkers.mpg
