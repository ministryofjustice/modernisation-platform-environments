locals {
  sns_topic_name                 = "${var.appnameenv}-alerting-topic"
}

resource "aws_cloudwatch_metric_alarm" "esccpuoverthreshold" {
  alarm_name         = "${var.appnameenv}-ECS-CPU-high-threshold-alarm"
  alarm_description  = "If the CPU exceeds the predefined threshold, this alarm will trigger. \n Please investigate."
  namespace          = "AWS/ECS"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pECSCPUAlarmThreshold
  treat_missing_data = "breaching"
  dimensions = {
    ClusterName = var.pClusterName
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "ecsmemoryoverthreshold" {
  alarm_name         = "${var.appnameenv}-ECS-Memory-Over-Threshold"
  alarm_description  = "If the memory util exceeds the predefined threshold, this alarm will trigger.\n Please investigate."
  namespace          = "AWS/ECS"
  metric_name        = "MemoryUtilization"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pECSMemoryAlarmThreshold
  treat_missing_data = "breaching"
  dimensions = {
    ClusterName = var.pClusterName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "cpuoverthreshold" {

  alarm_name         = "${var.appnameenv}-CPU-high-threshold-alarm"
  alarm_description  = "If the CPU exceeds the predefined threshold, this alarm will trigger. \n Please investigate."
  namespace          = "AWS/EC2"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pASGCPUAlarmThreshold
  treat_missing_data = "breaching"
  dimensions = {
    AutoScalingGroupName = var.pAutoscalingGroupName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "statuscheckfailure" {
  alarm_name         = "${var.appnameenv}-status-check-failure-alarm"
  alarm_description  = "If a status check failure occurs on an instance, please investigate. http=//docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  namespace          = "AWS/EC2"
  metric_name        = "StatusCheckFailed"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pASGStatusFailureAlarmThreshold
  treat_missing_data = "breaching"
  dimensions = {
    AutoScalingGroupName = var.pAutoscalingGroupName
  }
  comparison_operator = "GreaterThanThreshold"
}
# Application Load Balancer Alerting
resource "aws_cloudwatch_metric_alarm" "targetresponsetime" {
  alarm_name         = "${var.appnameenv}-alb-target-response-time-alarm"
  alarm_description  = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received"
  namespace          = "AWS/ApplicationELB"
  metric_name        = "TargetResponseTime"
  extended_statistic = "p99"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pALBTargetResponseTimeThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = var.pLoadBalancerName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "targetResponsetimemaximum" {
  alarm_name         = "${var.appnameenv}-alb-target-response-time-alarm-maximum"
  alarm_description  = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received. Triggered if response is longer than 60s."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "TargetResponseTime"
  statistic          = "Maximum"
  period             = "60"
  evaluation_periods = "1"
  #TODO needs alarm actions and snstopics resources added
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pALBTargetResponseTimeThresholdMaximum
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = var.pLoadBalancerName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "unhealthyhosts" {
  alarm_name         = "${var.appnameenv}-unhealthy-hosts-alarm"
  alarm_description  = "The unhealthy hosts alarm triggers if your load balancer recognises there is an unhealthy host and has been there for over 15 minutes."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "UnHealthyHostCount"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  #AlarmActions
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pALBUnhealthyAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = var.pLoadBalancerName
    TargetGroup  = var.pTargetGroupName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "rejectedconnectioncount" {
  alarm_name         = "${var.appnameenv}-RejectedConnectionCount-alarm"
  alarm_description  = "There is no surge queue on ALB's. Alert triggers in ALB rejects too many requests, usually due to backend being busy."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "RejectedConnectionCount"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pALBRejectedAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = var.pLoadBalancerName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "http5xxerror" {
  alarm_name         = "${var.appnameenv}-http-5xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 5XX http alerts in a 5 minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_Target_5XX_Count"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  #AlarmActions
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pALBTarget5xxAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = var.pLoadBalancerName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "applicationelb5xxerror" {
  alarm_name         = "${var.appnameenv}-elb-5xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 5XX elb alerts in a 5 minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_ELB_5XX_Count"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  #AlarmActions
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pALB5xxAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = var.pLoadBalancerName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "http4xxerror" {
  alarm_name         = "${var.appnameenv}-http-4xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 4XX http alerts in a 5 minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_Target_4XX_Count"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  #AlarmActions
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pALBTarget4xxAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = var.pLoadBalancerName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_metric_alarm" "applicationelb4xxerror" {
  alarm_name         = "${var.appnameenv}-elb-4xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 4XX elb alerts in a 5 minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_ELB_4XX_Count"
  statistic          = "Sum"
  period             = "60"
  evaluation_periods = "5"
  #TODO needs alarm actions and snstopics resources added
  #AlarmActions
  alarm_actions      = [aws_sns_topic.mlra_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.mlra_alerting_topic.arn]
  threshold          = var.pALB4xxAlarmThreshold
  treat_missing_data = "notBreaching"
  dimensions = {
    LoadBalancer = var.pLoadBalancerName
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_cloudwatch_dashboard" "mlradash" {
  dashboard_name = "MLRA"
  depends_on = [
    aws_cloudwatch_metric_alarm.applicationelb4xxerror,
    aws_cloudwatch_metric_alarm.applicationelb5xxerror,
    aws_cloudwatch_metric_alarm.targetresponsetime,
    aws_cloudwatch_metric_alarm.esccpuoverthreshold,
    aws_cloudwatch_metric_alarm.ecsmemoryoverthreshold
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
              "${aws_cloudwatch_metric_alarm.applicationelb5xxerror.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${var.region}",
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
              "${aws_cloudwatch_metric_alarm.applicationelb4xxerror.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${var.region}",
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
              "${aws_cloudwatch_metric_alarm.targetresponsetime.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${var.region}",
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
              "${aws_cloudwatch_metric_alarm.esccpuoverthreshold.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${var.region}",
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
              "${aws_cloudwatch_metric_alarm.ecsmemoryoverthreshold.arn}"
            ]
          },
          "view": "timeSeries",
          "region": "${var.region}",
          "stacked": false
      }
    }
  ]
}
EOF
}

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "mlra_alerting_topic" {
  name = local.sns_topic_name
}
