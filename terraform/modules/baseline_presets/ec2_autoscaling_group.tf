locals {

  ec2_autoscaling_group = {
    desired_capacity    = 1
    max_size            = 2
    vpc_zone_identifier = module.environment.subnets["private"].ids
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
