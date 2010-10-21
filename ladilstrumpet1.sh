#! /bin/bash
/usr/bin/linuxsampler &

sleep 4

cat /home/d/linux_muziek/linuxsampler/trumpet1.lscp | nc localhost 8888 





