#!/bin/sh

[ ! $(pgrep -u $USER pulseaudio) ] && pulseaudio -D --exit-idle-time=-1


