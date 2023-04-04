# oasys-production environment settings
locals {
  production_config = {
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
      patch_approval_delay_days = 7
      patch_day                 = "THU"
    }

    baseline_bastion_linux = {
      public_key_data = local.public_key_data.keys[local.environment]
      tags            = local.tags
    }

    baseline_lbs = {
      prod-oasys-internal = {
        enable_delete_protection = false
        force_destroy_bucket     = false
        idle_timeout             = "60"
        internal_lb              = true
        security_groups          = [module.baseline.security_groups["private"].id]
        public_subnets           = module.environment.subnets["public"].ids
        existing_target_groups   = {}
        tags                     = local.tags
        listeners                = {}
      }
    }

    baseline_ec2_autoscaling_groups = {
      prod-oasys-training = {
        autoscaling_group     = module.baseline_presets.ec2_autoscaling_group
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "base_rhel_8_5_*"
        })
        ebs_volume_config = null
        ebs_volumes       = null
        instance          = module.baseline_presets.ec2_instance.instance.default
        lb_target_groups  = null
        ssm_parameters    = null
        tags = {
          os-type = "Linux"
        }
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      }
    }
  }
}
