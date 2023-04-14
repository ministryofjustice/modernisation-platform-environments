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

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_s3_buckets = {
    }

    baseline_ec2_autoscaling_groups = {
      test-oasys-web = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "oasys_webserver_release_*"
        })
        instance                 = module.baseline_presets.ec2_instance.instance.default
        user_data_cloud_init     = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        ebs_volume_config        = null
        ebs_volumes              = null
        autoscaling_group        = module.baseline_presets.ec2_autoscaling_group
        autoscaling_schedules    = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        ssm_parameters           = null
        lb_target_groups         = {}
        cloudwatch_metric_alarms = {}
        tags = {
          os-type = "Linux"
        }
      }

      t2-oasys-web = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "base_rhel_8_5_*"
          ssm_parameters_prefix     = "ec2-web-t2/"
          iam_resource_names_prefix = "ec2-web-t2"
          # instance_profile_policies = local.ec2_common_managed_policies # need to check the preset policies are enough
        })

        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          monitoring             = true
          #instance_type          = "t3.medium"
        })

        cloudwatch_metric_alarms = {}

        user_data_cloud_init     = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
            branch = "ccfe2d0becae50d1ff706442b52a6c9fe01d5a7c" # 2023-04-12
          })
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours

        autoscaling_group = module.baseline_presets.ec2_autoscaling_group

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
        tags = {
          component         = "web"
          os-type           = "Linux"
          os-major-version  = 7
          os-version        = "RHEL 7.9"
          "Patch Group"     = "RHEL"
          server-type       = "oasys-web"
          description       = "t2 OASys web"
          monitored         = true
          oasys-environment = "t2"
          environment-name  = terraform.workspace
          oracle-db-hostname = "T2ODL0009"
          oracle-db-name     = "OASPROD"
        }
      } 
    }

    baseline_lbs = {
      # AWS doesn't let us call it internal
      t2-oasys-internal = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is deafult
        security_groups          = [module.baseline.security_groups["public"].id]
        public_subnets           = module.environment.subnets["public"].ids
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
                  target_group_name = "prod-oasys-training-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = ["training.oasys.${module.environment.vpc_name}.modernisation-platform.service.justice.gov.uk"]
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
      "${module.environment.domains.public.business_unit_environment}" = {  # "hmpps-test.modernisation-platform.service.justice.gov.uk"
        records = [
          { name = "t2.oasys.db", type = "A", ttl = "300", records = ["10.101.36.132"] }, # "t2.oasys.db.hmpps-test.modernisation-platform.service.justice.gov.uk" currently pointing to azure db
        ]
        lb_alias_records = [
          { name = "t2.oasys", type = "A", lbs_map_key = "t2-oasys-internal" }, # "t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"
        ]
      }
    }
  }
}
