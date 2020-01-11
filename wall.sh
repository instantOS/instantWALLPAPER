#!/bin/bash

#######################################
## chromecast like wallpaper changer ##
#######################################

source ~/paperbenni/import.sh || source <(curl -Ls https://git.io/JerLG)
pb instantos

mkdir -p $HOME/instantos/wallpapers/default &>/dev/null
cd $HOME/instantos/wallpapers

randomwallpaper() {
    if curl google.com &> /dev/null; then
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
        if $((RANDOM % 2)); then
            randomwallpaper
        else
            bingwallpaper
        fi

    fi

    instantoverlay
    convert photo.jpg -resize 1920x1080^ -extent 1920x1080 wall.png
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
fi

if date +%A | grep -Ei '(Wednesday|Mittwoch)'; then
    if ! [ -e ~/instantos/wallpaper/wednesday ]; then

        genwallpaper
        touch ~/instantos/wallpaper/wednesday
    else
        echo "wallpaper wednesday already happened"
    fi
else
    if [ -e ~/instantos/wallpaper/wednesday ]; then
        echo "removing cache file"
        rm ~/instantos/wallpaper/wednesday
    fi
fi

feh --bg-scale instantwallpaper.png
