# #### Secret for support email address ###
# resource "aws_secretsmanager_secret" "support_email_account" {
#   name                    = "support_email_account"
#   description             = "email address of the support account for cw alerts"
#   recovery_window_in_days = local.is-production ? 30 : 0
# }

# # Use a default dummy address just for creation. Will require to be populated manually.
# resource "aws_secretsmanager_secret_version" "support_email_account" {
#   secret_id     = aws_secretsmanager_secret.support_email_account.id
#   secret_string = "default@email.com"
#   lifecycle {
#     ignore_changes = [secret_string]
#   }
# }

resource "aws_secretsmanager_secret" "alerts_subscription_email" {
  name                    = "alerts_subscription_email"
  description             = "E-mail address of the Slack channel for alerts"
  recovery_window_in_days = local.is-production ? 30 : 0
}

resource "aws_secretsmanager_secret_version" "alerts_subscription_email" {
  secret_id     = aws_secretsmanager_secret.alerts_subscription_email.id
  secret_string = local.application_data.accounts[local.environment].alerts_subscription_email
}

resource "aws_sns_topic" "cw_alerts" {
  name              = "ccms-ebs-ec2-alerts"
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = "${local.application_name}-ec2-alerts" }
  )
}

data "aws_iam_policy_document" "sns_topic_policy_ec2cw" {
  # Owner full access
  statement {
    sid     = "AllowOwnerFullAccess"
    effect  = "Allow"
    actions = ["sns:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    resources = [aws_sns_topic.cw_alerts.arn]
  }

  # CloudWatch / CloudWatch Alarms can publish
  statement {
    sid     = "AllowCloudWatchToPublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    resources = [aws_sns_topic.cw_alerts.arn]
  }

  # EventBridge GuardDuty rule can publish
  statement {
    sid     = "AllowEventBridgeGuardDutyToPublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.cw_alerts.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.guardduty_all_findings.arn]
    }
  }
}

resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.cw_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy_ec2cw.json
}

resource "aws_sns_topic" "s3_topic" {
  name              = "s3-event-notification-topic"
  policy            = data.aws_iam_policy_document.s3_topic_policy.json
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = "s3-event-notification-topic" }
  )
}

# S3 SNS -> Lambda (Slack) instead of email
resource "aws_sns_topic_subscription" "s3_subscription" {
  topic_arn = aws_sns_topic.s3_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudwatch_sns.arn
}

resource "aws_lambda_permission" "allow_s3_sns_invoke" {
  statement_id  = "AllowExecutionFromS3SNSTopic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.s3_topic.arn
}

resource "aws_sns_topic" "ddos_alarm" {
  name              = format("%s_ddos_alarm", local.application_name)
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = format("%s_ddos_alarm", local.application_name) }
  )
}

# DDoS SNS -> Lambda (Slack) instead of email
resource "aws_sns_topic_subscription" "ddos_subscription" {
  topic_arn = aws_sns_topic.ddos_alarm.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudwatch_sns.arn
}

resource "aws_lambda_permission" "allow_ddos_sns_invoke" {
  statement_id  = "AllowExecutionFromDDoSSNSTopic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ddos_alarm.arn
}

resource "aws_sns_topic" "guardduty_alerts" {
  name              = "${local.application_name}-guardduty-alerts"
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = "${local.application_name}-guardduty-alerts" }
  )
}
