locals {
  /* worksapce specific configurations */
  enabled_workspaces        = ["test", "development"]
  environment_configuration = local.environment_configurations[local.environment]
}