resource "aws_security_group" "smtp4dev_sg_kpmg" {
  count       = local.is-preproduction ? 1 : 0
  name        = "smtp4dev_sg_kpmg"
  description = "Additional rules to allow KPMG access SMTP4DEV"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = "smtp4dev_sg_kpmg" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "smtp4dev_workspace_22_ingress_rule_kpmg" {
  count             = local.is-preproduction ? 1 : 0
  security_group_id = aws_security_group.smtp4dev_sg_kpmg[count.index].id
  description       = "AWS Workspace to SMTP4DEV:22"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod

  tags = merge(local.tags,
    { Name = "smtp4dev_sg_kpmg_ingress_22" }
  )
}
