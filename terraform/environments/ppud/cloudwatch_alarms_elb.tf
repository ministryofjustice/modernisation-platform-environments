##############################################
# CloudWatch Alarms for Elastic Load Balancers
##############################################

##############################
# CloudWatch Alarms Production
##############################

resource "aws_cloudwatch_metric_alarm" "high_target_response_time_wam_elb" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "High-Target-Response-Time-WAM-ELB"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "3600"
  statistic           = "Average"
  threshold           = "2"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the target response time of the WAM load balancer. If the target response time averages over 1 second for 60 minutes, the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    LoadBalancer     = "app/WAM-ALB-PROD/bfc963544454bdde"
    AvailabilityZone = "eu-west-2a"
  }
}