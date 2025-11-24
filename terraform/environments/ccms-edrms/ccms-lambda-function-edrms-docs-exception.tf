resource "aws_iam_role" "lambda_edrms_docs_exception_role" {
  name = "${local.application_name}-${local.environment}-edrms_docs_exception_role"

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
    Name = "${local.application_name}-${local.environment}-edrms-docs-exception-role"
  })
}

resource "aws_iam_role_policy" "lambda_edrms_docs_exception_policy" {
  name = "${local.application_name}-${local.environment}-edrms-docs-exception_policy"
  role = aws_iam_role.lambda_edrms_docs_exception_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.edrms_docs_exception_monitor.function_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.log_group_edrms.arn}:*"
      },
      {
        Action : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Effect   = "Allow",
        Resource = [aws_secretsmanager_secret.edrms_docs_exception_secrets.arn]
      }
    ]
  })
}

# Lambda Layer
resource "aws_lambda_layer_version" "lambda_layer" {
  # filename                 = "lambda/layerV1.zip"
  layer_name               = "${local.application_name}-${local.environment}-edrms-docs-exception-layer"
  s3_key                   = "lambda_delivery/${local.application_name}-docs-exception-layer/layerV1.zip"
  s3_bucket                = module.s3-bucket-shared.bucket.id
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["x86_64"]
  description              = "Lambda Layer for ${local.application_name} Edrms Docs Exception"
}

resource "aws_lambda_function" "edrms_docs_exception_monitor" {
  filename         = "./lambda/edrms_docs_exception.zip"
  source_code_hash = filebase64sha256("./lambda/edrms_docs_exception.zip")
  function_name    = "${local.application_name}-${local.environment}-edrms-docs-exception-monitor"
  role             = aws_iam_role.lambda_edrms_docs_exception_role.arn
  handler          = "lambda_function.lambda_handler"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  runtime          = "python3.13"
  timeout          = 30
  publish          = true
  memory_size      = 4096 # Sets memory defaults to 4gb

  ephemeral_storage {
    size = 1024 # Sets ephemeral storage defaults to 1GB (/tmp space)
  }
  environment {
    variables = {
      LOG_GROUP_NAME = aws_cloudwatch_log_group.log_group_edrms.name
      SNS_TOPIC_ARN  = aws_sns_topic.cloudwatch_slack.arn
      SECRET_NAME    = aws_secretsmanager_secret.edrms_docs_exception_secrets.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-edrms-docs-exception-monitor"
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.edrms_docs_exception_monitor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.log_group_edrms.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "edrms_docs_exception_filter" {
  name            = "${local.application_name}-${local.environment}-edrms-docs-exception-filter"
  log_group_name  = aws_cloudwatch_log_group.log_group_edrms.name
  filter_pattern  = "\"EdrmsDocumentException\""
  destination_arn = aws_lambda_function.edrms_docs_exception_monitor.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch_invoke]
}