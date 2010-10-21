#! /bin/bash
/usr/bin/jackd -R -dalsa -dhw:0 -r48000 -p64 -n2 -Xseq &
sleep 4
/usr/bin/linuxsampler &

sleep 4

cat /home/d/linux_muziek/linuxsampler/drumkit.lscp | nc localhost 8888 &

sleep 6

jack_connect LinuxSampler\:0 system\:playback_1 &

jack_connect LinuxSampler\:1 system\:playback_2 &

jack_connect alsa_pcm\:M-Audio-Audiophile-24/96/midi_capture_1 LinuxSampler\:midi_in_0 &





