# Run with the Terraform version being checked:
#   terraform init -backend=false && TF_WORKSPACE=cloud-platform-development terraform test
# Providers are mocked to keep plan-time validation independent of AWS.

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
    }
  }
}
mock_provider "aws" { alias = "original-session" }
mock_provider "aws" { alias = "modernisation-platform" }
mock_provider "aws" { alias = "core-vpc" }
mock_provider "aws" { alias = "us-east-1" }
mock_provider "aws" { alias = "sso-readonly" }
mock_provider "aws" { alias = "shared-configuration-access" }
mock_provider "dns" {}
mock_provider "external" {}
mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = "{\"tags\":{}}"
    }
  }
}

override_data {
  target = data.terraform_remote_state.core_network_services
  values = {
    outputs = {}
  }
}

override_data {
  target = data.aws_secretsmanager_secret_version.environment_management
  values = {
    secret_string = "{\"account_ids\":{\"cloud-platform-development\":\"111111111111\",\"cloud-platform-nonlive\":\"222222222222\",\"cloud-platform-live\":\"333333333333\",\"core-network-services-production\":\"444444444444\",\"core-shared-services-production\":\"555555555555\"},\"aws_organizations_root_account_id\":\"666666666666\"}"
  }
}

override_data {
  target = data.aws_ssm_parameter.modernisation_platform_account_id
  values = {
    value = "777777777777"
  }
}

override_data {
  target = data.aws_caller_identity.original_session
  values = {
    account_id = "888888888888"
    arn        = "arn:aws:sts::888888888888:assumed-role/AdministratorAccess/test"
  }
}

override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "888888888888"
    arn        = "arn:aws:sts::888888888888:assumed-role/AdministratorAccess/test"
  }
}

override_data {
  target = data.aws_caller_identity.modernisation_platform
  values = {
    account_id = "777777777777"
    arn        = "arn:aws:sts::777777777777:assumed-role/modernisation-account-limited-read-member-access/test"
  }
}

override_data {
  target = data.aws_iam_session_context.whoami
  values = {
    issuer_arn = "arn:aws:iam::888888888888:role/AdministratorAccess"
  }
}

override_data {
  target = data.aws_availability_zones.available
  values = {
    names = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  }
}

run "configuration_plans" {
  command = plan

  assert {
    condition     = local.cp_vpc_name == "cloud-platform-development"
    error_message = "The development workspace should select the development VPC."
  }

  assert {
    condition     = local.vpc_cidr[local.cp_vpc_name].primary == "10.195.32.0/20"
    error_message = "The development VPC should retain its configured primary CIDR."
  }
}
