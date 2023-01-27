# following AWS terraform naming convention here aws_lb, aws_lb_listener, so lbs.tf and lb_listeners.tf.

module "loadbalancer" {
  for_each = merge(local.lbs.common, local.lbs[local.environment])

  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer.git?ref=v2.1.2"
  providers = {
    aws.bucket-replication = aws
  }

  account_number             = local.environment_management.account_ids[terraform.workspace]
  application_name           = each.key
  enable_deletion_protection = try(each.value.enable_delete_protection, local.lb_defaults.enable_delete_protection)
  force_destroy_bucket       = try(each.value.force_destroy_bucket, local.lb_defaults.force_destroy_bucket)
  idle_timeout               = try(each.value.idle_timeout, local.lb_defaults.idle_timeout)
  internal_lb                = try(each.value.internal_lb, local.lb_defaults.internal_lb)
  loadbalancer_egress_rules  = try(each.value.lb_egress_rules, local.lb_defaults.lb_egress_rules)
  loadbalancer_ingress_rules = try(each.value.lb_ingress_rules, local.lb_defaults.lb_ingress_rules)
  public_subnets             = try(each.value.public_subnets, local.lb_defaults.public_subnets)
  region                     = local.region
  vpc_all                    = module.environment.vpc_name
  tags                       = try(each.value.tags, local.lb_defaults.tags)
}
