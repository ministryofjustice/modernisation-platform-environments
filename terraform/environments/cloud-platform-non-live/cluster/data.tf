data "aws_vpc" "selected" {

  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}"]
  }
}

data "aws_subnets" "eks_private" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["cloud-platform-non-live-*-private-*"]
  }
}

data "aws_subnets" "eks_public" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["cloud-platform-non-live-*-public-*"]
  }
}

data "aws_iam_roles" "platform_engineer_admin_sso_role" {
  name_regex  = "AWSReservedSSO_platform-engineer-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}