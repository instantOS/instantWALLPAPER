#!/bin/bash

#######################################
## chromecast like wallpaper changer ##
#######################################

source ~/paperbenni/import.sh || source <(curl -Ls https://git.io/JerLG)
pb instantos

mkdir -p $HOME/instantos/wallpapers/default &>/dev/null
cd $HOME/instantos/wallpapers

randomwallpaper() {
    if curl google.com &>/dev/null; then
        url='https://storage.googleapis.com/chromeos-wallpaper-public'

        fetch() {
            IFS='<' read -a array <<<"$(wget -O - -q "$url")"
            for field in "${array[@]}"; do
                if [[ "$field" == *_resolution.jpg ]]; then
                    IFS='>' read -a key <<<"$field"
                    printf "%s\n" "${key[1]}"
                fi
            done
        }

        wget -qO photo.jpg "$url/$(fetch | shuf -n 1)"
    fi
}

bingwallpaper() {
    curl $(curl -s https://bing.biturl.top/ | grep -Eo 'www.bing.com/[^"]*(jpg|png)') >photo.jpg
}

instantoverlay() {
    [ -e overlay.png ] || wget -q "https://raw.githubusercontent.com/instantOS/instantLOGO/master/wallpaper/overlay.png"
}

instantoverlay

if ! [ -e ./default/$(getinstanttheme).png ]; then
    echo "generating default wallpaper"
    cd default
    instantoverlay
    convert overlay.png -fill "$(instantforeground)" -colorize 100 color.png
    convert color.png -background "$(instantbackground)" -alpha remove -alpha off "$(getinstanttheme)".png
    rm color.png
    cd ..
fi

genwallpaper() {
    feh --bg-scale default/$(getinstanttheme).png
    if [ -n "$1" ]; then
        randomwallpaper
    else
        RANDOMM=$(eval '((RANDOM%2))') && ((RANDOMM == 0)) && CMD='randomwallpaper' || CMD='bingwallpaper' && $CMD
    fi

    instantoverlay
    if [ -e /opt/instantos/monitor/max.txt ]; then
        RESOLUTION=$(head -1 /opt/instantos/monitor/max.txt)
    else
        RESOLUTION="1920x1080"
    fi

    echo "RESOLUTION $RESOLUTION"
    convert photo.jpg -resize $RESOLUTION^ -extent $RESOLUTION wall.png

    if ! [ "$RESOLUTION" = "1920x1080" ]; then
        if [ -e .overlayresize ]; then
            echo "overlay already resized"
        else
            mv overlay.png overlay2.png
            convert overlay2.png -resize $RESOLUTION^ -extent $RESOLUTION overlay.png
            touch .overlayresize
            rm overlay2.png
        fi
    fi

    convert wall.png -negate invert.png
    convert invert.png overlay.png -alpha off -compose CopyOpacity -composite out.png
    composite out.png wall.png instantwallpaper.png
    rm wall.png
    rm invert.png
    rm out.png
    rm photo.jpg
}

if [ -n "$1" ]; then
    genwallpaper google
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

feh --bg-scale instantwallpaper.png
