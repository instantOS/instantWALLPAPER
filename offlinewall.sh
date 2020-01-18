#!/bin/bash

if ! [ -e ~/instantos/wallpapers/ ]; then
    exit
fi
cd ~/instantos/wallpapers/

setwallpaper() {
    if [ -e "$1" ]; then
        feh --bg-scale "$1"
        exit
    fi
}

setwallpaper instantwallpaper.png
setwallpaper default/$(cat ../themes/config).png
setwallpaper /opt/instantos/wallpapers/default.png
