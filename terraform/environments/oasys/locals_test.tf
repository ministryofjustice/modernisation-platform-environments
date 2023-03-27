# oasys-test environment settings
locals {
  test_config = {
    # db_enabled                             = true
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
    # db_monitoring_interval                 = "5"
    # db_enabled_cloudwatch_logs_exports     = ["audit", "audit", "listener", "trace"]
    # db_performance_insights_enabled        = false
    # db_skip_final_snapshot                 = true


    log_groups = {}

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    # ec2_autoscaling_groups = {
    #   webserver = {
    #     config = ""
    #     instance = ""
    #     user_data_cloud_init = ""
    #     ebs_volume_config = ""
    #     ebs_volumes = ""
    #     autoscaling_group = ""
    #     autoscaling_schedules = ""
    #     ssm_parameters = ""
    #     lb_target_groups = ""
    #     tags = ""
    #   }
    # }

    baseline_ec2_instances = {
      # Example instance using RedHat image with ansible provisioning
      # test-redhat-rhel79-1 = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name  = "RHEL-7.9_HVM-*"
      #     ami_owner = "309956199498"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   tags = {
      #     description = "For testing with official RedHat RHEL7.9 image"
      #     os-type     = "Linux"
      #     component   = "test"
      #     server-type = "oasys-db"
      #     monitored   = false
      #   }
      # }
    }

    baseline_bastion_linux = {
      public_key_data = local.public_key_data.keys[local.environment]
      tags            = local.tags
    }
  }
}
