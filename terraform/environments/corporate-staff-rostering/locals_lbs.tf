locals {

  lbs = {
    rxy = {
      access_logs                      = false
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = true
      force_destroy_bucket             = true
      internal_lb                      = true
      load_balancer_type               = "network"
      security_groups                  = ["load-balancer"]
      subnets = [
        module.environment.subnet["private"]["eu-west-2a"].id,
        module.environment.subnet["private"]["eu-west-2b"].id,
      ]
      instance_target_groups = {
        w-80 = {
          port     = 80
          protocol = "TCP"
          health_check = {
            enabled             = true
            interval            = 5
            healthy_threshold   = 3
            port                = 80
            protocol            = "TCP"
            timeout             = 4
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "source_ip"
          }
        }
        w-7770 = {
          port     = 7770
          protocol = "TCP"
          health_check = {
            enabled             = true
            interval            = 5
            healthy_threshold   = 3
            path                = "/isps/index.html"
            port                = 7770
            protocol            = "HTTP"
            timeout             = 4
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "source_ip"
          }
        }
        w-7771 = {
          port     = 7771
          protocol = "TCP"
          health_check = {
            enabled             = true
            interval            = 5
            healthy_threshold   = 3
            path                = "/isps/index.html"
            port                = 7771
            protocol            = "HTTP"
            timeout             = 4
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "source_ip"
          }
        }
        w-7780 = {
          port     = 7780
          protocol = "TCP"
          health_check = {
            enabled             = true
            interval            = 5
            healthy_threshold   = 3
            path                = "/"
            port                = 7770
            protocol            = "HTTP"
            timeout             = 4
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "source_ip"
          }
        }
        w-7781 = {
          port     = 7781
          protocol = "TCP"
          health_check = {
            enabled             = true
            interval            = 5
            healthy_threshold   = 3
            path                = "/"
            port                = 7771
            protocol            = "HTTP"
            timeout             = 4
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "source_ip"
          }
        }
      }
      listeners = {
        http = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
          port                     = 80
          protocol                 = "TCP"
        }
        http-7770 = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
          port                     = 7770
          protocol                 = "TCP"
        }
        http-7771 = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
          port                     = 7771
          protocol                 = "TCP"
        }
        http-7780 = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
          port                     = 7780
          protocol                 = "TCP"
        }
        http-7781 = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
          port                     = 7781
          protocol                 = "TCP"
        }
      }
    }
  }
}
