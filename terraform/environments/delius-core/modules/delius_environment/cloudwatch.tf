# Log group Policy to enable EventBridge to write events to log groups
resource "aws_cloudwatch_log_resource_policy" "log_group_policy" {
  policy_name = "${var.env_name}-eventbridge-to-logs-policy"
  policy_document = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
      },
      "Action" : [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource" : "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.id}:log-group:/metrics/${var.env_name}/*"
    }]
  })
}

######################################
###           ALB Alarms           ###
######################################
resource "aws_cloudwatch_metric_alarm" "alb_client_tls_negotiation_error_warning" {
  alarm_name          = "weblogic-${var.env_name}-client-tls-negotiation-error-warning"
  alarm_description   = "The ${var.env_name} Weblogic ALB experienced more than 50 client TLS negotiation errors."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  metric_name         = "ClientTLSNegotiationErrorCount"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 50
  treat_missing_data  = "notBreaching"
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [aws_sns_topic.delius_core_alarms.arn]
  ok_actions          = [aws_sns_topic.delius_core_alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.delius_core_frontend.arn_suffix
  }

  tags = merge(var.tags, { "Name" = local.alb_name })
}

resource "aws_cloudwatch_metric_alarm" "alb_4xx_warning" {
  alarm_name          = "weblogic-${var.env_name}-alb-4xx-warning"
  alarm_description   = "The ${var.env_name} Weblogic ALB experienced more than 50 4xx errors."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  metric_name         = "HTTPCode_ELB_4XX_Count"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 50
  treat_missing_data  = "notBreaching"
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [aws_sns_topic.delius_core_alarms.arn]
  ok_actions          = [aws_sns_topic.delius_core_alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.delius_core_frontend.arn_suffix
  }

  tags = merge(var.tags, { "Name" = local.alb_name })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_warning" {
  alarm_name          = "weblogic-${var.env_name}-alb-5xx-warning"
  alarm_description   = "The ${var.env_name} Weblogic ALB experienced 5xx errors."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [aws_sns_topic.delius_core_alarms.arn]
  ok_actions          = [aws_sns_topic.delius_core_alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.delius_core_frontend.arn_suffix
  }

  tags = merge(var.tags, { "Name" = local.alb_name })
}

resource "aws_cloudwatch_metric_alarm" "alb_rejected_connections_warning" {
  alarm_name          = "weblogic-${var.env_name}-alb-rejected-connections-warning"
  alarm_description   = "The ${var.env_name} Weblogic ALB rejected connections."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  metric_name         = "RejectedConnectionCount"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [aws_sns_topic.delius_core_alarms.arn]
  ok_actions          = [aws_sns_topic.delius_core_alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.delius_core_frontend.arn_suffix
  }

  tags = merge(var.tags, { "Name" = local.alb_name })
}