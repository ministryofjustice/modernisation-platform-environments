resource "aws_security_group" "ftp_sg_kpmg" {
  name        = "ftp_sg_kpmg"
  description = "Additional rules to allow KPMG access FTP"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-FTP-KPMG", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ftp_workspaces_22_ingress_kpmg" {
  count             = local.is-preproduction ? 1 : 0
  security_group_id = aws_security_group.ftp_sg_kpmg.id
  description       = "[KPMG] AWS Workspaces to FTP:22"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod

  tags = merge(local.tags,
    { Name = "[KPMG] AWS Workspaces to FTP:22" }
  )
}
