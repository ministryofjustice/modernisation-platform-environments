locals {
  # EC2 User data
  # TODO The hostname is too long as the domain itself is 62 characters long... If this hostname is required, a new domain is required
  # /etc/fstab mount setting as per https://docs.aws.amazon.com/efs/latest/ug/nfs-automount-efs.html
  ohs_1_userdata = <<EOF
#!/bin/bash

# Setting up SSM Agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

EOF

  #   ohs_2_userdata = <<EOF
  # #!/bin/bash
  # EOF
}

#################################
# OHS Security Group Rules
#################################

resource "aws_security_group" "ohs_instance" {
  name        = "${local.application_name}-${local.environment}-ohs-security-group"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ohs-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "ohs_outbound" {
  security_group_id = aws_security_group.ohs_instance.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "ohs_local_vpc" {
  security_group_id = aws_security_group.ohs_instance.id
  description       = "OHS Inbound from Local account VPC"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 7777
  ip_protocol       = "tcp"
  to_port           = 7777
}

resource "aws_vpc_security_group_ingress_rule" "ohs_nonprod_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.ohs_instance.id
  description       = "OHS Inbound from Shared Svs VPC"
  cidr_ipv4         = local.nonprod_workspaces_cidr # env-BastionSSHCIDR
  from_port         = 7777
  ip_protocol       = "tcp"
  to_port           = 7777
}

# resource "aws_vpc_security_group_ingress_rule" "ohs_prod_workspaces" {
#   security_group_id = aws_security_group.ohs_instance.id
#   description       = "OHS Inbound from Prod Shared Svs VPC"
#   cidr_ipv4         = local.prod_workspaces_cidr
#   from_port         = 7777
#   ip_protocol       = "tcp"
#   to_port           = 7777
# }

resource "aws_vpc_security_group_ingress_rule" "ohs_ons" {
  security_group_id = aws_security_group.ohs_instance.id
  description       = "ONS Port"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 6200
  ip_protocol       = "tcp"
  to_port           = 6200
}

resource "aws_vpc_security_group_ingress_rule" "ohs_ping" {
  security_group_id = aws_security_group.ohs_instance.id
  description       = "Allow ping response"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 8
  ip_protocol       = "icmp"
  to_port           = -1
}

######################################
# OHS Instance
######################################

resource "aws_instance" "ohs_instance_1" {
  ami                         = local.application_data.accounts[local.environment].ohs_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].ohs_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.ohs_instance.id]
  # subnet_id                   = module.vpc.private_subnets.0
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  user_data_base64            = base64encode(local.ohs_1_userdata)
  user_data_replace_on_change = true
  # key_name                    = aws_key_pair.portal_ssh_ohs.key_name

  network_interface {
    network_interface_id = aws_network_interface.ohs_1.id
    device_index         = 0
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${local.application_name} OHS Instance 1" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

resource "aws_network_interface" "ohs_1" {
  subnet_id   = module.vpc.private_subnets.0
  private_ips = ["10.206.4.100"]

  tags = {
    Name = "ohs1_ec2_networking_interface"
  }
}

#############################################
# TEMP SSH Key to installing Portal
#############################################
# resource "aws_key_pair" "portal_ssh_ohs" {
#   key_name   = "portal-ssh-ohs-key"
#   public_key = ""
# }

# resource "aws_vpc_security_group_ingress_rule" "ohs_ssh" {
#   security_group_id            = aws_security_group.ohs_instance.id
#   description                  = "SSH for Portal Installation"
#   referenced_security_group_id = module.bastion_linux.bastion_security_group
#   from_port                    = 22
#   ip_protocol                  = "tcp"
#   to_port                      = 22
# }


# resource "aws_instance" "ohs_instance_2" {
#   count         = contains(["development", "testing"], local.environment) ? 0 : 1
#   ami           = local.application_data.accounts[local.environment].ohs_ami_id
#   instance_type = local.application_data.accounts[local.environment].ohs_instance_type
#   # vpc_security_group_ids         = [aws_security_group.ohs_instance.id]
#   subnet_id            = data.aws_subnet.private_subnets_b.id
#   iam_instance_profile = aws_iam_instance_profile.portal.id
#   # user_data_base64               = base64encode(local.ohs_2_userdata)

#   #   # root_block_device {
#   #   # delete_on_termination     = false
#   #   # encrypted                 = true
#   #   # volume_size               = 60
#   #   # volume_type               = "gp2"
#   #   # tags = merge(
#   #   #   local.tags,
#   #   #   { "Name" = "${local.application_name}-root-volume" },
#   #   # )
#   # }


#   tags = merge(
#     { "instance-scheduling" = "skip-scheduling" },
#     local.tags,
#     { "Name" = "${local.application_name} OHS Instance 2" },
#     local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
#   )
# }

###############################
# OHS EBS Volumes
###############################
# TODO These volume code should only removed after all the testing and deployment are done to production. This is because we need the EBS attached to the instances to do the data transfer to EFS
# The exception is the mserver volume which is required live

# resource "aws_ebs_volume" "ohsvolume1" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = "30"
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   # snapshot_id       = local.application_data.accounts[local.environment].ohssnapshot1

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OHSVolume1" },
#   )
# }

# resource "aws_volume_attachment" "ohs_EC2ServerVolume01" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/xvdb"
#   volume_id   = aws_ebs_volume.ohsvolume1[0].id
#   instance_id = aws_instance.ohs_instance_1.id
# }

# resource "aws_ebs_volume" "ohs_mserver" {
#   availability_zone = "eu-west-2a"
#   size              = "30"
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   # snapshot_id       = local.application_data.accounts[local.environment].ohs_mserver_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OHS-mserver" },
#   )
# }

# resource "aws_volume_attachment" "ohs_mserver" {
#   device_name = "/dev/xvdc"
#   volume_id   = aws_ebs_volume.ohs_mserver.id
#   instance_id = aws_instance.ohs_instance_1.id
# }
