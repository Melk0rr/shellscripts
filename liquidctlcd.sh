#!/usr/bin/bash

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

currWpp=$(readlink "${cacheDir}/wall.quad")
mode="static"

if [[ $currWpp == *"gif"* ]] ; then
  mode="gif"
fi

liquidctl --match kraken set lcd screen $mode "$currWpp"
