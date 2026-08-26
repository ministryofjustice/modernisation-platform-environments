locals {

  backup_plans_filter = flatten([
    var.options.enable_backup_plan_daily_and_weekly ? ["daily_except_sunday", "weekly_on_sunday", "daily_except_sunday_vss", "weekly_on_sunday_vss"] : []
  ])

  backup_plans = {

    # Cron Format: Minutes Hours Day-of-month Month Day-of-week Year
    # Note: You cannot use * in both the Day-of-month and Day-of-week fields. If you use it in one, you must use ? in the other.

    daily_except_sunday = {
      rule = {
        schedule          = "cron(30 23 ? * MON-SAT *)"
        start_window      = 60
        completion_window = 3600
        delete_after      = lookup(var.options, "backup_plan_daily_delete_after", 7)
      }
      selection = {
        selection_tags = [{
          type  = "STRINGEQUALS"
          key   = "backup-plan"
          value = "daily-and-weekly"
        }]
      }
    }
    daily_except_sunday_vss = {
      rule = {
        schedule          = "cron(30 23 ? * MON-SAT *)"
        start_window      = 60
        completion_window = 3600
        delete_after      = lookup(var.options, "backup_plan_daily_delete_after", 7)
      }
      advanced_backup_setting = {
        backup_options = {
          WindowsVSS = "enabled"
        }
        resource_type = "EC2"
      }
      selection = {
        selection_tags = [{
          type  = "STRINGEQUALS"
          key   = "backup-plan"
          value = "daily-and-weekly-vss"
        }]
      }
    }
    weekly_on_sunday = {
      rule = {
        schedule          = "cron(30 23 ? * SUN *)"
        start_window      = 60
        completion_window = 3600
        delete_after      = lookup(var.options, "backup_plan_weekly_delete_after", 28)
      }
      selection = {
        selection_tags = [{
          type  = "STRINGEQUALS"
          key   = "backup-plan"
          value = "daily-and-weekly"
        }]
      }
    }
    weekly_on_sunday_vss = {
      rule = {
        schedule          = "cron(30 23 ? * SUN *)"
        start_window      = 60
        completion_window = 3600
        delete_after      = lookup(var.options, "backup_plan_weekly_delete_after", 28)
      }
      advanced_backup_setting = {
        backup_options = {
          WindowsVSS = "enabled"
        }
        resource_type = "EC2"
      }
      selection = {
        selection_tags = [{
          type  = "STRINGEQUALS"
          key   = "backup-plan"
          value = "daily-and-weekly-vss"
        }]
      }
    }
  }
}
