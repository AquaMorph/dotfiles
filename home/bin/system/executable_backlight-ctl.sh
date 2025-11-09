#!/usr/bin/env bash

# Print help info.
function print_help() {
  echo 'Control the backlight brightness with animation.'
  echo
  echo '-i    -- increase brightness'
  echo '-d    -- decrease brightness'
}

# Increase backlight brightness.
function increase() {
  run_animation 'light -A 0.1'
}

# Decrease backlight brightness.
function decrease() {
  run_animation 'light -U 0.1'
}

# Run animation task.
function run_animation() {
  local cmd="${1}"
  i=0
  while [ $i -lt 50 ]; do
    ${cmd}
    sleep 0.01
    ((i = i + 1));
  done
}


# Check arguments
for i in "$@"; do
  case $i in
    -h|--help)
      print_help
      exit 0
      ;;
    -i)
      increase
      ;;
    -d)
      decrease
      ;;
    *)
      print_help
      exit 1
      ;;
  esac
done

