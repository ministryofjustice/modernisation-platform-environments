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

resource "aws_vpc_security_group_ingress_rule" "ebsapps_ssh_workspace" {
  security_group_id = aws_security_group.ebsapps.id
  description       = "SSH from AWS Workspaces"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_egress_rule" "ebsapps_to_db_oracle" {
  security_group_id            = aws_security_group.ebsapps.id
  description                  = "Oracle Net listener to DB tier"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1522
  referenced_security_group_id = aws_security_group.ebsdb.id
}

resource "aws_vpc_security_group_ingress_rule" "ebsapps_from_db_fndfs" {
  security_group_id            = aws_security_group.ebsapps.id
  description                  = "Application Listener (FNDFS) from EBS db tier"
  ip_protocol                  = "tcp"
  from_port                    = 1626
  to_port                      = 1626
  referenced_security_group_id = aws_security_group.ebsdb.id
}

resource "aws_vpc_security_group_egress_rule" "ebsapps_to_db_fndfs" {
  security_group_id            = aws_security_group.ebsapps.id
  description                  = "Application Listener (FNDFS) to EBS db tier"
  ip_protocol                  = "tcp"
  from_port                    = 1626
  to_port                      = 1626
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
