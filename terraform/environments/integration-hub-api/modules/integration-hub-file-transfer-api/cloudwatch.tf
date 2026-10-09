module "api_access_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.3"

  name              = "/aws/apigateway/${local.resource_name_prefix}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = 30
  tags              = var.tags
}

module "cloudwatch_api_gateway_5xx" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.3"

  alarm_name          = "${local.resource_name_prefix}-api-gateway-5xx"
  alarm_description   = "Integration Hub API Gateway is returning server errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority

  dimensions = {
    ApiId = module.api_gateway.api_id
    Stage = aws_apigatewayv2_stage.default.name
  }

  tags = var.tags
}

module "cloudwatch_api_gateway_latency" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.3"

  alarm_name          = "${local.resource_name_prefix}-api-gateway-latency"
  alarm_description   = "Integration Hub API Gateway latency is above the expected threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.observability_configuration.api_gateway_latency_evaluation_periods
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = local.observability_configuration.api_gateway_latency_threshold_ms
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_low_priority
  ok_actions          = local.cloudwatch_alarm_actions_low_priority

  dimensions = {
    ApiId = module.api_gateway.api_id
    Stage = aws_apigatewayv2_stage.default.name
  }

  tags = var.tags
}

module "cloudwatch_lambda_errors" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.3"

  alarm_name          = "${each.value.alarm_name_prefix}-errors"
  alarm_description   = "${each.value.description} returned one or more errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority
  dimensions          = { FunctionName = each.value.function_name }
  tags                = var.tags
}

module "cloudwatch_lambda_throttles" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.3"

  alarm_name          = "${each.value.alarm_name_prefix}-throttles"
  alarm_description   = "${each.value.description} is throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority
  dimensions          = { FunctionName = each.value.function_name }
  tags                = var.tags
}

module "cloudwatch_lambda_duration" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.3"

  alarm_name          = "${each.value.alarm_name_prefix}-duration"
  alarm_description   = "${each.value.description} duration is above the expected threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.observability_configuration.lambda_duration_evaluation_periods
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = local.observability_configuration.lambda_duration_threshold_ms
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_low_priority
  ok_actions          = local.cloudwatch_alarm_actions_low_priority
  dimensions          = { FunctionName = each.value.function_name }
  tags                = var.tags
}

resource "aws_cloudwatch_dashboard" "api_platform" {
  dashboard_name = "${local.resource_name_prefix}-${var.environment}-overview"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title = "API Gateway Requests and Errors", region = local.region, view = "timeSeries", stacked = false, period = 300
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", module.api_gateway.api_id, "Stage", aws_apigatewayv2_stage.default.name],
            [".", "4xx", ".", ".", ".", ".", { "yAxis" : "right" }],
            [".", "5xx", ".", ".", ".", ".", { "yAxis" : "right" }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title = "API Gateway Latency", region = local.region, view = "timeSeries", stacked = false, period = 300
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", module.api_gateway.api_id, "Stage", aws_apigatewayv2_stage.default.name],
            [".", "IntegrationLatency", ".", ".", ".", "."]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title = "Lambda Errors and Throttles", region = local.region, view = "timeSeries", stacked = false, period = 300
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", module.lambda_upload_ticket.lambda_function_name],
            [".", "Errors", ".", module.lambda_api_authorizer.lambda_function_name],
            [".", "Errors", ".", module.lambda_api_docs.lambda_function_name],
            [".", "Throttles", ".", module.lambda_upload_ticket.lambda_function_name, { "yAxis" : "right" }],
            [".", "Throttles", ".", module.lambda_api_authorizer.lambda_function_name, { "yAxis" : "right" }],
            [".", "Throttles", ".", module.lambda_api_docs.lambda_function_name, { "yAxis" : "right" }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title = "Lambda Duration and Invocations", region = local.region, view = "timeSeries", stacked = false, period = 300
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", module.lambda_upload_ticket.lambda_function_name],
            [".", "Duration", ".", module.lambda_api_authorizer.lambda_function_name],
            [".", "Duration", ".", module.lambda_api_docs.lambda_function_name],
            [".", "Invocations", ".", module.lambda_upload_ticket.lambda_function_name, { "yAxis" : "right" }],
            [".", "Invocations", ".", module.lambda_api_authorizer.lambda_function_name, { "yAxis" : "right" }],
            [".", "Invocations", ".", module.lambda_api_docs.lambda_function_name, { "yAxis" : "right" }]
          ]
        }
      }
    ]
  })
}
