#!/bin/bash

REPO_NAME=$1
FUNCTION_NAME=$2

LATEST_IMAGE=$(aws ecr describe-images --repository-name "$REPO_NAME" --query "sort_by(imageDetails,& imagePushedAt)[*].{ImageURI:imageUri,Tag:ImageTags[0]}" --output json | jq -r --arg FUNCTION_NAME "$FUNCTION_NAME" '[.[] | select(.Tag | startswith($FUNCTION_NAME))] | last | .ImageURI')

# Check if LATEST_IMAGE is empty
if [ -z "$LATEST_IMAGE" ]; then
  echo "{\"error\": \"No image found for function name $FUNCTION_NAME\"}"
  exit 1
fi

echo "{\"latest_image_uri\": \"$LATEST_IMAGE\"}"
