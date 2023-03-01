#### This file can be used to store locals specific to the member account ####

locals {
  business_unit = var.networking[0].business-unit

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  environment_config = local.environment_configs[local.environment]
}
