# Current deployment account and region
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# Modernisation Platform account information
data "aws_caller_identity" "modernisation_platform" {
  provider = aws.modernisation-platform
}

# Original session information used by the platform providers
data "aws_caller_identity" "original_session" {
  provider = aws.original-session
}

data "aws_iam_session_context" "whoami" {
  provider = aws.original-session
  arn      = data.aws_caller_identity.original_session.arn
}

# Application tags maintained in the Modernisation Platform repository
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}
