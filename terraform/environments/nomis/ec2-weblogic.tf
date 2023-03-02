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
      public-http-7001   = local.lb_target_group_http_7001
      public-http-7777   = local.lb_target_group_http_7777
      internal-http-7001 = local.lb_target_group_http_7001
      internal-http-7777 = local.lb_target_group_http_7777
    }
    cloudwatch_metric_alarms_weblogic = {
      weblogic-node-manager-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "weblogic-node-manager service has stopped"
        alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
        dimensions = {
          instance = "weblogic_node_manager"
        }
      }
    }
  }
}

module "ec2_weblogic_autoscaling_group" {
  source = "../../modules/ec2_autoscaling_group"

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
  cloudwatch_metric_alarms = {
    for key, value in merge(local.ec2_weblogic.cloudwatch_metric_alarms_weblogic, local.cloudwatch_metric_alarms_linux) :
    key => merge(value, {
      alarm_actions = [lookup(each.value, "sns_topic", aws_sns_topic.nomis_nonprod_alarms.arn)]
  }) }
}
