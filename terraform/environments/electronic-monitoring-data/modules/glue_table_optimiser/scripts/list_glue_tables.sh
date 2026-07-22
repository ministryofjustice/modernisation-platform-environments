#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
database_name="$(echo "$input" | jq -r '.database_name')"
region="$(echo "$input" | jq -r '.region')"

if [[ -z "$database_name" || "$database_name" == "null" ]]; then
  echo '{"tables_json":"[]","locations_json":"{}"}'
  exit 0
fi

next_token=""
table_names_json='[]'
table_locations_json='{}'

while true; do
  if [[ -n "$next_token" ]]; then
    response="$(aws glue get-tables --region "$region" --database-name "$database_name" --query "{TableList: TableList[?Parameters.presto_view=='true'], NextToken: NextToken}" --next-token "$next_token" --output json)"
  else
    response="$(aws glue get-tables --region "$region" --database-name "$database_name" --query "{TableList: TableList[?Parameters.presto_view=='true'], NextToken: NextToken}" --output json)"
  fi

  page_table_names="$(echo "$response" | jq -c '[.TableList[]?.Name]')"
  page_table_locations="$(echo "$response" | jq -c '[.TableList[]? | { key: .Name, value: (.StorageDescriptor.Location // "") }] | from_entries')"

  table_names_json="$(jq -cn --argjson current "$table_names_json" --argjson page "$page_table_names" '$current + $page')"
  table_locations_json="$(jq -cn --argjson current "$table_locations_json" --argjson page "$page_table_locations" '$current * $page')"

  next_token="$(echo "$response" | jq -r '.NextToken // ""')"
  if [[ -z "$next_token" ]]; then
    break
  fi
done

jq -cn \
  --arg tables_json "$table_names_json" \
  --arg locations_json "$table_locations_json" \
  '{tables_json: $tables_json, locations_json: $locations_json}'