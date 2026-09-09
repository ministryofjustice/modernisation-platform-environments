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

resource "aws_vpc_security_group_ingress_rule" "ebsdb_from_cloud_platform_oracle" {
  security_group_id = aws_security_group.ebsdb.id
  description       = "Oracle Net listener from Cloud Platform"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1522
  cidr_ipv4         = local.application_data.accounts[local.environment].cloud_platform_subnet
}

resource "aws_vpc_security_group_ingress_rule" "ebsdb_from_apps_fndfs" {
  security_group_id            = aws_security_group.ebsdb.id
  description                  = "Application Listener (FNDFS) from EBS apps tier"
  ip_protocol                  = "tcp"
  from_port                    = 1626
  to_port                      = 1626
  referenced_security_group_id = aws_security_group.ebsapps.id
}

resource "aws_vpc_security_group_egress_rule" "ebsdb_to_apps_fndfs" {
  security_group_id            = aws_security_group.ebsdb.id
  description                  = "Application Listener (FNDFS) to EBS apps tier"
  ip_protocol                  = "tcp"
  from_port                    = 1626
  to_port                      = 1626
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

resource "aws_vpc_security_group_ingress_rule" "ebsdb_ssh_workspace" {
  security_group_id = aws_security_group.ebsdb.id
  description       = "SSH from AWS Workspaces"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ebsdb_plsql_workspace" {
  security_group_id = aws_security_group.ebsdb.id
  description       = "PLSQL from AWS Workspaces"
  ip_protocol       = "tcp"
  from_port         = 1522
  to_port           = 1522
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
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
