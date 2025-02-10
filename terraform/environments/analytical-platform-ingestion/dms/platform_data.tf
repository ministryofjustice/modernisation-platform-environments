# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_kms_secret" "dms" {
    provider = aws.core-network-services
    secret_arn = var.dms_kms_secret_arn
    encryption_context = {
    "Key" = "Value"
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.shared.id

  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
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
