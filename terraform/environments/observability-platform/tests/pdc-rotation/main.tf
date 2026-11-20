variable "accounts" {
  type = map(object({
    pdc_enabled = bool
  }))
  default = {
    sprinkler-development = { pdc_enabled = true }
    cooker-development    = { pdc_enabled = true }
    disabled-development  = { pdc_enabled = false }
  }
}

variable "environment" {
  type    = string
  default = "development"
}

variable "rotator" {
  type = object({
    image_uri                          = string
    credential_secret_arn              = string
    credential_kms_key_arn             = string
    stack_query_credential_secret_arn  = string
    stack_query_credential_kms_key_arn = string
    failure_topic_arn                  = string
  })
  default = null
}

locals {
  environment      = var.environment
  application_name = "observability-platform"
  tags             = { application = "observability-platform" }
  gc_accounts      = var.accounts
  all_account_ids = {
    sprinkler-development = format("%012d", 1)
    cooker-development    = format("%012d", 2)
    disabled-development  = format("%012d", 3)
  }
  environment_management = {
    account_ids = {
      core-shared-services-production = format("%012d", 5)
    }
  }
  environment_configuration_gc = {
    pdc_token_rotator = var.rotator
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
