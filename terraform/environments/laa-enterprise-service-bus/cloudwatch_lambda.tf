######################################
### Lambda SG
######################################

resource "aws_security_group" "cloudwatch_log_alert_sg" {
  name        = "${local.application_name_short}-${local.environment}-cloudwatch-log-security-group"
  description = "CloudWatch Log Alert Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cloudwatch-log-security-group" }
  )
}

resource "aws_security_group_rule" "cloudwatch_log_alert_https" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.cloudwatch_log_alert_sg.id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

resource "aws_security_group_rule" "cloudwatch_log_alert_https_to_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cloudwatch_log_alert_sg.id
  description       = "Allow outbound HTTPS to any destination (0.0.0.0/0) for Slack webhook"
}

######################################
### Lambda Function
######################################
resource "aws_lambda_function" "cloudwatch_log_alert" {
  description      = "Lambda function to send CloudWatch log alerts to Slack."
  function_name    = "cloudwatch_log_alert"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  role             = aws_iam_role.cloudwatch_log_alert_role.arn
  s3_bucket        = data.aws_s3_object.cloudwatch_log_alert_zip.bucket
  s3_key           = data.aws_s3_object.cloudwatch_log_alert_zip.key
  s3_object_version = data.aws_s3_object.cloudwatch_log_alert_zip.version_id
  timeout          = 60

  environment {
    variables = {
      SLACK_WEBHOOK_URL = aws_secretsmanager_secret.slack_alert_channel_webhook.name
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.cloudwatch_log_alert_sg.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cloudwatch-log-alert" }
  )
}

######################################
### Lambda Permissions
######################################

resource "aws_lambda_permission" "allow_cwa_extract_logs" {
  statement_id  = "AllowExecutionFromCWAExtractLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_log_alert.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwa_extract_lambda:*"
}

resource "aws_lambda_permission" "allow_cwa_file_transfer_logs" {
  statement_id  = "AllowExecutionFromCWAFileTransferLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_log_alert.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwa_file_transfer_lambda:*"
}

resource "aws_lambda_permission" "allow_cwa_sns_logs" {
  statement_id  = "AllowExecutionFromCWASNSLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_log_alert.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwa_sns_lambda:*"
}

resource "aws_lambda_permission" "allow_ccms_provider_logs" {
  statement_id  = "AllowExecutionFromCCMSProviderhLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_log_alert.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/ccms_provider_load_function:*"
}

resource "aws_lambda_permission" "allow_maat_provider_logs" {
  statement_id  = "AllowExecutionFromMAATProviderLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_log_alert.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/maat_provider_load_function:*"
}

resource "aws_lambda_permission" "allow_ccr_provider_logs" {
  statement_id  = "AllowExecutionFromCCRProviderLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_log_alert.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/ccr_provider_load_function:*"
}

resource "aws_lambda_permission" "allow_cclf_provider_logs" {
  statement_id  = "AllowExecutionFromCCLFProviderLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_log_alert.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cclf_provider_load_function:*"
}

resource "aws_lambda_permission" "allow_purge_lambda_logs" {
  statement_id  = "AllowExecutionFromPurgeLambdaLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_log_alert.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/purge_lambda_function:*"
}

######################################
### IAM Resources
######################################
resource "aws_iam_role" "cloudwatch_log_alert_role" {
  name = "${local.application_name_short}-cloudwatch-log-alert-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cloudwatch-log-alert-lambda-role"
    }
  )
}

resource "aws_iam_policy" "cloudwatch_log_alert_policy" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.hub2_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          aws_secretsmanager_secret.slack_alert_channel_webhook.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::${local.application_name_short}-${local.environment}-lambda-files/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_log_alert_attach" {
  role       = aws_iam_role.cloudwatch_log_alert_role.name
  policy_arn = aws_iam_policy.cloudwatch_log_alert_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_log_alert_vpc_access" {
  role       = aws_iam_role.cloudwatch_log_alert_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


######################################
### CloudWatch Resources
######################################
resource "aws_cloudwatch_log_subscription_filter" "cwa_extract_error_alert" {
  name            = "cwa-extract-lambda-error-alert"
  log_group_name  = "/aws/lambda/cwa_extract_lambda"
  filter_pattern  = "{ $.level = \"ERROR\" && $.location = \"lambda_handler*\" }"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "cwa_file_transfer_error_alert" {
  name            = "cwa-file-transfer-lambda-error-alert"
  log_group_name  = "/aws/lambda/cwa_file_transfer_lambda"
  filter_pattern  = "{ $.level = \"ERROR\" && $.location = \"lambda_handler*\" }"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "cwa_sns_error_alert" {
  name            = "cwa-sns-lambda-error-alert"
  log_group_name  = "/aws/lambda/cwa_sns_lambda"
  filter_pattern  = "{ $.level = \"ERROR\" && $.location = \"lambda_handler*\" }"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "ccms_provider_error_alert" {
  name            = "ccms-provider-lambda-error-alert"
  log_group_name  = "/aws/lambda/ccms_provider_load_function"
  filter_pattern  = "{ $.level = \"ERROR\" && $.location = \"lambda_handler*\" }"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "maat_provider_error_alert" {
  name            = "maat-provider-lambda-error-alert"
  log_group_name  = "/aws/lambda/maat_provider_load_function"
  filter_pattern  = "{ $.level = \"ERROR\" && $.location = \"lambda_handler*\" }"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "ccr_provider_error_alert" {
  name            = "ccr-provider-lambda-error-alert"
  log_group_name  = "/aws/lambda/ccr_provider_load_function"
  filter_pattern  = "{ $.level = \"ERROR\" && $.location = \"lambda_handler*\" }"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "cclf_provider_error_alert" {
  name            = "cclf-provider-lambda-error-alert"
  log_group_name  = "/aws/lambda/cclf_provider_load_function"
  filter_pattern  = "{ $.level = \"ERROR\" && $.location = \"lambda_handler*\" }"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "purge_lambda_error_alert" {
  name            = "purge-lambda-error-alert"
  log_group_name  = "/aws/lambda/purge_lambda_function"
  filter_pattern  = "{ $.level = \"ERROR\" && $.location = \"lambda_handler*\" }"
  destination_arn = aws_lambda_function.cloudwatch_log_alert.arn
}