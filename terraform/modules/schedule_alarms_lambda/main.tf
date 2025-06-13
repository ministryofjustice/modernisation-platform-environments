data "archive_file" "lambda_function_payload" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda/alarm_scheduler.zip"
  excludes    = ["alarm_scheduler.zip"]
}

resource "aws_lambda_function" "alarm_scheduler" {
  #checkov:skip=CKV_AWS_50: "X-Ray tracing is enabled for Lambda" - could be implemented but not required
  #checkov:skip=CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit" - seems unnecessary for this module, could be added as reserved_concurrent_executions = 100 or similar (smaller) number.
  #checkov:skip=CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)" - not required 
  #checkov:skip=CKV_AWS_117: "Ensure that AWS Lambda function is configured inside a VPC" - irrelevant for this module
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS" - not required
  #checkov:skip=CKV_AWS_173: "Check encryption settings for Lambda environmental variable" - not required
  #checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing" - code signing is not implemented
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year" - only 7 days required, see execution_logs below

  filename         = "${path.module}/lambda/alarm_scheduler.zip"
  function_name    = var.lambda_function_name
  architectures    = ["arm64"]
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.12"
  handler          = "alarm_scheduler.lambda_handler"
  source_code_hash = data.archive_file.lambda_function_payload.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      LOG_LEVEL       = var.lambda_log_level
      SPECIFIC_ALARMS = tostring(join(",", var.alarm_list))
      ALARM_PATTERNS  = tostring(join(",", var.alarm_patterns))
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "execution_logs" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS" - not required
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year" - only 7 days required, see below
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
      "cloudwatch:SetAlarmState",
    ]
    resources = ["arn:aws:cloudwatch:*:*:alarm:*"]
  }
}

resource "aws_cloudwatch_event_rule" "alarm_scheduler" {
  for_each            = local.schedule_rules
  name                = "${var.lambda_function_name}-${each.value.name}"
  description         = each.value.description
  schedule_expression = each.value.schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "alarm_scheduler" {
  for_each  = local.schedule_rules
  rule      = aws_cloudwatch_event_rule.alarm_scheduler[each.key].name
  target_id = "${each.value.action}-alarms-lambda"
  arn       = aws_lambda_function.alarm_scheduler.arn
  input     = jsonencode({ "action" : each.value.action })
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each      = local.schedule_rules
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_scheduler[each.key].arn
}
