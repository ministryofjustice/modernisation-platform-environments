data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_caller_identity" "original_session" {
  provider = aws.original-session
}

data "aws_ssm_parameter" "modernisation_platform_account_id" {
  provider = aws.original-session
  name     = "modernisation_platform_account_id"
}

data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}
