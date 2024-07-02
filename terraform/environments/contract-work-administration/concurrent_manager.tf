locals {
  cm_userdata = <<EOF
#!/bin/bash

### Temp install of AWS CLI - removed once actual AMI is used
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# sudo yum install -y unzip
# unzip awscliv2.zip
# sudo ./aws/install
##############

hostnamectl set-hostname ${local.cm_hostname}

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
APP1_IP=""
DB_IP=""

while [ -z "$APP1_IP" ] || [ -z "$DB_IP" ]
do
  sleep 5
  APP1_IP=$(aws ec2 describe-instances --filter Name=tag:Name,Values="${local.appserver1_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
  DB_IP=$(aws ec2 describe-instances --filter Name=tag:Name,Values="${local.database_ec2_name}" Name=instance-state-name,Values="pending","running" |grep PrivateIpAddress |head -1|sed "s/[\"PrivateIpAddress:,\"]//g" | awk '{$1=$1;print}')
done

sudo sed -i '/cwa-db$/d' /etc/hosts
sudo sed -i '/cwa-app1$/d' /etc/hosts
sudo sed -i '/cwa-app2$/d' /etc/hosts
sudo bash -c "echo '$DB_IP	${local.application_name_short}-db.${data.aws_route53_zone.external.name}		${local.database_hostname}' >> /etc/hosts"
sudo bash -c "echo '$APP1_IP	${local.application_name_short}-app1.${data.aws_route53_zone.external.name}		${local.appserver1_hostname}' >> /etc/hosts"
sudo bash -c "echo '$PRIVATE_IP	${local.application_name_short}-app2.${data.aws_route53_zone.external.name}		${local.cm_hostname}' >> /etc/hosts"


## Mounting to EFS - uncomment when AMI has been applied
echo "${aws_efs_file_system.cwa.dns_name}:/ /efs nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2" >> /etc/fstab
mount -a
mount_status=$?
while [[ $mount_status != 0 ]]
do
  sleep 10
  mount -a
  mount_status=$?
done

## Update SSH key allowed
echo "${local.cwa_ec2_key}" > .ssh/authorized_keys

EOF

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
  user_data_replace_on_change = true

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
