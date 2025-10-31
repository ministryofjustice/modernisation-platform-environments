#!/usr/bin/env bash

# Contact Points and the Notification Policy Tree are tightly coupled, and you cannot delete a Contact Point without first removing it from the Notification Policy Tree.
# This script will delete a Contact Point from the Notification Policy Tree and then delete the Contact Point itself.
# To run this script, you will need to provide the following arguments:
# 1. The stage you are working in (e.g. development, production)
# 2. The name of the Contact Point you want to delete (e.g. xxx-slack, yyy-pagerduty)
# Example usage: bash contrib/delete-contact-point.sh development xxx-slack

ENVIRONMENT=$(basename ${PWD})
STAGE="${1}"
ROLE="modernisation-platform-developer"
CONTACT_POINT="${2}"

GRAFANA_API_KEY="$(aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- aws secretsmanager get-secret-value --secret-id grafana/api-key --query SecretString --output text)"
GRAFANA_WORKSPACE_ID="$(aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- aws grafana list-workspaces | jq -r '.workspaces[] | select(.name=="observability-platform") | .id')"
GRAFANA_ENDPOINT="https://${GRAFANA_WORKSPACE_ID}.grafana-workspace.eu-west-2.amazonaws.com"

# Get Notification Policy Tree
curl \
  --silent \
  --request GET \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --url "${GRAFANA_ENDPOINT}/api/v1/provisioning/policies" | jq > contrib/notification-policies-original.json

# Delete Contact Point from Notification Policy Tree
jq --arg CONTACT_POINT "${CONTACT_POINT}" 'del(.routes[] | select(.receiver==$CONTACT_POINT))' contrib/notification-policies-original.json > contrib/notification-policies-updated.json

# Put modified Notification Policy Tree
curl \
  --silent \
  --request PUT \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --data @contrib/notification-policies-updated.json \
  --url "${GRAFANA_ENDPOINT}/api/v1/provisioning/policies"

# Get Contact Point UID
getContactPointUid=$(curl \
  --silent \
  --request GET \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --url "${GRAFANA_ENDPOINT}/api/v1/provisioning/contact-points" | jq -r --arg CONTACT_POINT "${CONTACT_POINT}" '.[] | select(.name==$CONTACT_POINT) | .uid')

# Delete Contact Point
curl \
  --silent \
  --request DELETE \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer ${GRAFANA_API_KEY}" \
  --url "${GRAFANA_ENDPOINT}/api/v1/provisioning/contact-points/${getContactPointUid}"
