locals {
  db_userdata = <<EOF
#!/bin/bash

echo "Setting host name"
hostname ${local.database_hostname}
echo "${local.database_hostname}" > /etc/hostname
sed -i '/^HOSTNAME/d' /etc/sysconfig/network
echo "HOSTNAME=${local.database_hostname}" >> /etc/sysconfig/network

echo "Getting IP Addresses for /etc/hosts"
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
APP1_IP=""
CM_IP=""

while [ -z "$APP1_IP" ] || [ -z "$CM_IP" ]
do
  sleep 5
  APP1_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.appserver1_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
  CM_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.cm_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
done

echo "Updating /etc/hosts"
sed -i '/cwa-db$/d' /etc/hosts
sed -i '/cwa-app1$/d' /etc/hosts
sed -i '/cwa-app2$/d' /etc/hosts
echo "$PRIVATE_IP	${local.application_name_short}-db.${data.aws_route53_zone.external.name}		${local.database_hostname}" >> /etc/hosts
echo "$APP1_IP	${local.application_name_short}-app1.${data.aws_route53_zone.external.name}		${local.appserver1_hostname}" >> /etc/hosts
echo "$CM_IP	${local.application_name_short}-app2.${data.aws_route53_zone.external.name}		${local.cm_hostname}" >> /etc/hosts

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
/usr/local/bin/aws s3 cp s3://${aws_s3_bucket.backup_lambda.id}/db-cw-custom.sh /var/cw-custom.sh
chmod 700 /var/cw-custom.sh
# This script will be ran by the cron job in /etc/cron.d/custom_cloudwatch_metrics

EOF

}

### Load custom metric script into an S3 bucket
resource "aws_s3_object" "db_custom_script" {
    bucket = aws_s3_bucket.backup_lambda.id
    key    = "db-cw-custom.sh"
    source = "./db-cw-custom.sh"
    source_hash  = filemd5("./db-cw-custom.sh")
}

resource "time_sleep" "wait_db_custom_script" {
  create_duration = "1m"
  depends_on      = [aws_s3_object.db_custom_script]
}

######################################
# Database Instance
######################################

resource "aws_instance" "database" {
  ami                         = local.application_data.accounts[local.environment].db_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].db_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.database.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.cwa.id
  key_name                    = aws_key_pair.cwa.key_name
  user_data_base64            = base64encode(local.db_userdata)
  user_data_replace_on_change = true
  metadata_options {
    http_tokens                 = "optional"
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = local.database_ec2_name }
  )
  depends_on          = [time_sleep.wait_db_custom_script]
}

resource "aws_key_pair" "cwa" {
  key_name   = "${local.application_name_short}-ssh-key"
  public_key = local.application_data.accounts[local.environment].cwa_ec2_key
}

#################################
# Database Security Group Rules
#################################

resource "aws_security_group" "database" {
  name        = "${local.application_name}-${local.environment}-db-security-group"
  description = "Security Group for database"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-db-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "db_outbound" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "db_bastion_ssh" {
  security_group_id            = aws_security_group.database.id
  description                  = "SSH from the Bastion"
  referenced_security_group_id = module.bastion_linux.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "db_workspaces_1" {
  security_group_id = aws_security_group.database.id
  description       = "DB access for Workspaces"
  cidr_ipv4         = local.application_data.accounts[local.environment].workspaces_local_cidr1
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_workspaces_2" {
  security_group_id = aws_security_group.database.id
  description       = "DB access for Workspaces"
  cidr_ipv4         = local.application_data.accounts[local.environment].workspaces_local_cidr2
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_local_vpc_1" {
  security_group_id = aws_security_group.database.id
  description       = "DB access from local VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_local_vpc_2" {
  security_group_id = aws_security_group.database.id
  description       = "DB access from local VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
}

resource "aws_vpc_security_group_ingress_rule" "db_cp" {
  security_group_id = aws_security_group.database.id
  description       = "DB access from Cloud Platform"
  cidr_ipv4         = local.cloud_platform_cidr
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}
### Port 1571 rules allow inbound for 10.200.32.0/20 and 10.200.96.0/19 not added as unsure what they are for

resource "aws_vpc_security_group_ingress_rule" "db_app_1" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 1571
  ip_protocol                  = "tcp"
  to_port                      = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_app_2" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 32803
  ip_protocol                  = "tcp"
  to_port                      = 32803
}

resource "aws_vpc_security_group_ingress_rule" "db_app_3" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 662
  ip_protocol                  = "tcp"
  to_port                      = 662
}

resource "aws_vpc_security_group_ingress_rule" "db_app_4" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 111
  ip_protocol                  = "tcp"
  to_port                      = 111
}

resource "aws_vpc_security_group_ingress_rule" "db_app_5" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 892
  ip_protocol                  = "tcp"
  to_port                      = 892
}

resource "aws_vpc_security_group_ingress_rule" "db_app_6" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Application Servers"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_1" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 1571
  ip_protocol                  = "tcp"
  to_port                      = 1571
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_2" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 32803
  ip_protocol                  = "tcp"
  to_port                      = 32803
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_3" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 662
  ip_protocol                  = "tcp"
  to_port                      = 662
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_4" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 111
  ip_protocol                  = "tcp"
  to_port                      = 111
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_5" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 892
  ip_protocol                  = "tcp"
  to_port                      = 892
}

resource "aws_vpc_security_group_ingress_rule" "db_cm_6" {
  security_group_id            = aws_security_group.database.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}



###############################
# Database EBS Volumes
###############################

resource "aws_ebs_volume" "oradata" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oradata_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oradata_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oradata" },
  )
}

resource "aws_volume_attachment" "oradata" {
  device_name = "/dev/sd${local.oradata_device_name_letter}"
  volume_id   = aws_ebs_volume.oradata.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oracle" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oracle_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oracle_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oracle" },
  )
}

resource "aws_volume_attachment" "oracle" {
  device_name = "/dev/sd${local.oracle_device_name_letter}"
  volume_id   = aws_ebs_volume.oracle.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oraarch" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oraarch_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oraarch_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oraarch" },
  )
}

resource "aws_volume_attachment" "oraarch" {
  device_name = "/dev/sd${local.oraarch_device_name_letter}"
  volume_id   = aws_ebs_volume.oraarch.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oratmp" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oratmp_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oratmp_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oratmp" },
  )
}

resource "aws_volume_attachment" "oratmp" {
  device_name = "/dev/sd${local.oratmp_device_name_letter}"
  volume_id   = aws_ebs_volume.oratmp.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oraredo" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oraredo_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oraredo_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oraredo" },
  )
}

resource "aws_volume_attachment" "oraredo" {
  device_name = "/dev/sd${local.oraredo_device_name_letter}"
  volume_id   = aws_ebs_volume.oraredo.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "share" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_share_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].share_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-share" },
  )
}

resource "aws_volume_attachment" "share" {
  device_name = "/dev/sd${local.share_device_name_letter}"
  volume_id   = aws_ebs_volume.share.id
  instance_id = aws_instance.database.id
}

