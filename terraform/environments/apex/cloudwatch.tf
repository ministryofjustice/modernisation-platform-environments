resource "aws_cloudwatch_metric_alarm" "database_status" {

  alarm_name          = "${local.application_name}-${local.environment}-ec2-database-status-check-failure-alarm"
  alarm_description   = "If a status check failure occurs on the EC2 database, please investigate"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.apex_db_instance.id
  }
  evaluation_periods = "10"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_status_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ec2-database-status-check-failure-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {

  alarm_name          = "${local.application_name}-${local.environment}-ec2-database-CPU-high-threshold-alarm"
  alarm_description   = "If the CPU exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.apex_db_instance.id
  }
  evaluation_periods = "10"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].database_cpu_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ec2-database-CPU-high-threshold-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_oracle_alerts" {

  alarm_name          = "${local.application_name}-${local.environment}-oracle-alerts-log-errors"
  alarm_description   = "Errors Detected in Oracle Alerts Log, please check the log group ${aws_cloudwatch_log_group.database.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.database.name
  namespace           = aws_cloudwatch_log_metric_filter.database.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = local.application_data.accounts[local.environment].database_oracle_alerts_alarm_threshold
  alarm_actions       = [aws_sns_topic.apex.arn]
  ok_actions          = [aws_sns_topic.apex.arn]
  treat_missing_data  = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-oracle-alerts-log-errors"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_pmon_status" {

  alarm_name          = "${local.application_name}-${local.environment}-oracle-alerts-pmon-status"
  alarm_description   = "Database Down indicator found in the pmon logs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.pmon_status.name
  namespace           = aws_cloudwatch_log_metric_filter.pmon_status.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = local.application_data.accounts[local.environment].database_pmon_status_alarm_threshold
  alarm_actions       = [aws_sns_topic.apex.arn]
  ok_actions          = [aws_sns_topic.apex.arn]
  treat_missing_data  = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-oracle-alerts-pmon-status"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {

  alarm_name          = "${local.application_name}-${local.environment}-ecs-cpu-high-threshold-alarm"
  alarm_description   = "If the CPU exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    ClusterName = module.apex-ecs.ecs_cluster_name
  }
  evaluation_periods = "5"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].ecs_cpu_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ecs-cpu-high-threshold-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {

  alarm_name          = "${local.application_name}-${local.environment}-ecs-memory-high-threshold-alarm"
  alarm_description   = "If the memory exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    ClusterName = module.apex-ecs.ecs_cluster_name
  }
  evaluation_periods = "5"
  metric_name        = "MemoryUtilization"
  namespace          = "AWS/ECS"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].ecs_memory_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ecs-memory-high-threshold-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu" {

  alarm_name          = "${local.application_name}-${local.environment}-asg-cpu-high-threshold-alarm"
  alarm_description   = "If the Auto-Scaling Group CPU exceeds the predefined threshold, this alarm will trigger. Please investigate."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    AutoScalingGroupName = module.apex-ecs.ec2_autoscaling_group.name
  }
  evaluation_periods = "5"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].asg_cpu_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-asg-cpu-high-threshold-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "asg_status" {

  alarm_name          = "${local.application_name}-${local.environment}-asg-status-check-failure-alarm"
  alarm_description   = "If a status check failure occurs on the Auto-Scaling Group, please investigate"
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    AutoScalingGroupName = module.apex-ecs.ec2_autoscaling_group.name
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].asg_status_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-ec2-database-status-check-failure-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_response_time" {

  alarm_name          = "${local.application_name}-${local.environment}-alb-target-response-time-alarm"
  alarm_description   = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = module.alb.load_balancer_arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "TargetResponseTime"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  extended_statistic = "p99"
  threshold          = local.application_data.accounts[local.environment].alb_response_time_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alb-target-response-time-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_response_time_max" {

  alarm_name          = "${local.application_name}-${local.environment}-alb-target-response-time-maximum-alarm"
  alarm_description   = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = module.alb.load_balancer_arn_suffix
  }
  evaluation_periods = "1"
  metric_name        = "TargetResponseTime"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Maximum"
  threshold          = local.application_data.accounts[local.environment].alb_response_time_max_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alb-target-response-time-maximum-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {

  alarm_name          = "${local.application_name}-${local.environment}-alb-unhealthy-hosts-alarm"
  alarm_description   = "The unhealthy hosts alarm triggers if your load balancer recognises there is an unhealthy host and has been there for over x minutes."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = module.alb.load_balancer_arn_suffix
    TargetGroup  = module.alb.target_group_arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "UnHealthyHostCount"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Average"
  threshold          = local.application_data.accounts[local.environment].alb_unhealthy_hosts_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alb-unhealthy-hosts-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_rejected_connections" {

  alarm_name          = "${local.application_name}-${local.environment}-alb-rejected-connections-count-alarm"
  alarm_description   = "There is no surge queue on ALB's. Alert triggers in ALB rejects too many requests, usually due to backend being busy."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = module.alb.load_balancer_arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "RejectedConnectionCount"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].alb_rejected_connections_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alb-rejected-connections-count-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {

  alarm_name          = "${local.application_name}-${local.environment}-alb-target-5xx-error-alarm"
  alarm_description   = "The number of HTTP 5XX response codes generated by the targets is over the threshold. This does not include any response codes generated by the load balancer."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = module.alb.load_balancer_arn_suffix
  }
  evaluation_periods  = "5"
  datapoints_to_alarm = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = local.application_data.accounts[local.environment].alb_target_5xx_alarm_threshold
  alarm_actions       = [aws_sns_topic.apex.arn]
  ok_actions          = [aws_sns_topic.apex.arn]
  treat_missing_data  = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alb-target-5xx-error-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_elb_5xx" {

  alarm_name          = "${local.application_name}-${local.environment}-alb-elb-5xx-error-alarm"
  alarm_description   = "The number of HTTP 5XX server error codes that originate from the load balancer is over the threshold. This count does not include any response codes generated by the targets."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = module.alb.load_balancer_arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "HTTPCode_ELB_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].alb_elb_5xx_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alb-elb-5xx-error-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_target_4xx" {

  alarm_name          = "${local.application_name}-${local.environment}-alb-target-4xx-error-alarm"
  alarm_description   = "The number of HTTP 4XX response codes generated by the targets is over the threshold. This does not include any response codes generated by the load balancer."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = module.alb.load_balancer_arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "HTTPCode_Target_4XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].alb_target_4xx_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alb-target-4xx-error-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_elb_4xx" {

  alarm_name          = "${local.application_name}-${local.environment}-alb-elb-4xx-error-alarm"
  alarm_description   = "The number of HTTP 4XX server error codes that originate from the load balancer is over the threshold. This count does not include any response codes generated by the targets."
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = module.alb.load_balancer_arn_suffix
  }
  evaluation_periods = "5"
  metric_name        = "HTTPCode_ELB_4XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = local.application_data.accounts[local.environment].alb_elb_4xx_alarm_threshold
  alarm_actions      = [aws_sns_topic.apex.arn]
  ok_actions         = [aws_sns_topic.apex.arn]
  treat_missing_data = "notBreaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alb-elb-4xx-error-alarm"
    }
  )
}

################################
### CloudWatch Dashboard
################################

data "template_file" "dashboard" {
  template = file("${path.module}/dashboard.tpl")

  vars = {
    aws_region              = "eu-west-2"
    alb_elb_5xx_alarm       = aws_cloudwatch_metric_alarm.alb_elb_5xx.arn
    alb_elb_4xx_alarm       = aws_cloudwatch_metric_alarm.alb_elb_4xx.arn
    alb_response_time_alarm = aws_cloudwatch_metric_alarm.alb_response_time.arn
    ecs_cpu_alarm           = aws_cloudwatch_metric_alarm.ecs_cpu.arn
    ecs_memory_alarm        = aws_cloudwatch_metric_alarm.ecs_memory.arn

  }
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${upper(local.application_name)}-Monitoring-Dashboard"
  dashboard_body = data.template_file.dashboard.rendered
}





