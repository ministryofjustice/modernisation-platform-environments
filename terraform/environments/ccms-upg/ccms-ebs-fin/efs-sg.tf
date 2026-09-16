resource "aws_security_group" "ebsapps_efs" {
  name        = "${local.component_name}-${local.env_label}-efs-sg"
  description = "Controls access to the EFS mount targets for the shared EBS apps /u01, /u03 and /stage filesystems"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-efs-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_apps" {
  security_group_id            = aws_security_group.ebsapps_efs.id
  description                  = "EFS from EBS apps tier"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.ebsapps.id
}
