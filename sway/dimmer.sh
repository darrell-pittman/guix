#!/bin/sh

pkill -9 redshift 
redshift -l 47.551571:-52.770660 -b .6:.4 &>/dev/null &
