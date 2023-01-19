# oasys-development environment specific settings
locals {
  oasys_development = {

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_days = 90
      }
    }

    external_remote_access_cidrs = [
      local.cidrs.noms_test,
      local.cidrs.noms_mgmt,
      local.cidrs.noms_test_dr,
      local.cidrs.noms_mgmt_dr,
    ]

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    autoscaling_groups = {
      webserver = merge(local.webserver, { # merge common config and env specific
        tags = {
          nomis-environment = "t1"
          description       = "oasys webserver"
          component         = "web"
          server-type       = "webserver"
        }
      })
    }
    db_enabled                             = false
    db_auto_minor_version_upgrade          = "true"
    db_allow_major_version_upgrade         = "false"
    db_backup_window                       = "03:00-06:00"
    db_retention_period                    = "15"
    db_maintenance_window                  = "mon:00:00-mon:03:00"
    db_instance_class                      = "db.t3.small"
    db_user                                = "eor"
    db_allocated_storage                   = "500"
    db_max_allocated_storage               = "0"
    db_multi_az                            = "false"
    db_iam_database_authentication_enabled = "false"
    db_monitoring_interval                 = "0"
    db_enabled_cloudwatch_logs_exports     = ["audit", "audit", "listener", "trace"]
    db_performance_insights_enabled        = "false"
    db_skip_final_snapshot                 = "true"
  }
}