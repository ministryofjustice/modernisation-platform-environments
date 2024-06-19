#!/bin/bash

# Read the input from Terraform
read input

database_name=$(echo "$input" | jq -r '.file_content' | grep database_standby_sid: | cut -d' ' -f2)

# Output the data in JSON format
echo "{\"database_name\": \"$database_name\"}"
