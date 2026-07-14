data "aws_lb_target_group" "ldap-target-group" {
  name = "ldap-training-at-389"
}

locals {
  # Restart schedules for envs, testing for dev only now
  fargate_restart_schedules = {
    training = { day = "TUESDAY", time = "22:00" }
  }

  # Debug logging control per environment
  fargate_debug_logging = {
    training = true
  }
}
module "fargate_graceful_retirement" {
  count                   = contains(keys(local.fargate_restart_schedules), "training") ? 1 : 0
  source                  = "../delius-core/modules/components/fargate_graceful_retirement"
  restart_time            = local.fargate_restart_schedules["training"].time
  restart_day_of_the_week = local.fargate_restart_schedules["training"].day
  debug_logging           = lookup(local.fargate_debug_logging, "training", false)
  environment             = "training"
  extra_environment_vars = {
    LDAP_NLB_ARN = data.aws_lb_target_group.ldap-target-group.arn
  }
}
