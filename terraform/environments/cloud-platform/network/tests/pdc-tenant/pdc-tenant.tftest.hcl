# Plan only: run_pdc_tenant_tests.py inspects the plan in each workspace. Nothing is ever applied.
mock_provider "aws" {
  # The AWS provider validates these values, so they must look real
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "000000000011"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-2"
    }
  }

  mock_data "aws_subnet" {
    defaults = {
      vpc_id = "vpc-0123456789abcdef0"
    }
  }
}

run "plan" {
  command = plan
}
