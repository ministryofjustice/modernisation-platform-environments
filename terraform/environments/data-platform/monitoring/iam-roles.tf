module "monitoring" {
  source = "../modules/monitoring"
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  # additional_policies = {
  # }
}
