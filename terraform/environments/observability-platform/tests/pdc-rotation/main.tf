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

variable "use_environment_configuration" {
  type    = bool
  default = false
}

module "checked_in_configuration" {
  source = "./configuration"

  environment = var.environment
}

variable "rotator" {
  type = object({
    image_digest      = string
    bootstrap_enabled = optional(bool, false)
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
  gc_accounts      = var.use_environment_configuration ? module.checked_in_configuration.pdc_accounts : var.accounts
  all_account_ids = {
    sprinkler-development              = format("%012d", 1)
    cooker-development                 = format("%012d", 2)
    disabled-development               = format("%012d", 3)
    observability-platform-development = format("%012d", 4)
    production-observability-a         = format("%012d", 6)
    production-observability-b         = format("%012d", 7)
    new-development                    = format("%012d", 8)
    example-development                = format("%012d", 9)
    cloud-platform-development         = format("%012d", 10)
    # The Cloud Platform and Container Platform accounts configured for production.
    cloud-platform-preproduction     = format("%012d", 20)
    cloud-platform-nonlive           = format("%012d", 21)
    cloud-platform-live              = format("%012d", 22)
    container-platform-octo-nonlive  = format("%012d", 23)
    container-platform-octo-live     = format("%012d", 24)
    container-platform-laa-nonlive   = format("%012d", 25)
    container-platform-laa-live      = format("%012d", 26)
    container-platform-hmpps-nonlive = format("%012d", 27)
    container-platform-hmpps-live    = format("%012d", 28)
    container-platform-cd-nonlive    = format("%012d", 29)
    container-platform-cd-live       = format("%012d", 30)
  }
  environment_management = {
    account_ids = {
      core-shared-services-production = format("%012d", 5)
    }
  }
  environment_configuration_gc = {
    pdc_token_rotator  = var.use_environment_configuration ? module.checked_in_configuration.rotator : var.rotator
    pdc_failure_alerts = var.use_environment_configuration ? module.checked_in_configuration.failure_alerts : var.failure_alerts
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "marker_id" {
  value = try(terraform_data.gc_pdc_bootstrap["new-development"].id, null)
}
