locals {

  ec2_autoscaling_groups = {

    bip_cms = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      config               = local.ec2_instances.bip_cms.config
      ebs_volumes          = local.ec2_instances.bip_cms.ebs_volumes
      instance             = local.ec2_instances.bip_cms.instance
      user_data_cloud_init = local.ec2_instances.bip_cms.user_data_cloud_init
      tags                 = local.ec2_instances.bip_cms.tags
    }

    bip_web = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      config      = local.ec2_instances.bip_web.config
      ebs_volumes = local.ec2_instances.bip_web.ebs_volumes
      instance    = local.ec2_instances.bip_web.instance

      lb_target_groups = {
        asg-http-7777 = {
          port     = 7777
          protocol = "HTTP"
          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 30
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

      user_data_cloud_init = local.ec2_instances.bip_web.user_data_cloud_init
      tags                 = local.ec2_instances.bip_web.tags
    }

    bods = merge(local.ec2_instances.bods, {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      autoscaling_schedules = {
        scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
      }
    })

    boe_app = merge(local.ec2_instances.boe_app, {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      autoscaling_schedules = {
        scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
      }
    })

    boe_web = merge(local.ec2_instances.boe_web, {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      autoscaling_schedules = {
        scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
      }
    })
  }
}
