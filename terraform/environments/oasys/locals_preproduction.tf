# oasys-preproduction environment settings
locals {
  preproduction_config = {
    # db_enabled                             = false
    # db_auto_minor_version_upgrade          = true
    # db_allow_major_version_upgrade         = false
    # db_backup_window                       = "03:00-06:00"
    # db_retention_period                    = "15"
    # db_maintenance_window                  = "mon:00:00-mon:03:00"
    # db_instance_class                      = "db.t3.small"
    # db_user                                = "eor"
    # db_allocated_storage                   = "500"
    # db_max_allocated_storage               = "0"
    # db_multi_az                            = false
    # db_iam_database_authentication_enabled = false
    # db_monitoring_interval                 = "0"
    # db_enabled_cloudwatch_logs_exports     = ["audit", "audit", "listener", "trace"]
    # db_performance_insights_enabled        = false
    # db_skip_final_snapshot                 = true

    log_groups = {}


    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_ec2_instances = {
      # Example instance using RedHat image with ansible provisioning

    }

    baseline_bastion_linux = {
      public_key_data = local.public_key_data.keys[local.environment]
      tags            = local.tags
    }
  }
}

