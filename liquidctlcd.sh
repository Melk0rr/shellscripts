#!/usr/bin/bash

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

currWpp=$(readlink "${cacheDir}/wall.set")
lcdWpp=$(readlink "${cacheDir}/wall.sqre")
mode="static"

if [[ $currWpp == *"gif"* ]] ; then
  lcdWpp=$currWpp
  mode="gif"
fi

liquidctl --match kraken set lcd screen $mode "$lcdWpp"
