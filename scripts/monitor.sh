#!/bin/bash
intern=eDP-1
externMSI=HDMI-1
externDell=DP-1-4

if xrandr -q | grep "$externMSI connected"; then
    xrandr --output "$externMSI" --mode 3840x2160 --pos 1920x0 --rotate normal \
    --output "$externDell" --off \
    --output "$intern" --mode 1920x1080 --pos 0x1080 --rotate normal
elif xrandr -q | grep "$externDell connected"; then
    xrandr --output "$externDell" --mode 3840x2160 --pos 1920x0 --rotate normal \
        --output "$externMSI" --off \
        --output "$intern" --mode 1920x1080 --pos 0x1080 --rotate normal
else
    xrandr --output "$externMSI" --off --output "$externDell" --off \
        --output "$intern" --auto
fi
