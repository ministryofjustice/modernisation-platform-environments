locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      data_lake_environment = local.environment
    }
    test = {
      data_lake_environment = local.environment
    }
    preproduction = {
      data_lake_environment = local.environment
    }
    production = {
      data_lake_environment = local.environment
    }
  }

  data_platform_lakeformation_configuration = yamldecode(file("../data-platform-governance/lakeformation/configuration/lakeformation.yml"))["environment"][local.environment_configuration.data_lake_environment]["factories"]["${local.application_name}-${local.environment}"]
}
