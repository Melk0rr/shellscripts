#!/usr/bin/bash

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

wallpaperDir="$HOME/Pictures/wallpapers/"
confThemeDir="${confDir}/hyde/themes"

for themeDir in "$wallpaperDir"*/; do
  themeDirName=$(basename "$themeDir")

  if [[ ! -d "${confThemeDir}/${themeDirName}" ]]; then
    mkdir "${confThemeDir}/${themeDirName}"
  fi

  if (
    ln -sf "${wallpaperDir}/${themeDirName}/wallpapers" "${confThemeDir}/${themeDirName}/wallpapers"
  ) >/dev/null 2>&1; then
    echo "Created link to ${themeDirName} wallpapers in $confThemeDir/${themeDirName}"
  else
    echo "Failed to create symlink to $themeDirName"
  fi
done
