locals {

  bip_ssm_parameters = {
    prefix = "/bi-platform/"
    parameters = {
      bobj_account_password   = { description = "bobj account password" }
      oracle_account_password = { description = "oracle account password" }
      product_key             = { description = "BIP product key" }
      oracle_cms_tnsname      = { description = "Oracle TNS name for CMS repository" }
      oracle_cms_username     = { description = "Oracle username for CMS repository" }
      oracle_cms_password     = { description = "Oracle password for CMS repository" }
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

  bi-platform_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "base_rhel_8_5_*"
      ssm_parameters_prefix     = "bi-platform/"
      iam_resource_names_prefix = "ec2-bi-platform"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private"]
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
      os-type     = "Linux"
      server-type = "ncr-bip"
      component   = "web"
    }
  }

}