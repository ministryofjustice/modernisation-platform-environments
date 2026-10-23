resource "aws_security_group" "smtp4dev_sg_kpmg" {
  count       = local.is-preproduction ? 1 : 0
  name        = "smtp4dev_sg_kpmg"
  description = "Additional rules to allow KPMG access SMTP4DEV"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-SMTP4DEV-KPMG", local.application_name, local.environment)) }
  )

  # Detach the SG from the instances before deleting it (outside preproduction, where count is 0)
  lifecycle {
    create_before_destroy = true
  }
}

# THe following ingress is commented as part of emudhra cert exercise on 23Oct2026

# resource "aws_vpc_security_group_ingress_rule" "smtp4dev_workspaces_22_ingress_kpmg" {
#   count             = local.is-preproduction ? 1 : 0
#   security_group_id = aws_security_group.smtp4dev_sg_kpmg[0].id
#   description       = "[KPMG] AWS Workspaces to SMTP4DEV:22"
#   ip_protocol       = "tcp"
#   from_port         = 22
#   to_port           = 22
#   cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod

#   tags = merge(local.tags,
#     { Name = "[KPMG] AWS Workspaces to SMTP4DEV:22" }
#   )
# }

# Only created in preproduction, where KPMG are testing - keep the existing preproduction SG rather than recreating it
moved {
  from = aws_security_group.smtp4dev_sg_kpmg
  to   = aws_security_group.smtp4dev_sg_kpmg[0]
}
