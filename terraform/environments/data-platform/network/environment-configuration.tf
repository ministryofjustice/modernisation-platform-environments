locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
    }
    test = {
    }
    preproduction = {
    }
    production = {
    }
  }

  network_configuration = yamldecode(file("${path.module}/configuration/network.yml"))["environment"][local.environment]
}
