locals {

  backup_plans = {
    daily_except_sunday = {
      rule = {
        schedule          = "cron(30 23 * * MON-SAT *)"
        start_window      = 60
        completion_window = 3600
        lifecycle = {
          delete_after = "7"
        }
        advanced_backup_setting = {
          backup_options = {
            WindowsVSS = "enabled"
          }
          resource_type = "EC2"
        }
      }
      selection = {
        selection_tags = [{
          type  = "STRINGEQUALS"
          key   = "backup-plan"
          value = "daily-weekly"
        }]
      }
    }
    weekly_on_sunday = {
      rule = {
        schedule          = "cron(30 23 * * SUN *)"
        start_window      = 60
        completion_window = 3600
        lifecycle = {
          delete_after = "28"
        }
        advanced_backup_setting = {
          backup_options = {
            WindowsVSS = "enabled"
          }
          resource_type = "EC2"
        }
      }
      selection = {
        selection_tags = [{
          type  = "STRINGEQUALS"
          key   = "backup-plan"
          value = "daily-weekly"
        }]
      }
    }
  }
}
