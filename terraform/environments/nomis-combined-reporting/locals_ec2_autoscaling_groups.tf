locals {

  ec2_autoscaling_groups = {

    bip_app = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      config               = local.ec2_instances.bip_app.config
      ebs_volumes          = local.ec2_instances.bip_app.ebs_volumes
      instance             = local.ec2_instances.bip_app.instance
      user_data_cloud_init = local.ec2_instances.bip_app.user_data_cloud_init
      tags                 = local.ec2_instances.bip_app.tags
    }

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

    bip_webadmin = {
      autoscaling_group = {
        desired_capacity    = 1
        max_size            = 1
        force_delete        = true
        vpc_zone_identifier = module.environment.subnets["private"].ids
      }
      config      = local.ec2_instances.bip_webadmin.config
      ebs_volumes = local.ec2_instances.bip_webadmin.ebs_volumes
      instance    = local.ec2_instances.bip_webadmin.instance

      lb_target_groups = {
        http-7010 = {
          port     = 7010
          protocol = "HTTP"
          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 30
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
      }

      user_data_cloud_init = local.ec2_instances.bip_webadmin.user_data_cloud_init
      tags                 = local.ec2_instances.bip_webadmin.tags
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
        http-7777 = {
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

  }
}
