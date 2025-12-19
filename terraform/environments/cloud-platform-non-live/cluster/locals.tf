locals {
  /* worksapce specific configurations */
  enabled_workspaces        = []
  environment_configuration = local.environment_configurations[local.environment]
}