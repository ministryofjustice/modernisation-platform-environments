# ==============================================================================
# Load Balancer Alerts - TO BE MOVED
# ==============================================================================
/* resource "aws_cloudwatch_metric_alarm" "load-balancer-unhealthy-state-routing" {
  alarm_name          = "load-balancer-unhealthy-state-routing"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "UnHealthyStateRouting"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors the number of unhealthy hosts in the routing table for the load balancer. If the number of unhealthy hosts is greater than 0 for 3 minutes."
  alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
} */

/* resource "aws_cloudwatch_metric_alarm" "load-balancer-unhealthy-state-dns" {
  alarm_name          = "load-balancer-unhealthy-state-dns"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "UnHealthyStateDNS"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors the number of unhealthy hosts in the DNS table for the load balancer. If the number of unhealthy hosts is greater than 0 for 3 minutes."
  alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
} */

# This may be overkill as unhealthy hosts will trigger an alert themselves (or should do) independently.
/* resource "aws_cloudwatch_metric_alarm" "load-balancer-unhealthy-state-target" {
  alarm_name          = "load-balancer-unhealthy-state-target"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "UnHealthyStateTarget"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors the number of unhealthy hosts in the target table for the load balancer. If the number of unhealthy hosts is greater than 0 for 3 minutes."
  alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
} */