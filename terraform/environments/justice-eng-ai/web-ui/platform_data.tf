# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# VPC and subnet data
#
# justice-eng-ai has its own dedicated VPC (created in the parent
# justice-eng-ai root's vpc.tf), not the generic shared core-vpc used by
# most other member accounts, so there's no tagged "shared" VPC to look up
# here. Read it from the parent root's state instead, same pattern as
# backend-processing/data.tf.
data "terraform_remote_state" "justice_eng_ai" {
  backend   = "s3"
  workspace = terraform.workspace

  config = {
    bucket               = "modernisation-platform-terraform-state"
    key                  = "terraform.tfstate"
    region               = "eu-west-2"
    workspace_key_prefix = "environments/members/justice-eng-ai"
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
