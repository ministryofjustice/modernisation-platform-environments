#!/bin/bash

# Get the current date in seconds
now=$(date +%s)

# Get the AWS SSO session expiration date in seconds
# Assuming AWS_SSO_SESSION_EXPIRATION is in a format like '2024-01-24 05:34:21 UTC'
sessionExpiration=$(echo "$AWS_SSO_SESSION_EXPIRATION" | awk '{print $1 " " $2 " " $4}')
expiration=$(date -d "$sessionExpiration" +%s)

# Calculate the difference in seconds
diff=$((expiration-now))

# Convert the difference to human-readable format
days=$((diff/86400))
hours=$((diff%86400/3600))
minutes=$((diff%3600/60))
seconds=$((diff%60))

echo "Time left: $hours hours, $minutes minutes, $seconds seconds"