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
        description     = "Allow Inbound Http"
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.jumpserver-windows.id]
        cidr_blocks     = local.environment_config.external_weblogic_access_cidrs
      }
      http7001_external = {
        description     = "Allow Inbound Http port 7001"
        from_port       = 7001
        to_port         = 7001
        protocol        = "tcp"
        security_groups = [aws_security_group.jumpserver-windows.id]
        cidr_blocks     = local.environment_config.external_weblogic_access_cidrs
      }
      http7777_external = {
        description     = "Allow Inbound Http port 7777"
        from_port       = 7777
        to_port         = 7777
        protocol        = "tcp"
        security_groups = [aws_security_group.jumpserver-windows.id]
        cidr_blocks     = local.environment_config.external_weblogic_access_cidrs
      }
      https_external = {
        description     = "Allow Inbound Https"
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        security_groups = [aws_security_group.jumpserver-windows.id]
        cidr_blocks     = local.environment_config.external_weblogic_access_cidrs
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
