# # Reference the secret for 1stlocate ftp thirdparty
# data "aws_secretsmanager_secret" "ftp_tp_secret" {
#   name = "LAA-ftp-1stlocate-ccms-inbound-${local.environment}"
# }

# # Get the latest version of the secret value for1stlocate ftp thirdparty
# data "aws_secretsmanager_secret_version" "ftp_tp_secret_value" {
#   secret_id = data.aws_secretsmanager_secret.ftp_tp_secret.id
# }

locals {
  # ftp_tp_secret_value = jsondecode(data.aws_secretsmanager_secret_version.ftp_tp_secret_value.secret_string)
  secret_ids = [
    "LAA-ftp-allpay-inbound-ccms",
    "LAA-ftp-rossendales-ccms-inbound",
    "LAA-ftp-eckoh-inbound-ccms",
    "LAA-ftp-1stlocate-ccms-inbound",
    "LAA-ftp-xerox-outbound"
  ]
  # full_secret_ids = [
  #   for id in local.secret_ids : "${id}-${local.environment}"
  # ]

  # host_cidrs = {
  #   for key, secret in data.aws_secretsmanager_secret_version.secrets :
  #   key => jsondecode(secret.secret_string)["HOST_CIDR"]
  # }

  # # Filtered CIDRs for SSH only
  # ssh_host_cidrs = {
  #   for key, value in local.host_cidrs :
  #   key => value
  #   if !(key == ["LAA-ftp-1stlocate-ccms-inbound-${local.environment}"])
  # }
}

# Fetch each secret's current version
data "aws_secretsmanager_secret_version" "secrets" {
  for_each = toset(local.secret_ids)

  secret_id = "${each.value}-${local.environment}"
}

# Reference Lambda security group by name tag
data "aws_security_group" "lambda_security_group" {
  vpc_id = data.aws_vpc.shared.id
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-lambda-sg"]
  }
}

# VPC endpoint subnets for outbound connectivity
data "aws_subnet" "vpce_subnets_a" {
  vpc_id            = data.aws_vpc.shared.id
  availability_zone = data.aws_availability_zones.available.names[0]
  filter {
    name   = "tag:Name"
    values = ["${local.vpc_name}-vpce-*"]
  }
}

data "aws_subnet" "vpce_subnets_b" {
  vpc_id            = data.aws_vpc.shared.id
  availability_zone = data.aws_availability_zones.available.names[1]
  filter {
    name   = "tag:Name"
    values = ["${local.vpc_name}-vpce-*"]
  }
}

data "aws_subnet" "vpce_subnets_c" {
  vpc_id            = data.aws_vpc.shared.id
  availability_zone = data.aws_availability_zones.available.names[2]
  filter {
    name   = "tag:Name"
    values = ["${local.vpc_name}-vpce-*"]
  }
}

# S3 gateway endpoint prefix list
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

# Security Group for FTP Server

resource "aws_security_group" "ec2_sg_ftp" {
  name        = "ec2_sg_ftp"
  description = "Security Group for FTP Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-FTP", local.application_name, local.environment)) }
  )
}

# INGRESS Rules

### FTP

# resource "aws_security_group_rule" "ingress_traffic_ftp_20" {
#   security_group_id = aws_security_group.ec2_sg_ftp.id
#   type              = "ingress"
#   description       = "FTP"
#   protocol          = "TCP"
#   from_port         = 20
#   to_port           = 21
#   cidr_blocks = [data.aws_vpc.shared.cidr_block,
#   local.application_data.accounts[local.environment].lz_aws_subnet_env]
# }

# ### FTP Passive Ports

# resource "aws_security_group_rule" "ingress_traffic_ftp_3000" {
#   security_group_id = aws_security_group.ec2_sg_ftp.id
#   type              = "ingress"
#   description       = "FTP Passive Ports"
#   protocol          = "TCP"
#   from_port         = 3000
#   to_port           = 3010
#   cidr_blocks = [data.aws_vpc.shared.cidr_block,
#   local.application_data.accounts[local.environment].lz_aws_subnet_env]
# }

# ### SSH

# resource "aws_security_group_rule" "ingress_traffic_ftp_22" {
#   security_group_id = aws_security_group.ec2_sg_ftp.id
#   type              = "ingress"
#   description       = "SSH"
#   protocol          = "TCP"
#   from_port         = 22
#   to_port           = 22
#   cidr_blocks = [data.aws_vpc.shared.cidr_block,
#   local.application_data.accounts[local.environment].lz_aws_subnet_env]
# }



resource "aws_vpc_security_group_ingress_rule" "ingress_ftp_lambda_443" {
  security_group_id            = aws_security_group.ec2_sg_ftp.id
  description                  = "Allow ingress from lambda security group on port 443"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = data.aws_security_group.lambda_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ftp_ebsdb_22" {
  security_group_id            = aws_security_group.ec2_sg_ftp.id
  description                  = "Allow ingress from EBS DB security group on port 22"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.ec2_sg_ebsdb.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ftp_ftp_1521_1522" {
  security_group_id            = aws_security_group.ec2_sg_ftp.id
  description                  = "Allow ingress from FTP security group on ports 1521-1522"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1522
  referenced_security_group_id = aws_security_group.ec2_sg_ftp.id
}


# EGRESS Rules

resource "aws_vpc_security_group_egress_rule" "egress_ftp_ebsdb_1521_1522" {
  security_group_id            = aws_security_group.ec2_sg_ftp.id
  description                  = "Allow egress to EBS DB security group on ports 1521-1522"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1522
  referenced_security_group_id = aws_security_group.ec2_sg_ebsdb.id
}

resource "aws_vpc_security_group_egress_rule" "egress_ftp_vpce" {
  for_each = toset([
    data.aws_subnet.vpce_subnets_a.cidr_block,
    data.aws_subnet.vpce_subnets_b.cidr_block,
    data.aws_subnet.vpce_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "Allow egress to VPC endpoints (S3 / Secrets Manager)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "egress_ftp_s3" {
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "Allow S3 access via gateway endpoint (prefix list)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

### FTP

# resource "aws_security_group_rule" "egress_traffic_ftp_20" {
#   security_group_id = aws_security_group.ec2_sg_ftp.id
#   type              = "egress"
#   description       = "FTP"
#   protocol          = "TCP"
#   from_port         = 20
#   to_port           = 21
#   cidr_blocks = [data.aws_vpc.shared.cidr_block,
#   local.application_data.accounts[local.environment].lz_aws_subnet_env]
# }

### SSH

# resource "aws_security_group_rule" "egress_traffic_ftp_22" {
#   count               = local.environment != "test" ? 1 : 0
#   for_each = local.ssh_host_cidrs
#   security_group_id = aws_security_group.ec2_sg_ftp.id
#   type              = "egress"
#   description       = "SSH for testing third party host ${each.key}"
#   protocol          = "TCP"
#   from_port         = 22
#   to_port           = 22
#   cidr_blocks       = [each.value]
# }

resource "aws_security_group_rule" "egress_traffic_ftp_22_xerox" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  type              = "egress"
  description       = "SSH for testing third party host xerox"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-xerox-outbound"].secret_string)["HOST_CIDR"]]
}

resource "aws_security_group_rule" "egress_traffic_ftp_22_eckoh" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  type              = "egress"
  description       = "SSH for testing third party host eckoh"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-eckoh-inbound-ccms"].secret_string)["HOST_CIDR"]]
}

resource "aws_security_group_rule" "egress_traffic_ftp_22_allpay" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  type              = "egress"
  description       = "SSH for testing third party host allpay"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-allpay-inbound-ccms"].secret_string)["HOST_CIDR"]]
}

resource "aws_security_group_rule" "egress_traffic_ftp_22_rossendales" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  type              = "egress"
  description       = "SSH for testing third party host rossendales"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-rossendales-ccms-inbound"].secret_string)["HOST_CIDR"]]
}

### SFTP
resource "aws_security_group_rule" "egress_traffic_ftp_8022" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  type              = "egress"
  description       = "SFTP for 1stlocate thirdparty"
  protocol          = "TCP"
  from_port         = 8022
  to_port           = 8022
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-1stlocate-ccms-inbound"].secret_string)["HOST_CIDR"]]
}
### HTTPS

resource "aws_security_group_rule" "egress_traffic_ftp_443" {
  security_group_id = aws_security_group.ec2_sg_ftp.id
  type              = "egress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}
