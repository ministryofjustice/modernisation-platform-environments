locals {

  bip_ssm_parameters = {
    prefix = "/bip/"
    parameters = {
      product_key        = { description = "BIP product key" }
      lcm_password       = { description = "LCM Password" }
      cms_cluster_key    = { description = "CMS Cluster Key" }
      cms_admin_password = { description = "CMS Admin Password" }
      cms_db_password    = { description = "CMS DB Password" }
    }
  }

  bip_secretsmanager_secrets = {
    secrets = {
      passwords = {}
    }
  }

  bip_target_group_http_7777 = {
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
  bip_target_group_http_6410 = {
    port                 = 6410
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 6410
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }
  bip_target_group_http_6400 = {
    port                 = 6400
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 6400
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }
  bip_target_group_http_6455 = {
    port                 = 6455
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 6455
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  bip_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status,
  )

  bip_cloudwatch_log_groups = {
    cwagent-bip-logs = {
      retention_in_days = 30
    }
  }

  bip_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "base_rhel_8_5_*"
      ssm_parameters_prefix     = "bip/"
      iam_resource_names_prefix = "ec2-bip"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private"]

      tags = {
        backup-plan = "daily-and-weekly"
      }
    })

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default
    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", size = 100 }
      "/dev/sdc" = { type = "gp3", size = 100 }
      "/dev/sds" = { type = "gp3", size = 100 }
    }

    lb_target_groups = {
      http-7777 = local.bip_target_group_http_7777
      listening = local.bip_target_group_http_6455
      sia       = local.bip_target_group_http_6410
      cms       = local.bip_target_group_http_6400
    }

    tags = {
      description = "ncr bip webtier component"
      ami         = "base_rhel_8_5"
      backup      = "false" # opt out of mod platform default backup plan
      os-type     = "Linux"
      server-type = "ncr-bip"
      component   = "web"
    }
  }

}
