locals {
  nonprod_workspaces_cidr         = "10.200.0.0/20"
  prod_workspaces_cidr            = "10.200.16.0/20"
  redc_cidr                       = "172.16.0.0/20"
  atos_cidr                       = "10.0.0.0/8"

  # EC2 User data
  oam_1_userdata = <<EOF
#!/bin/bash
echo "/dev/xvdb /IDAM/product/fmw ext4 defaults 0 0" >> /etc/fstab
echo "/dev/xvdc /IDAM/product/runtime/Domain/aserver ext4 defaults 0 0" >> /etc/fstab
echo "/dev/xvdd /IDAM/product/runtime/Domain/config ext4 defaults 0 0" >> /etc/fstab
echo "/dev/xvde /IDAM/product/runtime/Domain/mserver ext4 defaults 0 0" >> /etc/fstab
echo "/dev/sdf /IDMLCM/repo_home ext4 defaults 0 0" >> /etc/fstab
mount -a
hostnamectl set-hostname ${local.application_name}-oam1-ms.${data.aws_route53_zone.external.name}
EOF
  oam_2_userdata = <<EOF
#!/bin/bash
echo "/dev/xvde /IDAM/product/runtime/Domain/mserver ext4 defaults 0 0" >> /etc/fstab
echo "${local.application_name}-oam1-ms.${data.aws_route53_zone.external.name}:/IDAM/product/fmw /IDAM/product/fmw nfs nolock 0 0" >> /etc/fstab
echo "${local.application_name}-oam1-ms.${data.aws_route53_zone.external.name}:/IDAM/product/runtime/Domain/config /IDAM/product/runtime/Domain/config nfs nolock 0 0" >> /etc/fstab
echo "${local.application_name}-oam1-ms.${data.aws_route53_zone.external.name}:/IDAM/product/runtime/Domain/aserver /IDAM/product/runtime/Domain/aserver nfs nolock 0 0" >> /etc/fstab
echo "${local.application_name}-oam1-ms.${data.aws_route53_zone.external.name}:/IDMLCM/repo_home /IDMLCM/repo_home nfs nolock 0 0" >> /etc/fstab
mount -a
hostnamectl set-hostname ${local.application_name}-oam2-ms.${data.aws_route53_zone.external.name}
EOF
}

#################################
# OAM Security Group Rules
#################################

resource "aws_security_group" "oam_instance" {
  name        = local.application_name
  description = "Portal App OAM Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.oam_instance.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "-1"
  to_port     = 0
}

# TODO some rules will need adding referencing Landing Zone environments (e.g. VPC) for other dependent applications not migrated to MP yet but needs talking to Portal.
# At the moment we are unsure what rules form LZ is required so leaving out those rules for now, to be added when dependencies identified in future tickets or testing.
# Some rules may need updating or removing as we migrate more applications across to MP.

resource "aws_vpc_security_group_ingress_rule" "oam_inbound" {
  security_group_id = aws_security_group.oam_instance.id
  description = "OAM Inbound"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port   = 14100
  ip_protocol = "tcp"
  to_port     = 14100
}

resource "aws_vpc_security_group_ingress_rule" "oam_proxy" {
  security_group_id = aws_security_group.oam_instance.id
  description = "OAM Proxy Inbound"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port   = 5575
  ip_protocol = "tcp"
  to_port     = 5575
}

resource "aws_vpc_security_group_ingress_rule" "oam_nodemanager" {
  security_group_id = aws_security_group.oam_instance.id
  description = "OAM NodeManager Port"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port   = 5556
  ip_protocol = "tcp"
  to_port     = 5556
}

resource "aws_vpc_security_group_ingress_rule" "oracle_access_gate" {
  security_group_id = aws_security_group.oam_instance.id
  description = "Oracle Access Gate"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port   = 9002
  ip_protocol = "tcp"
  to_port     = 9002
}

resource "aws_vpc_security_group_ingress_rule" "oracle_admin" {
  security_group_id = aws_security_group.oam_instance.id
  description = "OAM Admin Server"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port   = 7001
  ip_protocol = "tcp"
  to_port     = 7001
}

resource "aws_vpc_security_group_ingress_rule" "oracle_admin_prod" {
  security_group_id = aws_security_group.oam_instance.id
  description = "OAM Admin Server from Prod Shared Svs"
  cidr_ipv4   = local.prod_workspaces_cidr
  from_port   = 7001
  ip_protocol = "tcp"
  to_port     = 7001
}

resource "aws_vpc_security_group_ingress_rule" "ping" {
  security_group_id = aws_security_group.oam_instance.id
  description = "Allow ping response"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port   = 8
  ip_protocol = "icmp"
  to_port     = -1
}

resource "aws_vpc_security_group_ingress_rule" "oam_coherence_tcp" {
  security_group_id = aws_security_group.oam_instance.id
  description = "OAM coherence communication"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
}

resource "aws_vpc_security_group_ingress_rule" "oam_coherence_icmp" {
  security_group_id = aws_security_group.oam_instance.id
  description = "OAM coherence communication"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port   = -1
  ip_protocol = "icmp"
  to_port     = -1
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

######################################
# OAM Instance
######################################

resource "aws_instance" "oam_instance_1" {
  ami                         = local.application_data.accounts[local.environment].oam_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].oam_instance_type
  vpc_security_group_ids      = [aws_security_group.oam_instance.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.portal.id
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


###############################
# OAM EBS Volumes
###############################

resource "aws_ebs_volume" "oam_repo_home" {
  availability_zone = "eu-west-2a"
  size              = 150
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oam_repo_home_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OAM-repo-home" },
  )
}
resource "aws_volume_attachment" "oam_repo_home" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.oam_repo_home.id
  instance_id = aws_instance.oam_instance_1.id
}

resource "aws_ebs_volume" "oam_config" {
  availability_zone = "eu-west-2a"
  size              = 15
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id  # TODO This key is not being used by Terraform and is pointing to the AWS default one in the local account
  snapshot_id       = local.application_data.accounts[local.environment].oam_config_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OAM-config" },
  )
}
resource "aws_volume_attachment" "oam_onfig" {
  device_name = "/dev/xvdd"
  volume_id   = aws_ebs_volume.oam_config.id
  instance_id = aws_instance.oam_instance_1.id
}

resource "aws_ebs_volume" "oam_fmw" {
  availability_zone = "eu-west-2a"
  size              = 30
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oam_fmw_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OAM-fmw" },
  )
}
resource "aws_volume_attachment" "oam_fmw" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.oam_fmw.id
  instance_id = aws_instance.oam_instance_1.id
}

resource "aws_ebs_volume" "oam_aserver" {
  availability_zone = "eu-west-2a"
  size              = 15
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oam_aserver_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OAM-aserver" },
  )
}
resource "aws_volume_attachment" "oam_aserver" {
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.oam_aserver.id
  instance_id = aws_instance.oam_instance_1.id
}

resource "aws_ebs_volume" "oam_mserver" {
  availability_zone = "eu-west-2a"
  size              = 40
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].oam_mserver_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OAM-mserver" },
  )
}
resource "aws_volume_attachment" "oam_mserver" {
  device_name = "/dev/xvde"
  volume_id   = aws_ebs_volume.oam_mserver.id
  instance_id = aws_instance.oam_instance_1.id
}

###############################
# EC2 Instance Profile
###############################

# IAM Role, policy and instance profile (to attach the role to the EC2)

resource "aws_iam_instance_profile" "portal" {
  name = "${local.application_name}-ec2-instance-profile"
  role = aws_iam_role.portal.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-profile"
    }
  )
}

resource "aws_iam_role" "portal" {
  name = "${local.application_name}-ec2-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-role"
    }
  )
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# TODO What exactly do the instance role require kms:Decrypt for?

resource "aws_iam_policy" "portal" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-instance-policy"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-policy"
    }
  )
  policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "ec2:*",
                "ec2messages:*",
                "s3:*",
                "ssm:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "kms:Decrypt",
            "Resource": [
                "arn:aws:kms:eu-west-2:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.portal.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "portal" {
  role       = aws_iam_role.portal.name
  policy_arn = aws_iam_policy.portal.arn
}

#####################################
# OAM Route 53 records
#####################################

resource "aws_route53_record" "oam1_nonprod" {
  count    = local.environment != "production" ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name}-oam1-ms.${data.aws_route53_zone.external.name}" # Correspond to portal-oam1-ms.aws.dev.legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oam_instance_1.private_ip]
}

# resource "aws_route53_record" "oam1_prod" {
#   count    = local.environment == "production" ? 1 : 0
#   provider = aws.core-network-services
#   zone_id  = data.aws_route53_zone.portal-oam.zone_id # TODO This hosted zone name to be determined
#   name     = "${local.application_name}-oam1.${data.aws_route53_zone.portal-oam.zone_id}" # TODO Record name to be determined
#   type     = "A"
#   ttl      = 60
#   records  = [aws_instance.oam_instance_1.private_ip]
# }

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
