#!/bin/bash
set -euo pipefail

input="$(cat)"
database_name="$(echo "$input" | jq -r '.database_name')"
region="$(echo "$input" | jq -r '.region')"

if [[ -z "$database_name" || "$database_name" == "null" ]]; then
  echo '{"tables_json":"[]"}'
  exit 0
fi

next_token=""
table_names_json='[]'

while true; do
  if [[ -n "$next_token" ]]; then
    response="$(aws glue get-tables --region "$region" --database-name "$database_name" --next-token "$next_token" --output json)"
  else
    response="$(aws glue get-tables --region "$region" --database-name "$database_name" --output json)"
  fi

  page_table_names="$(echo "$response" | jq -c '[.TableList[]?.Name]')"
  table_names_json="$(jq -cn --argjson current "$table_names_json" --argjson page "$page_table_names" '$current + $page')"

  next_token="$(echo "$response" | jq -r '.NextToken // ""')"
  if [[ -z "$next_token" ]]; then
    break
  fi
done

echo "{\"tables_json\":$(jq -Rn --arg value "$table_names_json" '$value')}"
