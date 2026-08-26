locals {
  daily_schedule = {
    "disable_alarms_daily" = {
      name        = "disable-alarms-daily"
      description = "Disable alarms daily"
      schedule    = "cron(${split(":", var.start_time)[1]} ${split(":", var.start_time)[0]} ? * * *)"
      action      = "disable"
    },
    "enable_alarms_daily" = {
      name        = "enable-alarms-daily"
      description = "Enable alarms daily"
      schedule    = "cron(${split(":", var.end_time)[1]} ${split(":", var.end_time)[0]} ? * * *)"
      action      = "enable"
    }
  }

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

  weekend_schedule = {
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
  }

  schedule_rules = var.disable_weekend ? merge(local.weekday_schedule, local.weekend_schedule) : local.daily_schedule
}
