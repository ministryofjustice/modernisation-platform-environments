data "aws_vpc" "main" {
  tags = {
    "Name" = "${local.application_name}-${local.environment}"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-private*"]
  }
}

data "aws_subnet" "private_subnet_details" {
  for_each = toset(data.aws_subnets.private.ids)

  id = each.value
}

data "aws_iam_roles" "platform_engineer_admin_sso_role" {
  name_regex  = "AWSReservedSSO_platform-engineer-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_subnets" "firewall" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-firewall*"]
  }
}

data "aws_subnet" "firewall_subnet_details" {
  for_each = toset(data.aws_subnets.firewall.ids)

  id = each.value
}
