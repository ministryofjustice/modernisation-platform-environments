resource "random_password" "datahub_rds" {
  length  = 32
  special = false
}

data "aws_eks_cluster" "apps_and_tools" {
  name = "apps-tools-${local.environment}"
}

data "aws_iam_openid_connect_provider" "apps_and_tools" {
  url = data.aws_eks_cluster.apps_and_tools.identity[0].oidc[0].issuer
}

data "aws_vpc" "dedicated" {
  tags = {
    Name = "${local.application_name}-${local.environment}"
  }
}

data "aws_subnets" "dedicated" {
  for_each = toset(["db", "private", "public"])
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dedicated.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-${each.value}-*"]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.dedicated["private"].ids)
  id       = each.value
}

data "aws_db_subnet_group" "db_subnet_group" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_iam_policy_document" "datahub" {
  statement {
    sid       = "AllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = formatlist("arn:aws:iam::%s:role/${local.environment_configuration.datahub_role}", local.environment_configuration.datahub_target_accounts)
  }
}