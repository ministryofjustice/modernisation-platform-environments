locals {

  tomcat_ssm_parameters = {
    prefix = "/tomcat/"
    parameters = {
      bobj_password     = { description = "bobj account password" }
      oracle_password   = { description = "oracle account password" }
      product_key       = { description = "BIP product key" }
      cms_password      = { description = "CMS password for host machine" }
    }
  }

  tomcat_target_group_http_7010 = {
    port                 = 7010
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 7010
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  tomcat_lb_listeners = {

    http = {
      port     = 80
      protocol = "HTTP"

      default_action = {
        type = "redirect"
        redirect = {
          port        = 443
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }

    http7777 = {
      port     = 7777
      protocol = "HTTP"

      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not implemented"
          status_code  = "501"
        }
      }
    }

    https = {
      port                      = 443
      protocol                  = "HTTPS"
      ssl_policy                = "ELBSecurityPolicy-2016-08"
      certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]
      cloudwatch_metric_alarms  = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].lb_default

      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not implemented"
          status_code  = "501"
        }
      }
    }
  }

  tomcat_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name          = "base_rhel_8_5_*"
      ssm_parameters_prefix     = "tomcat/"
      iam_resource_names_prefix = "ec2-tomcat"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private"]
    })
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    lb_target_groups = {
      http-7777 = local.tomcat_target_group_http_7010
    }

    tags = {
      description = "ncr tomcat webtier component"
      ami         = "base_rhel_8_5"
      os-type     = "Linux"
      server-type = "ncr-tomcat"
      component   = "web"
    }
  }

}