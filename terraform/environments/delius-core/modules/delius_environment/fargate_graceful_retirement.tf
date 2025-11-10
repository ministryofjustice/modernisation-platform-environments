data "aws_lb_target_group" "ldap-target-group" {
  name = "ldap-${var.env_name}-at-389"
}

locals {
  # Restart schedules for envs, testing for dev only now
  fargate_restart_schedules = {
    dev  = { day = "TUESDAY", time = "22:00" }
    poc  = { day = "MONDAY", time = "20:00" }
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
  count                   = contains(keys(local.fargate_restart_schedules), var.env_name) ? 1 : 0
  source                  = "../components/fargate_graceful_retirement"
  restart_time            = local.fargate_restart_schedules[var.env_name].time
  restart_day_of_the_week = local.fargate_restart_schedules[var.env_name].day
  debug_logging           = lookup(local.fargate_debug_logging, var.env_name, false)
  environment             = var.env_name
  extra_environment_vars = {
    LDAP_NLB_ARN = data.aws_lb_target_group.ldap-target-group.arn
  }
}
