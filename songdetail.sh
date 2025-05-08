#!/usr/bin/bash

player_status=$(playerctl status)

icon=$(case $player_status in
    "Playing") echo "" ;;
    "Paused")  echo "" ;;
    *)         echo "" ;;
esac)  

song_info=$(playerctl metadata --format "$icon   {{artist}}   -   {{title}}")

echo "$song_info" 
