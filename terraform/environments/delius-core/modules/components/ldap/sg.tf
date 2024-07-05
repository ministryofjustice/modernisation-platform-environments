resource "aws_security_group" "ldap" {
  name        = "${var.env_name}-ldap-sg"
  description = "Security group for the ${var.env_name} ldap service"
  vpc_id      = var.account_info.vpc_id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  description       = "Allow all outbound traffic to any IPv4 address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ldap.id
}

resource "aws_security_group_rule" "ldap_nlb" {
  for_each          = toset(["tcp", "udp"])
  description       = "Allow inbound traffic from VPC"
  type              = "ingress"
  from_port         = var.ldap_config.port
  to_port           = var.ldap_config.port
  protocol          = each.value
  security_group_id = aws_security_group.ldap.id
  cidr_blocks       = [var.account_config.shared_vpc_cidr]
}

resource "aws_security_group_rule" "to_ldap_from_bastion" {
  for_each                 = toset(["tcp", "udp"])
  description              = "Allow inbound traffic from bastion"
  type                     = "ingress"
  from_port                = var.ldap_config.port
  to_port                  = var.ldap_config.port
  protocol                 = each.value
  security_group_id        = aws_security_group.ldap.id
  source_security_group_id = var.bastion_sg_id
}

resource "aws_security_group_rule" "allow_ldap_from_legacy_env" {
  for_each          = toset(["tcp", "udp"])
  description       = "Allow inbound LDAP traffic from corresponding legacy VPC"
  type              = "ingress"
  from_port         = var.ldap_config.port
  to_port           = var.ldap_config.port
  protocol          = each.value
  security_group_id = aws_security_group.ldap.id
  cidr_blocks       = var.environment_config.migration_environment_private_cidr
}

resource "aws_security_group_rule" "allow_ldap_from_cp_env" {
  for_each          = toset(["tcp", "udp"])
  description       = "Allow inbound LDAP traffic from CP"
  type              = "ingress"
  from_port         = var.ldap_config.port
  to_port           = var.ldap_config.port
  protocol          = each.value
  security_group_id = aws_security_group.ldap.id
  cidr_blocks       = [var.account_info.cp_cidr]
}

resource "aws_security_group_rule" "efs_ingress_ldap" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = module.efs.sg_id
  security_group_id        = aws_security_group.ldap.id
}
