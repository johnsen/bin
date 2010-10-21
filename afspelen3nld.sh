#!/bin/sh
v4l2-ctl -d /dev/video0 -v width=720,height=576
v4l2-ctl -d /dev/video0 -s pal-b
v4l2-ctl -d /dev/video0 -i 0
ivtv-tune -d /dev/video0 -t europa-west -f 203.259
vlc pvr:// 

