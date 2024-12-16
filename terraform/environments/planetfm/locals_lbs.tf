locals {

  lbs = {

    # NOTE: NTLM auth doesn't support application load balancer
    web = {
      access_logs                      = false
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = true
      force_destroy_bucket             = true
      internal_lb                      = true
      load_balancer_type               = "network"
      security_groups                  = ["loadbalancer"]
      subnets = [
        module.environment.subnet["private"]["eu-west-2a"].id,
        module.environment.subnet["private"]["eu-west-2b"].id,
      ]
      instance_target_groups = {
        https = {
          port     = 443
          protocol = "TCP"
          health_check = {
            enabled             = true
            interval            = 5
            healthy_threshold   = 3
            port                = 443
            protocol            = "TCP"
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
        https = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
          port                     = 443
          protocol                 = "TCP"
        }
      }
    }
  }
}
