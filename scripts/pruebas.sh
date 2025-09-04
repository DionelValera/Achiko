#!/usr/bin/env bash

# shellcheck disable=SC2034 # https://github.com/koalaman/shellcheck/wiki/SC2034

# Load in the functions and animations
source ./bash_loading_animations.sh
# Run BLA::stop_loading_animation if the script is interrupted
trap BLA::stop_loading_animation SIGINT

demo_loading_animation() {
  BLA_active_loading_animation=( "${@}" )
  # Extract the delay between each frame from the active_loading_animation array
  BLA_loading_animation_frame_interval="${BLA_active_loading_animation[0]}"
  # Sleep long enough that all frames are showed
  # substract 1 to the number of frames to account for index [0]
  demo_duration=$( echo "${BLA_active_loading_animation[0]} * ( ${#BLA_active_loading_animation[@]} - 1 )" | bc )
  # Make sure each animation is shown for at least 3 seconds
  if [[ $( echo "if (${demo_duration} < 3) 0 else 1" | bc ) -eq 0 ]] ; then
    demo_duration=3
  fi
  unset "BLA_active_loading_animation[0]"
  echo
  BLA::play_loading_animation_loop &
  BLA_loading_animation_pid="${!}"
  sleep "${demo_duration}"
  kill "${BLA_loading_animation_pid}" &> /dev/null
  clear
}

tput civis # Hide the terminal cursor
clear

demo_loading_animation "${BLA_filling_bar[@]}"
demo_loading_animation "${BLA_quarter[@]}"
demo_loading_animation "${BLA_semi_circle[@]}"
demo_loading_animation "${BLA_braille[@]}"
demo_loading_animation "${BLA_braille_whitespace[@]}"
demo_loading_animation "${BLA_modern_metro[@]}"
demo_loading_animation "${BLA_circle_quadrants[@]}"
demo_loading_animation "${BLA_arc[@]}"
demo_loading_animation "${BLA_vertical_blocks[@]}"
demo_loading_animation "${BLA_horizontal_blocks[@]}"

tput cnorm # Restore the terminal cursor

exit 0