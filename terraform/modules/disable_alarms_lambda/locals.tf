locals {
  weekday_schedule = {
    "disable_alarms_weekday" = {
      name        = "disable-alarms-weekday"
      description = "Disable alarms on weekdays"
      schedule    = "cron(${split(":", var.start_time)[1]} ${split(":", var.start_time)[0]} ? * MON-FRI *)"
      action      = "disable"
    },
    "enable_alarms_weekday" = {
      name        = "enable-alarms-weekday"
      description = "Enable alarms on weekdays"
      schedule    = "cron(${split(":", var.end_time)[1]} ${split(":", var.end_time)[0]} ? * MON-FRI *)"
      action      = "enable"
    }
  }

  weekend_schedule = var.disable_weekend ? {
    "disable_alarms_weekend" = {
      name        = "disable-alarms-weekend"
      description = "Disable alarms on weekends"
      schedule    = "cron(${split(":", var.start_time)[1]} ${split(":", var.start_time)[0]} ? * FRI *)"
      action      = "disable"
    },
    "enable_alarms_monday" = {
      name        = "enable-alarms-monday"
      description = "Enable alarms on Monday"
      schedule    = "cron(${split(":", var.end_time)[1]} ${split(":", var.end_time)[0]} ? * MON *)"
      action      = "enable"
    }
  } : {}

  schedule_rules = merge(local.weekday_schedule, local.weekend_schedule)
}
