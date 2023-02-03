locals {

  lb_defaults = {
    enable_delete_protection = false
    idle_timeout             = "60"
    public_subnets           = module.environment.subnets["public"].ids
    force_destroy_bucket     = true
    internal_lb              = true
    tags                     = local.tags
    security_groups          = [aws_security_group.public.id]
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
      nomis-internal = {
        internal_lb = true
      }
    }

    preproduction = {}

    production = {}
  }
}
