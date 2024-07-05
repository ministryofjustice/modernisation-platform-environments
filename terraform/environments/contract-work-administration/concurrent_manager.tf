locals {
  cm_userdata = <<EOF
#!/bin/bash

### Temp install of AWS CLI - removed once actual AMI is used
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# sudo yum install -y unzip
# unzip awscliv2.zip
# sudo ./aws/install
##############

echo "Setting host name"
hostname ${local.cm_hostname}
echo "${local.cm_hostname}" > /etc/hostname
sed -i '/^HOSTNAME/d' /etc/sysconfig/network
echo "HOSTNAME=${local.cm_hostname}" >> /etc/sysconfig/network

echo "Getting IP Addresses for /etc/hosts"
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
APP1_IP=""
CM_IP=""

while [ -z "$APP1_IP" ] || [ -z "$DB_IP" ]
do
  sleep 5
  APP1_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.appserver1_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
  DB_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.database_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
done

echo "Updating /etc/hosts"
sed -i '/cwa-db$/d' /etc/hosts
sed -i '/cwa-app1$/d' /etc/hosts
sed -i '/cwa-app2$/d' /etc/hosts
echo "$DB_IP	${local.application_name_short}-db.${data.aws_route53_zone.external.name}		${local.database_hostname}" >> /etc/hosts
echo "$APP1_IP	${local.application_name_short}-app1.${data.aws_route53_zone.external.name}		${local.appserver1_hostname}" >> /etc/hosts
echo "$PRIVATE_IP	${local.application_name_short}-app2.${data.aws_route53_zone.external.name}		${local.cm_hostname}" >> /etc/hosts


## Mounting to EFS - uncomment when AMI has been applied
echo "Updating /etc/fstab"
sed -i '/^fs-/d' /etc/fstab
sed -i '/^s3fs/d' /etc/fstab
echo "${aws_efs_file_system.cwa.dns_name}:/ /efs nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2" >> /etc/fstab
mount -a
mount_status=$?
while [[ $mount_status != 0 ]]
do
  sleep 10
  mount -a
  mount_status=$?
done

## Update the send mail url
echo "Updating the send mail config"
sed -i 's/aws.dev.legalservices.gov.uk/${data.aws_route53_zone.external.name}/g' /etc/mail/sendmail.cf
sed -i 's/dev.legalservices.gov.uk/${data.aws_route53_zone.external.name}/g' /etc/mail/sendmail.cf

## Remove SSH key allowed
echo "Removing old SSH key"
sed -i '/development-general$/d' /home/ec2-user/.ssh/authorized_keys
sed -i '/development-general$/d' /root/.ssh/authorized_keys
sed -i '/testimage$/d' /root/.ssh/authorized_keys

## Add custom metric script
echo "Adding the custom metrics script for CloudWatch"
rm /var/cw-custom.sh
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.backup_lambda.id}/cm-cw-custom.sh /var/cw-custom.sh
chmod +x cw-custom.sh
#  This script will be ran by the cron job in /etc/cron.d/custom_cloudwatch_metrics

EOF

}

### Load custom metric script into an S3 bucket
resource "aws_s3_object" "cm_custom_script" {
    bucket = aws_s3_bucket.backup_lambda.id
    key    = "cm-cw-custom.sh"
    source = "./cm-cw-custom.sh"
    source_hash  = filemd5("./cm-cw-custom.sh")
}

resource "time_sleep" "wait_cm_custom_script" {
  create_duration = "1m"
  depends_on      = [aws_s3_object.cm_custom_script]
}

######################################
# concurrent_manager Instance
######################################

resource "aws_instance" "concurrent_manager" {
  ami                         = local.application_data.accounts[local.environment].cm_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].cm_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.concurrent_manager.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.cwa.id
  key_name                    = aws_key_pair.cwa.key_name
  user_data_base64            = base64encode(local.cm_userdata)
  user_data_replace_on_change = false
  metadata_options {
    http_tokens                 = "optional"
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = local.cm_ec2_name },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "no" } : { "snapshot-with-daily-35-day-retention" = "yes" }
  )
}

#################################
# concurrent_manager Security Group Rules
#################################

resource "aws_security_group" "concurrent_manager" {
  name        = "${local.application_name}-${local.environment}-cm-security-group"
  description = "Security Group for concurrent_manager"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-cm-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "cm_outbound" {
  security_group_id = aws_security_group.concurrent_manager.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "cm_bastion_ssh" {
  security_group_id            = aws_security_group.concurrent_manager.id
  description                  = "SSH from the Bastion"
  referenced_security_group_id = module.bastion_linux.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "cm_self" {
  security_group_id            = aws_security_group.concurrent_manager.id
  description                  = "Access from itself"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 1676
  ip_protocol                  = "tcp"
  to_port                      = 1676
}

resource "aws_vpc_security_group_ingress_rule" "cm_app" {
  security_group_id            = aws_security_group.concurrent_manager.id
  description                  = "Access from the Application Server"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 1676
  ip_protocol                  = "tcp"
  to_port                      = 1676
}

###############################
# concurrent_manager EBS Volumes
###############################

resource "aws_ebs_volume" "concurrent_manager" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_concurrent_manager_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].concurrent_manager_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-concurrent_manager" },
  )
}

resource "aws_volume_attachment" "concurrent_manager" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.concurrent_manager.id
  instance_id = aws_instance.concurrent_manager.id
}
