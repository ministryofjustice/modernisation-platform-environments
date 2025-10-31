locals {
  # Restart schedules for envs, testing for dev only now
  fargate_restart_schedules = {
    dev  = { day = "FRIDAY", time = "11:35" }
    poc  = { day = "MONDAY", time = "12:05" }
    test = { day = "TUESDAY", time = "22:00" }
  }

  # Debug logging control per environment
  fargate_debug_logging = {
    dev  = true
    poc  = true
    test = true
  }
}
module "fargate_graceful_retirement" {
  # count                   = local.environment == "development" ? 1 : 0
  count                   = contains(keys(local.fargate_restart_schedules), var.env_name) ? 1 : 0
  source                  = "../../../../modules/fargate_graceful_retirement"
  restart_time            = local.fargate_restart_schedules[var.env_name].time
  restart_day_of_the_week = local.fargate_restart_schedules[var.env_name].day
  debug_logging           = lookup(local.fargate_debug_logging, var.env_name, false)
  environment             = var.env_name
}
