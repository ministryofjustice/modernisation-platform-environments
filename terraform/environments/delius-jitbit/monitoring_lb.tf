resource "aws_cloudwatch_metric_alarm" "lb_high_5XX_count" {
  alarm_name                = "${local.application_name}-lb-5XX-count--critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "HTTPCode_ELB_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "10"
  alarm_description         = "This alarm monitors lb 5XX count"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions                = [aws_sns_topic.jitbit_alerting.arn]
  treat_missing_data        = "missing"
  dimensions = {
    LoadBalancer = aws_lb.external.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_high_4XX_count" {
  alarm_name                = "${local.application_name}-lb-4XX-count--critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "HTTPCode_ELB_4XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "10"
  alarm_description         = "This alarm monitors lb 4XX count"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions                = [aws_sns_topic.jitbit_alerting.arn]
  treat_missing_data        = "missing"
  dimensions = {
    LoadBalancer = aws_lb.external.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_high_target_response_time" {
  alarm_name                = "${local.application_name}-lb-target-response-time--critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "TargetResponseTime"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This alarm monitors lb target response time"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions                = [aws_sns_topic.jitbit_alerting.arn]
  treat_missing_data        = "missing"
  dimensions = {
    LoadBalancer = aws_lb.external.arn
    TargetGroup  = aws_lb_target_group.target_group_fargate.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_high_unhealthy_host_count" {
  alarm_name                = "${local.application_name}-unhealthy-host-count--critical"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "HealthyHostCount"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "0"
  alarm_description         = "This alarm monitors healthy host count"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions                = [aws_sns_topic.jitbit_alerting.arn]
  treat_missing_data        = "missing"
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
    TargetGroup  = aws_lb_target_group.target_group_fargate.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_group_high_4XX_error_rate" {
  alarm_name          = "${local.application_name}-target-group-high-4XX-error-rate--critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Sum of 4XX error responses returned by targets in target group exceeds 1 in given period"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  treat_missing_data  = "missing"
  dimensions = {
    LoadBalancer   = aws_lb.external.arn_suffix
    TargetGroupArn = aws_lb_target_group.target_group_fargate.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_group_high_5XX_error_rate" {
  alarm_name          = "${local.application_name}-target-group-high-5XX-error-rate--critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Sum of 5XX error responses returned by targets in target group exceeds 1 in given period"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  treat_missing_data  = "missing"
  dimensions = {
    LoadBalancer   = aws_lb.external.arn
    TargetGroupArn = aws_lb_target_group.target_group_fargate.arn
  }
}


