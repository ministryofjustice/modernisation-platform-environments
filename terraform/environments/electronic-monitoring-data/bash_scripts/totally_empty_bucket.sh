#!/bin/bash

# Function to delete all objects, versions, and delete markers from a bucket
delete_bucket_contents() {
  bucket=$1
  echo "Deleting all objects and versions from $bucket..."

  # Delete all object versions
  aws s3api delete-objects --bucket $bucket --delete "$(aws s3api list-object-versions --bucket $bucket --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
  
  # Delete all delete markers
  aws s3api delete-objects --bucket $bucket --delete "$(aws s3api list-object-versions --bucket $bucket --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
}

# Main script
echo "Enter the prefix of the S3 buckets you want to delete contents from:"
read prefix

# Get the list of buckets that start with the prefix
buckets=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '$prefix') && !ends_with(Name, 'logs')].Name" --output text)

if [ -z "$buckets" ]; then
  echo "No buckets found with the prefix '$prefix'"
  exit 1
fi

# Loop through each bucket and delete contents
for bucket in $buckets
do
  delete_bucket_contents $bucket
done