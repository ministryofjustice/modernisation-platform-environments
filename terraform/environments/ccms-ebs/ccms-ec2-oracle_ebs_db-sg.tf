# Security Group for EBSDB

resource "aws_security_group" "ec2_sg_ebsdb" {
  name        = "ec2_sg_ebsdb"
  description = "SG traffic control for EBSDB"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-ebsdb", local.application_name, local.environment)) }
  )
}

# INGRESS Rules

### HTTP

resource "aws_security_group_rule" "ingress_traffic_ebsdb_80" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "HTTP"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### HTTPS

resource "aws_security_group_rule" "ingress_traffic_ebsdb_443" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### SSH

resource "aws_security_group_rule" "ingress_traffic_ebsdb_22" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### Oracle LDAP

resource "aws_security_group_rule" "ingress_traffic_ebsdb_1389" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle LDAP"
  protocol          = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### Oracle Listerner Port

resource "aws_security_group_rule" "ingress_traffic_ebsdb_152x" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle Net Listener"
  protocol          = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
    local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b,
  local.application_data.accounts[local.environment].cloud_platform_subnet]
}

### Oracle

resource "aws_security_group_rule" "ingress_traffic_ebsdb_5101" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### Oracle

resource "aws_security_group_rule" "ingress_traffic_ebsdb_5401" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### Oracle

resource "aws_security_group_rule" "ingress_traffic_ebsdb_5575" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### Oracle LDAP SSL

resource "aws_security_group_rule" "ingress_traffic_ebsdb_1636" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle LDAP SSL"
  protocol          = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### Oracle

resource "aws_security_group_rule" "ingress_traffic_ebsdb_10401" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### Oracle HTTP

resource "aws_security_group_rule" "ingress_traffic_ebsdb_800x" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle HTTP"
  protocol          = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}

### Oracle HTTPS

resource "aws_security_group_rule" "ingress_traffic_ebsdb_4443" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = "Oracle HTTPS"
  protocol          = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
  local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b]
}


# EGRESS Rules

### HTTP

resource "aws_security_group_rule" "egress_traffic_ebsdb_80" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle HTTPs"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

### HTTPS

resource "aws_security_group_rule" "egress_traffic_ebsdb_443" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

### FTP

resource "aws_security_group_rule" "egress_traffic_ebsdb_2x" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "FTP"
  protocol          = "TCP"
  from_port         = 20
  to_port           = 21
  cidr_blocks       = ["0.0.0.0/0"]
}

### SSH

resource "aws_security_group_rule" "egress_traffic_ebsdb_22" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

### ORACLE LDAP

resource "aws_security_group_rule" "egress_traffic_ebsdb_1389" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "ORACLE LDAP"
  protocol          = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_blocks       = ["0.0.0.0/0"]
}

### ORACLE Net Listener

resource "aws_security_group_rule" "egress_traffic_ebsdb_152x" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "ORACLE Net Listener"
  protocol          = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle

resource "aws_security_group_rule" "egress_traffic_ebsdb_5101" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle

resource "aws_security_group_rule" "egress_traffic_ebsdb_5401" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle

resource "aws_security_group_rule" "egress_traffic_ebsdb_5575" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle LDAP SSL

resource "aws_security_group_rule" "egress_traffic_ebsdb_1636" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle LDAP SSL"
  protocol          = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle

resource "aws_security_group_rule" "egress_traffic_ebsdb_10401" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_blocks       = ["0.0.0.0/0"]
}

### Lloyds FTP

resource "aws_security_group_rule" "egress_traffic_ebsdb_50000" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 50000
  to_port           = 51000
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle HTTP

resource "aws_security_group_rule" "egress_traffic_ebsdb_800x" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle HTTP"
  protocol          = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle HTTPS

resource "aws_security_group_rule" "egress_traffic_ebsdb_4443" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "Oracle HTTPS"
  protocol          = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_blocks       = ["0.0.0.0/0"]
}

### SMTP

resource "aws_security_group_rule" "egress_traffic_ebsdb_2525" {
  count             = local.is-production ? 0 : 1
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = "SMTP"
  protocol          = "TCP"
  from_port         = 2525
  to_port           = 2525
  cidr_blocks       = ["0.0.0.0/0"]
}

