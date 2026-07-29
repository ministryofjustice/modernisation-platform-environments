# ALB Security Group

resource "aws_security_group" "ebsapps_alb" {
  name        = "${local.component_name}-${local.env_label}-alb-sg"
  description = "Controls access to the EBS apps application load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_vpc" {
  security_group_id = aws_security_group.ebsapps_alb.id
  description       = "HTTPS from the shared VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "alb_to_apps" {
  security_group_id            = aws_security_group.ebsapps_alb.id
  description                  = "Traffic to EBS apps on application port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].tg_apps_port
  to_port                      = local.application_data.accounts[local.environment].tg_apps_port
  referenced_security_group_id = aws_security_group.ebsapps.id
}

# EBS Apps Security Group

resource "aws_security_group" "ebsapps" {
  name        = "${local.component_name}-${local.env_label}-ebsapps-sg"
  description = "Controls access to the EBS application tier EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsapps-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ebsapps_from_alb" {
  security_group_id            = aws_security_group.ebsapps.id
  description                  = "Application traffic from ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].tg_apps_port
  to_port                      = local.application_data.accounts[local.environment].tg_apps_port
  referenced_security_group_id = aws_security_group.ebsapps_alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ebsapps_ssh" {
  security_group_id = aws_security_group.ebsapps.id
  description       = "SSH from the shared VPC"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "ebsapps_to_db_oracle" {
  security_group_id            = aws_security_group.ebsapps.id
  description                  = "Oracle Net listener to DB tier"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1522
  referenced_security_group_id = aws_security_group.ebsdb.id
}

resource "aws_vpc_security_group_egress_rule" "ebsapps_https" {
  security_group_id = aws_security_group.ebsapps.id
  description       = "HTTPS outbound"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ebsapps_http" {
  security_group_id = aws_security_group.ebsapps.id
  description       = "HTTP outbound"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# EBS DB Security Group

resource "aws_security_group" "ebsdb" {
  name        = "${local.component_name}-${local.env_label}-ebsdb-sg"
  description = "Controls access to the EBS database tier EC2 instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsdb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ebsdb_from_apps_oracle" {
  security_group_id            = aws_security_group.ebsdb.id
  description                  = "Oracle Net listener from EBS apps tier"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1522
  referenced_security_group_id = aws_security_group.ebsapps.id
}

resource "aws_vpc_security_group_ingress_rule" "ebsdb_ssh" {
  security_group_id = aws_security_group.ebsdb.id
  description       = "SSH from the shared VPC"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "ebsdb_https" {
  security_group_id = aws_security_group.ebsdb.id
  description       = "HTTPS outbound"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ebsdb_http" {
  security_group_id = aws_security_group.ebsdb.id
  description       = "HTTP outbound"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}
