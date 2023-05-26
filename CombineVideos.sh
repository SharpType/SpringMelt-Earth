#!/bin/bash

read -p "Enter a word: " word
word=$(echo "$word" | tr '[:lower:]' '[:upper:]')
word="${word// /}"

while getopts i flag
do
    case "${flag}" in
        i) inverse="true";;
    esac
done

input_files=()
for ((i=0; i<${#word}; i++)); do
  
    character="${word:i:1}"  
    file_name="Earth-$character.mp4"
    input_files+=("$file_name")
done

sum=$(for file in "${input_files[@]}"; do ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$file"; done | awk '{sum += $1} END {print sum}')

if ((sum > 3840)); then
  factor=$(echo "scale=3; $sum / 3840" | bc)
else
  factor=1
fi

num_files=${#input_files[@]}
individual_height=2160
filter_complex=""

for ((i=0; i<num_files; i++))
do
  individual_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 ${input_files[i]})
  filter_complex+="[${i}:v]scale=${individual_width}:${individual_height}[video${i}];"
done

filter_complex+="[video0]"
for ((i=1; i<num_files; i++))
do
  filter_complex+="[video${i}]"
done
filter_complex+="hstack=inputs=${num_files}[output]"

ffmpeg_cmd="ffmpeg"

for file in "${input_files[@]}"
do
  ffmpeg_cmd+=" -i ${file}"
done

ffmpeg_cmd+=" -vsync 2 -filter_complex '${filter_complex}' -map '[output]' -c:v libx264 -c:a copy Earth-$word.mp4"

eval "$ffmpeg_cmd"

if [[ $inverse ]]; then
  ffmpeg -i Earth-$word.mp4 -vf reverse -af areverse Earth-$word-inverse.mp4  
fi