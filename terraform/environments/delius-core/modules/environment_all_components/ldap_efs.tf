resource "aws_efs_file_system" "ldap" {
  creation_token = "${var.env_name}-ldap"
  tags = merge(
    local.tags,
    {
      Name = "${var.env_name}-ldap-efs"
    }
  )
}

resource "aws_security_group" "ldap_efs" {
  name        = "${var.env_name}-ldap-efs"
  description = "Allow traffic between ldap service and efs in ${var.env_name}"
  vpc_id      = var.account_info.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "efs_ingress" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ldap.id
  security_group_id        = aws_security_group.ldap_efs.id
}

resource "aws_security_group_rule" "efs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [var.network_config.shared_vpc_cidr]
  security_group_id = aws_security_group.ldap_efs.id
}