# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "prototype" {
  count = local.prototype_edge_enabled ? 1 : 0

  tags = {
    Name = "${local.application_name}-${local.environment}"
  }
}

data "aws_subnets" "private_prototypes" {
  count = local.prototype_edge_enabled ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.prototype[0].id]
  }

  tags = {
    Name = "${local.application_name}-${local.environment}-private-prototypes-*"
  }
}

# Each environment's web-ui root owns its ai-builder hosted zone in the same account.
data "aws_route53_zone" "ai_builder" {
  count = local.prototype_edge_enabled ? 1 : 0

  name         = "${local.prototype_domain_name}."
  private_zone = false
}

data "aws_organizations_organization" "root_account" {}

# Retrieve information about the modernisation platform account
data "aws_caller_identity" "modernisation_platform" {
  provider = aws.modernisation-platform
}

# caller account information to instantiate aws.oidc provider
data "aws_caller_identity" "original_session" {
  provider = aws.original-session
}

data "aws_iam_session_context" "whoami" {
  provider = aws.original-session
  arn      = data.aws_caller_identity.original_session.arn
}

# Get the environments file from the main repository
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}
