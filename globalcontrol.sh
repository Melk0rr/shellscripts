#!/usr/bin/bash

# HYDE-CLI
export CLI_PATH=$(dirname $(dirname "${0}"))
export PATH=$PATH:${CLI_PATH}/lib/hyde-cli/

# Cli Configs
export etcDir="/etc/hyde-cli"
 [[ "${CLI_PATH}" == *"/usr"* ]] || etcDir="$HOME/.hyde"
export usrDir="${CLI_PATH}/share/hyde-cli"

# xdg resolution
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# hyde envs
export HYDE_CONFIG_HOME="${XDG_CONFIG_HOME}/hyde"
export HYDE_DATA_HOME="${XDG_DATA_HOME}/hyde"
export HYDE_CACHE_HOME="${XDG_CACHE_HOME}/hyde"
export HYDE_STATE_HOME="${XDG_STATE_HOME}/hyde"
export HYDE_RUNTIME_DIR="${XDG_RUNTIME_DIR}/hyde"
export ICONS_DIR="${XDG_DATA_HOME}/icons"
export FONTS_DIR="${XDG_DATA_HOME}/fonts"
export THEMES_DIR="${XDG_DATA_HOME}/themes"

#legacy hyde envs // should be deprecated

export confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
export hydeConfDir="$HYDE_CONFIG_HOME"
export cacheDir="$HYDE_CACHE_HOME"
export thmbDir="$HYDE_CACHE_HOME/thumbs"
export dcolDir="$HYDE_CACHE_HOME/dcols"
export iconsDir="$ICONS_DIR"
export themesDir="$THEMES_DIR"
export fontsDir="$FONTS_DIR"
export hashMech="sha1sum"


source_user() {
    [ -f "${hydeConfDir}/hyde.conf" ] && . "${hydeConfDir}/hyde.conf"
}

get_hashmap() {
    unset wallHash
    unset wallList
    unset skipStrays
    unset verboseMap

    for wallSource in "$@"; do
        [ -z "${wallSource}" ] && continue
        [ "${wallSource}" == "--skipstrays" ] && skipStrays=1 && continue
        [ "${wallSource}" == "--verbose" ] && verboseMap=1 && continue

        supported_files=(
            "gif"
            "jpg"
            "jpeg"
            "png"
        )

        supported_files+=("${WALLPAPER_FILETYPES=[@]}") # Add custom wallpaper types # ! this should conform to the backend

        hashMap=$(
            # shellcheck disable=SC2046
            find -L "${wallSource}" -type f \
                \( $(printf -- "-iname *.%s -o " "${supported_files[@]}" | sed 's/ -o $//') \) ! -path "*/logo/*" \
                -exec "${hashMech}" {} + 2>/dev/null |
                sort -k2
        )
        # hashMap=$(
        # find "${wallSource}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.mkv"  \) ! -path "*/logo/*" -exec "${hashMech}" {} + | sort -k2
        # )

        if [ -z "${hashMap}" ]; then
            notify-send -a "HyDE Alert" "WARNING: No compatible wallpapers found in \"${wallSource}\""
            continue
        fi

        while read -r hash image; do
            wallHash+=("${hash}")
            wallList+=("${image}")
        done <<<"${hashMap}"
    done

    if [ -z "${#wallList[@]}" ] || [[ "${#wallList[@]}" -eq 0 ]]; then
        if [[ "${skipStrays}" -eq 1 ]]; then
            return 1
        else
            echo "ERROR: No image found in any source"
            exit 1
        fi
    fi

    if [[ "${verboseMap}" -eq 1 ]]; then
        echo "// Hash Map //"
        for indx in "${!wallHash[@]}"; do
            echo ":: \${wallHash[${indx}]}=\"${wallHash[indx]}\" :: \${wallList[${indx}]}=\"${wallList[indx]}\""
        done
    fi
}

# shellcheck disable=SC2120
get_themes() {
    unset thmSortS
    unset thmListS
    unset thmWallS
    unset thmSort
    unset thmList
    unset thmWall

    while read -r thmDir; do
        local realWallPath
        realWallPath="$(readlink "${thmDir}/wall.set")"
        if [ ! -e "${realWallPath}" ]; then
            get_hashmap "${thmDir}" --skipstrays || continue
            echo "fixing link :: ${thmDir}/wall.set"
            ln -fs "${wallList[0]}" "${thmDir}/wall.set"
        fi
        [ -f "${thmDir}/.sort" ] && thmSortS+=("$(head -1 "${thmDir}/.sort")") || thmSortS+=("0")
        thmWallS+=("${realWallPath}")
        thmListS+=("${thmDir##*/}") # Use this instead of basename
    done < <(find "${hydeConfDir}/themes" -mindepth 1 -maxdepth 1 -type d)

    while IFS='|' read -r sort theme wall; do
        thmSort+=("${sort}")
        thmList+=("${theme}")
        thmWall+=("${wall}")
    done < <(paste -d '|' <(printf "%s\n" "${thmSortS[@]}") <(printf "%s\n" "${thmListS[@]}") <(printf "%s\n" "${thmWallS[@]}") | sort -n -k 1 -k 2)
    #!  done < <(parallel --link echo "{1}\|{2}\|{3}" ::: "${thmSortS[@]}" ::: "${thmListS[@]}" ::: "${thmWallS[@]}" | sort -n -k 1 -k 2) # This is overkill and slow
    if [ "${1}" == "--verbose" ]; then
        echo "// Theme Control //"
        for indx in "${!thmList[@]}"; do
            echo -e ":: \${thmSort[${indx}]}=\"${thmSort[indx]}\" :: \${thmList[${indx}]}=\"${thmList[indx]}\" :: \${thmWall[${indx}]}=\"${thmWall[indx]}\""
        done
    fi
}

source_user

case "${enableWallDcol}" in
    0|1|2|3) ;;
    *) enableWallDcol=0 ;;
esac

if [ -z "${hydeTheme}" ] || [ ! -d "${hydeConfDir}/themes/${hydeTheme}" ] ; then
    get_themes
    hydeTheme="${thmList[0]}"
fi

export hydeTheme
export sddmTheme
export hydeThemeDir="${hydeConfDir}/themes/${hydeTheme}"
export wallbashDir="${hydeConfDir}/wallbash"
export enableWallDcol


#// hypr vars

if printenv HYPRLAND_INSTANCE_SIGNATURE &> /dev/null; then
    export hypr_border="$(hyprctl -j getoption decoration:rounding | jq '.int')"
    export hypr_width="$(hyprctl -j getoption general:border_size | jq '.int')"
fi


#// extra fns

pkg_installed()
{
    local pkgIn=$1
    if pacman -Qi "${pkgIn}" &> /dev/null ; then
        return 0
    elif pacman -Qi "flatpak" &> /dev/null && flatpak info "${pkgIn}" &> /dev/null ; then
        return 0
    elif command -v "${pkgIn}" &> /dev/null ; then
        return 0
    else
        return 1
    fi
}

get_aurhlpr()
{
    if pkg_installed yay
    then
        aurhlpr="yay"
    elif pkg_installed paru
    then
        aurhlpr="paru"
    fi
}

set_conf()
{
    local varName="${1}"
    local varData="${2}"
    touch "${hydeConfDir}/hyde.conf"

    if [ $(grep -c "^${varName}=" "${hydeConfDir}/hyde.conf") -eq 1 ] ; then
        sed -i "/^${varName}=/c${varName}=\"${varData}\"" "${hydeConfDir}/hyde.conf"
    else
        echo "${varName}=\"${varData}\"" >> "${hydeConfDir}/hyde.conf"
    fi
}

set_hash()
{
    local hashImage="${1}"
    "${hashMech}" "${hashImage}" | awk '{print $1}'
}

enable_package() {
    local Pkg_Dep=$(for PkgIn in "$@"; do ! pkg_installed "$PkgIn" && echo "$PkgIn"; done)
    if [[ -n "${Pkg_Dep}" ]]; then
        echo -e "$0 Dependencies:\n$Pkg_Dep"
        get_aurhlpr
        if [ -n "${DISPLAY}" ]; then
            notify-send -a "${0}" "Confirm to install dependencies: '${Pkg_Dep}'" -t 10000
            print_prompt -y "Confirm to install dependencies: '${Pkg_Dep}'"
            { pkexec --user "${USER}" env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" "${aurhlpr}" -S "$Pkg_Dep" --noconfirm && notify-send "Installed: ${Pkg_Dep}"; } || { notify-send "Operation Cancelled" && exit 1; }
        else
            print_prompt -y "Confirm to install dependencies: '${Pkg_Dep}'"
            { "${aurhlpr}" -S "$Pkg_Dep" --noconfirm && print_prompt -y "Installed: ${Pkg_Dep}"; } || { print_prompt -r "Operation cancelled" && exit 1; }
        fi

    fi
}

print_prompt() {
    while (("$#")); do
        case "$1" in
        -r|+r)
            echo -ne "\e[31m$2\e[0m"
            shift 2
            ;; # Red
        -g|+g)
            echo -ne "\e[32m$2\e[0m"
            shift 2
            ;; # Green
        -y|+y)
            echo -ne "\e[33m$2\e[0m"
            shift 2
            ;; # Yellow
        -b|+b)
            echo -ne "\e[34m$2\e[0m"
            shift 2
            ;; # Blue
        -m|+m)
            echo -ne "\e[35m$2\e[0m"
            shift 2
            ;; # Magenta
        -c|+c)
            echo -ne "\e[36m$2\e[0m"
            shift 2
            ;; # Cyan
        -wt|+w)
            echo -ne "\e[37m$2\e[0m"
            shift 2
            ;; # White
        -n|+n)
            echo -ne "\e[96m$2\e[0m"
            shift 2
            ;; # Neon
        -crit)
            echo -ne "\e[38;5;160m$2\e[0m"
            shift 2
            ;; # Neon            
        +)
            echo -ne "\e[38;5;$2m$3\e[0m"
            shift 3
            ;;
        *)
            echo -ne "$1"
            shift
            ;;
        esac
    done
    echo ""
}

rofi_pos() {
    pkill -x rofi && exit
    enable_package rofi jq
    source_user
    roConf="${confDir}/rofi/clipboard.rasi"

    #// set rofi scaling

    [[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10
    rofiScale=$((rofiScale + 1))
    fnt_override="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
    wind_border=$((hypr_border * 3 / 2))
    elem_border=$([ $hypr_border -eq 0 ] && echo "5" || echo $hypr_border)

    #// evaluate spawn position

    readarray -t curPos < <(hyprctl cursorpos -j | jq -r '.x,.y')
    readarray -t monRes < <(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width,.height,.scale,.x,.y')
    readarray -t offRes < <(hyprctl -j monitors | jq -r '.[] | select(.focused==true).reserved | map(tostring) | join("\n")')
    monRes[2]="$(echo "${monRes[2]}" | sed "s/\.//")"
    monRes[0]="$((${monRes[0]} * 100 / ${monRes[2]}))"
    monRes[1]="$((${monRes[1]} * 100 / ${monRes[2]}))"
    curPos[0]="$((${curPos[0]} - ${monRes[3]}))"
    curPos[1]="$((${curPos[1]} - ${monRes[4]}))"

    if [ "${curPos[0]}" -ge "$((${monRes[0]} / 2))" ]; then
        x_pos="east"
        x_off="-$((${monRes[0]} - ${curPos[0]} - ${offRes[2]}))"
    else
        x_pos="west"
        x_off="$((${curPos[0]} - ${offRes[0]}))"
    fi

    if [ "${curPos[1]}" -ge "$((${monRes[1]} / 2))" ]; then
        y_pos="south"
        y_off="-$((${monRes[1]} - ${curPos[1]} - ${offRes[3]}))"
    else
        y_pos="north"
        y_off="$((${curPos[1]} - ${offRes[1]}))"
    fi

    r_override="window{location:${x_pos} ${y_pos};anchor:${x_pos} ${y_pos};x-offset:${x_off}px;y-offset:${y_off}px;border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
}
