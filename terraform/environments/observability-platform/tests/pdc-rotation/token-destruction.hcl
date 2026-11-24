mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "@MOCK_PLATFORM_ACCOUNT@" }
  }
  mock_data "aws_region" {
    defaults = { name = "eu-west-2" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  mock_resource "aws_secretsmanager_secret" {
    defaults = { arn = "arn:aws:secretsmanager:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:secret:grafana-cloud/pdc/mock-ABCDEF" }
  }
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:key/12345678-1234-1234-1234-abcdefabcdef" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:grafana-pdc-rotation-failures-development" }
  }
}

mock_provider "grafana" {
  alias = "cloud"
}

run "bootstrap_tokens" {
  command = apply
}

run "unsafe_account_disablement" {
  command = plan

  variables {
    accounts = {
      sprinkler-development = { pdc_enabled = false }
      cooker-development    = { pdc_enabled = false }
    }
  }
}
