#!/bin/bash

#######################################
## chromecast like wallpaper changer ##
#######################################

if ! timeout 10 ping -c 1 google.com &>/dev/null; then
    echo "an internet connection is required"
    exit
fi

source ~/paperbenni/import.sh || source <(curl -Ls https://git.io/JerLG)
pb instantos

mkdir -p $HOME/instantos/wallpapers/default &>/dev/null
cd $HOME/instantos/wallpapers

googlewallpaper() {
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

wallhaven() {
    WALLURL=$(curl -Ls 'https://wallhaven.cc/search?q=id%3A711&categories=111&purity=100&sorting=random&order=desc' |
        grep -o 'https://wallhaven.cc/w/[^"]*' | shuf | head -1)

    wget -qO photo.jpg $(curl -s $WALLURL | grep -o 'https://w.wallhaven.cc/full/.*/.*.jpg' | head -1)

}

wallist() {
    wget -qO photo.jpg $(curl -s 'https://raw.githubusercontent.com/instantOS/instantWALLPAPER/master/list.txt' | shuf | head -1)
}

bingwallpaper() {
    wget -qO photo.jpg $(curl -s https://bing.biturl.top/ | grep -Eo 'www.bing.com/[^"]*(jpg|png)')
}

instantoverlay() {
    [ -e overlay.png ] || wget -q "https://raw.githubusercontent.com/instantOS/instantLOGO/master/wallpaper/overlay.png"
}

randomwallpaper() {
    array[0]="googlewallpaper"
    array[1]="bingwallpaper"
    array[2]="wallist"
    array[3]="wallhaven"

    size=${#array[@]}
    index=$(($RANDOM % $size))
    WALLCOMMAND=${array[$index]}
    echo $WALLCOMMAND
    $WALLCOMMAND
}

imgresize() {
    IMGRES=$(identify "$1" | grep -o '[0-9][0-9]*x[0-9][0-9]*' | sort -u | head -1)
    if [ $IMGRES = "$2" ]; then
        echo "image already resized"
        if [ -n "$3" ]; then
            if ! [ -e "$3" ]; then
                cp $1 $3
            fi
        fi
        return 0
    fi
    mv "$1" "${1%.*}.1.png"
    convert "${1%.*}.1.png" -alpha on -background none -gravity center -resize $2^ -gravity center -extent $2 ${3:-$1}
    rm "${1%.*}.1.png"
}

instantoverlay

if [ -e ~/instantos/monitor/max.txt ] && grep -q '....' ~/instantos/monitor/max.txt; then
    export RESOLUTION=$(head -1 ~/instantos/monitor/max.txt)
else
    export RESOLUTION="1920x1080"
fi

if ! [ -e ./default/$(getinstanttheme).png ]; then
    echo "generating default wallpaper"
    cd default
    instantoverlay
    imgresize overlay.png $RESOLUTION
    convert overlay.png -fill "$(instantforeground)" -colorize 100 color.png
    convert color.png -background "$(instantbackground)" -alpha remove -alpha off "$(getinstanttheme)".png
    rm color.png
    cd ..
fi

genwallpaper() {
    feh --bg-scale default/$(getinstanttheme).png
    if [ -n "$1" ]; then
        case "$1" in
        bing)
            bingwallpaper
            ;;
        haven)
            wallhaven
            ;;
        list)
            wallist
            ;;
        google)
            googlewallpaper
            ;;
        *)
            randomwallpaper
            ;;
        esac
    else
        randomwallpaper
    fi

    instantoverlay
    echo "RESOLUTION $RESOLUTION"
    imgresize photo.jpg $RESOLUTION wall.png
    imgresize overlay.png $RESOLUTION

    convert wall.png -channel RGB -negate invert.png
    convert overlay.png invert.png -compose Multiply -composite out.png
    composite out.png wall.png instantwallpaper.png
    rm wall.png
    rm invert.png
    rm out.png
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
