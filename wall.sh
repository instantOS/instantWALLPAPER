#!/bin/bash

###################################
## instantos wallpaper generator ##
###################################

source /usr/share/instantwallpaper/wallutils.sh

if [ ".$1" = ".offline" ] || ! timeout 10 ping -c 1 google.com &>/dev/null; then
    echo "offlinewall"
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
    exit
fi

source /usr/share/paperbash/import.sh || source <(curl -Ls https://git.io/JerLG)
pb instantos

cd
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

instantoverlay

if [ -e ~/instantos/monitor/max.txt ] && grep -q '....' ~/instantos/monitor/max.txt; then
    export RESOLUTION=$(head -1 ~/instantos/monitor/max.txt)
else
    export RESOLUTION="1920x1080"
fi

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
