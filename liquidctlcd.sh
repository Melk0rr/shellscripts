#!/usr/bin/bash

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

currWpp=$(readlink "${cacheDir}/wall.sqre")
mode="static"

if [[ $currWpp == *"gif"* ]] ; then
  $currWpp=$(readlink "${cacheDir}/wall.set")
  mode="gif"
fi

liquidctl --match kraken set lcd screen $mode "$currWpp"
