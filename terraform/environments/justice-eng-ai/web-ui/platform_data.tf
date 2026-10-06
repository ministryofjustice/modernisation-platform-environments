# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# VPC and subnet data
#
# justice-eng-ai has its own dedicated VPC (created in the parent
# justice-eng-ai root's vpc.tf via the terraform-aws-vpc module), not the
# generic shared core-vpc used by most other member accounts. It's tagged
# Name = "<application_name>-<environment>" (module's "name" input), with
# subnets tagged "<application_name>-<environment>-<tier>-<az>" -- so look
# it up directly rather than depending on the parent root's state/outputs,
# which would only be current once that root has actually been re-applied.
data "aws_vpc" "shared" {
  tags = {
    "Name" = "${local.application_name}-${local.environment}"
  }
}

data "aws_subnets" "shared-data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-data*"
  }
}

data "aws_subnets" "shared-private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-private*"
  }
}

data "aws_subnets" "shared-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-public*"
  }
}

data "aws_subnet" "private_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.application_name}-${local.environment}-private-${data.aws_region.current.region}a"
  }
}

data "aws_subnet" "private_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.application_name}-${local.environment}-private-${data.aws_region.current.region}b"
  }
}

data "aws_subnet" "private_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.application_name}-${local.environment}-private-${data.aws_region.current.region}c"
  }
}

# Route53 DNS data
data "aws_route53_zone" "network-services" {
  provider = aws.core-network-services

  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

# State for core-network-services resource information
data "terraform_remote_state" "core_network_services" {
  backend = "s3"
  config = {
    acl     = "bucket-owner-full-control"
    bucket  = "modernisation-platform-terraform-state"
    key     = "environments/accounts/core-network-services/core-network-services-production/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = "true"
  }
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
