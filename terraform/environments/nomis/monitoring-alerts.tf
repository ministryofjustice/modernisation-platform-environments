# ==============================================================================
# Nomis Monitoring and Alerts
# ==============================================================================

# Restricts monitoring to nomis-production environment and monitored instances only
# data "aws_instances" "nomis" {
#   instance_tags = {
#     environment = "nomis-production"
#     monitored   = true 
#   }
#   instance_state_names = ["running"]
# }

# Status and Instance Health Check Alarm

resource "aws_cloudwatch_metric_alarm" "status_and_instance_health_check" {
  # for_each            = toset(data.aws_instances.nomis.ids)
  alarm_name          = "status_and_instance_health_check"
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
  alarm_name          = "cpu_utilization"                           # name of the alarm
  comparison_operator = "GreaterThanOrEqualToThreshold"             # threshold to trigger the alarm state
  evaluation_periods  = "1"                                         # how many periods over which to evaluate the alarm
  metric_name         = "CPUUtilization"                            # name of the alarm's associated metric   
  namespace           = "AWS/EC2"                                   # namespace of the alarm's associated metric
  period              = "60"                                        # period in seconds over which the specified statistic is applied
  statistic           = "Average"                                   # could be Average/Minimum/Maximum etc.
  threshold           = "90"                                        # threshold for the alarm - see comparison_operator for usage
  alarm_description   = "This metric monitors ec2 cpu utilization"  # description of the alarm
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]            # SNS topic to send the alarm to
  /* dimensions = {
    InstanceId = "${each.value}"
  } */
  tags = {
    Name = "cpu_utilization"
  }
}
