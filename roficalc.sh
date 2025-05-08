#!/bin/bash

scrDir=$(dirname "$(realpath "$0")")
source $scrDir/globalcontrol.sh
roConf="${confDir}/rofi/calc.rasi"

enable_package libqalculate
rofi_pos

r_width="width: ${calc_width:-40em};"
r_height="height: ${calc_height:-23em};"
r_listview="listview { columns: 2 ;}"
r_override="window {$r_width border: ${hypr_width}px; border-radius: ${wind_border}px;} entry {border-radius: ${elem_border}px;} element {border-radius: ${elem_border}px;} ${r_listview} ${fnt_override} ${col_override} "

history_file="${cacheDir}/calculator.history"

get_history() {
  [[ -f $history_file ]] || mkdir -p "$(dirname "${history_file}")" && touch "${history_file}"
  { [[ ! -s $history_file ]] && echo "No history found"; } || cat "${history_file}"
}

is_in_history() { grep -q -x -F "$1" "${history_file}"; }

add_to_history() {
  file=$1
  content=$2
  awk -v var="${content}" 'BEGIN{print var} {print}' "${file}" >temp && mv temp "${file}"
  awk 'NF' "${file}" | awk '!seen[$0]++' >temp && mv temp "${file}"
}

result_from_equation() { printf "${1}" | sed 's/.*= //'; }

main() {
  while
    memory=$([[ -v result && -n $result ]] && echo "🟰 ${result}")
    if [[ -v customRoFile ]]; then
        input=$(get_history | rofi -dmenu -config "${customRoFile}")
    else
        input=$(get_history | rofi -dmenu -theme-str "entry { placeholder: \" ${memory:-"🧮 Calculate: "} \"; }" -theme-str "$r_override" -config "${roConf}")
    fi
    [[ -n $input ]]
  do
    # [[ $input == *"ans"* ]] && input="${input/ans/${result}}"
    equation=$({ is_in_history "$input" && echo "$input"; } || qalc "$input")
    add_to_history "${history_file}" "${equation}"
    unset result
    result="$(result_from_equation "${equation}")"
    notify-send -a "Result: " "${result}" & #-i ${usrDir}/show-calculator.svg 
    wl-copy "${result}"
  done
}

usage() {
    cat <<EOF
--reset 	        Reset cache
--rasi <PATH>			Set custom .rasi file. NOte that this removes all overrides

EOF

    exit 1
}

while (($# > 0)); do
  case $1 in
  --reset)
    rm -fr "${history_file}"
    print_prompt +g "[ok] " +y "reset"
    exit 0
    ;;
  --rasi)
    [[ -z ${2} ]] && print_prompt +r "[error] " +y "--rasi requires an file.rasi config file" && exit 1
    customRoFile=${2}
    shift
    ;;
  *)
    echo "Unknown option: $1"
    usage
    ;;
  esac
  shift # Shift off the current option being processed
done

# Always update currency at background
nohup qalc -e >/dev/null 2>&1 &


main "$@"