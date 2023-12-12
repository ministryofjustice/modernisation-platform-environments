# nomis-development environment settings
locals {

  # baseline config
  development_config = {

    baseline_ec2_autoscaling_groups = {
      # "dev-asg" = {

      # }
    }
    baseline_lbs = {

      private = {
        internal_lb                      = true
        enable_delete_protection         = false
        loadbalancer_type                = "application"
        idle_timeout                     = 3600
        security_groups                  = ["loadbalancer"]
        subnets                          = module.environment.subnets["private"].ids
        enable_cross_zone_load_balancing = true
        access_logs                      = true #default value

        instance_target_groups = {}

        listeners = {}
       
      }
    }
  }
}

