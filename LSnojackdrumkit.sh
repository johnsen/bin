#! /bin/bash
/usr/bin/linuxsampler &

sleep 4

cat /home/d/linux_muziek/linuxsampler/drumkit.lscp | nc localhost 8888 &


