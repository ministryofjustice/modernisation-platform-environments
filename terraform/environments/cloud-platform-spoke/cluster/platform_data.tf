# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "network-services" {
  provider = aws.core-network-services

  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_organizations_organization" "root_account" {}

data "aws_caller_identity" "modernisation_platform" {
  provider = aws.modernisation-platform
}

data "aws_caller_identity" "original_session" {
  provider = aws.original-session
}

data "aws_iam_session_context" "whoami" {
  provider = aws.original-session
  arn      = data.aws_caller_identity.original_session.arn
}

data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}
