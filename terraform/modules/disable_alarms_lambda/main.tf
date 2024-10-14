data "archive_file" "lambda_function_payload" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda/disable_alarms.zip"
  excludes    = ["disable_alarms.zip"]
}

resource "aws_lambda_function" "disable_alarms" {
  filename         = "${path.module}/lambda/disable_alarms.zip"
  function_name    = var.lambda_function_name
  architectures    = ["arm64"]
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.12"
  handler          = "disable_alarms.lambda_handler"
  source_code_hash = data.archive_file.lambda_function_payload.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL       = var.lambda_log_level
      SPECIFIC_ALARMS = tostring(join(",", var.alarm_list))
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "execution_logs" {
  name              = format("/aws/lambda/%s", var.lambda_function_name)
  retention_in_days = 7

  tags = var.tags
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lambda_logging" {
  name   = "${var.lambda_function_name}-logging-policy"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_logging.json
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda_cloudwatch" {
  name   = "${var.lambda_function_name}-cloudwatch-policy"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_cloudwatch.json
}

data "aws_iam_policy_document" "lambda_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DisableAlarmActions",
      "cloudwatch:EnableAlarmActions",
    ]
    resources = ["arn:aws:cloudwatch:*:*:alarm:*"]
  }
}
