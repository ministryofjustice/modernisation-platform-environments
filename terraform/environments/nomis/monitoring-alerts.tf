# ==============================================================================
# Load Balancer Alerts - TO BE MOVED
# ==============================================================================
resource "aws_cloudwatch_metric_alarm" "load_balancer_unhealthy_state_routing" {
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
}

resource "aws_cloudwatch_metric_alarm" "load_balancer_unhealthy_state_dns" {
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
}

# This may be overkill as unhealthy hosts will trigger an alert themselves (or should do) independently.
resource "aws_cloudwatch_metric_alarm" "load_balancer_unhealthy_state_target" {
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
}

# ==============================================================================
# Certificate Alerts - Days to Expiry - TO BE MOVED
# Certificates are managed by AWS Certificate Manager (ACM) so there shouldn't be any reason why these don't renew automatically. 
# ==============================================================================
/* resource "aws_cloudwatch_metric_alarm" "cert_expires_in_30_days" {
  alarm_name          = "cert-expires-in-30-days"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors the number of days until the certificate expires. If the number of days is less than 30."
  alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
  dimensions = {
    "CertificateArn" = "value"
  }
} */

/* resource "aws_cloudwatch_metric_alarm" "cert_expires_in_2_days" {
  alarm_name          = "cert-expires-in-2-days"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = "60"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors the number of days until the certificate expires. If the number of days is less than 2."
  alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
  dimensions = {
    "CertificateArn" = "value"
  }
} */