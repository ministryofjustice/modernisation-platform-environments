# ######################################
# CloudWatch Alarms for SSOGEN
# ######################################
# Alarm for ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_ssogen_5xx" {
  count               = local.is-development || local.is-test ? 1 : 0
  alarm_name          = "${local.application_name_ssogen}-${local.environment}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm when the number of 5xx errors from the ssogen ALB exceeds 10 in a 3 minute period"
  dimensions = {
    LoadBalancer = aws_lb.ssogen_alb[count.index].name
  }
  treat_missing_data = "notBreaching"
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  ok_actions          = [aws_sns_topic.cw_alerts.arn]

  tags = local.tags
}

# Underlying EC2 Instance Status Check Failure for Primary ASG
resource "aws_cloudwatch_metric_alarm" "Primary_Status_Check_Failure" {
  count             = local.is-development || local.is-test ? 1 : 0
  alarm_name          = "${local.application_name_ssogen}-${local.environment}-ec2-primary-status-check-failure"
  alarm_description   = "A ssogen EC2 instance has failed a status check, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ssogen-scaling-group-primary[count.index].name
  }
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  ok_actions          = [aws_sns_topic.cw_alerts.arn]

  tags = local.tags
}

# Underlying EC2 Instance Status Check Failure
resource "aws_cloudwatch_metric_alarm" "Secondary_Status_Check_Failure" {
  count               = local.is-development || local.is-test ? 1 : 0
  alarm_name          = "${local.application_name_ssogen}-${local.environment}-ec2-secondary-status-check-failure"
  alarm_description   = "A ssogen EC2 instance has failed a status check, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ssogen-scaling-group-secondary[count.index].name
  }
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  ok_actions          = [aws_sns_topic.cw_alerts.arn]

  tags = local.tags
}

# Underlying waf Instance Status Check Failure
resource "aws_cloudwatch_metric_alarm" "ssogen_waf_high_blocked_requests" {
  count               = local.is-development || local.is-test ? 1 : 0
  alarm_name          = "${local.application_name_ssogen}-${local.environment}-waf-high-blocked-requests"
  alarm_description   = "High number of requests blocked by WAF. Potential attack."

  comparison_operator = "GreaterThanThreshold"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 50 # tune for your workload
  treat_missing_data  = "notBreaching"

  dimensions = {
    WebACL = aws_wafv2_web_acl.ssogen_web_acl[count.index].name
    Scope  = "REGIONAL"
  }

  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  ok_actions          = [aws_sns_topic.cw_alerts.arn]

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "ssogen_alb_healthyhosts_app" {
  count           = local.is-development || local.is-test ? 1 : 0
  alarm_name          = "${local.application_name_ssogen}-${local.environment}-app-alb-targets-group"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 240
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].ssogen_no_instances
  alarm_description   = "Number of healthy hosts in SSOGEN App Target Group"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  ok_actions          = [aws_sns_topic.cw_alerts.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.ssogen_internal_tg_ssogen_app[count.index].arn_suffix
    LoadBalancer = aws_lb.ssogen_alb[count.index].arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ssogen_alb_healthyhosts_admin" {
  count        = local.is-development || local.is-test ? 1 : 0
  alarm_name          = "${local.application_name_ssogen}-${local.environment}-admin-alb-targets-group"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 240
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].ssogen_no_instances
  alarm_description   = "Number of healthy hosts in SSOGEN Admin Target Group"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  ok_actions          = [aws_sns_topic.cw_alerts.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.ssogen_internal_tg_ssogen_admin[count.index].arn_suffix
    LoadBalancer = aws_lb.ssogen_alb[count.index].arn_suffix
  }
}

# resource "aws_cloudwatch_metric_alarm" "disk_free_ssogen_temp" {
#   count                     = local.application_data.accounts[local.environment].ssogen_no_instances
#   alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ssogen${count.index + 1}-disk_free-temp"
#   alarm_description         = "This metric monitors the amount of free disk space on /temp mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   metric_name               = "disk_used_percent"
#   namespace                 = "CWAgent"
#   statistic                 = "Average"
#   insufficient_data_actions = [aws_sns_topic.cw_alerts.arn]

#   evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#   datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#   period              = local.application_data.cloudwatch_ec2.disk.period
#   threshold           = local.application_data.cloudwatch_ec2.disk.threshold
#   alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#   ok_actions          = [aws_sns_topic.cw_alerts.arn]

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group.name
#     path         = "/temp"
#     fstype       = "ext4"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "disk_free_ssogen_home_primary" {
#   count                     = local.is-development || local.is-test ? 1 : 0
#   # count                     = local.application_data.accounts[local.environment].ssogen_no_instances
#   alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ssogen${count.index + 1}-disk_free-home"
#   alarm_description         = "This metric monitors the amount of free disk space on /home mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   metric_name               = "disk_used_percent"
#   namespace                 = "CWAgent"
#   statistic                 = "Average"
#   insufficient_data_actions = [aws_sns_topic.cw_alerts.arn]
#   treat_missing_data        = "notBreaching"

#   evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#   datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#   period              = local.application_data.cloudwatch_ec2.disk.period
#   threshold           = local.application_data.cloudwatch_ec2.disk.threshold
#   alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#   ok_actions          = [aws_sns_topic.cw_alerts.arn]

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.ssogen-scaling-group-primary[count.index].name
#     path         = "/home"
#     fstype       = "ext4"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "disk_free_ssogen_home_secondary" {
#   count                = local.is-development || local.is-test ? 1 : 0
#   # count                     = local.application_data.accounts[local.environment].ssogen_no_instances
#   alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ssogen${count.index + 1}-disk_free-home"
#   alarm_description         = "This metric monitors the amount of free disk space on /home mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   metric_name               = "disk_used_percent"
#   namespace                 = "CWAgent"
#   statistic                 = "Average"
#   insufficient_data_actions = [aws_sns_topic.cw_alerts.arn]
#   treat_missing_data        = "notBreaching"

#   evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#   datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#   period              = local.application_data.cloudwatch_ec2.disk.period
#   threshold           = local.application_data.cloudwatch_ec2.disk.threshold
#   alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#   ok_actions          = [aws_sns_topic.cw_alerts.arn]

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.ssogen-scaling-group-secondary[count.index].name
#     path         = "/home"
#     fstype       = "ext4"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_export_home" {
#   count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
#   alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-export_home"
#   alarm_description         = "This metric monitors the amount of free disk space on /export/home mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   metric_name               = "disk_used_percent"
#   namespace                 = "CWAgent"
#   statistic                 = "Average"
#   insufficient_data_actions = [aws_sns_topic.cw_alerts.arn]

#   evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#   datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#   period              = local.application_data.cloudwatch_ec2.disk.period
#   threshold           = local.application_data.cloudwatch_ec2.disk.threshold
#   alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#   ok_actions          = [aws_sns_topic.cw_alerts.arn]

#   dimensions = {
#     ImageId      = aws_instance.ec2_ebsapps[count.index].ami
#     path         = "/export/home"
#     InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
#     InstanceId   = aws_instance.ec2_ebsapps[count.index].id
#     fstype       = "ext4"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "disk_free_ssogen_u01" {
#   count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
#   alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ssogen${count.index + 1}-disk_free-u01"
#   alarm_description         = "This metric monitors the amount of free disk space on /u01 mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   metric_name               = "disk_used_percent"
#   namespace                 = "CWAgent"
#   statistic                 = "Average"
#   insufficient_data_actions = [aws_sns_topic.cw_alerts.arn]

#   evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#   datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#   period              = local.application_data.cloudwatch_ec2.disk.period
#   threshold           = local.application_data.cloudwatch_ec2.disk.threshold
#   alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#   ok_actions          = [aws_sns_topic.cw_alerts.arn]

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group.name
#     path         = "/u01"
#     fstype       = "ext4"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "disk_free_ssogen_u03" {
#   count                     = local.application_data.accounts[local.environment].ssogen_no_instances
#   alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ssogen${count.index + 1}-disk_free-u03"
#   alarm_description         = "This metric monitors the amount of free disk space on /u03 mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   metric_name               = "disk_used_percent"
#   namespace                 = "CWAgent"
#   statistic                 = "Average"
#   insufficient_data_actions = [aws_sns_topic.cw_alerts.arn]

#   evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#   datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#   period              = local.application_data.cloudwatch_ec2.disk.period
#   threshold           = local.application_data.cloudwatch_ec2.disk.threshold
#   alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#   ok_actions          = [aws_sns_topic.cw_alerts.arn]
#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group.name
#     path         = "/u03"
#     fstype       = "ext4"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "disk_free_ssogen_stage" {
#   count                     = local.application_data.accounts[local.environment].ssogen_no_instances
#   alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ssogen${count.index + 1}-disk_free-stage"
#   alarm_description         = "This metric monitors the amount of free disk space on /stage mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   metric_name               = "disk_used_percent"
#   namespace                 = "CWAgent"
#   statistic                 = "Average"
#   insufficient_data_actions = [aws_sns_topic.cw_alerts.arn]

#   evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#   datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#   period              = local.application_data.cloudwatch_ec2.disk.period
#   threshold           = local.application_data.cloudwatch_ec2.disk.threshold
#   alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#   ok_actions          = [aws_sns_topic.cw_alerts.arn]
#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group.name
#     path         = "/stage"
#     fstype       = "ext4"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_backup_prod" {
#   count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
#   alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-backup_prod"
#   alarm_description         = "This metric monitors the amount of free disk space on /backup_prod mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   metric_name               = "disk_used_percent"
#   namespace                 = "CWAgent"
#   statistic                 = "Average"
#   insufficient_data_actions = [aws_sns_topic.cw_alerts.arn]

#   evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#   datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#   period              = local.application_data.cloudwatch_ec2.disk.period
#   threshold           = local.application_data.cloudwatch_ec2.disk.threshold
#   alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#   ok_actions          = [aws_sns_topic.cw_alerts.arn]
#   dimensions = {
#     ImageId      = aws_instance.ec2_ebsapps[count.index].ami
#     path         = "/backup_prod"
#     InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
#     InstanceId   = aws_instance.ec2_ebsapps[count.index].id
#     fstype       = "ext4"
#   }
# }