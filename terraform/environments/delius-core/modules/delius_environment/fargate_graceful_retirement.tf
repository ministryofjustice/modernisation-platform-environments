module "fargate_graceful_retirement" {
  count = var.environment_config.fargate_graceful_retirement.enabled ? 1 : 0
  source = "../../../../modules/fargate_graceful_retirement"
  restart_time = var.environment_config.fargate_graceful_retirement.restart_time
}
  
