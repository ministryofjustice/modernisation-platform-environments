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

    baseline_ec2_autoscaling_groups = {
      # webserver = {
      #   autoscaling_group = {
      #     desired_capacity    = 1
      #     max_size            = 2
      #     vpc_zone_identifier = module.environment.subnets["private"].ids
      #   }
      #   autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name = "base_rhel_8_5_*"
      #   })
      #   ebs_volume_config = null
      #   ebs_volumes       = null
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   lb_target_groups = null
      #   ssm_parameters   = null
      #   tags = {
      #     os-type = "Linux"
      #   }
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      # }
    }

    # baseline_lbs = {
    #   rhel85-test = {
    #     enable_delete_protection = false
    #     idle_timeout             = "60"
    #     public_subnets           = module.environment.subnets["public"].ids
    #     force_destroy_bucket     = true
    #     internal_lb              = true
    #     tags                     = local.tags
    #     security_groups          = [module.baseline.security_groups["public"].id]
    #     listeners = {
    #       https = {
    #         port             = 443
    #         protocol         = "HTTPS"
    #         ssl_policy       = "ELBSecurityPolicy-2016-08"
    #         certificate_arns = [module.acm_certificate["star.${module.environment.domains.public.application_environment}"].arn]
    #         default_action = {
    #           type = "fixed-response"
    #           fixed_response = {
    #             content_type = "text/plain"
    #             message_body = "Not implemented"
    #             status_code  = "501"
    #           }
    #         }

    #         rules = {
    #           forward-http-8080 = {
    #             priority = 100
    #             actions = [{
    #               type              = "forward"
    #               target_group_name = "http-8080"
    #             }]
    #             conditions = [
    #               {
    #                 host_header = {
    #                   values = ["web.oasys.${module.environment.vpc_name}.modernisation-platform.service.justice.gov.uk"]
    #                 }
    #               },
    #               {
    #                 path_pattern = {
    #                   values = ["/"]
    #                 }
    #             }]
    #           }
    #         }
    #       }
    #       route53_records = {
    #         "web.oasys" = {
    #           account                = "core-vpc"
    #           zone_id                = module.environment.route53_zones[module.environment.domains.public.business_unit_environment].zone_id
    #           evaluate_target_health = true
    #         }
    #       }
    #     }
    #   }
    # }
  }
}
