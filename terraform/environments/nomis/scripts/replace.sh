#!/bin/bash
# Replace one variable for another in all terraform files
#
# Put the variables to replace in a file called replace.txt containing:
# <match> <replace> [<only_on_lines_matching_this>]
# e.g.
# module.config.app_tags module.config.map.app_tags
# \"Production\" \"prod\" app_env

set -e
CONFIG_FILENAME="replace.txt"

config=()
num_config_lines=0

read_config() {
  IFS=$'\n'
  if [[ ! -e $CONFIG_FILENAME ]]; then
    echo "Config filename does not exist: $CONFIG_FILENAME" >&2
    return 1
  fi
  config=($(cat "$CONFIG_FILENAME"))
  unset IFS
  num_config_lines=${#config[@]}
}

replace() {
  for (( i=0; i<num_config_lines; i++ )); do
    items=(${config[i]})
    if [[ -z ${items[0]} || -z ${items[1]} || ${items[0]} == \#*  ]]; then
      echo "Skipping line #$((i+1)): ${config[i]}" >&2
    elif [[ -z ${items[2]} ]]; then
      echo "gsed -i 's/${items[0]}/${items[1]}/g' *.tf" >&2
      gsed -i "s/${items[0]}/${items[1]}/g" *.tf 
    else
      echo "gsed -i '/${items[2]}/s/${items[0]}/${items[1]}/' *.tf" >&2
      gsed -i "/${items[2]}/s/${items[0]}/${items[1]}/" *.tf
    fi  
  done
}

main() {
  read_config
  replace
}

main "$@"
