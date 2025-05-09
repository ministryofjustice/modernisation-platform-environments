locals {
  # EC2 User data
  # TODO The hostname is too long as the domain itself is 62 characters long... If this hostname is required, a new domain is required
  # /etc/fstab mount setting as per https://docs.aws.amazon.com/efs/latest/ug/nfs-automount-efs.html
  oam_1_userdata = <<EOF
#!/bin/bash

# Setting up SSM Agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent


EOF
  oam_2_userdata = <<EOF

EOF
}

#################################
# OAM Security Group Rules
#################################

resource "aws_security_group" "oam_instance" {
  name        = "${local.application_name}-${local.environment}-oam-security-group"
  description = "Portal App OAM Security Group"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "oam_outbound" {
  security_group_id = aws_security_group.oam_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# TODO some rules will need adding referencing Landing Zone environments (e.g. VPC) for other dependent applications not migrated to MP yet but needs talking to Portal.
# At the moment we are unsure what rules form LZ is required so leaving out those rules for now, to be added when dependencies identified in future tickets or testing.
# Some rules may need updating or removing as we migrate more applications across to MP.

resource "aws_vpc_security_group_ingress_rule" "oam_inbound" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "OAM Inbound"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 14100
  ip_protocol       = "tcp"
  to_port           = 14100
}

resource "aws_vpc_security_group_ingress_rule" "oam_proxy" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "OAM Proxy Inbound"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 5575
  ip_protocol       = "tcp"
  to_port           = 5575
}

resource "aws_vpc_security_group_ingress_rule" "oam_nodemanager" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "OAM NodeManager Port"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 5556
  ip_protocol       = "tcp"
  to_port           = 5556
}

resource "aws_vpc_security_group_ingress_rule" "oracle_access_gate" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "Oracle Access Gate"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 9002
  ip_protocol       = "tcp"
  to_port           = 9002
}

resource "aws_vpc_security_group_ingress_rule" "oracle_admin" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "OAM Admin Server"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 7001
  ip_protocol       = "tcp"
  to_port           = 7001
}

resource "aws_vpc_security_group_ingress_rule" "oracle_admin_prod" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "OAM Admin Server from Prod Shared Svs"
  cidr_ipv4         = local.prod_workspaces_cidr
  from_port         = 7001
  ip_protocol       = "tcp"
  to_port           = 7001
}

resource "aws_vpc_security_group_ingress_rule" "oam_ping" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "Allow ping response"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 8
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "oam_coherence_tcp" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "OAM coherence communication"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}

resource "aws_vpc_security_group_ingress_rule" "oam_coherence_icmp" {
  security_group_id = aws_security_group.oam_instance.id
  description       = "OAM coherence communication"
  cidr_ipv4         = module.vpc.vpc_cidr_block #!ImportValue env-VpcCidr
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

# nfs to be replaced with efs so these 4 ingress rules are no longer required
# resource "aws_vpc_security_group_ingress_rule" "nfs_oam_to_oam" {
#   security_group_id = aws_security_group.oam_instance.id
#   description = "Inbound NFS from other OAM instances"
#   referenced_security_group_id = aws_security_group.oam_instance.id
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }


# resource "aws_vpc_security_group_ingress_rule" "nfs_idm_to_oam" {
#   security_group_id = aws_security_group.oam_instance.id
#   description = "Inbound NFS from IDM Instances"
#   referenced_security_group_id = aws_security_group.idm_instance.id
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }


# resource "aws_vpc_security_group_ingress_rule" "nfs_ohs_to_oam" {
#   security_group_id = aws_security_group.oam_instance.id
#   description = "Inbound NFS from OHS Instances"
#   referenced_security_group_id = aws_security_group.ohs_instance.id
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }


# resource "aws_vpc_security_group_ingress_rule" "nfs_oim_to_oam" {
#   security_group_id = aws_security_group.oam_instance.id
#   description = "Inbound NFS from OIM Instances"
#   referenced_security_group_id = aws_security_group.oim_instance.id
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }

# resource "aws_vpc_security_group_ingress_rule" "nonprod_workspaces" {
#   count             = contains(["development", "testing"], local.environment) ? 1 : 0
#   security_group_id = aws_security_group.oam_instance.id
#   description       = "OAM Admin Server from Shared Svs"
#   cidr_ipv4         = local.nonprod_workspaces_cidr # env-BastionSSHCIDR
#   from_port         = 7001
#   ip_protocol       = "tcp"
#   to_port           = 7001
# }

# resource "aws_vpc_security_group_ingress_rule" "redc" {
#   count             = contains(["development", "testing"], local.environment) ? 1 : 0
#   security_group_id = aws_security_group.oam_instance.id
#   cidr_ipv4         = local.redc_cidr
#   from_port         = 5575
#   ip_protocol       = "tcp"
#   to_port           = 5575
# }

# resource "aws_vpc_security_group_ingress_rule" "atos" {
#   count             = contains(["preproduction", "production"], local.environment) ? 1 : 0
#   security_group_id = aws_security_group.oam_instance.id
#   cidr_ipv4         = local.atos_cidr
#   from_port         = 5575
#   ip_protocol       = "tcp"
#   to_port           = 5575
# }

######################################
# OAM Instance
######################################

resource "aws_instance" "oam_instance_1" {
  ami                         = local.application_data.accounts[local.environment].oam_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].oam_instance_type
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  user_data_base64            = base64encode(local.oam_1_userdata)
  user_data_replace_on_change = true
#   key_name                    = aws_key_pair.portal_ssh_ohs.key_name

  network_interface {
    network_interface_id = aws_network_interface.oam_1.id
    device_index         = 0
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${local.application_name} OAM Instance 1" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )


}

resource "aws_network_interface" "oam_1" {
  subnet_id   = module.vpc.private_subnets.0
  private_ips = ["10.206.4.196"]
  security_groups = [aws_security_group.oam_instance.id]

  tags = {
    Name = "oam1_ec2_networking_interface"
  }
}

#############################################
# TEMP SSH Key to installing Portal
#############################################
# resource "aws_vpc_security_group_ingress_rule" "oam_ssh" {
#   security_group_id            = aws_security_group.oam_instance.id
#   description                  = "SSH for Portal Installation"
#   referenced_security_group_id = module.bastion_linux.bastion_security_group
#   from_port                    = 22
#   ip_protocol                  = "tcp"
#   to_port                      = 22
# }



# resource "aws_instance" "oam_instance_2" {
#   count                  = contains(["development", "testing"], local.environment) ? 0 : 1
#   ami                    = local.application_data.accounts[local.environment].oam_ami_id
#   availability_zone      = "eu-west-2b"
#   instance_type          = local.application_data.accounts[local.environment].oam_instance_type
#   vpc_security_group_ids = [aws_security_group.oam_instance.id]
#   monitoring             = true
#   subnet_id              = data.aws_subnet.private_subnets_b.id
#   # iam_instance_profile        = aws_iam_instance_profile.portal_instance_profile.id # TODO to be updated once merging with OHS work
#   user_data_base64 = base64encode(local.oam_2_userdata)

#   tags = merge(
#     { "instance-scheduling" = "skip-scheduling" },
#     local.tags,
#     { "Name" = "${local.application_name} OAM Instance 2" },
#     local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
#   )
# }

# data "local_file" "cloudwatch_agent" {
#   filename = "${path.module}/cloudwatch_agent_config.json"
# }


###############################
# OAM EBS Volumes
###############################
# TODO These volume code should only removed after all the testing and deployment are done to production. This is because we need the EBS attached to the instances to do the data transfer to EFS
# The exception is the mserver volume which is required live

# resource "aws_ebs_volume" "oam_repo_home" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = 150
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].oam_repo_home_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OAM-repo-home" },
#   )
# }
# resource "aws_volume_attachment" "oam_repo_home" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.oam_repo_home[0].id
#   instance_id = aws_instance.oam_instance_1.id
# }

# resource "aws_ebs_volume" "oam_config" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = 15
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id # TODO This key is not being used by Terraform and is pointing to the AWS default one in the local account
#   snapshot_id       = local.application_data.accounts[local.environment].oam_config_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OAM-config" },
#   )
# }
# resource "aws_volume_attachment" "oam_onfig" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/xvdd"
#   volume_id   = aws_ebs_volume.oam_config[0].id
#   instance_id = aws_instance.oam_instance_1.id
# }

# resource "aws_ebs_volume" "oam_fmw" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = 30
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].oam_fmw_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OAM-fmw" },
#   )
# }
# resource "aws_volume_attachment" "oam_fmw" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/xvdb"
#   volume_id   = aws_ebs_volume.oam_fmw[0].id
#   instance_id = aws_instance.oam_instance_1.id
# }

# resource "aws_ebs_volume" "oam_aserver" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = 15
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].oam_aserver_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OAM-aserver" },
#   )
# }
# resource "aws_volume_attachment" "oam_aserver" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/xvdc"
#   volume_id   = aws_ebs_volume.oam_aserver[0].id
#   instance_id = aws_instance.oam_instance_1.id
# }

# resource "aws_ebs_volume" "oam_mserver" {
#   availability_zone = "eu-west-2a"
#   size              = 40
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   # snapshot_id       = local.application_data.accounts[local.environment].oam_mserver_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-OAM-mserver" },
#   )
# }
# resource "aws_volume_attachment" "oam_mserver" {
#   device_name = "/dev/xvde"
#   volume_id   = aws_ebs_volume.oam_mserver.id
#   instance_id = aws_instance.oam_instance_1.id
# }