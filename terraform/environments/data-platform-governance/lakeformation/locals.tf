locals {
  environment_configuration   = local.environment_configurations[local.environment]
  lakeformation_configuration = yamldecode(file("${path.module}/configuration/lakeformation.yml"))["environment"][local.environment]
}
