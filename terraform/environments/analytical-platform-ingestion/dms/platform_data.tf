# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "shared" {
  id = "${local.vpc_id}"
  tags = {
    name = "${local.application_name}-${local.environment}-connected"
  }
}

  # subnet_ids = concat([for subnet in module.isolated_vpc.private_subnets : subnet.id], [
  #   for
  #   subnet in module.isolated_vpc.private_subnets : subnet.id
  # ])


data "aws_subnet" "shared_private_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "shared_private_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "shared_private_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}c"
  }
}

# data "dms_kms_source_cmk" "dms" {
#     provider = aws.core-network-services
#     name = "dms"
#     key_id = module.dms_kms_source_cmk.key_id
#     encryption_context = {
#     "Key" = "Value"
#   }
# }

data "aws_ec2_transit_gateway" "moj_tgw" {
  id = "tgw-026162f1ba39ce704"
}

data "aws_availability_zone" "available" {
    provider = aws.core-network-services
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
