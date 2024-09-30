resource "aws_security_group" "db_ec2" {
  name        = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-ec2-instance-sg"
  description = "Controls access to db ec2 instance"
  vpc_id      = var.account_config.shared_vpc_id
  tags = merge(var.tags,
    { Name = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-ec2-instance-sg" }
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "db_ec2_instance_https_out" {
  security_group_id = aws_security_group.db_ec2.id
  cidr_ipv4         = "0.0.0.0/0" #trivy:ignore:avd-aws-0104
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 443, e.g. for SSM"
  tags = merge(var.tags,
    { Name = "https-out" }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_ec2_instance_rman" {
  security_group_id = aws_security_group.db_ec2.id
  cidr_ipv4         = var.environment_config.legacy_engineering_vpc_cidr
  from_port         = local.db_port
  to_port           = local.db_tcps_port
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 1521 to legacy rman"
  tags = merge(var.tags,
    { Name = "legacy-rman-out" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "db_ec2_instance_rman" {
  security_group_id = aws_security_group.db_ec2.id
  cidr_ipv4         = var.environment_config.legacy_engineering_vpc_cidr
  from_port         = local.db_port
  to_port           = local.db_tcps_port
  ip_protocol       = "tcp"
  description       = "Allow communication in on port 1521 from legacy rman"
  tags = merge(var.tags,
    { Name = "legacy-rman-in" }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_inter_conn" {
  security_group_id            = aws_security_group.db_ec2.id
  description                  = "Allow communication between delius db instances"
  from_port                    = local.db_port
  to_port                      = local.db_tcps_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_ingress_rule" "db_inter_conn" {
  security_group_id            = aws_security_group.db_ec2.id
  description                  = "Allow communication between delius db instances"
  from_port                    = local.db_port
  to_port                      = local.db_tcps_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_security_group_ingress_bastion" {
  security_group_id            = aws_security_group.db_ec2.id
  description                  = "bastion to testing db"
  from_port                    = local.db_port
  to_port                      = local.db_tcps_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.bastion_sg_id
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_security_group_ssh_ingress_bastion" {
  security_group_id            = aws_security_group.db_ec2.id
  description                  = "bastion to testing db"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.bastion_sg_id
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_oem_db" {
  ip_protocol       = "tcp"
  from_port         = local.db_port
  to_port           = local.db_tcps_port
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_egress_rule" "delius_db_rman_db" {
  ip_protocol       = "tcp"
  from_port         = local.db_port
  to_port           = local.db_tcps_port
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  security_group_id = aws_security_group.db_ec2.id
  description       = "Allow communication out on port 1521 to rman"
  tags = merge(var.tags,
    { Name = "rman-out" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_oem_agent" {
  ip_protocol       = "tcp"
  from_port         = 3872
  to_port           = 3872
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_egress_rule" "delius_db_oem_upload" {
  ip_protocol       = "tcp"
  from_port         = 4903
  to_port           = 4903
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_egress_rule" "delius_db_oem_console" {
  ip_protocol = "tcp"
  from_port   = 7803
  to_port     = 7803
  cidr_ipv4   = var.account_config.shared_vpc_cidr

  security_group_id = aws_security_group.db_ec2.id
}
