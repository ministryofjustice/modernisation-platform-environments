locals {

  ec2_autoscaling_group = {

    default = {
      desired_capacity    = 1
      max_size            = 1
      force_delete        = true
      vpc_zone_identifier = var.environment.subnets["private"].ids
    }

    default_with_ready_hook = {
      desired_capacity          = 1
      max_size                  = 1
      force_delete              = true
      vpc_zone_identifier       = var.environment.subnets["private"].ids
      wait_for_capacity_timeout = 0

      initial_lifecycle_hooks = {
        "ready-hook" = {
          default_result       = "ABANDON"
          heartbeat_timeout    = 7200
          lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
        }
      }
    }

    default_with_ready_hook_and_warm_pool = {
      desired_capacity          = 1
      max_size                  = 1
      force_delete              = true
      vpc_zone_identifier       = var.environment.subnets["private"].ids
      wait_for_capacity_timeout = 0

      initial_lifecycle_hooks = {
        "ready-hook" = {
          default_result       = "ABANDON"
          heartbeat_timeout    = 7200
          lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
        }
      }

      warm_pool = {
        reuse_on_scale_in           = true
        max_group_prepared_capacity = 1
      }
    }
  }

  ec2_autoscaling_schedules = {

    working_hours = {
      "scale_up" = {
        recurrence = "0 7 * * Mon-Fri"
      }
      "scale_down" = {
        desired_capacity = 0
        recurrence       = "0 19 * * Mon-Fri"
      }
    }
  }

}
