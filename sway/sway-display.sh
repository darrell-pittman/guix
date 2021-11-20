#!/bin/sh

LAPTOP_DISLAY=eDP-1
if grep -q open /proc/acpi/button/lid/LID/state; then
    swaymsg output $LAPTOP_DISPLAY enable
else
    swaymsg output $LAPTOP_DISPLAY disable
fi

