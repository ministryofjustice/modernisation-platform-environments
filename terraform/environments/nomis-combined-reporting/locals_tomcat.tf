locals {

  tomcat_ssm_parameters = {
    prefix = "/tomcat/"
    parameters = {
      bobj_password     = { description = "bobj account password" }
      oracle_password   = { description = "oracle account password" }
      product_key       = { description = "BIP product key" }
      cms_name          = { description = "Name of the BIP CMS machine" }
      cms_password      = { description = "CMS password for host machine" }
    }
  }

  tomcat_target_group_http_7777 = {
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

  tomcat_target_group_http_8443 = {
    port                 = 8443
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 8443
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  tomcat_target_group_http_8005 = {
    port                 = 8005
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 8005
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
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
    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", size = 100 }
      "/dev/sds" = { type = "gp3", size = 100 }
    }
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    lb_target_groups = {
      http7777 = local.tomcat_target_group_http_7777
      admin    = local.tomcat_target_group_http_7010
      redirect = local.tomcat_target_group_http_8443
      shutdown = local.tomcat_target_group_http_8005
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