module "alb" {
  # source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer"
  source = "./modules/ALB"
  providers = {
    aws.bucket-replication = aws
  }

  vpc_all                    = local.vpc_all
  application_name           = local.application_name
  public_subnets             = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  tags                       = local.tags
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = local.application_data.accounts[local.environment].region
  enable_deletion_protection = false
  idle_timeout               = 60
  force_destroy_bucket       = true
  ingress_cidr_block         = data.aws_vpc.shared.cidr_block
  deregistration_delay       = 30
  healthcheck_interval       = 15
  healthcheck_timeout        = 5
  healthcheck_healthy_threshold = 2
  healthcheck_unhealthy_threshold = 3
  stickiness_enabled         = true
  stickiness_type            = lb_cookie
  stickiness_cookie_duration = 10800
}








