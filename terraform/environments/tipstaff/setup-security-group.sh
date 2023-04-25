#! /bin/bash

export AWS_ACCESS_KEY_ID=$DMS_TARGET_ACCOUNT_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$DMS_TARGET_ACCOUNT_SECRET_KEY
export AWS_REGION=$DMS_TARGET_ACCOUNT_REGION

echo "AWS_ACCESS_KEY_ID = $DMS_TARGET_ACCOUNT_ACCESS_KEY"
echo "AWS_SECRET_ACCESS_KEY = $DMS_TARGET_ACCOUNT_SECRET_KEY"
echo "AWS_REGION = $DMS_TARGET_ACCOUNT_REGION"

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile dts-legacy-apps-user &&
aws configure set aws_secret_access_key "$AWS_ACCESS_KEY_SECRET" --profile dts-legacy-apps-user &&
aws configure set region "$AWS_REGION" --profile dts-legacy-apps-user &&
aws configure set output "json" --profile dts-legacy-apps-user

aws rds modify-db-instance --db-instance-identifier postgresql-staging --vpc-security-group-ids sg-08244ba362f922899 sg-0e0f5cf0883f81945 sg-04e9fe073afcc6b65 sg-00d9f1ef7526944ea ${DMS_SECURITY_GROUP}