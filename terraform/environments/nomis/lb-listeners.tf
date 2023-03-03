locals {
  existing_target_groups_list = [
    for asg_key, asg_value in module.ec2_weblogic_autoscaling_group : [
      for tg_key, tg_value in asg_value.lb_target_groups : {
        key   = "${asg_key}-${tg_key}"
        value = tg_value
      }
    ]
  ]
  existing_target_groups = { for item in flatten(local.existing_target_groups_list) : item.key => item.value }

  cloudwatch_metric_alarms_listener = {
    load-balancer-unhealthy-state-target = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      metric_name         = "UnHealthyStateTarget"
      namespace           = "AWS/ApplicationELB"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "This metric monitors the number of unhealthy hosts in the target table for the load balancer. If the number of unhealthy hosts is greater than 0 for 3 minutes."
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
    }
  }
}

module "lb_listener" {
  for_each = local.lb_listeners[local.environment]

  source = "../../modules/lb_listener"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  name                     = each.key
  business_unit            = local.business_unit
  environment              = local.environment
  load_balancer_arn        = module.loadbalancer[each.value.lb_application_name].load_balancer.arn
  target_groups            = try(each.value.target_groups, {})
  existing_target_groups   = local.existing_target_groups
  port                     = each.value.port
  protocol                 = each.value.protocol
  ssl_policy               = try(each.value.ssl_policy, null)
  certificate_arns         = try(each.value.certificate_arns, [])
  default_action           = each.value.default_action
  rules                    = try(each.value.rules, {})
  route53_records          = try(each.value.route53_records, {})
  replace                  = try(each.value.replace, {})
  tags                     = try(each.value.tags, local.tags)
  cloudwatch_metric_alarms = local.cloudwatch_metric_alarms_listener
}
