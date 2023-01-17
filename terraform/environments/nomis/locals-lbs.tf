locals {

  lb_defaults = {
    enable_delete_protection = false
    idle_timeout             = "60"
    public_subnets           = data.aws_subnets.public.ids
    force_destroy_bucket     = true
    internal_lb              = true
    tags                     = local.tags

    lb_egress_rules = {
      # map keys are not used other than for ordering
      all = {
        description     = "Allow all egress"
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
        security_groups = []
      }
    }

    lb_ingress_rules = {
      # map keys are not used other than for ordering
      http_external = {
        description     = "External access to http"
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = []
        cidr_blocks     = local.environment_config.external_weblogic_access_cidrs
      }
      http_internal = {
        description     = "Internal access to http"
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.jumpserver-windows.id]
        cidr_blocks     = []
      }
      https_external = {
        description     = "External access to https"
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        security_groups = []
        cidr_blocks     = local.environment_config.external_weblogic_access_cidrs
      }
      https_internal = {
        description     = "Internal access to https"
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        security_groups = [aws_security_group.jumpserver-windows.id]
        cidr_blocks     = []
      }
    }
  }

  lbs = {

    #--------------------------------------------------------------------------
    # define load balancers common to all environments here
    #--------------------------------------------------------------------------
    common = {}

    #--------------------------------------------------------------------------
    # define environment specific load balancers here
    #--------------------------------------------------------------------------

    development = {}

    test = {
      nomis-public = {
        internal_lb = false
      }
    }

    preproduction = {}

    production = {}
  }
}

locals {
  lb_security_group_ids = [for key, value in module.loadbalancer : value.security_group.id]
}
