#! /bin/bash

export AWS_ACCESS_KEY_ID=$RDS_SOURCE_ACCOUNT_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$RDS_SOURCE_ACCOUNT_SECRET_KEY
export AWS_DEFAULT_REGION=$RDS_SOURCE_ACCOUNT_REGION

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile dts-legacy-apps-user &&
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile dts-legacy-apps-user &&
aws configure set region "$AWS_DEFAULT_REGION" --profile dts-legacy-apps-user &&
aws configure set output "json" --profile dts-legacy-apps-user

aws rds modify-db-instance --db-instance-identifier postgresql-dev --vpc-security-group-ids sg-08244ba362f922899 sg-0e0f5cf0883f81945 sg-02938dce60af69c14 sg-05ea046c ${RDS_SECURITY_GROUP} --profile dts-legacy-apps-user