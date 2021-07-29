#!/bin/bash

###################################
## instantos wallpaper generator ##
###################################

source /usr/share/instantwallpaper/wallutils.sh

if [ "$(pgrep instantwallper | wc -l)" -gt 200 ]; then
    echo "recursion loop detected, exiting"
    exit 1
fi

echousage() {
    echo 'usage: instantwallpaper [action]
    gui          open gui settings for setting a custom wallpaper
    clear        remove custom wallpaper and reset to default wallpaper behaviour
    set          set custom image as wallpaper
    customlogo   set custom image as logo (requires alpha channel)
    logo         set custom image with logo as wallpaper
    offline      run instantwallpaper in offline mode
    fetch        fetch selection of wallpapers to choose from
    select       select wallpaper from fetched selection
    restore      restore current wallpaper in case of rendering errors
    color fg bg  generate colored wallpaper with instantOS logo'
    exit
}

# fetch monitor resolution
setupres

if ! [ -e "$(xdg-user-dir PICTURES)/wallpapers/readme.txt" ]; then
    echo "setting up readme"
    mkdir -p "$(xdg-user-dir PICTURES)/wallpapers"
    cp /usr/share/backgrounds/readme.jpg "$(xdg-user-dir PICTURES)"/wallpapers/readme.jpg
    echo "wallpapers are not preinstalled by default to reduce installation size
you can installl them by running
instantwallpaper fetch" >"$(xdg-user-dir PICTURES)"/wallpapers/readme.txt
fi

case "$1" in
clear)
    if [ -e ~/instantos/wallpapers/custom.png ]; then
        echo "clearing custom wallpaper"
        rm ~/instantos/wallpapers/custom.png
        rm -rf ~/.config/nitrogen
        instantwallpaper
    else
        echo "no custom wallpaper was found"
    fi
    exit
    ;;
gui)
    guiwall
    instantwallpaper set "$WALLPATH"
    exit
    ;;
set)
    # allow setting a custom image as a wallpaper
    if [ -n "$2" ]; then
        if [ -e "$2" ] && file "$2" | grep -q "image data"; then
            rm ~/instantos/wallpapers/custom.png
            mkdir -p ~/instantos/wallpapers &>/dev/null
            cp "$2" ~/instantos/wallpapers/custom.png
            ifeh ~/instantos/wallpapers/custom.png
            exit
        else
            echo "$2 is not an image"
            exit 1
        fi
    fi
    ;;
customlogo)
    # allow setting a custom image as a logo
    if [ -n "$2" ]; then
        if [ -e "$2" ] && file "$2" | grep -q "image data"; then
            rm ~/instantos/wallpapers/customlogo.png
            mkdir -p ~/instantos/wallpapers &>/dev/null
            cp "$2" ~/instantos/wallpapers/customlogo.png
            ifeh ~/instantos/wallpapers/customlogo.png
            exit
        else
            echo "$2 is not an image"
            exit 1
        fi
    fi
    ;;
logo)
    echo "setting custom image with logo as wallpaper"
    shift 1

    if [ -z "$1" ]; then
        guiwall
    else
        WALLPATH="$1"
        checkwall "$1" || exit 1
    fi

    rm -rf /tmp/logowallpaper
    mkdir /tmp/logowallpaper
    cp "$WALLPATH" /tmp/logowallpaper/tempwall.jpg
    cd /tmp/logowallpaper || exit
    compwallpaper tempwall.jpg
    instantwallpaper set instantwallpaper.png
    rm -rf /tmp/logowallpaper

    ;;

offline)
    fallbackwallpaper
    ;;
fetch)
    fetchwallpapers
    exit
    ;;
select)
    if ! [ -e "$(xdg-user-dir PICTURES)"/wallpapers/10.jpg ]; then
        st -e bash -c "instantwallpaper fetch"
    else
        echo "wallpapers already downloaded"
    fi
    nitrogen "$(xdg-user-dir PICTURES)"/wallpapers/
    exit
    ;;
restore)
    echo 'restoring wallpaper'
    if [ -e ~/instantos/wallpapers/custom.png ]; then
        ifeh ~/instantos/wallpapers/custom.png
    else
        if [ -e ~/instantos/wallpapers/instantwallpaper.png ]; then
            ifeh ~/instantos/wallpapers/instantwallpaper.png
        else
            ifeh /usr/share/instantwallpaper/defaultphoto.png
        fi
    fi
    exit
    ;;
color)

    echo 'setting colored wallpaper'
    THEME="$(iconf theme:arc)"
    if [ -n "$2" ]; then
        FGCOLOR="$2"
    else
        FGCOLOR="$(grep foreground /usr/share/instantthemes/colors/"$THEME".theme | grep -o '#.*')"
    fi

    if [ -n "$3" ]; then
        BGCOLOR="$3"
    else
        BGCOLOR="$(grep background /usr/share/instantthemes/colors/"$THEME".theme | grep -o '#.*')"
    fi
    echo "theme $THEME"
    echo "bg color $BGCOLOR"
    echo "fg color $FGCOLOR"
    mkdir -p ~/instantos/wallpapers/color
    cd ~/instantos/wallpapers/color || exit 1
    defaultwall "$FGCOLOR" "$BGCOLOR" "customcolor"
    [ -e "customcolor.png" ] || {
        notify-send 'failed to set colored wallpaper'
        exit 1
    }
    instantwallpaper set customcolor.png

    exit
    ;;
-h)
    echousage
    ;;
--help)
    echousage
    ;;
esac

! checkinternet && fallbackwallpaper && exit

# detect custom wallpaper from elsewhere
if [ -e ~/instantos/wallpapers/custom.png ]; then
    cd ~/instantos/wallpapers || exit 1
    imgresize custom.png "$RESOLUTION"
    ifeh custom.png
    exit
fi

# allow manually overriding wallpaper with nitrogen
if [ -e ~/.config/nitrogen/bg-saved.cfg ]; then
    if [ -z "$1" ] || grep -q 'offline' <<<"$1"; then
        if ! grep '/home/.*/instantos/wallpapers/' ~/.config/nitrogen/bg-saved.cfg; then
            echo "using nitrogen wallpaper"
            nitrogen --restore
            exit
        fi
    fi
fi

source /usr/share/paperbash/import.sh || source <(curl -Ls https://git.io/JerLG)
pb instantos

cd || exit 1
mkdir -p "$HOME"/instantos/wallpapers/default &>/dev/null
cd "$HOME"/instantos/wallpapers || exit 1

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

RESOLUTION=$(iconf max:1920x1080)
export RESOLUTION

# fetch logo overlay
instantoverlay
if ! [ -e ./default/"$(getinstanttheme)".png ]; then
    echo "generating default wallpaper"
    cd default || exit 1
    defaultwall
    cd .. || exit 1
fi

# generate the default wallpaper with a scraped photo and the logo
genwallpaper() {
    ifeh default/"$(getinstanttheme)".png
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
        if [ -e ~/instantos/wallpapers/instantwallpaper.png ]; then
            oldsum="$(md5sum ~/instantos/wallpapers/instantwallpaper.png | awk '{ print $1 }')"
        fi
    fi

    compwallpaper
}

if [ -n "$1" ]; then
    genwallpaper "$1"
elif ! [ -e ~/instantos/wallpapers/instantwallpaper.png ]; then
    # generate if no wallpaper is found
    genwallpaper w
else
    # generate new wallpaper every wednesday
    if date +%u | grep -q '3'; then
        if ! [ -e ~/instantos/wallpapers/wednesday ]; then
            echo "it is wallpaper wednesday my dudes"
            genwallpaper
            touch ~/instantos/wallpapers/wednesday
        else
            echo "wallpaper wednesday already happened"
        fi
    else
        # not wednesday, remove wednesday indicator
        if [ -e ~/instantos/wallpapers/wednesday ]; then
            echo "removing cache file"
            rm ~/instantos/wallpapers/wednesday
        fi
    fi
fi

if [ -z "$3" ]; then
    ifeh instantwallpaper.png
    if [ -n "$oldsum" ]; then
        newsum="$(md5sum ~/instantos/wallpapers/instantwallpaper.png | awk '{ print $1 }')"
        # generate new wallpaper if hash sums are equal
        if [ "$newsum" = "$oldsum" ]; then
            echo "regenerating failed wallpaper"
            checkinternet || exit 1

            WALLCOUNT="$(pgrep -f instantwallpaper | wc -l)"

            if [ "$WALLCOUNT" -gt 80 ]; then
                exit 1
            fi

            instantwallpaper w
            sleep 20
        fi
    fi
else
    echo "feh silenced"
fi
