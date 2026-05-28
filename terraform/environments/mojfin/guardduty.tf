# ---------------------------------------------
# GuardDuty Findings → Slack Alerting
# ---------------------------------------------

# KMS key for encrypting the GuardDuty SNS topic
resource "aws_kms_key" "cloudwatch_sns_alerts_key" {
  description             = "KMS Key for CloudWatch SNS Alerts Encryption"
  deletion_window_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-cloudwatch-sns-alerts-kms-key", local.application_name, local.environment)) }
  )
}

resource "aws_kms_alias" "cloudwatch_sns_alerts_key" {
  name          = "alias/${local.application_name}-${local.environment}-cloudwatch-sns-alerts-key"
  target_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
}

resource "aws_kms_key_policy" "cloudwatch_sns_alerts_key" {
  key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  policy = data.aws_iam_policy_document.cloudwatch_sns_encryption.json
}

data "aws_iam_policy_document" "cloudwatch_sns_encryption" {
  version = "2012-10-17"
  statement {
    sid    = "AllowCloudWatchSNSUseOfTheKey"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
        "events.amazonaws.com"
      ]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowAccountAdmins"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

# SNS topic for GuardDuty findings
resource "aws_sns_topic" "guardduty_alerts" {
  name = "${local.application_name}-guardduty-alerts"
  delivery_policy = <<EOF
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

data "aws_iam_policy_document" "guardduty_alerting_sns" {
  version = "2012-10-17"
  statement {
    sid    = "EventsAllowPublishSnsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.guardduty_alerts.arn
    ]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
      ]
    }
  }
}

resource "aws_sns_topic_policy" "guardduty_default" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.guardduty_alerting_sns.json
}

# EventBridge rule to capture GuardDuty findings
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

# IAM role for the GuardDuty Slack notify Lambda
resource "aws_iam_role" "lambda_guardduty_sns_role" {
  name = "${local.application_name}-${local.environment}-lambda-guardduty-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-lambda-guardduty-sns-role"
  })
}

resource "aws_iam_role_policy" "lambda_guardduty_sns_policy" {
  name = "${local.application_name}-${local.environment}-lambda-guardduty-sns-policy"
  role = aws_iam_role.lambda_guardduty_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = [aws_secretsmanager_secret.mojfin_secret.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.guardduty_slack_notify.function_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = [aws_kms_key.cloudwatch_sns_alerts_key.arn]
      }
    ]
  })
}

# Lambda Layer loaded from the mojfin shared S3 bucket
# Note: the zip file must be manually uploaded to the bucket at the path below
# See: https://dsdmoj.atlassian.net/wiki/spaces/LDD/pages/5975606239/Build+Layered+Function+for+Lambda
resource "aws_lambda_layer_version" "guardduty_sns_layer" {
  layer_name               = "${local.application_name}-${local.environment}-guardduty-sns-layer"
  s3_key                   = "lambda_delivery/cloudwatch_sns_layer/layerV1.zip"
  s3_bucket                = module.s3-bucket-shared.bucket.id
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["x86_64"]
  description              = "Lambda Layer for ${local.application_name} GuardDuty SNS Alerts Integration"
}

data "archive_file" "guardduty_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/cloudwatch_alarm_slack_integration"
  output_path = "${path.module}/lambda/cloudwatch_alarm_slack_integration.zip"
}

resource "aws_lambda_function" "guardduty_slack_notify" {
  filename         = data.archive_file.guardduty_lambda_zip.output_path
  source_code_hash = base64sha256(join("", local.lambda_source_hashes))
  function_name    = "${local.application_name}-${local.environment}-guardduty-slack-notify"
  role             = aws_iam_role.lambda_guardduty_sns_role.arn
  handler          = "lambda_function.lambda_handler"
  layers           = [aws_lambda_layer_version.guardduty_sns_layer.arn]
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.mojfin_secret.name
    }
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-guardduty-slack-notify"
  })
}

resource "aws_lambda_permission" "guardduty_lambda_permission" {
  statement_id  = "AllowExecutionFromGuardDutySNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_slack_notify.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.guardduty_alerts.arn
}

resource "aws_sns_topic_subscription" "guardduty_lambda_subscription" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.guardduty_slack_notify.arn
}

# ---------------------------------------------
# GuardDuty Malware Protection - S3 bucket scan
# ---------------------------------------------

data "aws_iam_role" "guardduty_s3_malware_role" {
  name = "GuardDutyS3MalwareProtectionRole"
}

resource "aws_guardduty_malware_protection_plan" "mojfin_s3_shared" {
  role = data.aws_iam_role.guardduty_s3_malware_role.arn

  protected_resource {
    s3_bucket {
      bucket_name = module.s3-bucket-shared.bucket.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-guardduty-mpp", local.application_name, local.environment)) }
  )

  depends_on = [module.s3-bucket-shared]
}

resource "aws_guardduty_malware_protection_plan" "mojfin_s3_rds_oracle" {
  role = data.aws_iam_role.guardduty_s3_malware_role.arn

  protected_resource {
    s3_bucket {
      bucket_name = aws_s3_bucket.mojfin_rds_oracle.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-guardduty-mpp", local.application_name, local.environment)) }
  )

  depends_on = [aws_s3_bucket.mojfin_rds_oracle]
}

moved {
  from = aws_guardduty_malware_protection_plan.mojfin_s3_malware_plan
  to   = aws_guardduty_malware_protection_plan.mojfin_s3_shared
}
