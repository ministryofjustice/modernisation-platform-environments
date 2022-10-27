# DSOS-109
module "jb_load_balancer_test" {
  source = "git@github.com:ministryofjustice/modernisation-platform-terraform-loadbalancer.git"
  count  = local.environment == "development" ? 1 : 0

  account_number             = local.modernisation_platform_account_id
  application_name           = local.application_name
  enable_deletion_protection = false
  idle_timeout               = "60"
  loadbalancer_egress_rules  = ""
  loadbalancer_ingress_rules = ""
  public_subnets             = ""
  region                     = local.region
  tags                       = ""
  vpc_all                    = ""
}

locals {
  
}