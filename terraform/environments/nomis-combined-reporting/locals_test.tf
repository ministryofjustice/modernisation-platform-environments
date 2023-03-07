locals {
  test_config = {

    baseline_ec2_autoscaling_groups = {

      test-base-rhel85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "base_rhel_8_5_*"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing with official RedHat RHEL8.5 image"
          os-type     = "Linux"
          component   = "test"
        }
        lb_target_groups = {
          http-7777 = {
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
        }
      }
    }
    baseline_lbs = {
    }
  }
}
