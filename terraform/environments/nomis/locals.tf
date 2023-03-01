locals {
  business_unit       = var.networking[0].business-unit
  region              = "eu-west-2"
  availability_zone_1 = "eu-west-2a"
  availability_zone_2 = "eu-west-2b"
  autoscaling_schedules_default = {
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = 0
      recurrence       = "0 19 * * Mon-Fri"
    }
  }
}

