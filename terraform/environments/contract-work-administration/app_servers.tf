locals {
  app_userdata = <<EOF
#!/bin/bash

### Temp install of AWS CLI - removed once actual AMI is used
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# sudo yum install -y unzip
# unzip awscliv2.zip
# sudo ./aws/install
##############

echo "Setting host name"
hostname ${local.appserver1_hostname}
echo "${local.appserver1_hostname}" > /etc/hostname
sed -i '/^HOSTNAME/d' /etc/sysconfig/network
echo "HOSTNAME=${local.appserver1_hostname}" >> /etc/sysconfig/network

echo "Getting IP Addresses for /etc/hosts"
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
APP1_IP=""
CM_IP=""

while [ -z "$DB_IP" ] || [ -z "$CM_IP" ]
do
  sleep 5
  DB_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.database_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
  CM_IP=$(/usr/local/bin/aws ec2 describe-instances --filter Name=tag:Name,Values="${local.cm_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
done

echo "Updating /etc/hosts"
sed -i '/cwa-db$/d' /etc/hosts
sed -i '/cwa-app1$/d' /etc/hosts
sed -i '/cwa-app2$/d' /etc/hosts
echo "$DB_IP	${local.application_name_short}-db.${data.aws_route53_zone.external.name}		${local.database_hostname}" >> /etc/hosts
echo "$PRIVATE_IP	${local.application_name_short}-app1.${data.aws_route53_zone.external.name}		${local.appserver1_hostname}" >> /etc/hosts
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

EOF

}

######################################
# app Instance
######################################

resource "aws_instance" "app1" {
  ami                         = local.application_data.accounts[local.environment].app_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].app_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.app.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.cwa.id
  key_name                    = aws_key_pair.cwa.key_name
  user_data_base64            = base64encode(local.app_userdata)
  user_data_replace_on_change = true
  metadata_options {
    http_tokens                 = "optional"
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = local.appserver1_ec2_name },
    { "snapshot-with-daily-35-day-retention" = "yes" }
  )
}

resource "aws_instance" "app2" {
  count                  = contains(["development", "testing"], local.environment) ? 0 : 1
  ami                    = local.application_data.accounts[local.environment].app_ami_id
  availability_zone      = "eu-west-2a"
  instance_type          = local.application_data.accounts[local.environment].app_instance_type
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.app.id]
  subnet_id              = data.aws_subnet.data_subnets_a.id
  iam_instance_profile   = aws_iam_instance_profile.cwa.id
  key_name               = aws_key_pair.cwa.key_name
  #   user_data_base64            = base64encode(local.app_userdata)
  #   user_data_replace_on_change = true

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${upper(local.application_name_short)} App Instance 2" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

#################################
# app Security Group Rules
#################################

resource "aws_security_group" "app" {
  name        = "${local.application_name}-${local.environment}-app-security-group"
  description = "Security Group for Application Servers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-app-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "app_outbound" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "app_bastion_ssh" {
  security_group_id            = aws_security_group.app.id
  description                  = "SSH from the Bastion"
  referenced_security_group_id = module.bastion_linux.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "app_self_1" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from itself"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 8050
  ip_protocol                  = "tcp"
  to_port                      = 8050
}

resource "aws_vpc_security_group_ingress_rule" "app_self_2" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from itself"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 9050
  ip_protocol                  = "tcp"
  to_port                      = 9050
}

resource "aws_vpc_security_group_ingress_rule" "app_self_3" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from itself"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 8250
  ip_protocol                  = "tcp"
  to_port                      = 8250
}

resource "aws_vpc_security_group_ingress_rule" "app_self_4" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from itself"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 1676
  ip_protocol                  = "tcp"
  to_port                      = 1676
}

resource "aws_vpc_security_group_ingress_rule" "app_cm_1" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 9050
  ip_protocol                  = "tcp"
  to_port                      = 9050
}

resource "aws_vpc_security_group_ingress_rule" "app_cm_2" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 8250
  ip_protocol                  = "tcp"
  to_port                      = 8250
}

resource "aws_vpc_security_group_ingress_rule" "app_cm_3" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 1676
  ip_protocol                  = "tcp"
  to_port                      = 1676
}

resource "aws_vpc_security_group_ingress_rule" "app_cm_4" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from Concurrent Manager"
  referenced_security_group_id = aws_security_group.concurrent_manager.id
  from_port                    = 8050
  ip_protocol                  = "tcp"
  to_port                      = 8050
}

resource "aws_vpc_security_group_ingress_rule" "app_db_1" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from Database server"
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 8250
  ip_protocol                  = "tcp"
  to_port                      = 8250
}

resource "aws_vpc_security_group_ingress_rule" "app_db_2" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from Database server"
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 9050
  ip_protocol                  = "tcp"
  to_port                      = 9050
}

resource "aws_vpc_security_group_ingress_rule" "app_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Access from CWA ALB"
  referenced_security_group_id = aws_security_group.external_lb.id
  from_port                    = 8050
  ip_protocol                  = "tcp"
  to_port                      = 8050
}



###############################
# app EBS Volumes
###############################

resource "aws_ebs_volume" "app1" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_app_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].app_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-app1" },
  )
}

resource "aws_volume_attachment" "app1" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.app1.id
  instance_id = aws_instance.app1.id
}

resource "aws_ebs_volume" "app2" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_app_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  # snapshot_id       = local.application_data.accounts[local.environment].app_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-app2" },
  )
}

resource "aws_volume_attachment" "app2" {
  count       = contains(["development", "testing"], local.environment) ? 0 : 1
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.app2[0].id
  instance_id = aws_instance.app2[0].id
}
