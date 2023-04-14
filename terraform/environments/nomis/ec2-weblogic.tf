#------------------------------------------------------------------------------
# Weblogic
#------------------------------------------------------------------------------

locals {

  lb_target_group_http_7001 = {
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

  lb_target_group_http_7777 = {
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

  lb_weblogic = {
    https = {
      port                      = 443
      protocol                  = "HTTPS"
      ssl_policy                = "ELBSecurityPolicy-2016-08"
      certificate_names_or_arns = ["nomis_wildcard_cert"]
      cloudwatch_metric_alarms  = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].lb_default
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

  # allows an over-ride on where to send alarms (which sns topic) based on environment
  lb_weblogic_listeners_sns_topic = {
    development = {}
    test = {
      sns_topic = aws_sns_topic.nomis_alarms.arn
    }
    preproduction = {}
    production    = {}
  }

  ec2_weblogic_cloudwatch_metric_alarms = {
    weblogic-node-manager-service = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      namespace           = "CWAgent"
      metric_name         = "collectd_exec_value"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "weblogic-node-manager service has stopped"
      dimensions = {
        instance = "weblogic_node_manager"
      }
    }
  }
  ec2_weblogic_cloudwatch_metric_alarms_lists = {
    weblogic = {
      parent_keys = [
        "ec2_default",
        "ec2_linux_default",
        "ec2_linux_with_collectd_default"
      ]
      alarms_list = [
        { key = "weblogic", name = "weblogic-node-manager-service" }
      ]
    }
  }

  ec2_weblogic_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
      ssm_parameters_prefix     = "weblogic/"
      iam_resource_names_prefix = "ec2-weblogic"
      instance_profile_policies = local.ec2_common_managed_policies
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default_rhel6, {
      instance_type          = "t2.large"
      vpc_security_group_ids = ["private-web"]
    })

    cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].weblogic
    user_data_cloud_init     = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = {
      desired_capacity = 1
      max_size         = 2
      vpc_zone_identifier = [
        module.environment.subnets["private"].ids
      ]
      health_check_grace_period = 300
      health_check_type         = "EC2"
      force_delete              = true
      termination_policies      = ["OldestInstance"]
      wait_for_capacity_timeout = 0

      # this hook is triggered by the post-ec2provision.sh
      initial_lifecycle_hooks = {
        "ready-hook" = {
          default_result       = "ABANDON"
          heartbeat_timeout    = 7200
          lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
        }
      }

      instance_refresh = {
        strategy               = "Rolling"
        min_healthy_percentage = 90 # seems that instances in the warm pool are included in the % health count so this needs to be set fairly high
        instance_warmup        = 300
      }

      # warm_pool = {
      #   reuse_on_scale_in           = true
      #   max_group_prepared_capacity = 1
      # }
    }

    lb_target_groups = {
      http-7777 = local.lb_target_group_http_7777
    }

    tags = {
      ami         = "nomis_rhel_6_10_weblogic_appserver_10_3"
      description = "nomis weblogic appserver 10.3"
      os-type     = "Linux"
      server-type = "nomis-web"
      component   = "web"
    }
  }
  ec2_weblogic_zone_a = merge(local.ec2_weblogic_default, {
    config = merge(local.ec2_weblogic_default.config, {
      availability_zone = "${local.region}a"
    })
    user_data_cloud_init = merge(local.ec2_weblogic_default.user_data_cloud_init, {
      args = merge(local.ec2_weblogic_default.user_data_cloud_init.args, {
        branch = "b7cf97d15687c1fe653ea139a728db642f783a2d" # 2023-04-06
      })
    })
  })
  ec2_weblogic_zone_b = merge(local.ec2_weblogic_default, {
    config = merge(local.ec2_weblogic_default.config, {
      availability_zone = "${local.region}b"
    })
  })
}
