#!/bin/bash

# Read the input from Terraform
read input

database_name=$(echo "$input" | jq -r '.file_content' | grep database_standby_sid: | cut -d' ' -f2)
audited_interaction_repository=$(echo "$input" | jq -r '.file_content' | grep audited_interaction_repository: | cut -d' ' -f2)
active_data_guard=$(echo "$input" | jq -r '.file_content' | grep active_data_guard: | cut -d' ' -f2)

# Output the data in JSON format
echo "{\"database_name\": \"$database_name\", \"audited_interaction_repository\": \"$audited_interaction_repository\", \"active_data_guard\": \"$active_data_guard\"}"
