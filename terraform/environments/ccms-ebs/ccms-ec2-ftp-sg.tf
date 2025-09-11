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

# Security Group for FTP Server

resource "aws_security_group" "ec2_sg_ftp" {
  name        = "ec2_sg_ftp"
  description = "Security Group for FTP Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-FTP", local.application_name, local.environment)) }
  )
}

### INGRESS Rules
# FTP

resource "aws_vpc_security_group_ingress_rule" "ingress_private_traffic_lambda" {
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "Allow all TCP traffic from Lambda"
  protocol          = "TCP"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_vpc_security_group_ingress_rule" "ingress_data_traffic_ebsdb" {
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "Allow all TCP traffic from EBS DB"
  protocol          = "TCP"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = [data.aws_subnet.data_subnets_a.cidr_block, data.aws_subnet.data_subnets_b.cidr_block, data.aws_subnet.data_subnets_c.cidr_block]
}


### EGRESS Rules
# FTP

# SSH
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ftp_22_xerox" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "SSH for testing third party host xerox"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-xerox-outbound"].secret_string)["HOST_CIDR"]]
}

# SSH
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ftp_22_eckoh" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "SSH for testing third party host eckoh"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-eckoh-inbound-ccms"].secret_string)["HOST_CIDR"]]
}

# SSH
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ftp_22_allpay" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "SSH for testing third party host allpay"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-allpay-inbound-ccms"].secret_string)["HOST_CIDR"]]
}

# SSH
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ftp_22_rossendales" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "SSH for testing third party host rossendales"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-rossendales-ccms-inbound"].secret_string)["HOST_CIDR"]]
}

# SFTP
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ftp_8022" {
  count             = local.environment != "test" ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "SFTP for 1stlocate thirdparty"
  protocol          = "TCP"
  from_port         = 8022
  to_port           = 8022
  cidr_blocks       = [jsondecode(data.aws_secretsmanager_secret_version.secrets["LAA-ftp-1stlocate-ccms-inbound"].secret_string)["HOST_CIDR"]]
}

# HTTPS
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ftp_443" {
  security_group_id = aws_security_group.ec2_sg_ftp.id
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}
