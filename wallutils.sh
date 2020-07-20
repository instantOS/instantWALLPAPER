#!/bin/bash

#####################################################
## utilities for wallpaper generation on instantOS ##
#####################################################

RAW="https://raw.githubusercontent.com/instantOS/instantLOGO/master"

setupres() {
    export RESOLUTION=$(iconf max:1920x1080)
}

setupres
# resize an image using imagemagick
imgresize() {
    if file "$1" | grep -q "image data"; then
        echo "image found"
    else
        echo "$1 is not an image"
        curl -s google.com || exit 1
        instantwallpaper w
        exit
    fi

    IMGRES=$(identify "$1" | grep -o '[0-9][0-9]*x[0-9][0-9]*' | sort -u | head -1)
    if [ "$IMGRES" = "$2" ]; then
        echo "image already resized"
        if [ -n "$3" ]; then
            if ! [ -e "$3" ]; then
                cp "$1" "$3"
            fi
        fi
        return 0
    fi
    mv "$1" "${1%.*}.1.png"
    convert "${1%.*}.1.png" -alpha on -background none \
        -gravity center -resize "$2^" -gravity center -extent "$2" "${3:-$1}"
    rm "${1%.*}.1.png"
}

instantoverlay() {
    if [ -e overlay.png ] && file overlay.png | grep -iq 'image data'; then
        return
    else
        [ -e overlay.png ] && rm overlay.png
        wget -q "https://media.githubusercontent.com/media/instantOS/instantLOGO/master/wallpaper/overlay.png"
    fi
}

# bing daily photo
bingwallpaper() {
    echo "downloading bing wallpaper"
    wget -qO photo.jpg "$(curl -s https://bing.biturl.top/ | grep -Eo 'www.bing.com/[^"]*(jpg|png)')"
}

googlewallpaper() {
    echo "downloading wallpaper from google"
    LINK="$(curl -s https://raw.githubusercontent.com/dconnolly/chromecast-backgrounds/master/README.md |
        shuf | head -1 | grep -o 'http[^ )]*')"
    wget -qO photo.jpg "$LINK"
}

wallhaven() {
    echo "downloading wallpaper from wallhaven"
    WALLURL=$(curl -Ls 'https://wallhaven.cc/search?q=id%3A711&categories=111&purity=100&sorting=random&order=desc' |
        grep -o 'https://wallhaven.cc/w/[^"]*' | shuf | head -1)

    wget -qO photo.jpg "$(curl -s "$WALLURL" | grep -o 'https://w.wallhaven.cc/full/.*/.*.jpg' | head -1)"

}

wallist() {
    echo "downloading wallpaper from list"
    wget -qO photo.jpg "$(curl -s 'https://raw.githubusercontent.com/instantOS/instantWALLPAPER/master/list.txt' | shuf | head -1)"
}

viviwall() {
    echo "vk pictures wallpaper"
    LINK="$(curl -s https://github.com/instantOS/wallpapers/tree/master/wallpapers | grep -o 'wall[0-9]*\.jpg' | sort -u | shuf | head -1)"
    wget -qO photo.jpg "https://raw.githubusercontent.com/instantOS/wallpapers/master/wallpapers/$LINK"
}

# generate default mono colored logo wallpaper
defaultwall() {
    instantoverlay
    imgresize overlay.png "$RESOLUTION"
    convert overlay.png -fill "$(instantforeground)" -colorize 100 color.png
    convert color.png -background "$(instantbackground)" -alpha remove -alpha off "$(getinstanttheme)".png
    rm color.png
}

# put the logo onto a wallpaper
compwallpaper() {

    echo "RESOLUTION $RESOLUTION"
    imgresize "${1:-photo.jpg}" "$RESOLUTION" wall.png || return 1

    # the logo is optional
    if ! iconf -i nologo; then
        instantoverlay
        imgresize overlay.png "$RESOLUTION"
        convert wall.png -channel RGB -negate invert.png
        convert overlay.png invert.png -compose Multiply -composite out.png
        composite out.png wall.png instantwallpaper.png
        rm wall.png
        rm invert.png
        rm out.png
    else
        echo "logo disabled"
        mv wall.png instantwallpaper.png
    fi
}

# work through a list of fallback wallpapers
# exit if one of them is found
fallbackwallpaper() {
    echo "offlinewall"
    if ! [ -e ~/instantos/wallpapers/ ]; then
        exit
    fi

    cd ~/instantos/wallpapers/

    setwallpaper() {
        if [ -e "$1" ]; then
            ifeh "$1"
            exit
        fi
    }

    setwallpaper custom.png
    setwallpaper instantwallpaper.png
    setwallpaper default/"$(cat ../themes/config)".png
    setwallpaper /opt/instantos/wallpapers/default.png
    exit
}

# predownload all list wallpapers
fetchwallpapers() {
    if ! [ -e "$(xdg-user-dir PICTURES)/wallpapers" ]; then
        mkdir -p "$(xdg-user-dir PICTURES)/wallpapers"
    fi
    cd "$(xdg-user-dir PICTURES)/wallpapers"

    if [ "$(ls | wc -l)" -gt 6 ]; then
        echo "wallpapers already downloaded"
        echo "remove $(xdg-user-dir PICTURES)/wallpapers to redownload them"
        exit
    fi

    if ! checkinternet; then
        echo "internet it required"
        notify-send "internet it required to fetch wallpapers"
        exit
    fi

    curl -s https://raw.githubusercontent.com/instantOS/instantWALLPAPER/master/list.txt | grep -v '512pixels.net' >/tmp/instantwallpaperlist
    WALLCOUNTER=0
    while read p; do
        WALLCOUNTER="(($WALLCOUNTER + 1))"
        echo "Downloading wallpaper $WALLCOUNTER"
        wget -qO "$WALLCOUNTER.jpg" "$p"
    done </tmp/instantwallpaperlist
}
