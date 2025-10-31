module "fargate_graceful_retirement" {
  count                   = local.environment == "development" ? 1 : 0
  environment             = local.environment
  source                  = "../delius-core/modules/components/fargate_graceful_retirement"
  restart_time            = "22:00"
  restart_day_of_the_week = "WEDNESDAY"
  debug_logging           = true
}
