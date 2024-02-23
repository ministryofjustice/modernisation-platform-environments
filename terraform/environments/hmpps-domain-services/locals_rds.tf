locals {

  rds_ec2_instance = {
    # ami has unwanted ephemeral device, don't copy all the ebs_volumess
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                      = "hmpps_windows_server_2022_release_2024-01-16T09-48-13.663Z"
      availability_zone             = "eu-west-2a"
      ebs_volumes_copy_all_from_ami = false
      user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      vpc_security_group_ids = ["rds-ec2s"]
    })
    ebs_volumes = {
      "/dev/sda1" = { type = "gp3", size = 100 }
    }
    tags = {
      os-type     = "Windows"
      component   = "remotedesktop"
      backup-plan = "daily-and-weekly"
    }
  }

  rds_lbs = {
    public = {
      access_logs                      = true
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = false
      force_destroy_bucket             = true
      internal_lb                      = false
      load_balancer_type               = "application"
      security_groups                  = ["public-lb"]
      subnets                          = module.environment.subnets["public"].ids
    }
  }

  rds_lb_listeners = {
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
    https = {
      port                      = 443
      protocol                  = "HTTPS"
      ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_names_or_arns = ["remote_desktop_wildcard_cert"]
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

  rds_target_groups = {
    http = {
      port     = 80
      protocol = "HTTP"
      health_check = {
        enabled             = true
        interval            = 10
        healthy_threshold   = 3
        matcher             = "200-399"
        path                = "/"
        port                = 80
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      stickiness = {
        enabled = true
        type    = "lb_cookie"
      }
      target_type = "instance"
    }
    https = {
      port     = 443
      protocol = "HTTPS"
      health_check = {
        enabled             = true
        interval            = 10
        healthy_threshold   = 3
        matcher             = "200-399"
        path                = "/"
        port                = 443
        protocol            = "HTTPS"
        timeout             = 5
        unhealthy_threshold = 2
      }
      stickiness = {
        enabled = true
        type    = "lb_cookie"
      }
      target_type = "instance"
    }
  }

}
