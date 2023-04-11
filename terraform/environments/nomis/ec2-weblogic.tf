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
    route53 = {
      route53_records = {
        "$(name).nomis" = {
          zone_name = module.environment.domains.public.business_unit_environment
        }
        "$(name)" = {
          zone_name = "${local.environment}.nomis.az.justice.gov.uk"
        }
      }
    }

    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          status_code = "HTTP_301"
          port        = 443
          protocol    = "HTTPS"
        }
      }
    }
    http-7001 = {
      port     = 7001
      protocol = "HTTP"
      default_action = {
        type              = "forward"
        target_group_name = "$(name)-http-7001"
      }
    }
    http-7777 = {
      port     = 7777
      protocol = "HTTP"
      default_action = {
        type              = "forward"
        target_group_name = "$(name)-http-7777"
      }
    }
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
      rules = {
        forward-http-7777 = {
          priority = 200
          actions = [{
            type              = "forward"
            target_group_name = "$(name)-http-7777"
          }]
          conditions = [{
            host_header = {
              values = [
                "$(name).nomis.${module.environment.domains.public.business_unit_environment}",
                "$(name).${local.environment}.nomis.az.justice.gov.uk"
              ]
            }
          }]
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

  ec2_weblogic_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
      ssm_parameters_prefix     = "weblogic/"
      iam_resource_names_prefix = "ec2-weblogic"
      instance_profile_policies = local.ec2_common_managed_policies
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default_rhel6, {
      instance_type          = "t2.large"
      vpc_security_group_ids = [aws_security_group.private.id]
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

  ec2_weblogic = {

    # server-type and nomis-environment auto set by module
    tags = {
      description = "nomis weblogic appserver 10.3"
      os-type     = "Linux"
      component   = "web"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "t2.large"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = true
      metadata_options_http_tokens = "optional"
      vpc_security_group_ids       = [aws_security_group.private.id]
    }

    user_data_cloud_init = {
      args = {
        lifecycle_hook_name  = "ready-hook"
        branch               = "main"
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
        ansible_args         = "--tags ec2provision"
      }
      scripts = [
        "ansible-ec2provision.sh.tftpl",
        "post-ec2provision.sh.tftpl"
      ]
    }

    autoscaling_group = {
      desired_capacity = 1
      max_size         = 2
      min_size         = 0

      health_check_grace_period = 300
      # health_check_type         = "ELB"
      health_check_type         = "EC2" # using EC2 for now while we test, otherwise server is killed if weblogic stopped
      force_delete              = true
      termination_policies      = ["OldestInstance"]
      target_group_arns         = []
      vpc_zone_identifier       = module.environment.subnets["private"].ids
      wait_for_capacity_timeout = 0

      # this hook is triggered by the post-ec2provision.sh
      initial_lifecycle_hooks = {
        "ready-hook" = {
          default_result       = "ABANDON"
          heartbeat_timeout    = 7200 # on a good day it takes 30 mins, but can be much longer
          lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
        }
      }
      warm_pool = {
        reuse_on_scale_in           = true
        max_group_prepared_capacity = 1
      }

      instance_refresh = {
        strategy               = "Rolling"
        min_healthy_percentage = 90 # seems that instances in the warm pool are included in the % health count so this needs to be set fairly high
        instance_warmup        = 300
      }
    }

    lb_target_groups = {
      http-7001 = local.lb_target_group_http_7001
      http-7777 = local.lb_target_group_http_7777
    }

    cloudwatch_metric_alarms = {
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
    cloudwatch_metric_alarms_lists = {
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
  }
}

module "ec2_weblogic_autoscaling_group" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-autoscaling-group?ref=v1.1.0"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.weblogic_autoscaling_groups, {})

  name = each.key

  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.ec2_weblogic.instance, lookup(each.value, "instance", {}))
  user_data_cloud_init          = merge(local.ec2_weblogic.user_data_cloud_init, lookup(each.value, "user_data_cloud_init", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = "weblogic/"
  ssm_parameters                = {}
  autoscaling_group             = merge(local.ec2_weblogic.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_schedules         = lookup(each.value, "autoscaling_schedules", local.autoscaling_schedules_default)
  lb_target_groups              = merge(local.ec2_weblogic.lb_target_groups, lookup(each.value, "lb_target_groups", {}))
  vpc_id                        = module.environment.vpc.id

  iam_resource_names_prefix = "ec2-weblogic-asg"
  instance_profile_policies = local.ec2_common_managed_policies

  application_name   = local.application_name
  region             = local.region
  subnet_ids         = module.environment.subnets["private"].ids
  tags               = merge(local.tags, local.ec2_weblogic.tags, try(each.value.tags, {}))
  account_ids_lookup = local.environment_management.account_ids

  cloudwatch_metric_alarms = merge(module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].weblogic,
    lookup(each.value, "cloudwatch_metric_alarms", {})
  )
}
