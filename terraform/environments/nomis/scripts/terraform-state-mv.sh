#!/bin/bash

main() {
  if [[ -z $1 ]]; then
    echo "Usage $0: <filename>"
    echo "Where filename is pipe separated file containing containing 'existing_resource_id|new_resource_id'"
    return 1
  fi
  if [[ ! -e $1 ]]; then
    echo "Config filename does not exist: $1" >&2
    return 1
  fi

  IFS=$'\n'
  config=($(grep -v '^#' "$1" | grep -v '^$'))
  unset IFS

  num_config_lines=${#config[@]}
  for (( i=0; i<num_config_lines; i++ )); do
    IFS='|'
    items=(${config[$i]})
    unset IFS
    if [[ ${#items[@]} -ne 2 ]]; then
      echo "Invalid config file.  Expected exactly 2 items on a line.  line $((i+1)): ${config[i]}"
      return 1
    fi
  done  

  echo "# terraform state list" >&2
  statelist=$(terraform state list)

  for (( i=0; i<num_config_lines; i++ )); do
    IFS='|'
    items=(${config[$i]})
    unset IFS
    IDS=$(echo "${statelist}" | grep "^${items[0]}" || true)
    for ID in $IDS; do
      echo "$1: terraform state mv '$ID' '${ID/${items[0]}/${items[1]}}'"
      echo terraform state mv "$ID" "${ID/${items[0]}/${items[1]}}"
    done
  done
}

main "$@"
