locals {

  weblogic_ssm_parameters = {
    prefix = "/weblogic/"
    parameters = {
      admin_username     = {}
      admin_password     = {}
      db_username        = {}
      db_password        = {}
      db_tagsar_username = {}
      db_tagsar_password = {}
      rms_hosts          = {}
      rms_key            = {}
    }
  }

  weblogic_target_group_http_7001 = {
    port                 = 7001
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 7001
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  weblogic_target_group_http_7777 = {
    port                 = 7777
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/keepalive.htm"
      port                = 7777
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  weblogic_lb_listeners = {

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
      certificate_names_or_arns = ["nomis_wildcard_cert"]
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

  weblogic_cloudwatch_metric_alarms = {
    weblogic-asg-collectd-services = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      namespace           = "CWAgent"
      metric_name         = "collectd_exec_value"
      period              = "60"
      statistic           = "Maximum"
      threshold           = "1"
      alarm_description   = "A weblogic service or metric that's being supplied by collectd has stopped"
    }
  }

  weblogic_cloudwatch_metric_alarms_lists = {
    weblogic = {
      parent_keys = [
        "ec2_default",
        "ec2_linux_default"
      ]
      alarms_list = [
        { key = "weblogic", name = "weblogic-asg-collectd-services" }
      ]
    }
  }

  weblogic_cloudwatch_log_groups = {
    cwagent-weblogic-logs = {
      retention_in_days = 30
    }
  }

  weblogic_ec2_default = {

    cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].weblogic

    # Note: use any availability zone since DB latency does not appear to be an issue
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
      availability_zone         = null
      ssm_parameters_prefix     = "weblogic/"
      iam_resource_names_prefix = "ec2-weblogic"
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default_rhel6, {
      instance_type          = "t2.large"
      vpc_security_group_ids = ["private-web"]
    })

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
    autoscaling_group    = module.baseline_presets.ec2_autoscaling_group.default_with_ready_hook_and_warm_pool

    lb_target_groups = {
      http-7777 = local.weblogic_target_group_http_7777
    }

    tags = {
      ami         = "nomis_rhel_6_10_weblogic_appserver_10_3"
      description = "nomis weblogic appserver 10.3"
      os-type     = "Linux"
      server-type = "nomis-web"
      component   = "web"
    }
  }

  # blue/green deployment
  # - set cloudwatch_metric_alarms = {} on the dormant deployment
  # - set desired_capacity = 0 on the dormant deployment unless testing
  # - use user_data_cloud_init.args.branch to set the ansible code for given deployment
  # - use load balancer rules defined in the environment specific locals file to switch between deployments

  # blue deployment
  weblogic_ec2_a = merge(local.weblogic_ec2_default, {
    config = merge(local.weblogic_ec2_default.config, {
    })
    user_data_cloud_init = merge(local.weblogic_ec2_default.user_data_cloud_init, {
      args = merge(local.weblogic_ec2_default.user_data_cloud_init.args, {
        branch = "b13cad848c48c9b7e4b99a253f40b6602206a9d8" # 2023-06-12 update DSOS-1934
      })
    })
    autoscaling_group = merge(local.weblogic_ec2_default.autoscaling_group, {})
    # autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
    #  desired_capacity = 0
    # })
    # cloudwatch_metric_alarms = {}
    tags = merge(local.weblogic_ec2_default.tags, {
      deployment = "blue"
    })
  })

  # green deployment
  weblogic_ec2_b = merge(local.weblogic_ec2_default, {
    config = merge(local.weblogic_ec2_default.config, {
      availability_zone = "${local.region}a" # NOTE: remove this permanently when next disabling -b instances
    })
    user_data_cloud_init = merge(local.weblogic_ec2_default.user_data_cloud_init, {
      args = merge(local.weblogic_ec2_default.user_data_cloud_init.args, {
        branch = "f8ece8fc507d42c638878ede0f9030455669bb74" # 2023-04-27 reporting fix
      })
    })
    # autoscaling_group = merge(local.module.baseline_presets.ec2_autoscaling_group.default, {
    #   desired_capacity = 0
    # })
    cloudwatch_metric_alarms = {}
    tags = merge(local.weblogic_ec2_default.tags, {
      deployment = "green"
    })
  })
}
