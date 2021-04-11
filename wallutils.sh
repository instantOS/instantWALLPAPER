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
    if [ -e ~/instantos/wallpapers/customlogo.png ]; then
        rsync -aP ~/instantos/wallpapers/customlogo.png ./overlay.png
    else
        if [ -e overlay.png ] && file overlay.png | grep -iq 'image data'; then
            return
        else
            [ -e overlay.png ] && rm overlay.png
            wget -q "https://raw.githubusercontent.com/instantOS/instantLOGO/master/wallpaper/overlay.png"
        fi
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

    if [ -n "$3" ]
    then
        OUTNAME="$3"
    else
        OUTNAME="$(iconf theme:arc)"
    fi

    if [ -n "$1" ] && [ -n "$2" ]; then
        echo "generating custom image"
        convert overlay.png -fill "$1" -colorize 100 color.png
        convert color.png -background "$2" -alpha remove -alpha off "$OUTNAME".png
    else
        echo "defaulting to theme colors"
        convert overlay.png -fill "$(instantforeground)" -colorize 100 color.png
        convert color.png -background "$(instantbackground)" -alpha remove -alpha off "$OUTNAME".png
    fi

    rm color.png
}

# checks if file is a valid image
checkwall() {
    if [ -e "$1" ] && file "$1" | grep -q 'image data'; then
        echo "image found"
        return 0
    else
        echo "not an image"
        return 1
    fi
}

# choose a wallpaper in a gui
guiwall() {
    WALLPATH="$(zenity --file-selection --file-filter='Image files (png, jpg) | *.png *.jpg')"
    if [ -z "$WALLPATH" ]; then
        echo "no wallpaper chosen"
        exit
    fi

    checkwall "$WALLPATH" || exit 1
}

# put the logo onto a wallpaper
compwallpaper() {

    echo "RESOLUTION $RESOLUTION"
    imgresize "${1:-photo.jpg}" "$RESOLUTION" wall.png || return 1

    # the logo is optional
    if ! iconf -i nologo; then
        instantoverlay
        imgresize overlay.png "$RESOLUTION"

        # set to invert if logoeffects is not set or broken
        iconf logoeffects |
        grep -E 'brighten|dim|contrast|grayscale|invert|blur|flip|swirl' ||
        iconf logoeffects 'invert'


        # perpare effect settings
        iconf logoeffects | grep swirl && EFFECTS+=("-swirl" "360")
        iconf logoeffects | grep flip && EFFECTS+=("-flip")
        iconf logoeffects | grep blur && EFFECTS+=("-blur" "100x100")
        iconf logoeffects | grep invert && EFFECTS+=("-channel" "RGB" "-negate")
        iconf logoeffects | grep grayscale && EFFECTS+=("-colorspace" "Gray")
        iconf logoeffects | grep contrast && EFFECTS+=("-level" "20000")
        iconf logoeffects | grep dim && EFFECTS+=("-modulate" "50")
        iconf logoeffects | grep brighten | grep -v dim && EFFECTS+=("-modulate" "150")

	# apply effects
        convert wall.png "${EFFECTS[@]}" effect.png

        # create mask from overlay
        convert overlay.png -alpha extract mask.png
        # cut the effect image with the mask
        composite -compose CopyOpacity mask.png effect.png cut.png
        # draw the computed overlay on top of the background
        convert wall.png cut.png -gravity center -composite instantwallpaper.png

        rm wall.png
        rm mask.png
        rm cut.png
        rm effect.png
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
    cd "$(xdg-user-dir PICTURES)/wallpapers" || return 1

    rm readme.jpg

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
    WALLCOUNTER=1
    while read p; do
        echo "Downloading wallpaper $WALLCOUNTER"
        wget -qO "$WALLCOUNTER.jpg" "$p"
        WALLCOUNTER="$((WALLCOUNTER + 1))"
    done </tmp/instantwallpaperlist
}
