locals {
  # EC2 User data
  # TODO The hostname is too long as the domain itself is 62 characters long... If this hostname is required, a new domain is required
  # /etc/fstab mount setting as per https://docs.aws.amazon.com/efs/latest/ug/nfs-automount-efs.html
  oim_1_userdata = <<EOF
#!/bin/bash
echo "${aws_efs_file_system.product["oim"].dns_name}:/fmw /IDAM/product/fmw nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
echo "${aws_efs_file_system.product["oim"].dns_name}:/runtime/Domain/aserver /IDAM/product/runtime/Domain/aserver nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
echo "${aws_efs_file_system.product["oim"].dns_name}:/runtime/Domain/config /IDAM/product/runtime/Domain/config nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
echo "/dev/xvde /IDAM/product/runtime/Domain/mserver ext4 defaults 0 0" >> /etc/fstab
echo "${aws_efs_file_system.efs.dns_name}:/ /IDMLCM/repo_home nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
mount -a
hostnamectl set-hostname ${local.application_name}-oim1-ms.${local.portal_hosted_zone}

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

  ingress {
    description = "Nodemanager port"
    from_port   = 5556
    to_port     = 5556
    protocol    = "TCP"
    cidr_blocks = [local.first-cidr]

  }


  ingress {
    description = "OIM Admin Console from Shared Svs"
    from_port   = 7101
    to_port     = 7101
    protocol    = "TCP"
    cidr_blocks = [local.second-cidr]

  }

  ingress {
    description = "OIM Admin Console"
    from_port   = 7101
    to_port     = 7101
    protocol    = "TCP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "Allow ping response"
    from_port   = 8
    to_port     = 1
    protocol    = "ICMP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "OIM Inbound on 14000"
    from_port   = 14000
    to_port     = 14000
    protocol    = "TCP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "Oracle BI Port"
    from_port   = 9704
    to_port     = 9704
    protocol    = "TCP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "Allow ping response"
    from_port   = 8
    to_port     = 1
    protocol    = "ICMP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "OIM Admin Console from Shared Svs"
    from_port   = 7101
    to_port     = 7101
    protocol    = "TCP"
    cidr_blocks = [local.third-cidr]

  }

  ingress {
    description = "SSH access from prod bastions"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [local.third-cidr]

  }

  # nfs to be replaced with efs so this ingress rule is no longer required
  # ingress {
  #     description = "Inbound NFS from other OIM Instances"
  #     from_port   = 2049
  #     to_port     = 2049
  #     protocol    = "TCP"
  #     self        = true
  #   }

  # ingress {
  #   description = "SSH access from VPC"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "TCP"
  #   cidr_blocks = [local.first-cidr]

  # }

  #   ingress {
  #   description = "SSH access from prod bastion"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "TCP"
  #   cidr_blocks = [local.prd-cidr]

  # }
  #   ingress {
  #   description = "oim Inbound from Prod Shared Svs VPC"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "7777"
  #   cidr_blocks = [local.prd-cidr]

  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }



  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-portal" }
  )
}


# TODO Depending on outcome of how EBS/EFS is used, this resource may depend on aws_instance.oam_instance_1

resource "aws_instance" "oim_instance_1" {
  ami                         = local.oim_ami-id
  instance_type               = local.application_data.accounts[local.environment].oim_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.oim_instance.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  user_data_base64            = base64encode(local.oim_1_userdata)
  user_data_replace_on_change = true

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
    local.tags,
    { "Name" = "${local.application_name} OIM Instance 1" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}


resource "aws_instance" "oim_instance_2" {
  count                       = local.environment == "production" ? 1 : 0
  ami                         = local.oim_ami-id
  instance_type               = local.application_data.accounts[local.environment].oim_instance_type
  vpc_security_group_ids      = [aws_security_group.oim_instance.id]
  subnet_id                   = data.aws_subnet.data_subnets_b.id
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
    local.tags,
    { "Name" = "${local.application_name} OIM Instance 2" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}


# resource "aws_ebs_volume" "oimvolume1" {
#   availability_zone = "eu-west-2a"
#   size              = "30"
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].oimsnapshot1
#
#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }
#
#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OIMVolume1" },
#   )
# }
#
# resource "aws_volume_attachment" "oim_EC2ServerVolume01" {
#   device_name = "/dev/xvdb"
#   volume_id   = aws_ebs_volume.oimvolume1.id
#   instance_id = aws_instance.oim1.id
# }
#
#
# resource "aws_ebs_volume" "oimvolume2" {
#   availability_zone = "eu-west-2a"
#   size              = "15"
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].oimsnapshot2
#
#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }
#
#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OIMVolume2" },
#   )
# }
#
# resource "aws_volume_attachment" "oim_EC2ServerVolume02" {
#   device_name = "/dev/xvdc"
#   volume_id   = aws_ebs_volume.oimvolume2.id
#   instance_id = aws_instance.oim1.id
# }
#
#
#
# resource "aws_ebs_volume" "oimvolume3" {
#   availability_zone = "eu-west-2a"
#   size              = "15"
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].oimsnapshot3
#
#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }
#
#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OIMVolume3" },
#   )
# }
#
# resource "aws_volume_attachment" "oim_EC2ServerVolume03" {
#   device_name = "/dev/xvdd"
#   volume_id   = aws_ebs_volume.oimvolume3.id
#   instance_id = aws_instance.oim1.id
# }


resource "aws_ebs_volume" "oimvolume4" {
  availability_zone = "eu-west-2a"
  size              = "20"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oimsnapshot4

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
