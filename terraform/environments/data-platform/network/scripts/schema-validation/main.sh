#!/usr/bin/env bash

SCHEMA="${1}"

case "${SCHEMA}" in
  fqdn|ip)
    ;;
  *)
    echo "Error: Invalid schema type. Use 'fqdn' or 'ip'."
    exit 1
    ;;
esac

echo "-> Validating YAML schema"
schemaValidation=$(uvx check-jsonschema \
  --schemafile "configuration/schema/rules/${SCHEMA}-rules.json" \
  "configuration/network-firewall/rules/${SCHEMA}-rules.yml")

if [ "${schemaValidation}" != "ok -- validation done" ]; then
  echo "Error: Schema validation failed for ${SCHEMA}-rules.yml"
  echo "${schemaValidation}"
  exit 1
else
  echo "Schema validation passed for ${SCHEMA}-rules.yml"
fi

echo "-> Validating SID uniqueness"
sidValidation=$(yq '[.rules[].sid] | length as $total | unique | length as $unique | $total == $unique' "configuration/network-firewall/rules/${SCHEMA}-rules.yml")
if [ "${sidValidation}" != "true" ]; then
  echo "Error: Duplicate SIDs found in ${SCHEMA}-rules.yml"
  exit 1
else
  echo "All SIDs are unique in ${SCHEMA}-rules.yml"
fi