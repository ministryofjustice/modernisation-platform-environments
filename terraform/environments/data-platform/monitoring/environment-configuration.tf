locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      monitoring_stack_enabled = true
    }
    test = {
      monitoring_stack_enabled = false
    }
    preproduction = {
      monitoring_stack_enabled = false
    }
    production = {
      monitoring_stack_enabled = true
    }
  }
}
