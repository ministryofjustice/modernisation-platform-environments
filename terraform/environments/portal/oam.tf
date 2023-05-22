locals {
  nonprod_workspaces_cidr         = "10.200.0.0/20"
  prod_workspaces_cidr            = "10.200.16.0/20"
  redc_cidr                       = "172.16.0.0/20"
  atos_cidr                       = "10.0.0.0/8"

  # EC2 User data
  oam_1_userdata = <<EOF
#!/bin/bash

EOF
  oam_2_userdata = <<EOF
#!/bin/bash

EOF
}

resource "aws_security_group" "oam_instance" {
  name        = local.application_name
  description = "Portal App OAM Security Group"
  vpc_id      = data.aws_vpc.shared.id

  # TODO some rules will need adding referencing Landing Zone environments (e.g. VPC) for other dependent applications not migrated to MP yet but needs talking to Portal.
  # At the moment we are unsure what rules form LZ is required so leaving out those rules for now, to be added when dependencies identified in future tickets or testing.
  # Some rules may need updating or removing as we migrate more applications across to MP.
  ingress {
    description = "OAM Inbound"
    from_port   = 14100
    to_port     = 14100
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "OAM Proxy Inbound"
    from_port   = 5575
    to_port     = 5575
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "OAM NodeManager Port"
    from_port   = 5556
    to_port     = 5556
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "Oracle Access Gate"
    from_port   = 9002
    to_port     = 9002
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "OAM Admin Server"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "OAM Admin Server from Prod Shared Svs"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = [local.prod_workspaces_cidr]
  }
  ingress {
    description = "Allow ping response"
    from_port   = 8
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "OAM coherence communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "OAM coherence communication"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "nfs_oam_to_oam" {
  security_group_id = aws_security_group.oam_instance.id
  description = "Inbound NFS from other OAM instances"
  referenced_security_group_id = aws_security_group.oam_instance.id
  from_port   = 2049
  ip_protocol = "tcp"
  to_port     = 2049
}

# TODO enable when IDM resources are created

# resource "aws_vpc_security_group_ingress_rule" "nfs_idm_to+oam" {
#   security_group_id = aws_security_group.oam_instance.id
#   description = "Inbound NFS from IDM Instances"
#   referenced_security_group_id = aws_security_group.idm_instance.id
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }

# TODO enable when OHS resources are created

# resource "aws_vpc_security_group_ingress_rule" "nfs_ohs_to_oam" {
#   security_group_id = aws_security_group.oam_instance.id
#   description = "Inbound NFS from OHS Instances"
#   referenced_security_group_id = aws_security_group.ohs_instance.id
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }

# TODO enable when OIM resources are created

# resource "aws_vpc_security_group_ingress_rule" "nfs_oim_to_oam" {
#   security_group_id = aws_security_group.oam_instance.id
#   description = "Inbound NFS from OIM Instances"
#   referenced_security_group_id = aws_security_group.oim_instance.id
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }

resource "aws_vpc_security_group_ingress_rule" "nonprod_workspaces" {
  count = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.oam_instance.id
  description = "OAM Admin Server from Shared Svs"
  cidr_ipv4   = local.nonprod_workspaces_cidr # env-BastionSSHCIDR
  from_port   = 7001
  ip_protocol = "tcp"
  to_port     = 7001
}

resource "aws_vpc_security_group_ingress_rule" "redc" {
  count = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.oam_instance.id
  cidr_ipv4   = local.redc_cidr
  from_port   = 5575
  ip_protocol = "tcp"
  to_port     = 5575
}

resource "aws_vpc_security_group_ingress_rule" "atos" {
  count = contains(["preproduction", "production"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.oam_instance.id
  cidr_ipv4   = local.atos_cidr
  from_port   = 5575
  ip_protocol = "tcp"
  to_port     = 5575
}

resource "aws_instance" "oam_instance_1" {
  ami                         = local.application_data.accounts[local.environment].oam_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].oam_instance_type
  vpc_security_group_ids      = [aws_security_group.oam_instance.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  # iam_instance_profile        = aws_iam_instance_profile.portal_instance_profile.id # TODO to be updated once merging with OHS work
  user_data_base64            = base64encode(local.oam_1_userdata)

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} OAM Instance 1" },
    { "snapshot-with-daily-35-day-retention" = "yes" }    # TODO the Backup rule needs setting up first
  )
}

resource "aws_instance" "oam_instance_2" {
  count = local.environment == "production" ? 1 : 0
  ami                         = local.application_data.accounts[local.environment].oam_ami_id
  availability_zone           = "eu-west-2b"
  instance_type               = local.application_data.accounts[local.environment].oam_instance_type
  vpc_security_group_ids      = [aws_security_group.oam_instance.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_b.id
  # iam_instance_profile        = aws_iam_instance_profile.portal_instance_profile.id # TODO to be updated once merging with OHS work
  user_data_base64            = base64encode(local.oam_2_userdata)

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} OAM Instance 2" },
    { "snapshot-with-daily-35-day-retention" = "yes" }    # TODO the Backup rule needs setting up first
  )
}

# Route 53 records
# resource "aws_route53_record" "oam1_nonprod" {
#   count    = local.environment != "production" ? 1 : 0
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "${local.application_name}.${data.aws_route53_zone.external.name}"
#   type     = "A"
#   ttl      = 60
#   records  = [aws_instance.oam_instance_1.private_ip]
# }
#
# resource "aws_route53_record" "oam1_prod" {
#   count    = local.environment == "production" ? 1 : 0
#   provider = aws.core-network-services
#   zone_id  = data.aws_route53_zone.portal-oam.zone_id # TODO This hosted zone name to be determined
#   name     = "${local.application_name}-oam1.${data.aws_route53_zone.portal-oam.zone_id}" # TODO Record name to be determined
#   type     = "A"
#   ttl      = 60
#   records  = [aws_instance.oam_instance_1.private_ip]
# }
#
# resource "aws_route53_record" "oam2_prod" {
#   count    = local.environment == "production" ? 1 : 0
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.portal-oam.zone_id # TODO This hosted zone name to be determined
#   name     = "${local.application_name}-oam1.${data.aws_route53_zone.portal-oam.zone_id}" # TODO Record name to be determined
#   type     = "A"
#   ttl      = 60
#   records  = [aws_instance.oam_instance_2.private_ip]
# }
#
#
# ## TODO Optionally, OAM Admin Records can be looped with the other records...
# resource "aws_route53_record" "oam_admin_nonprod" {
#   count    = local.environment != "production" ? 1 : 0
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "${local.application_name}.${data.aws_route53_zone.external.name}"
#   type     = "A"
#   ttl      = 60
#   records  = [aws_instance.oam_instance_1.private_ip]
# }
#
# resource "aws_route53_record" "oam_admin_prod" {
#   count    = local.environment == "production" ? 1 : 0
#   provider = aws.core-network-services
#   zone_id  = data.aws_route53_zone.portal-oam.zone_id # TODO This hosted zone name to be determined
#   name     = "${local.application_name}-oam1.${data.aws_route53_zone.portal-oam.zone_id}" # TODO Record name to be determined
#   type     = "A"
#   ttl      = 60
#   records  = [aws_instance.oam_instance_1.private_ip]
# }
#
# ###############
