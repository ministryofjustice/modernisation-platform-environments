locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development   = {}
    test          = {}
    preproduction = {}
    production    = {}
  }
}
