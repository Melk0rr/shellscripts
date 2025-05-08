#!/bin/bash

scrDir=`dirname "$(realpath "$0")"`
source $scrDir/globalcontrol.sh

sudo cp "${confDir}/sddm/themes/corners/theme.conf" "/usr/share/sddm/themes/corners/theme.conf"
sudo cp "${confDir}/sddm/themes/astronaut/theme.conf" "/usr/share/sddm/themes/astronaut/Themes/astronaut.conf"