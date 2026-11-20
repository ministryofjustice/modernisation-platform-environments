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

variable "rotator" {
  type = object({
    image_uri              = string
    credential_secret_arn  = string
    credential_kms_key_arn = string
    failure_topic_arn      = string
  })
  default = null
}

locals {
  environment      = "development"
  application_name = "observability-platform"
  tags             = {}
  gc_accounts      = var.accounts
  all_account_ids = {
    sprinkler-development = "111111111111"
    cooker-development    = "222222222222"
    disabled-development  = "333333333333"
  }
  environment_configuration_gc = {
    pdc_token_rotator = var.rotator
  }
}

provider "grafana" {
  alias = "cloud"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
