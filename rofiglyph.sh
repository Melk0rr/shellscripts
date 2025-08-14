#!/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir"/globalcontrol.sh

rofi_pos

enable_package wtype
# trap 'killall wtype' EXIT

#* This glyph Data is from `https://www.nerdfonts.com/cheat-sheet`
#* I don't own anything of it
#TODO:   Needed a way to fetch the glyph from the NerdFonts source.
#TODO:    find a way make the  DB update
#TODO:    make the update Script run on User space

glyphDATA="${etcDir}/glyph.db"
recentData="${cacheDir}/landing/show_glyph.recent"

save_recent() {
    #? Prepend the selected glyph to the top of the recentData file
    # sed -i "1i\\$selGlyph" "${recentData}"
    awk -v var="$dataGlyph" 'BEGIN{print var} {print}' "${recentData}" > temp && mv temp "${recentData}"
    #?  Use awk to remove duplicates and empty lines, moving the most recent glyph to the top
    awk 'NF' "${recentData}" | awk '!seen[$0]++' > temp && mv temp "${recentData}"
}

if [[ ! -f "${recentData}" ]]; then
    echo "  Arch linux I use Arch BTW" > "${recentData}"
fi
#? Read the contents of recent.db and main.db separately
recent_entries=$(cat "${recentData}")
main_entries=$(cat "${glyphDATA}")
#? Combine the recent entries with the main entries
combined_entries="${recent_entries}\n${main_entries}"
#? Remove duplicates from the combined entries
unique_entries=$(echo -e "${combined_entries}" | awk '!seen[$0]++')

dataGlyph=$(echo "${unique_entries}" | rofi -dmenu -multi-select -i -theme-str  "entry { placeholder: \"   Glyph\";} ${pos} ${r_override}" -theme-str "${fnt_override}" -config "${roConf}")
# selGlyph=$(echo -n "${selGlyph}" | cut -d' ' -f1 | tr -d '\n' | wl-copy)
trap save_recent EXIT
selGlyph=$(printf "%s" "${dataGlyph}" | cut -d' ' -f1 | tr -d '\n\r' )
wl-copy "${selGlyph}"
pasteIt "${*}"
