#! /bin/bash

export AWS_ACCESS_KEY_ID=$DMS_TARGET_ACCOUNT_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$DMS_TARGET_ACCOUNT_SECRET_KEY
export AWS_DEFAULT_REGION=$DMS_TARGET_ACCOUNT_REGION

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile dts-legacy-apps-user &&
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile dts-legacy-apps-user &&
aws configure set region "$AWS_DEFAULT_REGION" --profile dts-legacy-apps-user &&
aws configure set output "json" --profile dts-legacy-apps-user

aws rds modify-db-instance --db-instance-identifier tipstaff --vpc-security-group-ids sg-08244ba362f922899 sg-06f29e836693c21dd ${DMS_SECURITY_GROUP} --profile dts-legacy-apps-user