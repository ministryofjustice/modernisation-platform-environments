resource "aws_efs_file_system" "ldap" {
  creation_token                  = "${var.env_name}-ldap"
  encrypted                       = true
  kms_key_id                      = var.account_config.general_shared_kms_key_arn
  throughput_mode                 = var.ldap_config.efs_throughput_mode
  provisioned_throughput_in_mibps = var.ldap_config.efs_provisioned_throughput
  tags = merge(
    local.tags,
    {
      Name = "${var.env_name}-ldap-efs"
    }
  )
}

resource "aws_efs_mount_target" "ldap" {
  for_each       = toset(var.account_config.private_subnet_ids)
  file_system_id = aws_efs_file_system.ldap.id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.ldap_efs.id,
  ]
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
  cidr_blocks       = [var.account_config.shared_vpc_cidr]
  security_group_id = aws_security_group.ldap_efs.id
}
