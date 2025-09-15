# 🔹 Alarm for InvocationFailureCount (all Lambdas)
resource "aws_cloudwatch_metric_alarm" "lambda_failures" {
  for_each = {
    "cwa-extract"       = { namespace = "HUB20-CWA-NS",        servicename = "cwa-extract-service" }
    "cwa-file-transfer" = { namespace = "HUB20-CWA-NS",        servicename = "cwa-file-transfer-service" }
    "cwa-sns"           = { namespace = "HUB20-CWA-NS",        servicename = "cwa-sns-service" }
    "cclf-load"         = { namespace = "HUB20-CCLF-NS",       servicename = "cclf-load-service" }
    "ccr-load"          = { namespace = "HUB20-CCR-NS",        servicename = "ccr-load-service" }
    "maat-load"         = { namespace = "HUB20-MAAT-NS",       servicename = "maat-load-service" }
    "ccms-load"         = { namespace = "HUB20-CCMS-NS",       servicename = "ccms-load-service" }
    "purge-lambda"      = { namespace = "HUB20-PURGE-DATA-NS", servicename = "purge-lambda-service" }
  }

  alarm_name          = "${each.value.servicename}-${local.environment}-InvocationFailureCount-Alarm"
  alarm_description   = "Alarm when ${each.value.servicename} lambda reports failures in ${local.environment}"
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "m1"
    expression  = "SUM(SEARCH('${each.value.namespace} InvocationFailureCount', 'Sum', 300))"
    label       = "AllFailures"
    return_data = true
  }

  alarm_actions = [aws_sns_topic.hub2_alerts.arn]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-lambda-invocation-failure-alarm"
    }
  )
}