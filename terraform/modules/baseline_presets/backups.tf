locals {

  backup_plans_filter = flatten([
    var.options.enable_backup_plan_daily_and_weekly ? ["daily_except_sunday", "weekly_on_sunday"] : []
  ])

  backup_plans = {
    daily_except_sunday = {
      rule = {
        schedule          = "cron(30 23 * * MON-SAT *)"
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
          value = "daily-and-weekly"
        }]
      }
    }
    weekly_on_sunday = {
      rule = {
        schedule          = "cron(30 23 * * SUN *)"
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
          value = "daily-and-weekly"
        }]
      }
    }
  }
}
