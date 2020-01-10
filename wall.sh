#!/bin/bash

#######################################
## chromecast like wallpaper changer ##
#######################################
source <(curl -Ls https://git.io/JerLG)
pb instantos

mkdir -p $HOME/instantos/wallpapers/default &>/dev/null
cd $HOME/instantos/wallpapers

randomwallpaper() {
    file="$HOME/instantos/wallpapers/photo.jpg"
    if curl google.com; then
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

        wget -qO "$file" "$url/$(fetch | shuf -n 1)"
    fi
}

instantoverlay() {
    [ -e overlay.png ] || wget -q "https://raw.githubusercontent.com/instantOS/instantLOGO/master/wallpaper/overlay.png"
}

instantoverlay

if ! [ -e ./default/$(getinstanttheme).png ]; then
    echo "generating default wallpaper"
    cd default
    convert overlay.png -fill "$(instantforeground)" -colorize 100 color.png
    convert color.png -background "$(instantbackground)" -alpha remove -alpha off "$(getinstanttheme)".png
    rm color.png
    cd ..
fi
