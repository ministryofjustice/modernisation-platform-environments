locals {
  # EC2 User data
  # /etc/fstab mount setting as per https://docs.aws.amazon.com/efs/latest/ug/nfs-automount-efs.html
  idm_1_userdata = <<EOF
#!/bin/bash

# Setting up SSM Agent
# sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

EOF

  idm_2_userdata = <<EOF
#!/bin/bash

EOF
}

#################################
# IDM Security Group Rules
#################################

resource "aws_security_group" "idm_instance" {
  name        = "${local.application_name}-${local.environment}-idm-security-group"
  description = "Portal App IDM Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_egress_rule" "idm_outbound_local_vpc" {
  security_group_id = aws_security_group.idm_instance.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "-1"
}

# TODO some rules will need adding referencing Landing Zone environments (e.g. VPC) for other dependent applications not migrated to MP yet but needs talking to Portal.
# At the moment we are unsure what rules form LZ is required so leaving out those rules for now, to be added when dependencies identified in future tickets or testing.
# Some rules may need updating or removing as we migrate more applications across to MP.

# resource "aws_vpc_security_group_ingress_rule" "weblogic_admin_port_from_shared_svs" {
#   count             = contains(["development", "testing"], local.environment) ? 1 : 0
#   security_group_id = aws_security_group.idm_instance.id
#   description       = "Weblogic Admin Server port from Shared Svs"
#   cidr_ipv4         = local.nonprod_workspaces_cidr
#   from_port         = 7001
#   ip_protocol       = "tcp"
#   to_port           = 7001
# }

# resource "aws_vpc_security_group_ingress_rule" "weblogic_admin_port2_from_shared_svs" {
#   count             = contains(["development", "testing"], local.environment) ? 1 : 0
#   security_group_id = aws_security_group.idm_instance.id
#   description       = "Weblogic Admin Server port from Shared Svs"
#   cidr_ipv4         = local.nonprod_workspaces_cidr
#   from_port         = 7201
#   ip_protocol       = "tcp"
#   to_port           = 7201
# }

# resource "aws_vpc_security_group_ingress_rule" "idm_odsm_nonprod_workspaces" {
#   count             = contains(["development", "testing"], local.environment) ? 1 : 0
#   security_group_id = aws_security_group.idm_instance.id
#   description       = "IDM ODSM access from Workspaces"
#   cidr_ipv4         = local.nonprod_workspaces_cidr
#   from_port         = 14200
#   ip_protocol       = "tcp"
#   to_port           = 14200
# }

resource "aws_vpc_security_group_ingress_rule" "idm_weblogic_admin_prod" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "Weblogic Admin Server port from Prod Shared Svs"
  cidr_ipv4         = local.prod_workspaces_cidr
  from_port         = 7001
  ip_protocol       = "tcp"
  to_port           = 7001
}

resource "aws_vpc_security_group_ingress_rule" "idm_odsm_prod" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "IDM ODSM access from Prod Workspaces"
  cidr_ipv4         = local.prod_workspaces_cidr
  from_port         = 14200
  ip_protocol       = "tcp"
  to_port           = 14200
}

resource "aws_vpc_security_group_ingress_rule" "idm_weblogic_server" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "Weblogic Managed Server port"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 4444
  ip_protocol       = "tcp"
  to_port           = 4444
}

resource "aws_vpc_security_group_ingress_rule" "idm_opmn" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "Allow Adminserver to communicate to OPMN from IDM1 to IDM2"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 6800
  ip_protocol       = "tcp"
  to_port           = 6801
}

resource "aws_vpc_security_group_ingress_rule" "idm_nodemanager" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "IDM NodeManager Port"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 5556
  ip_protocol       = "tcp"
  to_port           = 5556
}

resource "aws_vpc_security_group_ingress_rule" "idm_server_ods" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "IDM Managed Server(ods)"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 14200
  ip_protocol       = "tcp"
  to_port           = 14200
}

resource "aws_vpc_security_group_ingress_rule" "idm_1636_tls" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "IDM Inbound on 1636 TLS"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 1636
  ip_protocol       = "tcp"
  to_port           = 1636
}

resource "aws_vpc_security_group_ingress_rule" "idm_weblogic_admin_server_port" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "Weblogic Admin Server port"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 7001
  ip_protocol       = "tcp"
  to_port           = 7001
}

resource "aws_vpc_security_group_ingress_rule" "ping_echo" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "Ping Echo"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 6200
  ip_protocol       = "tcp"
  to_port           = 6200
}

resource "aws_vpc_security_group_ingress_rule" "idm_ping" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "Allow ping response"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 8
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "idm_weblogic_admin_2" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "Weblogic Admin Server port"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 7201
  ip_protocol       = "tcp"
  to_port           = 7201
}

resource "aws_vpc_security_group_ingress_rule" "idm_1389_tls" {
  security_group_id = aws_security_group.idm_instance.id
  description       = "Idm Inbound on 1389"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 1389
  ip_protocol       = "tcp"
  to_port           = 1389
}

###### TO CHECK INGRESS RULES ######
# resource "aws_vpc_security_group_ingress_rule" "idm_ingress_7777_oas_mp" {
#   security_group_id = aws_security_group.idm_instance.id
#   description = "Inbound from Dev MP environment (OAS dev instance in MP)"
#   cidr_ipv4   = "10.26.56.0/21"
#   from_port   = 7777
#   ip_protocol = "tcp"
#   to_port     = 7777
# }

# resource "aws_vpc_security_group_ingress_rule" "idm_ingress_1389_oas_mp" {
#   security_group_id = aws_security_group.idm_instance.id
#   description = "Inbound from Dev MP environment (OAS dev instance in MP)"
#   cidr_ipv4   = "10.26.56.0/21"
#   from_port   = 1389
#   ip_protocol = "tcp"
#   to_port     = 1389
# }

# nfs to be replaced with efs so this ingress rule is no longer required
# resource "aws_vpc_security_group_ingress_rule" "nfs_idm_to_idm" {
#   security_group_id = aws_security_group.idm_instance.id
#   description = "Inbound NFS from other IDM instances"
#   referenced_security_group_id = aws_security_group.idm_instance.id
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }

######################################
# IDM Instance
######################################

resource "aws_instance" "idm_instance_1" {
  ami                         = local.application_data.accounts[local.environment].idm_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].idm_instance_type
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  user_data_base64            = base64encode(local.idm_1_userdata)
  user_data_replace_on_change = true
#   key_name                    = aws_key_pair.portal_ssh_ohs.key_name

  network_interface {
    network_interface_id = aws_network_interface.idm_1.id
    device_index         = 0
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${local.application_name} IDM Instance 1" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

resource "aws_network_interface" "idm_1" {
  subnet_id   = module.vpc.private_subnets.0
  private_ips = ["10.205.4.131"]
  security_groups = [aws_security_group.idm_instance.id]

  tags = {
    Name = "idm1_ec2_networking_interface"
  }
}

# resource "aws_vpc_security_group_ingress_rule" "idm_ssh" {
#   security_group_id            = aws_security_group.idm_instance.id
#   description                  = "SSH for Portal Installation"
#   referenced_security_group_id = module.bastion_linux.bastion_security_group
#   from_port                    = 22
#   ip_protocol                  = "tcp"
#   to_port                      = 22
# }

# resource "aws_instance" "idm_instance_2" {
#   count                  = contains(["development", "testing"], local.environment) ? 0 : 1
#   ami                    = local.application_data.accounts[local.environment].idm_ami_id
#   availability_zone      = "eu-west-2b"
#   instance_type          = local.application_data.accounts[local.environment].idm_instance_type
#   vpc_security_group_ids = [aws_security_group.idm_instance.id]
#   monitoring             = true
#   subnet_id              = data.aws_subnet.private_subnets_b.id
#   iam_instance_profile   = aws_iam_instance_profile.portal.id
#   user_data_base64       = base64encode(local.oam_2_userdata)

#   tags = merge(
#     { "instance-scheduling" = "skip-scheduling" },
#     local.tags,
#     { "Name" = "${local.application_name} IDM Instance 2" },
#     local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
#   )
# }


###############################
# IDM EBS Volumes
###############################
# TODO These volume code should only removed after all the testing and deployment are done to production. This is because we need the EBS attached to the instances to do the data transfer to EFS
# The exception is the mserver volume which is required live


# resource "aws_ebs_volume" "idm_fmw" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = 30
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].idm_fmw_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-IDM-fmw" },
#   )
# }
# resource "aws_volume_attachment" "idm_fmw" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/xvdb"
#   volume_id   = aws_ebs_volume.idm_fmw[0].id
#   instance_id = aws_instance.idm_instance_1.id
# }

# resource "aws_ebs_volume" "idm_aserver" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = 15
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].idm_aserver_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-IDM-aserver" },
#   )
# }
# resource "aws_volume_attachment" "idm_aserver" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/xvdc"
#   volume_id   = aws_ebs_volume.idm_aserver[0].id
#   instance_id = aws_instance.idm_instance_1.id
# }

# resource "aws_ebs_volume" "idm_config" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = 15
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].idm_config_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-IDM-config" },
#   )
# }
# resource "aws_volume_attachment" "idm_config" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/xvdd"
#   volume_id   = aws_ebs_volume.idm_config[0].id
#   instance_id = aws_instance.idm_instance_1.id
# }

# resource "aws_ebs_volume" "idm_mserver" {
#   availability_zone = "eu-west-2a"
#   size              = 20
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   # snapshot_id       = local.application_data.accounts[local.environment].idm_mserver_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-IDM-mserver" },
#   )
# }
# resource "aws_volume_attachment" "idm_mserver" {
#   device_name = "/dev/xvde"
#   volume_id   = aws_ebs_volume.idm_mserver.id
#   instance_id = aws_instance.idm_instance_1.id
# }

# resource "aws_ebs_volume" "idm_instances" {
#   count             = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   availability_zone = "eu-west-2a"
#   size              = 20
#   type              = "gp2"
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   snapshot_id       = local.application_data.accounts[local.environment].idm_instances_snapshot

#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-IDM-instances" },
#   )
# }
# resource "aws_volume_attachment" "idm_instances" {
#   count       = contains(local.ebs_conditional, local.environment) ? 1 : 0
#   device_name = "/dev/xvdf"
#   volume_id   = aws_ebs_volume.idm_instances[0].id
#   instance_id = aws_instance.idm_instance_1.id
# }
