#! /bin/bash

#source ./connect-to-aws.sh

aws configure set aws_access_key_id "$DMS_SOURCE_ACCOUNT_ACCESS_KEY" --profile dts-legacy-apps-user
aws configure set aws_secret_access_key "$DMS_SOURCE_ACCOUNT_SECRET_KEY" --profile dts-legacy-apps-user
aws configure set region "$AWS_REGION" --profile dts-legacy-apps-user
aws configure set output "json" --profile dts-legacy-apps-user

#retrieve existing security groups 
aws ec2 describe-instances --region ${AWS_REGION} --instance-ids ${EC2_INSTANCE_ID} --profile dts-legacy-apps-user --query "Reservations[].Instances[].SecurityGroups[].GroupId" > security_groups

existing_group_ids="$(sed 's/[^a-zA-Z0-9-]//g' security_groups)"
echo existing group ids : $existing_group_ids
echo DMS security group id : ${DMS_SECURITY_GROUP}
aws ec2 modify-instance-attribute --region ${AWS_REGION} --instance-id ${EC2_INSTANCE_ID} --profile dts-legacy-apps-user --groups $existing_group_ids ${DMS_SECURITY_GROUP}

aws ec2 describe-instances --region ${AWS_REGION} --instance-ids ${EC2_INSTANCE_ID} --profile dts-legacy-apps-user --query "Reservations[].Instances[].SecurityGroups[].GroupId" > security_groups
cat security_groups