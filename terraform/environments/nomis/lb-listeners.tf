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
    lb-unhealthy-host-count = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      metric_name         = "UnHealthyHostCount"
      namespace           = "AWS/ApplicationELB"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "This metric monitors the number of unhealthy hosts in the target table for the load balancer. If the number of unhealthy hosts is greater than 0 for 3 minutes."
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
    }
    load-balancer-unhealthy-state-routing = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      metric_name         = "UnHealthyStateRouting"
      namespace           = "AWS/ApplicationELB"
      period              = "60"
      statistic           = "Minimum"
      threshold           = "1"
      alarm_description   = "This metric monitors the number of unhealthy hosts in the routing table for the load balancer. If the number of unhealthy hosts is greater than 0 for 3 minutes."
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
    }
    load-balancer-unhealthy-state-dns = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      metric_name         = "UnHealthyStateDNS"
      namespace           = "AWS/ApplicationELB"
      period              = "60"
      statistic           = "Minimum"
      threshold           = "1"
      alarm_description   = "This metric monitors the number of unhealthy hosts in the DNS table for the load balancer. If the number of unhealthy hosts is greater than 0 for 3 minutes."
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
    }
  }
}

