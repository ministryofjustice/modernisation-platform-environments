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
      test-oasys-web = local.webserver

      t2-oasys-web = merge(local.webserver, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-t2/"
          iam_resource_names_prefix = "ec2-web-t2"
        })
        tags = merge(local.webserver.tags, {
          description        = "t2 OASys web"
          oasys-environment  = "t2"
          oracle-db-hostname = "T2ODL0009"
        })
      })
    }

    baseline_lbs = {
      t2-oasys-internal = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is deafult
        security_groups          = ["public"]
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
                  target_group_name = "t2-oasys-web-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = ["t2.oasys.${module.environment.domains.public.business_unit_environment}"]
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
