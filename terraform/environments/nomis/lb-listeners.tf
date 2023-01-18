module "lb_listener" {
  for_each = local.lb_listeners[local.environment]

  source = "../../modules/lb_listener"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  name              = each.key
  business_unit     = local.vpc_name
  environment       = local.environment
  load_balancer_arn = module.loadbalancer[each.value.lb_application_name].load_balancer.arn
  target_groups     = try(each.value.target_groups, {})
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = try(each.value.ssl_policy, null)
  certificate_arns  = try(each.value.certificate_arns, [])
  default_action    = each.value.default_action
  rules             = try(each.value.rules, {})
  route53_records   = try(each.value.route53_records, {})
  tags              = try(each.value.tags, local.tags)
}
