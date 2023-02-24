locals {
  # flatten the load balancer listeners
  lb_listener_list = [
    for lb_key, lb_value in var.lbs : [
      for listener_key, listener_value in lb_value.listeners : {
        key = "${lb_key}-${listener_key}"
        value = merge(listener_value, {
          lb_application_name = lb_key
        })
      }
    ]
  ]
  lb_listeners = { for item in flatten(local.lb_listener_list) : item.key => item.value }
}

# following AWS terraform naming convention here aws_lb, aws_lb_listener, so lbs.tf and lb_listeners.tf.
module "lb" {
  for_each = var.lbs

  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer.git?ref=v2.1.2"

  providers = {
    aws.bucket-replication = aws
  }

  account_number             = var.environment.account_id
  application_name           = each.key
  enable_deletion_protection = each.value.enable_delete_protection
  force_destroy_bucket       = each.value.force_destroy_bucket
  idle_timeout               = each.value.idle_timeout
  internal_lb                = each.value.internal_lb

  security_groups = [
    for sg in each.value.security_groups : lookup(aws_security_group.this, sg, null) != null ? aws_security_group.this[sg].id : sg
  ]

  public_subnets = each.value.public_subnets
  region         = var.environment.region
  vpc_all        = var.environment.vpc_name
  tags           = merge(local.tags, each.value.tags)
}

module "lb_listener" {
  for_each = local.lb_listeners

  source = "../../modules/lb_listener"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  name                   = each.key
  business_unit          = var.environment.business_unit
  environment            = var.environment.environment
  load_balancer_arn      = module.lb[each.value.lb_application_name].load_balancer.arn
  existing_target_groups = local.asg_target_groups
  port                   = each.value.port
  protocol               = each.value.protocol
  ssl_policy             = each.value.ssl_policy
  certificate_arns       = each.value.certificate_arns
  default_action         = each.value.default_action
  rules                  = each.value.rules
  route53_records        = each.value.route53_records
  tags                   = merge(local.tags, each.value.tags)

  depends_on = [
    module.acm_certificate,       # ensure certs are created first
    module.ec2_autoscaling_group, # ensure ASG target groups are created first
  ]
}
