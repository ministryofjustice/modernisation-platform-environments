resource "aws_security_group" "ec2_sg_gh_runner_kpmg" {
  count       = local.is-preproduction ? 1 : 0
  name        = "github_runner_sg_kpmg"
  description = "Additional rules to allow KPMG access GitHub Runner"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("github-runner-%s-sg-KPMG", local.environment)) }
  )

  # Detach the SG from the instances before deleting it (outside preproduction, where count is 0)
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "gh_runner_workspaces_22_ingress_kpmg" {
  count             = local.is-preproduction ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_gh_runner_kpmg[0].id
  description       = "[KPMG] AWS Workspaces to GitHubRunner:22"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod

  tags = merge(local.tags,
    { Name = "[KPMG] AWS Workspaces to GitHubRunner:22" }
  )
}
