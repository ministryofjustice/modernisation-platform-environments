resource "aws_cloudwatch_metric_alarm" "orchestrator_errors" {
  count = local.create_service ? 1 : 0

  alarm_name          = "${local.application_name}-${local.component_name}-orchestrator-errors"
  alarm_description   = "Benefit orchestrator Lambda errors in a five-minute window"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    FunctionName = module.lambda_benefit_orchestrator[0].lambda_function_name
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  count = local.create_service ? 1 : 0

  alarm_name          = "${local.application_name}-${local.component_name}-api-5xx"
  alarm_description   = "API Gateway server errors in a five-minute window"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    ApiId = aws_apigatewayv2_api.benefit_checker[0].id
  }
  tags = local.tags
}
