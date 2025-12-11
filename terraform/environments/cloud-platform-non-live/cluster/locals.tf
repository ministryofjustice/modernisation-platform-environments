locals {
  /* worksapce specific configurations */
  enabled_workspaces        = ["development"]
  environment_configuration = local.environment_configurations[local.environment]
}