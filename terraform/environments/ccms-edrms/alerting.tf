resource "aws_cloudwatch_event_rule" "guardduty" {
  name = "${local.application_name}-guardduty-findings"
  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule = aws_cloudwatch_event_rule.guardduty.name
  arn  = aws_sns_topic.guardduty_alerts.arn
}

resource "aws_cloudwatch_event_rule" "certificate_expiration_warning" {
  name = "${local.application_name}-certificate-expiration-warning"
  event_pattern = jsonencode({
    "source" : ["aws.acm"],
    "detail-type" : ["ACM Certificate Approaching Expiration", "ACM Certificate Expired", "ACM Certificate Renewal Failed"]
  })
}

resource "aws_cloudwatch_event_target" "certificate_expiration_warning_to_sns" {
  rule = aws_cloudwatch_event_rule.certificate_expiration_warning.name
  target_id = "certificate-expiration-warning-target"
  arn  = aws_lambda_function.cloudwatch_sns.arn
}
