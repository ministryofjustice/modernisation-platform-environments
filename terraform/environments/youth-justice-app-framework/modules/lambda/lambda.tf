# Lambda function resource

resource "aws_lambda_function" "main" {
  #checkov:skip=CKV_AWS_50: "X-Ray tracing is enabled for Lambda" - could be implemented but not required
  #checkov:skip=CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit" - seems unnecessary for this module, could be added as reserved_concurrent_executions = 100 or similar (smaller) number.
  #checkov:skip=CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)" - not required 
  #checkov:skip=CKV_AWS_117: "Ensure that AWS Lambda function is configured inside a VPC" - irrelevant for this module
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS" - not required
  #checkov:skip=CKV_AWS_173: "Check encryption settings for Lambda environmental variable" - not required
  #checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing" - code signing is not implemented
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year" - only 7 days required, see execution_logs below
  function_name    = var.lambda.function_name
  runtime          = "python3.12"
  handler          = var.lambda.handler
  role             = aws_iam_role.lambda_iam_roles.arn
  filename         = var.lambda.function_zip_file
  source_code_hash = filebase64sha256(var.lambda.function_zip_file)
  environment {
    variables = var.lambda.environment_variables
  }

  dynamic "logging_config" {
    for_each = var.lambda.log_group != null ? [var.lambda.log_group] : []
    content {
      log_format = "Text"
      log_group  = aws_cloudwatch_log_group.log_group[0].name
    }
  }

  dynamic "vpc_config" {
    for_each = var.lambda.vpc_config != null ? [var.lambda.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  memory_size = var.lambda.lambda_memory_size
  timeout     = var.lambda.lambda_timeout

  tags = merge(var.tags, local.tags)
}

resource "aws_cloudwatch_log_group" "log_group" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS" - not required
  count             = var.lambda.log_group != null ? 1 : 0
  name_prefix       = var.lambda.log_group.name
  retention_in_days = 365

  kms_key_id = var.cloudwatch_log_group_kms_key_id

  tags = var.tags
}

resource "aws_iam_role" "lambda_iam_roles" {
  name               = var.lambda_role.name
  assume_role_policy = file(var.lambda_role.trust_policy_path)
}

resource "aws_iam_policy" "lambda_iam_permissions" {
  name   = var.lambda_role.name
  policy = templatefile(var.lambda_role.iam_policy_path, var.lambda_role.policy_template_vars)
}

resource "aws_iam_role_policy_attachment" "lambda_iam_roles_policy" {
  role       = aws_iam_role.lambda_iam_roles.name
  policy_arn = aws_iam_policy.lambda_iam_permissions.arn
}

resource "aws_iam_role_policy_attachment" "lambda_iam_roles_basic_policy" {
  role       = aws_iam_role.lambda_iam_roles.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

