#!/bin/bash

# Load suppression list from JSON file
SUPPRESSION_FILE="modules/ses/suppressed-ses.json"

# Parse JSON and add each suppressed email
jq -c '.SuppressedDestinations[]' $SUPPRESSION_FILE | while read -r entry; do
  EMAIL=$(echo $entry | jq -r '.EmailAddress')
  REASON=$(echo $entry | jq -r '.Reason')

  echo "Adding $EMAIL to suppression list..."
  aws sesv2 put-suppressed-destination --email-address "$EMAIL" --reason "$REASON"
done

echo "Suppression list import complete."