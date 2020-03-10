#!/bin/bash

###################################
## instantos wallpaper generator ##
###################################

source /usr/share/instantwallpaper/wallutils.sh

# fetch monitor resolution
setupres

# allow setting a custom image as a wallpaper
if [ "$1" = "set" ] && [ -n "$2" ]; then
    if [ -e "$2" ] && identify "$2"; then
        rm ~/instantos/wallpapers/custom.png
        mkdir -p ~/instantos/wallpapers &>/dev/null
        cp "$2" ~/instantos/wallpapers/custom.png
        instantwallpaper
        exit
    else
        echo "$2 is not an image"
        exit 1
    fi
fi

if [ -e ~/instantos/wallpapers/custom.png ]; then
    cd ~/instantos/wallpapers
    imgresize custom.png "$RESOLUTION"
    feh --bg-scale custom.png
    exit
fi

if [ ".$1" = ".offline" ] || ! timeout 10 ping -c 1 google.com &>/dev/null; then
    echo "offlinewall"
    if ! [ -e ~/instantos/wallpapers/ ]; then
        exit
    fi

    cd ~/instantos/wallpapers/

    # work through a list of fallback wallpapers
    # exit if one of them is found
    setwallpaper() {
        if [ -e "$1" ]; then
            feh --bg-scale "$1"
            exit
        fi
    }

    setwallpaper instantwallpaper.png
    setwallpaper default/$(cat ../themes/config).png
    setwallpaper /opt/instantos/wallpapers/default.png
    exit
fi

source /usr/share/paperbash/import.sh || source <(curl -Ls https://git.io/JerLG)
pb instantos

cd
mkdir -p "$HOME"/instantos/wallpapers/default &>/dev/null
cd "$HOME"/instantos/wallpapers

randomwallpaper() {
    array[0]="googlewallpaper"
    array[1]="bingwallpaper"
    array[2]="wallist"
    array[3]="wallhaven"
    array[4]="viviwall"

    size=${#array[@]}
    index=$(($RANDOM % $size))
    WALLCOMMAND=${array[$index]}
    echo $WALLCOMMAND
    $WALLCOMMAND
}

instantoverlay

export RESOLUTION=$(iconf max:1920x1080)

if ! [ -e ./default/$(getinstanttheme).png ]; then
    echo "generating default wallpaper"
    cd default
    defaultwall
    cd ..
fi

genwallpaper() {
    feh --bg-scale default/$(getinstanttheme).png
    if [ -n "$1" ]; then
        case "$1" in
        b*)
            bingwallpaper
            ;;
        h*)
            wallhaven
            ;;
        l*)
            wallist
            ;;
        g*)
            googlewallpaper
            ;;
        v*)
            viviwall
            ;;
        *)
            randomwallpaper
            ;;
        esac
    else
        randomwallpaper
    fi

    compwallpaper
}

if [ -n "$1" ]; then
    genwallpaper "$1"
elif ! [ -e ~/instantos/wallpapers/instantwallpaper.png ]; then
    genwallpaper
else
    if date +%A | grep -Ei '(Wednesday|Mittwoch)'; then
        if ! [ -e ~/instantos/wallpapers/wednesday ]; then
            genwallpaper
            touch ~/instantos/wallpapers/wednesday
        else
            echo "wallpaper wednesday already happened"
        fi
    else
        if [ -e ~/instantos/wallpapers/wednesday ]; then
            echo "removing cache file"
            rm ~/instantos/wallpapers/wednesday
        fi
    fi
fi

if [ -z "$3" ]; then
    feh --bg-scale instantwallpaper.png
else
    echo "feh silenced"
fi
