
# Restricts monitoring to nomis-production environment and monitored instances only
/* data "aws_instances" "nomis" {
  instance_tags = {
    environment = "nomis-production"
    monitored   = true 
  }
  instance_state_names = ["running"]
} */

# Status and Instance Health Check Alarm

resource "aws_cloudwatch_metric_alarm" "status_and_instance_health_check" {
  # for_each            = toset(data.aws_instances.nomis.ids)
  alarm_name          = "status_and_instance_health_check_${each.value}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "180"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ec2 status and instance health check"
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  /* dimensions = {
    InstanceId = "${each.value}"
  } */
  tags = {
    Name = "status_and_instance_health_check"
  }
}

# CPU Utilization Alarm

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  # for_each            = toset(data.aws_instances.nomis.ids)
  alarm_name          = "cpu_utilization_${each.value}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  /* dimensions = {
    InstanceId = "${each.value}"
  } */
  tags = {
    Name = "cpu_utilization"
  }
}

#==================================================================================================
# Setup for monitoring/alerting
#==================================================================================================

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "nomis_alarms" {
  name              = "nomis_alarms"
  # kms_master_key_id = data.aws_kms_key.sns.id
}

## Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}
data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
}

# link the sns topic to the service
module "pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.nomis_alarms
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [aws_sns_topic.nomis_alarms.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["nomis_alarms"]
}
