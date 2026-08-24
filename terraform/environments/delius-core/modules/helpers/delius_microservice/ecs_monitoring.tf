# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", var.ecs_cluster_arn)[1]
}

######################################
###           ECS Alarms           ###
######################################
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_warning" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-cpu-warning"
  alarm_description   = "Triggers alarm if ECS CPU crosses 80%"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ServiceName = "${var.env_name}-${var.name}"
    ClusterName = local.cluster_name
  }

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_critical" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-cpu-critical"
  alarm_description   = "Triggers alarm if ECS CPU crosses 90%"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "90"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ServiceName = "${var.env_name}-${var.name}"
    ClusterName = local.cluster_name
  }

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_warning" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-memory-warning"
  alarm_description   = "Triggers alarm if ECS memory crosses 80%"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ServiceName = "${var.env_name}-${var.name}"
    ClusterName = local.cluster_name
  }

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_critical" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-memory-critical"
  alarm_description   = "Triggers alarm if ECS memory crosses 90%"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "90"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ServiceName = "${var.env_name}-${var.name}"
    ClusterName = local.cluster_name
  }

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_log_metric_filter" "ecs_log_error_filter" {
  count          = var.log_error_pattern != "" ? 1 : 0
  log_group_name = aws_cloudwatch_log_group.ecs.name
  name           = "${var.name}-${var.env_name}-logged-errors"
  pattern        = var.log_error_pattern
  metric_transformation {
    name          = "${var.name}-${var.env_name}-logged-errors"
    namespace     = "${var.env_name}/${var.name}"
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_error_critical" {
  count               = var.log_error_pattern != "" ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-error-count-critical"
  alarm_description   = "Critical alarm for log error threshold"
  namespace           = "${var.env_name}/${var.name}"
  metric_name         = "${var.name}-${var.env_name}-logged-errors"
  statistic           = "Sum"
  period              = var.log_error_threshold_config.critical.period
  evaluation_periods  = "1"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = var.log_error_threshold_config.critical.threshold
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_healthy_hosts_fatal" {
  count               = var.microservice_lb != null ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-healthy-hosts-fatal"
  alarm_description   = "All `${var.name}` instances stopped responding."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Minimum"
  metric_name         = "HealthyHostCount"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  dimensions = {
    LoadBalancer = var.frontend_lb_arn_suffix
    TargetGroup  = aws_lb_target_group.frontend[0].arn_suffix
  }

  tags = merge(var.tags, { "app" = var.name })
}

# Weblogic Capacity Provider Alarms
# Require CW agent to be configured via userdata to export custom metrics
resource "aws_cloudwatch_metric_alarm" "ecs_root_volume_usage_warning" {
  count               = var.asg_name != null ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-root-volume-usage-warning"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 70
  treat_missing_data  = "missing"

  metric_query {
    id          = "root_volume_usage"
    label       = "Highest root volume usage (%)"
    return_data = true
    period      = 300

    expression = <<-EOT
      SELECT MAX(disk_used_percent)
      FROM SCHEMA(CWAgent, AutoScalingGroupName, InstanceId, device, fstype, path)
      WHERE AutoScalingGroupName = '${var.asg_name}'
        AND path = '/'
    EOT
  }

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_host_volume_usage_critical" {
  count               = var.asg_name != null ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-ecs-host-volume-usage-critical"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 85
  treat_missing_data  = "missing"

  metric_query {
    id          = "root_volume_usage"
    label       = "Highest root volume usage (%)"
    return_data = true
    period      = 300

    expression = <<-EOT
      SELECT MAX(disk_used_percent)
      FROM SCHEMA(CWAgent, AutoScalingGroupName, InstanceId, device, fstype, path)
      WHERE AutoScalingGroupName = '${var.asg_name}'
        AND path = '/'
    EOT
  }

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_host_cpu_warning" {
  count = var.asg_name != null ? 1 : 0

  alarm_name          = "${var.name}-${var.env_name}-ecs-host-cpu-warning"
  alarm_description   = "ECS EC2 host CPU utilization crossed 70%"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "cpu_usage"
    label       = "Highest ECS host CPU utilization (%)"
    return_data = true
    period      = 300

    expression = <<-EOT
      SELECT MAX(CPUUtilization)
      FROM SCHEMA("AWS/EC2", AutoScalingGroupName, InstanceId)
      WHERE AutoScalingGroupName = '${var.asg_name}'
    EOT
  }

  tags = merge(var.tags, { app = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_host_cpu_critical" {
  count = var.asg_name != null ? 1 : 0

  alarm_name          = "${var.name}-${var.env_name}-ecs-host-cpu-critical"
  alarm_description   = "ECS EC2 host CPU utilization crossed 85%"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 85
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "cpu_usage"
    label       = "Highest ECS host CPU utilization (%)"
    return_data = true
    period      = 300

    expression = <<-EOT
      SELECT MAX(CPUUtilization)
      FROM SCHEMA("AWS/EC2", AutoScalingGroupName, InstanceId)
      WHERE AutoScalingGroupName = '${var.asg_name}'
    EOT
  }

  tags = merge(var.tags, { app = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_host_memory_warning" {
  count = var.asg_name != null ? 1 : 0

  alarm_name          = "${var.name}-${var.env_name}-ecs-host-memory-warning"
  alarm_description   = "ECS EC2 host memory utilization crossed 75%"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 75
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "memory_usage"
    label       = "Highest ECS host memory utilization (%)"
    return_data = true
    period      = 300

    expression = <<-EOT
      SELECT MAX(mem_used_percent)
      FROM SCHEMA(CWAgent, AutoScalingGroupName, InstanceId)
      WHERE AutoScalingGroupName = '${var.asg_name}'
    EOT
  }

  tags = merge(var.tags, { app = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_host_memory_critical" {
  count = var.asg_name != null ? 1 : 0

  alarm_name          = "${var.name}-${var.env_name}-ecs-host-memory-critical"
  alarm_description   = "ECS EC2 host memory utilization crossed 85%"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 85
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "memory_usage"
    label       = "Highest ECS host memory utilization (%)"
    return_data = true
    period      = 300

    expression = <<-EOT
      SELECT MAX(mem_used_percent)
      FROM SCHEMA(CWAgent, AutoScalingGroupName, InstanceId)
      WHERE AutoScalingGroupName = '${var.asg_name}'
    EOT
  }

  tags = merge(var.tags, { app = var.name })
}

resource "aws_cloudwatch_metric_alarm" "ecs_desired-task-count-warning" {
  alarm_name          = "${var.name}-${var.env_name}-desired-task-count-warning"
  alarm_description   = "ECS service tasks below desired amount"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60
  comparison_operator = "LessThanThreshold"
  threshold           = var.desired_count
  treat_missing_data  = "missing"
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  statistic           = "Minimum"

  dimensions = {
    ServiceName = "${var.env_name}-${var.name}"
    ClusterName = local.cluster_name
  }

  tags = merge(var.tags, { "app" = var.name })
}

######################################
###           ALB Alarms           ###
######################################
resource "aws_cloudwatch_metric_alarm" "alb_response_time_critical" {
  count               = var.microservice_lb != null ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-response-time-critical"
  alarm_description   = "Average response time for the `${var.name}` service exceeded 5 seconds."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Average"
  metric_name         = "TargetResponseTime"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  evaluation_periods  = 1
  period              = 300
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  dimensions = {
    LoadBalancer = var.frontend_lb_arn_suffix
    TargetGroup  = aws_lb_target_group.frontend[0].arn_suffix
  }

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_metric_alarm" "alb_response_code_5xx_warning" {
  count               = var.microservice_lb != null ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-5xx-response-warning"
  alarm_description   = "The `${var.name}` service responded with 5xx errors."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  metric_name         = "HTTPCode_Target_5XX_Count"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  dimensions = {
    LoadBalancer = var.frontend_lb_arn_suffix
    TargetGroup  = aws_lb_target_group.frontend[0].arn_suffix
  }

  tags = merge(var.tags, { "app" = var.name })
}

resource "aws_cloudwatch_metric_alarm" "alb_response_code_5xx_critical" {
  count               = var.microservice_lb != null ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-5xx-response-critical"
  alarm_description   = "The `${var.name}` service responded with 5xx errors at an elevated rate (over 10/minute)."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  metric_name         = "HTTPCode_Target_5XX_Count"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  dimensions = {
    LoadBalancer = var.frontend_lb_arn_suffix
    TargetGroup  = aws_lb_target_group.frontend[0].arn_suffix
  }

  tags = merge(var.tags, { "app" = var.name })
}
