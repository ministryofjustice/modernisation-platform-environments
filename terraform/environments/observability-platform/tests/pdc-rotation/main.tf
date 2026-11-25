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
    image_digest = string
  })
  default = null
}

variable "failure_alerts" {
  type = object({
    slack_channel_id = string
  })
  default  = { slack_channel_id = "C06ALD6LX55" }
  nullable = true
}

locals {
  environment      = var.environment
  application_name = "observability-platform"
  tags             = { application = "observability-platform" }
  gc_accounts      = var.accounts
  all_account_ids = {
    sprinkler-development      = format("%012d", 1)
    cooker-development         = format("%012d", 2)
    disabled-development       = format("%012d", 3)
    production-observability-a = format("%012d", 6)
    production-observability-b = format("%012d", 7)
    new-development            = format("%012d", 8)
  }
  environment_management = {
    account_ids = {
      core-shared-services-production = format("%012d", 5)
    }
  }
  environment_configuration_gc = {
    pdc_token_rotator  = var.rotator
    pdc_failure_alerts = var.environment == "development" ? var.failure_alerts : null
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
