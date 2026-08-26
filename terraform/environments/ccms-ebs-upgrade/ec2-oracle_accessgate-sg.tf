# Security Group for AccessGate
resource "aws_security_group" "ec2_sg_accessgate" {
  name        = "ec2_sg_accessgate"
  description = "SG traffic control for AccessGate"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-accessgate", local.application_name, local.environment)) }
  )
}

# INGRESS Rules

### HTTP

resource "aws_security_group_rule" "ingress_traffic_accessgate_80" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "HTTP"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### HTTPS

resource "aws_security_group_rule" "ingress_traffic_accessgate_443" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### SSH

resource "aws_security_group_rule" "ingress_traffic_accessgate_22" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle LDAP

resource "aws_security_group_rule" "ingress_traffic_accessgate_1389" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle LDAP"
  protocol          = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle Listerner Port

resource "aws_security_group_rule" "ingress_traffic_accessgate_152x" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle Net Listener"
  protocol          = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle

resource "aws_security_group_rule" "ingress_traffic_accessgate_5101" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle

resource "aws_security_group_rule" "ingress_traffic_accessgate_5401" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle

resource "aws_security_group_rule" "ingress_traffic_accessgate_5575" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle LDAP SSL

resource "aws_security_group_rule" "ingress_traffic_accessgate_1636" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle LDAP SSL"
  protocol          = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle

resource "aws_security_group_rule" "ingress_traffic_accessgate_10401" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle HTTP

resource "aws_security_group_rule" "ingress_traffic_accessgate_800x" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle HTTP"
  protocol          = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

### Oracle HTTPS

resource "aws_security_group_rule" "ingress_traffic_accessgate_4443" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = "Oracle HTTPS"
  protocol          = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
  local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}


# EGRESS Rules

### HTTP

resource "aws_security_group_rule" "egress_traffic_accessgate_80" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle HTTPs"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

### HTTPS

resource "aws_security_group_rule" "egress_traffic_accessgate_443" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

### FTP

resource "aws_security_group_rule" "egress_traffic_accessgate_2x" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "FTP"
  protocol          = "TCP"
  from_port         = 20
  to_port           = 21
  cidr_blocks       = ["0.0.0.0/0"]
}

### SSH

resource "aws_security_group_rule" "egress_traffic_accessgate_22" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

### ORACLE LDAP

resource "aws_security_group_rule" "egress_traffic_accessgate_1389" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "ORACLE LDAP"
  protocol          = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_blocks       = ["0.0.0.0/0"]
}

### ORACLE Net Listener

resource "aws_security_group_rule" "egress_traffic_accessgate_152x" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "ORACLE Net Listener"
  protocol          = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle

resource "aws_security_group_rule" "egress_traffic_accessgate_5101" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle

resource "aws_security_group_rule" "egress_traffic_accessgate_5401" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle

resource "aws_security_group_rule" "egress_traffic_accessgate_5575" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle LDAP SSL

resource "aws_security_group_rule" "egress_traffic_accessgate_1636" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle LDAP SSL"
  protocol          = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle

resource "aws_security_group_rule" "egress_traffic_accessgate_10401" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_blocks       = ["0.0.0.0/0"]
}

### Lloyds FTP

resource "aws_security_group_rule" "egress_traffic_accessgate_50000" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle"
  protocol          = "TCP"
  from_port         = 50000
  to_port           = 51000
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle HTTP

resource "aws_security_group_rule" "egress_traffic_accessgate_800x" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle HTTP"
  protocol          = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_blocks       = ["0.0.0.0/0"]
}

### Oracle HTTPS

resource "aws_security_group_rule" "egress_traffic_accessgate_4443" {
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = "Oracle HTTPS"
  protocol          = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_blocks       = ["0.0.0.0/0"]
}

