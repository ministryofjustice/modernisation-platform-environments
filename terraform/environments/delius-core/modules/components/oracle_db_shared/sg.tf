resource "aws_security_group" "db_ec2" {
  #checkov:skip=CKV2_AWS_5 "ignore"
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
  to_port           = local.db_port
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
  to_port           = local.db_port
  ip_protocol       = "tcp"
  description       = "Allow communication in on port 1521 from legacy rman"
  tags = merge(var.tags,
    { Name = "legacy-rman-in" }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_ec2_instance_legacy_oracle" {
  for_each = toset(var.environment_config.migration_environment_db_cidr)

  security_group_id = aws_security_group.db_ec2.id
  cidr_ipv4         = each.key
  from_port         = local.db_port
  to_port           = local.db_port
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 1521 to legacy"
  tags = merge(var.tags,
    { Name = "legacy-oracle-out-db" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "db_ec2_instance_legacy_oracle" {
  for_each = toset(var.environment_config.migration_environment_db_cidr)

  security_group_id = aws_security_group.db_ec2.id
  cidr_ipv4         = each.key
  from_port         = local.db_port
  to_port           = local.db_port
  ip_protocol       = "tcp"
  description       = "Allow communication in on port 1521 from legacy"
  tags = merge(var.tags,
    { Name = "legacy-oracle-in-db" }
  )
}

resource "aws_vpc_security_group_egress_rule" "asg_ec2_instance_legacy_oracle" {
  for_each = toset(var.environment_config.migration_environment_private_cidr)

  security_group_id = aws_security_group.db_ec2.id
  cidr_ipv4         = each.key
  from_port         = local.db_port
  to_port           = local.db_port
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 1521 to legacy"
  tags = merge(var.tags,
    { Name = "legacy-oracle-out-asg" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "asg_ec2_instance_legacy_oracle" {
  for_each = toset(var.environment_config.migration_environment_private_cidr)

  security_group_id = aws_security_group.db_ec2.id
  cidr_ipv4         = each.key
  from_port         = local.db_port
  to_port           = local.db_port
  ip_protocol       = "tcp"
  description       = "Allow communication in on port 1521 from legacy"
  tags = merge(var.tags,
    { Name = "legacy-oracle-in-asg" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "cp_oracle" {
  security_group_id = aws_security_group.db_ec2.id
  cidr_ipv4         = var.account_info.cp_cidr
  from_port         = local.db_port
  to_port           = local.db_port
  ip_protocol       = "tcp"
  description       = "Allow communication in on port 1521 from CP"
  tags = merge(var.tags,
    { Name = "cp-oracle-in-asg" }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_inter_conn" {
  security_group_id            = aws_security_group.db_ec2.id
  description                  = "Allow communication between delius db instances"
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_ingress_rule" "db_inter_conn" {
  security_group_id            = aws_security_group.db_ec2.id
  description                  = "Allow communication between delius db instances"
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_security_group_ssh_ingress_bastion" {
  #checkov:skip=CKV_AWS_24
  security_group_id = aws_security_group.db_ec2.id
  description       = "bastion to testing db"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  # referenced_security_group_id = var.bastion_sg_id # Temporarily removed to recreate bastion SG
  cidr_ipv4 = var.account_config.shared_vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_oem_db" {
  #checkov:skip=CKV_AWS_23
  ip_protocol       = "tcp"
  from_port         = local.db_port
  to_port           = local.db_port
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_egress_rule" "delius_db_rman_db" {
  ip_protocol       = "tcp"
  from_port         = local.db_port
  to_port           = local.db_port
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  security_group_id = aws_security_group.db_ec2.id
  description       = "Allow communication out on port 1521 to rman"
  tags = merge(var.tags,
    { Name = "rman-out" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_oem_agent" {
  #checkov:skip=CKV_AWS_23
  ip_protocol       = "tcp"
  from_port         = 3872
  to_port           = 3872
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_egress_rule" "delius_db_oem_upload" {
  #checkov:skip=CKV_AWS_23
  ip_protocol       = "tcp"
  from_port         = 4903
  to_port           = 4903
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  security_group_id = aws_security_group.db_ec2.id
}

resource "aws_vpc_security_group_egress_rule" "delius_db_oem_console" {
  #checkov:skip=CKV_AWS_23
  ip_protocol = "tcp"
  from_port   = 7803
  to_port     = 7803
  cidr_ipv4   = var.account_config.shared_vpc_cidr

  security_group_id = aws_security_group.db_ec2.id
}

# https://dsdmoj.atlassian.net/browse/TM-1162
# resource "aws_vpc_security_group_ingress_rule" "ap_db_oracle" {
#   count             = (var.env_name == "dev" || var.env_name == "test") ? 1 : 0
#   ip_protocol       = "tcp"
#   from_port         = 1521
#   to_port           = 1522
#   cidr_ipv4         = local.ap_dev_cidr
#   security_group_id = aws_security_group.db_ec2.id
#   description       = "Allow communication in on port 1521/1522 from AP dev"
#   tags = merge(var.tags,
#     { Name = "ap-oracle-in" }
#   )
# }

resource "aws_vpc_security_group_ingress_rule" "ap_db_oracle" {
  for_each = try({ for env, cidr in local.ap_env_cidrs : env => cidr if env == var.env_name }, {})

  ip_protocol       = "tcp"
  from_port         = local.db_port
  to_port           = local.db_port
  cidr_ipv4         = each.value
  security_group_id = aws_security_group.db_ec2.id
  description       = "Allow communication in on port 1521,1522 from AP ${each.key}"
  tags = merge(var.tags,
    { Name = "ap-oracle-in-${each.key}" }
  )
}
