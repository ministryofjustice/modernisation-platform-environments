resource "aws_lb" "tribunals_lb" {
  name                       = "tribunals-lb"
  load_balancer_type         = "application"
  security_groups            = [module.tribunal.tribunals_lb_sc_id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
}