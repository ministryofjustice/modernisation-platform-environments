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
        enable_delete_protection = false # change to true before we actually use
        force_destroy_bucket     = false
        idle_timeout             = "60"
        internal_lb              = true
        security_groups          = ["private"]
        public_subnets           = module.environment.subnets["public"].ids
        existing_target_groups   = {}
        tags                     = local.tags
        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["application_environment_wildcard_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
            rules = {
              forward-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "prod-oasys-web-trn-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = ["trn.oasys.${module.environment.domains.public.business_unit_environment}"]
                    }
                  },
                  {
                    path_pattern = {
                      values = ["/"]
                    }
                }]
              }
            }
          }
        }
      }
    }

    baseline_route53_zones = {
      "${module.environment.domains.public.business_unit_environment}" = {
        lb_alias_records = [
          { name = "trn.oasys", type = "A", lbs_map_key = "prod-oasys-internal" },
        ]
      }
    }

    baseline_ec2_autoscaling_groups = {
      prod-oasys-web-trn = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "oasys_webserver_release_*"
        })
        instance              = module.baseline_presets.ec2_instance.instance.default
        user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        ebs_volume_config     = null
        ebs_volumes           = null
        autoscaling_group     = module.baseline_presets.ec2_autoscaling_group
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        ssm_parameters        = null
        lb_target_groups = {
          http-8080 = {
            port                 = 8080
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 8080
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
        }
        cloudwatch_metric_alarms = {}
        tags = {
          component         = "web"
          os-type           = "Linux"
          os-major-version  = 7
          os-version        = "RHEL 7.9"
          "Patch Group"     = "RHEL"
          server-type       = "oasys-web-training"
          description       = "${local.environment} OASys web training"
          monitored         = true
          oasys-environment = local.environment
          environment-name  = terraform.workspace
        }
      }
    }
  }
}
