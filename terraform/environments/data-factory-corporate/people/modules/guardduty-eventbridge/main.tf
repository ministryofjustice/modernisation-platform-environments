
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

# Match configured GuardDuty scan outcomes for objects in the protected buckets.
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

# Create an SNS topic for scan alerts.
resource "aws_sns_topic" "scan_alerts" {
  name              = "${var.name}-alerts"
  kms_master_key_id = var.kms_key_arn
  tags              = local.common_tags
}

# Give the account owner topic access and allow only the alert rules to publish.
data "aws_iam_policy_document" "scan_alerts" {

  statement {
    sid    = "AllowAccountToManageTopic"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["sns:*"]
    resources = [aws_sns_topic.scan_alerts.arn]
  }

  # Only these two EventBridge rules may publish GuardDuty alerts to the topic.
  statement {
    sid    = "AllowEventBridgeToPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.scan_alerts.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.scan_alerts.arn, aws_cloudwatch_event_rule.plan_alerts.arn]
    }
  }

  # Let Amazon Q subscribe to GuardDuty alerts for the configured Slack channel.
  statement {
    sid    = "AllowChatbotToConsume"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }

    actions   = ["sns:Subscribe", "sns:Receive"]
    resources = [aws_sns_topic.scan_alerts.arn]
  }
}

# Apply the scoped publishing permissions to the alerts topic.
resource "aws_sns_topic_policy" "scan_alerts" {
  arn    = aws_sns_topic.scan_alerts.arn
  policy = data.aws_iam_policy_document.scan_alerts.json
}

# Publish the configured scan results for the protected buckets to SNS.
resource "aws_cloudwatch_event_rule" "scan_alerts" {
  name        = "${var.name}-alerts"
  description = "Report GuardDuty malware findings and unsuccessful S3 object scans."

  event_pattern = jsonencode({
    source        = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Malware Protection Object Scan Result"]
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

# Send matching scan results to SNS in Amazon Q's custom notification format.
resource "aws_cloudwatch_event_target" "scan_alerts" {
  rule      = aws_cloudwatch_event_rule.scan_alerts.name
  target_id = "guardduty-scan-alerts"
  arn       = aws_sns_topic.scan_alerts.arn

  # Amazon Q Developer in chat applications expects this custom notification schema.
  input_transformer {
    input_paths = {
      bucket = "$.detail.s3ObjectDetails.bucketName"
      key    = "$.detail.s3ObjectDetails.objectKey"
      result = "$.detail.scanResultDetails.scanResultStatus"
    }
    input_template = <<-EOF
      {"version":"1.0","source":"custom","content":{"description":"GuardDuty S3 malware scan: <result> for s3://<bucket>/<key>. Review the GuardDuty scan result and quarantine status."}}
    EOF
  }

  depends_on = [aws_sns_topic_policy.scan_alerts]
}

# Plan warnings and errors can prevent scanning before any object result is emitted.
resource "aws_cloudwatch_event_rule" "plan_alerts" {
  name        = "${var.name}-plan-alerts"
  description = "Report GuardDuty malware protection plan warnings and errors."

  event_pattern = jsonencode({
    source = ["aws.guardduty"]
    "detail-type" = [
      "GuardDuty Malware Protection Resource Status Warning",
      "GuardDuty Malware Protection Resource Status Error"
    ]
    detail = {
      s3BucketDetails = {
        bucketName = var.bucket_names
      }
    }
  })

  tags = local.common_tags
}

# Send plan health warnings and errors to the same SNS alerts topic.
resource "aws_cloudwatch_event_target" "plan_alerts" {
  rule      = aws_cloudwatch_event_rule.plan_alerts.name
  target_id = "guardduty-plan-alerts"
  arn       = aws_sns_topic.scan_alerts.arn

  input_transformer {
    input_paths = {
      bucket = "$.detail.s3BucketDetails.bucketName"
      status = "$.detail.resourceStatus"
    }
    input_template = <<-EOF
      {"version":"1.0","source":"custom","content":{"description":"GuardDuty S3 malware protection plan: <status> for bucket <bucket>. Check the protection plan status and its reasons."}}
    EOF
  }

  depends_on = [aws_sns_topic_policy.scan_alerts]
}

