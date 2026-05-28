locals {
  # EC2 User data
  # TODO The hostname is too long as the domain itself is 62 characters long... If this hostname is required, a new domain is required
  # /etc/fstab mount setting as per https://docs.aws.amazon.com/efs/latest/ug/nfs-automount-efs.html
  oim_1_userdata = <<EOF
#!/bin/bash

# Setting up SSM Agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

echo "${aws_efs_file_system.product["oim"].dns_name}:/fmw /IDAM/product/fmw nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
echo "${aws_efs_file_system.product["oim"].dns_name}:/runtime/Domain/aserver /IDAM/product/runtime/Domain/aserver nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
echo "${aws_efs_file_system.product["oim"].dns_name}:/runtime/Domain/config /IDAM/product/runtime/Domain/config nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
echo "/dev/xvde /IDAM/product/runtime/Domain/mserver ext4 defaults 0 0" >> /etc/fstab
echo "${aws_efs_file_system.efs.dns_name}:/ /IDMLCM/repo_home nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
mount -a
mount_status=$?
while [[ $mount_status != 0 ]]
do
  sleep 10
  mount -a
  mount_status=$?
done

hostnamectl set-hostname ${local.application_name}-oim1-ms

sed -i '/^search/d' /etc/resolv.conf
echo "search ${data.aws_route53_zone.external.name} eu-west-2.compute.internal" >> /etc/resolv.conf

chattr +i /etc/resolv.conf

# Setting up CloudWatch Agent
mkdir cloudwatch_agent
cd cloudwatch_agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
echo '${data.local_file.cloudwatch_agent.content}' > cloudwatch_agent_config.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:cloudwatch_agent_config.json

EOF
  oim_2_userdata = <<EOF
#!/bin/bash
EOF
}



resource "aws_security_group" "oim_instance" {
  name        = "${local.application_name}-${local.environment}-oim-security-group"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "oim_nodemanager" {
  security_group_id = aws_security_group.oim_instance.id
  description       = "Nodemanager port"
  cidr_ipv4         = local.first-cidr
  from_port         = 5556
  ip_protocol       = "tcp"
  to_port           = 5556
}


resource "aws_vpc_security_group_ingress_rule" "oim_admin_Shared" {
  security_group_id = aws_security_group.oim_instance.id
  description       = "OIM Admin Console from Shared Svs"
  cidr_ipv4         = local.second-cidr
  from_port         = 7101
  ip_protocol       = "tcp"
  to_port           = 7101
}

resource "aws_vpc_security_group_ingress_rule" "oim_admin_console2" {
  security_group_id = aws_security_group.oim_instance.id
  description       = "OIM Admin Console"
  cidr_ipv4         = local.first-cidr
  from_port         = 7101
  ip_protocol       = "tcp"
  to_port           = 7101
}

resource "aws_vpc_security_group_ingress_rule" "oim_ping" {
  security_group_id = aws_security_group.oim_instance.id
  description       = "Allow ping response"
  cidr_ipv4         = local.first-cidr
  from_port         = 8
  ip_protocol       = "ICMP"
  to_port           = 1
}

resource "aws_vpc_security_group_ingress_rule" "oim_inbound" {
  security_group_id = aws_security_group.oim_instance.id
  description       = "OIM Inbound on 14000"
  cidr_ipv4         = local.first-cidr
  from_port         = 14000
  ip_protocol       = "TCP"
  to_port           = 14000
}


resource "aws_vpc_security_group_ingress_rule" "oim_bi" {
  security_group_id = aws_security_group.oim_instance.id
  description       = "Oracle BI Port"
  cidr_ipv4         = local.first-cidr
  from_port         = 9704
  ip_protocol       = "TCP"
  to_port           = 9704
}


resource "aws_vpc_security_group_ingress_rule" "oim_shared1" {
  security_group_id = aws_security_group.oim_instance.id
  description       = "OIM Admin Console from Shared Svs"
  cidr_ipv4         = local.third-cidr
  from_port         = 7101
  ip_protocol       = "TCP"
  to_port           = 7101
}

resource "aws_vpc_security_group_ingress_rule" "oim_ssh" {
  security_group_id = aws_security_group.oim_instance.id
  description       = "SSH access from prod bastions"
  cidr_ipv4         = local.third-cidr
  from_port         = 22
  ip_protocol       = "TCP"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "outbound_oim" {
  security_group_id = aws_security_group.oim_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# TODO Depending on outcome of how EBS/EFS is used, this resource may depend on aws_instance.oam_instance_1

resource "aws_instance" "oim_instance_1" {
  ami                         = local.application_data.accounts[local.environment].oim_ami_id
  instance_type               = local.application_data.accounts[local.environment].oim_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.oim_instance.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  user_data_base64            = base64encode(local.oim_1_userdata)
  user_data_replace_on_change = true
  key_name                    = aws_key_pair.portal_ssh_ohs.key_name

  # root_block_device {
  #   delete_on_termination      = false
  #   encrypted                  = true
  #   volume_size                = 60
  #   volume_type                = "gp2"
  #   tags = merge(
  #     local.tags,
  #     { "Name" = "${local.application_name}-root-volume" },
  #   )
  # }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${local.application_name} OIM Instance 1" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

#############################################
# TEMP SSH Key to installing Portal
#############################################
resource "aws_vpc_security_group_ingress_rule" "oim_bastion_ssh" {
  security_group_id            = aws_security_group.oim_instance.id
  description                  = "SSH for Portal Installation"
  referenced_security_group_id = module.bastion_linux.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}


resource "aws_instance" "oim_instance_2" {
  count                       = contains(["development", "testing"], local.environment) ? 0 : 1
  ami                         = local.application_data.accounts[local.environment].oim_ami_id
  instance_type               = local.application_data.accounts[local.environment].oim_instance_type
  vpc_security_group_ids      = [aws_security_group.oim_instance.id]
  subnet_id                   = data.aws_subnet.private_subnets_b.id
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  user_data_base64            = base64encode(local.oim_2_userdata)
  user_data_replace_on_change = true

  #   # root_block_device {
  #   # delete_on_termination     = false
  #   # encrypted                 = true
  #   # volume_size               = 60
  #   # volume_type               = "gp2"
  #   # tags = merge(
  #   #   local.tags,
  #   #   { "Name" = "${local.application_name}-root-volume" },
  #   # )
  # }


  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${local.application_name} OIM Instance 2" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}



resource "aws_ebs_volume" "oimvolume1" {
  count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
  availability_zone = "eu-west-2a"
  size              = "30"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oimsnapshot1

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OIMVolume1" },
  )
}

resource "aws_volume_attachment" "oim_EC2ServerVolume01" {
  count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.oimvolume1[0].id
  instance_id = aws_instance.oim_instance_1.id
}


resource "aws_ebs_volume" "oimvolume2" {
  count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
  availability_zone = "eu-west-2a"
  size              = "15"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oimsnapshot2

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OIMVolume2" },
  )
}

resource "aws_volume_attachment" "oim_EC2ServerVolume02" {
  count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.oimvolume2[0].id
  instance_id = aws_instance.oim_instance_1.id
}



resource "aws_ebs_volume" "oimvolume3" {
  count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
  availability_zone = "eu-west-2a"
  size              = "15"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oimsnapshot3

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OIMVolume3" },
  )
}

resource "aws_volume_attachment" "oim_EC2ServerVolume03" {
  count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
  device_name = "/dev/xvdd"
  volume_id   = aws_ebs_volume.oimvolume3[0].id
  instance_id = aws_instance.oim_instance_1.id
}


# This should be the mserver volume
resource "aws_ebs_volume" "oimvolume4" {
  availability_zone = "eu-west-2a"
  size              = "20"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  # snapshot_id       = local.application_data.accounts[local.environment].oimsnapshot4


  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OIMVolume4" },
  )
}

resource "aws_volume_attachment" "oim_EC2ServerVolume04" {
  device_name = "/dev/xvde"
  volume_id   = aws_ebs_volume.oimvolume4.id

  instance_id = aws_instance.oim_instance_1.id
}
