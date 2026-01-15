resource "aws_iam_role" "lambda_certificate_monitor_role" {
  name = "${local.application_name}-${local.environment}-acm_certificate_monitor_role"

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
    Name = "${local.application_name}-${local.environment}-certificate-monitor"
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.application_name}-${local.environment}-acm_certificate_monitor_policy"
  role = aws_iam_role.lambda_certificate_monitor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "securityhub:BatchImportFindings",
          "securityhub:BatchUpdateFindings",
          "securityhub:DescribeHub"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [aws_sns_topic.certificate_expiration_alerts.arn]
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

resource "aws_sns_topic" "certificate_expiration_alerts" {
  name              = "${local.application_name}-${local.environment}-acm-certificate-alerts"
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-certificate-monitor"
  })
}

resource "aws_sns_topic_subscription" "certificate_monitor_email" {
  topic_arn = aws_sns_topic.certificate_expiration_alerts.arn
  protocol  = "email"
  endpoint  = local.application_data.accounts[local.environment].certificate_monitor_email
}

resource "aws_lambda_function" "certificate_monitor" {
  filename         = "./lambda/certificate_monitor.zip"
  source_code_hash = filebase64sha256("./lambda/certificate_monitor.zip")
  function_name    = "${local.application_name}-${local.environment}-certificate-monitor"
  role             = aws_iam_role.lambda_certificate_monitor_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      EXPIRY_DAYS         = local.application_data.accounts[local.environment].certificate_expiry_days
      SECURITY_HUB_REGION = "eu-west-2"
      SNS_TOPIC_ARN       = aws_sns_topic.certificate_expiration_alerts.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-certificate-monitor"
  })
}

resource "aws_cloudwatch_event_rule" "acm_events" {
  name        = "${local.application_name}-${local.environment}-acm-certificate-events"
  description = "Capture ACM certificate events"

  event_pattern = jsonencode({
    source = ["aws.acm"]
    detail-type = [
      "ACM Certificate Approaching Expiration",
      "ACM Certificate Expired"
    ]
  })
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-certificate-monitor"
  })
}

resource "aws_cloudwatch_event_target" "lambda_certificate_monitor" {
  rule      = aws_cloudwatch_event_rule.acm_events.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.certificate_monitor.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.certificate_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.acm_events.arn
}

output "sns_topic_arn_certificate_expiration_alerts" {
  description = "ARN of the SNS topic for certificate alerts"
  value       = aws_sns_topic.certificate_expiration_alerts.arn
}

output "lambda_function_arn_certificate_monitor" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.certificate_monitor.arn
}
