locals {
  nonprod_workspaces_cidr         = "10.200.0.0/20"
  prod_workspaces_cidr            = "10.200.16.0/20"
  redc_cidr                       = "172.16.0.0/20"
  atos_cidr                       = "10.0.0.0/8"
  portal_hosted_zone              = data.aws_route53_zone.external.name # TODO This needs a logic for a TBC Hosted Zone for production


  # EC2 User data
  # TODO The hostname is too long as the domain itself is 62 characters long... If this hostname is required, a new domain is required

  idm_1_userdata = <<EOF
#!/bin/bash
echo "/dev/xvdb /IDAM/product/fmw ext4 defaults 0 0" >> /etc/fstab
echo "/dev/xvdc /IDAM/product/runtime/Domain/aserver ext4 defaults 0 0" >> /etc/fstab
echo "/dev/xvdd /IDAM/product/runtime/Domain/config ext4 defaults 0 0" >> /etc/fstab
echo "/dev/xvde /IDAM/product/runtime/Domain/mserver ext4 defaults 0 0" >> /etc/fstab
mount -a
hostnamectl set-hostname ${local.application_name}-idm1-ms.${local.portal_hosted_zone}
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

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.idm_instance.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# TODO some rules will need adding referencing Landing Zone environments (e.g. VPC) for other dependent applications not migrated to MP yet but needs talking to Portal.
# At the moment we are unsure what rules form LZ is required so leaving out those rules for now, to be added when dependencies identified in future tickets or testing.
# Some rules may need updating or removing as we migrate more applications across to MP.

resource "aws_vpc_security_group_ingress_rule" "weblogic_admin_port_from_shared_svs" {
  count = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.idm_instance.id
  description = "Weblogic Admin Server port from Shared Svs"
  cidr_ipv4   = local.nonprod_workspaces_cidr 
  from_port   = 7001
  ip_protocol = "tcp"
  to_port     = 7001
}

resource "aws_vpc_security_group_ingress_rule" "weblogic_admin_port2_from_shared_svs" {
  count = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.idm_instance.id
  description = "Weblogic Admin Server port from Shared Svs"
  cidr_ipv4   = local.nonprod_workspaces_cidr
  from_port   = 7201
  ip_protocol = "tcp"
  to_port     = 7201
}

resource "aws_vpc_security_group_ingress_rule" "idm_odsm_from_workspaces" {
  count = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.idm_instance.id
  description = "IDM ODSM access from Workspaces"
  cidr_ipv4   = local.nonprod_workspaces_cidr 
  from_port   = 14200
  ip_protocol = "tcp"
  to_port     = 14200
}

resource "aws_vpc_security_group_ingress_rule" "weblogic_admin_port_from_prod_shared_svs" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Weblogic Admin Server port from Prod Shared Svs"
  cidr_ipv4   = local.prod_workspaces_cidr 
  from_port   = 7001
  ip_protocol = "tcp"
  to_port     = 7001
}

resource "aws_vpc_security_group_ingress_rule" "idm_odsm_from_prod_workspaces" {
  security_group_id = aws_security_group.idm_instance.id
  description = "IDM ODSM access from Prod Workspaces"
  cidr_ipv4   = local.prod_workspaces_cidr 
  from_port   = 14200
  ip_protocol = "tcp"
  to_port     = 14200
}

resource "aws_vpc_security_group_ingress_rule" "weblogic_server_port" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Weblogic Managed Server port"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block 
  from_port   = 4444
  ip_protocol = "tcp"
  to_port     = 4444
}

resource "aws_vpc_security_group_ingress_rule" "opmn_idm1_to_idm2" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Allow Adminserver to communicate to OPMN from IDM1 to IDM2"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block 
  from_port   = 6800
  ip_protocol = "tcp"
  to_port     = 6801
}

resource "aws_vpc_security_group_ingress_rule" "idm_nodemanager" {
  security_group_id = aws_security_group.idm_instance.id
  description = "IDM NodeManager Port"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block 
  from_port   = 5556
  ip_protocol = "tcp"
  to_port     = 5556
}

resource "aws_vpc_security_group_ingress_rule" "idm_server_ods" {
  security_group_id = aws_security_group.idm_instance.id
  description = "IDM Managed Server(ods)"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block 
  from_port   = 14200
  ip_protocol = "tcp"
  to_port     = 14200
}

resource "aws_vpc_security_group_ingress_rule" "idm_ingress_1636_tls" {
  security_group_id = aws_security_group.idm_instance.id
  description = "IDM Inbound on 1636 TLS"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block 
  from_port   = 1636
  ip_protocol = "tcp" 
  to_port     = 1636
}

resource "aws_vpc_security_group_ingress_rule" "weblogic_admin_server_port" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Weblogic Admin Server port"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block 
  from_port   = 7001
  ip_protocol = "tcp" 
  to_port     = 7001
}

resource "aws_vpc_security_group_ingress_rule" "ping_echo" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Ping Echo"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block 
  from_port   = 6200
  ip_protocol = "tcp" 
  to_port     = 6200
}

resource "aws_vpc_security_group_ingress_rule" "ping_allow" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Allow ping response"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block
  from_port   = 8
  ip_protocol = "icmp"
  to_port     = -1
}

resource "aws_vpc_security_group_ingress_rule" "weblogic_admin_server_port2" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Weblogic Admin Server port"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block 
  from_port   = 7201
  ip_protocol = "tcp" 
  to_port     = 7201
}

resource "aws_vpc_security_group_ingress_rule" "idm_ingress_1389_tls" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Idm Inbound on 1389"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block
  from_port   = 1389
  ip_protocol = "tcp"
  to_port     = 1389
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

resource "aws_vpc_security_group_ingress_rule" "redc_1636_tls" {
  count = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.idm_instance.id
  cidr_ipv4   = local.redc_cidr
  from_port   = 1636
  ip_protocol = "tcp"
  to_port     = 1636
}

resource "aws_vpc_security_group_ingress_rule" "redc_1389_tls" {
  count = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.idm_instance.id
  cidr_ipv4   = local.redc_cidr
  from_port   = 1389
  ip_protocol = "tcp"
  to_port     = 1389
}

resource "aws_vpc_security_group_ingress_rule" "atos_1636_tls" {
  count = contains(["uat", "production"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.idm_instance.id
  cidr_ipv4   = local.atos_cidr
  from_port   = 1636
  ip_protocol = "tcp"
  to_port     = 1636
}

resource "aws_vpc_security_group_ingress_rule" "atos_1389_tls" {
  count = contains(["uat", "production"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.idm_instance.id
  cidr_ipv4   = local.atos_cidr
  from_port   = 1389
  ip_protocol = "tcp"
  to_port     = 1389
}

resource "aws_vpc_security_group_ingress_rule" "nfs_idm_to_idm" {
  security_group_id = aws_security_group.idm_instance.id
  description = "Inbound NFS from other IDM instances"
  referenced_security_group_id = aws_security_group.idm_instance.id
  from_port   = 2049
  ip_protocol = "tcp"
  to_port     = 2049
}

######################################
# IDM Instance
######################################

resource "aws_instance" "idm_instance_1" {
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
