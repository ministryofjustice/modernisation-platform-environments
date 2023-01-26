# following AWS terraform naming convention here aws_lb, aws_lb_listener, so lbs.tf and lb_listeners.tf.

module "loadbalancer" {
  for_each = merge(local.lbs.common, local.lbs[local.environment])

  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer.git?ref=v2.1.2"
  providers = {
    aws.bucket-replication = aws
  }

  account_number             = local.environment_management.account_ids[terraform.workspace]
  application_name           = each.key
  enable_deletion_protection = coalesce(lookup(each.value, "enable_delete_protection", null), local.lb_defaults.enable_delete_protection)
  force_destroy_bucket       = coalesce(lookup(each.value, "force_destroy_bucket", null), local.lb_defaults.force_destroy_bucket)
  idle_timeout               = coalesce(lookup(each.value, "idle_timeout", null), local.lb_defaults.idle_timeout)
  internal_lb                = coalesce(lookup(each.value, "internal_lb", null), local.lb_defaults.internal_lb)
  security_groups            = coalesce(lookup(each.value, "security_groups", null), local.lb_defaults.security_groups)
  public_subnets             = coalesce(lookup(each.value, "public_subnets", null), local.lb_defaults.public_subnets)
  region                     = local.region
  vpc_all                    = module.environment.vpc_name
  tags                       = coalesce(lookup(each.value, "tags", null), local.lb_defaults.tags)
}
