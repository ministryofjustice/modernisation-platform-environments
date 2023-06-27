locals {
  test_config = {

    baseline_s3_buckets = {

      # the shared image builder bucket is just created in test
      nomis-combined-reporting-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
      nomis-combined-reporting-bip-packages = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsReadOnlyAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_acm_certificates = {
      nomis_combined_reporting_wildcard_cert = {
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
        ]
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {

      tomcat-webserver = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "base_rhel_8_5_*"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type          = "t3.large",
          vpc_security_group_ids = ["private"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        # autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing BI Platform tomcat installation and connections with official RedHat RHEL8.5 image"
          os-type     = "Linux"
          component   = "test"
        }
        lb_target_groups = {
          http-7777 = {
            port                 = 7777
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7777
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
        }
      }

      bip-application-server = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "base_rhel_8_5_*"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type          = "t3.large",
          vpc_security_group_ids = ["private"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        # autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing BIP 4.3 installation and connections with official RedHat RHEL8.5 image"
          os-type     = "Linux"
          component   = "test"
        }
        lb_target_groups = {
          http = {
            port                 = 7777
            protocol             = "HTTP"
            target_type          = "instance"
            deregistration_delay = 30
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7777
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
        }
      }
    }
    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destrroy_bucket    = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = ["private"]
        listeners = {
          http = {
            port     = 80
            protocol = "HTTP"
            default_action = {
              type = "redirect"
              redirect = {
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_301"
              }
            }
          }
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "HTTPS"
                status_code  = "200"
              }
            }
          }
        }
      }
    }
    baseline_route53_zones = {
      (module.environment.domains.public.modernisation_platform) = {
        lb_alias_records = [
          { name = "web.test.${local.application_name}", type = "A", lbs_map_key = "private" }
        ]
      }
    }
  }
}
