#!/bin/bash


BUCKET_PREFIX=$1
BUCKET_ACCOUNT_ID=$2


WHOAMI=$(aws sts get-caller-identity | jq -r '.Arn')

echo "{\"bucket_name\": \"$WHOAMI\"}"
exit 0

for BUCKET in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do
    if [[ $BUCKET =~ ${BUCKET_PREFIX}* ]]; then
    echo "{\"bucket_name\": \"$BUCKET\"}"
    break
  fi
done
exit 0

aws s3api list-buckets --query "Buckets[].Name" --output text > buckets.txt
for BUCKET in $(cat buckets.txt); do
  if [[ $BUCKET = ${BUCKET_PREFIX}* ]]; then
    OWNER_ID=$(aws s3api get-bucket-acl --bucket $BUCKET --query "Owner.ID" --output text)
    if [[ $OWNER_ID == ${BUCKET_ACCOUNT_ID} ]]; then
      echo "{\"bucket_name\": \"$BUCKET\"}"
      break
    fi
  fi
done
