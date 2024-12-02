#!/bin/bash

# Function to copy all objects from source bucket to destination bucket
copy_bucket_contents() {
  source_bucket=$1
  destination_bucket=$2
  echo "Copying contents from $source_bucket to $destination_bucket..."

  # Copy all objects from source bucket to destination bucket
  aws s3 sync s3://$source_bucket s3://$destination_bucket
}

# Main script
echo "Enter the source prefix of the S3 buckets you want to copy from:"
read source_prefix

echo "Enter the destination prefix of the S3 buckets you want to copy to:"
read destination_prefix

# Get the list of source buckets that start with the source prefix and exclude buckets with the 'logs' suffix
source_buckets=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '$source_prefix') && !ends_with(Name, 'logs')].Name" --output text)

if [ -z "$source_buckets" ]; then
  echo "No source buckets found with the prefix '$source_prefix' (excluding buckets with 'logs' suffix)"
  exit 1
fi

# Get the list of destination buckets that start with the destination prefix
destination_buckets=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '$destination_prefix')].Name" --output text)

if [ -z "$destination_buckets" ]; then
  echo "No destination buckets found with the prefix '$destination_prefix'"
  exit 1
fi

# Match source buckets to destination buckets based on suffix
declare -A bucket_map

for source_bucket in $source_buckets
do
  echo "For source bucket: $source_bucket..."
  for destination_bucket in $destination_buckets
  do
    echo "Do you want to copy $source_bucket to destination bucket $destination_bucket? (y/n)"
    read answer

    if [ "$answer" == "y" ]; then
      selected_destination=$destination_bucket
      break
    fi
  done
  # If the user selected a destination bucket, copy the contents
  if [ -n "$selected_destination" ]; then
    copy_bucket_contents $source_bucket $selected_destination
  else
    echo "No destination bucket selected for $source_bucket, skipping..."
  fi
done

echo "Done!"