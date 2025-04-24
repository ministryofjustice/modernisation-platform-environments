#!/bin/sh

#Set variables
source_env_name=$1
source_bucket_name=$2
source_account_number=$3
dest_bucket_name=$4
dest_account_number=$5

script_location=$(dirname -- "$( readlink -f -- "$0"; )");
script_location=${script_location/\/c\//\/c:/}


eval "cat <<EOF
$(<./replication-configuration.json.template)
EOF
" > ./replication-configuration.json

eval "cat <<EOF
$(<./manifest-generator.json.template)
EOF
" > ./manifest-generator.json

echo ""
echo "Configuring Replication for " $source_bucket_name
echo aws s3api put-bucket-versioning --bucket $source_bucket_name --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning --bucket $source_bucket_name --versioning-configuration Status=Enabled

echo ""
echo aws s3api put-bucket-replication --bucket $source_bucket_name --replication-configuration file:/${script_location}/replication-configuration.json
aws s3api put-bucket-replication --bucket $source_bucket_name --replication-configuration file:/${script_location}/replication-configuration.json

echo ""
echo aws s3control create-job --account-id $source_account_number \
 --operation "{\"S3ReplicateObject\":{}}" \
 --report "{\"Bucket\": \"arn:aws:s3:::yjaf-${source_env_name}-replication-manifests\", \"Prefix\":\"batch-replication-report\", \"Format\": \"Report_CSV_20180820\", \"Enabled\": true, \"ReportScope\": \"AllTasks\"}" \
 --manifest-generator file:/${script_location}/manifest-generator.json \
 --priority 1 --role-arn arn:aws:iam::${source_account_number}:role/cross-account-bucket-replication-role --no-confirmation-required

aws s3control create-job --account-id $source_account_number \
--operation "{\"S3ReplicateObject\":{}}" \
--report "{\"Bucket\": \"arn:aws:s3:::yjaf-${source_env_name}-replication-manifests\", \"Prefix\":\"batch-replication-report\", \"Format\": \"Report_CSV_20180820\", \
    \"Enabled\": true, \"ReportScope\": \"AllTasks\"}" \
--manifest-generator file:/${script_location}/manifest-generator.json \
--priority 1 --role-arn arn:aws:iam::${source_account_number}:role/cross-account-bucket-replication-role --no-confirmation-required
