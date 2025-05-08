#!/usr/bin/bash

#// set variables
scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

wallSet="${hydeThemeDir}/wall.set"
mozProfile=$(grep "Default=" ~/.mozilla/firefox/profiles.ini | head -n 1 | cut -s -f 2 -d =)
floorpProfile=$(grep "Default=" ~/.floorp/profiles.ini | tail -n 1 | cut -s -f 2 -d '=')
zenProfile=$(grep "Default=" ~/.zen/profiles.ini | tail -n 1 | cut -s -f 2 -d '=')

mozDir="$HOME/.mozilla/firefox/${mozProfile}"
floorpDir="$HOME/.floorp/${floorpProfile}"
zenDir="$HOME/.zen/${zenProfile}"

mkdir -p "$mozDir"/chrome
mkdir -p "$floorpDir"/chrome
mkdir -p "$zenDir"/chrome

ln -sf "$(readlink "${wallSet}")" "$mozDir"/chrome/wall.set
ln -sf "$(readlink "${wallSet}")" "$floorpDir"/chrome/wall.set
ln -sf "$(readlink "${wallSet}")" "$zenDir"/chrome/wall.set
magick "$(readlink "${wallSet}")" "$HOME"/.config/BraveSoftware/Brave-Browser/wall.jpg
