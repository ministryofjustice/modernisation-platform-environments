locals {
  /* worksapce specific configurations */
  # enabled_workspaces        = ["test", "development", "preproduction", "production"]
  environment_configuration = local.environment_configurations[local.environment]
}