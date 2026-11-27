variable "environment" {
  type = string
}

locals {
  environment = var.environment
}

# The runner copies the real environment configuration and its normalisation module here.
output "pdc_accounts" {
  value = { for name, account in local.gc_accounts : name => { pdc_enabled = account.pdc_enabled } }
}

output "rotator" {
  value = local.environment_configuration_gc.pdc_token_rotator
}

output "failure_alerts" {
  value = local.environment_configuration_gc.pdc_failure_alerts
}
