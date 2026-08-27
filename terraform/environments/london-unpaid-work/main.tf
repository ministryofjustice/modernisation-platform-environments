# Majority of resources created by baseline module.
# See common settings in locals.tf and environment specific settings in
# locals_development.tf, locals_test.tf etc.

module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

module "environment" {
  source = "../../modules/environment"

  providers = {
    aws.modernisation-platform = aws.modernisation-platform
    aws.core-network-services  = aws.core-network-services
    aws.core-vpc               = aws.core-vpc
  }

  environment_management = local.environment_management
  business_unit          = var.networking[0].business-unit
  application_name       = local.application_name
  environment            = local.environment
  subnet_set             = local.subnet_set
}

module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment  = module.environment
  ip_addresses = module.ip_addresses

  options = merge(
    local.baseline_presets_all_environments.options,
    local.baseline_presets_environment_specific.options
  )
}

module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
    aws.us-east-1             = aws.us-east-1
  }

  environment = module.environment

  lbs = merge(
    lookup(local.baseline_all_environments, "lbs", {}),
    lookup(local.baseline_environment_specific, "lbs", {})
  )

  security_groups = merge(
    module.baseline_presets.security_groups,
    lookup(local.baseline_all_environments, "security_groups", {}),
    lookup(local.baseline_environment_specific, "security_groups", {}),
  )
}

