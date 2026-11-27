locals {
  gc_pdc_enrolment_delivery_alarm_names = {
    for name in keys(local.gc_pdc_enrolment_accounts) : name => "pdc-enrol-${name}-delivery-failed"
  }
}

resource "aws_cloudwatch_event_rule" "gc_pdc_enrolment" {
  for_each = local.gc_pdc_enrolment_accounts

  name                = "pdc-enrol-${each.key}"
  description         = "Check PDC rotation readiness for ${each.key}"
  schedule_expression = "rate(1 hour)"

  depends_on = [terraform_data.gc_pdc_bootstrap]
}

resource "aws_lambda_permission" "gc_pdc_enrolment_tick" {
  for_each = length(local.gc_pdc_enrolment_accounts) > 0 ? local.gc_pdc_rotator_deployments : {}

  action         = "lambda:InvokeFunction"
  function_name  = module.grafana_pdc_token_rotator["this"].lambda_function_arn
  principal      = "events.amazonaws.com"
  source_arn     = "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/pdc-enrol-*"
  source_account = data.aws_caller_identity.current.account_id

  depends_on = [aws_cloudwatch_event_rule.gc_pdc_enrolment]
}

resource "aws_lambda_permission" "gc_pdc_enrolment_rotation" {
  for_each = length(local.gc_pdc_enrolment_accounts) > 0 ? local.gc_pdc_rotator_deployments : {}

  action         = "lambda:InvokeFunction"
  function_name  = module.grafana_pdc_token_rotator["this"].lambda_function_arn
  principal      = "secretsmanager.amazonaws.com"
  source_arn     = local.gc_pdc_secret_arn_pattern
  source_account = data.aws_caller_identity.current.account_id

  depends_on = [terraform_data.gc_pdc_bootstrap]
}

resource "aws_cloudwatch_event_target" "gc_pdc_enrolment" {
  for_each = aws_cloudwatch_event_rule.gc_pdc_enrolment

  rule      = each.value.name
  target_id = "enrol-rotation"
  arn       = module.grafana_pdc_token_rotator["this"].lambda_function_arn
  input = jsonencode({
    Step     = "enrolRotation"
    SecretId = aws_secretsmanager_secret.gc_pdc_token[each.key].arn
  })

  depends_on = [aws_lambda_permission.gc_pdc_enrolment_tick, aws_lambda_permission.gc_pdc_enrolment_rotation]
}

# Delivery failures never reach Lambda, so the rotator's Errors alarm cannot see them.
resource "aws_cloudwatch_metric_alarm" "gc_pdc_enrolment_delivery" {
  for_each = aws_cloudwatch_event_rule.gc_pdc_enrolment

  alarm_name          = local.gc_pdc_enrolment_delivery_alarm_names[each.key]
  alarm_description   = "EventBridge failed to deliver the PDC enrolment tick for ${each.key}"
  namespace           = "AWS/Events"
  metric_name         = "FailedInvocations"
  dimensions          = { RuleName = each.value.name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.gc_pdc_failure_alerts["this"].arn]
}
