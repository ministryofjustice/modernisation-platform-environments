#####################################
#
# ECS ALERTING 
# 
#####################################

resource "aws_cloudwatch_metric_alarm" "maat_EscCPUoverThreshold" {
  alarm_name         = "${local.application_name}-ECS-CPU-high-threshold-alarm"
  alarm_description  = "If the CPU exceeds the predefined threshold, this alarm will trigger. Please investigate"
  namespace          = "AWS/ECS"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn, aws_sns_topic.AlertCrimeAppsSnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn, aws_sns_topic.AlertCrimeAppsSnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ECSCPUAlarmThreshold
  treat_missing_data = "breaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ECS-CPU-high-threshold-alarm"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_EcsMemoryOverThreshold" {
  alarm_name         = "${local.application_name}-ECS-Memory-high-threshold-alarm"
  alarm_description  = "If the memory util exceeds the predefined threshold, this alarm will trigger. Please investigate."
  namespace          = "AWS/ECS"
  metric_name        = "MemoryUtilization"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].EcsMemoryOverThreshold
  treat_missing_data = "breaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    var.tags,
    {
      Name = "${local.application_name}-ECS-Memory-high-threshold-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_EcsCPUNotRunning" {
  alarm_name         = "${local.application_name}-ECS-CPU-not-running-alarm"
  alarm_description  = "If the the number of CPU processes drops to 0, this alarm will trigger. Please investigate."
  namespace          = "AWS/ECS"
  metric_name        = "CPUUtilization"
  statistic          = "SampleCount"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn, aws_sns_topic.AlertCrimeAppsSnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn, aws_sns_topic.AlertCrimeAppsSnsTopic.arn]
  threshold          = 0
  treat_missing_data = "breaching"
  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ECS-CPU-not-running-alarm"
    },
  )
}


#####################################
#
# EC2 ALERTING 
# 
#####################################

#######   StatusCheckFailure CLOUDWATCH ALARM

resource "aws_cloudwatch_metric_alarm" "maat_status-check-failure-alarm" {
  alarm_name         = "${local.application_name}-elb-4xx-error-alarm"
  alarm_description  = "If a status check failure occurs on an instance, please investigate. http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html."
  namespace          = "AWS/EC2"
  metric_name        = "StatusCheckFailed"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn, aws_sns_topic.AlertCrimeAppsSnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn, aws_sns_topic.AlertCrimeAppsSnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ASGStatusFailureAlarmThreshold
  treat_missing_data = "breaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.maat_ec2_scaling_group.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-elb-4xx-error-alarm"
    },
  )
}

#####################################
#
# ALB ALERTING 
# 
#####################################

resource "aws_cloudwatch_metric_alarm" "maat_TargetResponseTime" {
  alarm_name         = "${local.application_name}-alb-target-response-time-alarm"
  alarm_description  = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "TargetResponseTime"
  extended_statistic = "p99"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ALBTargetResponseTimeThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.external.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-alb-target-response-time-alarm"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_TargetResponseTimeMaximum" {
  alarm_name         = "${local.application_name}-alb-target-response-time-alarm-maximum"
  alarm_description  = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received. Triggered if response is longer than 60s."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "TargetResponseTime"
  statistic          = "Maximum"
  period             = "60"
  evaluation_periods = "1"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ALBTargetResponseTimeThresholdMaximum
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.external.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-alb-target-response-time-alarm-maximum"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_UnHealthyHosts" {
  alarm_name         = "${local.application_name}-unhealthy-hosts-alarm"
  alarm_description  = "The unhealthy hosts alarm triggers if your load balancer recognises there is an unhealthy host and has been there for over 15 minutes."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "UnHealthyHostCount"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ALBUnhealthyAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.external.name
    TargetGroup = aws_lb_target_group.external.arn
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-unhealthy-hosts-alarm"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_RejectedConnectionCount" {
  alarm_name         = "${local.application_name}-RejectevdConnectionCount-alarm"
  alarm_description  = "There is no surge queue on ALB's. Alert triggers in ALB rejects too many requests, usually due to backend being busy."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "RejectedConnectionCount"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ALBRejectedAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.external.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-RejectevdConnectionCount-alarm"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_http5xxError" {
  alarm_name         = "${local.application_name}-http-5xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 5XX http alerts in a 5 minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_Target_5XX_Count"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ALBTarget5xxAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.external.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-http-5xx-error-alarm"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_ApplicationELB5xxError" {
  alarm_name         = "${local.application_name}-elb-5xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 5XX elb alerts in a 5 minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_ELB_5XX_Count"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ALB5xxAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.external.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-elb-5xx-error-alarm"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_http4xxError" {
  alarm_name         = "${local.application_name}-elb-5xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 4XX http alerts in a 5 minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_Target_4XX_Count"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ALBTarget4xxAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.external.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-elb-5xx-error-alarm"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "maat_ApplicationELB4xxError" {
  alarm_name         = "${local.application_name}-elb-4xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 4XX elb alerts in a 5 minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_ELB_4XX_Count"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.Sev5SnsTopic.arn]
  ok_actions         = [aws_sns_topic.Sev5SnsTopic.arn]
  threshold          = local.application_data.accounts[local.environment].ALB4xxAlarmThreshold 
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.external.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-elb-4xx-error-alarm"
    },
  )
}


#####################################
#
# Dashboard creation and configuration
# 
#####################################

####### CLOUDWATCH DASHBOARD

resource "aws_cloudwatch_dashboard" "maat_cloudwatch_dashboard" {
  dashboard_name = "MAAT"
  depends_on = [
    aws_cloudwatch_metric_alarm.maat_ApplicationELB4xxError,
    aws_cloudwatch_metric_alarm.maat_TargetResponseTime,
    aws_cloudwatch_metric_alarm.maat_http4xxError,
    aws_cloudwatch_metric_alarm.maat_ApplicationELB5xxError,
    aws_cloudwatch_metric_alarm.maat_http5xxError,
    aws_cloudwatch_metric_alarm.maat_RejectedConnectionCount,
    aws_cloudwatch_metric_alarm.maat_UnHealthyHosts,
    aws_cloudwatch_metric_alarm.maat_StatusCheckFailure,
    aws_cloudwatch_metric_alarm.maat_EcsMemoryOverThreshold,
    aws_cloudwatch_metric_alarm.maat_EscCPUoverThreshold,
  ]
  dashboard_body = <<EOF
{
  "widgets" : [
    {
      "type" : "metric",
      "x" : 0,
      "y" : 0,
      "width" : 8,
      "height" : 6,
      "properties" : {
          "title" : "Application ELB 5xx Error",
          "annotations": {
            "alarms": [
              "${aws_cloudwatch_metric_alarm.maat_ApplicationELB5xxError.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${local.application_data.accounts[local.environment].region}",
          "stacked": false
      }
    },
    {
      "type" : "metric",
      "x" : 8,
      "y" : 0,
      "width" : 8,
      "height" : 6,
      "properties" : {
          "title" : "Application ELB 4xx Error",
          "annotations": {
            "alarms": [
              "${aws_cloudwatch_metric_alarm.maat_http4xxError.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${local.application_data.accounts[local.environment].region}",
          "stacked": false
      }
    },
    {
      "type" : "metric",
      "x" : 16,
      "y" : 0,
      "width" : 8,
      "height" : 6,
      "properties" : {
          "title" : "Application ELB Target Response Time",
          "annotations": {
            "alarms": [
              "${aws_cloudwatch_metric_alarm.maat_TargetResponseTime.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${local.application_data.accounts[local.environment].region}",
          "stacked": false
      }
    },
    {
      "type" : "metric",
      "x" : 0,
      "y" : 12,
      "width" : 12,
      "height" : 6,
      "properties" : {
          "title" : "ECS CPU",
          "annotations": {
            "alarms": [
              "${aws_cloudwatch_metric_alarm.maat_EscCPUoverThreshold.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${local.application_data.accounts[local.environment].region}",
          "stacked": false
      }
    },
    {
      "type" : "metric",
      "x" : 12,
      "y" : 12,
      "width" : 12,
      "height" : 6,
      "properties" : {
          "title" : "ECS Memory",
          "annotations": {
            "alarms": [
              "${aws_cloudwatch_metric_alarm.maat_ecsmemoryoverthreshold.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${local.application_data.accounts[local.environment].region}",
          "stacked": false
      }
    }
  ]
}
EOF
}

####### CLOUDWATCH ALERTING
# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "Sev5SnsTopic" {
  name = Sev5SnsTopic
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-Sev5SnsTopic"
    },
  )
}

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "AlertCrimeAppsSnsTopic" {
  name = AlertCrimeAppsSnsTopic
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-AlertCrimeAppsSnsTopic"
    },
  )
}

# resource "aws_sns_topic_subscription" "pagerduty_Sev5_subscription" {
#   topic_arn = aws_sns_topic.Sev5SnsTopic.arn
#   protocol  = "https"
#   endpoint  = "https://events.pagerduty.com/integration/${var.pagerduty_integration_key}/enqueue"
# }

# resource "aws_sns_topic_subscription" "pagerduty_app_subscription" {
#   topic_arn = aws_sns_topic.AlertCrimeAppsSnsTopic.arn
#   protocol  = "https"
#   endpoint  = "https://events.pagerduty.com/integration/${var.pagerduty_integration_key}/enqueue"
# }

