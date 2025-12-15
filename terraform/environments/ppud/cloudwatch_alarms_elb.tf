##############################################
# CloudWatch Alarms for Elastic Load Balancers
##############################################

##############################
# CloudWatch Alarms Production
##############################
/*
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
  alarm_description   = "This metric monitors the target response time of the WAM load balancer. If the target response time averages over 2 second for 60 minutes, the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_std_and_sms_alerts[0].arn]
  dimensions = {
    LoadBalancer     = "app/WAM-ALB-PROD/bfc963544454bdde"
    AvailabilityZone = "eu-west-2a"
  }
}
*/

resource "aws_cloudwatch_metric_alarm" "high_target_response_time_wam_alb_p95" {
  count               = local.is-production ? 1 : 0
  alarm_name          = "High-Target-Response-Time-P95-WAM-ALB"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = 2
  period              = 60
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p95"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    LoadBalancer     = "app/WAM-ALB-PROD/bfc963544454bdde"
    AvailabilityZone = "eu-west-2a"
  }
   alarm_description = "This metric monitors the target response time of the WAM load balancer. If the target response time averages over 2 seconds for 3 of the last 5 minutes, the alarm will trigger."
}