
# GuardDuty creates its own internal EventBridge rule to start scans.

# This file creates an Eventbridge rule to trigger the quarantine Lambda when 
# GuardDuty Malware Protection reports an unsafe or failed S3 object scan.

# - listen for GuardDuty scan result events
# - match unsafe or failed scan outcomes
# - invoke the quarantine Lambda
#
# GuardDuty publishes scan results to the default EventBridge bus with:
#
# detail-type = GuardDuty Malware Protection Object Scan Result

# https://docs.aws.amazon.com/guardduty/latest/ug/monitor-with-eventbridge-s3-malware-protection.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule

resource "aws_cloudwatch_event_rule" "guardduty_quarantine" {
  name        = var.name
  description = "Invoke quarantine Lambda when GuardDuty reports an unsafe or failed S3 object scan."

  event_pattern = jsonencode({
    source = [
      "aws.guardduty"
    ]

    "detail-type" = [
      "GuardDuty Malware Protection Object Scan Result"
    ]

    detail = {
      s3ObjectDetails = {
        bucketName = var.bucket_names
      }

      scanResultDetails = {
        scanResultStatus = var.scan_result_statuses
      }
    }
  })

  tags = local.common_tags
}

# Give Lambda as target for the EventBridge rule.
resource "aws_cloudwatch_event_target" "guardduty_quarantine_lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_quarantine.name
  target_id = var.target_lambda_name
  arn       = var.target_lambda_arn
}

# Lambda needs a policy resource to allow EventBridge to invoke it.
resource "aws_lambda_permission" "allow_eventbridge_quarantine" {
  statement_id  = "AllowExecutionFromEventBridgeGuardDutyQuarantine"
  action        = "lambda:InvokeFunction"
  function_name = var.target_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_quarantine.arn
}

