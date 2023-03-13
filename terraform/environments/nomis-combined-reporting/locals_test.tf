locals {
  test_config = {

    baseline_ec2_autoscaling_groups = {

      test-base-rhel85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "base_rhel_8_5_*"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing with official RedHat RHEL8.5 image"
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
