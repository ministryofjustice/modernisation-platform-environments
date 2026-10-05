resource "aws_security_group" "sftp_cluster_ec2_kpmg" {
  name        = "${local.sftp_suffix}-cluster-ec2-security-group-KPMG"
  description = "Additional rules to allow KPMG access the SFTP cluster"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-cluster-ec2-security-group-KPMG" }
  )}

resource "aws_vpc_security_group_ingress_rule" "clamav_workspaces_22_ingress_kpmg" {
  count             = local.is-preproduction ? 1 : 0
  security_group_id = aws_security_group.sftp_cluster_ec2_kpmg.id
  description       = "[KPMG] AWS Workspaces to SFTP:22"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod

  tags = merge(local.tags,
    { Name = "[KPMG] AWS Workspaces to SFTP:22" }
  )
}