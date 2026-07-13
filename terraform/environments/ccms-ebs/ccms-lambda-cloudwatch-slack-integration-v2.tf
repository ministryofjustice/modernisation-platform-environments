resource "aws_iam_role" "lambda_cloudwatch_slack_integration_v2_role" {
  name = "${local.application_name}-${local.environment}-lambda_cloudwatch_slack_integration_v2_role"

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
    Name = "${local.application_name}-${local.environment}-lambda_cloudwatch_slack_integration_v2_role"
  })
}

resource "aws_iam_role_policy" "lambda_cloudwatch_slack_integration_v2_policy" {
  name = "${local.application_name}-${local.environment}-lambda_cloudwatch_slack_integration_v2_role_policy"
  role = aws_iam_role.lambda_cloudwatch_slack_integration_v2_role.id

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
        # Secret now contains slack_channel_webhook, slack_channel_webhook_guardduty, slack_channel_webhook_s3
        Resource = [aws_secretsmanager_secret.ebs_cw_alerts_secrets.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.cloudwatch_slack_integration_v2.function_name}:*"
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

resource "aws_sns_topic_subscription" "lambda_cloudwatch_slack_integration_v2_sns_subscription" {
  topic_arn = aws_sns_topic.cw_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudwatch_slack_integration_v2.arn
}

# Lambda Layer -> requirements.txt for layer function has been generated following process in the link but it is same as
# what has been used for edrms docs exception, also requirements.txt has been added. The zip file for layered function
# have been added in s3 bucket manually. https://dsdmoj.atlassian.net/wiki/spaces/LDD/pages/5975606239/Build+Layered+Function+for+Lambda

resource "aws_lambda_layer_version" "lambda_cloudwatch_slack_integration_v2_layer" {
  # filename                 = "lambda/layerV1.zip"
  layer_name               = "${local.application_name}-${local.environment}-cloudwatch-slack-integration-v2-layer"
  s3_key                   = "lambda_delivery/cloudwatch_sns_layer/layerV2.zip"
  s3_bucket                = aws_s3_bucket.ccms_ebs_shared.bucket
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["x86_64"]
  description              = "Lambda Layer for ${local.application_name} CloudWatch/GuardDuty/S3 SNS Alerts Integration V2"
}

data "archive_file" "lambda_cloudwatch_slack_integration_v2_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/cloudwatch-slack-integration-v2"
  output_path = "${path.module}/lambda/cloudwatch-slack-integration-v2.zip"
}

resource "aws_lambda_function" "cloudwatch_slack_integration_v2" {
  filename         = data.archive_file.lambda_cloudwatch_slack_integration_v2_zip.output_path
  source_code_hash = base64sha256(join("", local.lambda_source_hashes_cloudwatch_slack_integration_v2))
  function_name    = "${local.application_name}-${local.environment}-cloudwatch-slack-integration-v2"
  role             = aws_iam_role.lambda_cloudwatch_slack_integration_v2_role.arn
  handler          = "lambda_function.lambda_handler"
  layers           = [aws_lambda_layer_version.lambda_cloudwatch_slack_integration_v2_layer.arn]
  runtime          = "python3.14"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      # This secret now contains slack_channel_webhook, slack_channel_webhook_guardduty, slack_channel_webhook_s3
      SECRET_NAME = aws_secretsmanager_secret.ebs_cw_alerts_secrets.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-cloudwatch-alarm-slack-integration"
  })
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_slack_integration_v2.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cw_alerts.arn
}

resource "aws_lambda_permission" "allow_s3_sns_invoke" {
  statement_id  = "AllowExecutionFromS3SNSTopic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_slack_integration_v2.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.s3_topic.arn
}

resource "aws_lambda_permission" "allow_ddos_sns_invoke" {
  statement_id  = "AllowExecutionFromDDoSSNSTopic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_slack_integration_v2.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ddos_alarm.arn
}

resource "aws_lambda_permission" "allow_sns_invoke_guardduty" {
  statement_id  = "AllowExecutionFromGuardDutySNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_slack_integration_v2.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.guardduty_alerts.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_slack_integration_v2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.certificate_expiration_warning.arn
}
